-- ============================================
-- Reset Schema - حذف الجداول القديمة وإعادة إنشائها
-- ============================================
-- استخدم هذا الملف إذا واجهت مشاكل في أنواع البيانات

-- حذف الجداول بالترتيب الصحيح (حذف الجداول التي تعتمد على غيرها أولاً)
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS schools CASCADE;

-- الآن نفذ ملف supabase_schema.sql بعد هذا

