-- =============================================
-- Step 8: Insert SystemSettings for Configuration
-- Description: Populate initial system configuration settings
-- =============================================

SET NOCOUNT ON;
GO

DECLARE @SystemAdminId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

PRINT 'Inserting system configuration settings...';

-- =============================================
-- AUDIT LOG RETENTION SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    -- Audit Retention Periods (in days)
    ('AuditLog.Retention.Authentication', '90', 'Int', 'Audit', 'Login/logout logs retained for 90 days', @SystemAdminId),
    ('AuditLog.Retention.Documents', '2555', 'Int', 'Audit', '7 years (legal requirement)', @SystemAdminId),
    ('AuditLog.Retention.DocumentAccess', '365', 'Int', 'Audit', 'Who viewed documents - 1 year', @SystemAdminId),
    ('AuditLog.Retention.Users', '1825', 'Int', 'Audit', 'User changes - 5 years', @SystemAdminId),
    ('AuditLog.Retention.UserGroups', '1825', 'Int', 'Audit', 'Group changes - 5 years', @SystemAdminId),
    ('AuditLog.Retention.GroupMemberships', '1095', 'Int', 'Audit', 'Membership changes - 3 years', @SystemAdminId),
    ('AuditLog.Retention.GroupPermissions', '1825', 'Int', 'Audit', 'Permission changes - 5 years', @SystemAdminId),
    ('AuditLog.Retention.DocumentTypes', '3650', 'Int', 'Audit', 'Config changes - 10 years', @SystemAdminId),
    ('AuditLog.Retention.IndexFields', '730', 'Int', 'Audit', 'Index field changes - 2 years', @SystemAdminId),
    ('AuditLog.Retention.SystemSettings', '3650', 'Int', 'Audit', 'System config - 10 years', @SystemAdminId),
    
    -- Audit Cleanup Job
    ('AuditLog.Cleanup.Enabled', 'true', 'Bool', 'Audit', 'Enable automatic cleanup job', @SystemAdminId),
    ('AuditLog.Cleanup.Schedule', '0 2 * * 0', 'String', 'Audit', 'Cron: Run Sunday 2 AM', @SystemAdminId);

PRINT 'Audit log retention settings inserted.';

-- =============================================
-- FILE STORAGE SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('Storage.DefaultMaxFileSizeBytes', '104857600', 'Int', 'Storage', 'Default max file size: 100 MB', @SystemAdminId),
    ('Storage.BasePath', '\\fileserver\docs', 'String', 'Storage', 'Base path for file storage', @SystemAdminId),
    ('Storage.UseGuidFolders', 'true', 'Bool', 'Storage', 'Organize files in GUID subfolders', @SystemAdminId),
    ('Storage.AllowedFileExtensions', 'pdf,doc,docx,xls,xlsx,jpg,jpeg,png,gif,txt,csv,zip', 'String', 'Storage', 'Comma-separated allowed file types', @SystemAdminId);

PRINT 'File storage settings inserted.';

-- =============================================
-- OCR SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('OCR.Enabled', 'true', 'Bool', 'OCR', 'Enable OCR processing', @SystemAdminId),
    ('OCR.AutoProcess', 'true', 'Bool', 'OCR', 'Automatically queue documents for OCR', @SystemAdminId),
    ('OCR.MaxRetries', '3', 'Int', 'OCR', 'Maximum retry attempts for failed OCR', @SystemAdminId),
    ('OCR.ProcessingTimeout', '300', 'Int', 'OCR', 'OCR processing timeout in seconds', @SystemAdminId),
    ('OCR.SupportedFileTypes', 'pdf,jpg,jpeg,png,tif,tiff', 'String', 'OCR', 'File types that support OCR', @SystemAdminId);

PRINT 'OCR settings inserted.';

-- =============================================
-- EMAIL SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, IsSensitive, ModifiedBy)
VALUES 
    ('Email.SmtpServer', 'smtp.youragency.gov', 'String', 'Email', 'SMTP server address', 0, @SystemAdminId),
    ('Email.SmtpPort', '587', 'Int', 'Email', 'SMTP server port', 0, @SystemAdminId),
    ('Email.UseSsl', 'true', 'Bool', 'Email', 'Use SSL/TLS for SMTP', 0, @SystemAdminId),
    ('Email.FromAddress', 'noreply@youragency.gov', 'String', 'Email', 'Default sender email address', 0, @SystemAdminId),
    ('Email.FromName', 'Document Management System', 'String', 'Email', 'Default sender display name', 0, @SystemAdminId),
    ('Email.Username', '', 'String', 'Email', 'SMTP authentication username', 1, @SystemAdminId),
    ('Email.Password', '', 'String', 'Email', 'SMTP authentication password (encrypted)', 1, @SystemAdminId),
    ('Email.MaxRetries', '3', 'Int', 'Email', 'Maximum retry attempts for failed emails', 0, @SystemAdminId),
    ('Email.RetryDelayMinutes', '5', 'Int', 'Email', 'Delay between email retry attempts', 0, @SystemAdminId);

PRINT 'Email settings inserted.';

-- =============================================
-- SECURITY SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('Security.PasswordMinLength', '8', 'Int', 'Security', 'Minimum password length', @SystemAdminId),
    ('Security.PasswordRequireUppercase', 'true', 'Bool', 'Security', 'Require uppercase letters', @SystemAdminId),
    ('Security.PasswordRequireLowercase', 'true', 'Bool', 'Security', 'Require lowercase letters', @SystemAdminId),
    ('Security.PasswordRequireDigit', 'true', 'Bool', 'Security', 'Require numeric digits', @SystemAdminId),
    ('Security.PasswordRequireSpecialChar', 'true', 'Bool', 'Security', 'Require special characters', @SystemAdminId),
    ('Security.PasswordExpirationDays', '90', 'Int', 'Security', 'Password expiration period', @SystemAdminId),
    ('Security.MaxFailedLoginAttempts', '5', 'Int', 'Security', 'Max failed login attempts before lockout', @SystemAdminId),
    ('Security.LockoutDurationMinutes', '30', 'Int', 'Security', 'Account lockout duration', @SystemAdminId),
    ('Security.SessionTimeoutMinutes', '60', 'Int', 'Security', 'Idle session timeout', @SystemAdminId),
    ('Security.RequireMfa', 'false', 'Bool', 'Security', 'Require multi-factor authentication', @SystemAdminId);

PRINT 'Security settings inserted.';

-- =============================================
-- NOTIFICATION SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('Notification.Enabled', 'true', 'Bool', 'Notifications', 'Enable in-app notifications', @SystemAdminId),
    ('Notification.DefaultExpirationDays', '30', 'Int', 'Notifications', 'Default notification expiration', @SystemAdminId),
    ('Notification.SendEmail', 'true', 'Bool', 'Notifications', 'Send email for notifications', @SystemAdminId),
    ('Notification.EmailDigestEnabled', 'false', 'Bool', 'Notifications', 'Send daily digest emails', @SystemAdminId),
    ('Notification.EmailDigestTime', '08:00', 'String', 'Notifications', 'Daily digest send time (HH:mm)', @SystemAdminId);

PRINT 'Notification settings inserted.';

-- =============================================
-- GENERAL SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('General.ApplicationName', 'Document Management System', 'String', 'General', 'Application display name', @SystemAdminId),
    ('General.OrganizationName', 'Your Agency Name', 'String', 'General', 'Organization name', @SystemAdminId),
    ('General.DefaultLanguage', 'en-US', 'String', 'General', 'Default language/locale', @SystemAdminId),
    ('General.DefaultTimeZone', 'UTC', 'String', 'General', 'Default timezone', @SystemAdminId),
    ('General.DateFormat', 'MM/dd/yyyy', 'String', 'General', 'Default date format', @SystemAdminId),
    ('General.TimeFormat', 'hh:mm tt', 'String', 'General', 'Default time format', @SystemAdminId),
    ('General.PageSize', '25', 'Int', 'General', 'Default records per page', @SystemAdminId),
    ('General.EnableFullTextSearch', 'true', 'Bool', 'General', 'Enable full-text search', @SystemAdminId);

PRINT 'General settings inserted.';

-- =============================================
-- DOCUMENT SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('Document.DefaultStatus', 'Active', 'String', 'Documents', 'Default document status on upload', @SystemAdminId),
    ('Document.EnableVersioning', 'true', 'Bool', 'Documents', 'Enable document versioning', @SystemAdminId),
    ('Document.MaxVersionsToKeep', '0', 'Int', 'Documents', 'Max versions to keep (0 = unlimited)', @SystemAdminId),
    ('Document.RequireDocumentType', 'true', 'Bool', 'Documents', 'Require document type selection', @SystemAdminId),
    ('Document.AllowDuplicateFileNames', 'true', 'Bool', 'Documents', 'Allow duplicate file names', @SystemAdminId),
    ('Document.DefaultRetentionDays', '0', 'Int', 'Documents', 'Default retention period (0 = forever)', @SystemAdminId);

PRINT 'Document settings inserted.';

-- =============================================
-- ACTIVE DIRECTORY SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, IsSensitive, ModifiedBy)
VALUES 
    ('AD.Enabled', 'false', 'Bool', 'Active Directory', 'Enable Active Directory integration', 0, @SystemAdminId),
    ('AD.Domain', '', 'String', 'Active Directory', 'AD domain name', 0, @SystemAdminId),
    ('AD.LdapPath', '', 'String', 'Active Directory', 'LDAP connection path', 0, @SystemAdminId),
    ('AD.Username', '', 'String', 'Active Directory', 'AD service account username', 1, @SystemAdminId),
    ('AD.Password', '', 'String', 'Active Directory', 'AD service account password (encrypted)', 1, @SystemAdminId),
    ('AD.AutoCreateUsers', 'true', 'Bool', 'Active Directory', 'Auto-create users on first AD login', 0, @SystemAdminId),
    ('AD.SyncInterval', '60', 'Int', 'Active Directory', 'User sync interval in minutes', 0, @SystemAdminId);

PRINT 'Active Directory settings inserted.';

-- =============================================
-- SEARCH SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('Search.MaxResults', '1000', 'Int', 'Search', 'Maximum search results to return', @SystemAdminId),
    ('Search.MinSearchLength', '3', 'Int', 'Search', 'Minimum search term length', @SystemAdminId),
    ('Search.EnableWildcard', 'true', 'Bool', 'Search', 'Enable wildcard search', @SystemAdminId),
    ('Search.HighlightResults', 'true', 'Bool', 'Search', 'Highlight search terms in results', @SystemAdminId);

PRINT 'Search settings inserted.';

-- =============================================
-- PERFORMANCE SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('Performance.CacheEnabled', 'true', 'Bool', 'Performance', 'Enable application caching', @SystemAdminId),
    ('Performance.CacheDurationMinutes', '30', 'Int', 'Performance', 'Default cache duration', @SystemAdminId),
    ('Performance.EnableCompression', 'true', 'Bool', 'Performance', 'Enable response compression', @SystemAdminId),
    ('Performance.MaxConcurrentUploads', '5', 'Int', 'Performance', 'Max concurrent file uploads per user', @SystemAdminId);

PRINT 'Performance settings inserted.';

-- =============================================
-- LOGGING SETTINGS
-- =============================================
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description, ModifiedBy)
VALUES 
    ('Logging.Level', 'Information', 'String', 'Logging', 'Minimum log level (Debug, Information, Warning, Error)', @SystemAdminId),
    ('Logging.LogToFile', 'true', 'Bool', 'Logging', 'Write logs to file', @SystemAdminId),
    ('Logging.LogToDatabase', 'true', 'Bool', 'Logging', 'Write logs to database', @SystemAdminId),
    ('Logging.LogFilePath', 'C:\Logs\DMS', 'String', 'Logging', 'Log file directory path', @SystemAdminId),
    ('Logging.LogFileRetentionDays', '30', 'Int', 'Logging', 'Log file retention period', @SystemAdminId);

PRINT 'Logging settings inserted.';

-- =============================================
-- SUMMARY
-- =============================================
DECLARE @SettingCount INT;
SELECT @SettingCount = COUNT(*) FROM SystemSettings;

PRINT '';
PRINT '========================================';
PRINT 'SystemSettings Configuration Complete';
PRINT '========================================';
PRINT 'Total settings inserted: ' + CAST(@SettingCount AS VARCHAR(10));
PRINT '';
PRINT 'Settings by category:';
SELECT Category, COUNT(*) as SettingCount
FROM SystemSettings
GROUP BY Category
ORDER BY Category;

PRINT '';
PRINT 'Action Required:';
PRINT '  1. Update Email.SmtpServer, Email.Username, Email.Password with your SMTP credentials';
PRINT '  2. Update Storage.BasePath to your actual file storage location';
PRINT '  3. Update General.OrganizationName with your organization name';
PRINT '  4. Configure Active Directory settings if using AD integration';
PRINT '  5. Review and adjust retention periods based on compliance requirements';

SET NOCOUNT OFF;
GO
