# 🚀 دليل رفع المشروع على GitHub

## 📋 المتطلبات

- حساب GitHub (إنشاء حساب: [github.com/signup](https://github.com/signup))
- Git مثبت على جهازك
- المشروع مقسم إلى ملفات منفصلة

## 🔧 الخطوة 1: تثبيت Git (إذا لم يكن مثبتاً)

### Windows:
1. حمّل من [git-scm.com/download/win](https://git-scm.com/download/win)
2. شغّل المثبت
3. اختر الخيارات الافتراضية

### التحقق من التثبيت:
```bash
git --version
```

## 📦 الخطوة 2: إنشاء مستودع جديد على GitHub

1. اذهب إلى [github.com](https://github.com) وسجّل الدخول
2. اضغط على زر **"+"** في الأعلى → **"New repository"**
3. املأ المعلومات:
   - **Repository name**: `billing-accounts-system`
   - **Description**: `نظام إدارة الحسابات والفواتير`
   - **Visibility**: اختر **Private** (خاص) أو **Public** (عام)
   - **⚠️ لا تضع علامة** على "Initialize this repository with a README"
4. اضغط **"Create repository"**

## 💻 الخطوة 3: إعداد Git محلياً

افتح **Terminal** (Windows: PowerShell أو CMD) في مجلد المشروع:

```bash
# الانتقال إلى مجلد المشروع
cd "D:\Projects\VBA\قسم الحسابات"

# تهيئة Git
git init

# إضافة جميع الملفات
git add .

# عمل commit أولي
git commit -m "Initial commit: تقسيم المشروع إلى ملفات منفصلة"

# إضافة رابط المستودع (استبدل USERNAME باسمك على GitHub)
git remote add origin https://github.com/USERNAME/billing-accounts-system.git

# تغيير اسم الفرع إلى main
git branch -M main

# رفع الملفات
git push -u origin main
```

### إذا طُلب منك اسم المستخدم وكلمة المرور:
- **Username**: اسمك على GitHub
- **Password**: استخدم **Personal Access Token** (ليس كلمة المرور العادية)

### إنشاء Personal Access Token:
1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. اختر الصلاحيات: `repo` (كامل)
4. انسخ الرمز واحفظه (لن يظهر مرة أخرى!)

## 🔄 الخطوة 4: رفع التحديثات المستقبلية

عندما تقوم بتعديلات:

```bash
# إضافة التغييرات
git add .

# عمل commit مع وصف التغييرات
git commit -m "وصف التغييرات - مثلاً: إصلاح مشكلة في التقارير"

# رفع التحديثات
git push
```

## 📁 الملفات التي يجب ألا ترفعها

تأكد من وجود ملف `.gitignore` (تم إنشاؤه تلقائياً):

```
js/config.js          # المفاتيح السرية
*.backup
*.log
```

## 🔐 حماية المفاتيح السرية

### قبل الرفع:

1. **أنشئ `js/config.js` محلياً** (لا ترفعه):
```javascript
const SUPABASE_URL = 'https://your-actual-url.supabase.co';
const SUPABASE_ANON_KEY = 'your-actual-key';
const SYSTEM_NAME = 'billing_accounts';
```

2. **تأكد من وجود `js/config.js` في `.gitignore`**

3. **ارفع `js/config.example.js` فقط** (بدون مفاتيح حقيقية)

### للمستخدمين الجدد:
- ينسخون `config.example.js` إلى `config.js`
- يملؤون المفاتيح الحقيقية محلياً

## 🛠️ حل المشاكل الشائعة

### خطأ: "remote origin already exists"
```bash
git remote remove origin
git remote add origin https://github.com/USERNAME/billing-accounts-system.git
```

### خطأ: "failed to push"
```bash
# سحب التغييرات أولاً
git pull origin main --allow-unrelated-histories

# ثم ارفع
git push -u origin main
```

### نسيان commit
```bash
git status  # لرؤية الملفات المعدلة
git add .
git commit -m "وصف التغييرات"
git push
```

## 📚 أوامر Git مفيدة

```bash
# رؤية حالة الملفات
git status

# رؤية التغييرات
git diff

# رؤية تاريخ الـ commits
git log

# إلغاء التغييرات في ملف
git checkout -- filename

# سحب التحديثات من GitHub
git pull
```

## 🎯 نصائح

1. **اعمل commit بعد كل تغيير مهم**
2. **اكتب وصف واضح في commit message**
3. **لا ترفع المفاتيح السرية أبداً**
4. **احتفظ بنسخة احتياطية محلية**

## 📞 المساعدة

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com)
- [Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)

