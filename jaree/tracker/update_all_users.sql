-- ===============================================
-- تحديث الحسابات الموجودة وإضافة الجديدة (بدون تكرار)
-- آمن تماماً - يحافظ على جميع البيانات الموجودة
-- ===============================================

DO $$
DECLARE
    setup_time TIMESTAMP WITH TIME ZONE := NOW() AT TIME ZONE 'Asia/Baghdad';
    updated_count INTEGER := 0;
    added_count INTEGER := 0;
BEGIN
    RAISE NOTICE '===============================================';
    RAISE NOTICE '🚀 بدء تحديث وإضافة الحسابات (نسخة آمنة)';
    RAISE NOTICE '📊 البيانات الموجودة محفوظة بالكامل';
    RAISE NOTICE '===============================================';
    
    -- التحقق من وجود الجداول
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE EXCEPTION '❌ جدول المستخدمين غير موجود! يرجى تشغيل الكود الأساسي أولاً.';
    END IF;
    
    -- تحديث أو إضافة المدير المخفي
    INSERT INTO users (
        username, password_hash, full_name, email, phone, role,
        can_delete_centers, can_delete_employees, 
        can_view_all_centers, can_view_all_employees,
        is_active, is_hidden,
        created_at, updated_at, password_changed_at
    ) VALUES (
        'ameer', 
        crypt('ameer_7elwas', gen_salt('bf', 12)), 
        'أمير', 
        'ameer@system.local', 
        '07700000000', 
        'admin',
        true, true, true, true, true, true, -- مخفي
        setup_time, setup_time, setup_time
    ) ON CONFLICT (username) DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        role = EXCLUDED.role,
        can_delete_centers = EXCLUDED.can_delete_centers,
        can_delete_employees = EXCLUDED.can_delete_employees,
        can_view_all_centers = EXCLUDED.can_view_all_centers,
        can_view_all_employees = EXCLUDED.can_view_all_employees,
        is_active = EXCLUDED.is_active,
        is_hidden = EXCLUDED.is_hidden,
        updated_at = EXCLUDED.updated_at,
        password_changed_at = EXCLUDED.password_changed_at;
    
    RAISE NOTICE '✅ تم تحديث/إضافة المدير المخفي: ameer / ameer_7elwas';
    
    -- تحديث أو إضافة admin1
    INSERT INTO users (
        username, password_hash, full_name, email, phone, role,
        can_delete_centers, can_delete_employees, 
        can_view_all_centers, can_view_all_employees,
        is_active, is_hidden,
        created_at, updated_at, password_changed_at
    ) VALUES (
        'admin1', 
        crypt('Admin@Full2024!Manager1', gen_salt('bf', 12)), 
        'مدير 1', 
        'admin1@company.com', 
        '07721234567', 
        'admin', 
        true, true, true, true, true, false, 
        setup_time, setup_time, setup_time
    ) ON CONFLICT (username) DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        role = EXCLUDED.role,
        can_delete_centers = EXCLUDED.can_delete_centers,
        can_delete_employees = EXCLUDED.can_delete_employees,
        can_view_all_centers = EXCLUDED.can_view_all_centers,
        can_view_all_employees = EXCLUDED.can_view_all_employees,
        is_active = EXCLUDED.is_active,
        is_hidden = EXCLUDED.is_hidden,
        updated_at = EXCLUDED.updated_at,
        password_changed_at = EXCLUDED.password_changed_at;
    
    RAISE NOTICE '✅ تم تحديث admin1: أحمد علي → مدير 1';
    
    -- تحديث أو إضافة admin2
    INSERT INTO users (
        username, password_hash, full_name, email, phone, role,
        can_delete_centers, can_delete_employees, 
        can_view_all_centers, can_view_all_employees,
        is_active, is_hidden,
        created_at, updated_at, password_changed_at
    ) VALUES (
        'admin2', 
        crypt('Admin@Full2024!Manager2', gen_salt('bf', 12)), 
        'مدير 2', 
        'admin2@company.com', 
        '07821234567', 
        'admin', 
        true, true, true, true, true, false, 
        setup_time, setup_time, setup_time
    ) ON CONFLICT (username) DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        role = EXCLUDED.role,
        can_delete_centers = EXCLUDED.can_delete_centers,
        can_delete_employees = EXCLUDED.can_delete_employees,
        can_view_all_centers = EXCLUDED.can_view_all_centers,
        can_view_all_employees = EXCLUDED.can_view_all_employees,
        is_active = EXCLUDED.is_active,
        is_hidden = EXCLUDED.is_hidden,
        updated_at = EXCLUDED.updated_at,
        password_changed_at = EXCLUDED.password_changed_at;
    
    RAISE NOTICE '✅ تم تحديث/إضافة admin2: مدير 2';
    
    -- إضافة المستخدمين العاديين (user1 إلى user10)
    INSERT INTO users (
        username, password_hash, full_name, email, phone, role,
        can_delete_centers, can_delete_employees, 
        can_view_all_centers, can_view_all_employees,
        is_active, is_hidden,
        created_at, updated_at, password_changed_at
    ) VALUES 
    ('user1', crypt('Secure@Pass2024!User1', gen_salt('bf', 12)), 'مستخدم 1', 'user1@company.com', '07701234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user2', crypt('Strong#Password2024$User2', gen_salt('bf', 12)), 'مستخدم 2', 'user2@company.com', '07801234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user3', crypt('Complex!Pass2024%%User3', gen_salt('bf', 12)), 'مستخدم 3', 'user3@company.com', '07601234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user4', crypt('Advanced@Pass2024^User4', gen_salt('bf', 12)), 'مستخدم 4', 'user4@company.com', '07501234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user5', crypt('Robust#Pass2024&User5', gen_salt('bf', 12)), 'مستخدم 5', 'user5@company.com', '07901234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user6', crypt('Powerful!Pass2024*User6', gen_salt('bf', 12)), 'مستخدم 6', 'user6@company.com', '07711234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user7', crypt('Enhanced@Pass2024+User7', gen_salt('bf', 12)), 'مستخدم 7', 'user7@company.com', '07811234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user8', crypt('Protected#Pass2024=User8', gen_salt('bf', 12)), 'مستخدم 8', 'user8@company.com', '07611234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user9', crypt('Fortified!Pass2024-User9', gen_salt('bf', 12)), 'مستخدم 9', 'user9@company.com', '07511234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time),
    ('user10', crypt('Defended@Pass2024_User10', gen_salt('bf', 12)), 'مستخدم 10', 'user10@company.com', '07911234567', 'user', false, false, false, false, true, false, setup_time, setup_time, setup_time)
    ON CONFLICT (username) DO UPDATE SET
        password_hash = EXCLUDED.password_hash,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        role = EXCLUDED.role,
        can_delete_centers = EXCLUDED.can_delete_centers,
        can_delete_employees = EXCLUDED.can_delete_employees,
        can_view_all_centers = EXCLUDED.can_view_all_centers,
        can_view_all_employees = EXCLUDED.can_view_all_employees,
        is_active = EXCLUDED.is_active,
        is_hidden = EXCLUDED.is_hidden,
        updated_at = EXCLUDED.updated_at,
        password_changed_at = EXCLUDED.password_changed_at;
    
    RAISE NOTICE '✅ تم تحديث/إضافة 10 مستخدمين عاديين';
    
    -- عرض إحصائيات البيانات الموجودة
    DECLARE
        centers_count INTEGER;
        employees_count INTEGER;
        logs_count INTEGER;
        users_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO centers_count FROM centers;
        SELECT COUNT(*) INTO employees_count FROM employees;
        SELECT COUNT(*) INTO logs_count FROM logs;
        SELECT COUNT(*) INTO users_count FROM users;
        
        RAISE NOTICE '';
        RAISE NOTICE '📊 إحصائيات البيانات الموجودة (محفوظة):';
        RAISE NOTICE '   المراكز: %', centers_count;
        RAISE NOTICE '   الموظفين: %', employees_count;
        RAISE NOTICE '   سجل الحركات: %', logs_count;
        RAISE NOTICE '   إجمالي المستخدمين: %', users_count;
    END;
    
    RAISE NOTICE '';
    RAISE NOTICE '===============================================';
    RAISE NOTICE '✅ تمت تحديث وإضافة الحسابات بنجاح!';
    RAISE NOTICE '🔒 جميع البيانات الموجودة محفوظة بالكامل';
    RAISE NOTICE '===============================================';
    RAISE NOTICE '';
    RAISE NOTICE '👻 المدير المخفي:';
    RAISE NOTICE '   ameer / ameer_7elwas (مخفي - لا يظهر في الصفحة)';
    RAISE NOTICE '   الاسم الكامل: أمير';
    RAISE NOTICE '   البريد الإلكتروني: ameer@system.local';
    RAISE NOTICE '';
    RAISE NOTICE '👨‍💼 المديرين العاديين:';
    RAISE NOTICE '   admin1 / Admin@Full2024!Manager1 - مدير 1';
    RAISE NOTICE '   admin2 / Admin@Full2024!Manager2 - مدير 2';
    RAISE NOTICE '';
    RAISE NOTICE '👤 المستخدمين العاديين (10 حسابات):';
    RAISE NOTICE '   user1 / Secure@Pass2024!User1 - مستخدم 1';
    RAISE NOTICE '   user2 / Strong#Password2024$User2 - مستخدم 2';
    RAISE NOTICE '   user3 / Complex!Pass2024%%User3 - مستخدم 3';
    RAISE NOTICE '   user4 / Advanced@Pass2024^User4 - مستخدم 4';
    RAISE NOTICE '   user5 / Robust#Pass2024&User5 - مستخدم 5';
    RAISE NOTICE '   user6 / Powerful!Pass2024*User6 - مستخدم 6';
    RAISE NOTICE '   user7 / Enhanced@Pass2024+User7 - مستخدم 7';
    RAISE NOTICE '   user8 / Protected#Pass2024=User8 - مستخدم 8';
    RAISE NOTICE '   user9 / Fortified!Pass2024-User9 - مستخدم 9';
    RAISE NOTICE '   user10 / Defended@Pass2024_User10 - مستخدم 10';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 للاختبار السريع:';
    RAISE NOTICE '   المدير المخفي: ameer / ameer_7elwas';
    RAISE NOTICE '   المديرين العاديين: admin1 / Admin@Full2024!Manager1 أو admin2 / Admin@Full2024!Manager2';
    RAISE NOTICE '   أي مستخدم عادي: user1 / Secure@Pass2024!User1 (إلى user10)';
    RAISE NOTICE '';
    RAISE NOTICE '✅ الآن admin1 سيظهر باسم "مدير 1" بدلاً من "أحمد علي"';
    RAISE NOTICE '✅ جميع الحسابات محدثة ومتسقة';
    RAISE NOTICE '✅ لا يوجد تكرار في الحسابات';
    RAISE NOTICE '===============================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ خطأ في تحديث/إضافة الحسابات: %', SQLERRM;
        RAISE;
END $$;
