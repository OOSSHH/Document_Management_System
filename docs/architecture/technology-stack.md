# System Architecture & Technology Stack

## Document Management System - Technical Architecture Decision

**Status**: In Progress  
**Date**: January 25, 2026  
**Target**: Government Agencies (Local/Municipal)

---

## 1. Architecture Overview

### High-Level Architecture Pattern
**Selected**: **Client-Server Architecture with Microservices Backend**

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT TIER                                   │
├────────────┬─────────────┬─────────────┬─────────────┬───────────┤
│ Config.exe │Workflow.exe │MainApp.exe  │Scheduler.exe│Diagnostics│
│  (Admin)   │ (Designer)  │(End Users)  │(Automation) │  (IT/Dev) │
├────────────┴─────────────┴─────────────┴─────────────┴───────────┤
│              Web Interface (Browser) + Public Portal             │
└──────────────────────────────┬───────────────────────────────────┘
                               │
         ┌─────────────────────▼─────────────────────┐
         │   API Gateway                             │
         │  (Rate Limiting, Authentication)          │
         └─────────────────────┬─────────────────────┘
                               │
      ┌─────────────┴─────────────┐
      │                           │
┌─────▼─────────────────────────────────────────────┐
│           BACKEND SERVICES TIER                   │
├───────────────┬───────────────┬───────────────────┤
│  Document API │ Workflow API  │ User/Auth API     │
│  Search API   │ Forms API     │ Scheduler API     │
│  Reports API  │ OCR Worker    │ Notification Svc  │
└───────┬───────┴───────┬───────┴───────┬───────────┘
        │               │               │
┌───────▼───────┬───────▼───────┬───────▼───────┐
│   Database    │ Search Engine │ File Storage  │
│  (SQL Server/ │ (Elasticsearch│ (Local/Azure  │
│  PostgreSQL)  │ /Azure Search)│  Blob/AWS S3) │
└───────────────┴───────────────┴───────────────┘
```

**Rationale**:
- **Government Requirements**: On-premise deployment capability essential
- **Scalability**: Individual services can scale independently
- **Security**: Clear separation of concerns, easier to audit
- **Maintenance**: Services can be updated without full system downtime
- **Flexible Access Control**: User groups can span departments or be granular within departments

---

## 2. Technology Stack Decisions

### 2.1 Backend Framework
**Selected**: **ASP.NET Core 8 Web API**

**Alternatives Considered**:
- Node.js/Express
- Python/Django or FastAPI
- Java/Spring Boot

**Decision Factors**:
✅ **Chose ASP.NET Core 8 because**:
- **Government Compatibility**: Most local governments use Windows infrastructure
- **Enterprise Features**: Built-in authentication, authorization, dependency injection
- **Performance**: Excellent performance for document-heavy operations
- **Desktop Integration**: Same .NET ecosystem as WPF/MAUI desktop apps
- **Active Directory Integration**: Seamless integration with government networks
- **Long-term Support**: Microsoft LTS guarantees
- **Security**: Regular security updates, built-in CSRF/XSS protection
- **Mature Ecosystem**: Extensive libraries for PDF, Office docs, OCR

**Technology Versions**:
- .NET 8 (LTS - supported until November 2026)
- ASP.NET Core 8 Web API
- C# 12

---

### 2.2 Database
**Selected**: **SQL Server 2022** (Primary Recommendation)  
**Alternative**: **PostgreSQL 15+** (For cost-conscious deployments)

**Comparison**:

| Feature | SQL Server 2022 | PostgreSQL 15 |
|---------|----------------|---------------|
| **Cost** | Licensed (Express free up to 10GB) | Free/Open Source |
| **Government Use** | Common in gov agencies | Growing adoption |
| **Windows Integration** | Excellent | Good |
| **Active Directory** | Native support | Requires pgAdmin |
| **Backup/Recovery** | Enterprise-grade tools | Excellent, open tools |
| **JSON Support** | Excellent | Excellent |
| **Full-Text Search** | Built-in | Built-in (good) |
| **Scalability** | Excellent | Excellent |
| **Audit Features** | Built-in temporal tables | Extension required |

**Selected**: **SQL Server 2022** for:
- Better Windows/AD integration (government requirement)
- Familiar to most government IT departments
- Built-in temporal tables for audit compliance
- SQL Server Express free for small deployments

**Fallback**: PostgreSQL for budget-constrained agencies

**ORM**: **Entity Framework Core 8**
- Type-safe database access
- Migration management
- LINQ queries
- Change tracking for audit logs

---

### 2.3 Search Engine
**Selected**: **Elasticsearch 8.x** (Self-Hosted)  
**Alternative**: **Azure Cognitive Search** (Cloud-only deployments)

**Decision Matrix**:

| Feature | Elasticsearch | Azure Cognitive Search |
|---------|---------------|------------------------|
| **Deployment** | Self-hosted | Cloud only |
| **Cost** | Free (Apache 2.0) | Pay per use |
| **Full-Text Search** | Excellent | Excellent |
| **OCR Text Indexing** | Excellent | Excellent |
| **Scalability** | Horizontal scaling | Managed scaling |
| **Security** | Self-managed | Microsoft-managed |
| **Government** | On-premise OK | Cloud concerns |

**Selected**: **Elasticsearch 8.x** because:
- On-premise deployment required for many government agencies
- No recurring cloud costs
- Full control over sensitive data
- Excellent full-text search capabilities
- Native JSON document indexing
- Powerful aggregation for reports

**Configuration**:
- Single-node for small agencies (<10K documents)
- 3-node cluster for medium agencies (10K-100K documents)
- 5+ node cluster for large agencies (100K+ documents)

---

### 2.4 Desktop Application Framework
**Selected**: **WPF (Windows Presentation Foundation) with .NET 8**

**Alternatives Considered**:
- .NET MAUI (cross-platform)
- Electron (web technologies)
- Windows Forms (legacy)

**Selected WPF because**:
- **Target Audience**: Government agencies primarily use Windows
- **Rich UI**: Complex data grids, drag-drop, charts
- **Mature**: 15+ years of development, stable
- **Performance**: Native Windows performance
- **MVVM Support**: Clean architecture with CommunityToolkit.Mvvm
- **Design Tools**: Excellent designer support in Visual Studio
- **Active Directory**: Native Windows authentication

**UI Framework**: **MaterialDesignInXaml** or **ModernWpf**
- Modern, clean appearance
- Government-appropriate professional look
- Accessibility built-in

**Desktop Applications Suite**:
1. **Config.exe**: System configuration, user/group management, security settings
2. **Workflow.exe**: Visual workflow designer with drag-drop canvas
3. **MainApp.exe**: Document management for end users
4. **Scheduler.exe**: Task automation configuration and monitoring
5. **Diagnostics.exe**: Real-time error logging, system health monitoring, troubleshooting

**Note**: .NET MAUI can be adopted later if cross-platform needed (Mac/Linux)

---

### 2.5 Web Frontend Framework
**Selected**: **React 18 with TypeScript**

**Alternatives Considered**:
- Blazor WebAssembly (stay in .NET)
- Angular
- Vue.js

**Decision Matrix**:

| Feature | React + TS | Blazor WASM | Angular |
|---------|-----------|-------------|---------|
| **Learning Curve** | Moderate | Low (for .NET devs) | Steep |
| **Performance** | Excellent | Good (larger payload) | Excellent |
| **Ecosystem** | Huge | Growing | Large |
| **Government Use** | Common | Emerging | Common |
| **PWA Support** | Excellent | Good | Excellent |
| **Mobile** | React Native option | Limited | Ionic option |

**Selected React + TypeScript because**:
- Largest ecosystem and community
- Excellent PWA support (critical for mobile access)
- Future mobile app via React Native
- Better performance for document-heavy UIs
- Wider talent pool for government hiring

**UI Component Library**: **Material-UI (MUI)** or **Ant Design**
- Professional, accessible components
- Built-in responsive design
- Government-appropriate styling

---

### 2.6 File Storage
**Selected**: **Hybrid Approach** (Local + Cloud Option)

**Local Storage**:
- **Windows File System** with structured folder hierarchy
- Department-based folder partitioning
- NTFS encryption at rest
- Windows Backup integration

**Cloud Storage (Optional)**:
- **Azure Blob Storage** (Primary cloud option)
- **AWS S3** (Alternative)
- Encrypted transfers (TLS 1.3)
- Geo-redundant storage for disaster recovery

**Decision**: **Local by default, cloud as configuration option**
- Many government agencies require on-premise data
- Cloud backup for disaster recovery
- Hybrid: Local primary, cloud backup

**File Organization**:
```
/DMSStorage/
  /Documents/
    /2026/
      /01-January/
        {DocumentID}_v1.pdf
        {DocumentID}_v2.pdf
      /02-February/
  /Archives/
    /2025/
  /Public/
  /Temp/
```

**Access Control Strategy**:
- Files organized by date, not by department
- Access controlled via database permissions and user groups
- User groups define who can see which documents (flexible, not tied to org chart)
- Groups can be department-wide, cross-departmental, or specific teams

---

### 2.7 OCR Engine
**Selected**: **Tesseract OCR 5.x** (Primary)  
**Optional**: **Azure Computer Vision API** (High-accuracy needs)

**Comparison**:

| Feature | Tesseract | Azure Computer Vision |
|---------|-----------|----------------------|
| **Cost** | Free | Pay per page |
| **Accuracy** | 85-95% | 95-99% |
| **Deployment** | On-premise | Cloud API |
| **Languages** | 100+ | 70+ |
| **Speed** | Good (local) | Fast (cloud) |
| **Handwriting** | Limited | Good |

**Selected**: **Tesseract 5.x** because:
- Free and open source
- On-premise processing (data security)
- Good accuracy for typed documents
- No per-page costs

**Wrapper**: **Tesseract.Net SDK** for .NET integration

**Upgrade Path**: Azure Computer Vision for departments needing higher accuracy (Police evidence, Legal contracts)

---

### 2.8 Job Scheduling
**Selected**: **Hangfire** (ASP.NET Core)

**Alternatives**:
- Quartz.NET
- Windows Task Scheduler
- Azure Functions (cloud)

**Selected Hangfire because**:
- Native ASP.NET Core integration
- Web-based dashboard (monitoring)
- Persistent jobs (survives restarts)
- Recurring jobs with cron expressions
- Retry logic built-in
- Dashboard accessible from Config.exe

**Use Cases**:
- OCR processing queue
- Document retention/archival
- Report generation
- Search index updates
- Workflow deadline reminders

---

### 2.9 Message Queue (OCR Processing)
**Selected**: **RabbitMQ** (Self-hosted)  
**Alternative**: **Azure Service Bus** (Cloud deployments)

**Selected RabbitMQ because**:
- On-premise deployment
- Reliable message delivery
- Dead letter queues for failed OCR
- Priority queues (urgent documents first)
- Management UI included

**Queue Structure**:
```
ocr-queue (high-priority)
ocr-queue (normal-priority)
ocr-failed (dead letter)
notification-queue
indexing-queue
```

---

### 2.10 Authentication & Authorization
**Selected**: 
- **ASP.NET Core Identity** (User management)
- **JWT Tokens** (API authentication)
- **Active Directory** (Government SSO)

**Authentication Flow**:
1. Desktop apps: Windows Authentication → AD validation
2. Web interface: Username/Password or AD SSO → JWT token
3. Public portal: Anonymous or optional login

**Authorization**:
- Role-Based Access Control (RBAC)
- Claims-based authorization
- Department-based data isolation
- Document-level ACLs

**Multi-Factor Authentication**:
- Optional MFA for sensitive departments (Police, Legal, HR)
- Integration with Microsoft Authenticator or SMS

---

### 2.11 Reporting & Export
**Selected**:
- **PDF**: **QuestPDF** (free, .NET native)
- **Excel**: **ClosedXML** or **EPPlus** (LGPL)
- **Charts**: **Chart.js** (web), **LiveCharts2** (WPF)

**Report Generation Service**:
- Background worker using Hangfire
- Template-based reports
- Scheduled report delivery via email

---

### 2.12 Caching
**Selected**: 
- **In-Memory Cache** (ASP.NET Core) for small deployments
- **Redis** (optional) for distributed caching in multi-server setups

**Cached Data**:
- User permissions
- Department hierarchies
- Keyword lists
- Search results (5-minute TTL)
- Document metadata (not file content)

---

### 2.13 Logging & Monitoring
**Selected**:
- **Logging**: **Serilog** (structured logging)
- **Monitoring**: **Application Insights** (optional) or **ELK Stack** (self-hosted)

**Log Storage**:
- File logs: `/Logs/{Date}.log`
- Database logs: Audit table (user actions)
- Elasticsearch: Searchable log analytics

**Monitoring Metrics**:
- API response times
- Document upload/download rates
- OCR processing queue length
- Search query performance
- Failed login attempts
- Storage usage

---

## 3. Shared Component Libraries

### 3.1 Shared .NET Libraries

**DMS.Shared.Core**:
- Common models (User, Document, Workflow, Department)
- Enums and constants
- Extension methods

**DMS.Shared.API.Client**:
- HTTP client wrapper
- API endpoint definitions
- Request/response DTOs

**DMS.Shared.Security**:
- Encryption helpers
- Token validation
- Permission checking

**DMS.Shared.Utils**:
- File handling utilities
- Date/time helpers
- String formatting

---

## 4. Development Environment

### Required Software
- **Visual Studio 2022** (17.8+) or **VS Code** with C# extensions
- **.NET 8 SDK**
- **SQL Server 2022 Developer Edition** or **PostgreSQL 15**
- **Node.js 20+ LTS** (for web frontend)
- **Docker Desktop** (for Elasticsearch, RabbitMQ local testing)
- **Git** (version control)

### Recommended Extensions
- **Visual Studio**: ReSharper or built-in code analysis
- **VS Code**: C# Dev Kit, ESLint, Prettier

---

## 5. Deployment Architecture

### Small Agency (<5 Departments, <1000 Users)
```
Single Server:
- Windows Server 2022
- SQL Server 2022 Express
- ASP.NET Core API
- Elasticsearch (single node)
- File Storage (local RAID)
```

### Medium Agency (5-20 Departments, 1000-5000 Users)
```
3-Server Setup:
- Server 1: Web/API (IIS + ASP.NET Core)
- Server 2: Database (SQL Server Standard)
- Server 3: Search + Workers (Elasticsearch + Hangfire)
- Shared Storage: NAS or SAN
```

### Large Agency (20+ Departments, 5000+ Users)
```
Multi-Server Cluster:
- Load Balancer: NGINX or Azure Load Balancer
- Web/API Servers: 2+ (horizontal scaling)
- Database: SQL Server Enterprise (Always On)
- Search Cluster: 5-node Elasticsearch
- Worker Pool: 3+ background worker servers
- Storage: SAN or Azure Blob (geo-redundant)
```

---

## 6. Security Architecture

### Data Security
- **Encryption at Rest**: 
  - Database: Transparent Data Encryption (TDE)
  - Files: NTFS encryption or Azure Storage encryption
- **Encryption in Transit**: 
  - TLS 1.3 for all API communications
  - HTTPS enforced on all web interfaces

### Network Security
- **Firewall**: Allow only necessary ports (443 for HTTPS, SQL port restricted)
- **VPN**: Remote access via government VPN
- **DMZ**: Public portal in DMZ, internal systems behind firewall

### Application Security
- **Input Validation**: All user inputs sanitized
- **SQL Injection**: Parameterized queries (Entity Framework)
- **XSS Protection**: Output encoding, Content Security Policy
- **CSRF Protection**: Anti-forgery tokens
- **Rate Limiting**: Prevent API abuse

---

## 7. Backup & Disaster Recovery

### Backup Strategy
- **Database**: 
  - Full backup: Daily (3am)
  - Differential: Every 6 hours
  - Transaction log: Every 15 minutes
  - Retention: 30 days local, 1 year offsite
  
- **File Storage**: 
  - Incremental backup: Daily
  - Full backup: Weekly
  - Retention: 90 days local, 1 year offsite

- **Configuration**:
  - Export nightly (JSON/XML)
  - Version controlled in Git

### Disaster Recovery
- **RTO (Recovery Time Objective)**: 4 hours
- **RPO (Recovery Point Objective)**: 15 minutes
- **Failover**: Manual failover to backup site
- **Testing**: Quarterly DR drills

---

## 8. Scalability Considerations

### Horizontal Scaling
- **API Servers**: Add more web servers behind load balancer
- **Workers**: Add more background processing servers
- **Search**: Add Elasticsearch nodes to cluster

### Vertical Scaling
- **Database**: Upgrade server RAM/CPU
- **Storage**: Add more disk space or faster drives

### Performance Targets
- **Document Upload**: <5 seconds for 10MB file
- **Search**: <1 second response for 100K documents
- **OCR Processing**: <2 minutes per page
- **API Response**: <200ms for CRUD operations
- **Concurrent Users**: Support 1000+ simultaneous users

---

## 9. Cost Estimation (Annual)

### Small Agency Setup
- **Software**: $0 (free/open source stack with SQL Server Express)
- **Hardware**: $5,000 (single server)
- **Development**: $80,000-120,000 (1-2 developers, 6 months)
- **Total Year 1**: ~$85,000-125,000

### Medium Agency Setup
- **Software**: $3,000 (SQL Server Standard license)
- **Hardware**: $15,000 (3 servers)
- **Development**: $120,000-180,000 (2-3 developers, 9 months)
- **Total Year 1**: ~$138,000-198,000

### Cloud Alternative (Azure)
- **Monthly Costs**: $500-2000 (depending on usage)
- **Annual**: $6,000-24,000 (operational costs)
- **Development**: Same as above

---

## 10. Decision Summary

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Backend** | ASP.NET Core 8 | Government compatibility, enterprise features |
| **Database** | SQL Server 2022 | Windows integration, government familiarity |
| **Search** | Elasticsearch 8 | On-premise, powerful full-text search |
| **Desktop** | WPF .NET 8 | Windows native, rich UI capabilities |
| **Web** | React 18 + TypeScript | Ecosystem, PWA support, performance |
| **Storage** | Local FS + Azure Blob | Flexibility, on-premise with cloud backup |
| **OCR** | Tesseract 5 | Free, on-premise, good accuracy |
| **Scheduler** | Hangfire | ASP.NET integration, web dashboard |
| **Queue** | RabbitMQ | Reliable, on-premise message queue |
| **Auth** | ASP.NET Identity + AD | Government SSO, familiar to IT staff |

---

## Next Steps

1. ✅ **Set up development environment** (Visual Studio, .NET 8, SQL Server)
2. ✅ **Technology stack decisions finalized**
3. ⬜ **Create solution structure** (backend API, desktop apps, web frontend)
4. ⬜ **Set up Git repository** with branching strategy
5. ⬜ **Initialize database** with Entity Framework Core migrations
6. ⬜ **Create proof-of-concept** (simple document upload/retrieve)
7. ⬜ **Design database schema** (Task 2)

---

**Document Version**: 1.1  
**Last Updated**: January 25, 2026  
**Status**: Completed
**Approved By**: [Pending Review]

**Note**: File storage structure and database schemas will be refined during implementation phases.
