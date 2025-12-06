-- حذف جميع المستخدمين من قاعدة البيانات
-- قم بتنفيذ هذا في Supabase SQL Editor

-- حذف جميع المستخدمين
DELETE FROM users;

-- التأكد من الحذف
SELECT 'users' as table_name, COUNT(*) as count FROM users;

