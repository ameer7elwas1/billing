-- تحديث اسم admin1 من "أحمد علي" إلى "مدير 1"
UPDATE users 
SET full_name = 'مدير 1', 
    updated_at = NOW() AT TIME ZONE 'Asia/Baghdad'
WHERE username = 'admin1';

-- تحديث اسم admin2 من "فاطمة حسن" إلى "مدير 2" (إذا كان موجود)
UPDATE users 
SET full_name = 'مدير 2', 
    updated_at = NOW() AT TIME ZONE 'Asia/Baghdad'
WHERE username = 'admin2';

-- عرض النتيجة
SELECT username, full_name, role FROM users WHERE username IN ('admin1', 'admin2');
