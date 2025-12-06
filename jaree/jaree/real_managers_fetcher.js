const puppeteer = require('puppeteer');
const fs = require('fs').promises;
const path = require('path');

// إعدادات النظام
const IRAQCELL_CONFIG = {
  baseUrl: 'https://billing.iraqcell.iq',
  loginUrl: 'https://billing.iraqcell.iq/#/login',
  managersApi: 'https://billing.iraqcell.iq/admin/api/index.php/api/index/manager',
  dashboardApi: 'https://billing.iraqcell.iq/admin/api/index.php/api/dashboard',
  authApi: 'https://billing.iraqcell.iq/admin/api/index.php/api/auth',
  credentials: {
    username: process.env.IRAQCELL_USERNAME || 'ameer@sales',
    password: process.env.IRAQCELL_PASSWORD || 'Am@s@123'
  }
};

class RealManagersFetcher {
  constructor() {
    this.browser = null;
    this.page = null;
    this.token = null;
    this.isAuthenticated = false;
  }

  async initialize() {
    console.log('🚀 بدء تهيئة أداة جلب بيانات المدراء...');
    
    try {
      this.browser = await puppeteer.launch({
        headless: false, // عرض المتصفح للتحكم
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
      
      // إعداد interceptor لتحسين الأداء
      await this.page.setRequestInterception(true);
      this.page.on('request', (req) => {
        if (req.resourceType() === 'image' || req.resourceType() === 'stylesheet' || req.resourceType() === 'font') {
          req.abort();
        } else {
          req.continue();
        }
      });

      console.log('✅ تم تهيئة المتصفح بنجاح');
      return true;
    } catch (error) {
      console.error('❌ خطأ في تهيئة المتصفح:', error.message);
      throw error;
    }
  }

  async authenticate() {
    try {
      console.log('🔐 بدء عملية المصادقة...');
      
      await this.page.goto(IRAQCELL_CONFIG.loginUrl, {
        waitUntil: 'networkidle2',
        timeout: 60000
      });

      console.log('📝 تعبئة بيانات تسجيل الدخول...');
      await this.page.waitForSelector('input[name="username"]', { timeout: 30000 });
      await this.page.type('input[name="username"]', IRAQCELL_CONFIG.credentials.username);
      await this.page.type('input[name="password"]', IRAQCELL_CONFIG.credentials.password);

      console.log('🔑 جاري تسجيل الدخول...');
      await this.page.click('button[type="submit"]');
      await this.page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 60000 });

      this.token = await this.page.evaluate(() => localStorage.getItem('sas4_jwt'));
      if (!this.token) {
        throw new Error('فشل في استخراج التوكن من localStorage');
      }

      this.isAuthenticated = true;
      console.log('✅ تم تسجيل الدخول بنجاح!');
      return true;
    } catch (error) {
      console.error('❌ خطأ في المصادقة:', error.message);
      this.isAuthenticated = false;
      throw error;
    }
  }

  async fetchWithRetry(url, options = {}, retries = 3) {
    for (let i = 0; i < retries; i++) {
      try {
        console.log(`🔄 محاولة ${i + 1}/${retries} لـ ${url}`);
        
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
        
        console.log(`✅ نجح في جلب البيانات من ${url}`);
        return data;
      } catch (error) {
        console.warn(`⚠️ محاولة ${i + 1} فشلت لـ ${url}:`, error.message);
        
        if (i === retries - 1) {
          throw error;
        }
        
        // إعادة المصادقة إذا كان الخطأ متعلق بالتوكن
        if (error.message.includes('401') || error.message.includes('403')) {
          console.log('🔄 إعادة المصادقة...');
          await this.authenticate();
        }
        
        await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
      }
    }
  }

  async fetchManagersData() {
    try {
      console.log('👥 جاري جلب بيانات المدراء...');
      
      const managersData = await this.fetchWithRetry(IRAQCELL_CONFIG.managersApi, {
        method: 'POST',
        body: JSON.stringify({})
      });

      if (!managersData || !managersData.data) {
        throw new Error('لا توجد بيانات للمدراء في الاستجابة');
      }

      console.log(`✅ تم جلب ${managersData.data.length} مدير بنجاح`);
      return managersData;
    } catch (error) {
      console.error('❌ خطأ في جلب بيانات المدراء:', error.message);
      throw error;
    }
  }

  async cleanup() {
    if (this.browser) {
      await this.browser.close();
      console.log('🔒 تم إغلاق المتصفح');
    }
  }
}

// تشغيل الأداة
async function main() {
  const fetcher = new RealManagersFetcher();
  
  try {
    console.log('🇮🇶 أداة جلب بيانات المدراء الحقيقية - IraqCell');
    console.log('=' .repeat(60));
    
    await fetcher.initialize();
    await fetcher.authenticate();
    
    const managers = await fetcher.fetchManagersData();
    await fs.writeFile('iraqcell_managers.json', JSON.stringify(managers, null, 2), 'utf8');
    console.log('✅ تم حفظ بيانات المدراء في iraqcell_managers.json');
    
  } catch (error) {
    console.error('❌ خطأ في تشغيل الأداة:', error.message);
  } finally {
    await fetcher.cleanup();
  }
}

if (require.main === module) {
  main();
}

module.exports = RealManagersFetcher; 