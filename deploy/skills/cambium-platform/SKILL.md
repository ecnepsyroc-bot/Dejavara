---
name: cambium-platform
description: "Unified automation platform for Feature Millwork operations. Encompasses Botta e Risposta (shop communication), AutoCAD Tools (Luxify), Badge Reflex, Factory Orders, and workflow automation. Use when working on any Cambium subsystem, discussing platform architecture, or integrating systems. Triggers include Cambium, Botta e Risposta, shop communication, factory orders, workflow builder, Luxify, or Feature Millwork automation."
---

# Cambium Platform

Feature Millwork's unified automation platform following hexagonal architecture.

## Platform Overview

| System | Tech Stack | Status | Purpose |
|--------|------------|--------|---------|
| **Botta e Risposta** | .NET 8, SignalR, PostgreSQL | Active | Shop floor messaging |
| **Luxify (AutoCAD Tools)** | .NET Framework 4.8, WPF | Active | Drawing automation, badges, title blocks |
| **Laminate Inventory** | React 19, TypeScript | **PRODUCTION** | Shop floor inventory tracking |
| **Workflow Builder** | React 19, Zustand, React Flow | Active | Visual process automation |
| **Document Creator** | React 19, TypeScript | Active | Document generation |
| **Courier** | .NET 10, Module | Building | Shipping/document management |

## Tech Stack

### Backend

| Component | Version | Purpose |
|-----------|---------|---------|
| .NET SDK | 8.0 / 10.0 | API and modules |
| ASP.NET Core | 8.0 | REST API + SignalR |
| Entity Framework Core | 8.0 | ORM |
| **PostgreSQL** | 14+ | Primary database (NOT SQL Server) |
| Npgsql | 9.0.2 | PostgreSQL driver |
| Serilog | — | Structured logging |

### Frontend

| Component | Version | Purpose |
|-----------|---------|---------|
| React | 19 | UI framework |
| TypeScript | 5.9+ | Type safety |
| Vite | 7 | Build tool |
| Zustand | — | State management |
| React Flow | — | Visual workflow editor |

### AutoCAD Plugin

| Component | Version | Purpose |
|-----------|---------|---------|
| .NET Framework | 4.8 | AutoCAD 2022-2025 |
| WPF | — | Palette UI |
| CommunityToolkit.Mvvm | — | MVVM pattern |

## Architecture

```
Cambium/
├── Cambium/                          # Core platform
│   ├── src/
│   │   ├── Cambium.Api/              # ASP.NET Core API
│   │   ├── Cambium.Core/             # Business logic
│   │   ├── Cambium.Data/             # EF Core + PostgreSQL
│   │   └── Cambium.Shared/           # DTOs, contracts
│   │
│   ├── modules/                      # 16 hexagonal modules
│   │   ├── Cambium.Module.Chat/      # Messaging
│   │   ├── Cambium.Module.Jobs/      # Job management
│   │   ├── Cambium.Module.Badges/    # Badge system
│   │   ├── Cambium.Module.Inventory/ # Laminate tracking
│   │   ├── Cambium.Module.Staging/   # Pre-production
│   │   ├── Cambium.Module.Workflow/  # Process automation
│   │   └── ...
│   │
│   ├── adapters/                     # 7 cross-module bridges
│   │   ├── SpecToMaster/             # Specs → AutoCAD
│   │   ├── JobToChat/                # Job events → Notifications
│   │   ├── MasterToSheet/            # Masters → Sheets
│   │   ├── SheetToPdf/               # Sheets → PDF output
│   │   └── ...
│   │
│   ├── clients/                      # React frontends
│   │   ├── laminate-inventory/       # PRODUCTION SYSTEM
│   │   ├── workflow-builder/
│   │   ├── document-creator/
│   │   └── shared/
│   │
│   └── event-schema/                 # Shared event contracts
│
├── AutoCAD-Tools/                    # Luxify plugin (submodule)
│   └── Luxify/
│       ├── Luxify.Layout/            # Main DLL
│       ├── Luxify.Badging/           # Smart Badge system
│       ├── Luxify.Legends/           # Legend generation
│       └── Luxify.Core/              # Shared utilities
│
├── BottaERisposta/                   # Alternative deployment
│
└── foundational documents/           # Domain standards
    └── standards/                    # v5.7.0 documentation
```

## Hexagonal Architecture Rules

**Modules NEVER import from each other.** All cross-module communication goes through adapters.

```
Module A ──event──► Adapter ──command──► Module B
```

### Active Modules (16)

| Module | Purpose |
|--------|---------|
| `Cambium.Module.Chat` | Real-time messaging |
| `Cambium.Module.Jobs` | Job lifecycle |
| `Cambium.Module.Badges` | Badge domain logic |
| `Cambium.Module.Inventory` | Laminate tracking |
| `Cambium.Module.Staging` | Pre-production workflow |
| `Cambium.Module.Workflow` | Visual workflow engine |
| `Cambium.Module.Documents` | Document management |
| `Cambium.Module.DrawingCheckout` | Drawing access control |
| `Cambium.Module.Production` | Manufacturing workflow |
| `Cambium.Module.Specifications` | Material specs |
| `Cambium.Module.Bom` | Bill of Materials |
| `Cambium.Courier` | Shipping/contacts |
| `Cambium.PdfLibrary` | PDF utilities |
| `Cambium.Sheets` | Sheet management |

### Active Adapters (7)

| Adapter | From → To |
|---------|-----------|
| `SpecToMaster` | Specifications → AutoCAD masters |
| `FlagToOverlay` | Spec flags → AutoCAD overlays |
| `JobToChat` | Job events → Chat notifications |
| `DrawingCheckoutToChat` | Drawing changes → Notifications |
| `MasterToSheet` | Masters → Sheet generation |
| `SheetToPdf` | Sheets → PDF output |
| `StagingToProduction` | Staging → Production promotion |

## Database Schema (PostgreSQL)

### Core Entities (91 tables)

**Jobs & Factory Orders:**

```sql
CREATE TABLE jobs (
    id SERIAL PRIMARY KEY,
    job_code VARCHAR(50) UNIQUE NOT NULL,
    job_name VARCHAR(255) NOT NULL,
    client VARCHAR(255),
    contractor VARCHAR(255),
    pm VARCHAR(100),
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE factory_orders (
    id SERIAL PRIMARY KEY,
    fo_number VARCHAR(50) UNIQUE NOT NULL,
    job_id INT REFERENCES jobs(id),
    description TEXT,
    status VARCHAR(50),
    due_date DATE,
    hold_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE fo_parts (
    id SERIAL PRIMARY KEY,
    fo_id INT REFERENCES factory_orders(id),
    part_number VARCHAR(50),
    description TEXT,
    quantity INT
);
```

**Messaging:**

```sql
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    job_id INT REFERENCES jobs(id),
    chat_id INT,
    content TEXT NOT NULL,
    sender_name VARCHAR(255),
    sender_id INT,
    type VARCHAR(50),  -- User, System, Bot
    is_edited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE individual_chats (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    job_id INT REFERENCES jobs(id)
);
```

**Badges & Specifications:**

```sql
CREATE TABLE job_badges (
    id SERIAL PRIMARY KEY,
    job_id INT REFERENCES jobs(id),
    badge_code VARCHAR(50),
    category VARCHAR(50),
    description TEXT,
    provenance_flag BOOLEAN DEFAULT FALSE,
    availability_flag BOOLEAN DEFAULT FALSE
);

CREATE TABLE badge_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    shape VARCHAR(50)
);
```

**Spatial Hierarchy:**

```sql
-- Job → Zone → Room → Area → Wall/Ceiling
CREATE TABLE job_zones (id, job_id, name);
CREATE TABLE job_rooms (id, zone_id, name, room_number);
CREATE TABLE job_areas (id, room_id, name);
CREATE TABLE job_walls (id, area_id, wall_id);
CREATE TABLE job_ceilings (id, area_id, name);
```

**Drawings:**

```sql
CREATE TABLE drawings (
    id SERIAL PRIMARY KEY,
    job_id INT REFERENCES jobs(id),
    drawing_number VARCHAR(50),
    title VARCHAR(255),
    status VARCHAR(50),
    current_revision INT DEFAULT 0
);

CREATE TABLE drawing_checkouts (
    id SERIAL PRIMARY KEY,
    drawing_id INT REFERENCES drawings(id),
    user_id INT,
    checked_out_at TIMESTAMP,
    checked_in_at TIMESTAMP
);
```

## API Endpoints

### REST (64 endpoints)

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

## Domain Vocabulary

| Term | Definition |
|------|------------|
| **Factory Order (FO)** | Atomic unit of manufacturing |
| **Badge** | Shop floor ID linking specs to physical materials |
| **Specification** | Material definition with flags |
| **Provenance Flag** | Permission gate (sample approved, sign-off) |
| **Availability Flag** | Reality gate (in stock, lead time) |
| **SSOT** | Single Source of Truth (Excel driving outputs) |

## Badge Categories

| Category | Purpose | Badge Shape |
|----------|---------|-------------|
| FINISH | Surface materials | Ellipse |
| FIXTURE | Built items, hardware | Hexagon |
| EQUIPMENT | Appliances, electrical | Rectangle |
| BUYOUT | Subcontracted items | Rounded Rectangle |

## Hierarchies

### Job Hierarchy

```
Job (Netflix, Dentons, ESDC)
└── Project (Billable deliverable)
    └── Factory Order (Manufacturing unit)
        └── FO Part (Line items)
```

### Location Hierarchy

```
Zone/Wing
└── Room
    └── Area
        ├── Wall
        └── Ceiling
```

### Build Hierarchy

```
Item (Credenza, Reception Desk)
└── Assembly (Upper Cabinet, Drawer Bank)
    └── Component (Drawer Box)
        └── Part (Side Panel, Drawer Bottom)
```

## Port Registry

| Port | Service | Purpose |
|------|---------|---------|
| 5001 | Cambium.Api | Main REST + SignalR |
| 5050 | Mock Sync Server | Dev testing |
| 5174 | Workflow Builder | React dev |
| 5175 | Document Creator | React dev |
| 5176 | Document Staging | React dev |
| 5177 | BOM Manager | React dev |
| 5432 | PostgreSQL | Database |

## Build Commands

```powershell
# API
cd Cambium/src/Cambium.Api
dotnet run

# Migrations
dotnet ef database update --project Cambium/src/Cambium.Data --startup-project Cambium/src/Cambium.Api

# React clients
cd Cambium/clients/laminate-inventory
npm install && npm run build

# AutoCAD Tools (MUST close AutoCAD first!)
cd AutoCAD-Tools
.\BUILD_AND_DEPLOY.ps1

# Windows Service
sc query CambiumApi
net stop CambiumApi && net start CambiumApi
```

## Production Systems (PROTECT)

### Laminate Inventory

**Status:** Live on shop floor

```bash
# Verify before changes
npm run test:run

# Build (NEVER npm run dev in production)
npm run build
```

**Tunnel:** Cloudflare tunnel on localhost:5001

### AutoCAD Tools (Luxify)

**Status:** Active

```powershell
# CLOSE AUTOCAD BEFORE BUILD
.\BUILD_AND_DEPLOY.ps1
```

**Deployment:** `C:\ProgramData\Autodesk\ApplicationPlugins\Luxify.bundle\Contents\`

## UI Standards (CRITICAL)

**NEVER use inline styles for form elements** — breaks dark theme.

```html
<!-- WRONG -->
<select style="padding: 8px;">

<!-- CORRECT -->
<select class="form-select">
```

**Required classes:** `form-group`, `form-label`, `form-input`, `form-select`, `form-textarea`

## AutoCAD Command Bridge

Named pipe IPC between API and AutoCAD plugin:

```
Pipe: \\.\pipe\LuxifyCommandBridge
Client: ICommandBridgeClient (DI injectable)
Server: Runs inside AutoCAD plugin
```

```csharp
// Send command to AutoCAD
await _bridgeClient.SendCommandAsync("LUX_PLACE_BADGE", parameters);
```

## Configuration

```json
{
  "ConnectionStrings": {
    "Default": "Host=localhost;Port=5432;Database=cambium;Username=cambium_user;Password=..."
  },
  "Jwt": {
    "Issuer": "Cambium",
    "Audience": "CambiumUsers",
    "Key": "your-secret-key"
  },
  "CommandBridge": {
    "PipeName": "LuxifyCommandBridge",
    "ConnectionTimeout": 5000,
    "CommandTimeout": 30000
  }
}
```

## PostgreSQL Syntax (NOT SQL Server)

```sql
-- String operations
POSITION('x' IN col)           -- NOT CHARINDEX()
SUBSTRING(col FROM 1 FOR 5)    -- Different syntax

-- Concatenation
col1 || col2                   -- NOT col1 + col2

-- Booleans
TRUE / FALSE                   -- NOT 1 / 0
```

## Philosophy

> **Humans make decisions. Software tracks and meets them at every turn.**

- Single source of truth
- Enter data once, auto-fill everywhere
- Identify repeating workflow steps, automate them
- Ship one reflex at a time, not complete systems
