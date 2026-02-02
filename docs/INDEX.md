# Dejavara Platform Documentation Index

## Platform Overview

- [CLAUDE.md](../CLAUDE.md) - AI assistant context for the platform

---

## Domains

### Cambium (Work)

Millwork factory management system.

- [CLAUDE.md](../Cambium/CLAUDE.md) - Work domain context
- [Architecture](../Cambium/CLAUDE-ARCHITECTURE.md) - System architecture
- [Build & Deploy](../Cambium/CLAUDE-BUILD-DEPLOY.md) - Deployment guide
- [Troubleshooting](../Cambium/CLAUDE-TROUBLESHOOTING.md) - Common issues

### Phteah-pi (Home)

Raspberry Pi home server.

- [CLAUDE.md](../Phteah-pi/CLAUDE.md) - Home domain context
- [Development](../Phteah-pi/DEVELOPMENT.md) - Dev environment setup
- [Port Registry](../Phteah-pi/docs/PORT-REGISTRY.md) - Service ports

### OpenClaw (AI)

Central AI controller powered by Claude API.

- Located in `OpenClaw/` submodule
- TypeScript-based, ~560k lines

---

## Shared Utilities

### FileOrganizer

File organization CLI tool.

- Location: [FileOrganizer/](../FileOrganizer/)
- Used by: Cambium, Phteah-pi

### AutoCAD-AHK

AutoHotkey scripts for AutoCAD panning.

- Location: [AutoCAD-AHK/](../AutoCAD-AHK/)
- Scripts: AutoPan.ahk, StickyPan.ahk

---

## Architecture & Planning

- [Simplification Spec](SIMPLIFICATION-SPEC.md) - Codebase simplification plan

---

## Quick Stats

| Component | Language | Lines | Purpose |
|-----------|----------|-------|---------|
| OpenClaw | TypeScript | 560,292 | AI orchestration |
| Cambium | C# | 390,010 | Factory systems |
| Luxify | C# | ~15,000 | AutoCAD plugin |
| Phteah-pi | Mixed | ~6,000 | Home automation |

**Total:** ~971,000 lines of code
