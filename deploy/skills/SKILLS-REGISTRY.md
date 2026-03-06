# Skills Registry

Track custom skills and their revision status.

## Custom Skills

| Skill | Version | Last Updated | Next Review | Status |
|-------|---------|--------------|-------------|--------|
| aspnet-dual-auth | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| aspnet-dataprotection-db | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| cloudflare-tunnel | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| dev-passwords | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| railway-deploy | 1.1.0 | 2026-02-13 | 2026-03-13 | Superseded by cambium-railway-ops |
| session-to-skill | 1.0.0 | 2026-02-08 | 2026-03-08 | Active |
| postgres-failover-sync | 1.1.0 | 2026-02-13 | 2026-03-13 | Active |
| postgres-remote-ops | 1.0.0 | 2026-02-13 | 2026-03-13 | Active |
| millwork-file-management | 1.0.0 | 2026-02-17 | — | PENDING UPDATE (V7.1.1) |
| autocad-plugin-development | 1.0.1 | 2026-03-06 | 2026-04-06 | Active |
| cambium-platform | 1.1.0 | 2026-03-05 | 2026-04-05 | Active |
| cambium-auth-credentials | 1.0.0 | 2026-03-05 | 2026-04-05 | Active |
| aspnet-api-development | 1.1.0 | 2026-03-06 | 2026-04-06 | Active |
| agentic-coding-workflow | 1.1.0 | 2026-03-06 | 2026-04-06 | Active |
| cambium-railway-ops | 1.0.0 | 2026-03-05 | 2026-04-05 | Active |
| cambium-database-migrations | 1.0.0 | 2026-03-05 | 2026-04-05 | Active |
| cambium-permissions-log | 1.0.0 | 2026-03-05 | 2026-04-05 | Active |
| feature-millwork-infrastructure | 1.0.0 | 2026-02-14 | 2026-04-14 | Active |
| pm-folder-standards | 1.0.0 | 2026-02-17 | 2026-04-17 | Active |
| awmac-naaws | 1.0.0 | 2026-03-06 | 2026-04-06 | Active |
| badge-reflex-system | 1.0.0 | 2026-03-06 | 2026-04-06 | Active |
| context-engineering | 1.0.0 | 2026-03-06 | 2026-04-06 | Active |
| mcp-server-development | 1.0.0 | 2026-03-06 | 2026-04-06 | Active |
| millwork-shop-drawings | 1.0.0 | 2026-03-06 | 2026-04-06 | Active |
| quickbooks-contractor-invoicing | 1.0.0 | 2026-03-06 | 2026-04-06 | Active |
| cambium-hosting | - | - | - | Planned |

## Revision Schedule

- **Monthly review**: Check for API changes, deprecated features, new best practices
- **On failure**: Update skill when a documented workflow fails
- **On success**: Capture new patterns that worked

## Revision Checklist

When reviewing a skill:
1. Test main workflows still work
2. Check for API version changes
3. Update response examples if changed
4. Add new common issues encountered
5. Update version number and dates

## Changelog

### 2026-03-06 (Claude.ai-only skills export)
- Exported 6 Claude.ai-only skills to local version control: awmac-naaws, badge-reflex-system, context-engineering, mcp-server-development, millwork-shop-drawings, quickbooks-contractor-invoicing
- Status changed from "Active (Claude.ai only)" → "Active" for all 6

### 2026-03-06 (skills audit + consolidation)
- `cambium-platform` v1.1.0: verified counts (20 modules, 8 clients, 117 migrations, 0 warnings)
- `aspnet-api-development` v1.1.0: removed Rami terminology, added dual auth + column-drift pattern
- `agentic-coding-workflow` v1.1.0: added AUDIT.log protocol, pre-railway-push gate, fixed warning count
- `autocad-plugin-development` v1.0.1: updated AutoCAD version range to 2022-2026
- `millwork-file-management`: flagged PENDING UPDATE (V7.1.1 gap — 10+ structural changes including folder naming, view numbers, system folders, fabrication suffix)
- Registered `feature-millwork-infrastructure` v1.0.0 (existed locally since 2026-02-14)
- Registered `pm-folder-standards` v1.0.0 (existed locally since 2026-02-17)
- Added 6 Claude.ai-only skills to registry (no local source): awmac-naaws, badge-reflex-system, context-engineering, mcp-server-development, millwork-shop-drawings, quickbooks-contractor-invoicing
- Produced 5 updated skill files in `deploy/skills-for-claude-ai/` for Claude.ai upload

### 2026-03-05 (skills update session)
- Updated `cambium-platform` to v1.1.0
  - Module count corrected to 20 (was 16) with Status and MODULE.md columns
  - Client table verified: 8 clients (bom-manager confirmed phantom — removed)
  - Database counts: 117 migrations, 182 DbSets (91 unique types)
  - Railway schema drift section: 109/164 tables present, 55 missing
  - EF Core version conflict documented (22 MSB3277 warnings)
  - Adapter count corrected to 8 (was 7, adds SpecToAutoCAD)
  - Known violations and build status sections added
- Created `aspnet-api-development` skill v1.0.0
  - Smart PolicyScheme (JWT/Cookie selector) with code pattern
  - EF Core column-drift failure pattern (42703 → cascading 500s)
  - Self-healing startup pattern (individual try/catch per ALTER)
  - Post-heal schema verification pattern
  - Railway connection string parsing (DATABASE_URL URI → Npgsql)
  - DataProtection key persistence to database
- Created `agentic-coding-workflow` skill v1.0.0
  - Permissions Log Protocol (AUDIT.log format)
  - Verification-Before-Implementation Protocol
  - Multi-Model Workflow (Claude.ai + Claude Code)
  - Pre-Railway-Push Gate
  - Session End Protocol
- Created `cambium-railway-ops` skill v1.0.0 (supersedes `railway-deploy`)
  - Variable Reference rule (DATABASE_URL must be `${{Postgres.DATABASE_URL}}`)
  - Schema check documentation (scripts/check-railway-schema.sql)
  - Deployment sequence with log patterns to watch
  - Credential rotation procedures with blast radius analysis
- Created `cambium-database-migrations` skill v1.0.0
  - The v5 pattern: no MigrateAsync (deliberate)
  - Column-drift failure chain documentation
  - 6 highest-drift-risk user columns identified
  - When to use migration vs ALTER TABLE self-healing
  - Manual migration application workflow
- Created `cambium-permissions-log` skill v1.0.0
  - AUDIT.log format specification and action types
  - Session templates (verification, implementation, skills)
  - Rules for autonomous action logging

### 2026-03-05
- Created `cambium-auth-credentials` skill v1.0.0
  - Dual JWT + Cookie auth documentation with code locations
  - Railway Variable Reference rule (`${{Postgres.DATABASE_URL}}`)
  - Admin password recovery pattern (ADMIN_DEFAULT_PASSWORD env var)
  - Pre-push checklist derived from 3 real production incidents
  - Credential inventory with blast radius analysis
  - Self-healing startup block documentation (C1-C4 fixes)

### 2026-02-18

- Created `autocad-plugin-development` skill v1.0.0
  - Based on Luxify (Feature Millwork production plugin)
  - Target: .NET Framework 4.8 (AutoCAD 2022-2025), NOT .NET 8
  - `IExtensionApplication` initialization with assembly resolver
  - Bundle deployment to `C:\ProgramData\Autodesk\ApplicationPlugins\`
  - `PackageContents.xml` for auto-loading
  - Transaction patterns with `using` statements
  - Document locking for event/async contexts
  - Block creation and attribute population
  - WPF palette with MVVM and theme detection
  - Build script with AutoCAD process check

- Created `cambium-platform` skill v1.0.0
  - Feature Millwork unified automation platform
  - Hexagonal architecture: 16 modules + 7 adapters
  - Tech stack: .NET 8/10, React 19, PostgreSQL, SignalR
  - Core systems: Botta e Risposta, Luxify, Laminate Inventory
  - 91 database entities, 64 REST endpoints
  - Domain vocabulary: FO, Badge, Provenance/Availability flags
  - Command Bridge: Named pipe IPC to AutoCAD
  - Production systems protection (laminate inventory, Luxify)

### 2026-02-17

- Created `millwork-file-management` skill v1.0.0
  - Based on Cambium Documentation Standards v5.7.0
  - 12-folder project structure (00-11) + `_archive` and `_cambium`
  - Job number format: YY## (4-digit)
  - Naming pattern: `{job}-{type}-{seq}-R{#}-{date}`
  - Factory Order dual-location (`C:\FO\` + project `07-production/`)
  - Three underscore patterns: `_source/`, `_received/`, `_template/`
  - AWMAC 4-subfolder structure
  - SOURCE_DWG traceability (FO vs SUB modes)
  - Revision control with `revision-log.json`

### 2026-02-13
- Created `postgres-remote-ops` skill v1.0.0
  - Execute SQL when psql isn't locally installed
  - Node.js `pg` package one-liners and scripts
  - SSH jump box patterns for Cambium-server
  - Batch file approach to avoid escaping hell
  - Railway-specific notes (external vs internal hosts)
  - Decision tree for method selection
- Updated `postgres-failover-sync` to v1.1.0
  - Added post-sync verification section
  - Column drift detection and repair
  - Node.js fallback when psql unavailable
  - Common issues table with fixes
- Updated `railway-deploy` to v1.1.0
  - Added database sync & verification section
  - Column drift explanation and prevention
  - Free plan limitations documented
  - Cross-reference to postgres-remote-ops

### 2026-02-12
- Created `postgres-failover-sync` skill v1.0.0
  - Schema nuke pattern for reliable full-database sync
  - pg_terminate_backend before restore
  - Cross-auth JWT key matching
  - Windows batch and Linux script templates
  - Lessons: incremental --clean fails on schema drift; nuke and rebuild wins

### 2026-02-08 (evening)
- Created `aspnet-dual-auth` skill v1.0.0
  - Policy scheme selector for JWT vs Cookie based on request
  - Cookie config for SPA (HttpOnly, SameSite=Lax, 30-day expiry)
  - Critical: Return 401 instead of redirect for API calls
  - Login controller pattern to set both JWT and cookie
  - SPA client configuration (withCredentials: true)
- Created `aspnet-dataprotection-db` skill v1.0.0
  - IDataProtectionKeyContext implementation
  - Migration for data_protection_keys table
  - Package version alignment (EF Core 8.0.*)
  - Railway-specific notes (ephemeral filesystem)

### 2026-02-08
- Created `dev-passwords` skill v1.0.0
  - BCrypt library compatibility across platforms (.NET, Node.js, Python)
  - How to diagnose auth failures from hash mismatches
  - Hash generation examples for each platform
  - Lesson captured: bcryptjs ≠ BCrypt.Net
- Created `railway-deploy` skill v1.0.0
  - .NET 8 deployment workflow
  - PostgreSQL provisioning and connection
  - EF Core migrations via SQL scripts (timeout workaround)
  - Troubleshooting reference: duplicate appsettings, gitignore conflicts, port config
- Created `cloudflare-tunnel` skill v1.0.0
  - API workflows for domain, tunnel, DNS management
  - Helper script `cf-tunnel.sh`
  - API response examples reference
- Created `session-to-skill` skill v1.0.0
  - Meta-skill for capturing sessions as documentation
  - Skill template reference
  - Quality checklist for skill creation

## Planned Skills

### cambium-hosting (Priority: Medium)
- Cambium-specific deployment config
- Environment variables
- Database migration
- Frontend deployment

### hosting-general (Priority: Low)
- Compare hosting options (Railway, Render, Fly.io, Hetzner)
- Cost/complexity tradeoffs
- When to use which
