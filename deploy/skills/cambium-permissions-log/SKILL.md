---
name: cambium-permissions-log
description: >
  The Cambium Permissions Log (AUDIT.log) — mandatory tracking of all autonomous
  AI actions and explicit human approvals. Use this skill at the START of every
  Claude Code session (initialize or append to AUDIT.log), whenever taking any
  autonomous action on files (log BEFORE executing), whenever Cory grants explicit
  approval (log immediately as EXPLICIT), and at session end (log SESSION_END).
  Triggers include: AUDIT.log, permissions log, "log this", "what did Claude change",
  YOLO mode actions, session start, verification sessions.
---

# Cambium Permissions Log

AUDIT.log is append-only. It lives at the repository root. Every Claude Code session must initialize it and close it. Every autonomous file action must be logged before execution.

## Format

```
[ISO-8601 timestamp] SESSION_START | Description of session scope
[ISO-8601 timestamp] EXPLICIT      | Cory approved: specific description
[ISO-8601 timestamp] YOLO          | ACTION_TYPE: path/file — reason
[ISO-8601 timestamp] SESSION_END   | N actions, summary of what changed
[ISO-8601 timestamp] PENDING_WORK  | Description — awaiting Cory approval
```

## Action Types

| Type | When to Use |
|------|------------|
| CREATED | New file created |
| MODIFIED | Existing file changed |
| DELETED | File removed |
| MIGRATION | EF Core migration added |
| SCHEMA | Direct database schema change (ALTER TABLE) |
| CONFIG | Configuration file changed (appsettings, env var) |
| SESSION_START | Beginning of a session |
| SESSION_END | End of a session |
| EXPLICIT | Cory verbally approved something |
| PENDING_WORK | Action identified but not yet approved |

## Rules

1. Log BEFORE executing — not after
2. Never edit existing log entries
3. EXPLICIT entries must be logged the moment approval is given, before acting
4. Verification-only sessions: only SESSION_START, SESSION_END, and PENDING_WORK entries
5. If a write to AUDIT.log fails, print the entry to output and flag the failure

## Session Templates

### Verification Session (no code changes)

```
[timestamp] SESSION_START | Verification-only — reading code, no changes
[timestamp] PENDING_WORK  | [N] actions identified — awaiting Cory approval
[timestamp] SESSION_END   | Verification complete, 0 files changed
```

### Implementation Session

```
[timestamp] SESSION_START | Implementing Actions 1-4: auth resilience fixes
[timestamp] EXPLICIT      | Cory approved: Actions 1-4 (auth production fixes)
[timestamp] YOLO          | MODIFIED: src/Cambium.Api/Program.cs — C1: split shared try/catch
[timestamp] YOLO          | MODIFIED: src/Cambium.Api/Program.cs — C4: post-heal schema verification
[timestamp] YOLO          | MODIFIED: src/Cambium.Api/wwwroot/app.js — C2+C3: 500 handling + 401 interceptor
[timestamp] SESSION_END   | 3 files modified, all 4 critical auth fixes applied, 167 tests pass
```

### Skills Session

```
[timestamp] SESSION_START | Skills update — updating 3 existing, creating 3 new
[timestamp] YOLO          | CREATED: skills/cambium-auth-credentials/SKILL.md
[timestamp] SESSION_END   | 6 skill files created, 3 skills updated
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
- Running read-only commands (git log, dotnet build, psql SELECT)
- Producing output/reports in the terminal
