-- إصلاح جداول المحادثة والإشعارات
-- قم بتنفيذ هذا الملف في Supabase SQL Editor

-- حذف الجداول القديمة إذا كانت موجودة
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS messages CASCADE;

-- إنشاء جدول messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES schools(id) NOT NULL,
    sender_name VARCHAR(255) NOT NULL,
    receiver_id UUID REFERENCES schools(id),
    message TEXT NOT NULL,
    is_broadcast BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- فهارس لجدول messages
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_read ON messages(is_read);

-- إنشاء جدول notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    school_id UUID REFERENCES schools(id) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

-- فهارس لجدول notifications
CREATE INDEX idx_notifications_school ON notifications(school_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

-- رسالة تأكيد
SELECT 'تم إنشاء الجداول بنجاح!' AS status;

