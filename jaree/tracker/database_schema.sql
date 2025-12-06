-- إضافة الأعمدة المفقودة إذا كانت الجداول موجودة
DO $$ 
BEGIN
    -- إضافة school_id إلى users إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'school_id'
    ) THEN
        ALTER TABLE users ADD COLUMN school_id UUID;
    END IF;
    
    -- إضافة password إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'password'
    ) THEN
        ALTER TABLE users ADD COLUMN password VARCHAR(255);
    END IF;
    
    -- إضافة password_hash إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'password_hash'
    ) THEN
        ALTER TABLE users ADD COLUMN password_hash TEXT;
    END IF;
    
    -- إضافة user_type إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'user_type'
    ) THEN
        ALTER TABLE users ADD COLUMN user_type VARCHAR(50) DEFAULT 'user';
    END IF;
    
    -- إضافة is_active إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- إضافة created_at إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP DEFAULT NOW();
    END IF;
    
    -- إضافة updated_at إذا لم يكن موجوداً
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE users ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
    END IF;
    
    -- إضافة تحديث في الجداول إذا لم تكن موجودة
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'students') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'students' AND column_name = 'mother_name'
        ) THEN
            ALTER TABLE students ADD COLUMN mother_name VARCHAR(255);
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'students' AND column_name = 'has_sibling'
        ) THEN
            ALTER TABLE students ADD COLUMN has_sibling BOOLEAN DEFAULT false;
        END IF;
    END IF;
END $$;

-- إنشاء جداول فقط إذا لم تكن موجودة
-- جدول المدارس
CREATE TABLE IF NOT EXISTS schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    school_type VARCHAR(50) NOT NULL, -- 'روضة', 'ابتدائية', 'ثانوية'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- جدول المستخدمين
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    school_id UUID REFERENCES schools(id),
    user_type VARCHAR(50) DEFAULT 'user', -- 'admin', 'school_admin', 'user'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(username, school_id)
);

-- جدول الطلاب
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) NOT NULL,
    receipt_number VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    mother_name VARCHAR(255) NOT NULL,
    guardian VARCHAR(255) NOT NULL,
    grade VARCHAR(100) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    annual_fee NUMERIC(15,2) NOT NULL,
    final_fee NUMERIC(15,2) NOT NULL,
    discount NUMERIC(15,2) DEFAULT 0,
    has_sibling BOOLEAN DEFAULT false,
    registration_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(school_id, receipt_number)
);

-- جدول الدفعات (الأقساط)
CREATE TABLE IF NOT EXISTS installments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE NOT NULL,
    installment_number INTEGER NOT NULL, -- 1, 2, 3, 4
    amount_paid NUMERIC(15,2) DEFAULT 0,
    payment_date DATE,
    status VARCHAR(50) DEFAULT 'unpaid', -- 'unpaid', 'partial', 'paid'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CHECK (installment_number BETWEEN 1 AND 4),
    UNIQUE(student_id, installment_number)
);

-- جدول الدفعات (للتاريخ)
CREATE TABLE IF NOT EXISTS payment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES students(id) ON DELETE CASCADE NOT NULL,
    installment_id UUID REFERENCES installments(id),
    amount NUMERIC(15,2) NOT NULL,
    payment_date DATE NOT NULL,
    receipt_number VARCHAR(50),
    notes TEXT,
    created_by VARCHAR(100), -- اسم المستخدم بدلاً من foreign key
    created_at TIMESTAMP DEFAULT NOW()
);

-- إضافة Foreign Key constraints إذا لم تكن موجودة
DO $$ 
BEGIN
    -- إضافة foreign key لـ users.school_id
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') 
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'schools')
       AND NOT EXISTS (
           SELECT 1 FROM information_schema.table_constraints 
           WHERE constraint_name = 'fk_users_school' AND table_name = 'users'
       ) THEN
        ALTER TABLE users ADD CONSTRAINT fk_users_school 
            FOREIGN KEY (school_id) REFERENCES schools(id);
    END IF;
    
    -- إضافة foreign key لـ students.school_id
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'students') 
       AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'schools')
       AND NOT EXISTS (
           SELECT 1 FROM information_schema.table_constraints 
           WHERE constraint_name = 'students_school_id_fkey' AND table_name = 'students'
       ) THEN
        ALTER TABLE students ADD CONSTRAINT students_school_id_fkey 
            FOREIGN KEY (school_id) REFERENCES schools(id);
    END IF;
END $$;

-- Indexes للتحسين (إنشاء فقط إذا لم تكن موجودة)
CREATE INDEX IF NOT EXISTS idx_students_school ON students(school_id);
CREATE INDEX IF NOT EXISTS idx_students_mother_name ON students(mother_name);
CREATE INDEX IF NOT EXISTS idx_students_receipt_number ON students(receipt_number);
CREATE INDEX IF NOT EXISTS idx_installments_student ON installments(student_id);
CREATE INDEX IF NOT EXISTS idx_payment_history_student ON payment_history(student_id);
CREATE INDEX IF NOT EXISTS idx_payment_history_date ON payment_history(payment_date);
CREATE INDEX IF NOT EXISTS idx_users_school ON users(school_id);
CREATE INDEX IF NOT EXISTS idx_students_phone ON students(phone);
CREATE INDEX IF NOT EXISTS idx_students_grade ON students(grade);

-- إدراج المدارس (إضافة فقط إذا لم تكن موجودة)
INSERT INTO schools (name, code, school_type)
SELECT 'روضة رسول الرحمة', 'rawda', 'روضة'
WHERE NOT EXISTS (SELECT 1 FROM schools WHERE code = 'rawda');

INSERT INTO schools (name, code, school_type)
SELECT 'مدرسة رسول الرحمة', 'rasoul', 'ابتدائية'
WHERE NOT EXISTS (SELECT 1 FROM schools WHERE code = 'rasoul');

INSERT INTO schools (name, code, school_type)
SELECT 'مدرسة نور الرحمة', 'noor', 'ابتدائية'
WHERE NOT EXISTS (SELECT 1 FROM schools WHERE code = 'noor');

INSERT INTO schools (name, code, school_type)
SELECT 'مدرسة نبي الرحمة', 'nabi', 'ابتدائية'
WHERE NOT EXISTS (SELECT 1 FROM schools WHERE code = 'nabi');

INSERT INTO schools (name, code, school_type)
SELECT 'ثانوية رسول الرحمة', 'thanawiya', 'ثانوية'
WHERE NOT EXISTS (SELECT 1 FROM schools WHERE code = 'thanawiya');

-- إدراج المدير الرئيسي (استخدام UPSERT)
INSERT INTO users (username, password, password_hash, school_id, user_type, full_name) 
VALUES ('admin', 'master123', 'master123', NULL, 'admin', 'مدير النظام')
ON CONFLICT (username) DO UPDATE 
SET password = EXCLUDED.password,
    password_hash = EXCLUDED.password_hash,
    user_type = EXCLUDED.user_type,
    full_name = EXCLUDED.full_name;

-- إدراج مستخدمين لكل مدرسة (تحديث أو إضافة)
DO $$
DECLARE
    school_record RECORD;
    user_exists BOOLEAN;
    admin_username VARCHAR;
BEGIN
    FOR school_record IN SELECT id, code, name FROM schools LOOP
        -- استخدام username فريد لكل مدرسة
        admin_username := 'admin_' || school_record.code;
        
        -- التحقق من وجود المستخدم
        SELECT EXISTS(
            SELECT 1 FROM users 
            WHERE school_id = school_record.id 
            AND (username = 'admin' OR username = admin_username)
        ) INTO user_exists;
        
        IF NOT user_exists THEN
            -- محاولة إدراج admin أولاً
            BEGIN
                INSERT INTO users (username, password, password_hash, school_id, user_type, full_name)
                VALUES (
                    admin_username,
                    school_record.code || '123',
                    school_record.code || '123',
                    school_record.id,
                    'school_admin',
                    'مدير ' || school_record.name
                );
            EXCEPTION WHEN unique_violation THEN
                -- إذا كان username موجود، استخدم username مختلف
                INSERT INTO users (username, password, password_hash, school_id, user_type, full_name)
                VALUES (
                    admin_username || '_' || TO_CHAR(NOW(), 'MMDD'),
                    school_record.code || '123',
                    school_record.code || '123',
                    school_record.id,
                    'school_admin',
                    'مدير ' || school_record.name
                );
            END;
        ELSE
            -- تحديث المستخدم الموجود
            UPDATE users 
            SET password = school_record.code || '123',
                password_hash = school_record.code || '123',
                full_name = 'مدير ' || school_record.name
            WHERE school_id = school_record.id;
        END IF;
    END LOOP;
END $$;

-- جدول المحادثات (Messages)
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES schools(id) NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    receiver_id UUID REFERENCES schools(id),
    message TEXT NOT NULL,
    is_broadcast BOOLEAN DEFAULT false, -- رسالة عامة لجميع المدارس
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- فهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_read ON messages(is_read);

-- جدول الإشعارات (Notifications)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info', -- 'info', 'success', 'warning', 'error'
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_school ON notifications(school_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);

-- رسائل تأكيد
DO $$
BEGIN
    RAISE NOTICE 'تم إنشاء قاعدة البيانات بنجاح!';
    RAISE NOTICE 'عدد المدارس: %', (SELECT COUNT(*) FROM schools);
    RAISE NOTICE 'عدد المستخدمين: %', (SELECT COUNT(*) FROM users);
END $$;

