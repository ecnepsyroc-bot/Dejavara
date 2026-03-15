# Cambium — Project Context

> Feature Millwork's Unified Automation Platform
> For use in Claude AI Projects — verified 2026-03-15
>
> **Verification basis:** Code-level recount against live source tree (2026-03-15), corroborated by audits (2026-02-22, 2026-03-11) and platform skill files (2026-03-05).

## 1. What Cambium Is

Cambium is a C# platform that automates shop floor communication, drawing production, and job management for Feature Millwork, a 26-person custom millwork manufacturer in Coquitlam, BC. Today it runs real-time messaging (Botta e Risposta), laminate inventory tracking (live on the shop floor), a purchasing ledger, AutoCAD drawing automation via the Luxify plugin, and badge-based specification management. ~390,000 lines of C# managing 30+ concurrent projects.

## 2. Core Philosophy

- **"Humans decide. Systems prepare."** — AI translates intent, humans maintain authority.
- **"Ship one reflex at a time."** — Deliver incremental value, not complete systems.
- **"100 clicks → 3 clicks"** — Measure success by automation reduction.
- **"Architecture is enforcement, not suggestion."** — Boundaries must be mechanical.
- **"Paper follows data."** — Documents generated from events, never re-keyed.

## 3. Architecture

Cambium follows hexagonal architecture with two coexisting generations of code — understanding this split is essential.

**Gen 2 (target architecture):** 21 `Cambium.Module.*` modules in `modules/` (25 total including non-module projects), communicating only through adapters. No module imports from another module. Only 2 modules (Jobs, Inventory) are fully hexagonally compliant with proper Domain/Ports/Adapters structure and use-case wiring. Badges has the folder structure but routes through Gen 1 managers. 20 of 21 `Cambium.Module.*` dirs have MODULE.md files (missing: SiteView).

**Gen 1 (legacy, dominant):** 44 concrete manager classes in `src/Cambium.Core/Managers/` that inject `CambiumDbContext` directly. ~55 controllers, most calling managers without an intermediate use-case layer. This is the code path that handles most requests today.

```
Module A ──event──► Adapter ──command──► Module B
```

**Layer dependencies (downward only):**
```
Cambium.Api (Controllers, Hubs)
  → Cambium.Core (Managers, Services)  [44 managers, Gen 1]
    → Cambium.Data (EF Core, Repos)
      → Cambium.Shared (DTOs, Interfaces)
```

**Known dependency violations:** `Cambium.Core.csproj` references `Cambium.Data.csproj` and `Cambium.Module.Chat.csproj`. `Cambium.Module.Inventory.csproj` references `Cambium.Data.csproj`. `InMemoryEventBus` (infrastructure) lives in `Cambium.Core/Events/`.

**Event-driven status:** Only 4 domain events are wired via `IEventBus`: `JobCreated`, `JobRenamed`, `JobArchived`, `JobDeleted`. 9 event contract files exist in `EventSchema.Contracts/Events/` but most are contracts-only (defined, not emitted). The event bus is in-memory, synchronous, no queuing, no retry.

**Enforcement examples:**
```csharp
// ❌ WRONG — direct cross-module import
using Cambium.Module.Jobs;

// ✅ CORRECT — communicate through adapter
var job = await jobToChatAdapter.GetJobAsync(jobId);
```

## 4. Production Systems (DO NOT BREAK)

| System | What It Does | Verify Command | Notes |
|--------|-------------|----------------|-------|
| **Laminate Inventory** | Shop floor inventory tracking | `cd clients/laminate-inventory && npm run verify` | React 19, TypeScript. Live via QR codes at workstations |
| **Purchasing Ledger** | Purchasing workflow | [UNVERIFIED] launched 2026-03-09 | React client at `clients/purchasing-ledger/` |
| **Cambium API** | REST + SignalR, port 5001 | `sc query CambiumApi` | Windows Service on DEJAVARA (shop server) |
| **Luxify (AutoCAD)** | Badge placement, legends, title blocks | Close AutoCAD → `BUILD_AND_DEPLOY.ps1` | .NET Framework 4.8, DLLs lock while running |
| **Cloudflare Tunnel** | api.luxifyspecgen.com → localhost:5001 | Dashboard | cloudflared as Windows service |

## 5. Modules by Status

25 directories under `modules/`: 21 are `Cambium.Module.*`, 4 are standalone projects (`Cambium.Courier`, `Cambium.PdfLibrary`, `Cambium.Sheets`, `Cambium.Workflow`). 20 of 21 `Cambium.Module.*` dirs have MODULE.md; the 4 standalone projects do not. `Cambium.Module.SiteView` is the only `Cambium.Module.*` missing MODULE.md.

### Production

| Module | Responsibility | Confidence |
|--------|---------------|-----------|
| Cambium.Module.Inventory | Laminate inventory tracking | Verified — React client in production, daily transactions |
| Cambium.Module.Chat | Real-time messaging (Botta e Risposta) | Verified — SignalR hub, ChatRepository, daily use |
| Cambium.Module.Badges | Badge management, spec tracking | Verified — but STRUCTURAL ONLY hex compliance (has Domain/Ports/Adapters folders; BadgeService injects CambiumDbContext directly, uses IBadgesManager Gen 1 pattern) |
| Cambium.Module.Staging | Pre-production staging | Verified — StagingHub, StagingController |
| Cambium.Module.Production | Production workflows | Skill-sourced — listed Active in all audits |

### Functional

| Module | Responsibility | Evidence |
|--------|---------------|---------|
| Cambium.Module.Jobs | Job CRUD, FOs, status | 4 use cases (Create/Rename/Archive/Delete), only module with event-driven flow |
| Cambium.Module.Purchasing | Purchasing workflows | Client launched 2026-03-09 |
| Cambium.Module.DrawingCheckout | Drawing checkout | Builds confirmed (2026-03-11 audit); has EF annotation violations |
| Cambium.Module.Specifications | Specification data | Git commits reference active feature work |
| Cambium.Module.Documents | Document storage/generation | DocumentsController exists; 4 .module.md in DocumentManagement |
| Cambium.Module.Samples | Sample tracking | SamplesController exists per skill docs |
| Cambium.Courier | Email/shipment routing | .NET 10 module |

### Skeleton / In Progress

Cambium.Module.Bom, Cambium.Module.Courier, Cambium.Module.Directory, Cambium.Module.DocumentIngestion, Cambium.Module.FileSync, Cambium.Module.LocalPathMapping, Cambium.Module.Locations, Cambium.Module.R2Storage, Cambium.Module.SiteView (no MODULE.md), Cambium.Module.Workflow, Cambium.PdfLibrary, Cambium.Sheets, Cambium.Workflow (stub).

## 6. Clients by Status

Location: `Cambium/Cambium/clients/` — 8 client directories + 1 shared library (per Mar 5 skill). The Feb 22 audit counted 3 SPAs + 1 shared; the difference represents simpler clients added between Feb–Mar 2026. `bom-manager` does NOT exist — phantom reference, remove all mentions.

| Tier | Client | Notes |
|------|--------|-------|
| **Production** | laminate-inventory | React 19, Vite 7, TypeScript, shared lib. Live on shop floor |
| **Production** | purchasing-ledger | [UNVERIFIED] launched 2026-03-09 |
| **Functional** | app | Main SPA, shared lib |
| **Functional** | admin | Admin interface |
| **Functional** | document-creator | Document generation, shared lib |
| **Functional** | workflow-builder | React Flow, Zustand |
| **Functional** | compliance-audit | Compliance checks |
| **Functional** | quick-reference | Quick reference, shared lib |
| **Library** | shared | Components/styles consumed by 4 clients |

## 7. Adapters

Location: `Cambium/Cambium/adapters/` — 8 adapters, 11 `.adapter.md` files, `ORCHESTRATOR.md`.

### Active

| Adapter | Connects | Purpose |
|---------|----------|---------|
| SpecToAutoCAD | Specifications → AutoCAD | Cross-context read (documented exception) |
| SpecToMaster | Specifications → AutoCAD masters | Badge specs via named pipe |
| FlagToOverlay | Spec flags → AutoCAD overlays | Provenance/availability indicators |
| JobToChat | Jobs → Chat | Job lifecycle broadcasts (event-driven) |
| DrawingCheckoutToChat | DrawingCheckout → Chat | Change notifications |
| StagingToProduction | Staging → Production | Data promotion |

### Placeholder

MasterToSheet, SheetToPdf — implement or remove.

## 8. Tech Stack

### Backend

| Component | Version | Source |
|-----------|---------|--------|
| .NET SDK | 8.0 / 10.0 (Courier) | Skill files + build confirmation |
| ASP.NET Core | 8.0 | REST API + SignalR |
| Entity Framework Core | 8.0 | Build passes; 0 MSB3277 warnings on clean build |
| PostgreSQL | 17 (shop + Pi), 14+ (Railway) | Hosting skill |
| Npgsql | 9.0.2 | Skill files |

### Frontend

| Component | Version | Source |
|-----------|---------|--------|
| React | 19 | Skill files |
| TypeScript | 5.9+ | Skill files |
| Vite | 7 | Skill files |

### AutoCAD Plugin (Luxify)

.NET Framework 4.8, AutoCAD 2022–2026. 6 projects: Core, Layout (~8K lines), Badging, Legends, Styles, CuttingBill. WPF palette UI. Named pipe IPC: `\\.\pipe\LuxifyCommandBridge`. Deploy: `C:\ProgramData\Autodesk\ApplicationPlugins\Luxify.bundle\Contents\`.

### Infrastructure

Shop server (DEJAVARA, Windows 11, 192.168.0.108) is the authoritative source — must work offline. Phteah-Pi (Raspberry Pi 5, 192.168.1.76) is a home replica synced every 20 min. Railway (cloud) auto-deploys from `main` — convenience replica only.

Key ports: 5001 (API), 5432 (PG 17), 5433 (PG 16 legacy, DEJAVARA only), 51820 (WireGuard VPN). Tunnel: api.luxifyspecgen.com → localhost:5001.

## 9. Database Summary

- **175 DbSet registrations** mapping to **171 distinct entity types** in CambiumDbContext — a single shared context across all domains
- **58 migrations** (2025-12-23 → 2026-03-12), including 1 in AutoCAD subfolder. No orphans.
- **165 tables** on shop server, **109 on Railway** (56 unshipped = expected)
- **288 DTO classes** in `Cambium.Shared/DTOs/` (Feb 2026 count)

Entity groups: Jobs & FOs, Messaging, Badges & Specs, Millwork Hierarchy, Directory, Operations, Contract Documents, Drawings, Inventory, Courier, Users & Auth.

**Railway schema drift:** 56 tables on shop server have no Railway equivalent. Any endpoint querying these returns 500. Pre-push: run `scripts/check-railway-schema.sql`.

**No MigrateAsync().** Removed after destructive Railway recreation. Self-healing ALTER block in Program.cs:622-674 handles auth-critical columns.

## 10. API Surface

~55 controller files, 64+ endpoints. ~1,200 lines in Program.cs.

**Production-tier:** LaminatesController, BadgesController (IBadgesManager + IHybridAiService + ICommandBridgeClient + more), AuthController (dual JWT/Cookie "Smart" PolicyScheme, login lines 40-190, JWT lines 1226-1256).

**Functional:** JobsController (event-driven use cases), FactoryOrdersController, DirectoryController, DocumentsController, ContractController, CourierController, DrawingsController, DrawingCheckoutController, StagingController, SpecificationsController, SamplesController, AutoCadController, WorkflowsController, HealthController (includes `/api/health/sync`).

**SignalR:** StagingHub — JoinJobChannel, LeaveJobChannel. Events: MessageReceived, StagingUpdated, FactoryOrderCreated.

**Auth:** "Smart" PolicyScheme selects JWT or Cookie per request. Cookie: `Cambium.Auth`, 30-day sliding, HttpOnly. OnRedirectToLogin returns 401 not 302. DataProtection keys in DB — missing table = silent session invalidation.

## 11. Build & Verify Commands

```powershell
dotnet build                                    # ~10.7s, 0 errors (2026-03-11)
dotnet test tests/Cambium.Tests.Unit            # 167 tests passing
cd clients/laminate-inventory && npm run verify  # PRODUCTION verification
psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql  # pre-push
cd AutoCAD-Tools && .\BUILD_AND_DEPLOY.ps1      # CLOSE AUTOCAD FIRST
sc query CambiumApi                             # Windows Service status
dotnet publish src/Cambium.Api -c Release -o publish/  # manual deploy
```

## 12. Domain Terminology

**Factory Order (FO)** — atomic manufacturing unit. **Job** — customer project. **Badge** — shop floor spec identifier; shape encodes category (Ellipse=FINISH, Diamond=FIXTURE, Rectangle=EQUIPMENT, 8-Point Star=BUYOUT, Triangle=PROVENANCE). **Specification** — material definition gated by **Provenance Flag** (permission) and **Availability Flag** (reality). **Hierarchies:** Job → Project → FO → Part. Zone → Room → Area → Wall/Ceiling. Item → Assembly → Component → Part.

## 13. Architectural Constraints & Gotchas

**No cross-module imports.** Adapters only. **PostgreSQL only.** `POSITION()` not `CHARINDEX()`, `||` not `+`, `TRUE/FALSE` not `1/0`. **AutoCAD DLL locking** — close before building. **Dev vs Service** — both use port 5001, check `netstat`. **Sheet numbering** — GLOBAL per job, not per-layout. **BottaERisposta CSS** — NEVER inline styles on form elements (breaks dark theme). Use `form-group`, `form-select`, etc. **EF column drift** — one missing column kills all queries for that entity (42703). **Railway DATABASE_URL** — must be `${{Postgres.DATABASE_URL}}`, never hardcoded. **BCrypt `$` in bash** — use `.sql` files with `psql -f`. **No MigrateAsync()** — apply manually.

## 14. Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | AI context — read first |
| `CLAUDE-ARCHITECTURE.md` | Hexagonal rules (note: lists only 2 adapters — stale) |
| `src/Cambium.Api/Program.cs` | Startup (1200+ lines): self-healing 622-674, auth 201-214, admin seed 1192-1211 |
| `src/Cambium.Api/Controllers/AuthController.cs` | Login 40-190, JWT 1226-1256 |
| `src/Cambium.Data/DbContext/CambiumDbContext.cs` | 175 DbSets (171 distinct types) |
| `modules/Cambium.Module.Inventory/Domain/Entities/Laminate.cs` | Best DDD example: factory methods, value objects |
| `scripts/check-railway-schema.sql` | Pre-push Railway validation |

## 15. Known Debt

- **Gen 1 dominates Gen 2.** 44 managers in Core vs. 2 fully compliant modules (Jobs, Inventory). Badges has hex folder structure but wires through Gen 1 managers with direct DbContext injection.
- **Only 4 domain events wired.** 9 event contracts defined, 5 are contracts-only.
- **Monolithic CambiumDbContext** with 175 DbSets (171 distinct types). Module boundaries not enforced at data layer.
- **Dependency violations:** Core→Data, Core→Module.Chat, Module.Inventory→Data (compiler-visible).
- **127+ TODO/FIXME/Deprecated** markers across the codebase (2026-03-11 audit).
- **56 Railway-missing tables.** New endpoints touching unshipped entities will 500.
- **CLAUDE-ARCHITECTURE.md is stale** — lists only 2 adapters (there are 8).
- **DrawingCheckout** has EF `[Table]`/`[Column]` annotations on domain entities (violates hex rules).
- **`bom-manager`** phantom — referenced in old docs, never existed.
- **288 DTOs** in Shared — growing; should separate contract interfaces from API DTOs.
- **Cambium.Module.SiteView** is the only `Cambium.Module.*` dir missing MODULE.md.
