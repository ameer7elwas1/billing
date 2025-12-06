@echo off
REM سكريبت بناء وتشغيل تطبيق جاري للأندرويد - Windows
REM Jaree Employee Tracker Android Build Script for Windows

echo 🚀 بدء بناء تطبيق جاري للأندرويد...

REM التحقق من وجود Cordova
where cordova >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Cordova غير مثبت. يرجى تثبيته أولاً:
    echo npm install -g cordova
    pause
    exit /b 1
)

REM التحقق من وجود Android SDK
if "%ANDROID_HOME%"=="" (
    echo ❌ متغير ANDROID_HOME غير محدد. يرجى إعداده أولاً.
    pause
    exit /b 1
)

REM الانتقال إلى مجلد المشروع
cd /d "%~dp0"

echo 📦 تثبيت التبعيات...
call npm install

echo 🔧 إضافة منصة الأندرويد...
call cordova platform add android

echo 🔌 إضافة الإضافات المطلوبة...
call cordova plugin add cordova-plugin-geolocation
call cordova plugin add cordova-plugin-network-information
call cordova plugin add cordova-plugin-device
call cordova plugin add cordova-plugin-statusbar
call cordova plugin add cordova-plugin-splashscreen
call cordova plugin add cordova-plugin-whitelist
call cordova plugin add cordova-plugin-file

echo 🏗️ بناء التطبيق...
call cordova build android

if %errorlevel% equ 0 (
    echo ✅ تم بناء التطبيق بنجاح!
    echo 📱 يمكنك الآن تشغيله باستخدام:
    echo cordova run android
    
    REM سؤال المستخدم إذا كان يريد تشغيل التطبيق
    set /p choice="هل تريد تشغيل التطبيق الآن؟ (y/n): "
    if /i "%choice%"=="y" (
        echo 🚀 تشغيل التطبيق...
        call cordova run android
    )
) else (
    echo ❌ فشل في بناء التطبيق. يرجى مراجعة الأخطاء أعلاه.
    pause
    exit /b 1
)

pause
