// ===========================
// نظام النسخ الاحتياطي في قاعدة البيانات
// JavaScript Integration
// ===========================

// إعدادات النسخ الاحتياطي في قاعدة البيانات
let databaseBackupSettings = {
    enabled: true,
    autoBackupInterval: 24, // ساعات
    maxBackupSize: 100, // ميجابايت
    compressionEnabled: true,
    encryptionEnabled: false,
    includeLogs: true,
    logsLimit: 1000,
    cleanupEnabled: true,
    cleanupDays: 30
};

// تهيئة نظام النسخ الاحتياطي في قاعدة البيانات
async function initializeDatabaseBackupSystem() {
    console.log('Initializing database backup system...');
    
    try {
        // تحميل الإعدادات من قاعدة البيانات
        await loadBackupSettings();
        
        // بدء النسخ التلقائي
        if (databaseBackupSettings.enabled) {
            startDatabaseAutoBackup();
        }
        
        console.log('Database backup system initialized successfully');
        
    } catch (error) {
        console.error('Error initializing database backup system:', error);
    }
}

// تحميل إعدادات النسخ الاحتياطي من قاعدة البيانات
async function loadBackupSettings() {
    try {
        const { data, error } = await appState.supabase
            .from('backup_settings')
            .select('setting_name, setting_value, setting_type');
        
        if (error) throw error;
        
        // تطبيق الإعدادات
        data.forEach(setting => {
            const value = setting.setting_type === 'boolean' ? 
                setting.setting_value === 'true' : 
                setting.setting_type === 'number' ? 
                parseInt(setting.setting_value) : 
                setting.setting_value;
            
            switch (setting.setting_name) {
                case 'auto_backup_enabled':
                    databaseBackupSettings.enabled = value;
                    break;
                case 'auto_backup_interval_hours':
                    databaseBackupSettings.autoBackupInterval = value;
                    break;
                case 'max_backup_size_mb':
                    databaseBackupSettings.maxBackupSize = value;
                    break;
                case 'compression_enabled':
                    databaseBackupSettings.compressionEnabled = value;
                    break;
                case 'encryption_enabled':
                    databaseBackupSettings.encryptionEnabled = value;
                    break;
                case 'include_logs':
                    databaseBackupSettings.includeLogs = value;
                    break;
                case 'logs_limit':
                    databaseBackupSettings.logsLimit = value;
                    break;
                case 'cleanup_enabled':
                    databaseBackupSettings.cleanupEnabled = value;
                    break;
                case 'cleanup_days':
                    databaseBackupSettings.cleanupDays = value;
                    break;
            }
        });
        
    } catch (error) {
        console.error('Error loading backup settings:', error);
    }
}

// إنشاء نسخة احتياطية في قاعدة البيانات
async function createDatabaseBackup(backupName = null, description = null) {
    try {
        if (!appState.supabase) {
            throw new Error('Supabase not initialized');
        }
        
        showLoading();
        
        const { data, error } = await appState.supabase.rpc('create_system_backup', {
            backup_name_param: backupName,
            backup_type_param: 'manual',
            created_by_param: appState.currentUser?.id,
            description_param: description,
            include_logs: databaseBackupSettings.includeLogs,
            logs_limit: databaseBackupSettings.logsLimit
        });
        
        if (error) throw error;
        
        if (data.success) {
            showSuccess(`تم إنشاء النسخة الاحتياطية بنجاح! (${data.backup_name})`);
            await loadDatabaseBackups();
        } else {
            showError('خطأ في إنشاء النسخة الاحتياطية: ' + data.error);
        }
        
    } catch (error) {
        console.error('Error creating database backup:', error);
        showError('خطأ في إنشاء النسخة الاحتياطية: ' + error.message);
    } finally {
        hideLoading();
    }
}

// استعادة نسخة احتياطية من قاعدة البيانات
async function restoreDatabaseBackup(backupId, restoreType = 'full') {
    try {
        if (!appState.supabase) {
            throw new Error('Supabase not initialized');
        }
        
        // تأكيد من المستخدم
        if (!confirm('هل أنت متأكد من استعادة هذه النسخة الاحتياطية؟ سيتم استبدال البيانات الحالية!')) {
            return;
        }
        
        showLoading();
        
        const { data, error } = await appState.supabase.rpc('restore_system_backup', {
            backup_id_param: backupId,
            restore_type: restoreType,
            created_by_param: appState.currentUser?.id
        });
        
        if (error) throw error;
        
        if (data.success) {
            showSuccess(`تم استعادة ${data.restored_count} عنصر بنجاح!${data.error_count > 0 ? ` (${data.error_count} أخطاء)` : ''}`);
            
            // إعادة تحميل البيانات
            await loadAllData();
        } else {
            showError('خطأ في استعادة النسخة الاحتياطية: ' + data.error);
        }
        
    } catch (error) {
        console.error('Error restoring database backup:', error);
        showError('خطأ في استعادة النسخة الاحتياطية: ' + error.message);
    } finally {
        hideLoading();
    }
}

// عرض النسخ الاحتياطية من قاعدة البيانات
async function loadDatabaseBackups() {
    try {
        if (!appState.supabase) {
            throw new Error('Supabase not initialized');
        }
        
        const { data, error } = await appState.supabase.rpc('list_system_backups', {
            limit_param: 50,
            offset_param: 0,
            backup_type_filter: null
        });
        
        if (error) throw error;
        
        if (data.success) {
            displayDatabaseBackups(data.backups);
            updateDatabaseBackupStatus(data.total_count);
        } else {
            showError('خطأ في جلب النسخ الاحتياطية: ' + data.error);
        }
        
    } catch (error) {
        console.error('Error loading database backups:', error);
        showError('خطأ في جلب النسخ الاحتياطية: ' + error.message);
    }
}

// عرض النسخ الاحتياطية في الواجهة
function displayDatabaseBackups(backups) {
    const container = document.getElementById('databaseBackupsList');
    if (!container) return;
    
    if (!backups || backups.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: var(--text-secondary);">لا توجد نسخ احتياطية</p>';
        return;
    }
    
    container.innerHTML = '';
    
    backups.forEach((backup, index) => {
        const isLatest = index === 0;
        const date = new Date(backup.created_at).toLocaleString('ar-SA');
        const size = formatFileSize(backup.backup_size);
        
        const backupItem = document.createElement('div');
        backupItem.className = 'backup-item';
        backupItem.style.cssText = `
            margin: 10px 0; 
            padding: 15px; 
            border: 2px solid ${isLatest ? '#28a745' : '#dee2e6'}; 
            border-radius: 8px; 
            background: ${isLatest ? '#f8fff8' : '#f8f9fa'};
        `;
        
        backupItem.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <strong style="color: ${isLatest ? '#28a745' : '#495057'};">${backup.backup_name}</strong>
                    ${isLatest ? '<span style="background: #28a745; color: white; padding: 2px 8px; border-radius: 10px; font-size: 0.8em; margin-right: 10px;">الأحدث</span>' : ''}
                    <br>
                    <small style="color: #6c757d;">التاريخ: ${date}</small><br>
                    <small style="color: #6c757d;">النوع: ${backup.backup_type} | الحجم: ${size}</small><br>
                    <small style="color: #6c757d;">
                        المراكز: ${backup.metadata.total_centers} | 
                        المستخدمين: ${backup.metadata.total_users} | 
                        الموظفين: ${backup.metadata.total_employees}
                    </small>
                </div>
                <div>
                    <button onclick="testDatabaseBackup(${backup.id})" class="btn btn-info" style="margin: 2px;">
                        🔍 اختبار
                    </button>
                    <button onclick="restoreDatabaseBackup(${backup.id})" class="btn btn-warning" style="margin: 2px;">
                        🔄 استعادة
                    </button>
                    <button onclick="deleteDatabaseBackup(${backup.id})" class="btn btn-danger" style="margin: 2px;">
                        🗑️ حذف
                    </button>
                </div>
            </div>
        `;
        
        container.appendChild(backupItem);
    });
}

// اختبار النسخة الاحتياطية
async function testDatabaseBackup(backupId) {
    try {
        if (!appState.supabase) {
            throw new Error('Supabase not initialized');
        }
        
        const { data, error } = await appState.supabase
            .from('system_backups')
            .select('backup_name, backup_data, created_at')
            .eq('id', backupId)
            .single();
        
        if (error) throw error;
        
        const backupData = data.backup_data;
        const metadata = backupData.metadata;
        const dataSection = backupData.data;
        
        let summary = `
            <h3>محتوى النسخة الاحتياطية: ${data.backup_name}</h3>
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0;">
                <strong>📊 إحصائيات النسخة:</strong><br>
                • المراكز: ${metadata.database_info.total_centers}<br>
                • المستخدمين: ${metadata.database_info.total_users}<br>
                • الموظفين: ${metadata.database_info.total_employees}<br>
                • السجلات: ${metadata.database_info.total_logs}<br>
                • تاريخ النسخة: ${new Date(metadata.created_at).toLocaleString('ar-SA')}<br>
                • نوع النسخة: ${metadata.backup_type}
            </div>
        `;
        
        if (dataSection.centers && dataSection.centers.length > 0) {
            summary += '<div style="margin: 10px 0;"><strong>🏢 المراكز:</strong><ul>';
            dataSection.centers.forEach(center => {
                summary += `<li>${center.name} (${center.latitude}, ${center.longitude})</li>`;
            });
            summary += '</ul></div>';
        }
        
        if (dataSection.users && dataSection.users.length > 0) {
            summary += '<div style="margin: 10px 0;"><strong>👥 المستخدمين:</strong><ul>';
            dataSection.users.forEach(user => {
                summary += `<li>${user.full_name} (${user.username}) - ${user.role}</li>`;
            });
            summary += '</ul></div>';
        }
        
        if (dataSection.employees && dataSection.employees.length > 0) {
            summary += '<div style="margin: 10px 0;"><strong>👤 الموظفين:</strong><ul>';
            dataSection.employees.forEach(employee => {
                summary += `<li>${employee.name} (${employee.phone})</li>`;
            });
            summary += '</ul></div>';
        }
        
        // عرض النافذة المنبثقة
        const modal = document.createElement('div');
        modal.className = 'modal';
        modal.style.display = 'flex';
        modal.innerHTML = `
            <div class="modal-content" style="max-width: 600px;">
                <div class="modal-header">
                    <h2>🔍 اختبار النسخة الاحتياطية</h2>
                    <span class="close" onclick="this.closest('.modal').remove()">&times;</span>
                </div>
                <div style="padding: 20px;">
                    ${summary}
                </div>
                <div style="text-align: center; padding: 20px;">
                    <button class="btn btn-warning" onclick="restoreDatabaseBackup(${backupId}); this.closest('.modal').remove();" style="margin: 5px;">
                        🔄 استعادة هذه النسخة
                    </button>
                    <button class="btn" onclick="this.closest('.modal').remove()" style="margin: 5px;">إغلاق</button>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
    } catch (error) {
        console.error('Error testing database backup:', error);
        showError('خطأ في اختبار النسخة الاحتياطية: ' + error.message);
    }
}

// حذف النسخة الاحتياطية
async function deleteDatabaseBackup(backupId) {
    try {
        if (!confirm('هل أنت متأكد من حذف هذه النسخة الاحتياطية؟ لا يمكن التراجع عن هذا الإجراء.')) {
            return;
        }
        
        if (!appState.supabase) {
            throw new Error('Supabase not initialized');
        }
        
        const { data, error } = await appState.supabase.rpc('delete_system_backup', {
            backup_id_param: backupId,
            deleted_by_param: appState.currentUser?.id
        });
        
        if (error) throw error;
        
        if (data.success) {
            showSuccess(data.message);
            await loadDatabaseBackups();
        } else {
            showError('خطأ في حذف النسخة الاحتياطية: ' + data.error);
        }
        
    } catch (error) {
        console.error('Error deleting database backup:', error);
        showError('خطأ في حذف النسخة الاحتياطية: ' + error.message);
    }
}

// النسخ التلقائي في قاعدة البيانات
let databaseAutoBackupInterval;

function startDatabaseAutoBackup() {
    if (databaseAutoBackupInterval) {
        clearInterval(databaseAutoBackupInterval);
    }
    
    if (databaseBackupSettings.enabled && databaseBackupSettings.autoBackupInterval > 0) {
        const intervalMs = databaseBackupSettings.autoBackupInterval * 60 * 60 * 1000;
        
        databaseAutoBackupInterval = setInterval(async () => {
            try {
                console.log('Starting automatic database backup...');
                await createDatabaseBackup(null, 'نسخة احتياطية تلقائية');
            } catch (error) {
                console.error('Auto database backup failed:', error);
            }
        }, intervalMs);
        
        console.log(`Database auto backup started - interval: ${databaseBackupSettings.autoBackupInterval} hours`);
    }
}

// تحديث حالة النسخ الاحتياطي في قاعدة البيانات
function updateDatabaseBackupStatus(totalCount) {
    const statusElement = document.getElementById('databaseBackupStatus');
    if (statusElement) {
        statusElement.innerHTML = `
            <strong>النسخ الاحتياطية في قاعدة البيانات:</strong><br>
            <small>إجمالي النسخ: ${totalCount}</small><br>
            <small>الحفظ التلقائي: ${databaseBackupSettings.enabled ? 'مفعل' : 'معطل'}</small>
        `;
    }
}

// تنظيف النسخ القديمة
async function cleanupOldDatabaseBackups() {
    try {
        if (!appState.supabase) {
            throw new Error('Supabase not initialized');
        }
        
        const { data, error } = await appState.supabase.rpc('cleanup_old_backups', {
            days_to_keep: databaseBackupSettings.cleanupDays,
            keep_manual_backups: true
        });
        
        if (error) throw error;
        
        if (data.success) {
            showSuccess(data.message);
            await loadDatabaseBackups();
        } else {
            showError('خطأ في تنظيف النسخ القديمة: ' + data.error);
        }
        
    } catch (error) {
        console.error('Error cleaning up old backups:', error);
        showError('خطأ في تنظيف النسخ القديمة: ' + error.message);
    }
}

// تنسيق حجم الملف
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// تسجيل الدوال في window object
window.createDatabaseBackup = createDatabaseBackup;
window.restoreDatabaseBackup = restoreDatabaseBackup;
window.loadDatabaseBackups = loadDatabaseBackups;
window.testDatabaseBackup = testDatabaseBackup;
window.deleteDatabaseBackup = deleteDatabaseBackup;
window.cleanupOldDatabaseBackups = cleanupOldDatabaseBackups;
window.initializeDatabaseBackupSystem = initializeDatabaseBackupSystem;
