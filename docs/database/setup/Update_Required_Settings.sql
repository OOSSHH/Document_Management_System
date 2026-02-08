-- =============================================
-- Update Required System Settings
-- Description: Update organization name and storage path
-- =============================================

SET NOCOUNT ON;
GO

DECLARE @SystemAdminId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

PRINT 'Updating required system settings...';
PRINT '';

-- =============================================
-- UPDATE YOUR ORGANIZATION NAME
-- =============================================
UPDATE SystemSettings
SET SettingValue = 'Your Agency Name Here',  -- ⬅️ CHANGE THIS
    ModifiedDate = GETUTCDATE(),
    ModifiedBy = @SystemAdminId
WHERE SettingKey = 'General.OrganizationName';

PRINT '✓ Organization name updated to: ' + (SELECT SettingValue FROM SystemSettings WHERE SettingKey = 'General.OrganizationName');

-- =============================================
-- UPDATE YOUR FILE STORAGE PATH
-- =============================================
UPDATE SystemSettings
SET SettingValue = 'C:\DMS\Files',  -- ⬅️ CHANGE THIS to your actual path
    ModifiedDate = GETUTCDATE(),
    ModifiedBy = @SystemAdminId
WHERE SettingKey = 'Storage.BasePath';

PRINT '✓ Storage path updated to: ' + (SELECT SettingValue FROM SystemSettings WHERE SettingKey = 'Storage.BasePath');

-- =============================================
-- OPTIONAL: Update other settings
-- =============================================

-- Update application name (optional)
-- UPDATE SystemSettings
-- SET SettingValue = 'My Custom DMS Name',
--     ModifiedDate = GETUTCDATE(),
--     ModifiedBy = @SystemAdminId
-- WHERE SettingKey = 'General.ApplicationName';

-- Update log file path (optional)
-- UPDATE SystemSettings
-- SET SettingValue = 'C:\Logs\MyDMS',
--     ModifiedDate = GETUTCDATE(),
--     ModifiedBy = @SystemAdminId
-- WHERE SettingKey = 'Logging.LogFilePath';

PRINT '';
PRINT '========================================';
PRINT 'Settings Update Complete';
PRINT '========================================';

-- Show current values
SELECT 
    SettingKey,
    SettingValue,
    Description
FROM SystemSettings
WHERE SettingKey IN (
    'General.OrganizationName',
    'Storage.BasePath',
    'General.ApplicationName',
    'Logging.LogFilePath'
)
ORDER BY SettingKey;

SET NOCOUNT OFF;
GO
