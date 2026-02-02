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

## Git Workflow

**Commit incrementally** - Do NOT let changes accumulate. Commit after each logical change:

1. After implementing a feature or fix, commit immediately
2. After adding new files, commit before moving to the next task
3. After modifying configuration, commit before code changes
4. When working across submodules, commit inner repos first, then outer

**Commit order for submodules:**

```text
1. AutoCAD-Tools (if changed) → commit & push
2. Cambium (if changed) → commit & push
3. Dejavara → commit & push (updates submodule refs)
```

**Why incremental commits matter:**

- Smaller commits are easier to review and revert
- Reduces risk of losing work
- Keeps working directory clean
- Makes code review possible

**Use `--no-verify` sparingly** - Only for submodule reference updates when hooks fail on non-code changes.

## Quick Navigation

- Work tasks → `Cambium/CLAUDE.md`
- Home tasks → `Phteah-pi/CLAUDE.md`
- AI/orchestration → `Clawdbot/`
- File organization → `FileOrganizer/`
- AutoCAD scripts → `AutoCAD-AHK/`
