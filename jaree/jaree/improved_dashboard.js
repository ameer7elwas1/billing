const puppeteer = require('puppeteer');
const express = require('express');
const cors = require('cors');
const path = require('path');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const winston = require('winston');
const crypto = require('crypto');
const session = require('express-session');
const open = (...args) => import('open').then(m => m.default(...args));

// إعدادات الأمان
const SECURITY_CONFIG = {
  sessionSecret: process.env.SESSION_SECRET || crypto.randomBytes(32).toString('hex'),
  rateLimitWindow: 15 * 60 * 1000, // 15 دقيقة
  rateLimitMax: 100, // 100 طلب لكل نافذة
  tokenExpiry: 24 * 60 * 60 * 1000 // 24 ساعة
};

// إعداد التسجيل
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

// APIs محسنة مع إدارة أفضل للأخطاء
const API_CONFIG = {
  baseUrl: 'https://billing.iraqcell.iq',
  endpoints: {
    login: '/#/login',
    auth: '/admin/api/index.php/api/auth',
    dashboard: '/admin/api/index.php/api/dashboard',
    managers: '/admin/api/index.php/api/index/manager',
    stats: '/admin/api/index.php/api/widgetData/internal',
    resources: '/admin/api/index.php/api/resources'
  },
  credentials: {
    username: process.env.IRAQCELL_USERNAME || 'ameer@sales',
    password: process.env.IRAQCELL_PASSWORD || 'Am@s@123'
  }
};

// إدارة الحالة المحسنة
class StateManager {
  constructor() {
    this.browser = null;
    this.page = null;
    this.token = null;
    this.tokenExpiry = null;
    this.cachedData = {
      stats: null,
      managers: null,
      agents: null,
      lastUpdate: null
    };
    this.isAuthenticated = false;
  }

  async initialize() {
    try {
      logger.info('بدء تهيئة النظام...');
      await this.setupBrowser();
      await this.authenticate();
      return true;
    } catch (error) {
      logger.error('خطأ في تهيئة النظام:', error);
      throw error;
    }
  }

  async setupBrowser() {
    this.browser = await puppeteer.launch({
      headless: process.env.NODE_ENV === 'production',
      defaultViewport: null,
      args: [
        '--start-maximized',
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-accelerated-2d-canvas',
        '--no-first-run',
        '--no-zygote',
        '--disable-gpu'
      ]
    });
    
    this.page = await this.browser.newPage();
    await this.page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
    
    // إعداد interceptor للطلبات
    await this.page.setRequestInterception(true);
    this.page.on('request', (req) => {
      if (req.resourceType() === 'image' || req.resourceType() === 'stylesheet' || req.resourceType() === 'font') {
        req.abort();
      } else {
        req.continue();
      }
    });
  }

  async authenticate() {
    try {
      logger.info('بدء عملية المصادقة...');
      
      await this.page.goto(API_CONFIG.baseUrl + API_CONFIG.endpoints.login, {
        waitUntil: 'networkidle2',
        timeout: 60000
      });

      await this.page.waitForSelector('input[name="username"]', { timeout: 30000 });
      await this.page.type('input[name="username"]', API_CONFIG.credentials.username);
      await this.page.type('input[name="password"]', API_CONFIG.credentials.password);

      await this.page.click('button[type="submit"]');
      await this.page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 60000 });

      this.token = await this.page.evaluate(() => localStorage.getItem('sas4_jwt'));
      if (!this.token) {
        throw new Error('فشل في استخراج التوكن');
      }

      this.tokenExpiry = Date.now() + SECURITY_CONFIG.tokenExpiry;
      this.isAuthenticated = true;
      
      logger.info('تم المصادقة بنجاح');
      return true;
    } catch (error) {
      logger.error('خطأ في المصادقة:', error);
      this.isAuthenticated = false;
      throw error;
    }
  }

  async ensureAuthenticated() {
    if (!this.isAuthenticated || !this.token || Date.now() > this.tokenExpiry) {
      logger.info('إعادة المصادقة...');
      await this.authenticate();
    }
  }

  async fetchWithRetry(url, options = {}, retries = 3) {
    await this.ensureAuthenticated();
    
    for (let i = 0; i < retries; i++) {
      try {
        const data = await this.page.evaluate(async (url, token, options) => {
          const res = await fetch(url, {
            ...options,
            headers: {
              'Authorization': 'Bearer ' + token,
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-Requested-With': 'XMLHttpRequest',
              ...options.headers
            }
          });
          
          if (!res.ok) {
            throw new Error(`HTTP ${res.status}: ${res.statusText}`);
          }
          
          return await res.json();
        }, url, this.token, options);
        
        return data;
      } catch (error) {
        logger.warn(`محاولة ${i + 1} فشلت لـ ${url}:`, error.message);
        
        if (i === retries - 1) {
          throw error;
        }
        
        // إعادة المصادقة إذا كان الخطأ متعلق بالتوكن
        if (error.message.includes('401') || error.message.includes('403')) {
          await this.authenticate();
        }
        
        await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
      }
    }
  }

  async cleanup() {
    if (this.browser) {
      await this.browser.close();
    }
  }
}

// إنشاء مدير الحالة
const stateManager = new StateManager();

// إعداد Express مع الأمان
const app = express();

// إعدادات الأمان
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net", "https://cdnjs.cloudflare.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
      imgSrc: ["'self'", "data:", "https:"],
      fontSrc: ["'self'", "https://cdnjs.cloudflare.com"]
    }
  }
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: SECURITY_CONFIG.rateLimitWindow,
  max: SECURITY_CONFIG.rateLimitMax,
  message: {
    error: 'تم تجاوز الحد الأقصى للطلبات. يرجى المحاولة لاحقاً.'
  },
  standardHeaders: true,
  legacyHeaders: false
});

app.use(limiter);

// إعدادات CORS محسنة
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000'],
  credentials: true,
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// إعداد الجلسات
app.use(session({
  secret: SECURITY_CONFIG.sessionSecret,
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 ساعة
  }
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Middleware للتحقق من المصادقة
const requireAuth = (req, res, next) => {
  if (!stateManager.isAuthenticated) {
    return res.status(401).json({ error: 'غير مصرح، يلزم إعادة المصادقة' });
  }
  next();
};

// Routes محسنة
app.get('/', requireAuth, async (req, res) => {
  try {
    const stats = await fetchAllStats();
    const html = generateDashboardHTML(stats);
    res.send(html);
  } catch (error) {
    logger.error('خطأ في الصفحة الرئيسية:', error);
    res.status(500).send(generateErrorHTML(error.message));
  }
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    authenticated: stateManager.isAuthenticated,
    timestamp: new Date().toISOString()
  });
});

app.get('/api/refresh', requireAuth, async (req, res) => {
  try {
    const stats = await fetchAllStats();
    res.json({
      success: true,
      data: stats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    logger.error('خطأ في تحديث البيانات:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Middleware للتعامل مع الأخطاء
app.use((error, req, res, next) => {
  logger.error('خطأ غير متوقع:', error);
  res.status(500).json({
    error: 'خطأ داخلي في الخادم',
    timestamp: new Date().toISOString()
  });
});

// إدارة الإغلاق الآمن
process.on('SIGINT', async () => {
  logger.info('إيقاف السيرفر...');
  await stateManager.cleanup();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  logger.info('إيقاف السيرفر...');
  await stateManager.cleanup();
  process.exit(0);
});

// تشغيل السيرفر
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    await stateManager.initialize();
    
    app.listen(PORT, () => {
      logger.info(`🚀 السيرفر يعمل على http://localhost:${PORT}`);
      logger.info('📊 داشبورد IraqCell المحسن - الإصدار 3.0');
      
      if (process.env.NODE_ENV !== 'production') {
        open(`http://localhost:${PORT}`);
      }
    });
  } catch (error) {
    logger.error('فشل في بدء السيرفر:', error);
    process.exit(1);
  }
}

startServer(); 