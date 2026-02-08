# Document Management System - Development Roadmap
**Phase 1 Implementation Guide**

---

## Current Status
✅ Database schema created (19 core tables)  
✅ Initial data setup complete (system admin, permissions, settings)  
✅ Sample configuration data created  

---

## Next Steps: Application Development

### **Step 1: Project Setup & Infrastructure**
**Goal**: Create solution structure and shared components

1. **Create Visual Studio Solution**
   - Create new Windows Forms solution: `DocumentManagementSystem.sln`
   - Target: .NET 8.0 (or .NET Framework 4.8 if required)
   - Projects to create:
     - `DMS.Main` - Main document management application
     - `DMS.Config` - Admin configuration tool
     - `DMS.Scheduler` - Background job processor
     - `DMS.Core` - Shared business logic library
     - `DMS.Data` - Data access layer (Entity Framework Core)
     - `DMS.Common` - Shared utilities and models

2. **Set Up Data Access Layer (DMS.Data)**
   - Install Entity Framework Core NuGet packages
   - Create DbContext with all 19 tables as DbSets
   - Generate entity models from existing database (scaffold)
   - Configure connection strings in app.config/appsettings.json
   - Test database connectivity

3. **Create Core Business Logic (DMS.Core)**
   - Services layer:
     - `AuthenticationService` - User login, permissions check
     - `DocumentService` - Document CRUD operations
     - `UserService` - User/group management
     - `PermissionService` - Permission checking
     - `AuditService` - Audit logging
     - `FileStorageService` - File save/retrieve operations
   - DTOs and view models
   - Business validation logic

4. **Common Utilities (DMS.Common)**
   - Logging helper
   - Configuration manager (reads SystemSettings table)
   - File validation utilities
   - Extension methods
   - Constants and enums

**Deliverable**: Solution structure with working database connection

---

### **Step 2: Main.exe - Core Document Management**
**Goal**: Users can upload, search, and view documents

#### **2.1 Authentication & Main Window**
1. **Login Form**
   - Username/password fields
   - "Remember me" checkbox
   - Validate against Users table
   - Check IsActive, account lockout
   - Load user's groups and permissions
   - Store current user in session

2. **Main Dashboard Window**
   - Menu bar: File, Edit, View, Tools, Help
   - Toolbar: New Document, Search, Recent, Refresh
   - Status bar: User info, connection status
   - Main area: Document list or search results grid

#### **2.2 Document Upload**
1. **New Document Form**
   - Document Type dropdown (filtered by user's group permissions)
   - Load required/optional index fields for selected type
   - Title and Description text boxes
   - Dynamic index field controls (text, date, dropdown based on field type)
   - File browser button
   - Validate file type against PreferredFileTypes (show warning if mismatch)
   - Validate file size against MaxFileSizeBytes
   - Validate required index fields filled
   - Validate field values against ValidationRegex

2. **Upload Process**
   - Generate DocumentNumber from AutoNumberFormat
   - Calculate file hash (SHA-256)
   - Copy file to Storage.BasePath with GUID filename
   - Create Documents record
   - Create DocumentVersions record
   - Create DocumentIndexData records (one per field)
   - Auto-grant access via DocumentGroups (based on group permissions)
   - Queue for OCR if RequireOCR = 1
   - Log to AuditLogs

3. **Progress Indicator**
   - Show progress bar during file copy
   - Display success message with DocumentNumber
   - Option to upload another or view document

#### **2.3 Document Search**
1. **Search Form**
   - Basic search: Title, DocumentNumber, date range
   - Advanced search: Index field filters (dynamically loaded)
   - Document Type filter
   - Status filter (Draft/Active/Archived)
   - Created by/date filters
   - Full-text search option

2. **Search Results Grid**
   - Columns: DocumentNumber, Title, Type, Created Date, Created By, Status
   - Sort by any column
   - Pagination (use SystemSettings: General.PageSize)
   - Filter results by user's access (join DocumentGroups)
   - Hide sensitive index fields if user lacks Search.ViewPII permission
   - Double-click to view document

3. **Search Query Building**
   - Dynamic SQL based on selected filters
   - Security: Always filter by user's groups (DocumentGroups table)
   - Performance: Use indexed queries (IX_IndexFieldSearch)

#### **2.4 Document Viewing**
1. **Document Details Form**
   - Display all metadata (title, description, type, dates)
   - Display all index field values (hide sensitive if no permission)
   - Show document number prominently
   - Version history list
   - Action buttons: Download, Edit, New Version, Delete

2. **File Viewing**
   - "Open File" button retrieves FileStorageKey
   - Launch file with default application (Process.Start)
   - Or embed PDF viewer for in-app viewing (optional)

3. **Version Management**
   - List all versions with version number, date, uploaded by
   - View/download any version
   - Upload new version (increments CurrentVersionNumber)

4. **Edit Metadata**
   - Check Document.Edit permission
   - Allow editing title, description, index field values
   - Log changes to AuditLogs

**Deliverable**: Working document upload, search, and viewing

---

### **Step 3: Config.exe - Administration Tool**
**Goal**: Admins can configure system, users, groups, document types

#### **3.1 User Management**
1. **User List**
   - DataGridView: Username, Name, Email, Active, Last Login
   - Add/Edit/Delete buttons
   - Filter by active/inactive

2. **User Form**
   - Fields: Username, Email, First/Last Name, Job Title, Employee ID
   - IsActive checkbox
   - Password reset button
   - Group membership checklist (with IsGroupAdmin checkboxes)
   - Save validates username uniqueness

3. **User Groups**
   - List groups with member count
   - Add/Edit/Delete group
   - Group form: Name, Description, Type, ParentGroup
   - Manage members (add/remove users)

#### **3.2 Permission Management**
1. **Group Permissions Form**
   - Select group from dropdown
   - Checklist of all permissions (grouped by category)
   - Grant/Revoke buttons
   - Show inherited permissions from parent groups (read-only)

2. **Permission Audit**
   - "Who has this permission?" query
   - "What can this user do?" query

#### **3.3 Document Type Configuration**
1. **Document Type Groups**
   - List with DisplayOrder
   - Add/Edit/Delete
   - Set Icon and Color for UI

2. **Document Types**
   - List grouped by DocumentTypeGroup
   - Add/Edit form:
     - Type Name, Description
     - Auto-numbering: Format, Prefix, Next Value
     - File handling: PreferredFileTypes, MaxFileSizeBytes
     - OCR: RequireOCR checkbox
     - Retention: RetentionDays
     - Display: Order, Icon, Color
   - Preview auto-number format

3. **Index Field Management**
   - List all fields with FieldType, IsSearchable, IsSensitive
   - Add/Edit form:
     - Field Name, Description
     - Field Type (Text/Number/Date/Boolean/Dropdown)
     - Validation: MaxLength, ValidationRegex
     - Dropdown options (JSON editor)
     - Access: IsSensitive checkbox
   - Test validation regex tool

4. **Document Type Index Fields**
   - For selected document type, show assigned fields
   - Add/remove fields
   - Set IsRequired and DisplayOrder
   - Preview what upload form will look like

#### **3.4 System Settings**
1. **Settings Editor**
   - TreeView grouped by Category
   - Edit value with type-appropriate control (textbox/checkbox/number)
   - Validation against ValidationRules
   - Encrypt sensitive settings (Email.Password, AD.Password)
   - Test Email/AD connection buttons

2. **Audit Log Viewer**
   - Filter by date range, user, entity type, action
   - Export to CSV
   - Retention policy configuration

**Deliverable**: Complete admin configuration tool

---

### **Step 4: Scheduler.exe - Background Jobs**
**Goal**: Automated OCR processing and audit cleanup

#### **4.1 Project Setup**
1. **Console Application** or **Windows Service**
   - Runs continuously or on schedule
   - Reads SystemSettings for job schedules
   - Logs to file and database

2. **Job Framework**
   - `IJob` interface
   - `JobScheduler` class (uses cron expressions or timers)
   - Job status tracking

#### **4.2 OCR Processing Job**
1. **OCR Worker**
   - Query OcrQueue WHERE Status = 'Pending' ORDER BY Priority DESC
   - Process top N items (configurable: OCR.MaxConcurrentJobs)
   - For each document:
     - Update Status = 'Processing'
     - Call OCR library (Tesseract.NET or Azure Computer Vision)
     - Save ExtractedText to OcrQueue and Documents.OcrText
     - Update Status = 'Completed' or 'Failed'
     - Increment RetryCount on failure
   - Respect OCR.ProcessingTimeout setting

2. **OCR Library Integration**
   - Install Tesseract.OCR NuGet package (free, open source)
   - Or integrate Azure Computer Vision API (cloud service)
   - Handle PDF multi-page processing

#### **4.3 Audit Log Cleanup Job**
1. **Cleanup Worker**
   - Runs based on AuditLog.Cleanup.Schedule (cron)
   - For each audit type:
     - Read retention period from SystemSettings
     - DELETE FROM AuditLogs WHERE EntityType = X AND EventDate < DATEADD(day, -retention, GETUTCDATE())
   - Log summary: "Deleted 1,234 audit records older than retention policy"

2. **Safety Checks**
   - Confirm AuditLog.Cleanup.Enabled = true
   - Transaction safety (rollback on error)
   - Never delete records without retention policy set

#### **4.4 Email Queue Processor**
1. **Email Sender**
   - Poll EmailQueue WHERE Status = 'Pending'
   - Send via SMTP using SystemSettings configuration
   - Update Status = 'Sent' or 'Failed'
   - Retry logic based on Email.MaxRetries

#### **4.5 Monitoring & Logging**
1. **Console Output** or **Windows Event Log**
2. **Database Logging** (create SchedulerLogs table or use AuditLogs)
3. **Email Alerts** for critical failures

**Deliverable**: Background job processor handling OCR, cleanup, emails

---

### **Step 5: Advanced Features**

#### **5.1 Full-Text Search Integration**
1. Test SQL Server Full-Text Search performance
2. Or integrate Elasticsearch for better search (optional)
3. Implement wildcard and proximity searching

#### **5.2 File Previews**
1. Integrate PDF viewer control (PdfiumViewer or similar)
2. Image thumbnails for JPEG/PNG documents
3. Office document preview (requires Office interop or cloud service)

#### **5.3 User Experience Enhancements**
1. Recent documents list
2. Favorites/bookmarks
3. Drag-and-drop file upload
4. Bulk upload (multiple files)
5. Export search results to Excel

#### **5.4 Security Hardening**
1. Password hashing (use BCrypt or Argon2)
2. Session timeout enforcement
3. Failed login tracking and lockout
4. Audit all sensitive operations
5. Encrypt sensitive SystemSettings (IsSensitive = 1)

#### **5.5 Reporting**
1. Document upload statistics
2. User activity reports
3. Storage usage by document type
4. Audit trail reports

**Deliverable**: Production-ready system

---

### **Step 6: Testing & Deployment**

#### **6.1 Testing**
1. **Unit Tests**
   - Core business logic
   - Validation rules
   - Permission checks

2. **Integration Tests**
   - Database CRUD operations
   - File storage operations
   - OCR processing

3. **User Acceptance Testing**
   - Test with real users
   - Collect feedback
   - Fix bugs

#### **6.2 Deployment**
1. **Database Migration Scripts**
   - Version control for schema changes
   - Upgrade path from v0.1 → v0.2 → etc.

2. **Application Deployment**
   - ClickOnce deployment (auto-update)
   - Or MSI installer
   - Central configuration management

3. **Documentation**
   - User manual
   - Admin guide
   - API documentation (if building web API later)

4. **Training**
   - Admin training (Config.exe)
   - End user training (Main.exe)
   - Video tutorials

**Deliverable**: Deployed and operational system

---

## Development Priority Order

### **Week 1-2: Foundation**
- ✅ Database setup (DONE)
- Project structure and data access layer
- Authentication and login

### **Week 3-4: Core Features**
- Document upload form
- Basic search functionality
- Document viewing

### **Week 5-6: Administration**
- User/group management
- Document type configuration
- Index field setup

### **Week 7-8: Automation**
- OCR processing job
- Audit cleanup job
- Testing and bug fixes

### **Week 9-10: Polish & Deploy**
- Advanced search
- Reporting
- User testing
- Deployment

---

## Critical Success Factors

1. **Security First**: Always filter by user's groups, check permissions before any action
2. **Audit Everything**: Log all create/update/delete operations
3. **User Experience**: Fast search, intuitive upload, easy navigation
4. **Performance**: Index optimization, caching, pagination
5. **Reliability**: Transaction safety, error handling, data validation

---

## Next Immediate Actions

1. **Create Visual Studio solution** with 6 projects
2. **Scaffold Entity Framework models** from database
3. **Build login form** and test authentication
4. **Start Main.exe with document upload form**

---

**You're ready to start building!** 🚀
