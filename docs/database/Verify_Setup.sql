-- =============================================
-- Database Setup Verification
-- Description: Verify all Phase 1 tables and initial data are in place
-- =============================================

SET NOCOUNT ON;
GO

PRINT '========================================';
PRINT 'DATABASE SETUP VERIFICATION';
PRINT '========================================';
PRINT '';

-- =============================================
-- 1. Check all tables exist
-- =============================================
PRINT '1. Verifying Phase 1 Tables...';
PRINT '';

DECLARE @ExpectedTables TABLE (TableName NVARCHAR(100));
INSERT INTO @ExpectedTables VALUES 
    ('Users'), ('UserGroups'), ('UserGroupMembers'), ('Permissions'), ('GroupPermissions'),
    ('DocumentTypeGroups'), ('DocumentTypes'), ('Documents'), ('DocumentVersions'), 
    ('DocumentGroups'), ('IndexFields'), ('DocumentIndexData'), ('DocumentTypeIndexFields'),
    ('SystemSettings'), ('OcrQueue'), ('Notifications'), ('EmailQueue'), ('HelpContent'),
    ('AuditLogs');

SELECT 
    CASE 
        WHEN COUNT(*) = 19 THEN '✓ All 19 core tables exist'
        ELSE '✗ Missing ' + CAST(19 - COUNT(*) AS VARCHAR(10)) + ' tables'
    END AS TableStatus
FROM @ExpectedTables e
WHERE EXISTS (SELECT 1 FROM sys.tables t WHERE t.name = e.TableName);

-- Show any missing tables
IF EXISTS (
    SELECT 1 FROM @ExpectedTables e
    WHERE NOT EXISTS (SELECT 1 FROM sys.tables t WHERE t.name = e.TableName)
)
BEGIN
    PRINT '';
    PRINT 'Missing tables:';
    SELECT e.TableName
    FROM @ExpectedTables e
    WHERE NOT EXISTS (SELECT 1 FROM sys.tables t WHERE t.name = e.TableName);
END

PRINT '';

-- =============================================
-- 2. Check system admin user
-- =============================================
PRINT '2. Verifying System Admin User...';
PRINT '';

IF EXISTS (SELECT 1 FROM Users WHERE UserId = '00000000-0000-0000-0000-000000000001')
    PRINT '✓ System admin user exists (system.admin)';
ELSE
    PRINT '✗ System admin user NOT found';

-- =============================================
-- 3. Check System Administrators group
-- =============================================
PRINT '3. Verifying System Administrators Group...';
PRINT '';

DECLARE @SysAdminGroupExists BIT = 0;
DECLARE @SysAdminGroupId UNIQUEIDENTIFIER;

SELECT @SysAdminGroupExists = 1, @SysAdminGroupId = GroupId
FROM UserGroups 
WHERE GroupName = 'System Administrators';

IF @SysAdminGroupExists = 1
BEGIN
    PRINT '✓ System Administrators group exists';
    
    -- Check if system admin is member
    IF EXISTS (
        SELECT 1 FROM UserGroupMembers 
        WHERE GroupId = @SysAdminGroupId 
        AND UserId = '00000000-0000-0000-0000-000000000001'
        AND RemovedDate IS NULL
    )
        PRINT '✓ System admin is member of System Administrators';
    ELSE
        PRINT '✗ System admin is NOT a member of System Administrators';
END
ELSE
    PRINT '✗ System Administrators group NOT found';

PRINT '';

-- =============================================
-- 4. Check permissions
-- =============================================
PRINT '4. Verifying Permissions...';
PRINT '';

DECLARE @PermissionCount INT;
SELECT @PermissionCount = COUNT(*) FROM Permissions WHERE IsActive = 1;

PRINT '✓ ' + CAST(@PermissionCount AS VARCHAR(10)) + ' active permissions created';

-- Show permission breakdown by category
PRINT '';
PRINT 'Permissions by category:';
SELECT 
    Category,
    COUNT(*) as PermissionCount
FROM Permissions
WHERE IsActive = 1
GROUP BY Category
ORDER BY Category;

-- Check if System Administrators has all permissions
DECLARE @SysAdminPermCount INT = 0;
IF @SysAdminGroupExists = 1
BEGIN
    SELECT @SysAdminPermCount = COUNT(*)
    FROM GroupPermissions
    WHERE GroupId = @SysAdminGroupId
    AND RevokedDate IS NULL;
    
    PRINT '';
    IF @SysAdminPermCount = @PermissionCount
        PRINT '✓ System Administrators has all ' + CAST(@PermissionCount AS VARCHAR(10)) + ' permissions';
    ELSE
        PRINT '✗ System Administrators only has ' + CAST(@SysAdminPermCount AS VARCHAR(10)) + ' of ' + CAST(@PermissionCount AS VARCHAR(10)) + ' permissions';
END

PRINT '';

-- =============================================
-- 5. Check system settings
-- =============================================
PRINT '5. Verifying System Settings...';
PRINT '';

DECLARE @SettingsCount INT;
SELECT @SettingsCount = COUNT(*) FROM SystemSettings;

PRINT '✓ ' + CAST(@SettingsCount AS VARCHAR(10)) + ' system settings configured';

-- Show critical settings
PRINT '';
PRINT 'Critical settings:';
SELECT 
    SettingKey,
    SettingValue,
    CASE 
        WHEN SettingValue = '' OR SettingValue IS NULL THEN '⚠ NOT CONFIGURED'
        ELSE '✓ Configured'
    END AS Status
FROM SystemSettings
WHERE SettingKey IN (
    'General.OrganizationName',
    'Storage.BasePath',
    'Email.SmtpServer',
    'AD.Enabled'
)
ORDER BY SettingKey;

PRINT '';

-- =============================================
-- 6. Check full-text catalog
-- =============================================
PRINT '6. Verifying Full-Text Search...';
PRINT '';

IF EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = 'DocumentCatalog')
    PRINT '✓ DocumentCatalog full-text catalog exists';
ELSE
    PRINT '✗ DocumentCatalog full-text catalog NOT found';

PRINT '';

-- =============================================
-- 7. Summary
-- =============================================
PRINT '========================================';
PRINT 'SETUP VERIFICATION SUMMARY';
PRINT '========================================';
PRINT '';

-- Overall status
DECLARE @SetupComplete BIT = 1;

IF NOT EXISTS (SELECT 1 FROM Users WHERE UserId = '00000000-0000-0000-0000-000000000001')
    SET @SetupComplete = 0;

IF @SysAdminGroupExists = 0
    SET @SetupComplete = 0;

IF @PermissionCount < 40  -- Should have at least 40 permissions
    SET @SetupComplete = 0;

IF @SettingsCount < 50  -- Should have at least 50 settings
    SET @SetupComplete = 0;

IF @SetupComplete = 1
BEGIN
    PRINT '✓✓✓ DATABASE SETUP COMPLETE ✓✓✓';
    PRINT '';
    PRINT 'Your Document Management System database is ready!';
    PRINT '';
    PRINT 'Next Steps:';
    PRINT '  1. Create initial user groups (e.g., HR, Legal, Managers, End Users)';
    PRINT '  2. Create document type groups (e.g., Forms, Legal Docs, Reports)';
    PRINT '  3. Create document types with auto-numbering formats';
    PRINT '  4. Create index fields (e.g., FIRST NAME, LAST NAME, DATE, etc.)';
    PRINT '  5. Start building the Windows Forms applications:';
    PRINT '     - Main.exe (document upload, search, viewing)';
    PRINT '     - Config.exe (admin configuration)';
    PRINT '     - Scheduler.exe (background jobs: OCR, cleanup)';
END
ELSE
BEGIN
    PRINT '✗✗✗ SETUP INCOMPLETE ✗✗✗';
    PRINT '';
    PRINT 'Please review the errors above and complete the missing steps.';
END

PRINT '';
PRINT '========================================';

SET NOCOUNT OFF;
GO
