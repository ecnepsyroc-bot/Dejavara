# Dejavara Platform - AI Context

Master orchestration platform with domains for work and home.

## Platform Overview

**Dejavara** is a personal ecosystem orchestrated by OpenClaw (AI controller).

| Component | Purpose | Details |
|-----------|---------|---------|
| OpenClaw | Central AI controller | Claude API-powered assistant |
| Cambium | Work domain | See `Cambium/CLAUDE.md` |
| Phteah-pi | Home domain | See `Phteah-pi/CLAUDE.md` |
| FileOrganizer | Shared utility | File organization across domains |
| AutoCAD-AHK | Shared utility | AutoHotkey scripts for AutoCAD |

## Architecture

```
C:\Dev\
├── Dejavara/           # THIS REPO - master monorepo
│   ├── OpenClaw/       ← AI brain (SUBMODULE)
│   ├── Cambium/        ← Work: millwork factory (SUBMODULE)
│   ├── Phteah-pi/      ← Home: Pi server (SUBMODULE)
│   ├── FileOrganizer/  ← File organization (SUBMODULE)
│   ├── AutoCAD-AHK/    ← AutoCAD scripts (SUBMODULE)
│   ├── deploy/         ← Skills, identity → syncs to Pi
│   └── scripts/        ← Workstation ops scripts
├── AutoCAD-tools/      # Standalone (not submodule)
└── llm-council/        # Standalone (not submodule)
```

## CRITICAL: Prevent Dev Environment Divergence

**DO NOT:**

- Clone Cambium, OpenClaw, or Phteah-pi as standalone repos outside Dejavara
- Create alternate dev roots (`C:\Users\cory\Dev\`, etc.)
- Add circular submodule references (e.g., Cambium containing Dejavara)
- Scatter scripts to `C:\scripts\` or other locations

**ALWAYS:**

- Work within `C:\Dev\Dejavara\{submodule}` for all submodule work
- Push from within submodules, then update Dejavara's ref
- Keep workstation scripts in `C:\Dev\Dejavara\scripts\`

This structure was consolidated on 2026-02-14 after 25+ GB of duplicate repos had drifted apart.

## Domain Boundaries

- **OpenClaw** coordinates across domains but doesn't own domain logic
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
- AI/orchestration → `OpenClaw/`
- File organization → `FileOrganizer/`
- AutoCAD scripts → `AutoCAD-AHK/`
