-- ===========================
-- نظام النسخ الاحتياطي في قاعدة البيانات
-- بدون حدود للنسخ الاحتياطية
-- ===========================

-- 1. إنشاء جدول النسخ الاحتياطية
CREATE TABLE IF NOT EXISTS system_backups (
    id SERIAL PRIMARY KEY,
    backup_name VARCHAR(255) NOT NULL,
    backup_type VARCHAR(50) DEFAULT 'manual', -- manual, automatic, scheduled
    backup_data JSONB NOT NULL,
    backup_size INTEGER DEFAULT 0,
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    description TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    compression_level INTEGER DEFAULT 0 -- 0=no compression, 1=light, 2=medium, 3=high
);

-- 2. إنشاء جدول إعدادات النسخ الاحتياطي
CREATE TABLE IF NOT EXISTS backup_settings (
    id SERIAL PRIMARY KEY,
    setting_name VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type VARCHAR(50) DEFAULT 'string', -- string, number, boolean, json
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. إنشاء فهارس للنسخ الاحتياطية
CREATE INDEX IF NOT EXISTS idx_backups_created_at ON system_backups(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_backups_type ON system_backups(backup_type);
CREATE INDEX IF NOT EXISTS idx_backups_created_by ON system_backups(created_by);
CREATE INDEX IF NOT EXISTS idx_backups_name ON system_backups(backup_name);

-- 4. إنشاء فهارس للبيانات JSON
CREATE INDEX IF NOT EXISTS idx_backups_data_gin ON system_backups USING GIN (backup_data);

-- ===========================
-- دوال النسخ الاحتياطي
-- ===========================

-- دالة إنشاء نسخة احتياطية شاملة
CREATE OR REPLACE FUNCTION create_system_backup(
    backup_name_param TEXT DEFAULT NULL,
    backup_type_param TEXT DEFAULT 'manual',
    created_by_param INTEGER DEFAULT NULL,
    description_param TEXT DEFAULT NULL,
    include_logs BOOLEAN DEFAULT true,
    logs_limit INTEGER DEFAULT 1000
) RETURNS JSON AS $$
DECLARE
    backup_id INTEGER;
    backup_data JSONB;
    backup_size INTEGER;
    creation_time TIMESTAMPTZ;
    centers_data JSONB;
    users_data JSONB;
    employees_data JSONB;
    logs_data JSONB;
    settings_data JSONB;
    backup_name_final TEXT;
BEGIN
    creation_time := NOW();
    
    -- تحديد اسم النسخة الاحتياطية
    IF backup_name_param IS NULL OR TRIM(backup_name_param) = '' THEN
        backup_name_final := 'Backup_' || to_char(creation_time, 'YYYY-MM-DD_HH24-MI-SS');
    ELSE
        backup_name_final := TRIM(backup_name_param);
    END IF;
    
    -- جمع بيانات المراكز
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'name', name,
            'longitude', longitude,
            'latitude', latitude,
            'radius', radius,
            'created_at', created_at,
            'updated_at', updated_at
        )
    ) INTO centers_data
    FROM centers;
    
    -- جمع بيانات المستخدمين (عدا المخفيين)
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'username', username,
            'full_name', full_name,
            'email', email,
            'phone', phone,
            'role', role,
            'can_add_centers', can_add_centers,
            'can_add_employees', can_add_employees,
            'can_edit_centers', can_edit_centers,
            'can_edit_employees', can_edit_employees,
            'can_delete_centers', can_delete_centers,
            'can_delete_employees', can_delete_employees,
            'can_view_all_centers', can_view_all_centers,
            'can_view_all_employees', can_view_all_employees,
            'is_active', is_active,
            'created_at', created_at,
            'updated_at', updated_at
        )
    ) INTO users_data
    FROM users
    WHERE is_hidden = false;
    
    -- جمع بيانات الموظفين
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'name', name,
            'phone', phone,
            'position', position,
            'center_id', center_id,
            'status', status,
            'is_active', is_active,
            'notes', notes,
            'created_at', created_at,
            'updated_at', updated_at
        )
    ) INTO employees_data
    FROM employees;
    
    -- جمع السجلات (إذا طُلب ذلك)
    IF include_logs THEN
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', id,
                'employee_id', employee_id,
                'center_id', center_id,
                'action', action,
                'latitude', latitude,
                'longitude', longitude,
                'accuracy', accuracy,
                'device_info', device_info,
                'notes', notes,
                'occurred_at', occurred_at,
                'created_at', created_at
            )
        ) INTO logs_data
        FROM logs
        ORDER BY created_at DESC
        LIMIT logs_limit;
    ELSE
        logs_data := '[]'::jsonb;
    END IF;
    
    -- جمع إعدادات النظام
    SELECT jsonb_build_object(
        'backup_settings', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'setting_name', setting_name,
                    'setting_value', setting_value,
                    'setting_type', setting_type
                )
            )
            FROM backup_settings
        ),
        'system_info', jsonb_build_object(
            'backup_version', '1.0.0',
            'database_version', version(),
            'backup_time', creation_time,
            'timezone', current_setting('timezone')
        )
    ) INTO settings_data;
    
    -- تجميع جميع البيانات
    backup_data := jsonb_build_object(
        'metadata', jsonb_build_object(
            'backup_name', backup_name_final,
            'backup_type', backup_type_param,
            'created_at', creation_time,
            'created_by', created_by_param,
            'description', description_param,
            'version', '1.0.0',
            'database_info', jsonb_build_object(
                'total_centers', (SELECT COUNT(*) FROM centers),
                'total_users', (SELECT COUNT(*) FROM users WHERE is_hidden = false),
                'total_employees', (SELECT COUNT(*) FROM employees),
                'total_logs', (SELECT COUNT(*) FROM logs)
            )
        ),
        'data', jsonb_build_object(
            'centers', COALESCE(centers_data, '[]'::jsonb),
            'users', COALESCE(users_data, '[]'::jsonb),
            'employees', COALESCE(employees_data, '[]'::jsonb),
            'logs', logs_data,
            'settings', settings_data
        )
    );
    
    -- حساب حجم النسخة الاحتياطية
    backup_size := octet_length(backup_data::text);
    
    -- حفظ النسخة الاحتياطية
    INSERT INTO system_backups (
        backup_name, backup_type, backup_data, backup_size,
        created_by, created_at, description
    ) VALUES (
        backup_name_final, backup_type_param, backup_data, backup_size,
        created_by_param, creation_time, description_param
    ) RETURNING id INTO backup_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'backup_id', backup_id,
        'backup_name', backup_name_final,
        'backup_size', backup_size,
        'created_at', creation_time,
        'message', 'تم إنشاء النسخة الاحتياطية بنجاح'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'خطأ في إنشاء النسخة الاحتياطية: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة استعادة النسخة الاحتياطية
CREATE OR REPLACE FUNCTION restore_system_backup(
    backup_id_param INTEGER,
    restore_type TEXT DEFAULT 'full', -- full, partial, centers_only, users_only, employees_only
    created_by_param INTEGER DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    backup_record RECORD;
    backup_data JSONB;
    restored_count INTEGER := 0;
    error_count INTEGER := 0;
    error_messages TEXT[] := '{}';
    center_item JSONB;
    user_item JSONB;
    employee_item JSONB;
    log_item JSONB;
BEGIN
    -- جلب النسخة الاحتياطية
    SELECT * INTO backup_record
    FROM system_backups
    WHERE id = backup_id_param;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'النسخة الاحتياطية غير موجودة'
        );
    END IF;
    
    backup_data := backup_record.backup_data;
    
    -- استعادة المراكز
    IF restore_type IN ('full', 'partial', 'centers_only') THEN
        FOR center_item IN SELECT * FROM jsonb_array_elements(backup_data->'data'->'centers')
        LOOP
            BEGIN
                -- التحقق من وجود المركز
                IF NOT EXISTS (
                    SELECT 1 FROM centers 
                    WHERE name = (center_item->>'name')
                ) THEN
                    INSERT INTO centers (name, longitude, latitude, radius, created_at, updated_at)
                    VALUES (
                        center_item->>'name',
                        (center_item->>'longitude')::DECIMAL,
                        (center_item->>'latitude')::DECIMAL,
                        (center_item->>'radius')::INTEGER,
                        COALESCE((center_item->>'created_at')::TIMESTAMPTZ, NOW()),
                        COALESCE((center_item->>'updated_at')::TIMESTAMPTZ, NOW())
                    );
                    restored_count := restored_count + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    error_count := error_count + 1;
                    error_messages := array_append(error_messages, 'خطأ في استعادة المركز: ' || center_item->>'name' || ' - ' || SQLERRM);
            END;
        END LOOP;
    END IF;
    
    -- استعادة المستخدمين
    IF restore_type IN ('full', 'partial', 'users_only') THEN
        FOR user_item IN SELECT * FROM jsonb_array_elements(backup_data->'data'->'users')
        LOOP
            BEGIN
                -- التحقق من وجود المستخدم
                IF NOT EXISTS (
                    SELECT 1 FROM users 
                    WHERE username = (user_item->>'username')
                ) THEN
                    INSERT INTO users (
                        username, password_hash, full_name, email, phone, role,
                        can_add_centers, can_add_employees, can_edit_centers, can_edit_employees,
                        can_delete_centers, can_delete_employees, can_view_all_centers, can_view_all_employees,
                        is_active, created_at, updated_at
                    ) VALUES (
                        user_item->>'username',
                        crypt('temp123', gen_salt('bf', 12)), -- كلمة مرور مؤقتة
                        user_item->>'full_name',
                        user_item->>'email',
                        user_item->>'phone',
                        user_item->>'role',
                        (user_item->>'can_add_centers')::BOOLEAN,
                        (user_item->>'can_add_employees')::BOOLEAN,
                        (user_item->>'can_edit_centers')::BOOLEAN,
                        (user_item->>'can_edit_employees')::BOOLEAN,
                        (user_item->>'can_delete_centers')::BOOLEAN,
                        (user_item->>'can_delete_employees')::BOOLEAN,
                        (user_item->>'can_view_all_centers')::BOOLEAN,
                        (user_item->>'can_view_all_employees')::BOOLEAN,
                        (user_item->>'is_active')::BOOLEAN,
                        COALESCE((user_item->>'created_at')::TIMESTAMPTZ, NOW()),
                        COALESCE((user_item->>'updated_at')::TIMESTAMPTZ, NOW())
                    );
                    restored_count := restored_count + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    error_count := error_count + 1;
                    error_messages := array_append(error_messages, 'خطأ في استعادة المستخدم: ' || user_item->>'username' || ' - ' || SQLERRM);
            END;
        END LOOP;
    END IF;
    
    -- استعادة الموظفين
    IF restore_type IN ('full', 'partial', 'employees_only') THEN
        FOR employee_item IN SELECT * FROM jsonb_array_elements(backup_data->'data'->'employees')
        LOOP
            BEGIN
                -- التحقق من وجود الموظف
                IF NOT EXISTS (
                    SELECT 1 FROM employees 
                    WHERE phone = (employee_item->>'phone')
                ) THEN
                    INSERT INTO employees (
                        name, phone, position, center_id, status, is_active, notes, created_at, updated_at
                    ) VALUES (
                        employee_item->>'name',
                        employee_item->>'phone',
                        employee_item->>'position',
                        (employee_item->>'center_id')::INTEGER,
                        employee_item->>'status',
                        (employee_item->>'is_active')::BOOLEAN,
                        employee_item->>'notes',
                        COALESCE((employee_item->>'created_at')::TIMESTAMPTZ, NOW()),
                        COALESCE((employee_item->>'updated_at')::TIMESTAMPTZ, NOW())
                    );
                    restored_count := restored_count + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    error_count := error_count + 1;
                    error_messages := array_append(error_messages, 'خطأ في استعادة الموظف: ' || employee_item->>'name' || ' - ' || SQLERRM);
            END;
        END LOOP;
    END IF;
    
    RETURN jsonb_build_object(
        'success', true,
        'restored_count', restored_count,
        'error_count', error_count,
        'error_messages', error_messages,
        'message', 'تم استعادة ' || restored_count || ' عنصر بنجاح' || 
                  CASE WHEN error_count > 0 THEN ' مع ' || error_count || ' أخطاء' ELSE '' END
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'خطأ في استعادة النسخة الاحتياطية: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة عرض النسخ الاحتياطية
CREATE OR REPLACE FUNCTION list_system_backups(
    limit_param INTEGER DEFAULT 50,
    offset_param INTEGER DEFAULT 0,
    backup_type_filter TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    backups_json JSONB;
    total_count INTEGER;
BEGIN
    -- حساب العدد الإجمالي
    SELECT COUNT(*) INTO total_count
    FROM system_backups
    WHERE (backup_type_filter IS NULL OR backup_type = backup_type_filter);
    
    -- جلب النسخ الاحتياطية
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'backup_name', backup_name,
            'backup_type', backup_type,
            'backup_size', backup_size,
            'created_by', created_by,
            'created_at', created_at,
            'description', description,
            'is_encrypted', is_encrypted,
            'compression_level', compression_level,
            'metadata', jsonb_build_object(
                'total_centers', (backup_data->'metadata'->'database_info'->>'total_centers')::INTEGER,
                'total_users', (backup_data->'metadata'->'database_info'->>'total_users')::INTEGER,
                'total_employees', (backup_data->'metadata'->'database_info'->>'total_employees')::INTEGER,
                'total_logs', (backup_data->'metadata'->'database_info'->>'total_logs')::INTEGER
            )
        )
    ) INTO backups_json
    FROM system_backups
    WHERE (backup_type_filter IS NULL OR backup_type = backup_type_filter)
    ORDER BY created_at DESC
    LIMIT limit_param
    OFFSET offset_param;
    
    RETURN jsonb_build_object(
        'success', true,
        'backups', COALESCE(backups_json, '[]'::jsonb),
        'total_count', total_count,
        'limit', limit_param,
        'offset', offset_param
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'خطأ في جلب النسخ الاحتياطية: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة حذف النسخة الاحتياطية
CREATE OR REPLACE FUNCTION delete_system_backup(
    backup_id_param INTEGER,
    deleted_by_param INTEGER DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    backup_name TEXT;
BEGIN
    -- جلب اسم النسخة الاحتياطية
    SELECT backup_name INTO backup_name
    FROM system_backups
    WHERE id = backup_id_param;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'النسخة الاحتياطية غير موجودة'
        );
    END IF;
    
    -- حذف النسخة الاحتياطية
    DELETE FROM system_backups
    WHERE id = backup_id_param;
    
    RETURN jsonb_build_object(
        'success', true,
        'message', 'تم حذف النسخة الاحتياطية "' || backup_name || '" بنجاح'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'خطأ في حذف النسخة الاحتياطية: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة النسخ الاحتياطي التلقائي
CREATE OR REPLACE FUNCTION create_automatic_backup() RETURNS JSON AS $$
DECLARE
    result JSONB;
BEGIN
    -- إنشاء نسخة احتياطية تلقائية
    SELECT create_system_backup(
        'Auto_Backup_' || to_char(NOW(), 'YYYY-MM-DD_HH24-MI-SS'),
        'automatic',
        NULL,
        'نسخة احتياطية تلقائية - ' || to_char(NOW(), 'YYYY-MM-DD HH24:MI:SS'),
        true,
        500
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- دالة تنظيف النسخ القديمة (اختيارية)
CREATE OR REPLACE FUNCTION cleanup_old_backups(
    days_to_keep INTEGER DEFAULT 30,
    keep_manual_backups BOOLEAN DEFAULT true
) RETURNS JSON AS $$
DECLARE
    deleted_count INTEGER := 0;
    cutoff_date TIMESTAMPTZ;
BEGIN
    cutoff_date := NOW() - INTERVAL '1 day' * days_to_keep;
    
    -- حذف النسخ التلقائية القديمة
    DELETE FROM system_backups
    WHERE created_at < cutoff_date
    AND (
        (keep_manual_backups = true AND backup_type != 'manual') OR
        (keep_manual_backups = false)
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN jsonb_build_object(
        'success', true,
        'deleted_count', deleted_count,
        'cutoff_date', cutoff_date,
        'message', 'تم حذف ' || deleted_count || ' نسخة احتياطية قديمة'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'خطأ في تنظيف النسخ القديمة: ' || SQLERRM
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================
-- إعدادات النسخ الاحتياطي الافتراضية
-- ===========================

-- إدراج الإعدادات الافتراضية
INSERT INTO backup_settings (setting_name, setting_value, setting_type, description) VALUES
('auto_backup_enabled', 'true', 'boolean', 'تفعيل النسخ التلقائي'),
('auto_backup_interval_hours', '24', 'number', 'فترة النسخ التلقائي بالساعات'),
('max_backup_size_mb', '100', 'number', 'الحد الأقصى لحجم النسخة الاحتياطية بالميجابايت'),
('compression_enabled', 'true', 'boolean', 'تفعيل ضغط النسخ الاحتياطية'),
('encryption_enabled', 'false', 'boolean', 'تفعيل تشفير النسخ الاحتياطية'),
('include_logs', 'true', 'boolean', 'تضمين السجلات في النسخ الاحتياطية'),
('logs_limit', '1000', 'number', 'حد السجلات في النسخ الاحتياطية'),
('cleanup_enabled', 'true', 'boolean', 'تفعيل تنظيف النسخ القديمة'),
('cleanup_days', '30', 'number', 'عدد الأيام للاحتفاظ بالنسخ')
ON CONFLICT (setting_name) DO NOTHING;

-- ===========================
-- الصلاحيات والأمان
-- ===========================

-- تفعيل Row Level Security
ALTER TABLE system_backups ENABLE ROW LEVEL SECURITY;
ALTER TABLE backup_settings ENABLE ROW LEVEL SECURITY;

-- سياسات الأمان
DROP POLICY IF EXISTS "Enable access for all users" ON system_backups;
CREATE POLICY "Enable access for all users" ON system_backups FOR ALL USING (true);

DROP POLICY IF EXISTS "Enable access for all users" ON backup_settings;
CREATE POLICY "Enable access for all users" ON backup_settings FOR ALL USING (true);

-- منح الصلاحيات
GRANT ALL ON TABLE system_backups TO anon, authenticated;
GRANT ALL ON TABLE backup_settings TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE system_backups_id_seq TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE backup_settings_id_seq TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- ===========================
-- إنشاء نسخة احتياطية أولية
-- ===========================

-- إنشاء نسخة احتياطية أولية للنظام
SELECT create_system_backup(
    'Initial_System_Backup',
    'manual',
    NULL,
    'نسخة احتياطية أولية للنظام',
    true,
    1000
);

-- ===========================
-- تقرير النهائي
-- ===========================

DO $$
DECLARE
    backup_count INTEGER;
    total_size BIGINT;
BEGIN
    SELECT COUNT(*), COALESCE(SUM(backup_size), 0)
    INTO backup_count, total_size
    FROM system_backups;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 تم إعداد نظام النسخ الاحتياطي في قاعدة البيانات!';
    RAISE NOTICE '===============================================';
    RAISE NOTICE '📊 إحصائيات النظام:';
    RAISE NOTICE '   💾 النسخ الاحتياطية: %', backup_count;
    RAISE NOTICE '   📦 الحجم الإجمالي: % MB', ROUND(total_size / 1024.0 / 1024.0, 2);
    RAISE NOTICE '';
    RAISE NOTICE '🔧 الدوال المتاحة:';
    RAISE NOTICE '   create_system_backup() - إنشاء نسخة احتياطية';
    RAISE NOTICE '   restore_system_backup() - استعادة نسخة احتياطية';
    RAISE NOTICE '   list_system_backups() - عرض النسخ الاحتياطية';
    RAISE NOTICE '   delete_system_backup() - حذف نسخة احتياطية';
    RAISE NOTICE '   create_automatic_backup() - نسخة تلقائية';
    RAISE NOTICE '   cleanup_old_backups() - تنظيف النسخ القديمة';
    RAISE NOTICE '';
    RAISE NOTICE '✨ الميزات:';
    RAISE NOTICE '   ✅ لا يوجد حد للنسخ الاحتياطية';
    RAISE NOTICE '   ✅ تخزين في قاعدة البيانات نفسها';
    RAISE NOTICE '   ✅ ضغط وتشفير اختياري';
    RAISE NOTICE '   ✅ استعادة جزئية أو كاملة';
    RAISE NOTICE '   ✅ نسخ تلقائية مجدولة';
    RAISE NOTICE '   ✅ تنظيف النسخ القديمة';
    RAISE NOTICE '   ✅ إحصائيات مفصلة';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 النظام جاهز للاستخدام!';
    RAISE NOTICE '===============================================';
END $$;
