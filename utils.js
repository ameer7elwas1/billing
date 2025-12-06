// ============================================
// Utilities - رسول الرحمة System
// ============================================

const Utils = {
    // ============================================
    // Input Validation & Sanitization
    // ============================================

    /**
     * تنظيف النص من HTML tags لمنع XSS
     */
    sanitizeHTML: function(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    /**
     * التحقق من صحة الاسم
     */
    validateName: function(name) {
        if (!name || typeof name !== 'string') return false;
        const trimmed = name.trim();
        return trimmed.length >= CONFIG.VALIDATION.NAME_MIN_LENGTH && 
               trimmed.length <= CONFIG.VALIDATION.NAME_MAX_LENGTH;
    },

    /**
     * التحقق من صحة رقم الهاتف
     */
    validatePhone: function(phone) {
        if (!phone) return false;
        const cleaned = phone.replace(/[\s\-\(\)]/g, '');
        return cleaned.length >= CONFIG.VALIDATION.PHONE_MIN_LENGTH && 
               cleaned.length <= CONFIG.VALIDATION.PHONE_MAX_LENGTH &&
               /^[0-9+]+$/.test(cleaned);
    },

    /**
     * تنظيف رقم الهاتف وتنسيقه
     */
    cleanPhone: function(phone) {
        if (!phone) return '';
        let cleaned = phone.replace(/[\s\-\(\)]/g, '');
        
        // إضافة رمز الدولة إذا لم يكن موجوداً
        if (!cleaned.startsWith('964') && !cleaned.startsWith('+964')) {
            if (cleaned.startsWith('0')) {
                cleaned = '964' + cleaned.substring(1);
            } else {
                cleaned = '964' + cleaned;
            }
        }
        
        return cleaned.replace(/^\+/, '');
    },

    /**
     * التحقق من صحة المبلغ المالي
     */
    validateAmount: function(amount) {
        const num = parseFloat(amount);
        return !isNaN(num) && num >= 0 && num <= 999999999999.99;
    },

    /**
     * التحقق من صحة التاريخ
     */
    validateDate: function(dateString) {
        if (!dateString) return false;
        const date = new Date(dateString);
        return date instanceof Date && !isNaN(date.getTime());
    },

    /**
     * التحقق من صحة اسم المستخدم
     */
    validateUsername: function(username) {
        if (!username || typeof username !== 'string') return false;
        const trimmed = username.trim();
        return trimmed.length >= CONFIG.VALIDATION.USERNAME_MIN_LENGTH && 
               trimmed.length <= CONFIG.VALIDATION.USERNAME_MAX_LENGTH &&
               /^[a-z0-9_]+$/.test(trimmed.toLowerCase());
    },

    /**
     * التحقق من صحة كلمة المرور
     */
    validatePassword: function(password) {
        if (!password || typeof password !== 'string') return false;
        return password.length >= CONFIG.VALIDATION.PASSWORD_MIN_LENGTH;
    },

    /**
     * تنظيف النص من الأحرف الخطرة
     */
    sanitizeText: function(text, maxLength = null) {
        if (!text) return '';
        let cleaned = text.trim()
            .replace(/[<>]/g, '') // إزالة < و >
            .replace(/javascript:/gi, '')
            .replace(/on\w+=/gi, '');
        
        if (maxLength && cleaned.length > maxLength) {
            cleaned = cleaned.substring(0, maxLength);
        }
        
        return cleaned;
    },

    // ============================================
    // Formatting Functions
    // ============================================

    /**
     * تنسيق الأرقام باللغة الإنجليزية
     */
    formatNumber: function(number, decimals = 0) {
        if (isNaN(number)) return '0';
        return Number(number).toLocaleString('en-US', {
            minimumFractionDigits: decimals,
            maximumFractionDigits: decimals
        });
    },

    /**
     * تنسيق المبلغ المالي
     */
    formatCurrency: function(amount, currency = 'د.ع') {
        return this.formatNumber(amount, 0) + ' ' + currency;
    },

    /**
     * تنسيق التاريخ بالعربية
     */
    formatDateArabic: function(dateString) {
        if (!dateString) return '';
        
        try {
            let date;
            
            if (dateString instanceof Date) {
                date = dateString;
            } else if (typeof dateString === 'string') {
                if (dateString.includes('/')) {
                    const parts = dateString.split('/');
                    if (parts.length === 3) {
                        const day = parseInt(parts[0]);
                        const month = parseInt(parts[1]) - 1;
                        const year = parseInt(parts[2]);
                        date = new Date(year, month, day);
                    } else {
                        date = new Date(dateString);
                    }
                } else if (dateString.includes('-')) {
                    const parts = dateString.split('-');
                    if (parts.length === 3) {
                        const year = parseInt(parts[0]);
                        const month = parseInt(parts[1]) - 1;
                        const day = parseInt(parts[2]);
                        date = new Date(year, month, day);
                    } else {
                        date = new Date(dateString);
                    }
                } else {
                    date = new Date(dateString);
                }
            } else {
                date = new Date(dateString);
            }
            
            if (isNaN(date.getTime())) {
                return dateString;
            }
            
            const day = date.getDate();
            const month = date.getMonth() + 1;
            const year = date.getFullYear();
            
            const monthNames = [
                'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
                'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
            ];
            
            if (month < 1 || month > 12) {
                return dateString;
            }
            
            return `${day} ${monthNames[month - 1]} ${year}`;
        } catch (error) {
            console.error('خطأ في تنسيق التاريخ:', error, dateString);
            return dateString;
        }
    },

    /**
     * تنسيق الوقت
     */
    formatTime: function(dateString) {
        if (!dateString) return '';
        try {
            const date = new Date(dateString);
            return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
        } catch (error) {
            return dateString;
        }
    },

    // ============================================
    // Data Manipulation
    // ============================================

    /**
     * Deep clone object
     */
    deepClone: function(obj) {
        return JSON.parse(JSON.stringify(obj));
    },

    /**
     * Get nested property safely
     */
    getNestedProperty: function(obj, path, defaultValue = null) {
        const keys = path.split('.');
        let current = obj;
        
        for (const key of keys) {
            if (current === null || current === undefined || typeof current !== 'object') {
                return defaultValue;
            }
            current = current[key];
        }
        
        return current !== undefined ? current : defaultValue;
    },

    /**
     * Set nested property safely
     */
    setNestedProperty: function(obj, path, value) {
        const keys = path.split('.');
        const lastKey = keys.pop();
        let current = obj;
        
        for (const key of keys) {
            if (!current[key] || typeof current[key] !== 'object') {
                current[key] = {};
            }
            current = current[key];
        }
        
        current[lastKey] = value;
    },

    // ============================================
    // Array Operations
    // ============================================

    /**
     * Group array by key
     */
    groupBy: function(array, key) {
        return array.reduce((result, item) => {
            const groupKey = typeof key === 'function' ? key(item) : item[key];
            if (!result[groupKey]) {
                result[groupKey] = [];
            }
            result[groupKey].push(item);
            return result;
        }, {});
    },

    /**
     * Remove duplicates from array
     */
    unique: function(array, key = null) {
        if (!key) {
            return [...new Set(array)];
        }
        
        const seen = new Set();
        return array.filter(item => {
            const value = typeof key === 'function' ? key(item) : item[key];
            if (seen.has(value)) {
                return false;
            }
            seen.add(value);
            return true;
        });
    },

    // ============================================
    // Storage Helpers
    // ============================================

    /**
     * Safe localStorage get
     */
    storageGet: function(key, defaultValue = null) {
        try {
            const item = localStorage.getItem(key);
            return item ? JSON.parse(item) : defaultValue;
        } catch (error) {
            console.error(`خطأ في قراءة ${key} من localStorage:`, error);
            return defaultValue;
        }
    },

    /**
     * Safe localStorage set
     */
    storageSet: function(key, value) {
        try {
            localStorage.setItem(key, JSON.stringify(value));
            return true;
        } catch (error) {
            console.error(`خطأ في حفظ ${key} في localStorage:`, error);
            return false;
        }
    },

    /**
     * Safe localStorage remove
     */
    storageRemove: function(key) {
        try {
            localStorage.removeItem(key);
            return true;
        } catch (error) {
            console.error(`خطأ في حذف ${key} من localStorage:`, error);
            return false;
        }
    },

    // ============================================
    // Debounce & Throttle
    // ============================================

    /**
     * Debounce function
     */
    debounce: function(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },

    /**
     * Throttle function
     */
    throttle: function(func, limit) {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    },

    // ============================================
    // Error Handling
    // ============================================

    /**
     * Safe try-catch wrapper
     */
    safeExecute: function(func, errorMessage = 'حدث خطأ', defaultValue = null) {
        try {
            return func();
        } catch (error) {
            console.error(errorMessage, error);
            return defaultValue;
        }
    },

    /**
     * Safe async execute
     */
    safeExecuteAsync: async function(func, errorMessage = 'حدث خطأ', defaultValue = null) {
        try {
            return await func();
        } catch (error) {
            console.error(errorMessage, error);
            return defaultValue;
        }
    },

    // ============================================
    // URL Helpers
    // ============================================

    /**
     * Build WhatsApp URL
     */
    buildWhatsAppURL: function(phone, message) {
        const cleanedPhone = this.cleanPhone(phone);
        const encodedMessage = encodeURIComponent(message);
        return `https://wa.me/${cleanedPhone}?text=${encodedMessage}`;
    },

    // ============================================
    // Calculation Helpers
    // ============================================

    /**
     * Calculate sibling discount
     */
    calculateSiblingDiscount: function(siblingCount) {
        if (siblingCount >= 3) {
            return CONFIG.DISCOUNTS.SIBLING_3_PLUS;
        } else if (siblingCount === 2) {
            return CONFIG.DISCOUNTS.SIBLING_2;
        }
        return 0;
    },

    /**
     * Calculate final fee with discount
     */
    calculateFinalFee: function(annualFee, discountRate) {
        const discountAmount = annualFee * discountRate;
        return annualFee - discountAmount;
    }
};

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
    module.exports = Utils;
}

