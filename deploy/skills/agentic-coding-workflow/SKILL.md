---
name: agentic-coding-workflow
description: >
  Development workflow discipline for Cambium AI-assisted coding sessions.
  Use at the START of every Claude Code session and when taking any autonomous
  actions. Covers: AUDIT.log permissions tracking, verification-before-implementation
  protocol, multi-model workflow (Claude.ai + Claude Code), pre-Railway-push gate,
  and session end protocol. Triggers include: session start, YOLO mode, autonomous
  actions, "log this", verification session, Railway push preparation, session end.
---

# Agentic Coding Workflow

Mandatory protocols for AI-assisted Cambium development sessions. Initialize or append to AUDIT.log before starting any session.

## Permissions Log Protocol

Every autonomous action (YOLO mode) must be logged to `AUDIT.log` BEFORE execution. Every explicit approval from Cory must be logged immediately as EXPLICIT.

```
Format:
[ISO-8601 timestamp] YOLO    | ACTION_TYPE: path — reason
[ISO-8601 timestamp] EXPLICIT | Cory approved: description

Action types: CREATED | MODIFIED | DELETED | MIGRATION | SCHEMA | CONFIG

Session bookends:
[ISO-8601 timestamp] SESSION_START | Description of session scope
[ISO-8601 timestamp] SESSION_END   | N actions taken, N CRITICAL findings, summary
```

Create `AUDIT.log` at repo root if it doesn't exist. It is **append-only**. Never edit existing entries.

See `cambium-permissions-log` skill for full format specification, templates, and rules.

## Verification-Before-Implementation Protocol

For any session involving production systems:

1. **Read code first** — run the verification prompt (read code, don't change code)
2. **Produce the work plan** with explicit approval checkpoints
3. **Get Cory's approval** on the plan before touching files
4. **Log the approval** as EXPLICIT before each action

```
[timestamp] SESSION_START | Verification-only — reading code, no changes
[timestamp] PENDING_WORK  | [N] actions identified — awaiting Cory approval
[timestamp] SESSION_END   | Verification complete, 0 files changed
```

## Multi-Model Workflow

```
Claude.ai (chat)    = Strategic advisor, spec reviewer, plan synthesizer
Claude Code (terminal) = Implementer, code reader, file creator

Pattern:
1. Claude.ai writes/reviews specs
2. Claude Code implements from specs
3. Claude.ai reviews output
4. Neither makes production changes without explicit Cory approval
```

## Pre-Railway-Push Gate

**Never push to main without completing ALL of these:**

1. Run `scripts/check-railway-schema.sql` against Railway
   ```bash
   psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql
   ```
2. Confirm critical tables are clean (`users`, `factory_orders`, `jobs`, `laminates`)
3. Build passing with 0 errors (22 pre-existing MSB3277 warnings are acceptable)
4. 167 tests passing
   ```bash
   dotnet build Cambium/Root.sln && dotnet test Cambium/tests/Cambium.Tests.Unit
   ```

## Session End Protocol

```bash
# 1. Verify build
dotnet build Cambium/Root.sln && dotnet test Cambium/tests/Cambium.Tests.Unit

# 2. Commit (conventional commits)
git add <specific files>
git commit -m "type(scope): description"

# 3. Pre-push Railway gate (if pushing to main)
psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql
# Confirm all critical tables clean before proceeding

# 4. Push
git pull --rebase origin main
git push origin main

# 5. Verify Railway deployment
# Watch logs for startup errors
# Confirm login at cambium.luxifysystems.com

# 6. Close AUDIT.log session
# Append: [timestamp] SESSION_END | Session complete, N files changed
```

## What Counts as an Autonomous Action

**Must be logged:**
- Creating any file
- Modifying any existing file
- Deleting any file
- Running any database command (ALTER TABLE, INSERT, UPDATE, DELETE)
- Changing any configuration

**Does NOT need to be logged:**
- Reading files
- Running read-only commands (`git log`, `dotnet build`, `psql SELECT`)
- Producing output/reports in the terminal
