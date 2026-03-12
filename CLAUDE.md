# Dejavara Platform - AI Context

Master orchestration platform with domains for work and home.

## Platform Overview

**Dejavara** is a personal ecosystem orchestrated by OpenClaw (AI controller).

| Component | Purpose | Details |
|-----------|---------|---------|
| OpenClaw | Central AI controller | Gateway on Pi, node on laptop. See `OpenClaw/CLAUDE.md` |
| Cambium | Work domain | See `Cambium/CLAUDE.md` |
| Phteah-pi | Home domain | See `Phteah-pi/CLAUDE.md` |
| AutoCAD-AHK | Shared utility | AutoHotkey scripts for AutoCAD |

## Architecture

```
C:\Dev\
├── Dejavara/           # THIS REPO - master monorepo
│   ├── OpenClaw/       ← AI brain (SUBMODULE)
│   ├── Cambium/        ← Work: millwork factory (SUBMODULE)
│   ├── Phteah-pi/      ← Home: Pi server (SUBMODULE)
│   ├── AutoCAD-AHK/    ← AutoCAD scripts (SUBMODULE)
│   ├── deploy/         ← Skills, identity → syncs to Pi
│   └── scripts/        ← Workstation ops scripts
└── llm-council/        # Standalone (not submodule)
```

## CRITICAL: Prevent Dev Environment Divergence

### ABSOLUTE RULE: No Standalone Clones

**Submodules exist ONLY inside `C:\Dev\Dejavara\`.** There is no other option.

```
VALID:   C:\Dev\Dejavara\Cambium\
INVALID: C:\Users\cory\repos\Cambium\      ← NEVER
INVALID: C:\Users\cory\Dev\Dejavara\       ← NEVER
INVALID: C:\Cambium\                        ← NEVER
INVALID: Anywhere else                      ← NEVER
```

**If a submodule breaks, FIX IT. Do not clone fresh somewhere else.**

```bash
# Submodule broken? Run this:
cd C:\Dev\Dejavara
git submodule update --init --remote Cambium
cd Cambium
git checkout main
git pull
```

That's the fix. Not `git clone`. Never `git clone` for submodules.

### Why This Rule Exists

On 2026-02-14, we cleaned up 25+ GB of duplicate repos that had drifted apart.
On 2026-03-11, we cleaned up AGAIN because a standalone clone appeared at `C:\Users\cory\repos\Cambium`.

The pattern: submodule breaks → someone clones fresh as "workaround" → work accumulates there → drift → cleanup. This cycle ends now.

### Blocked Actions

- Clone Cambium, OpenClaw, Phteah-pi, or AutoCAD-Tools outside Dejavara
- Create alternate dev roots (`C:\Users\cory\Dev\`, `C:\Users\cory\repos\`, etc.)
- Add circular submodule references
- Scatter scripts outside `C:\Dev\Dejavara\scripts\`

### Required Actions

- Work within `C:\Dev\Dejavara\{submodule}` for ALL submodule work
- Push from within submodules, then update Dejavara's ref
- If submodule breaks, fix it in place — see commands above

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

## Plan Review Gate (Adversarial Code Review Pattern)

No implementation plan executes without external review. This is based on the Adversarial Code Review pattern — a distinct AI session reviews artifacts produced by the builder session, breaking the "echo chamber" where a model validates its own output.

**Why this exists:** A model that confidently generates flawed code will confidently assert that the code is correct. Self-review doesn't catch blind spots because the same reasoning that produced the problem will miss it on review. A separate session with no access to the builder's reasoning process evaluates only the artifacts — the plan, the file list, the architecture decisions.

### The Process

1. Claude Code generates a plan and saves it to `.claude/plans/`
2. User copies the plan to Claude.ai for adversarial review
3. Claude.ai reviews against: hexagonal architecture rules, coupling risks, missing edge cases, sequence of operations, and whether the plan creates walls to tear down later
4. User brings corrections back to Claude Code, plan is revised
5. Repeat until Claude.ai approves
6. Only then does Claude Code begin implementation

This is the ASSUMED/CERTIFIED frame applied to planning. A plan generated by Claude Code is ASSUMED correct. It becomes CERTIFIED only after external review confirms it.

### When to Use the Gate

**ALWAYS use for:**
- Architecture changes (new modules, sync infrastructure, database schema)
- Cross-module modifications (anything touching 3+ files across domain boundaries)
- New background services or middleware
- Anything involving data integrity (sequences, sync, backups, migrations)
- Plans with more than 3 phases or 10+ files

**SKIP for:**
- Single-file bug fixes with obvious cause and solution
- CSS/UI-only changes with no logic
- Documentation-only updates
- Config value changes (env vars, connection strings)
- Anything you could verify correctness of in under 2 minutes

The overhead is ~10 minutes per review. On multi-day implementation work, that's noise. On a typo fix, it's waste. Use judgment.

### Reminders for Claude Code

When generating plans, always end with: "This plan is ready for external review before execution. Copy to Claude.ai for adversarial review."

Do not ask to skip this step. Do not treat "looks good to me" from the user as a substitute — the user needs to actually send it for review.

If the user says "just do it" without having reviewed externally, push back once: "This plan hasn't been through the review gate yet. It touches [N files / architecture / data integrity] — worth 10 minutes of review?"

If the user overrides after the pushback, proceed. The gate is a guardrail, not a prison.

**Effective:** 2026-03-10

## CRITICAL: Keep Infrastructure Docs Current

When making changes to deployed infrastructure (Phteah-Pi, Cambium server, etc.), **always update the corresponding build/inventory docs before reporting completion**.

### Phteah-Pi doc chain (all must stay in sync):
- `Phteah-pi/docs/BUILD.md` — hardware/software inventory of the live Pi
- `Phteah-pi/docs/PORT-REGISTRY.md` — port assignments
- `Phteah-pi/CLAUDE.md` — service list and platform overview
- `Phteah-pi/README.md` — user-facing services table and roadmap

If you add a container, change a port, modify storage, or alter network config — update all affected docs in the same session. Docs that drift from reality are worse than no docs.

### Cambium Shop Server (cambium-server) — DEPRECATED
- Windows 10 at 192.168.0.108, accessible via Chrome Remote Desktop
- CambiumApi on DEJAVARA serves the shop floor (localhost:5001 → Cloudflare tunnel). cambium-server is not needed as an API host.
- Has stale CambiumApi service (disabled, DI bug). Treat as dead unless explicitly revived.
- If repurposed in future, needs full rebuild from Dejavara monorepo — current directory layout is diverged.

## Debugging Approach

When debugging, exhaust source code analysis before asking the user to test anything. You have filesystem access — read the code, trace the execution path, check configs. Only ask the user to intervene for things that require a browser or physical access you genuinely don't have.

## Quick Navigation

- Work tasks → `Cambium/CLAUDE.md`
- Home tasks → `Phteah-pi/CLAUDE.md`
- AI/orchestration → `OpenClaw/`
- File organization → `FileOrganizer/`
- AutoCAD scripts → `AutoCAD-AHK/`
