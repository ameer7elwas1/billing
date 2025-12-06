-- إعداد المستخدمين في قاعدة البيانات
-- قم بتنفيذ هذا الملف في Supabase SQL Editor

-- حذف المستخدمين القديمة أولاً (اختياري - احذر!)
-- DROP TABLE IF EXISTS users CASCADE;

-- إنشاء جدول المستخدمين إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    school_id UUID REFERENCES schools(id),
    user_type VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    full_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(username, school_id)
);

-- فهارس
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_school ON users(school_id);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- حذف المستخدمين القدامى (احذر!)
DELETE FROM users WHERE username IN ('admin_rasoul', 'admin_noor', 'admin_nabi', 'admin_thanawiya', 'admin_rawda');

-- إدراج المستخدمين الجدد
-- الحصول على معرفات المدارس
DO $$ 
DECLARE
    rawda_id UUID;
    rasoul_id UUID;
    noor_id UUID;
    nabi_id UUID;
    thanawiya_id UUID;
BEGIN
    -- الحصول على معرفات المدارس
    SELECT id INTO rawda_id FROM schools WHERE code = 'rawda';
    SELECT id INTO rasoul_id FROM schools WHERE code = 'rasoul';
    SELECT id INTO noor_id FROM schools WHERE code = 'noor';
    SELECT id INTO nabi_id FROM schools WHERE code = 'nabi';
    SELECT id INTO thanawiya_id FROM schools WHERE code = 'thanawiya';
    
    -- إدراج مستخدمين المدراس (بأسماء مستخدمين مميزة)               
    IF rawda_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin_rawda' AND school_id = rawda_id) THEN
        INSERT INTO users (username, password, password_hash, school_id, user_type, is_active, full_name)
        VALUES ('admin_rawda', 'rawda123', 'rawda123', rawda_id, 'school_admin', true, 'مدير روضة رسول الرحمة');
    END IF;
    
    IF rasoul_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin_rasoul' AND school_id = rasoul_id) THEN
        INSERT INTO users (username, password, password_hash, school_id, user_type, is_active, full_name)
        VALUES ('admin_rasoul', 'rasoul123', 'rasoul123', rasoul_id, 'school_admin', true, 'مدير مدرسة رسول الرحمة');
    END IF;
    
    IF noor_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin_noor' AND school_id = noor_id) THEN
        INSERT INTO users (username, password, password_hash, school_id, user_type, is_active, full_name)
        VALUES ('admin_noor', 'noor123', 'noor123', noor_id, 'school_admin', true, 'مدير مدرسة نور الرحمة');
    END IF;
    
    IF nabi_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin_nabi' AND school_id = nabi_id) THEN
        INSERT INTO users (username, password, password_hash, school_id, user_type, is_active, full_name)
        VALUES ('admin_nabi', 'nabi123', 'nabi123', nabi_id, 'school_admin', true, 'مدير مدرسة نبي الرحمة');
    END IF;
    
    IF thanawiya_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin_thanawiya' AND school_id = thanawiya_id) THEN
        INSERT INTO users (username, password, password_hash, school_id, user_type, is_active, full_name)
        VALUES ('admin_thanawiya', 'thanawiya123', 'thanawiya123', thanawiya_id, 'school_admin', true, 'مدير ثانوية رسول الرحمة');
    END IF;
    
    RAISE NOTICE 'تم إدراج مستخدمين المدارس بنجاح';
END $$;

-- إضافة حساب رئيس مجلس الإدارة (admin master)
INSERT INTO users (username, password, password_hash, school_id, user_type, is_active, full_name)
SELECT 
    'admin',
    'master123',
    'master123',
    NULL,
    'admin',
    true,
    'رئيس مجلس الإدارة'
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE username = 'admin' AND user_type = 'admin'
);

-- التحقق من النتيجة
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'schools' as table_name, COUNT(*) FROM schools
UNION ALL
SELECT 'admin users' as table_name, COUNT(*) FROM users WHERE user_type = 'admin';

