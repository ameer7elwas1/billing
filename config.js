// ============================================
// Configuration File - رسول الرحمة System
// ============================================
// ⚠️ IMPORTANT: هذا الملف يجب أن يكون في .gitignore في الإنتاج
// ⚠️ يجب نقل المفاتيح إلى متغيرات بيئية في الإنتاج

const CONFIG = {
    // Supabase Configuration
    SUPABASE: {
        URL: 'https://vpvvjascwgivdjyyhzwp.supabase.co',
        ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZwdnZqYXNjd2dpdmRqeXloendwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MDYxMjYsImV4cCI6MjA2NTM4MjEyNn0.6AR2-MG4x9ugNTXe9jUqx-IwGEtj1m6MCYwQkTsSbUQ'
    },

    // Default Fees (يمكن تغييرها من الإعدادات)
    DEFAULT_FEES: {
        KINDERGARTEN: 1000000,
        ELEMENTARY: 1100000,
        MIDDLE: 1300000
    },

    // Installment Settings
    INSTALLMENT_COUNT: 4,
    QUARTERLY_INSTALLMENT: 300000,

    // Discount Settings
    DISCOUNTS: {
        SIBLING_2: 0.05,      // 5% لشخصين
        SIBLING_3_PLUS: 0.10  // 10% لثلاثة أو أكثر
    },

    // Cache Settings (بالميلي ثانية)
    CACHE_TTL: {
        STUDENTS: 300000,      // 5 دقائق
        INSTALLMENTS: 300000,  // 5 دقائق
        SCHOOLS: 600000,       // 10 دقائق
        NOTIFICATIONS: 30000,  // 30 ثانية
        MESSAGES: 30000,       // 30 ثانية
        USERS: 600000          // 10 دقائق
    },

    // WhatsApp Settings
    WHATSAPP: {
        AUTO_SEND: false,
        REMINDER_DAYS: 7,
        COUNTRY_CODE: '964'
    },

    // Validation Rules
    VALIDATION: {
        USERNAME_MIN_LENGTH: 3,
        USERNAME_MAX_LENGTH: 50,
        PASSWORD_MIN_LENGTH: 6,
        NAME_MIN_LENGTH: 2,
        NAME_MAX_LENGTH: 200,
        PHONE_MIN_LENGTH: 8,
        PHONE_MAX_LENGTH: 15,
        NOTES_MAX_LENGTH: 1000
    },

    // Security Settings
    SECURITY: {
        MAX_LOGIN_ATTEMPTS: 5,
        LOCKOUT_DURATION: 30 * 60 * 1000, // 30 دقيقة
        SESSION_TIMEOUT: 60 * 60 * 1000,  // ساعة واحدة
        PASSWORD_HASH_ROUNDS: 10
    },

    // Pagination
    PAGINATION: {
        DEFAULT_PAGE_SIZE: 50,
        MAX_PAGE_SIZE: 500
    },

    // Export Settings
    EXPORT: {
        MAX_RECORDS: 10000,
        DEFAULT_FORMAT: 'xlsx'
    }
};

// Schools Configuration
const SCHOOLS = {
    rawda: { 
        id: 'rawda', 
        name: 'روضة رسول الرحمة',
        code: 'RAWDA',
        color: '#8B4513'
    },
    rasoul: { 
        id: 'rasoul', 
        name: 'مدرسة رسول الرحمة',
        code: 'RASOUL',
        color: '#0f766e'
    },
    noor: { 
        id: 'noor', 
        name: 'مدرسة نور الرحمة',
        code: 'NOOR',
        color: '#f59e0b'
    },
    nabi: { 
        id: 'nabi', 
        name: 'مدرسة نبي الرحمة',
        code: 'NABI',
        color: '#3498db'
    },
    thanawiya: { 
        id: 'thanawiya', 
        name: 'ثانوية رسول الرحمة',
        code: 'THANAWIYA',
        color: '#e74c3c'
    }
};

// Grades Configuration
const GRADES = {
    rawda: ['روضة'],
    rasoul: ['الاول ابتدائي', 'الثاني ابتدائي', 'الثالث ابتدائي', 'الرابع ابتدائي', 'الخامس ابتدائي', 'السادس ابتدائي'],
    noor: ['الاول ابتدائي', 'الثاني ابتدائي', 'الثالث ابتدائي', 'الرابع ابتدائي', 'الخامس ابتدائي', 'السادس ابتدائي'],
    nabi: ['الاول ابتدائي', 'الثاني ابتدائي', 'الثالث ابتدائي', 'الرابع ابتدائي', 'الخامس ابتدائي', 'السادس ابتدائي'],
    thanawiya: ['الاول متوسط', 'الثاني متوسط', 'الثالث متوسط']
};

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { CONFIG, SCHOOLS, GRADES };
}

