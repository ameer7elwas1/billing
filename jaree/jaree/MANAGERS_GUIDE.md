# 👥 دليل جلب بيانات المدراء الحقيقية - IraqCell

## 🎯 **الهدف**

هذه الأداة مخصصة لجلب بيانات المدراء الحقيقية من نظام [IraqCell للفواتير](https://billing.iraqcell.iq) مع إمكانية استكشاف APIs إضافية.

## 🚀 **الميزات**

### ✅ **الميزات الأساسية**
- تسجيل دخول تلقائي لنظام IraqCell
- جلب بيانات المدراء الحقيقية
- استكشاف APIs إضافية
- إنشاء تقارير JSON و HTML
- إدارة أخطاء متقدمة
- إعادة المحاولة التلقائية

### 📊 **البيانات المجمعة**
- معلومات المدراء الأساسية
- بيانات الداشبورد
- معلومات المصادقة
- نتائج استكشاف APIs

## 🛠️ **التثبيت والتشغيل**

### المتطلبات
- Node.js >= 16.0.0
- npm أو yarn
- اتصال بالإنترنت

### التثبيت
```bash
# تثبيت التبعيات
npm install

# أو باستخدام yarn
yarn install
```

### إعداد متغيرات البيئة
```bash
# إنشاء ملف .env
echo "IRAQCELL_USERNAME=ameer@sales" > .env
echo "IRAQCELL_PASSWORD=Am@s@123" >> .env
```

### التشغيل
```bash
# تشغيل الأداة
npm start

# أو مباشرة
node real_managers_fetcher.js
```

## 📋 **خطوات التشغيل**

### 1. **تهيئة النظام**
```javascript
const fetcher = new RealManagersFetcher();
await fetcher.initialize();
```

### 2. **المصادقة**
```javascript
await fetcher.authenticate();
```

### 3. **جلب البيانات**
```javascript
// جلب بيانات المدراء
const managersData = await fetcher.fetchManagersData();

// جلب بيانات الداشبورد
const dashboardData = await fetcher.fetchDashboardData();

// جلب بيانات المصادقة
const authData = await fetcher.fetchAuthData();
```

### 4. **إنشاء التقرير**
```javascript
const report = await fetcher.generateDetailedReport();
```

### 5. **حفظ النتائج**
```javascript
// حفظ كـ JSON
await fetcher.saveReportToFile(report);

// إنشاء تقرير HTML
const htmlReport = await fetcher.generateHTMLReport(report);
```

## 📊 **هيكل البيانات**

### بيانات المدراء
```json
{
  "data": [
    {
      "id": "123",
      "username": "manager1",
      "name": "أحمد محمد",
      "email": "ahmed@iraqcell.iq",
      "phone": "+964771234567",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### تقرير مفصل
```json
{
  "timestamp": "2024-01-01T12:00:00Z",
  "system_info": {
    "url": "https://billing.iraqcell.iq",
    "user": "ameer@sales",
    "authenticated": true
  },
  "managers": {
    "data": [...],
    "total": 10
  },
  "dashboard": {...},
  "auth": {...},
  "additional_apis": {...},
  "summary": {
    "total_managers": 10,
    "successful_apis": 5,
    "failed_apis": 2
  }
}
```

## 🔧 **الاستخدام المتقدم**

### استخدام كـ Module
```javascript
const RealManagersFetcher = require('./real_managers_fetcher.js');

async function customFetch() {
  const fetcher = new RealManagersFetcher();
  
  try {
    await fetcher.initialize();
    await fetcher.authenticate();
    
    // جلب بيانات مخصصة
    const managers = await fetcher.fetchManagersData();
    const apis = await fetcher.exploreAdditionalAPIs();
    
    console.log(`تم جلب ${managers.data.length} مدير`);
    console.log(`تم اختبار ${Object.keys(apis).length} API`);
    
  } catch (error) {
    console.error('خطأ:', error.message);
  } finally {
    await fetcher.cleanup();
  }
}
```

### تخصيص الإعدادات
```javascript
// تعديل إعدادات النظام
const IRAQCELL_CONFIG = {
  baseUrl: 'https://billing.iraqcell.iq',
  loginUrl: 'https://billing.iraqcell.iq/#/login',
  managersApi: 'https://billing.iraqcell.iq/admin/api/index.php/api/index/manager',
  credentials: {
    username: process.env.IRAQCELL_USERNAME,
    password: process.env.IRAQCELL_PASSWORD
  }
};
```

## 📁 **الملفات المُنشأة**

### ملفات JSON
- `iraqcell_managers_report_YYYY-MM-DDTHH-MM-SS.json`
- يحتوي على جميع البيانات المجمعة

### ملفات HTML
- `iraqcell_managers_report.html`
- تقرير مرئي مع تصميم جميل

## 🔍 **استكشاف APIs**

### APIs المُختبرة تلقائياً
1. **Menu API**: `api/resources/menu`
2. **Forms API**: `api/resources/forms`
3. **Languages API**: `api/resources/languages`
4. **Version API**: `api/resources/version`
5. **Welcome Screen API**: `api/resources/welcomeScreen`
6. **Login API**: `api/resources/login`

### إضافة APIs جديدة
```javascript
const additionalAPIs = [
  'https://billing.iraqcell.iq/admin/api/index.php/api/your-new-api',
  // أضف APIs جديدة هنا
];
```

## 🚨 **إدارة الأخطاء**

### أنواع الأخطاء الشائعة

#### 1. **أخطاء المصادقة**
```javascript
// إعادة المحاولة التلقائية
if (error.message.includes('401') || error.message.includes('403')) {
  await fetcher.authenticate();
}
```

#### 2. **أخطاء الشبكة**
```javascript
// إعادة المحاولة مع تأخير
await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
```

#### 3. **أخطاء البيانات**
```javascript
// التحقق من صحة البيانات
if (!managersData || !managersData.data) {
  throw new Error('لا توجد بيانات للمدراء في الاستجابة');
}
```

## 📈 **تحسين الأداء**

### 1. **Request Interception**
```javascript
// منع تحميل الموارد غير الضرورية
this.page.on('request', (req) => {
  if (req.resourceType() === 'image' || req.resourceType() === 'stylesheet') {
    req.abort();
  } else {
    req.continue();
  }
});
```

### 2. **Caching**
```javascript
// حفظ البيانات مؤقتاً
this.cachedData = {
  managers: null,
  lastUpdate: null
};
```

### 3. **Parallel Processing**
```javascript
// جلب البيانات بالتوازي
const [managers, dashboard, auth] = await Promise.all([
  fetcher.fetchManagersData(),
  fetcher.fetchDashboardData(),
  fetcher.fetchAuthData()
]);
```

## 🔒 **الأمان**

### 1. **إدارة البيانات الحساسة**
```javascript
// استخدام Environment Variables
const credentials = {
  username: process.env.IRAQCELL_USERNAME,
  password: process.env.IRAQCELL_PASSWORD
};
```

### 2. **حماية التوكن**
```javascript
// التحقق من صلاحية التوكن
if (!this.token || Date.now() > this.tokenExpiry) {
  await this.authenticate();
}
```

### 3. **تنظيف البيانات**
```javascript
// حذف البيانات الحساسة
await fetcher.cleanup();
```

## 📊 **المراقبة والتشخيص**

### 1. **تسجيل العمليات**
```javascript
console.log('🚀 بدء تهيئة أداة جلب بيانات المدراء...');
console.log('✅ تم جلب 10 مدير بنجاح');
console.log('❌ خطأ في جلب بيانات المدراء: ' + error.message);
```

### 2. **إحصائيات الأداء**
```javascript
const startTime = Date.now();
// ... العمليات
const endTime = Date.now();
console.log(`⏱️ الوقت المستغرق: ${endTime - startTime}ms`);
```

### 3. **فحص الحالة**
```javascript
console.log(`🔐 حالة المصادقة: ${fetcher.isAuthenticated}`);
console.log(`📊 عدد المدراء: ${report.summary.total_managers}`);
```

## 🎯 **أمثلة الاستخدام**

### مثال 1: جلب بيانات المدراء فقط
```javascript
const fetcher = new RealManagersFetcher();
await fetcher.initialize();
await fetcher.authenticate();

const managers = await fetcher.fetchManagersData();
console.log(`تم جلب ${managers.data.length} مدير`);
```

### مثال 2: إنشاء تقرير شامل
```javascript
const fetcher = new RealManagersFetcher();
await fetcher.initialize();
await fetcher.authenticate();

const report = await fetcher.generateDetailedReport();
await fetcher.saveReportToFile(report);
```

### مثال 3: استكشاف APIs فقط
```javascript
const fetcher = new RealManagersFetcher();
await fetcher.initialize();
await fetcher.authenticate();

const apis = await fetcher.exploreAdditionalAPIs();
console.log('نتائج استكشاف APIs:', apis);
```

## 🤝 **المساهمة**

### كيفية المساهمة
1. Fork المشروع
2. إنشاء branch جديد
3. إجراء التغييرات
4. إضافة tests
5. إنشاء Pull Request

### معايير الكود
- استخدام ESLint
- اتباع معايير JavaScript
- كتابة تعليقات باللغة العربية
- اختبار شامل

## 📞 **الدعم**

### قنوات الدعم
- 📧 Email: support@iraqcell.iq
- 💬 Discord: [رابط Discord]
- 📱 Telegram: [رابط Telegram]
- 🐛 Issues: [GitHub Issues]

---

**تم التطوير بواسطة فريق IraqCell** 🇮🇶 