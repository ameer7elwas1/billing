# سكريبت رفع المشروع على GitHub
# استخدم: .\upload-to-github.ps1

Write-Host "🚀 دليل رفع المشروع على GitHub" -ForegroundColor Cyan
Write-Host ""

# التحقق من Git
Write-Host "📦 التحقق من Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "✅ Git مثبت: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git غير مثبت. حمّله من: https://git-scm.com/download/win" -ForegroundColor Red
    exit
}

# التحقق من وجود .git
if (Test-Path .git) {
    Write-Host "✅ Git مهيأ بالفعل" -ForegroundColor Green
} else {
    Write-Host "📝 تهيئة Git..." -ForegroundColor Yellow
    git init
    Write-Host "✅ تم تهيئة Git" -ForegroundColor Green
}

# التحقق من .gitignore
if (Test-Path .gitignore) {
    Write-Host "✅ ملف .gitignore موجود" -ForegroundColor Green
    if (Select-String -Path .gitignore -Pattern "js/config.js" -Quiet) {
        Write-Host "✅ js/config.js محمي من الرفع" -ForegroundColor Green
    } else {
        Write-Host "⚠️  تحذير: js/config.js غير موجود في .gitignore" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  تحذير: ملف .gitignore غير موجود" -ForegroundColor Yellow
}

# عرض الملفات التي ستُرفع
Write-Host "`n📋 الملفات التي ستُرفع:" -ForegroundColor Cyan
git status --short

# التحقق من وجود remote
$remote = git remote get-url origin 2>$null
if ($remote) {
    Write-Host "`n✅ المستودع البعيد: $remote" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  لم يتم إضافة مستودع بعيد" -ForegroundColor Yellow
    Write-Host "`n📝 خطوات إضافة المستودع:" -ForegroundColor Cyan
    Write-Host "   1. أنشئ مستودع جديد على GitHub" -ForegroundColor White
    Write-Host "   2. شغّل:" -ForegroundColor White
    Write-Host "      git remote add origin https://github.com/YOUR_USERNAME/billing-accounts-system.git" -ForegroundColor Gray
    Write-Host "`n   ثم شغّل هذا السكريبت مرة أخرى" -ForegroundColor White
    exit
}

# السؤال عن المتابعة
Write-Host "`n❓ هل تريد المتابعة مع الرفع؟ (Y/N)" -ForegroundColor Yellow
$response = Read-Host

if ($response -ne "Y" -and $response -ne "y") {
    Write-Host "❌ تم الإلغاء" -ForegroundColor Red
    exit
}

# إضافة الملفات
Write-Host "`n📤 إضافة الملفات..." -ForegroundColor Yellow
git add .

# Commit
Write-Host "💾 عمل commit..." -ForegroundColor Yellow
$commitMessage = Read-Host "أدخل رسالة commit (أو اضغط Enter للرسالة الافتراضية)"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Update: تحديث المشروع"
}
git commit -m $commitMessage

# رفع الملفات
Write-Host "`n🚀 رفع الملفات إلى GitHub..." -ForegroundColor Yellow
try {
    git push -u origin main
    Write-Host "`n✅ تم الرفع بنجاح!" -ForegroundColor Green
    Write-Host "`n🌐 يمكنك رؤية المشروع على:" -ForegroundColor Cyan
    Write-Host "   $remote" -ForegroundColor Gray
} catch {
    Write-Host "`n❌ حدث خطأ أثناء الرفع" -ForegroundColor Red
    Write-Host "`n💡 نصائح:" -ForegroundColor Yellow
    Write-Host "   - تأكد من اسم المستخدم وكلمة المرور" -ForegroundColor White
    Write-Host "   - استخدم Personal Access Token ككلمة مرور" -ForegroundColor White
    Write-Host "   - اقرأ UPLOAD_GUIDE.md للتفاصيل" -ForegroundColor White
}

Write-Host "`n✨ اكتمل!" -ForegroundColor Green

