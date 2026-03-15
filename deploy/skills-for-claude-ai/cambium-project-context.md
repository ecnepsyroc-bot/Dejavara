# Cambium — Project Context

> Feature Millwork's Unified Automation Platform
> For use in Claude AI Projects — sourced 2026-03-15
> Verification basis: skill files, audit reports (2026-02-16, 2026-03-11), git history, plan artifacts. Submodule source was not directly accessible; items marked [FROM DOCS] where code-level verification was not possible.

## 1. What Cambium Is

Cambium is a C# platform that automates shop floor communication, drawing production, and job management for Feature Millwork, a 26-person custom millwork manufacturer in Coquitlam, BC. Today it runs real-time messaging (Botta e Risposta), laminate inventory tracking (live on the shop floor), a purchasing ledger, AutoCAD drawing automation via the Luxify plugin, and badge-based specification management. It manages 30+ concurrent projects across factory orders, site installations, and quality control.

## 2. Core Philosophy

- **"Humans decide. Systems prepare."** — AI translates intent, humans maintain authority.
- **"Ship one reflex at a time."** — Deliver incremental value, not complete systems.
- **"100 clicks → 3 clicks"** — Measure success by automation reduction.
- **"Architecture is enforcement, not suggestion."** — Boundaries must be mechanical.
- **"Paper follows data."** — Documents generated from events, never re-keyed.

## 3. Architecture

Cambium follows hexagonal architecture: self-contained **modules** communicate only through **adapters**. No module imports from another module — ever.

```
Module A ──event──► Adapter ──command──► Module B
```

**Layer dependencies (downward only):**
```
Cambium.Api (Controllers, Hubs)  →  Cambium.Core (Managers, Services)
  →  Cambium.Data (EF Core, Repositories)  →  Cambium.Shared (DTOs, Interfaces)
```

**Enforcement examples:**
```csharp
// ❌ WRONG — direct cross-module import
using Cambium.Module.Jobs;

// ✅ CORRECT — communicate through adapter
var job = await jobToChatAdapter.GetJobAsync(jobId);
```

Controllers do not call adapters directly. After a 2026-02-16 refactor, JobsController uses event-driven use cases: Controller → UseCase → Manager + EventBus → Handler → Orchestrator. Other domains (Badges, Chat) still call managers directly from controllers — that migration is ongoing.

The event schema (`Cambium.EventSchema.Contracts`) defines event payloads declaratively but is underutilized. Many cross-module triggers remain imperative. Known violation: `Bridge/` types in event-schema contain mutable classes with logic.

## 4. Production Systems (DO NOT BREAK)

| System | What It Does | Verify Command | Notes |
|--------|-------------|----------------|-------|
| **Laminate Inventory** | Shop floor inventory tracking | `cd clients/laminate-inventory && npm run verify` | React 19, TypeScript. Live on shop floor via QR codes at workstations |
| **Purchasing Ledger** | Purchasing workflow tracking | [FROM DOCS] launched 2026-03-09 | React client at `clients/purchasing-ledger/` |
| **Cambium API** | REST + SignalR on port 5001 | `sc query CambiumApi` or `netstat -ano \| findstr :5001` | Windows Service on DEJAVARA (shop server) |
| **Luxify (AutoCAD)** | Badge placement, legends, title blocks | Close AutoCAD → `BUILD_AND_DEPLOY.ps1` | .NET Framework 4.8 plugin, DLLs lock while AutoCAD runs |
| **Cloudflare Tunnel** | Remote access: api.luxifyspecgen.com → localhost:5001 | Check dashboard | cloudflared runs as Windows service |

## 5. Modules by Status

Location: `Cambium/Cambium/modules/` — 20 directories per skill audit (2026-03-05). No modules have `.module.md` files. 4 `.module.md` files exist in `Cambium.DocumentManagement/Modules/` (Drawings, ExternalRefs, Projects, Submittals).

### Production

| Module | Responsibility | Key Evidence |
|--------|---------------|-------------|
| Cambium.Module.Inventory | Laminate inventory tracking | React client in production, dedicated controller, real transactions daily |
| Cambium.Module.Chat | Real-time messaging (Botta e Risposta) | SignalR hub, active daily use, ChatRepository confirmed in audit |
| Cambium.Module.Badges | Badge management and specification tracking | BadgesController with 5+ injected services, Luxify integration |
| Cambium.Module.Staging | Pre-production staging environment | StagingHub (SignalR), StagingController, active use |
| Cambium.Module.Production | Production workflows | Referenced as Active in all audits |

### Functional (built, not fully adopted)

| Module | Responsibility | Evidence |
|--------|---------------|---------|
| Cambium.Module.Jobs | Job CRUD, factory orders, status transitions | Event-driven use cases (Create, Rename, Archive, Delete) — refactored 2026-02-16 |
| Cambium.Module.Purchasing | Purchasing workflows | Purchasing Ledger client launched 2026-03-09, submodule ref updated |
| Cambium.Module.Documents | Document storage/generation | DocumentsController exists, Cambium.DocumentManagement has 4 .module.md files |
| Cambium.Module.DrawingCheckout | Drawing checkout workflow | dotnet build covers this project (confirmed 2026-03-11 audit) |
| Cambium.Module.Specifications | Specification data management | submodule ref commit references "specifications" feature work |
| Cambium.Module.Samples | Sample tracking and approval | SamplesController exists per skill docs |
| Cambium.Courier | Email/shipment routing | .NET 10 module, CourierController referenced |

### Skeleton / In Progress

Cambium.Module.Bom — Bill of materials. Cambium.Module.Courier — Module-level courier (separate from Cambium.Courier). Cambium.Module.Directory — Organization/contact directory. Cambium.Module.Locations — Location/spatial data. Cambium.Module.Workflow — Workflow state machines. Cambium.PdfLibrary — PDF generation. Cambium.Sheets — Sheet generation. Cambium.Workflow — Stub only.

## 6. Clients by Status

Location: `Cambium/Cambium/clients/` — 8 clients + 1 shared library. `bom-manager` does NOT exist (phantom reference from old docs — remove all references).

### Production

| Client | Dependencies | Notes |
|--------|-------------|-------|
| laminate-inventory | React 19, TypeScript, Vite 7, shared lib, own axios | Live on shop floor |
| purchasing-ledger | [FROM DOCS] own axios | Launched 2026-03-09 |

### Functional

| Client | Notes |
|--------|-------|
| app | Main SPA, uses shared lib |
| admin | Admin interface, own axios |
| document-creator | Document generation, uses shared lib + own axios |
| workflow-builder | Visual workflow editor (React Flow, Zustand), own axios |
| compliance-audit | Compliance checks |
| quick-reference | Quick reference tool, uses shared lib |

### Shared Library

`shared/` — Shared components and styles consumed by app, laminate-inventory, document-creator, quick-reference.

## 7. Adapters

Location: `Cambium/Cambium/adapters/` — 8 adapters, 11 `.adapter.md` files, plus `ORCHESTRATOR.md`.

### Active (code runs in production flows)

| Adapter | Connects | Purpose |
|---------|----------|---------|
| SpecToAutoCAD | Specifications → AutoCAD | Intentional cross-context read (documented exception) |
| SpecToMaster | Specifications → AutoCAD masters | Badge specs to drawing templates via named pipe |
| FlagToOverlay | Spec flags → AutoCAD overlays | Provenance/availability visual indicators |
| JobToChat | Jobs → Chat | Job lifecycle broadcasts (event-driven post-refactor) |
| DrawingCheckoutToChat | DrawingCheckout → Chat | Drawing change notifications |
| StagingToProduction | Staging → Production | Promotes staging data |

### Wired but unverified

MasterToSheet (placeholder — masters to sheet generation), SheetToPdf (placeholder — sheets to PDF output).

## 8. Tech Stack

### Backend (from skill files, corroborated by audit build output)

| Component | Version | Confidence |
|-----------|---------|------------|
| .NET SDK | 8.0 (primary), 10.0 (Courier module) | High — confirmed in skills, build passes |
| ASP.NET Core | 8.0 | High — REST API + SignalR |
| Entity Framework Core | 8.0 (pinned 8.0.11 in 5 projects; resolves 8.0.24) | High — version conflict causes 22 MSB3277 warnings |
| PostgreSQL | 17 (shop + Pi), 14+ (Railway) | High — hosting skill |
| Npgsql | 9.0.2 | High — explicit in skills |
| Serilog | — | Medium — referenced but version unconfirmed |
| BCrypt.Net-Next | 4.0.3 | [FROM DOCS] |

### Frontend (from skill files)

| Component | Version | Confidence |
|-----------|---------|------------|
| React | 19 | High — all clients |
| TypeScript | 5.9+ | High |
| Vite | 7 | High |
| Zustand | — | Medium — workflow-builder state management |
| React Flow | — | Medium — workflow-builder visual editor |
| Vitest | — | Medium — laminate-inventory tests |

### AutoCAD Plugin (Luxify)

.NET Framework 4.8 targeting AutoCAD 2022–2026. WPF palette UI. System.Text.Json 8.0.5, Newtonsoft.Json 13.0.3, CommunityToolkit.Mvvm. Named pipe IPC: `\\.\pipe\LuxifyCommandBridge`. Deployed to `C:\ProgramData\Autodesk\ApplicationPlugins\Luxify.bundle\Contents\`.

### Infrastructure

Three environments. Shop server (DEJAVARA) is the source of truth and must work offline.

| Environment | Host | Database | Purpose |
|-------------|------|----------|---------|
| **Shop (DEJAVARA)** | Windows 11, 192.168.0.108 | PG 17 (5432), PG 16 legacy (5433) | Authoritative source |
| **Phteah-Pi** | Raspberry Pi 5, 192.168.1.76 | PG 17 (5432) | Home replica via SyncCli (every 20 min) |
| **Railway** | Cloud auto-deploy from `main` | trolley.proxy.rlwy.net:44567 | Remote access convenience replica |

Key ports: 5001 (API), 5432 (PG), 5174 (Workflow Builder dev), 5175 (Document Creator dev), 5176 (Document Staging dev), 5050 (Mock Sync dev), 51820 (WireGuard VPN).

Cloudflare tunnel: api.luxifyspecgen.com → localhost:5001. WireGuard VPN: 10.8.0.0/24 subnet.

## 9. Database Summary

[FROM DOCS — based on skill file verified counts, not direct CambiumDbContext.cs inspection]

- **182 DbSet registrations** mapping to **91 unique entity types**
- **117 migrations** (2025-12-23 to 2026-03-04)
- **109 tables deployed on Railway**, **55 missing** (unshipped features — expected)

Entity groups by domain: Jobs & Factory Orders (11 entities), Messaging (3), Badges & Specifications (5), Millwork Hierarchy (6), Directory/Contacts (4), Operations (9), Contract Documents (5), Drawing Management (8), Inventory (laminate entities), Courier (3), Users & Auth (2+ with DataProtectionKeys).

**Critical: Railway schema drift.** 55 EF entity classes have no Railway tables. Any endpoint querying these will 500. High-risk missing: GIS Specifications (9), Cutting/Ardis (4), Purchasing (6), Drawings (5), FO extensions (6).

**Migration pattern:** Cambium does NOT use `MigrateAsync()`. Previous use caused destructive schema recreation on Railway. Apply manually via SQL scripts or self-healing ALTER TABLE blocks in Program.cs.

## 10. API Surface

[FROM DOCS — 64 endpoints total per skill audit]

**Production-tier controllers:** LaminatesController, BadgesController (5+ injected services including IHybridAiService, ICommandBridgeClient), AuthController (dual JWT/Cookie via "Smart" PolicyScheme, login at lines 40-190, JWT generation at lines 1226-1256).

**Functional controllers:** JobsController (event-driven use cases), FactoryOrdersController, DirectoryController, DocumentsController, ContractController, CourierController, DrawingsController, DrawingCheckoutController, StagingController, SpecificationsController, SamplesController, AutoCadController (command bridge), WorkflowsController.

**SignalR:** StagingHub with JoinJobChannel/LeaveJobChannel. Client events: MessageReceived, StagingUpdated, FactoryOrderCreated.

**Authentication:** "Smart" PolicyScheme auto-selects JWT (Bearer header) or Cookie (`Cambium.Auth`, 30-day sliding, HttpOnly). OnRedirectToLogin returns 401 not 302. DataProtection keys persisted to DB — missing table = silent session invalidation.

## 11. Build & Verify Commands

```powershell
# API (development)
cd Cambium/Cambium/src/Cambium.Api && dotnet run

# Full backend build (confirmed passes ~10.7s, 2026-03-11 audit)
dotnet build

# Laminate Inventory verification (PRODUCTION)
cd Cambium/Cambium/clients/laminate-inventory && npm run verify

# Backend tests (167 passing per audit)
cd Cambium && dotnet test tests/Cambium.Tests.Unit

# Pre-push Railway schema check
psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql

# AutoCAD Tools (CLOSE AUTOCAD FIRST)
cd AutoCAD-Tools && .\BUILD_AND_DEPLOY.ps1

# Windows Service
sc query CambiumApi
net stop CambiumApi && net start CambiumApi  # requires admin

# Manual deploy (no CI/CD — deliberate for offline capability)
dotnet publish Cambium/src/Cambium.Api -c Release -o publish/
# Copy to C:\dev\cambium\BottaERisposta\publish\, restart service
```

## 12. Domain Terminology

**Factory Order (FO)** — atomic unit of manufacturing, a bundle of shop floor work. **Job** — customer project (Netflix, Dentons, ESDC). **Badge** — shop floor identifier linking specifications to physical materials; shapes encode category (Ellipse=FINISH, Diamond=FIXTURE, Rectangle=EQUIPMENT, 8-Point Star=BUYOUT, Triangle=PROVENANCE). **Specification** — material definition with two gates: **Provenance Flag** (permission: sample approved?) and **Availability Flag** (reality: in stock?). **SSOT** — Single Source of Truth, Excel driving outputs.

**Hierarchies:** Job → Project → Factory Order → FO Part. Zone → Room → Area → Wall/Ceiling. Item → Assembly → Component → Part.

## 13. Architectural Constraints & Gotchas

**No cross-module imports.** Modules communicate only through adapters. Violation = mechanical enforcement failure.

**PostgreSQL only.** Use `POSITION('x' IN col)` not `CHARINDEX()`. Use `col1 || col2` not `col1 + col2`. Use `TRUE/FALSE` not `1/0`. Use `SUBSTRING(col FROM 1 FOR 5)`.

**AutoCAD DLL locking.** AutoCAD locks DLLs at runtime. Always close AutoCAD before building Luxify.

**Dev vs Service conflict.** Both `dotnet run` and Windows Service CambiumApi use port 5001. Check `netstat -ano | findstr :5001`.

**Sheet numbering.** Numbers are GLOBAL across all layouts in a job, not per-layout.

**BottaERisposta CSS.** NEVER use inline styles on form elements — breaks dark theme (dropdown options invisible). Use classes: `form-group`, `form-label`, `form-input`, `form-select`, `form-textarea`.

**EF Core column drift.** EF generates SELECT with ALL mapped columns. One missing column kills every endpoint touching that entity (PostgreSQL 42703). Self-healing startup block (Program.cs:622-674) handles auth-critical columns.

**Railway DATABASE_URL.** Must be `${{Postgres.DATABASE_URL}}` (Variable Reference), never hardcoded. Password rotates on regeneration.

**BCrypt in bash.** Hashes contain `$`. Use `.sql` files with `psql -f`, never inline bash.

**No MigrateAsync().** Removed after destructive schema recreation on Railway. Apply migrations manually.

## 14. Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | AI context — read first |
| `CLAUDE-ARCHITECTURE.md` | Hexagonal rules and enforcement |
| `CLAUDE-BUILD-DEPLOY.md` | Build and deployment procedures |
| `CLAUDE-API.md` | API reference |
| `CLAUDE-TROUBLESHOOTING.md` | Diagnostics |
| `src/Cambium.Api/Program.cs` | Startup, self-healing (622-674), auth config (201-214), admin seed (1192-1211) |
| `src/Cambium.Api/Controllers/AuthController.cs` | Login (40-190), JWT (1226-1256) |
| `src/Cambium.Data/DbContext/CambiumDbContext.cs` | All 182 DbSet registrations |
| `adapters/ORCHESTRATOR.md` | Adapter orchestration documentation |
| `scripts/check-railway-schema.sql` | Pre-push Railway validation |

## 15. Known Debt

- **22 MSB3277 warnings** from EF Core version conflict (5 projects pin 8.0.11, solution resolves 8.0.24). Fix tracked as remediation Action 8-9.
- **0 of 20 modules** have `.module.md` files in the modules directory.
- **Missing application/use-case layer** in most domains. Jobs has use cases; Badges, Chat, others still call managers directly from controllers.
- **Event-driven orchestration incomplete.** Many adapters still invoked imperatively.
- **`Cambium.Shared` scope creep.** Growing into a grab-bag — should separate contract interfaces from DTOs.
- **Module migration incomplete.** Chat, Jobs, Badges business logic still lives in `src/Cambium.Core`, not in formal modules.
- **127+ TODO/FIXME/Deprecated markers** across the codebase (2026-03-11 audit).
- **55 Railway-missing tables.** Any new endpoint querying unshipped entities will 500 on Railway without pre-deploy ALTERs.
- **`bom-manager` phantom.** Referenced in old docs but never existed. Clean up all references.
