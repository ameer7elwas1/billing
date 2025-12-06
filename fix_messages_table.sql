-- ============================================
-- إصلاح جدول messages لاستخدام TEXT بدلاً من UUID
-- وتغيير message_text إلى message
-- نفذ هذا الكود في Supabase SQL Editor
-- ============================================

-- التحقق من نوع الأعمدة الحالية
SELECT 
    column_name, 
    data_type,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'messages' 
AND column_name IN ('sender_id', 'receiver_id', 'message', 'message_text');

-- إذا كانت الأعمدة من نوع UUID، قم بتحويلها إلى TEXT
-- ملاحظة: هذا سيعمل فقط إذا لم تكن هناك بيانات موجودة، أو إذا كانت البيانات قابلة للتحويل

-- الخطوة 1: تغيير اسم العمود من message_text إلى message (إن وجد)
DO $$
BEGIN
    -- التحقق من وجود العمود message_text
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' 
        AND column_name = 'message_text'
    ) THEN
        -- تغيير اسم العمود
        ALTER TABLE messages RENAME COLUMN message_text TO message;
        RAISE NOTICE 'تم تغيير اسم العمود من message_text إلى message';
    ELSE
        RAISE NOTICE 'العمود message_text غير موجود أو تم تغييره بالفعل';
    END IF;
END $$;

-- الخطوة 2: حذف الـ Views التي تعتمد على جدول messages (إن وجدت)
-- ملاحظة: يجب حذف الـ Views أولاً قبل تغيير نوع الأعمدة
DROP VIEW IF EXISTS messages_detail CASCADE;
DROP VIEW IF EXISTS messages_view CASCADE;
DROP VIEW IF EXISTS v_messages CASCADE;

-- الخطوة 3: حذف جميع Foreign Key Constraints المرتبطة بـ sender_id و receiver_id
-- ملاحظة: يجب حذف هذه القيود قبل تغيير نوع الأعمدة
DO $$
DECLARE
    constraint_name TEXT;
    col_attnum INTEGER;
BEGIN
    -- الحصول على أرقام الأعمدة sender_id و receiver_id
    SELECT attnum INTO col_attnum FROM pg_attribute 
    WHERE attrelid = 'messages'::regclass AND attname = 'sender_id';
    
    -- البحث عن جميع الـ foreign key constraints المرتبطة بـ sender_id
    FOR constraint_name IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'messages'::regclass
        AND contype = 'f'
        AND col_attnum = ANY(conkey)
    LOOP
        EXECUTE format('ALTER TABLE messages DROP CONSTRAINT IF EXISTS %I CASCADE', constraint_name);
        RAISE NOTICE 'تم حذف constraint المرتبط بـ sender_id: %', constraint_name;
    END LOOP;
    
    -- الحصول على أرقام الأعمدة receiver_id
    SELECT attnum INTO col_attnum FROM pg_attribute 
    WHERE attrelid = 'messages'::regclass AND attname = 'receiver_id';
    
    -- البحث عن جميع الـ foreign key constraints المرتبطة بـ receiver_id
    FOR constraint_name IN
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'messages'::regclass
        AND contype = 'f'
        AND col_attnum = ANY(conkey)
    LOOP
        EXECUTE format('ALTER TABLE messages DROP CONSTRAINT IF EXISTS %I CASCADE', constraint_name);
        RAISE NOTICE 'تم حذف constraint المرتبط بـ receiver_id: %', constraint_name;
    END LOOP;
END $$;

-- طريقة بديلة أبسط: حذف جميع الـ foreign key constraints المعروفة
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey CASCADE;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_receiver_id_fkey CASCADE;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS fk_messages_sender CASCADE;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS fk_messages_receiver CASCADE;

-- الخطوة 4: حذف القيد CHECK الموجود (إن وجد)
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_sender_receiver_check;

-- الخطوة 5: تحويل sender_id من UUID إلى TEXT
DO $$
BEGIN
    -- التحقق من نوع العمود
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' 
        AND column_name = 'sender_id' 
        AND data_type = 'uuid'
    ) THEN
        -- حذف البيانات الموجودة إذا كانت من نوع UUID (لأنها لن تكون متوافقة)
        -- ملاحظة: يمكنك حذف هذا السطر إذا كنت تريد الاحتفاظ بالبيانات
        -- DELETE FROM messages;
        
        -- تحويل UUID إلى TEXT
        ALTER TABLE messages 
        ALTER COLUMN sender_id DROP NOT NULL;
        
        ALTER TABLE messages 
        ALTER COLUMN sender_id TYPE TEXT USING 
            CASE 
                WHEN sender_id IS NULL THEN NULL 
                ELSE sender_id::TEXT 
            END;
        
        ALTER TABLE messages 
        ALTER COLUMN sender_id SET NOT NULL;
        
        RAISE NOTICE 'تم تحويل sender_id من UUID إلى TEXT';
    ELSE
        RAISE NOTICE 'sender_id بالفعل من نوع TEXT أو غير موجود';
    END IF;
END $$;

-- الخطوة 6: تحويل receiver_id من UUID إلى TEXT
DO $$
BEGIN
    -- التحقق من نوع العمود
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' 
        AND column_name = 'receiver_id' 
        AND data_type = 'uuid'
    ) THEN
        -- تحويل UUID إلى TEXT (مع السماح بـ NULL)
        ALTER TABLE messages 
        ALTER COLUMN receiver_id TYPE TEXT USING 
            CASE 
                WHEN receiver_id IS NULL THEN NULL 
                ELSE receiver_id::TEXT 
            END;
        
        RAISE NOTICE 'تم تحويل receiver_id من UUID إلى TEXT';
    ELSE
        RAISE NOTICE 'receiver_id بالفعل من نوع TEXT أو غير موجود';
    END IF;
END $$;

-- الخطوة 7: إعادة إضافة القيود
ALTER TABLE messages 
ADD CONSTRAINT messages_sender_receiver_check 
CHECK (sender_id != receiver_id OR receiver_id IS NULL);

-- الخطوة 8: التحقق من النتيجة
SELECT 
    column_name, 
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'messages' 
AND column_name IN ('sender_id', 'receiver_id', 'message')
ORDER BY column_name;

-- ============================================
-- ملاحظة: إذا كنت تستخدم view اسمه messages_detail،
-- يجب إعادة إنشائه يدوياً بعد تنفيذ هذا الكود
-- ============================================
-- تم إصلاح جدول messages بنجاح!
-- ============================================

