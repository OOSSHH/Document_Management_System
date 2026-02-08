# Database Schema Design
**Document Management System**

**Version**: 0.4 (Phase 1 Draft)  
**Status**: Design Phase - Complete and ready for implementation  
**Last Updated**: January 26, 2026

**Change Log**:
- v0.4 (Jan 26): Redesigned index field system - Keywords → IndexFields with structured field/value storage for searchable data (FIRST NAME = 'Bob', SSN = '123456798')
- v0.3 (Jan 26): Added DocumentTypeGroups, DocumentTypes, DocumentTypeIndexFields tables; finalized auto-numbering, file storage, audit retention, and access inheritance; resolved 9 major design questions
- v0.2 (Jan 25): Simplified to UserGroups-only model (removed Roles/Departments); split into Phase 1 (17 tables) vs Phase 2 (deferred)
- v0.1 (Jan 24): Initial schema draft with 33 tables

---

## Table of Contents
1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Phase 1: Core Schema](#phase-1-core-schema)
   - [Entity Relationship Diagram](#entity-relationship-diagram)
   - [Identity & Access Tables](#identity--access-tables)
   - [Document Management Tables](#document-management-tables)
   - [System Tables](#system-tables)
4. [Indexing Strategy](#indexing-strategy)
5. [Performance Considerations](#performance-considerations)
6. [Open Questions & Refinements](#open-questions--refinements)
7. [Phase 2: Deferred Tables](#phase-2-deferred-tables)

---

## Overview

This document defines the database schema for the Document Management System, designed specifically for government agencies with flexible user group-based access control.

**Development Approach**: Phased implementation focusing on core document management first.

### Phase 1: Document Management Core (CURRENT FOCUS)
- **Simplified Access Model**: UserGroups handle both permissions AND data access (no separate Roles)
- **No Department Constraints**: Groups can represent departments, teams, projects, or any structure
- Document versioning with full history
- Hierarchical keywords/tagging
- OCR processing queue
- Comprehensive audit logging
- User preferences and notifications
- System configuration

### Phase 2: Advanced Features (DEFERRED)
- Workflow engine with custom actions
- Form builder and submissions
- Scheduled automation and tasks
- Advanced reporting
- Third-party integrations

**Database**: SQL Server 2022 (primary) / PostgreSQL 15+ (alternative)  
**Phase 1 Core Tables**: 16 + 11 audit tables = **27 total**

**Key Design Decisions**:
- ✅ UserGroups-only model (no separate Roles or Departments)
- ✅ Index fields with structured values (FIRST NAME = 'Bob', searchable per field)
- ✅ Auto-numbering per document type (e.g., IR-2026-00001)
- ✅ File storage: GUID-based keys, human-readable document numbers
- ✅ Audit retention: Configurable per table type with automatic cleanup
- ✅ Document access: Auto-inherit from group permissions
- ✅ File type handling: Preferred types with warnings (Option B)
- ✅ Two-tier admin: IsGroupAdmin (per-group) + UserGroup.Manage (global)

---

## Design Principles

1. **Simplicity First**: One concept (UserGroups) for both permissions and data access - no separate Roles table
2. **Flexibility Over Rigidity**: User groups can represent any organizational structure (departments optional)
3. **Audit Everything**: Temporal tables for change tracking
4. **Soft Deletes**: Never hard-delete data (compliance requirement)
5. **Denormalization Where Needed**: Performance over purity for read-heavy operations
6. **JSON for Flexibility**: Use JSON columns for extensible data (action parameters, form fields)
7. **Foreign Key Constraints**: Maintain referential integrity
8. **Indexes for Performance**: Strategic indexing on all query patterns

---

## Phase 1: Core Schema

### Entity Relationship Diagram

**Phase 1 focuses on document management fundamentals:**

```
┌─────────────────────────────────────────────────────────────────┐
│                  IDENTITY & ACCESS CONTROL                       │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│    Users     │  UserGroups  │ GroupMembers │   Permissions      │
│              │              │              │                    │
│              │              │              │  GroupPermissions  │
└──────┬───────┴──────┬───────┴──────┬───────┴──────┬─────────────┘
       │              │              │              │
       └──────────────┴──────────────┴──────────────┘
                      │
       ┌──────────────▼──────────────────────────────┐
       │         DOCUMENT MANAGEMENT                 │
       ├──────────────┬──────────────┬───────────────┤
       │  Documents   │  DocVersions │ DocumentGroups│
       │              │              │               │
       │  Keywords    │DocKeywords   │   OcrQueue    │
       └──────┬───────┴──────┬───────┴───────┬───────┘
              │              │               │
       ┌──────▼──────────────▼───────────────▼───────┐
       │           SYSTEM & AUDIT                     │
       ├──────────────┬──────────────┬───────────────┤
       │  AuditLogs   │  Settings    │ Notifications │
       │              │              │               │
       │  HelpContent │              │               │
       └──────────────┴──────────────┴───────────────┘
```

**Key Relationships**:
- Users belong to UserGroups (many-to-many via UserGroupMembers)
- UserGroups have Permissions (many-to-many via GroupPermissions)
- Documents visible to UserGroups (many-to-many via DocumentGroups)
- Documents have Keywords (many-to-many via DocumentKeywords)
- Documents have Versions (one-to-many DocumentVersions)
- Documents queued for OCR (one-to-many OcrQueue)

---

## Identity & Access Tables

### 1. Users
Primary user identity table - integrates with Active Directory

```sql
CREATE TABLE Users (
    UserId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    -- Identity
    Username NVARCHAR(100) NOT NULL UNIQUE,
    Email NVARCHAR(255) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    DisplayName NVARCHAR(200) NOT NULL,
    
    -- Authentication
    PasswordHash NVARCHAR(255) NULL,  -- NULL if AD-only
    ActiveDirectoryId NVARCHAR(255) NULL,
    ActiveDirectorySid NVARCHAR(255) NULL,
    
    -- Organization (Metadata Only)
    JobTitle NVARCHAR(100) NULL,
    EmployeeId NVARCHAR(50) NULL,
    
    -- Status
    IsActive BIT NOT NULL DEFAULT 1,
    IsSystemAdmin BIT NOT NULL DEFAULT 0,  -- Full system access
    MustChangePassword BIT NOT NULL DEFAULT 0,
    LastLoginDate DATETIME2 NULL,
    FailedLoginAttempts INT NOT NULL DEFAULT 0,
    LockedOutUntil DATETIME2 NULL,
    
    -- Preferences
    PreferredLanguage NVARCHAR(10) NULL DEFAULT 'en-US',
    TimeZone NVARCHAR(50) NULL DEFAULT 'UTC',
    ThemePreference NVARCHAR(20) NULL,  -- 'light', 'dark', 'auto'
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy UNIQUEIDENTIFIER NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NULL,
    DeletedDate DATETIME2 NULL,  -- Soft delete
    DeletedBy UNIQUEIDENTIFIER NULL,
    
    CONSTRAINT FK_Users_CreatedBy FOREIGN KEY (CreatedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT FK_Users_ModifiedBy FOREIGN KEY (ModifiedBy) 
        REFERENCES Users(UserId)
);

CREATE INDEX IX_Users_Username ON Users(Username) WHERE DeletedDate IS NULL;
CREATE INDEX IX_Users_Email ON Users(Email) WHERE DeletedDate IS NULL;
CREATE INDEX IX_Users_ADId ON Users(ActiveDirectoryId) WHERE ActiveDirectoryId IS NOT NULL;
```

### 2. UserGroups
**THE KEY TABLE** - Flexible groups for access control

```sql
CREATE TABLE UserGroups (
    GroupId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    GroupName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500) NULL,
    
    -- Group Type (helps with organization, but not enforced)
    GroupType NVARCHAR(50) NULL,  -- 'Department', 'Project', 'Team', 'Role', 'External', 'Custom'
    
    -- Hierarchy Support
    ParentGroupId UNIQUEIDENTIFIER NULL,  -- Nested groups
    
    -- Visibility
    IsSystemGroup BIT NOT NULL DEFAULT 0,  -- System-managed groups (can't be deleted)
    IsActive BIT NOT NULL DEFAULT 1,
    IsHidden BIT NOT NULL DEFAULT 0,  -- Hide from general user selection
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy UNIQUEIDENTIFIER NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NULL,
    DeletedDate DATETIME2 NULL,
    
    CONSTRAINT FK_UserGroups_Parent FOREIGN KEY (ParentGroupId) 
        REFERENCES UserGroups(GroupId)
);

CREATE INDEX IX_UserGroups_Type ON UserGroups(GroupType) WHERE DeletedDate IS NULL;
```

### 4. UserGroupMembers
Many-to-many: Users ↔ Groups

```sql
CREATE TABLE UserGroupMembers (
    MemberId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    GroupId UNIQUEIDENTIFIER NOT NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    
    -- Membership Details
    IsPrimaryGroup BIT NOT NULL DEFAULT 0,  -- User's main group (for UI organization)
    IsGroupAdmin BIT NOT NULL DEFAULT 0,   -- Can manage group members
    
    -- Validity Period (Optional)
    ValidFrom DATETIME2 NULL,
    ValidUntil DATETIME2 NULL,
    
    -- Audit
    AddedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    AddedBy UNIQUEIDENTIFIER NULL,
    RemovedDate DATETIME2 NULL,  -- Soft delete for history
    RemovedBy UNIQUEIDENTIFIER NULL,
    
    CONSTRAINT FK_UGM_Group FOREIGN KEY (GroupId) REFERENCES UserGroups(GroupId),
    CONSTRAINT FK_UGM_User FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT UQ_UserGroupMembers UNIQUE (GroupId, UserId, RemovedDate)
);

CREATE INDEX IX_UGM_User ON UserGroupMembers(UserId) WHERE RemovedDate IS NULL;
CREATE INDEX IX_UGM_Group ON UserGroupMembers(GroupId) WHERE RemovedDate IS NULL;
```

### 5. Permissions
Granular application permissions (e.g., "Document.Create", "Workflow.Design", "System.Configure")

```sql
CREATE TABLE Permissions (
    PermissionId INT IDENTITY(1,1) PRIMARY KEY,
    
    PermissionKey NVARCHAR(100) NOT NULL UNIQUE,  -- e.g., "Document.Create", "Admin.Users"
    PermissionName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    Category NVARCHAR(50) NULL,  -- 'Documents', 'Workflows', 'Admin', 'Reports', etc.
    
    -- Permission Level
    PermissionLevel NVARCHAR(20) NULL,  -- 'Read', 'Write', 'Delete', 'Admin'
    
    IsActive BIT NOT NULL DEFAULT 1,
    
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);

CREATE INDEX IX_Permissions_Category ON Permissions(Category) WHERE IsActive = 1;
```

**Common Permissions Examples**:
- `Document.Create`, `Document.Edit`, `Document.Delete`, `Document.Download`
- `Workflow.Design`, `Workflow.Publish`, `Workflow.Execute`
- `Admin.Users`, `Admin.Groups`, `Admin.System`
- `Report.Create`, `Report.Schedule`
- `Form.Design`, `Form.Publish`

### 6. GroupPermissions
Many-to-many: UserGroups ↔ Permissions

**This is how we control what users can DO (not just what they can SEE)**

```sql
CREATE TABLE GroupPermissions (
    GroupPermissionId INT IDENTITY(1,1) PRIMARY KEY,
    
    GroupId UNIQUEIDENTIFIER NOT NULL,
    PermissionId INT NOT NULL,
    
    -- Audit
    GrantedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    GrantedBy UNIQUEIDENTIFIER NULL,
    RevokedDate DATETIME2 NULL,
    RevokedBy UNIQUEIDENTIFIER NULL,
    
    CONSTRAINT FK_GP_Group FOREIGN KEY (GroupId) REFERENCES UserGroups(GroupId),
    CONSTRAINT FK_GP_Permission FOREIGN KEY (PermissionId) REFERENCES Permissions(PermissionId),
    CONSTRAINT FK_GP_GrantedBy FOREIGN KEY (GrantedBy) REFERENCES Users(UserId),
    CONSTRAINT UQ_GroupPermissions UNIQUE (GroupId, PermissionId, RevokedDate)
);

CREATE INDEX IX_GP_Group ON GroupPermissions(GroupId) WHERE RevokedDate IS NULL;
CREATE INDEX IX_GP_Permission ON GroupPermissions(PermissionId) WHERE RevokedDate IS NULL;
```

**Example Group Configurations**:

```sql
-- "System Administrators" group gets all admin permissions
-- "Workflow Designers" group gets Workflow.Design + Workflow.Publish
-- "Department Managers" group gets Document.Create + Document.Edit + Report.Create
-- "End Users" group gets Document.Create + Document.Download (basic access)
-- "Auditors" group gets read-only access to audit logs
```

---

## Document Management Tables

### 5. DocumentTypeGroups
Organizational grouping of document types (e.g., "Legal Residence", "HR Forms", "Police Reports")

```sql
CREATE TABLE DocumentTypeGroups (
    DocumentTypeGroupId INT IDENTITY(1,1) PRIMARY KEY,
    
    GroupName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500) NULL,
    
    -- Display
    DisplayOrder INT NOT NULL DEFAULT 0,
    Icon NVARCHAR(50) NULL,
    Color NVARCHAR(7) NULL,  -- Hex color for UI
    
    -- Status
    IsActive BIT NOT NULL DEFAULT 1,
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NOT NULL,
    
    CONSTRAINT FK_DTG_Creator FOREIGN KEY (CreatedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT FK_DTG_Modifier FOREIGN KEY (ModifiedBy) 
        REFERENCES Users(UserId)
);
```

### 6. DocumentTypes
Admin-configured document type templates (e.g., "Incident Report Form", "Supporting Evidence")

```sql
CREATE TABLE DocumentTypes (
    DocumentTypeId INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Basic Info
    TypeName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    DocumentTypeGroupId INT NOT NULL,  -- FK to DocumentTypeGroups
    
    -- Auto-Numbering Configuration
    AutoNumberFormat NVARCHAR(100) NULL,  -- e.g., 'IR-{YYYY}-{#####}' → 'IR-2026-00001'
    AutoNumberPrefix NVARCHAR(20) NULL,   -- e.g., 'IR', 'FORM', 'EVIDENCE'
    AutoNumberNextValue INT NOT NULL DEFAULT 1,
    
    -- File Type Handling (Option B: Preferred with warning)
    PreferredFileTypes NVARCHAR(200) NULL,  -- CSV: 'pdf,docx,xlsx'
    MaxFileSizeBytes BIGINT NULL,  -- NULL = use system default
    
    -- OCR Configuration
    RequireOCR BIT NOT NULL DEFAULT 0,
    
    -- Retention Policy
    RetentionDays INT NULL,  -- NULL = keep forever, else auto-archive after X days
    
    -- Display
    DisplayOrder INT NOT NULL DEFAULT 0,
    Icon NVARCHAR(50) NULL,
    Color NVARCHAR(7) NULL,
    
    -- Status
    IsActive BIT NOT NULL DEFAULT 1,
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NOT NULL,
    
    CONSTRAINT FK_DT_Group FOREIGN KEY (DocumentTypeGroupId) 
        REFERENCES DocumentTypeGroups(DocumentTypeGroupId),
    CONSTRAINT FK_DT_Creator FOREIGN KEY (CreatedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT FK_DT_Modifier FOREIGN KEY (ModifiedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT UQ_DocumentTypes UNIQUE (TypeName, DocumentTypeGroupId)
);

CREATE INDEX IX_DT_Group ON DocumentTypes(DocumentTypeGroupId) WHERE IsActive = 1;
```

### 7. Documents
Primary document metadata table

```sql
CREATE TABLE Documents (
    DocumentId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    -- Identification
    DocumentNumber NVARCHAR(50) NULL,  -- Auto-generated: 'IR-2026-00001', 'FORM-2026-00042', etc.
    Title NVARCHAR(500) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    
    -- Document Type (FK to DocumentTypes table)
    DocumentTypeId INT NOT NULL,  -- Required for all new documents
    DocumentTypeGroupId INT NULL,  -- Denormalized for quick filtering
    
    -- Current Version Info (denormalized for performance)
    CurrentVersionId UNIQUEIDENTIFIER NULL,  -- FK to DocumentVersions
    CurrentVersionNumber INT NOT NULL DEFAULT 1,
    
    -- File Info (denormalized from current version)
    FileStorageKey NVARCHAR(500) NULL,  -- Physical file location: '\\fileserver\docs\{GUID}.pdf' or 'azure-blob-key'
    FileName NVARCHAR(255) NULL,  -- Original filename uploaded by user
    FileExtension NVARCHAR(10) NULL,
    FileSizeBytes BIGINT NULL,
    MimeType NVARCHAR(100) NULL,
    
    -- Status
    Status NVARCHAR(50) NOT NULL DEFAULT 'Draft',  -- 'Draft', 'Active', 'Archived', 'Deleted'
    
    -- OCR Status
    IsOcrProcessed BIT NOT NULL DEFAULT 0,
    OcrStatus NVARCHAR(50) NULL,  -- 'Pending', 'Processing', 'Completed', 'Failed', 'NotNeeded'
    OcrProcessedDate DATETIME2 NULL,
    OcrText NVARCHAR(MAX) NULL,  -- For simple queries; Elasticsearch for full-text search
    
    -- Classification (Optional - for advanced filtering)
    SecurityLevel NVARCHAR(50) NULL,  -- 'Public', 'Internal', 'Confidential', 'Restricted'
    RetentionPolicyId INT NULL,  -- FK to RetentionPolicies
    
    -- Dates
    DocumentDate DATETIME2 NULL,  -- The "effective date" of the document content
    ExpirationDate DATETIME2 NULL,
    ArchiveDate DATETIME2 NULL,
    
    -- Workflow
    CurrentWorkflowInstanceId UNIQUEIDENTIFIER NULL,  -- FK to WorkflowInstances
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NOT NULL,
    DeletedDate DATETIME2 NULL,
    DeletedBy UNIQUEIDENTIFIER NULL,
    
    CONSTRAINT FK_Documents_CurrentVersion FOREIGN KEY (CurrentVersionId) 
        REFERENCES DocumentVersions(VersionId),
    CONSTRAINT FK_Documents_DocumentType FOREIGN KEY (DocumentTypeId) 
        REFERENCES DocumentTypes(DocumentTypeId),
    CONSTRAINT FK_Documents_DocumentTypeGroup FOREIGN KEY (DocumentTypeGroupId) 
        REFERENCES DocumentTypeGroups(DocumentTypeGroupId),
    CONSTRAINT FK_Documents_Creator FOREIGN KEY (CreatedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT FK_Documents_Modifier FOREIGN KEY (ModifiedBy) 
        REFERENCES Users(UserId)
);

CREATE INDEX IX_Documents_DocumentNumber ON Documents(DocumentNumber) WHERE DeletedDate IS NULL;
CREATE INDEX IX_Documents_Type ON Documents(DocumentTypeId) WHERE DeletedDate IS NULL;
CREATE INDEX IX_Documents_TypeGroup ON Documents(DocumentTypeGroupId) WHERE DeletedDate IS NULL;
CREATE INDEX IX_Documents_Status ON Documents(Status) WHERE DeletedDate IS NULL;
CREATE INDEX IX_Documents_Created ON Documents(CreatedDate DESC);
CREATE INDEX IX_Documents_DocumentDate ON Documents(DocumentDate DESC);
CREATE FULLTEXT INDEX ON Documents(Title, Description, OcrText);  -- SQL Server full-text
```

### 8. DocumentVersions
Version history for all documents

```sql
CREATE TABLE DocumentVersions (
    VersionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    DocumentId UNIQUEIDENTIFIER NOT NULL,
    VersionNumber INT NOT NULL,
    
    -- File Storage
    FilePath NVARCHAR(500) NOT NULL,  -- Relative path in storage
    FileName NVARCHAR(255) NOT NULL,
    FileExtension NVARCHAR(10) NOT NULL,
    FileSizeBytes BIGINT NOT NULL,
    MimeType NVARCHAR(100) NOT NULL,
    FileHash NVARCHAR(64) NOT NULL,  -- SHA-256 hash for integrity
    
    -- Version Metadata
    VersionNotes NVARCHAR(MAX) NULL,  -- What changed in this version
    IsCurrentVersion BIT NOT NULL DEFAULT 0,
    
    -- Upload Info
    UploadedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UploadedBy UNIQUEIDENTIFIER NOT NULL,
    
    -- Audit
    DeletedDate DATETIME2 NULL,  -- Can soft-delete old versions
    DeletedBy UNIQUEIDENTIFIER NULL,
    
    CONSTRAINT FK_DV_Document FOREIGN KEY (DocumentId) 
        REFERENCES Documents(DocumentId),
    CONSTRAINT FK_DV_Uploader FOREIGN KEY (UploadedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT UQ_DocumentVersions UNIQUE (DocumentId, VersionNumber)
);

CREATE INDEX IX_DV_Document ON DocumentVersions(DocumentId, VersionNumber DESC);
CREATE INDEX IX_DV_Current ON DocumentVersions(IsCurrentVersion) WHERE IsCurrentVersion = 1;
```

### 9. DocumentGroups
**ACCESS CONTROL**: Which user groups can see which documents

```sql
CREATE TABLE DocumentGroups (
    DocumentGroupId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    DocumentId UNIQUEIDENTIFIER NOT NULL,
    GroupId UNIQUEIDENTIFIER NOT NULL,
    
    -- Permissions for this group on this document
    CanView BIT NOT NULL DEFAULT 1,
    CanEdit BIT NOT NULL DEFAULT 0,
    CanDelete BIT NOT NULL DEFAULT 0,
    
    -- Audit
    GrantedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    GrantedBy UNIQUEIDENTIFIER NOT NULL,
    RevokedDate DATETIME2 NULL,
    RevokedBy UNIQUEIDENTIFIER NULL,
    
    CONSTRAINT FK_DG_Document FOREIGN KEY (DocumentId) 
        REFERENCES Documents(DocumentId),
    CONSTRAINT FK_DG_Group FOREIGN KEY (GroupId) 
        REFERENCES UserGroups(GroupId),
    CONSTRAINT FK_DG_GrantedBy FOREIGN KEY (GrantedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT UQ_DocumentGroups UNIQUE (DocumentId, GroupId, RevokedDate)
);

CREATE INDEX IX_DG_Document ON DocumentGroups(DocumentId) WHERE RevokedDate IS NULL;
CREATE INDEX IX_DG_Group ON DocumentGroups(GroupId) WHERE RevokedDate IS NULL;
```

### 10. IndexFields
Index field definitions for document indexing (e.g., FIRST NAME, LAST NAME, SSN)

```sql
CREATE TABLE IndexFields (
    IndexFieldId INT IDENTITY(1,1) PRIMARY KEY,
    
    FieldName NVARCHAR(100) NOT NULL,  -- 'FIRST NAME', 'LAST NAME', 'SSN', etc.
    Description NVARCHAR(500) NULL,
    
    -- Data Type & Validation
    FieldType NVARCHAR(50) NOT NULL DEFAULT 'Text',  -- 'Text', 'Number', 'Date', 'Boolean', 'Dropdown'
    MaxLength INT NULL,  -- For text fields
    ValidationRegex NVARCHAR(500) NULL,  -- e.g., SSN pattern
    DropdownOptions NVARCHAR(MAX) NULL,  -- JSON array for dropdown choices
    
    -- Hierarchy (optional grouping)
    ParentFieldId INT NULL,  -- Group related fields
    Level INT NOT NULL DEFAULT 0,
    
    -- Access Control
    IsSensitive BIT NOT NULL DEFAULT 0,  -- PII/PHI flag - requires Search.ViewPII permission to view
    
    -- Display
    DisplayOrder INT NOT NULL DEFAULT 0,
    IsSearchable BIT NOT NULL DEFAULT 1,  -- Can users search by this field?
    
    -- Status
    IsActive BIT NOT NULL DEFAULT 1,
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy UNIQUEIDENTIFIER NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NULL,
    DeletedDate DATETIME2 NULL,
    
    CONSTRAINT FK_IndexFields_Parent FOREIGN KEY (ParentFieldId) 
        REFERENCES IndexFields(IndexFieldId),
    CONSTRAINT UQ_IndexFields UNIQUE (FieldName, DeletedDate)
);

CREATE INDEX IX_IndexFields_Parent ON IndexFields(ParentFieldId) WHERE DeletedDate IS NULL;
CREATE INDEX IX_IndexFields_Active ON IndexFields(IsActive) WHERE DeletedDate IS NULL;
```

### 11. DocumentIndexData
Actual index field values for each document (e.g., FIRST NAME = 'Bob', SSN = '123456798')

```sql
CREATE TABLE DocumentIndexData (
    DocumentIndexDataId BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    DocumentId UNIQUEIDENTIFIER NOT NULL,
    IndexFieldId INT NOT NULL,
    
    -- The Actual Value
    FieldValue NVARCHAR(4000) NOT NULL,  -- 'Bob', 'Smith', '123456798', '2024-01-15', etc.
    
    -- Audit
    AddedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    AddedBy UNIQUEIDENTIFIER NOT NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NOT NULL,
    RemovedDate DATETIME2 NULL,
    
    CONSTRAINT FK_DID_Document FOREIGN KEY (DocumentId) 
        REFERENCES Documents(DocumentId),
    CONSTRAINT FK_DID_IndexField FOREIGN KEY (IndexFieldId) 
        REFERENCES IndexFields(IndexFieldId),
    CONSTRAINT FK_DID_AddedBy FOREIGN KEY (AddedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT UQ_DocumentIndexData UNIQUE (DocumentId, IndexFieldId, RemovedDate)
);

CREATE INDEX IX_DID_Document ON DocumentIndexData(DocumentId) WHERE RemovedDate IS NULL;
CREATE INDEX IX_DID_Field ON DocumentIndexData(IndexFieldId) WHERE RemovedDate IS NULL;
-- CRITICAL: Index for searching by field value
CREATE INDEX IX_DID_FieldValue ON DocumentIndexData(IndexFieldId, FieldValue) 
    WHERE RemovedDate IS NULL;

-- Full-Text Search for wildcard/partial matching on FieldValue
CREATE FULLTEXT INDEX ON DocumentIndexData(FieldValue)
    KEY INDEX PK_DocumentIndexData
    ON DocumentCatalog
    WITH STOPLIST = SYSTEM;
```

### 12. DocumentTypeIndexFields
Defines which index fields are required/optional for each document type

```sql
CREATE TABLE DocumentTypeIndexFields (
    DocumentTypeIndexFieldId INT IDENTITY(1,1) PRIMARY KEY,
    
    DocumentTypeId INT NOT NULL,
    IndexFieldId INT NOT NULL,
    
    -- Requirement
    IsRequired BIT NOT NULL DEFAULT 0,  -- TRUE = must be filled, FALSE = optional
    
    -- Display
    DisplayOrder INT NOT NULL DEFAULT 0,
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy UNIQUEIDENTIFIER NOT NULL,
    RemovedDate DATETIME2 NULL,
    
    CONSTRAINT FK_DTIF_DocumentType FOREIGN KEY (DocumentTypeId) 
        REFERENCES DocumentTypes(DocumentTypeId),
    CONSTRAINT FK_DTIF_IndexField FOREIGN KEY (IndexFieldId) 
        REFERENCES IndexFields(IndexFieldId),
    CONSTRAINT FK_DTIF_Creator FOREIGN KEY (CreatedBy) 
        REFERENCES Users(UserId),
    CONSTRAINT UQ_DocumentTypeIndexFields UNIQUE (DocumentTypeId, IndexFieldId, RemovedDate)
);

CREATE INDEX IX_DTIF_DocumentType ON DocumentTypeIndexFields(DocumentTypeId) WHERE RemovedDate IS NULL;
CREATE INDEX IX_DTIF_IndexField ON DocumentTypeIndexFields(IndexFieldId) WHERE RemovedDate IS NULL;
```

---

## System Tables

### 13. SystemSettings

---

## System Tables

### 27. AuditLogs
Comprehensive audit trail

```sql
CREATE TABLE AuditLogs (
    AuditId BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Event Info
    EventType NVARCHAR(50) NOT NULL,  -- 'Create', 'Update', 'Delete', 'View', 'Download', etc.
    EntityType NVARCHAR(50) NOT NULL,  -- 'Document', 'User', 'Workflow', etc.
    EntityId NVARCHAR(50) NOT NULL,
    
    -- Action Details
    Action NVARCHAR(100) NOT NULL,  -- Detailed action description
    OldValues NVARCHAR(MAX) NULL,  -- JSON: before state
    NewValues NVARCHAR(MAX) NULL,  -- JSON: after state
    
    -- User & Context
    UserId UNIQUEIDENTIFIER NULL,
    Username NVARCHAR(100) NULL,
    IpAddress NVARCHAR(45) NULL,
    UserAgent NVARCHAR(500) NULL,
    
    -- Timing
    EventDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    -- Result
    Success BIT NOT NULL DEFAULT 1,
    ErrorMessage NVARCHAR(MAX) NULL,
    
    CONSTRAINT FK_AL_User FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE INDEX IX_AL_EventDate ON AuditLogs(EventDate DESC);
CREATE INDEX IX_AL_EntityType ON AuditLogs(EntityType, EntityId, EventDate DESC);
CREATE INDEX IX_AL_User ON AuditLogs(UserId, EventDate DESC);
CREATE INDEX IX_AL_EventType ON AuditLogs(EventType, EventDate DESC);
```

### 28. SystemSettings
Application configuration key-value store

```sql
CREATE TABLE SystemSettings (
    SettingId INT IDENTITY(1,1) PRIMARY KEY,
    
    SettingKey NVARCHAR(100) NOT NULL UNIQUE,
    SettingValue NVARCHAR(MAX) NULL,
    
    -- Metadata
    Description NVARCHAR(500) NULL,
    DataType NVARCHAR(50) NOT NULL,  -- 'String', 'Int', 'Bool', 'JSON', etc.
    Category NVARCHAR(50) NULL,  -- 'General', 'Email', 'Storage', 'Security', etc.
    
    -- Validation
    ValidationRules NVARCHAR(MAX) NULL,  -- JSON: min, max, regex, etc.
    
    -- Security
    IsEncrypted BIT NOT NULL DEFAULT 0,
    IsSensitive BIT NOT NULL DEFAULT 0,  -- Hide from UI
    
    -- Audit
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NULL,
    
    CONSTRAINT FK_SS_ModifiedBy FOREIGN KEY (ModifiedBy) 
        REFERENCES Users(UserId)
);

CREATE INDEX IX_SS_Category ON SystemSettings(Category);
```

### 29. OcrQueue
OCR processing queue

```sql
CREATE TABLE OcrQueue (
    QueueId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    DocumentId UNIQUEIDENTIFIER NOT NULL,
    VersionId UNIQUEIDENTIFIER NOT NULL,
    
    -- Priority
    Priority INT NOT NULL DEFAULT 5,  -- 1-10, higher = more urgent
    
    -- Status
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending',  -- 'Pending', 'Processing', 'Completed', 'Failed'
    
    -- Processing
    ProcessingStarted DATETIME2 NULL,
    ProcessingCompleted DATETIME2 NULL,
    ProcessedBy NVARCHAR(100) NULL,  -- Worker ID
    
    -- Results
    ExtractedText NVARCHAR(MAX) NULL,
    Confidence DECIMAL(5,2) NULL,  -- 0-100%
    PageCount INT NULL,
    
    -- Errors
    ErrorMessage NVARCHAR(MAX) NULL,
    RetryCount INT NOT NULL DEFAULT 0,
    MaxRetries INT NOT NULL DEFAULT 3,
    
    -- Timing
    QueuedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    CONSTRAINT FK_OQ_Document FOREIGN KEY (DocumentId) 
        REFERENCES Documents(DocumentId),
    CONSTRAINT FK_OQ_Version FOREIGN KEY (VersionId) 
        REFERENCES DocumentVersions(VersionId)
);

CREATE INDEX IX_OQ_Status ON OcrQueue(Status, Priority DESC, QueuedDate);
CREATE INDEX IX_OQ_Document ON OcrQueue(DocumentId);
```

### 30. Notifications
User notifications/alerts

```sql
CREATE TABLE Notifications (
    NotificationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    
    UserId UNIQUEIDENTIFIER NOT NULL,
    
    -- Notification Content
    Title NVARCHAR(200) NOT NULL,
    Message NVARCHAR(1000) NOT NULL,
    NotificationType NVARCHAR(50) NOT NULL,  -- 'Info', 'Warning', 'Error', 'Success', 'Task'
    
    -- Link
    LinkUrl NVARCHAR(500) NULL,
    LinkText NVARCHAR(100) NULL,
    
    -- Context
    RelatedEntityType NVARCHAR(50) NULL,  -- 'Document', 'Workflow', etc.
    RelatedEntityId NVARCHAR(50) NULL,
    
    -- Status
    IsRead BIT NOT NULL DEFAULT 0,
    ReadDate DATETIME2 NULL,
    
    -- Timing
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ExpirationDate DATETIME2 NULL,
    
    CONSTRAINT FK_N_User FOREIGN KEY (UserId) REFERENCES Users(UserId)
);

CREATE INDEX IX_N_User ON Notifications(UserId, IsRead, CreatedDate DESC);
CREATE INDEX IX_N_Expiration ON Notifications(ExpirationDate) WHERE ExpirationDate IS NOT NULL;
```

### 31. EmailQueue
Email sending queue for notifications and system emails

```sql
CREATE TABLE EmailQueue (
    EmailQueueId BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Recipient
    ToEmail NVARCHAR(255) NOT NULL,
    ToUserId UNIQUEIDENTIFIER NULL,  -- FK to Users if internal user
    
    -- Email Content
    Subject NVARCHAR(500) NOT NULL,
    Body NVARCHAR(MAX) NOT NULL,
    IsHtml BIT NOT NULL DEFAULT 1,
    
    -- Optional
    CcEmails NVARCHAR(MAX) NULL,  -- Comma-separated
    BccEmails NVARCHAR(MAX) NULL,
    Attachments NVARCHAR(MAX) NULL,  -- JSON array of file paths
    
    -- Sending
    Status NVARCHAR(50) NOT NULL DEFAULT 'Pending',  -- 'Pending', 'Sent', 'Failed'
    Priority INT NOT NULL DEFAULT 5,  -- 1-10, higher = more urgent
    ScheduledSendDate DATETIME2 NULL,  -- For delayed sending
    
    -- Results
    SentDate DATETIME2 NULL,
    ErrorMessage NVARCHAR(MAX) NULL,
    RetryCount INT NOT NULL DEFAULT 0,
    MaxRetries INT NOT NULL DEFAULT 3,
    
    -- Context
    RelatedNotificationId UNIQUEIDENTIFIER NULL,  -- FK to Notifications
    RelatedEntityType NVARCHAR(50) NULL,  -- 'Document', 'Workflow', etc.
    RelatedEntityId NVARCHAR(50) NULL,
    
    -- Audit
    QueuedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    CONSTRAINT FK_EQ_Notification FOREIGN KEY (RelatedNotificationId) 
        REFERENCES Notifications(NotificationId),
    CONSTRAINT FK_EQ_User FOREIGN KEY (ToUserId) 
        REFERENCES Users(UserId)
);

CREATE INDEX IX_EQ_Status ON EmailQueue(Status, Priority DESC, QueuedDate);
CREATE INDEX IX_EQ_User ON EmailQueue(ToUserId) WHERE ToUserId IS NOT NULL;
CREATE INDEX IX_EQ_Scheduled ON EmailQueue(ScheduledSendDate) WHERE ScheduledSendDate IS NOT NULL;
```

### 32. HelpContent
Contextual help system

```sql
CREATE TABLE HelpContent (
    HelpId INT IDENTITY(1,1) PRIMARY KEY,
    
    HelpKey NVARCHAR(100) NOT NULL UNIQUE,  -- e.g., 'Document.Upload'
    Title NVARCHAR(200) NOT NULL,
    Content NVARCHAR(MAX) NOT NULL,  -- Markdown or HTML
    
    -- Categorization
    Category NVARCHAR(50) NULL,
    Tags NVARCHAR(500) NULL,  -- Comma-separated
    
    -- Media
    VideoUrl NVARCHAR(500) NULL,
    ImageUrl NVARCHAR(500) NULL,
    
    -- Versioning
    Version NVARCHAR(20) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedBy UNIQUEIDENTIFIER NULL
);

CREATE INDEX IX_HC_Category ON HelpContent(Category) WHERE IsActive = 1;
CREATE INDEX IX_HC_Key ON HelpContent(HelpKey);
```

### 16. DocumentMetadataFields (Optional - Advanced)
Custom metadata fields for documents (if needed beyond keywords)

```sql
CREATE TABLE DocumentMetadataFields (
    MetadataFieldId INT IDENTITY(1,1) PRIMARY KEY,
    
    FieldName NVARCHAR(100) NOT NULL UNIQUE,
    FieldType NVARCHAR(50) NOT NULL,  -- 'Text', 'Number', 'Date', 'Boolean', 'Dropdown'
    Description NVARCHAR(500) NULL,
    
    -- Dropdown Options (JSON)
    DropdownOptions NVARCHAR(MAX) NULL,  -- JSON array of options
    
    -- Validation
    IsRequired BIT NOT NULL DEFAULT 0,
    ValidationRules NVARCHAR(MAX) NULL,  -- JSON: regex, min, max, etc.
    
    -- Applicability
    ApplicableDocumentTypes NVARCHAR(MAX) NULL,  -- JSON array, NULL = all types
    
    -- Display
    DisplayOrder INT NOT NULL DEFAULT 0,
    IsActive BIT NOT NULL DEFAULT 1,
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy UNIQUEIDENTIFIER NULL,
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    DeletedDate DATETIME2 NULL
);

CREATE TABLE DocumentMetadataValues (
    MetadataValueId BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    DocumentId UNIQUEIDENTIFIER NOT NULL,
    MetadataFieldId INT NOT NULL,
    
    -- Value (store as text, convert based on FieldType)
    Value NVARCHAR(MAX) NULL,
    
    -- Audit
    CreatedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    CONSTRAINT FK_DMV_Document FOREIGN KEY (DocumentId) REFERENCES Documents(DocumentId),
    CONSTRAINT FK_DMV_Field FOREIGN KEY (MetadataFieldId) REFERENCES DocumentMetadataFields(MetadataFieldId),
    CONSTRAINT UQ_DocumentMetadata UNIQUE (DocumentId, MetadataFieldId)
);

CREATE INDEX IX_DMV_Document ON DocumentMetadataValues(DocumentId);
CREATE INDEX IX_DMV_Field ON DocumentMetadataValues(MetadataFieldId);
```

**Note**: Tables 17 (DocumentMetadataFields/Values) are optional - only implement if keywords aren't sufficient for your metadata needs.

---

## Indexing Strategy

### Critical Performance Indexes (Phase 1)

**Already included in table definitions above, summary:**

1. **Users**: Username, Email, ActiveDirectoryId (login and authentication)
2. **UserGroupMembers**: UserId, GroupId (permission checking - most frequent query)
3. **GroupPermissions**: GroupId, PermissionId (authorization checks)
4. **Documents**: Type, Status, CreatedDate, DocumentDate, Full-Text on Title/Description/OcrText
5. **DocumentVersions**: DocumentId + VersionNumber, IsCurrentVersion (version history)
6. **DocumentGroups**: DocumentId, GroupId (access control - CRITICAL for security)
7. **DocumentKeywords**: DocumentId, KeywordId (searching by tags)
8. **OcrQueue**: Status + Priority (worker polling for processing)
9. **AuditLogs**: EventDate, EntityType+EntityId, UserId (compliance queries)
10. **Notifications**: UserId + IsRead + CreatedDate (notification center)

### Composite Indexes for Common Queries

```sql
-- User's accessible documents (THE most important query)
-- Joins: Users → UserGroupMembers → DocumentGroups → Documents
CREATE INDEX IX_UserDocumentAccess ON DocumentGroups(GroupId, DocumentId) 
    INCLUDE (CanView, CanEdit, CanDelete) 
    WHERE RevokedDate IS NULL;

-- User's group memberships (frequent permission check)
CREATE INDEX IX_UserGroups ON UserGroupMembers(UserId, GroupId)
    INCLUDE (IsPrimaryGroup, IsGroupAdmin)
    WHERE RemovedDate IS NULL;

-- Group permissions lookup
CREATE INDEX IX_GroupPerms ON GroupPermissions(GroupId, PermissionId)
    WHERE RevokedDate IS NULL;

-- Document search with access control
CREATE INDEX IX_DocumentSearch ON Documents(Status, DocumentTypeId, CreatedDate DESC)
    INCLUDE (Title, FileName, CreatedBy)
    WHERE DeletedDate IS NULL;

-- Index field-based document search (CRITICAL for performance)
-- Enables: Search by FIRST NAME = 'Joe', SSN = '123456798', etc.
CREATE INDEX IX_IndexFieldSearch ON DocumentIndexData(IndexFieldId, FieldValue)
    INCLUDE (DocumentId)
    WHERE RemovedDate IS NULL;
```

### Full-Text Search Indexes

```sql
-- SQL Server Full-Text Index (if using SQL Server instead of Elasticsearch)
CREATE FULLTEXT CATALOG DocumentCatalog AS DEFAULT;

CREATE FULLTEXT INDEX ON Documents(Title, Description, OcrText)
    KEY INDEX PK_Documents
    ON DocumentCatalog
    WITH CHANGE_TRACKING AUTO;

CREATE FULLTEXT INDEX ON IndexFields(FieldName, Description)
    KEY INDEX PK_IndexFields
    ON DocumentCatalog
    WITH CHANGE_TRACKING AUTO;

CREATE FULLTEXT INDEX ON DocumentIndexData(FieldValue)
    KEY INDEX PK_DocumentIndexData
    ON DocumentCatalog
    WITH CHANGE_TRACKING AUTO;
```

---

## Performance Considerations

### 1. Query Optimization Priorities

**Most Frequent Queries (optimize first)**:
1. Check if user can view/edit document: `Users → UserGroupMembers → DocumentGroups → Documents`
2. Get user's permissions: `Users → UserGroupMembers → GroupPermissions → Permissions`
3. Search documents user can access: `Documents + DocumentGroups filtered by user's groups`
4. Get documents by keyword: `Keywords → DocumentKeywords → Documents → DocumentGroups`
5. OCR worker polling: `SELECT FROM OcrQueue WHERE Status='Pending' ORDER BY Priority DESC`

### 2. Partitioning (for large deployments >100K documents)

```sql
-- Partition AuditLogs by month (SQL Server)
CREATE PARTITION FUNCTION PF_AuditLogs_Monthly (DATETIME2)
AS RANGE RIGHT FOR VALUES 
    ('2026-01-01', '2026-02-01', '2026-03-01', ...);  -- Add monthly boundaries

CREATE PARTITION SCHEME PS_AuditLogs_Monthly
AS PARTITION PF_AuditLogs_Monthly ALL TO ([PRIMARY]);

-- Apply to AuditLogs table (requires rebuild)

-- Also consider partitioning DocumentVersions by DocumentId or date
-- if version history becomes very large
```

### 2. Temporal Tables (SQL Server 2016+)

For automatic change tracking on critical tables:

```sql
-- Enable on Documents table
ALTER TABLE Documents
ADD 
    SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,
    SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);

ALTER TABLE Documents
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Documents_History));

-- Query historical data
SELECT * FROM Documents 
FOR SYSTEM_TIME AS OF '2026-01-01'
WHERE DocumentId = '...';
```

### 3. Denormalization for Read Performance

**Already implemented in Phase 1**:
- `Documents.CurrentVersionId` (avoids join to DocumentVersions for latest version)
- `Documents.FileName, FileExtension, FileSizeBytes, MimeType` (denormalized from DocumentVersions)
- `Documents.CurrentVersionNumber` (quick version display without join)
- `Documents.OcrText` (copy from Elasticsearch for simple queries; full search uses Elasticsearch)

### 4. Caching Strategy

**Recommended caching for Phase 1**:

1. **User Permissions** (in-memory cache, 15-min TTL)
   - Cache the result of "which permissions does this user have?"
   - Invalidate on group membership or permission changes

2. **User's Group Memberships** (in-memory cache, 30-min TTL)
   - Cache UserGroupMembers for each user
   - Invalidate when groups change

3. **System Settings** (in-memory cache, 1-hour TTL)
   - Cache entire SystemSettings table
   - Invalidate on settings update

4. **Index Field Definitions** (in-memory cache, 1-hour TTL)
   - Cache index field definitions and their validation rules
   - Invalidate when fields are modified

5. **Document Metadata** (Redis for distributed, 10-min TTL)
   - Cache frequently accessed document records
   - Invalidate on document updates

**Implementation**: Use `IMemoryCache` (ASP.NET Core built-in) for single-server, Redis for multi-server deployments.

---

## Implementation Notes & Configuration

### Initial System Setup

**Default System Admin User:**

Create a fixed system admin user for initial setup and system operations. This user should never be deleted.

```sql
-- Create the default system administrator (fixed GUID)
-- Use this GUID for all system operations: '00000000-0000-0000-0000-000000000001'
DECLARE @SystemAdminId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

INSERT INTO Users (
    UserId, 
    Username, 
    Email, 
    FirstName, 
    LastName, 
    DisplayName,
    IsActive,
    IsSystemAdmin,
    CreatedDate,
    CreatedBy,
    ModifiedDate,
    ModifiedBy
)
VALUES (
    @SystemAdminId,
    'system.admin',
    'admin@youragency.gov',
    'System',
    'Administrator',
    'System Administrator',
    1,  -- IsActive
    1,  -- IsSystemAdmin
    GETUTCDATE(),
    @SystemAdminId,  -- Self-created
    GETUTCDATE(),
    @SystemAdminId
);

-- Create System Administrators group
DECLARE @SystemAdminGroupId UNIQUEIDENTIFIER = NEWID();

INSERT INTO UserGroups (GroupId, GroupName, Description, IsSystemGroup, CreatedBy, ModifiedBy)
VALUES (
    @SystemAdminGroupId,
    'System Administrators',
    'Full system access - cannot be deleted',
    1,  -- IsSystemGroup
    @SystemAdminId,
    @SystemAdminId
);

-- Add system admin to the group
INSERT INTO UserGroupMembers (GroupId, UserId, IsPrimaryGroup, AddedBy)
VALUES (@SystemAdminGroupId, @SystemAdminId, 1, @SystemAdminId);
```

**Note**: Use this fixed GUID `'00000000-0000-0000-0000-000000000001'` for all subsequent setup scripts where a `CreatedBy` or `ModifiedBy` user is required.

---

### Core Permissions Setup

**Create all application permissions** organized by category:

```sql
-- Use the system admin GUID
DECLARE @SystemAdminId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

-- Document Permissions
INSERT INTO Permissions (PermissionKey, PermissionName, Description, Category, PermissionLevel, IsActive)
VALUES 
    -- Document Management
    ('Document.View', 'View Documents', 'Can view documents user has access to', 'Documents', 'Read', 1),
    ('Document.Create', 'Create Documents', 'Can upload new documents', 'Documents', 'Write', 1),
    ('Document.Edit', 'Edit Documents', 'Can modify document metadata', 'Documents', 'Write', 1),
    ('Document.Delete', 'Delete Documents', 'Can soft-delete documents', 'Documents', 'Delete', 1),
    ('Document.Download', 'Download Documents', 'Can download document files', 'Documents', 'Read', 1),
    ('Document.Version', 'Manage Versions', 'Can upload new versions of documents', 'Documents', 'Write', 1),
    ('Document.Restore', 'Restore Documents', 'Can restore soft-deleted documents', 'Documents', 'Admin', 1),
    
    -- Document Type Management
    ('DocumentType.View', 'View Document Types', 'Can view document type configurations', 'Documents', 'Read', 1),
    ('DocumentType.Create', 'Create Document Types', 'Can create new document types', 'Documents', 'Admin', 1),
    ('DocumentType.Edit', 'Edit Document Types', 'Can modify document type settings', 'Documents', 'Admin', 1),
    ('DocumentType.Delete', 'Delete Document Types', 'Can delete document types', 'Documents', 'Admin', 1),
    
    -- Index Field Management
    ('IndexField.View', 'View Index Fields', 'Can view index field definitions', 'Documents', 'Read', 1),
    ('IndexField.Create', 'Create Index Fields', 'Can create new index fields', 'Documents', 'Admin', 1),
    ('IndexField.Edit', 'Edit Index Fields', 'Can modify index field settings', 'Documents', 'Admin', 1),
    ('IndexField.Delete', 'Delete Index Fields', 'Can delete index fields', 'Documents', 'Admin', 1),
    
    -- Search & Access
    ('Search.Basic', 'Basic Search', 'Can search documents by title and metadata', 'Documents', 'Read', 1),
    ('Search.Advanced', 'Advanced Search', 'Can use full-text search and complex queries', 'Documents', 'Read', 1),
    ('Search.ViewPII', 'View PII Fields', 'Can view sensitive/PII index fields (SSN, etc.)', 'Documents', 'Read', 1),
    
    -- User Management
    ('Admin.Users.View', 'View Users', 'Can view user list and details', 'Admin', 'Read', 1),
    ('Admin.Users.Create', 'Create Users', 'Can create new user accounts', 'Admin', 'Write', 1),
    ('Admin.Users.Edit', 'Edit Users', 'Can modify user accounts', 'Admin', 'Write', 1),
    ('Admin.Users.Delete', 'Delete Users', 'Can soft-delete user accounts', 'Admin', 'Delete', 1),
    ('Admin.Users.ResetPassword', 'Reset Passwords', 'Can reset user passwords', 'Admin', 'Admin', 1),
    
    -- Group Management
    ('Admin.Groups.View', 'View Groups', 'Can view user groups', 'Admin', 'Read', 1),
    ('Admin.Groups.Create', 'Create Groups', 'Can create new user groups', 'Admin', 'Write', 1),
    ('Admin.Groups.Edit', 'Edit Groups', 'Can modify group settings', 'Admin', 'Write', 1),
    ('Admin.Groups.Delete', 'Delete Groups', 'Can delete user groups', 'Admin', 'Delete', 1),
    ('Admin.Groups.ManageMembers', 'Manage Group Members', 'Can add/remove users from groups', 'Admin', 'Write', 1),
    ('Admin.Groups.ManagePermissions', 'Manage Group Permissions', 'Can grant/revoke group permissions', 'Admin', 'Admin', 1),
    
    -- System Administration
    ('Admin.System.View', 'View System Settings', 'Can view system configuration', 'Admin', 'Read', 1),
    ('Admin.System.Configure', 'Configure System', 'Can modify system settings', 'Admin', 'Admin', 1),
    ('Admin.System.ViewAuditLogs', 'View Audit Logs', 'Can view audit trail', 'Admin', 'Read', 1),
    ('Admin.System.ManageRetention', 'Manage Retention', 'Can configure audit log retention', 'Admin', 'Admin', 1),
    
    -- OCR Management
    ('OCR.View', 'View OCR Queue', 'Can view OCR processing queue', 'System', 'Read', 1),
    ('OCR.Manage', 'Manage OCR', 'Can reprocess failed OCR jobs', 'System', 'Admin', 1),
    
    -- Notification Management
    ('Notification.Send', 'Send Notifications', 'Can send notifications to users', 'System', 'Write', 1),
    ('Notification.Manage', 'Manage Notifications', 'Can manage system notifications', 'System', 'Admin', 1),
    
    -- Email Management
    ('Email.Send', 'Send Emails', 'Can send emails via queue', 'System', 'Write', 1),
    ('Email.ViewQueue', 'View Email Queue', 'Can view email sending queue', 'System', 'Read', 1),
    ('Email.ManageQueue', 'Manage Email Queue', 'Can retry/cancel queued emails', 'System', 'Admin', 1),
    
    -- Reporting (Future Phase 2)
    ('Report.View', 'View Reports', 'Can view existing reports', 'Reports', 'Read', 1),
    ('Report.Create', 'Create Reports', 'Can create custom reports', 'Reports', 'Write', 1),
    ('Report.Schedule', 'Schedule Reports', 'Can schedule automated reports', 'Reports', 'Admin', 1),
    
    -- Help Content Management
    ('Help.View', 'View Help', 'Can view help content', 'System', 'Read', 1),
    ('Help.Manage', 'Manage Help', 'Can create/edit help content', 'System', 'Admin', 1);

-- Grant all permissions to System Administrators group
DECLARE @SystemAdminGroupId UNIQUEIDENTIFIER;

SELECT @SystemAdminGroupId = GroupId 
FROM UserGroups 
WHERE GroupName = 'System Administrators';

INSERT INTO GroupPermissions (GroupId, PermissionId, GrantedBy)
SELECT @SystemAdminGroupId, PermissionId, @SystemAdminId
FROM Permissions
WHERE IsActive = 1;
```

**Permission Categories:**
- **Documents**: Document and document type management
- **Admin**: User, group, and system administration
- **System**: OCR, notifications, email, and system operations
- **Reports**: Reporting functionality (Phase 2)

---

### Index Field System

**How It Works**:
Admin creates index field definitions in Config.exe, then users fill in values during document upload.

**Example Setup**:
```sql
-- Use the system admin GUID created during initial setup
DECLARE @AdminUserId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';

-- Admin creates index fields
INSERT INTO IndexFields (FieldName, FieldType, IsSearchable, IsSensitive, CreatedBy)
VALUES 
    ('FIRST NAME', 'Text', 1, 0, @AdminUserId),
    ('LAST NAME', 'Text', 1, 0, @AdminUserId),
    ('SSN', 'Text', 1, 1, @AdminUserId),  -- IsSensitive = PII
    ('DATE OF BIRTH', 'Date', 1, 1, @AdminUserId);

-- Admin configures which fields are required for "Legal Residence Form"
-- DocumentTypeId = 1, assumes IndexFieldIds 1-4 from above inserts
INSERT INTO DocumentTypeIndexFields (DocumentTypeId, IndexFieldId, IsRequired, DisplayOrder, CreatedBy)
VALUES 
    (1, 1, 1, 1, @AdminUserId),  -- FIRST NAME required
    (1, 2, 1, 2, @AdminUserId),  -- LAST NAME required
    (1, 3, 1, 3, @AdminUserId),  -- SSN required
    (1, 4, 0, 4, @AdminUserId);  -- DATE OF BIRTH optional
```

**User Imports Documents**:
```sql
-- Form 1: User uploads document and enters index field values
INSERT INTO Documents (DocumentId, DocumentTypeId, Title, ...)
VALUES ('{guid-form1}', 1, 'Legal Residence - Bob Smith', ...);

INSERT INTO DocumentIndexData (DocumentId, IndexFieldId, FieldValue, AddedBy)
VALUES 
    ('{guid-form1}', 1, 'Bob', '{user-guid}'),     -- FIRST NAME = Bob
    ('{guid-form1}', 2, 'Smith', '{user-guid}'),   -- LAST NAME = Smith
    ('{guid-form1}', 3, '123456798', '{user-guid}'); -- SSN = 123456798

-- Form 2:
INSERT INTO Documents (DocumentId, DocumentTypeId, Title, ...)
VALUES ('{guid-form2}', 1, 'Legal Residence - Joe Smith', ...);

INSERT INTO DocumentIndexData (DocumentId, IndexFieldId, FieldValue, AddedBy)
VALUES 
    ('{guid-form2}', 1, 'Joe', '{user-guid}'),
    ('{guid-form2}', 2, 'Smith', '{user-guid}'),
    ('{guid-form2}', 3, '987654321', '{user-guid}');

-- Form 3:
INSERT INTO Documents (DocumentId, DocumentTypeId, Title, ...)
VALUES ('{guid-form3}', 1, 'Legal Residence - Joe Smith', ...);

INSERT INTO DocumentIndexData (DocumentId, IndexFieldId, FieldValue, AddedBy)
VALUES 
    ('{guid-form3}', 1, 'Joe', '{user-guid}'),
    ('{guid-form3}', 2, 'Smith', '{user-guid}'),
    ('{guid-form3}', 3, '987651234', '{user-guid}');
```

**User Searches**:
```sql
-- Search: Document Type = Legal Residence Form, FIRST NAME = 'Joe'
-- Returns: Form 2, Form 3
SELECT DISTINCT d.*
FROM Documents d
INNER JOIN DocumentIndexData did ON d.DocumentId = did.DocumentId
INNER JOIN IndexFields if ON did.IndexFieldId = if.IndexFieldId
WHERE d.DocumentTypeId = 1
  AND if.FieldName = 'FIRST NAME'
  AND did.FieldValue = 'Joe'
  AND d.DeletedDate IS NULL
  AND did.RemovedDate IS NULL;

-- Search: Document Type = Legal Residence Form, LAST NAME = 'Smith'
-- Returns: Form 1, Form 2, Form 3
SELECT DISTINCT d.*
FROM Documents d
INNER JOIN DocumentIndexData did ON d.DocumentId = did.DocumentId
INNER JOIN IndexFields if ON did.IndexFieldId = if.IndexFieldId
WHERE d.DocumentTypeId = 1
  AND if.FieldName = 'LAST NAME'
  AND did.FieldValue = 'Smith'
  AND d.DeletedDate IS NULL
  AND did.RemovedDate IS NULL;

-- Search: Document Type = Legal Residence Form, SSN = '987651234'
-- Returns: Form 3 only
SELECT DISTINCT d.*
FROM Documents d
INNER JOIN DocumentIndexData did ON d.DocumentId = did.DocumentId
INNER JOIN IndexFields if ON did.IndexFieldId = if.IndexFieldId
WHERE d.DocumentTypeId = 1
  AND if.FieldName = 'SSN'
  AND did.FieldValue = '987651234'
  AND d.DeletedDate IS NULL
  AND did.RemovedDate IS NULL;

-- Advanced: Multiple field search (FIRST NAME = Joe AND SSN starts with '9876')
SELECT DISTINCT d.*
FROM Documents d
WHERE d.DocumentTypeId = 1
  AND EXISTS (
      SELECT 1 FROM DocumentIndexData did
      INNER JOIN IndexFields if ON did.IndexFieldId = if.IndexFieldId
      WHERE did.DocumentId = d.DocumentId
        AND if.FieldName = 'FIRST NAME'
        AND did.FieldValue = 'Joe'
        AND did.RemovedDate IS NULL
  )
  AND EXISTS (
      SELECT 1 FROM DocumentIndexData did
      INNER JOIN IndexFields if ON did.IndexFieldId = if.IndexFieldId
      WHERE did.DocumentId = d.DocumentId
        AND if.FieldName = 'SSN'
        AND did.FieldValue LIKE '9876%'
        AND did.RemovedDate IS NULL
  )
  AND d.DeletedDate IS NULL;
```

### Document Upload Process

**Required during upload**:
1. **Document Type** (mandatory selection)
2. **Required Keywords** (based on DocumentTypeKeywords where IsRequired = 1)
3. **File** (with validation against PreferredFileTypes if configured)

**Upload Workflow**:
```
1. User selects Document Type from dropdown (filtered by groups they belong to)
2. System loads required/optional keywords for that type
3. User enters title, description, selects required keywords (+ optional ones)
4. User uploads file
5. System validates:
   - All required keywords selected?
   - File type matches preferred types? (warning if not, Option B)
   - File size within limit?
## Implementation Notes & Configuration

### Document Upload Process

**Required during upload**:
1. **Document Type** (mandatory selection)
2. **Required Index Fields** (based on DocumentTypeIndexFields where IsRequired = 1)
3. **File** (with validation against PreferredFileTypes if configured)

**Upload Workflow**:
```
1. User selects Document Type from dropdown (e.g., "Legal Residence Form")
2. System loads required/optional index fields for that type (FIRST NAME, LAST NAME, SSN, etc.)
3. User enters title, description, fills in index field values
4. User uploads file
5. System validates:
   - All required index fields filled?
   - Field values match validation rules (regex, max length)?
   - File type matches preferred types? (warning if not, Option B)
   - File size within limit?
6. Generate DocumentNumber from template (e.g., FORM-2026-00001)
7. Store file with GUID-based FileStorageKey
8. Create Documents record
9. Create DocumentIndexData records (one per field)
10. Auto-grant access to groups with view permission
11. Queue for OCR if RequireOCR = 1
```

### Auto-Numbering System

**How It Works**:
- Admin configures format in `DocumentTypes.AutoNumberFormat` (e.g., `'IR-{YYYY}-{#####}'`)
- When document is uploaded, system generates next number: `IR-2026-00001`
- Stored in `Documents.DocumentNumber` as human-readable reference
- Actual file stored with GUID: `Documents.FileStorageKey = '\\fileserver\docs\2a3b4c5d-...-123.pdf'`
- Click to view: App queries by `DocumentNumber` OR `DocumentId`, retrieves `FileStorageKey`, opens file

**Example Configuration**:
```sql
-- Incident Reports
INSERT INTO DocumentTypes (TypeName, AutoNumberFormat, AutoNumberPrefix, AutoNumberNextValue)
VALUES ('Incident Report', 'IR-{YYYY}-{#####}', 'IR', 1);

-- Results in: IR-2026-00001, IR-2026-00002, IR-2026-00003...

-- Legal Forms
INSERT INTO DocumentTypes (TypeName, AutoNumberFormat, AutoNumberPrefix, AutoNumberNextValue)
VALUES ('Legal Residence Form', 'FORM-{YYYY}-{####}', 'FORM', 1);

-- Results in: FORM-2026-0001, FORM-2026-0002...
```

### File Type Handling (Option B: Preferred with Warning)

**Configuration**:
- Admin sets `DocumentTypes.PreferredFileTypes` = `'pdf,docx'` for a document type
- User uploads `.xlsx` file
- System displays warning: "This document type prefers PDF or Word files. Continue anyway?"
- User can proceed or cancel and convert file
- No hard blocking - flexibility for exceptions

### Audit Log Retention Configuration

**SystemSettings entries for retention**:
```sql
-- Configurable retention per audit table type (in days)
INSERT INTO SystemSettings (SettingKey, SettingValue, DataType, Category, Description)
VALUES 
    ('AuditLog.Retention.Authentication', '90', 'Int', 'Audit', 'Login/logout logs retained for 90 days'),
    ('AuditLog.Retention.Documents', '2555', 'Int', 'Audit', '7 years (legal requirement)'),
    ('AuditLog.Retention.DocumentAccess', '365', 'Int', 'Audit', 'Who viewed documents - 1 year'),
    ('AuditLog.Retention.Users', '1825', 'Int', 'Audit', 'User changes - 5 years'),
    ('AuditLog.Retention.UserGroups', '1825', 'Int', 'Audit', 'Group changes - 5 years'),
    ('AuditLog.Retention.GroupMemberships', '1095', 'Int', 'Audit', 'Membership changes - 3 years'),
    ('AuditLog.Retention.GroupPermissions', '1825', 'Int', 'Audit', 'Permission changes - 5 years'),
    ('AuditLog.Retention.DocumentTypes', '3650', 'Int', 'Audit', 'Config changes - 10 years'),
    ('AuditLog.Retention.IndexFields', '730', 'Int', 'Audit', 'Index field changes - 2 years'),
    ('AuditLog.Retention.SystemSettings', '3650', 'Int', 'Audit', 'System config - 10 years'),
    ('AuditLog.Cleanup.Enabled', 'true', 'Bool', 'Audit', 'Enable automatic cleanup job'),
    ('AuditLog.Cleanup.Schedule', '0 2 * * 0', 'String', 'Audit', 'Cron: Run Sunday 2 AM');
```

**Automatic Cleanup Job** (Scheduler.exe):
- Runs weekly (configurable via `AuditLog.Cleanup.Schedule`)
- Permanently deletes records older than configured retention
- No archive option (to save storage for smaller companies)
- Logs deletion summary to `AuditLog_SystemSettings`

### Document Access Inheritance

**When document is uploaded**:
1. User uploads document of type "Incident Report"
2. System looks up which groups have `Document.View` permission (or type-specific permission)
3. System automatically creates `DocumentGroups` records for all those groups
4. All users in those groups can immediately see the new document
5. Access is purely automatic based on group permissions - no manual sharing

**Example**:
```sql
-- Police Officers group has Document.View permission
-- Fire Department group has Document.View permission

-- User uploads Incident Report
-- System auto-creates:
INSERT INTO DocumentGroups (DocumentId, GroupId, CanView, CanEdit, CanDelete, GrantedBy)
VALUES 
    (@NewDocumentId, @PoliceOfficersGroupId, 1, 0, 0, @SystemUserId),
    (@NewDocumentId, @FireDeptGroupId, 1, 0, 0, @SystemUserId);

-- All police officers and fire dept users can now see this document
```

**Access Control Philosophy**:
- Access is determined solely by group membership and group permissions
- No manual document-level sharing - keeps security model simple and auditable
- To grant access: Add user to appropriate group or grant permission to their existing group

---

## Open Questions & Refinements

### ✅ Resolved Questions (From User Feedback):

1. **Auto-Numbering**: ✅ Format stored in DocumentTypes, number stored in Documents.DocumentNumber, file stored by GUID in FileStorageKey
2. **File Type Handling**: ✅ Option B selected - Preferred types with warning (flexible)
3. **Audit Retention**: ✅ Configurable time-based retention per audit table type, automatic deletion (not archive)
4. **Document Access**: ✅ Auto-grant to all groups with permission to view that document type, no manual sharing
5. **Permission Model**: ✅ Two-tier (IsGroupAdmin per-group + UserGroup.Manage global)
6. **Index Fields (Keywords)**: ✅ Redesigned as structured fields with values (FIRST NAME = 'Bob', SSN = '123456798')
7. **Document Type Configuration**: ✅ All options confirmed (name, group, index fields, auto-numbering, file size, file type, OCR, retention, description)
8. **Document.Share Permission**: ✅ Removed - access is purely automatic based on group permissions
9. **Document Type Required**: ✅ Mandatory selection during upload, along with all required index fields for that type

### Pending Phase 1 Questions:

1. **Document User-Level Sharing**:
   - Should we support **user-level** document access in addition to group-level?
   - Use case: Share document with specific individual without creating a group
   - **Decision**: Defer to Phase 2 - Groups-only for Phase 1 simplicity

2. **Index Fields Access Control**:
   - ✅ **RESOLVED**: Use `IsSensitive` flag + `Search.ViewPII` permission
   - Fields marked `IsSensitive = 1` are hidden from users without `Search.ViewPII` permission
   - Simple, consistent with existing permission model
   - No additional tables needed

3. **File Hash Deduplication**:
   - Should we detect duplicate files and save storage?
   - `DocumentVersions.FileHash` already exists for integrity
   - Could be used for: "This file already exists as Document #IR-2026-00042. Create new document or link to existing?"
   - **Decision**: Phase 1 = store hash for integrity, Phase 2 = add deduplication logic

4. **Cascading Deletes**:
   - When user group is deleted, what happens to documents assigned to that group?
   - Reassign to admin group? Prevent deletion? Soft delete only?
   - **Decision**: Soft delete only (`UserGroups.DeletedDate`) + prevent hard deletion if documents exist

---

## Phase 1 Schema Summary

**Total Tables**: 17 core tables

### User Management (4 tables)
1. Users
2. UserGroups
3. UserGroupMembers
4. Permissions
5. GroupPermissions

### Document Management (8 tables)
6. DocumentTypeGroups
7. DocumentTypes
8. DocumentTypeMetadataFields
9. Documents
10. DocumentVersions
11. DocumentGroups (access control)
12. MetadataFields
13. DocumentMetadata

### System & Operations (3 tables)
14. SystemSettings
15. OcrQueue
16. Notifications

### Audit Logs (11 separate tables)
17-27. AuditLog_* (Users, UserGroups, GroupMemberships, GroupPermissions, Documents, DocumentAccess, DocumentTypes, DocumentTypeGroups, IndexFields, SystemSettings, Authentication)

**Total**: 16 core + 11 audit = **27 tables for Phase 1**

---

## Next Steps

1. ✅ **Functional Requirements**: Complete - gathered via user's detailed document
2. ✅ **Auto-Numbering Design**: Complete - clarified format usage and storage
3. ✅ **File Type Handling**: Complete - Option B selected (preferred with warnings)
4. ✅ **Audit Retention**: Complete - configurable time-based with automatic cleanup
5. ✅ **Access Inheritance**: Complete - auto-grant to groups with permissions, no manual sharing
6. ✅ **Document Type Required**: Complete - mandatory selection during upload with required keywords
7. **ERD Visualization**: Create visual entity-relationship diagram
8. **Sample Data**: Create realistic test data for development
9. **Migration Scripts**: Write Entity Framework Core migrations
10. **Permission List**: Document complete list of 50+ permissions with categories

---

**STATUS**: Phase 1 Draft v0.3 - ✅ Complete and ready for implementation

**Last Updated**: January 26, 2026
