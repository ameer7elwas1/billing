# دليل تقسيم الملف الكبير إلى ملفات منفصلة

## 📋 الخطوات

### الخطوة 1: استخراج CSS

1. افتح `billing-new.html`
2. ابحث عن `<style>` (السطر 15 تقريباً)
3. انسخ كل المحتوى من `<style>` إلى `</style>` (السطر 2961)
4. احذف `<style>` و `</style>` من المحتوى
5. احفظه في `styles/main.css`

**مثال:**
```bash
# في المحرر، انسخ من السطر 16 إلى 2960
# احفظ في styles/main.css
```

### الخطوة 2: استخراج JavaScript

1. ابحث عن `<script>` (السطر 3652 تقريباً)
2. انسخ كل المحتوى من `<script>` إلى `</script>` (قبل `</body>`)
3. احذف `<script>` و `</script>` من المحتوى
4. قسّم المحتوى إلى ملفات:

#### `js/config.js`
```javascript
// المتغيرات العامة
const SUPABASE_URL = '...';
const SUPABASE_ANON_KEY = '...';
const SYSTEM_NAME = 'billing_accounts';

// المتغيرات العامة
let supabaseClient = null;
let loggedInUser = '';
let currentUserRole = 'employee';
let currentUserId = null;
```

#### `js/utils.js`
- دوال التنسيق: `formatNumber`, `formatNumberEnglish`
- دوال التاريخ: `getCurrentMonthYear`, `extractMonthYearFromData`
- دوال DOM: `showAlert`, `showSuccessMessage`

#### `js/supabase.js`
- `initSupabase()`
- `supabaseRequest()`
- `saveToDatabase()`

#### `js/auth.js`
- `handleLogin()`
- `handleLogout()`
- `updateAdminTabsVisibility()`
- `hashPassword()`

#### `js/agents.js`
- جميع دوال إدارة الوكلاء
- `loadAgents()`, `saveAgent()`, `deleteAgent()`

#### `js/reports.js`
- دوال التحليل: `analyzeBasicData()`, `analyzeAdvancedData()`
- دوال العرض: `displayBasicResults()`, `displayAdvancedResults()`

#### `js/exports.js`
- `exportSummaryToExcel()`
- `exportPercentageToExcel()`
- `generatePDFReport()`

#### `js/main.js`
- تهيئة التطبيق
- `DOMContentLoaded` event listeners
- دوال الواجهة الرئيسية

### الخطوة 3: إنشاء index.html الجديد

انسخ من `billing-new.html`:
- من البداية إلى `</head>` (بدون `<style>`)
- أضف: `<link rel="stylesheet" href="styles/main.css">`
- من `<body>` إلى `</body>` (بدون `<script>`)
- أضف قبل `</body>`:
```html
<script src="js/config.js"></script>
<script src="js/utils.js"></script>
<script src="js/supabase.js"></script>
<script src="js/auth.js"></script>
<script src="js/agents.js"></script>
<script src="js/reports.js"></script>
<script src="js/exports.js"></script>
<script src="js/main.js"></script>
```

## 🔧 أدوات مساعدة

### استخراج CSS تلقائياً (PowerShell)
```powershell
$content = Get-Content billing-new.html -Raw
$cssStart = $content.IndexOf('<style>') + 7
$cssEnd = $content.IndexOf('</style>')
$css = $content.Substring($cssStart, $cssEnd - $cssStart)
$css | Out-File styles/main.css -Encoding UTF8
```

### استخراج JavaScript تلقائياً
```powershell
$content = Get-Content billing-new.html -Raw
$jsStart = $content.IndexOf('<script>', $content.IndexOf('</head>')) + 8
$jsEnd = $content.LastIndexOf('</script>')
$js = $content.Substring($jsStart, $jsEnd - $jsStart)
$js | Out-File js/all.js -Encoding UTF8
```

## ⚠️ ملاحظات مهمة

1. **احتفظ بنسخة احتياطية** من `billing-new.html`
2. **اختبر كل ملف** بعد استخراجه
3. **تأكد من الترتيب** في `index.html` - الملفات يجب أن تُحمل بالترتيب الصحيح
4. **تحقق من الأخطاء** في Console (F12)

## 🎯 الترتيب الموصى به للتحميل

```html
<!-- 1. الإعدادات أولاً -->
<script src="js/config.js"></script>

<!-- 2. الأدوات الأساسية -->
<script src="js/utils.js"></script>

<!-- 3. Supabase -->
<script src="js/supabase.js"></script>

<!-- 4. المصادقة -->
<script src="js/auth.js"></script>

<!-- 5. الوكلاء -->
<script src="js/agents.js"></script>

<!-- 6. التقارير -->
<script src="js/reports.js"></script>

<!-- 7. التصدير -->
<script src="js/exports.js"></script>

<!-- 8. التهيئة الرئيسية (آخر شيء) -->
<script src="js/main.js"></script>
```

