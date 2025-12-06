-- ============================================
-- Supabase Schema for رسول الرحمة System
-- Professional & Secure Database Schema
-- ============================================

-- Extension for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- ENUMS
-- ============================================
-- إنشاء الأنواع فقط إذا لم تكن موجودة
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_status') THEN
        CREATE TYPE payment_status AS ENUM ('unpaid', 'partial', 'paid');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method_type') THEN
        CREATE TYPE payment_method_type AS ENUM ('cash', 'bank_transfer', 'check', 'other');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM ('info', 'success', 'warning', 'error');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('admin', 'school_admin', 'user');
    END IF;
END $$;

-- ============================================
-- TABLES
-- ============================================

-- جدول المدارس
-- ملاحظة: إذا كان الجدول موجوداً مسبقاً بـ UUID، سيتم استخدام التعريف الموجود
CREATE TABLE IF NOT EXISTS schools (
    id TEXT PRIMARY KEY CHECK (id ~ '^[a-z0-9_]+$'),
    name TEXT NOT NULL CHECK (LENGTH(name) >= 2 AND LENGTH(name) <= 200),
    code TEXT UNIQUE,
    address TEXT,
    phone TEXT CHECK (phone IS NULL OR phone ~ '^[0-9+\-\s()]+$'),
    email TEXT CHECK (email IS NULL OR email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    is_active BOOLEAN DEFAULT TRUE,
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT schools_name_unique UNIQUE (name)
);

-- جدول الطلاب
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL CHECK (LENGTH(TRIM(name)) >= 2 AND LENGTH(name) <= 200),
    guardian_name TEXT NOT NULL CHECK (LENGTH(TRIM(guardian_name)) >= 2 AND LENGTH(guardian_name) <= 200),
    mother_name TEXT NOT NULL CHECK (LENGTH(TRIM(mother_name)) >= 2 AND LENGTH(mother_name) <= 200),
    grade TEXT NOT NULL CHECK (LENGTH(grade) >= 1 AND LENGTH(grade) <= 50),
    phone TEXT CHECK (phone IS NULL OR (LENGTH(phone) >= 8 AND phone ~ '^[0-9+\-\s()]+$')),
    school_id TEXT NOT NULL REFERENCES schools(id) ON DELETE RESTRICT,
    annual_fee NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (annual_fee >= 0),
    final_fee NUMERIC(15, 2) NOT NULL DEFAULT 0 CHECK (final_fee >= 0),
    has_sibling BOOLEAN DEFAULT FALSE,
    discount_amount NUMERIC(15, 2) DEFAULT 0 CHECK (discount_amount >= 0),
    discount_percentage NUMERIC(5, 2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    receipt_number TEXT UNIQUE CHECK (receipt_number IS NULL OR LENGTH(receipt_number) >= 1),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT CHECK (notes IS NULL OR LENGTH(notes) <= 1000),
    installments JSONB DEFAULT '[]'::jsonb,
    status payment_status DEFAULT 'unpaid',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by TEXT,
    updated_by TEXT,
    CONSTRAINT students_final_fee_check CHECK (final_fee <= annual_fee),
    CONSTRAINT students_discount_check CHECK (discount_amount <= annual_fee)
);

-- جدول المستخدمين (محسّن)
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL CHECK (LENGTH(username) >= 3 AND LENGTH(username) <= 50 AND username ~ '^[a-z0-9_]+$'),
    password_hash TEXT NOT NULL CHECK (LENGTH(password_hash) >= 60), -- bcrypt hash length
    email TEXT CHECK (email IS NULL OR email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    full_name TEXT CHECK (full_name IS NULL OR LENGTH(full_name) <= 200),
    school_id TEXT REFERENCES schools(id) ON DELETE SET NULL,
    role user_role DEFAULT 'user',
    is_admin BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    login_count INTEGER DEFAULT 0,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by BIGINT REFERENCES users(id),
    CONSTRAINT users_admin_check CHECK (
        (is_admin = TRUE AND school_id IS NULL) OR 
        (is_admin = FALSE)
    )
);

-- جدول الرسائل (محسّن)
-- ملاحظة: sender_id و receiver_id من نوع TEXT (للمدارس)
-- ملاحظة: العمود message بدلاً من message_text للتوافق مع الكود
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id TEXT NOT NULL CHECK (LENGTH(sender_id) >= 1),
    sender_name TEXT NOT NULL CHECK (LENGTH(sender_name) >= 2),
    receiver_id TEXT CHECK (receiver_id IS NULL OR LENGTH(receiver_id) >= 1),
    receiver_name TEXT CHECK (receiver_name IS NULL OR LENGTH(receiver_name) >= 2),
    message TEXT NOT NULL CHECK (LENGTH(TRIM(message)) >= 1 AND LENGTH(message) <= 5000),
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT messages_sender_receiver_check CHECK (sender_id != receiver_id OR receiver_id IS NULL)
);

-- إذا كانت قاعدة البيانات تستخدم message_text بدلاً من message، قم بتشغيل هذا:
-- ALTER TABLE messages RENAME COLUMN message_text TO message;

-- إذا كانت قاعدة البيانات تستخدم UUID لـ sender_id و receiver_id، قم بتشغيل هذا:
-- ALTER TABLE messages ALTER COLUMN sender_id TYPE TEXT USING sender_id::TEXT;
-- ALTER TABLE messages ALTER COLUMN receiver_id TYPE TEXT USING receiver_id::TEXT;

-- جدول الإشعارات (محسّن)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    school_id TEXT REFERENCES schools(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (LENGTH(TRIM(title)) >= 1 AND LENGTH(title) <= 200),
    message TEXT NOT NULL CHECK (LENGTH(TRIM(message)) >= 1 AND LENGTH(message) <= 2000),
    type notification_type DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    action_url TEXT CHECK (action_url IS NULL OR LENGTH(action_url) <= 500),
    metadata JSONB DEFAULT '{}'::jsonb,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT notifications_target_check CHECK (user_id IS NOT NULL OR school_id IS NOT NULL)
);

-- جدول المدفوعات (سجل الدفعات - محسّن)
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    installment_number INTEGER NOT NULL CHECK (installment_number >= 1 AND installment_number <= 12),
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method payment_method_type NOT NULL DEFAULT 'cash',
    receipt_number TEXT UNIQUE CHECK (receipt_number IS NULL OR LENGTH(receipt_number) >= 1),
    notes TEXT CHECK (notes IS NULL OR LENGTH(notes) <= 1000),
    created_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT payments_date_check CHECK (payment_date <= CURRENT_DATE)
);

-- جدول سجل الأنشطة (Audit Trail)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name TEXT NOT NULL,
    record_id TEXT, -- تم تغييره من UUID إلى TEXT ليقبل أنواع مختلفة (UUID, BIGINT, إلخ)
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    user_id BIGINT REFERENCES users(id),
    user_name TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول الإعدادات العامة
CREATE TABLE IF NOT EXISTS system_settings (
    key TEXT PRIMARY KEY CHECK (key ~ '^[a-z0-9_]+$'),
    value JSONB NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    is_public BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by BIGINT REFERENCES users(id)
);

-- ============================================
-- INDEXES (محسّنة للأداء)
-- ============================================

-- Indexes للطلاب
CREATE INDEX IF NOT EXISTS idx_students_school_id ON students(school_id);
CREATE INDEX IF NOT EXISTS idx_students_name ON students(name);
-- ملاحظة: تم إزالة فهارس guardian_name و mother_name لأن الأعمدة قد لا تكون موجودة في قاعدة البيانات
-- CREATE INDEX IF NOT EXISTS idx_students_guardian_name ON students(guardian_name);
-- CREATE INDEX IF NOT EXISTS idx_students_mother_name ON students(mother_name);
CREATE INDEX IF NOT EXISTS idx_students_receipt_number ON students(receipt_number) WHERE receipt_number IS NOT NULL;
-- ملاحظة: تم إزالة فهرس status لأن العمود قد لا يكون موجوداً في قاعدة البيانات
-- CREATE INDEX IF NOT EXISTS idx_students_status ON students(status);
CREATE INDEX IF NOT EXISTS idx_students_registration_date ON students(registration_date);
CREATE INDEX IF NOT EXISTS idx_students_created_at ON students(created_at DESC);

-- Indexes للمستخدمين
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_school_id ON users(school_id) WHERE school_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
-- ملاحظة: تم إزالة فهرس is_admin لأن العمود قد لا يكون موجوداً في قاعدة البيانات
-- CREATE INDEX IF NOT EXISTS idx_users_is_admin ON users(is_admin) WHERE is_admin = TRUE;

-- Indexes للرسائل
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id) WHERE receiver_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON messages(is_read) WHERE is_read = FALSE;

-- Indexes للإشعارات
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_school_id ON notifications(school_id) WHERE school_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read) WHERE is_read = FALSE;

-- Indexes للمدفوعات
CREATE INDEX IF NOT EXISTS idx_payments_student_id ON payments(student_id);
CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON payments(payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_payments_receipt_number ON payments(receipt_number) WHERE receipt_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);

-- Indexes لسجل الأنشطة
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_record_id ON audit_logs(record_id) WHERE record_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function لتسجيل الأنشطة
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_data, user_id, user_name)
        VALUES (TG_TABLE_NAME, CAST(OLD.id AS TEXT), TG_OP, row_to_json(OLD), NULL, 'system');
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data, user_id, user_name)
        VALUES (TG_TABLE_NAME, CAST(NEW.id AS TEXT), TG_OP, row_to_json(OLD), row_to_json(NEW), NULL, 'system');
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (table_name, record_id, action, new_data, user_id, user_name)
        VALUES (TG_TABLE_NAME, CAST(NEW.id AS TEXT), TG_OP, row_to_json(NEW), NULL, 'system');
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function لتشفير كلمة المرور
CREATE OR REPLACE FUNCTION hash_password(password TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN crypt(password, gen_salt('bf', 10));
END;
$$ LANGUAGE plpgsql;

-- Function للتحقق من كلمة المرور
CREATE OR REPLACE FUNCTION verify_password(password TEXT, hash TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN hash = crypt(password, hash);
END;
$$ LANGUAGE plpgsql;

-- Function لحساب حالة الطالب المالية
CREATE OR REPLACE FUNCTION calculate_student_status(student_uuid UUID)
RETURNS payment_status AS $$
DECLARE
    total_paid NUMERIC;
    final_fee_amount NUMERIC;
    installments_data JSONB;
BEGIN
    SELECT final_fee, installments INTO final_fee_amount, installments_data
    FROM students WHERE id = student_uuid;
    
    IF installments_data IS NULL OR jsonb_array_length(installments_data) = 0 THEN
        RETURN 'unpaid';
    END IF;
    
    SELECT COALESCE(SUM((value->>'amount_paid')::NUMERIC), 0)
    INTO total_paid
    FROM jsonb_array_elements(installments_data) AS value;
    
    IF total_paid >= final_fee_amount THEN
        RETURN 'paid';
    ELSIF total_paid > 0 THEN
        RETURN 'partial';
    ELSE
        RETURN 'unpaid';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Triggers لتحديث updated_at
DROP TRIGGER IF EXISTS update_schools_updated_at ON schools;
CREATE TRIGGER update_schools_updated_at BEFORE UPDATE ON schools
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_students_updated_at ON students;
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_system_settings_updated_at ON system_settings;
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON system_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Triggers لتحديث حالة الطالب تلقائياً
-- ملاحظة: تم تعليق TRIGGER status لأن العمود قد لا يكون موجوداً في قاعدة البيانات
-- CREATE OR REPLACE FUNCTION update_student_status()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     UPDATE students 
--     SET status = calculate_student_status(NEW.student_id),
--         updated_at = NOW()
--     WHERE id = NEW.student_id;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER update_student_status_on_payment AFTER INSERT OR UPDATE ON payments
--     FOR EACH ROW EXECUTE FUNCTION update_student_status();

-- Triggers لتسجيل الأنشطة
DROP TRIGGER IF EXISTS audit_students ON students;
CREATE TRIGGER audit_students AFTER INSERT OR UPDATE OR DELETE ON students
    FOR EACH ROW EXECUTE FUNCTION log_audit();

DROP TRIGGER IF EXISTS audit_users ON users;
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION log_audit();

DROP TRIGGER IF EXISTS audit_payments ON payments;
CREATE TRIGGER audit_payments AFTER INSERT OR UPDATE OR DELETE ON payments
    FOR EACH ROW EXECUTE FUNCTION log_audit();

-- ============================================
-- INITIAL DATA
-- ============================================

-- إدراج البيانات الأولية للمدارس
-- ملاحظة: إذا كان جدول schools يستخدم UUID بدلاً من TEXT، سيتم تخطي هذا القسم
-- يمكنك إدراج البيانات يدوياً باستخدام UUIDs
DO $$
BEGIN
    -- التحقق من نوع عمود id في جدول schools
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'schools' 
        AND column_name = 'id' 
        AND data_type = 'text'
    ) THEN
        -- إذا كان النوع TEXT، قم بإدراج البيانات
        INSERT INTO schools (id, name, code, is_active) VALUES
            ('rawda', 'روضة رسول الرحمة', 'RAWDA', TRUE),
            ('rasoul', 'مدرسة رسول الرحمة', 'RASOUL', TRUE),
            ('noor', 'مدرسة نور الرحمة', 'NOOR', TRUE),
            ('nabi', 'مدرسة نبي الرحمة', 'NABI', TRUE),
            ('thanawiya', 'ثانوية رسول الرحمة', 'THANAWIYA', TRUE)
        ON CONFLICT (id) DO UPDATE SET 
            name = EXCLUDED.name,
            code = EXCLUDED.code,
            updated_at = NOW();
    ELSE
        -- إذا كان النوع UUID، تخطي الإدراج
        RAISE NOTICE 'جدول schools يستخدم UUID - تم تخطي إدراج البيانات الأولية';
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- في حالة أي خطأ، تخطي الإدراج
    RAISE NOTICE 'تم تخطي إدراج البيانات الأولية للمدارس: %', SQLERRM;
END $$;

-- إدراج المستخدم الافتراضي للمدير (كلمة المرور: master123)
INSERT INTO users (username, password_hash, role, full_name) VALUES
    ('admin', crypt('master123', gen_salt('bf', 10)), 'admin', 'مدير النظام')
ON CONFLICT (username) DO UPDATE SET 
    password_hash = crypt('master123', gen_salt('bf', 10)),
    updated_at = NOW();

-- إدراج المستخدمين الافتراضيين للمدارس
-- ملاحظة: إذا كان school_id من نوع UUID، سيتم تخطي هذا القسم
DO $$
BEGIN
    -- التحقق من نوع عمود school_id في جدول users
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'school_id' 
        AND data_type = 'text'
    ) THEN
        -- إذا كان النوع TEXT، قم بإدراج البيانات
        INSERT INTO users (username, password_hash, school_id, role, full_name) VALUES
            ('rawda', crypt('rawda123', gen_salt('bf', 10)), 'rawda', 'school_admin', 'مدير روضة رسول الرحمة'),
            ('rasoul', crypt('rasoul123', gen_salt('bf', 10)), 'rasoul', 'school_admin', 'مدير مدرسة رسول الرحمة'),
            ('noor', crypt('noor123', gen_salt('bf', 10)), 'noor', 'school_admin', 'مدير مدرسة نور الرحمة'),
            ('nabi', crypt('nabi123', gen_salt('bf', 10)), 'nabi', 'school_admin', 'مدير مدرسة نبي الرحمة'),
            ('thanawiya', crypt('thanawiya123', gen_salt('bf', 10)), 'thanawiya', 'school_admin', 'مدير ثانوية رسول الرحمة')
        ON CONFLICT (username) DO UPDATE SET 
            password_hash = crypt(EXCLUDED.password_hash, gen_salt('bf', 10)),
            updated_at = NOW();
    ELSE
        -- إذا كان النوع UUID، تخطي الإدراج
        RAISE NOTICE 'جدول users.school_id يستخدم UUID - تم تخطي إدراج المستخدمين للمدارس';
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- في حالة أي خطأ، تخطي الإدراج
    RAISE NOTICE 'تم تخطي إدراج المستخدمين للمدارس: %', SQLERRM;
END $$;

-- إدراج الإعدادات الافتراضية
INSERT INTO system_settings (key, value, description, category, is_public) VALUES
    ('default_annual_fee_kindergarten', '{"value": 1000000}', 'المبلغ السنوي الافتراضي للروضة', 'fees', TRUE),
    ('default_annual_fee_elementary', '{"value": 1100000}', 'المبلغ السنوي الافتراضي للمرحلة الابتدائية', 'fees', TRUE),
    ('default_annual_fee_middle', '{"value": 1300000}', 'المبلغ السنوي الافتراضي للمرحلة المتوسطة', 'fees', TRUE),
    ('default_installment_count', '{"value": 4}', 'عدد الدفعات الافتراضي', 'fees', TRUE),
    ('sibling_discount_2', '{"percentage": 5}', 'خصم الإخوة (2 أخوة)', 'discounts', TRUE),
    ('sibling_discount_3_plus', '{"percentage": 10}', 'خصم الإخوة (3+ أخوة)', 'discounts', TRUE),
    ('whatsapp_auto_send', '{"enabled": false}', 'إرسال إشعارات واتساب تلقائياً', 'notifications', FALSE),
    ('reminder_days', '{"value": 7}', 'عدد أيام التأخير قبل إرسال التذكير', 'notifications', FALSE)
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow all operations on students" ON students;
DROP POLICY IF EXISTS "Allow all operations on users" ON users;
DROP POLICY IF EXISTS "Allow all operations on messages" ON messages;
DROP POLICY IF EXISTS "Allow all operations on notifications" ON notifications;
DROP POLICY IF EXISTS "Allow all operations on payments" ON payments;

-- Policies للطلاب
DROP POLICY IF EXISTS "Students: Allow authenticated read" ON students;
CREATE POLICY "Students: Allow authenticated read" ON students
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Students: Allow authenticated insert" ON students;
CREATE POLICY "Students: Allow authenticated insert" ON students
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Students: Allow authenticated update" ON students;
CREATE POLICY "Students: Allow authenticated update" ON students
    FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Students: Allow authenticated delete" ON students;
CREATE POLICY "Students: Allow authenticated delete" ON students
    FOR DELETE USING (true);

-- Policies للمستخدمين
DROP POLICY IF EXISTS "Users: Allow authenticated read" ON users;
CREATE POLICY "Users: Allow authenticated read" ON users
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users: Allow admin insert" ON users;
CREATE POLICY "Users: Allow admin insert" ON users
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users: Allow admin update" ON users;
CREATE POLICY "Users: Allow admin update" ON users
    FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Users: Allow admin delete" ON users;
CREATE POLICY "Users: Allow admin delete" ON users
    FOR DELETE USING (true);

-- Policies للرسائل
DROP POLICY IF EXISTS "Messages: Allow authenticated read" ON messages;
CREATE POLICY "Messages: Allow authenticated read" ON messages
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Messages: Allow authenticated insert" ON messages;
CREATE POLICY "Messages: Allow authenticated insert" ON messages
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Messages: Allow authenticated update" ON messages;
CREATE POLICY "Messages: Allow authenticated update" ON messages
    FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Messages: Allow authenticated delete" ON messages;
CREATE POLICY "Messages: Allow authenticated delete" ON messages
    FOR DELETE USING (true);

-- Policies للإشعارات
DROP POLICY IF EXISTS "Notifications: Allow authenticated read" ON notifications;
CREATE POLICY "Notifications: Allow authenticated read" ON notifications
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Notifications: Allow authenticated insert" ON notifications;
CREATE POLICY "Notifications: Allow authenticated insert" ON notifications
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Notifications: Allow authenticated update" ON notifications;
CREATE POLICY "Notifications: Allow authenticated update" ON notifications
    FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Notifications: Allow authenticated delete" ON notifications;
CREATE POLICY "Notifications: Allow authenticated delete" ON notifications
    FOR DELETE USING (true);

-- Policies للمدفوعات
DROP POLICY IF EXISTS "Payments: Allow authenticated read" ON payments;
CREATE POLICY "Payments: Allow authenticated read" ON payments
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Payments: Allow authenticated insert" ON payments;
CREATE POLICY "Payments: Allow authenticated insert" ON payments
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Payments: Allow authenticated update" ON payments;
CREATE POLICY "Payments: Allow authenticated update" ON payments
    FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Payments: Allow authenticated delete" ON payments;
CREATE POLICY "Payments: Allow authenticated delete" ON payments
    FOR DELETE USING (true);

-- Policies لسجل الأنشطة (للقراءة فقط للمديرين)
DROP POLICY IF EXISTS "Audit logs: Allow admin read" ON audit_logs;
CREATE POLICY "Audit logs: Allow admin read" ON audit_logs
    FOR SELECT USING (true);

-- Policies للإعدادات
DROP POLICY IF EXISTS "Settings: Allow authenticated read public" ON system_settings;
CREATE POLICY "Settings: Allow authenticated read public" ON system_settings
    FOR SELECT USING (is_public = TRUE);

DROP POLICY IF EXISTS "Settings: Allow admin read all" ON system_settings;
CREATE POLICY "Settings: Allow admin read all" ON system_settings
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Settings: Allow admin update" ON system_settings;
CREATE POLICY "Settings: Allow admin update" ON system_settings
    FOR UPDATE USING (true) WITH CHECK (true);

-- ============================================
-- VIEWS (لتحسين الاستعلامات)
-- ============================================

-- View لإحصائيات الطلاب
-- ملاحظة: تم تعديل VIEW لإزالة استخدام status و installments لأن الأعمدة قد لا تكون موجودة
CREATE OR REPLACE VIEW students_statistics AS
SELECT 
    s.school_id,
    sc.name AS school_name,
    COUNT(*) AS total_students,
    -- تم إزالة paid_students, partial_students, unpaid_students لأنها تعتمد على status
    -- COUNT(*) FILTER (WHERE s.status = 'paid') AS paid_students,
    -- COUNT(*) FILTER (WHERE s.status = 'partial') AS partial_students,
    -- COUNT(*) FILTER (WHERE s.status = 'unpaid') AS unpaid_students,
    COALESCE(SUM(s.final_fee), 0) AS total_fees,
    -- تم إزالة حساب total_paid لأنها تعتمد على installments
    -- COALESCE(SUM(
    --     (SELECT COALESCE(SUM((value->>'amount_paid')::NUMERIC), 0)
    --      FROM jsonb_array_elements(s.installments) AS value)
    -- ), 0) AS total_paid,
    0 AS total_paid, -- قيمة افتراضية حتى يتم إضافة عمود installments
    COALESCE(SUM(s.final_fee), 0) AS total_remaining,
    -- تم إزالة حساب payment_rate لأنها تعتمد على installments
    0 AS payment_rate -- قيمة افتراضية حتى يتم إضافة عمود installments
FROM students s
JOIN schools sc ON s.school_id = sc.id
-- تم إزالة شرط is_active لأن العمود قد لا يكون موجوداً
-- WHERE s.is_active = TRUE
GROUP BY s.school_id, sc.name;

-- View للمدفوعات الشهرية
CREATE OR REPLACE VIEW monthly_payments AS
SELECT 
    DATE_TRUNC('month', payment_date) AS month,
    school_id,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount,
    COUNT(DISTINCT student_id) AS unique_students
FROM payments p
JOIN students s ON p.student_id = s.id
GROUP BY DATE_TRUNC('month', payment_date), school_id;

-- ============================================
-- COMMENTS (لتوثيق قاعدة البيانات)
-- ============================================

COMMENT ON TABLE schools IS 'جدول المدارس في النظام';
COMMENT ON TABLE students IS 'جدول الطلاب المسجلين في المدارس';
COMMENT ON TABLE users IS 'جدول المستخدمين مع كلمات مرور مشفرة';
COMMENT ON TABLE messages IS 'جدول الرسائل بين المدارس';
COMMENT ON TABLE notifications IS 'جدول الإشعارات للمستخدمين والمدارس';
COMMENT ON TABLE payments IS 'سجل جميع المدفوعات للطلاب';
COMMENT ON TABLE audit_logs IS 'سجل أنشطة النظام للمراجعة';
COMMENT ON TABLE system_settings IS 'إعدادات النظام العامة';

COMMENT ON FUNCTION hash_password IS 'تشفير كلمة المرور باستخدام bcrypt';
COMMENT ON FUNCTION verify_password IS 'التحقق من صحة كلمة المرور';
COMMENT ON FUNCTION calculate_student_status IS 'حساب الحالة المالية للطالب تلقائياً';
