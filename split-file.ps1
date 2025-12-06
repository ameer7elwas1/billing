# سكريبت تقسيم billing-new.html إلى ملفات منفصلة
# استخدم: .\split-file.ps1

$sourceFile = "billing-new.html"
$outputDir = "."

# إنشاء المجلدات
New-Item -ItemType Directory -Force -Path "styles" | Out-Null
New-Item -ItemType Directory -Force -Path "js" | Out-Null

Write-Host "📖 قراءة الملف..." -ForegroundColor Cyan

# قراءة الملف
$content = Get-Content $sourceFile -Raw -Encoding UTF8

# استخراج CSS
Write-Host "🎨 استخراج CSS..." -ForegroundColor Yellow
$cssStart = $content.IndexOf('<style>') + 7
$cssEnd = $content.IndexOf('</style>')
if ($cssStart -gt 6 -and $cssEnd -gt $cssStart) {
    $css = $content.Substring($cssStart, $cssEnd - $cssStart).Trim()
    $css | Out-File "styles/main.css" -Encoding UTF8 -NoNewline
    Write-Host "✅ تم حفظ CSS في styles/main.css" -ForegroundColor Green
} else {
    Write-Host "❌ لم يتم العثور على CSS" -ForegroundColor Red
}

# استخراج JavaScript
Write-Host "📜 استخراج JavaScript..." -ForegroundColor Yellow
$jsStart = $content.IndexOf('<script>', $content.IndexOf('</head>')) + 8
$jsEnd = $content.LastIndexOf('</script>')
if ($jsStart -gt 7 -and $jsEnd -gt $jsStart) {
    $js = $content.Substring($jsStart, $jsEnd - $jsStart).Trim()
    $js | Out-File "js/all.js" -Encoding UTF8 -NoNewline
    Write-Host "✅ تم حفظ JavaScript في js/all.js" -ForegroundColor Green
    Write-Host "⚠️  يجب تقسيم js/all.js يدوياً إلى ملفات أصغر" -ForegroundColor Yellow
} else {
    Write-Host "❌ لم يتم العثور على JavaScript" -ForegroundColor Red
}

# استخراج HTML
Write-Host "📄 إنشاء index.html..." -ForegroundColor Yellow
$htmlBeforeStyle = $content.Substring(0, $content.IndexOf('<style>'))
$htmlAfterScript = $content.Substring($content.LastIndexOf('</script>') + 9)

# إزالة <style> و <script> من HTML
$htmlContent = $htmlBeforeStyle + $htmlAfterScript

# استبدال <style>...</style> بـ رابط CSS
$htmlContent = $htmlContent -replace '<style>.*?</style>', '<link rel="stylesheet" href="styles/main.css">'

# إضافة روابط JavaScript قبل </body>
$jsLinks = @"
    <!-- ملفات JavaScript -->
    <script src="js/config.js"></script>
    <script src="js/utils.js"></script>
    <script src="js/supabase.js"></script>
    <script src="js/auth.js"></script>
    <script src="js/agents.js"></script>
    <script src="js/reports.js"></script>
    <script src="js/exports.js"></script>
    <script src="js/main.js"></script>
</body>
"@

$htmlContent = $htmlContent -replace '</body>', $jsLinks

$htmlContent | Out-File "index.html" -Encoding UTF8 -NoNewline
Write-Host "✅ تم إنشاء index.html" -ForegroundColor Green

Write-Host "`n✨ اكتمل التقسيم!" -ForegroundColor Green
Write-Host "📝 الخطوات التالية:" -ForegroundColor Cyan
Write-Host "   1. راجع index.html وتأكد من أن الروابط صحيحة" -ForegroundColor White
Write-Host "   2. قسّم js/all.js إلى ملفات أصغر حسب DIVISION_GUIDE.md" -ForegroundColor White
Write-Host "   3. أنشئ js/config.js من js/config.example.js" -ForegroundColor White
Write-Host "   4. اختبر التطبيق" -ForegroundColor White

