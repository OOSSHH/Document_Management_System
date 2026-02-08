-- =============================================
-- Migration: Remove IsRestricted Column from IndexFields
-- Description: Simplifies access control to use only IsSensitive flag + Search.ViewPII permission
-- Date: February 7, 2026
-- =============================================

SET NOCOUNT ON;
GO

BEGIN TRANSACTION;
BEGIN TRY

    PRINT 'Starting migration: Remove IsRestricted column from IndexFields table';
    
    -- Check if the column exists before attempting to drop it
    IF EXISTS (
        SELECT 1 
        FROM sys.columns 
        WHERE object_id = OBJECT_ID(N'dbo.IndexFields') 
        AND name = 'IsRestricted'
    )
    BEGIN
        PRINT 'IsRestricted column found. Proceeding with removal...';
        
        -- Step 1: Drop any default constraint on the IsRestricted column
        DECLARE @ConstraintName NVARCHAR(200);
        DECLARE @SQL NVARCHAR(MAX);
        
        SELECT @ConstraintName = dc.name
        FROM sys.default_constraints dc
        INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE c.object_id = OBJECT_ID(N'dbo.IndexFields')
        AND c.name = 'IsRestricted';
        
        IF @ConstraintName IS NOT NULL
        BEGIN
            PRINT 'Dropping default constraint: ' + @ConstraintName;
            SET @SQL = N'ALTER TABLE dbo.IndexFields DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
            EXEC sp_executesql @SQL;
            PRINT 'Default constraint dropped successfully.';
        END
        ELSE
        BEGIN
            PRINT 'No default constraint found on IsRestricted column.';
        END
        
        -- Step 2: Drop the IsRestricted column
        PRINT 'Dropping IsRestricted column...';
        ALTER TABLE dbo.IndexFields
        DROP COLUMN IsRestricted;
        
        PRINT 'Successfully removed IsRestricted column from IndexFields table.';
        PRINT '';
        PRINT 'Access control for sensitive index fields is now handled via:';
        PRINT '  - IsSensitive flag (marks PII/PHI fields)';
        PRINT '  - Search.ViewPII permission (controls who can view sensitive fields)';
    END
    ELSE
    BEGIN
        PRINT 'IsRestricted column does not exist. No changes needed.';
    END
    
    -- Commit the transaction
    COMMIT TRANSACTION;
    PRINT '';
    PRINT 'Migration completed successfully.';

END TRY
BEGIN CATCH
    -- Rollback on error
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    -- Display error information
    PRINT '';
    PRINT 'ERROR: Migration failed!';
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Error Message: ' + ERROR_MESSAGE();
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
    
    -- Re-throw the error
    THROW;
END CATCH;
GO

SET NOCOUNT OFF;
GO
