-- ============================================
-- نظام إدارة المدارس المتكامل
-- مجموعة رسول الرحمة التعليمية
-- ============================================

-- جدول المدارس
CREATE TABLE IF NOT EXISTS public.schools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100),
    code VARCHAR(50) UNIQUE,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    principal_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول الصفوف
CREATE TABLE IF NOT EXISTS public.grades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    level VARCHAR(50), -- ابتدائي، متوسط، ثانوي
    order_index INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول المدرسين
CREATE TABLE IF NOT EXISTS public.teachers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255),
    subject_name VARCHAR(100),
    grades TEXT[], -- الصفوف التي يدرسها
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول المواد الدراسية
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    grade VARCHAR(100),
    periods INTEGER DEFAULT 0, -- عدد الحصص الأسبوعية
    teacher_name VARCHAR(100),
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول الدروس (الجدول الأسبوعي)
CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    day VARCHAR(20) NOT NULL, -- السبت، الأحد، الإثنين، إلخ
    period INTEGER NOT NULL, -- رقم الحصة (1-8)
    grade VARCHAR(100) NOT NULL,
    subject_name VARCHAR(100) NOT NULL,
    teacher_name VARCHAR(100) NOT NULL,
    room VARCHAR(50),
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(day, period, grade, school_id) -- منع تكرار الدرس في نفس الوقت والصف
);

-- جدول الطلاب (موجود مسبقاً، نضيف فقط الحقول المطلوبة إن لم تكن موجودة)
-- ALTER TABLE IF EXISTS public.students ADD COLUMN IF NOT EXISTS school_id UUID REFERENCES public.schools(id);
-- ALTER TABLE IF EXISTS public.students ADD COLUMN IF NOT EXISTS grade VARCHAR(100);

-- جدول الدرجات
CREATE TABLE IF NOT EXISTS public.grades_records (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID, -- يمكن ربطه بجدول الطلاب
    subject_name VARCHAR(100) NOT NULL,
    exam_type VARCHAR(50), -- اختبار، مشروع، نشاط، إلخ
    grade DECIMAL(5,2) NOT NULL,
    max_grade DECIMAL(5,2) DEFAULT 100,
    exam_date DATE,
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول الأقساط (موجود مسبقاً، نضيف فقط الحقول المطلوبة إن لم تكن موجودة)
-- ALTER TABLE IF EXISTS public.installments ADD COLUMN IF NOT EXISTS school_id UUID REFERENCES public.schools(id);

-- جدول المحادثات بين المدارس
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    sender_name VARCHAR(100),
    receiver_id UUID REFERENCES public.schools(id) ON DELETE SET NULL, -- null يعني جميع المدارس
    receiver_name VARCHAR(100),
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول التنبيهات من رئيس مجلس الإدارة
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    sender_id UUID, -- رئيس مجلس الإدارة
    receiver_id UUID REFERENCES public.schools(id) ON DELETE CASCADE, -- null يعني جميع المدارس
    notification_type VARCHAR(50) DEFAULT 'info', -- info, warning, error, success
    is_read BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- جدول الحضور والغياب
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID, -- يمكن ربطه بجدول الطلاب
    date DATE NOT NULL,
    status VARCHAR(20) NOT NULL, -- present, absent, late, excused
    notes TEXT,
    school_id UUID REFERENCES public.schools(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, date, school_id)
);

-- إنشاء الفهارس لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_schools_code ON public.schools(code);
CREATE INDEX IF NOT EXISTS idx_grades_school ON public.grades(school_id);
CREATE INDEX IF NOT EXISTS idx_teachers_school ON public.teachers(school_id);
CREATE INDEX IF NOT EXISTS idx_subjects_school ON public.subjects(school_id);
CREATE INDEX IF NOT EXISTS idx_lessons_school ON public.lessons(school_id);
CREATE INDEX IF NOT EXISTS idx_lessons_day_period ON public.lessons(day, period);
CREATE INDEX IF NOT EXISTS idx_grades_records_student ON public.grades_records(student_id);
CREATE INDEX IF NOT EXISTS idx_grades_records_school ON public.grades_records(school_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_receiver ON public.notifications(receiver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_school ON public.attendance(school_id);

-- تعطيل RLS (Row Level Security) للتبسيط
ALTER TABLE public.schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades_records DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance DISABLE ROW LEVEL SECURITY;

-- إدراج بيانات تجريبية للمدارس
INSERT INTO public.schools (id, name, name_ar, code, is_active) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Rawda', 'روضة رسول الرحمة', 'rawda', true),
    ('00000000-0000-0000-0000-000000000002', 'Rasoul', 'مدرسة رسول الرحمة', 'rasoul', true),
    ('00000000-0000-0000-0000-000000000003', 'Noor', 'مدرسة نور الرحمة', 'noor', true),
    ('00000000-0000-0000-0000-000000000004', 'Nabi', 'مدرسة نبي الرحمة', 'nabi', true),
    ('00000000-0000-0000-0000-000000000005', 'Thanawiya', 'ثانوية رسول الرحمة', 'thanawiya', true)
ON CONFLICT (code) DO NOTHING;

