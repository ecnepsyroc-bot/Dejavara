# Luxify Architecture Quick Reference

## Layers

| Layer | Path | Purpose |
|-------|------|---------|
| Rami | `Cambium/rami/` | Isolated domain units (each has `.ramus.md`) |
| Grafts | `Cambium/grafts/` | Bridges between rami (each has `.graft.md`) |
| Water | `Cambium/water/` | Event contracts (declarative, no logic) |
| Sap | `Cambium/sap/` | Cross-cutting: auth, validation, CLI tools |
| Leaves | `wwwroot/`, `clients/` | Presentation layer (no domain logic) |

## Critical Rules

1. **Rami NEVER import from other rami** - use grafts for cross-ramus communication
2. **Grafts orchestrate, don't own domain logic** - they coordinate, not compute
3. **Water is events only** - declarative definitions, no business logic
4. **Sap validates at boundaries** - external input validation only

## Active Rami

| Ramus | Responsibility |
|-------|----------------|
| `Cambium.Ramus.Jobs` | Factory Order management |
| `Cambium.Ramus.Inventory` | Laminate inventory tracking |
| `Cambium.Ramus.Chat` | Shop floor messaging (Botta e Risposta) |
| `Cambium.Courier` | External system integration, addresses |
| `Cambium.Ramus.Badges` | Badge palette and placement |

## Key Paths

| Resource | Path |
|----------|------|
| Root | `C:\Dev\Dejavara\Cambium\` |
| API source | `Cambium/src/Cambium.Api/` |
| BottaERisposta | `BottaERisposta/` |
| Memory bank | `memory-bank/` |
| AutoCAD Tools | `AutoCAD-Tools/` (submodule) |
| Main docs | `CLAUDE.md`, `CLAUDE-ARCHITECTURE.md` |

## Database

- **PostgreSQL** (NOT SQL Server)
- Database: `cambium` (main), `shop_chat` (messaging)
- Port: 5432
- ORM: Entity Framework Core 8 + Npgsql

## Quick Commands

| Task | Command |
|------|---------|
| Build all | `just build` |
| Build API | `dotnet build Cambium.sln` |
| Run tests | `just test` |
| Health check | `just health` |
| Build AutoCAD | `.\BUILD_AND_DEPLOY.ps1` |

## AutoCAD Workflow

**CRITICAL:** After ANY AutoCAD-Tools change:
1. Close AutoCAD (DLLs locked while running)
2. Run `.\BUILD_AND_DEPLOY.ps1`
3. Verify DLL timestamps in `C:\ProgramData\Autodesk\ApplicationPlugins\Luxify.bundle\Contents\`

## API Ports

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:5001` |
| Production | `https://api.luxifyspecgen.com` |
