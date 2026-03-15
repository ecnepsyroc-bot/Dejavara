# Cambium — Comprehensive Project Context

**Feature Millwork's Unified Automation Platform**
*For use in Claude AI Projects*
*Updated: 2026-03-15*

## 1. Project Overview

Cambium is a collection of integrated C# automation systems built to serve Feature Millwork, a custom architectural millwork manufacturing company in Coquitlam, BC, Canada. The platform automates shop floor communication, drawing production, operational workflows, and job management across a 26-person team managing 30+ active projects simultaneously.

### What Cambium Does

- Replaces email threads and paper-based workflows with real-time messaging
- Automates CAD drawing production via AutoCAD plugins (Luxify)
- Manages job specifications, materials, hardware, and assembly workflows
- Tracks factory orders, site installations, and quality control
- Coordinates cross-trade communications and logistics
- Generates documents and specifications from data (PDFs, Excel, Word)
- Tracks laminate inventory on the shop floor (PRODUCTION system)

### Core Philosophy

- **"Humans decide. Systems prepare."** — AI translates intent, humans maintain authority
- **"Ship one reflex at a time."** — Deliver incremental value, not complete systems
- **"100 clicks → 3 clicks"** — Measure success by automation reduction
- **"Architecture is enforcement, not suggestion."** — Boundaries must be mechanical
- **"Paper follows data."** — Documents generated from events, never re-keyed

## 2. Architecture Summary: Hexagonal Architecture

Cambium follows a hexagonal architecture — isolation units with explicit bridges for cross-module communication.

### 2.1 Modules (Isolation Units)

**Location:** `Cambium/Cambium/modules/`

Self-contained services that own specific business logic. Each module:

- Is completely self-contained with its own logic, invariants, and data rules
- Does NOT import from other modules (mechanical enforcement)
- Owns its entities and data rules

**Current Modules (20):**

| Module | Responsibility | Status |
|--------|----------------|--------|
| Cambium.Module.Badges | Badge management, categories, status tracking | Active |
| Cambium.Module.Bom | Bill of materials | Building |
| Cambium.Module.Chat | Real-time messaging, problem tracking, chat threads | Active |
| Cambium.Module.Courier | Shipping/document routing | Building |
| Cambium.Module.Directory | Organization/contact directory | Building |
| Cambium.Module.Documents | Document storage, generation, archival | Building |
| Cambium.Module.DrawingCheckout | Drawing checkout workflow | Building |
| Cambium.Module.Inventory | Laminate inventory tracking, stock levels | **PRODUCTION** |
| Cambium.Module.Jobs | Job CRUD, factory orders, status transitions | Building |
| Cambium.Module.Locations | Location/spatial data | Building |
| Cambium.Module.Production | Production workflows | Active |
| Cambium.Module.Purchasing | Purchasing workflows | Building |
| Cambium.Module.Samples | Sample tracking and approval | Building |
| Cambium.Module.Specifications | Specification data management | Building |
| Cambium.Module.Staging | Staging environment for spec-first features | Active |
| Cambium.Module.Workflow | Workflow state machines | Building |
| Cambium.Courier | Email/shipment routing, addresses, contacts | Building |
| Cambium.PdfLibrary | PDF generation | Building |
| Cambium.Sheets | Sheet generation and layout | Building |
| Cambium.Workflow | Workflow definitions | Stub |

**Note:** 4 `.module.md` files exist in `Cambium.DocumentManagement/Modules/` (Drawings, ExternalRefs, Projects, Submittals). No `.module.md` files exist in the `modules/` directory itself. 11 `.adapter.md` files exist in `adapters/`.

### 2.2 Adapters (Bridges)

**Location:** `Cambium/Cambium/adapters/`

Explicit connectors between modules for cross-module communication. Adapters:

- Orchestrate behavior between modules (but own no domain logic)
- Map and translate data flows between modules
- Are the ONLY mechanism for cross-module interaction

**Current Adapters (8):**

| Adapter | Connects | Purpose | Notes |
|---------|----------|---------|-------|
| SpecToAutoCAD | Specifications → AutoCAD | Specifications to AutoCAD | Intentional cross-context read (documented exception) |
| SpecToMaster | Specifications → Masters | Badge specs flow to drawing templates (via named pipe to AutoCAD) | |
| FlagToOverlay | Specifications → Masters | Flag status flows to visual overlays | |
| JobToChat | Jobs → Chat | Broadcasts job events, manages chat subcategories | Event-driven (fixed 2026-02-16) |
| DrawingCheckoutToChat | DrawingCheckout → Chat | Drawing checkout notifications | |
| MasterToSheet | Masters → Sheets | Template data to sheet generation | Placeholder — implement or remove |
| SheetToPdf | Sheets → PdfLibrary | Generated sheets to PDF output | Placeholder — implement or remove |
| StagingToProduction | Staging → Production | Promotes staging data to production | |

**Architecture fix (2026-02-16):** Controllers no longer call adapters directly. JobsController was refactored to event-driven use cases (Create, Rename, Archive, Delete). Clean separation: Controller → UseCase → Manager + EventBus → Handler → Orchestrator.

### 2.3 Event Schema (Event Contracts)

**Location:** `Cambium/Cambium/event-schema/`

Declarative event definitions:

- Event names and payload shapes (DTOs) in `Cambium.EventSchema.Contracts`
- Contains NO business logic — purely declarative
- Events are versioned when payloads change
- **Known violation:** `Bridge/` types within event schema are mutable classes with logic (should be declarative-only)
- Currently underutilized — many cross-module triggers are still imperative rather than event-driven

### 2.4 Middleware (Guardrails)

**Location:** `Cambium/Cambium/middleware/`

Protective outer layer providing:

- Input validation and boundary checks
- Error handling and logging
- CLI tools and sync utilities (Cambium.Middleware.SyncCli, Cambium.Middleware.SyncClient)
- Does NOT redefine domain rules

### 2.5 UI (Presentation)

**Locations:** `Cambium/Cambium/src/Cambium.Api/wwwroot/`, `Cambium/Cambium/clients/`

**Frontend Clients (8 + shared lib):**

| Client | Uses Shared Lib | Own Axios | Status |
|--------|----------------|-----------|--------|
| app | Yes | No | Active |
| laminate-inventory | Yes | Yes | **PRODUCTION** |
| admin | No | Yes | Active |
| document-creator | Yes | Yes | Active |
| purchasing-ledger | No | Yes | Active |
| compliance-audit | No | No | Active |
| quick-reference | Yes | No | Active |
| workflow-builder | No | Yes | Active |
| shared | — | — | Library (not a client) |

**Note:** `bom-manager` does NOT exist. It is a phantom reference from earlier documentation. Remove all references.

UI and presentation layer:

- React SPAs: Workflow Builder, Document Creator, Laminate Inventory, Purchasing Ledger, Compliance Audit, Quick Reference
- Vanilla JavaScript for administrative interfaces (BottaERisposta / admin)
- No domain logic (purely representational)
- Interact through API endpoints or adapters

## 3. Technology Stack

### 3.1 Backend

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Runtime | .NET SDK | 8.0 / 10.0 (Courier) | C# execution |
| Web Framework | ASP.NET Core | 8.0 | REST API, SignalR |
| ORM | Entity Framework Core | 8.0 (pinned 8.0.11 in 5 projects; resolves 8.0.24) | Database access |
| Database | PostgreSQL | 17 (shop + Pi), 14+ (Railway) | Persistence |
| Logging | Serilog | — | Structured logging |
| Authentication | JWT Bearer + Cookie (Smart PolicyScheme) | 8.0 | Dual API security |
| PostgreSQL Driver | Npgsql | 9.0.2 | PostgreSQL connectivity |
| Password Hashing | BCrypt.Net-Next | 4.0.3 | Authentication |

**Known issue:** EF Core version conflict — 5 projects pin 8.0.11 while the solution resolves 8.0.24. This causes 22 MSB3277 warnings. Fix tracked as Action 8-9 in remediation plan. `Directory.Build.props` with `TreatWarningsAsErrors` has been committed.

**Other NuGet packages in use** (versions verifiable only when submodule is initialized):

- DocumentFormat.OpenXml — Office document generation
- EPPlus — Excel manipulation
- MailKit — Email
- Dapper — Complex query ORM

### 3.2 Frontend

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Runtime | Node.js | 20+ LTS | JavaScript execution |
| Framework | React | 19 | UI framework |
| Language | TypeScript | 5.9+ | Type safety |
| Build Tool | Vite | 7 | Fast bundling |
| State Management | Zustand | — | Application state |
| Visual Flows | React Flow | — | Node/edge diagrams |
| Testing | Vitest | — | Unit tests |

### 3.3 AutoCAD Integration (Luxify)

| Component | Version | Purpose |
|-----------|---------|---------|
| AutoCAD | 2022–2026 | Target platform |
| .NET Framework | 4.8 | Plugin language (net48, NOT .NET 8) |
| WPF | — | Palette UI |
| CommunityToolkit.Mvvm | — | MVVM pattern |
| Named Pipes | `\\.\pipe\LuxifyCommandBridge` | AutoCAD ↔ API bridge |
| System.Text.Json | 8.0.5 | JSON serialization |
| Newtonsoft.Json | 13.0.3 | JSON serialization (legacy) |

**Critical:** AutoCAD 2022-2025 uses .NET Framework 4.8, not .NET Core/.NET 8. Set `Private=false` for AutoCAD DLL references.

**Luxify Plugin Structure:**
- `Luxify.Layout` — Main DLL
- `Luxify.Badging` — Smart Badge system
- `Luxify.Legends` — Legend generation
- `Luxify.Core` — Shared utilities

**Deployment:** `C:\ProgramData\Autodesk\ApplicationPlugins\Luxify.bundle\Contents\`

### 3.4 Infrastructure (3-Environment Architecture)

| Environment | Host | Purpose | Database |
|-------------|------|---------|----------|
| **Shop (DEJAVARA)** | Windows 11, 192.168.0.108 | Source of truth, offline-capable | PG 17 (5432), PG 16 legacy (5433) |
| **Phteah-Pi** | Raspberry Pi 5, 192.168.1.76 | Home replica | PG 17 (5432) |
| **Railway** | Cloud auto-deploy from main | Convenience replica for remote access | PG at trolley.proxy.rlwy.net:44567 |

**Principle:** Shop server is authoritative. It must operate offline. Railway is a convenience replica — never treat it as the source of truth.

| Component | Purpose | Port |
|-----------|---------|------|
| Cambium.Api | REST API + SignalR | 5001 |
| PostgreSQL 17 | Database | 5432 |
| PostgreSQL 16 (legacy) | shop_chat only, DEJAVARA only | 5433 |
| Workflow Builder | React dev server | 5174 |
| Document Creator | React dev server | 5175 |
| Document Staging | React dev server | 5176 |
| Mock Sync Server | Dev testing | 5050 |
| Cloudflare Tunnel | api.luxifyspecgen.com → localhost:5001 | — |
| WireGuard VPN | DEJAVARA ↔ Pi connectivity | 51820 |

## 4. Project Structure

```
c:\dev\dejavara\cambium\
├── CLAUDE.md                           # AI context (READ FIRST)
├── CLAUDE-ARCHITECTURE.md              # Architecture specification
├── CLAUDE-BUILD-DEPLOY.md              # Build & deployment
├── CLAUDE-API.md                       # API reference
├── CLAUDE-TROUBLESHOOTING.md           # Diagnostics
├── CLAUDE-QUICK-REF.md                 # Command index
├── Root.sln                            # Solution file
│
├── docs/                               # Documentation
│   ├── adr/                           # Architecture Decision Records
│   ├── standards/                     # Development standards
│   ├── specs/                         # Feature specifications
│   ├── runbooks/                      # Operational runbooks
│   │   └── RAILWAY-DR-RUNBOOK.md      # Railway disaster recovery
│   └── TECH-STACK.md                  # Technology inventory
│
├── scripts/                            # Operational scripts
│   ├── check-railway-schema.sql       # Pre-push schema validation
│   └── backup-railway.ps1             # Railway backup
│
├── foundational documents/             # Domain standards
│   └── standards/                     # V7.1.1 documentation standards
│
├── Cambium/                            # Core platform
│   ├── Cambium.sln                    # Main solution
│   ├── src/
│   │   ├── Cambium.Api/               # ASP.NET Core REST API
│   │   │   ├── Controllers/           # REST endpoints
│   │   │   ├── Hubs/                  # SignalR real-time
│   │   │   └── wwwroot/              # Static files + SPA builds
│   │   ├── Cambium.Core/              # Business logic, managers
│   │   │   ├── Managers/             # I*Manager interfaces
│   │   │   └── Services/             # AI, validation, etc.
│   │   ├── Cambium.Data/              # EF Core DbContext, repos
│   │   ├── Cambium.Shared/            # DTOs, Enums, Interfaces
│   │   ├── Cambium.DocumentManagement/ # Document services
│   │   │   └── Modules/              # 4 .module.md files
│   │   └── BottaERisposta.Api/        # Legacy messaging API
│   │
│   ├── clients/                       # React frontends (8 + shared)
│   │   ├── app/                       # Main SPA
│   │   ├── laminate-inventory/        # PRODUCTION system
│   │   ├── admin/                     # Admin interface
│   │   ├── document-creator/          # Document generation
│   │   ├── purchasing-ledger/         # Purchasing tracking
│   │   ├── compliance-audit/          # Compliance checks
│   │   ├── quick-reference/           # Quick reference tool
│   │   ├── workflow-builder/          # Visual workflow editor
│   │   └── shared/                    # Shared components/styles
│   │
│   ├── modules/                       # 20 isolated domain modules
│   ├── adapters/                      # 8 cross-module bridges
│   │   └── ORCHESTRATOR.md           # Adapter orchestration docs
│   ├── event-schema/                  # Event contracts
│   ├── middleware/                     # Guardrails, CLI tools
│   └── tests/                         # Unit tests (167 passing)
│
├── AutoCAD-Tools/                     # Luxify plugin (submodule)
│   └── Luxify/
│       ├── Luxify.Layout/
│       ├── Luxify.Badging/
│       ├── Luxify.Legends/
│       └── Luxify.Core/
│
└── BottaERisposta/                    # Alternative deployment target
```

**Layer Dependencies (downward only):**
```
Cambium.Api (Controllers, Hubs)
    ↓
Cambium.Core (Domain logic, Managers, Services)
    ↓
Cambium.Data (EF Core DbContext, Repositories)
    ↓
Cambium.Shared (DTOs, Interfaces)
```

## 5. Database Schema Summary

### Verified Counts

| Item | Count | Notes |
|------|-------|-------|
| Migrations | 117 | Date range 2025-12-23 → 2026-03-04 |
| DbSets | 182 total (91 unique types) | Multiple aliases for same types |
| Railway tables present | 109 | Deployed and queryable |
| Railway tables missing | 55 | Unshipped features — safe if no code queries them |

### Railway Schema Drift (CRITICAL)

55 tables exist as EF entity classes but have NO corresponding Railway tables. Any endpoint querying these will 500 on Railway.

**High-risk missing groups:**
- GIS Specifications (9 tables)
- Cutting/Ardis workflow (4 tables)
- Purchasing (6 tables)
- Drawings subsystem (5 tables)
- FO extensions: `fo_parts`, `fo_checkpoints`, `fo_status_history`, `fo_sequences`, `project_factory_orders`, `projects` — **MEDIUM RISK** — FO module is active

**Pre-push safety:** Always run `scripts/check-railway-schema.sql` before `git push origin main`.

### Migration Pattern (No MigrateAsync)

Cambium deliberately does NOT use `MigrateAsync()`. Earlier versions caused destructive schema recreation on Railway. Migrations are tracked in `__EFMigrationsHistory` but NEVER auto-applied. Apply via SQL scripts or ALTER TABLE self-healing.

### Self-Healing Startup

Program.cs contains a self-healing startup block (lines 622-674) that ensures auth-critical columns exist on the `users` table. Individual try/catch per ALTER — one failure doesn't skip the rest.

### Core Entity Groups

**Job Management:**
Jobs, FactoryOrders, FoParts, FoCheckpoints, FoStatusHistory, FoSequences, Projects, ProjectRooms, ProjectSheets, ProjectContacts, ProjectFactoryOrders

**Chat System:**
Messages, Subcategories, IndividualChats

**Materials & Specifications:**
Materials, MaterialCategories, Hardware, HardwareCategories, Finishes, MillworkFinishes, JobSpecifications

**Badge System:**
BadgeCategories, JobBadges, RoomBadges, BadgeSpecHistory, BadgeDrawings

**Millwork Hierarchy:**
MillworkItems (cabinets/components), ItemMaterials, ItemHardware, ItemFinishes, JobFloors, JobZones, JobRooms, JobAreas, JobWalls, JobCeilings

**Directory/Contacts:**
Organizations, DirectoryContacts, JobOrganizationLinks, JobContactLinks

**Operations:**
SiteVisits, SitePhotos, SiteMeasurements, InstallationSchedules, InstallationChecklists, QualityInspections, Samples, SampleStatusHistory, Mockups

**Contract Documents:**
ContractDocumentTypes, ContractDocumentTypeAliases, ContractDocuments, DocumentRevisionLinks, DiscoveredFiles

**Drawing Management:**
Drawings, DrawingMaterials, DrawingRevisions, DrawingSeries, DrawingSets, DrawingSetItems, JobDrawingProperties, RoomDrawings, DrawingCheckouts

**Inventory:**
Laminate inventory entities (stock levels, transactions)

**Courier:**
Addresses, CourierContacts, Shipments

**Users & Auth:**
Users (with auth-critical columns: `failed_login_attempts`, `lockout_until`, `must_change_password`, `user_type`, `last_login_at`, `last_seen`), DataProtectionKeys

## 6. API Surface

### Key Controllers

| Controller | Purpose |
|------------|---------|
| JobsController | Job CRUD, status management (event-driven use cases) |
| FactoryOrdersController | Factory order management |
| BadgesController | Badge management |
| LaminatesController | Laminate inventory (PRODUCTION) |
| DirectoryController | Organization/contact directory |
| DocumentsController | Document generation, storage |
| ContractController | Contract management |
| CourierController | Email, shipments, addresses |
| AutoCadController | AutoCAD integration, command bridge |
| DrawingsController | Drawing CRUD |
| DrawingCheckoutController | Drawing checkout workflow |
| WorkflowsController | Workflow definitions |
| StagingController | Staging environment |
| AuthController | Authentication (dual JWT/Cookie) |
| SpecificationsController | Specification management |
| SamplesController | Sample tracking |

### Authentication (Smart PolicyScheme)

Cambium uses a "Smart" PolicyScheme that selects JWT or Cookie based on the request's Authorization header:

```csharp
builder.Services.AddAuthentication("Smart")
    .AddPolicyScheme("Smart", "Smart", options =>
    {
        options.ForwardDefaultSelector = context =>
        {
            var header = context.Request.Headers[HeaderNames.Authorization].ToString();
            return header.StartsWith("Bearer ")
                 ? JwtBearerDefaults.AuthenticationScheme
                 : CookieAuthenticationDefaults.AuthenticationScheme;
        };
    });
```

Cookie name: `Cambium.Auth`, 30-day sliding expiration, `OnRedirectToLogin` returns 401 (not 302 redirect).

### REST Endpoints (64+)

```
# Jobs
GET    /api/jobs                    # List jobs
GET    /api/jobs/{id}               # Get job
POST   /api/jobs                    # Create job

# Factory Orders
GET    /api/factoryorders           # List FOs
GET    /api/factoryorders/{id}      # Get FO
POST   /api/factoryorders           # Create FO

# Badges
GET    /api/badges/{code}           # Get badge spec
POST   /api/badges/refresh          # Sync badges

# Messages
GET    /api/messages                # List messages
POST   /api/messages                # Send message

# Laminates (PRODUCTION)
GET    /api/laminates               # List inventory
POST   /api/laminates/transactions  # Record movement

# AutoCAD Bridge
GET    /api/autocad/bridge/status   # Bridge status
POST   /api/autocad/bridge/connect  # Establish connection

# Health
GET    /api/health                  # Health check
```

### SignalR Hub

```csharp
// StagingHub — Real-time notifications
public class StagingHub : Hub
{
    public async Task JoinJobChannel(string jobNumber);
    public async Task LeaveJobChannel(string jobNumber);
}

// Client events
Clients.Group(jobNumber).SendAsync("MessageReceived", message);
Clients.Group(jobNumber).SendAsync("StagingUpdated", item);
Clients.All.SendAsync("FactoryOrderCreated", fo);
```

## 7. Build & Run Commands

```powershell
# Cambium API (development)
cd Cambium/Cambium/src/Cambium.Api
dotnet run

# Laminate Inventory (PRODUCTION - verify before/after changes)
cd Cambium/Cambium/clients/laminate-inventory
npm run verify

# React client development
cd Cambium/Cambium/clients/workflow-builder
npm install && npm run dev

# Database migrations (generate SQL, NEVER auto-apply)
dotnet ef migrations script \
  --project Cambium/Cambium/src/Cambium.Data \
  --startup-project Cambium/Cambium/src/Cambium.Api \
  --output migration.sql

# AutoCAD Tools build + deploy (CLOSE AUTOCAD FIRST)
powershell -NoProfile -ExecutionPolicy Bypass -File "AutoCAD-Tools\BUILD_AND_DEPLOY.ps1"

# Windows Service management (requires admin)
sc query CambiumApi
net stop CambiumApi && net start CambiumApi

# Full verification (backend + frontend)
cd Cambium && dotnet test tests/Cambium.Tests.Unit && cd clients/laminate-inventory && npm run verify

# Pre-push schema check (before git push origin main)
psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql
```

### Deploy Procedure (Shop Server — No CI/CD)

Shop server has no CI/CD (deliberate — must work offline).

**API updates:**
1. `dotnet publish Cambium/src/Cambium.Api -c Release -o publish/`
2. `net stop CambiumApi` (admin required)
3. Copy publish output to `C:\dev\cambium\BottaERisposta\publish\`
4. `net start CambiumApi`

**Frontend updates:**
1. `cd Cambium/clients/{name} && npm run build`
2. Output goes to `Cambium/src/Cambium.Api/wwwroot/{name}/`
3. Copy to service: `wwwroot/{name}/* → BottaERisposta/publish/wwwroot/{name}/`
4. No service restart needed for static files

## 8. Domain Terminology

| Term | Definition |
|------|------------|
| **Factory Order (FO)** | Atomic unit of manufacturing — bundle of work for the shop floor |
| **Job** | Customer project managing all aspects |
| **Room** | Area within a project (living room, kitchen, etc.) |
| **Badge** | Shop floor identifier linking specs to physical materials |
| **Specification** | Material definition with provenance/availability flags |
| **Provenance Flag** | Permission-to-proceed gate (sample approved?) |
| **Availability Flag** | Physical-reality gate (in stock? on order?) |
| **Shop Channel** | Real-time communication group per job |
| **SSOT** | Single Source of Truth (Excel driving outputs) |

### Badge Categories

| Category | Purpose | Badge Shape |
|----------|---------|-------------|
| FINISH | Surface materials | Ellipse |
| FIXTURE | Built items, hardware | Diamond |
| EQUIPMENT | Appliances, electrical | Rectangle |
| BUYOUT | Subcontracted items | 8-Point Star |
| PROVENANCE | Authorization tracking | Triangle |

### Hierarchies

**Job Hierarchy:**
```
Job (Netflix, Dentons, ESDC)
└── Project (Billable deliverable)
    └── Factory Order (Manufacturing unit)
        └── FO Part (Line items)
```

**Location Hierarchy:**
```
Zone/Wing
└── Room
    └── Area
        ├── Wall
        └── Ceiling
```

**Build Hierarchy:**
```
Item (Credenza, Reception Desk)
└── Assembly (Upper Cabinet, Drawer Bank)
    └── Component (Drawer Box)
        └── Part (Side Panel, Drawer Bottom)
```

## 9. Key Architectural Constraints

### No Cross-Module Imports

```csharp
// ❌ WRONG — Direct import from another module
using Cambium.Module.Jobs;

// ✅ CORRECT — Use adapter or event-driven communication
var job = await jobToChatAdapter.GetJobAsync(jobId);
```

### Domain Logic Stays in Modules

- Adapters orchestrate, never contain business rules
- Event schema defines events declaratively, no handlers
- Middleware validates input at boundaries

### Event-Driven Adapter Invocation (Post 2026-02-16)

```csharp
// ✅ CORRECT — Event-driven flow
Controller → UseCase → Manager + EventBus → Handler → Orchestrator/Adapter

// ❌ WRONG — Direct adapter calls from controllers
Controller → Adapter.OnSomethingAsync()
```

### Database: PostgreSQL ONLY

```sql
-- ✅ PostgreSQL syntax
POSITION('x' IN col)
SUBSTRING(col FROM start FOR length)
col1 || col2  -- string concat
TRUE / FALSE  -- booleans

-- ❌ SQL Server syntax (DO NOT USE)
CHARINDEX('x', col)
SUBSTRING(col, start, length)
col1 + col2
1 / 0
```

### Validation Checklist

Before marking any feature complete:

- [ ] `dotnet build` compiles with 0 errors
- [ ] No cross-module imports introduced
- [ ] New public APIs documented
- [ ] API tested (happy path + error case)
- [ ] Database state verified
- [ ] Laminate Inventory: `npm run verify` passes
- [ ] Pre-push: `scripts/check-railway-schema.sql` passes (if schema changed)

## 10. Production Systems (DO NOT BREAK)

| System | Location | Verify Command | Status |
|--------|----------|----------------|--------|
| Laminate Inventory | `Cambium/Cambium/clients/laminate-inventory/` | `npm run verify` | **LIVE on shop floor** |
| AutoCAD Tools (Luxify) | `AutoCAD-Tools/Luxify/` | Close AutoCAD → `BUILD_AND_DEPLOY.ps1` | Active |
| Cambium API | `Cambium/Cambium/src/Cambium.Api/` | Windows Service `CambiumApi` | Active |

**CRITICAL:** Laminate Inventory is actively used on the shop floor. Always run tests before AND after changes.

## 11. Critical Gotchas

### AutoCAD DLL Locking
AutoCAD locks DLLs while running. Always close AutoCAD before building.

### Development vs. Service
Two API instances can run:
- **Development:** `dotnet run` (port 5001)
- **Windows Service:** CambiumApi (port 5001)
- Check which is running: `netstat -ano | findstr :5001`

### Sheet Numbering
Sheet numbers are GLOBAL across all layouts in a job, not per-layout.

### BottaERisposta UI
NEVER use inline styles — use CSS classes only. Inline styles break dark theme (dropdown options become invisible).

### EF Core Column-Drift
EF Core generates SELECT with ALL mapped columns. One missing column = entire query fails (PostgreSQL 42703). This kills every endpoint that queries that entity — not just the one that needs the column.

### Railway DATABASE_URL
Must be `${{Postgres.DATABASE_URL}}` (a Variable Reference), never a hardcoded connection string. Password rotates — use dashboard if auth fails.

### BCrypt Hashes
BCrypt hashes contain `$` characters. Use `.sql` files with `psql -f`, not inline bash.

### DataProtection Keys
Must be persisted to database. Missing `DataProtectionKeys` table means all cookies invalidate on restart — silent login failure for all users.

## 12. Build Status

- Pre-push git hook runs `dotnet build` in Release mode
- Zero-warnings policy: enforced via `Directory.Build.props` (`TreatWarningsAsErrors=true`)
- 167 tests pass
- **Known:** 22 MSB3277 warnings from EF Core version conflict (8.0.11 vs 8.0.24 across 5 projects) — fix tracked as remediation Action 8-9

## 13. Known Violations & Architectural Debt

- **Unqualified property names** across entity files (`Code`, `Status`, `Type`, `Name`, `Number`) — bulk rename is Action 12 in remediation plan
- **Event schema `Bridge/` types:** mutable classes with logic (violates declarative-only pattern)
- **Missing application/use-case layer:** Jobs domain has use cases; Badges, Chat, other domains still need extraction
- **Event-driven orchestration incomplete:** Many cross-module triggers remain imperative (direct calls)
- **`Cambium.Shared` growing:** Risk of becoming grab-bag; should separate contract interfaces (adapters) from DTOs (API)
- **Module migration incomplete:** Chat, Jobs, Badges features still in `src/Cambium.Core`, not yet migrated to formal modules

## 14. Key Files for Reference

| File | Purpose |
|------|---------|
| `CLAUDE.md` | AI context (MANDATORY READ) |
| `CLAUDE-ARCHITECTURE.md` | Architecture specification |
| `CLAUDE-BUILD-DEPLOY.md` | Build & deployment guide |
| `CLAUDE-API.md` | API reference |
| `CLAUDE-TROUBLESHOOTING.md` | Diagnostics guide |
| `Cambium/src/Cambium.Data/DbContext/CambiumDbContext.cs` | Database schema |
| `Cambium/src/Cambium.Api/Program.cs` | App startup, self-healing, auth |
| `Cambium/src/Cambium.Api/Controllers/AuthController.cs` | Login flow, JWT generation |
| `adapters/ORCHESTRATOR.md` | Adapter orchestration docs |
| `scripts/check-railway-schema.sql` | Pre-push schema validation |
| `docs/runbooks/RAILWAY-DR-RUNBOOK.md` | Railway disaster recovery |

---

*Cambium — Feature Millwork's Automation Platform*
*Built on Hexagonal Architecture for Sustainable Growth*
