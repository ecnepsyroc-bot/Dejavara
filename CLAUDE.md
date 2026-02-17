# Dejavara Platform - AI Context

Master orchestration platform with domains for work and home.

## Platform Overview

**Dejavara** is a personal ecosystem orchestrated by OpenClaw (AI controller).

| Component | Purpose | Details |
|-----------|---------|---------|
| OpenClaw | Central AI controller | Gateway on Pi, node on laptop. See `OpenClaw/CLAUDE.md` |
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
1. OpenClaw (if changed) → commit & push
2. Cambium (if changed) → commit & push
3. Dejavara → commit & push (updates submodule refs)
```

**Why incremental commits matter:**

- Smaller commits are easier to review and revert
- Reduces risk of losing work
- Keeps working directory clean
- Makes code review possible

**Before ending any session, verify all repos are clean:**

```bash
# Run from Dejavara root - checks all submodules
git submodule foreach --recursive "git status --porcelain"
git status --porcelain
```

If anything appears, commit and push it. Do NOT end a session with uncommitted changes.

**Use `--no-verify` sparingly** - Only for submodule reference updates when hooks fail on non-code changes.

## CRITICAL: Keep Infrastructure Docs Current

When making changes to deployed infrastructure (Phteah-Pi, Cambium server, etc.), **always update the corresponding build/inventory docs before reporting completion**.

### Phteah-Pi doc chain (all must stay in sync):
- `Phteah-pi/docs/BUILD.md` — hardware/software inventory of the live Pi
- `Phteah-pi/docs/PORT-REGISTRY.md` — port assignments
- `Phteah-pi/CLAUDE.md` — service list and platform overview
- `Phteah-pi/README.md` — user-facing services table and roadmap

If you add a container, change a port, modify storage, or alter network config — update all affected docs in the same session. Docs that drift from reality are worse than no docs.

## Debugging Approach

When debugging, exhaust source code analysis before asking the user to test anything. You have filesystem access — read the code, trace the execution path, check configs. Only ask the user to intervene for things that require a browser or physical access you genuinely don't have.

## Quick Navigation

- Work tasks → `Cambium/CLAUDE.md`
- Home tasks → `Phteah-pi/CLAUDE.md`
- AI/orchestration → `OpenClaw/`
- File organization → `FileOrganizer/`
- AutoCAD scripts → `AutoCAD-AHK/`
