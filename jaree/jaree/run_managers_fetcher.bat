@echo off
chcp 65001 >nul
echo.
echo 🇮🇶 أداة جلب بيانات المدراء الحقيقية - IraqCell
echo ================================================
echo.

REM التحقق من وجود Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ خطأ: Node.js غير مثبت
    echo يرجى تثبيت Node.js من https://nodejs.org/
    pause
    exit /b 1
)

REM التحقق من وجود الملفات المطلوبة
if not exist "real_managers_fetcher.js" (
    echo ❌ خطأ: ملف real_managers_fetcher.js غير موجود
    pause
    exit /b 1
)

REM تثبيت التبعيات إذا لم تكن مثبتة
if not exist "node_modules" (
    echo 📦 تثبيت التبعيات...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ خطأ في تثبيت التبعيات
        pause
        exit /b 1
    )
)

echo 🚀 بدء تشغيل الأداة...
echo.

REM تشغيل الأداة
node real_managers_fetcher.js

echo.
echo ✅ تم الانتهاء من تشغيل الأداة
pause 