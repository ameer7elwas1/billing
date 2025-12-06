# دليل ربط نظام مجموعة رسول الرحمة التعليمية بقاعدة البيانات

## 1. إنشاء قاعدة البيانات

قم بتنفيذ ملف `database_schema.sql` على Supabase.

### الخطوات:
1. اذهب إلى Supabase Dashboard
2. افتح SQL Editor
3. قم بتنفيذ محتوى ملف `database_schema.sql`

## 2. البنية الأساسية

### الجداول المُنشأة:

#### 1. schools (المدارس)
- `id`: UUID
- `name`: اسم المدرسة
- `code`: كود المدرسة (rawda, rasoul, noor, nabi, thanawiya)
- `school_type`: نوع المدرسة (روضة، ابتدائية، ثانوية)

#### 2. users (المستخدمون)
- `id`: UUID
- `username`: اسم المستخدم
- `password`: كلمة المرور (يجب تشفيرها في الإنتاج)
- `school_id`: معرف المدرسة
- `user_type`: نوع المستخدم (admin, school_admin, user)

#### 3. students (الطلاب)
- `id`: UUID
- `school_id`: معرف المدرسة
- `receipt_number`: رقم الوصل
- `name`: اسم الطالب
- `mother_name`: اسم الأم
- `guardian`: ولي الأمر
- `grade`: الصف
- `phone`: رقم الهاتف
- `annual_fee`: المبلغ السنوي
- `final_fee`: المبلغ النهائي بعد الخصم
- `discount`: الخصم
- `has_sibling`: هل لديه أخوة
- `registration_date`: تاريخ التسجيل
- `notes`: ملاحظات

#### 4. installments (الأقساط)
- `id`: UUID
- `student_id`: معرف الطالب
- `installment_number`: رقم القسط (1-4)
- `amount_paid`: المبلغ المدفوع
- `payment_date`: تاريخ الدفع
- `status`: الحالة (unpaid, partial, paid)

#### 5. payment_history (سجل الدفعات)
- `id`: UUID
- `student_id`: معرف الطالب
- `installment_id`: معرف القسط
- `amount`: المبلغ
- `payment_date`: تاريخ الدفع
- `receipt_number`: رقم الوصل
- `notes`: ملاحظات

## 3. حماية البيانات

### Row Level Security (RLS)
```sql
-- تفعيل RLS على الجداول
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_history ENABLE ROW LEVEL SECURITY;

-- سياسة للقراءة: يمكن للمستخدمين قراءة بيانات مدرستهم فقط
CREATE POLICY "Users can view their school students"
ON students FOR SELECT
USING (
    auth.jwt() ->> 'school_id' = school_id::text
    OR auth.jwt() ->> 'user_type' = 'admin'
);

-- سياسة للإدراج: يمكن للمستخدمين إضافة طلاب لمدرستهم
CREATE POLICY "Users can insert students to their school"
ON students FOR INSERT
WITH CHECK (
    auth.jwt() ->> 'school_id' = school_id::text
    OR auth.jwt() ->> 'user_type' = 'admin'
);

-- سياسة للتحديث
CREATE POLICY "Users can update their school students"
ON students FOR UPDATE
USING (
    auth.jwt() ->> 'school_id' = school_id::text
    OR auth.jwt() ->> 'user_type' = 'admin'
);
```

## 4. استخدام النظام الحالي

النظام الحالي يعمل بـ localStorage للبيانات. لتحويله للعمل مع Supabase:

### الخطوات:
1. احتفظ بنسخة احتياطية من البيانات الحالية
2. قم بتشغيل النظام وتصدير البيانات
3. أنشئ سكربت لتحميل البيانات من localStorage إلى Supabase

## 5. مزامنة البيانات

```javascript
// دالة لمزامنة البيانات من localStorage إلى Supabase
async function syncToDatabase() {
    // جمع البيانات من جميع المدارس
    const allStudents = [];
    Object.keys(schools).forEach(schoolId => {
        const schoolData = localStorage.getItem(`students_data_${schoolId}`);
        if (schoolData) {
            const schoolStudents = JSON.parse(schoolData);
            schoolStudents.forEach(student => {
                student.schoolId = schoolId;
                allStudents.push(student);
            });
        }
    });
    
    // إدراج الطلاب
    for (const student of allStudents) {
        // الحصول على school_id من جدول schools
        const { data: schoolData } = await supabase
            .from('schools')
            .select('id')
            .eq('code', student.schoolId)
            .single();
        
        if (schoolData) {
            // إدراج الطالب
            const { error } = await supabase
                .from('students')
                .insert({
                    school_id: schoolData.id,
                    receipt_number: student.receiptNumber,
                    name: student.name,
                    mother_name: student.motherName,
                    guardian: student.guardian,
                    grade: student.grade,
                    phone: student.phone,
                    annual_fee: student.annualFee,
                    final_fee: student.finalFee,
                    discount: student.discount,
                    has_sibling: student.hasSibling,
                    registration_date: student.registrationDate,
                    notes: student.notes
                });
            
            if (error) {
                console.error('Error inserting student:', error);
            }
        }
    }
}
```

## 6. تشفير كلمات المرور

في الإنتاج، يجب تشفير كلمات المرور:

```sql
-- استخدام PostgreSQL's crypt
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- تحديث جدول users لاستخدام التشفير
ALTER TABLE users ADD COLUMN password_hash TEXT;

-- إدراج مستخدم بتشفير كلمة المرور
INSERT INTO users (username, password_hash, school_id, user_type)
VALUES (
    'admin',
    crypt('master123', gen_salt('bf')),
    NULL,
    'admin'
);
```

## 7. النسخ الاحتياطي

قاعدة البيانات تقدم نسخ احتياطي تلقائي. يمكنك أيضاً:

```bash
# تصدير قاعدة البيانات
pg_dump -h db.vpvvjascwgivdjyyhzwp.supabase.co -U postgres -F c database_name > backup.dump

# استيراد النسخ الاحتياطي
pg_restore -h db.vpvvjascwgivdjyyhzwp.supabase.co -U postgres -d database_name backup.dump
```

## 8. الأدوات المفيدة

- Supabase Dashboard: إدارة قاعدة البيانات
- Supabase Studio: تحرير البيانات
- Postgres Client: الوصول المباشر لقاعدة البيانات

## 9. الأمان

- استخدام RLS (Row Level Security)
- تشفير كلمات المرور
- استخدام HTTPS
- التحقق من المستخدمين قبل الوصول للبيانات

## 10. الصيانة

- مراقبة حجم قاعدة البيانات
- تنظيف البيانات القديمة
- تحديث الفهارس (indexes) بانتظام
- نسخ احتياطي أسبوعي

