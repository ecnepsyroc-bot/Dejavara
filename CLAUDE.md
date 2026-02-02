# Dejavara Platform - AI Context

Master orchestration platform with domains for work and home.

## Platform Overview

**Dejavara** is a personal ecosystem orchestrated by Clawdbot (AI controller).

| Component | Purpose | Details |
|-----------|---------|---------|
| Clawdbot | Central AI controller | Claude API-powered assistant |
| Cambium | Work domain | See `Cambium/CLAUDE.md` |
| Phteah-pi | Home domain | See `Phteah-pi/CLAUDE.md` |
| FileOrganizer | Shared utility | File organization across domains |
| AutoCAD-AHK | Shared utility | AutoHotkey scripts for AutoCAD |

## Architecture

```
Dejavara (Master)
├── Clawdbot/        ← AI brain, orchestrates everything
├── Cambium/         ← Work: millwork factory systems
├── Phteah-pi/       ← Home: Raspberry Pi server
├── FileOrganizer/   ← Shared: file organization
└── AutoCAD-AHK/     ← Shared: AutoCAD panning scripts
```

## Domain Boundaries

- **Clawdbot** coordinates across domains but doesn't own domain logic
- **Cambium** handles all work/factory concerns
- **Phteah-pi** handles all home server concerns
- **FileOrganizer** is a utility consumed by both domains

## Quick Navigation

- Work tasks → `Cambium/CLAUDE.md`
- Home tasks → `Phteah-pi/CLAUDE.md`
- AI/orchestration → `Clawdbot/`
- File organization → `FileOrganizer/`
- AutoCAD scripts → `AutoCAD-AHK/`
