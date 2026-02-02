# Dejavara Platform Simplification - Implementation Specification

**Version:** 1.0
**Created:** 2026-02-01
**Status:** Phase 1 Complete, Phase 2-4 Pending

---

## Overview

This document provides detailed implementation specifications for simplifying the Dejavara platform codebase.

**Baseline Metrics:**

- Total LOC: ~971,000
- Target LOC: ~900,000 (7% reduction)
- Estimated Effort: 2-4 weeks

---

## Phase 1: Quick Wins [COMPLETE]

### 1.1 Duplicate KFC Agents Removal

**Status:** COMPLETE

**What was done:**

- Deleted `.claude/agents/kfc/` from Cambium (7 files, 1,080 lines)
- Deleted `.claude/agents/kfc/` from Phteah-pi (7 files, 1,080 lines)
- Kept single source of truth at `Dejavara/.claude/agents/kfc/`

**Commits:**

- Cambium: `9059f76`
- Phteah-pi: `27f7fa2`
- Dejavara: `2afd9d9`

### 1.2 System Prompts Centralization

**Status:** COMPLETE

- Deleted `.claude/system-prompts/` from Cambium
- Deleted `.claude/system-prompts/` from Phteah-pi
- Kept single source at `Dejavara/.claude/system-prompts/`

### 1.3 Pre-commit Hook Fix

**Status:** COMPLETE

- Simplified root `.husky/pre-commit` to no-op (linting happens in submodules)
- Cambium retains its own `npx lint-staged` hook

---

## Phase 2: Consolidation [PENDING]

### 2.1 Luxify Project Merges

**Current State:**

```text
Luxify.sln (6 projects)
├── Luxify.Core/         → KEEP (shared utilities)
├── Luxify.Layout/       → KEEP (main plugin, ~8,000 lines)
├── Luxify.Badging/      → MERGE into Layout
├── Luxify.Legends/      → MERGE into Layout
├── Luxify.Styles/       → KEEP (themes, small)
└── Luxify.CuttingBill/  → KEEP (standalone WPF app)
```

**Target State:**

```text
Luxify.sln (4 projects)
├── Luxify.Core/         → Shared utilities
├── Luxify.Layout/       → Main plugin (includes Badging, Legends)
├── Luxify.Styles/       → Theme resources
└── Luxify.CuttingBill/  → Standalone cutting bill app
```

#### 2.1.1 Merge Luxify.Badging → Luxify.Layout

**Files to move:**

```text
Luxify.Badging/
├── BadgeBlockFactory.cs      → Layout/Badging/BadgeBlockFactory.cs
├── BadgingCommands.cs        → Layout/Badging/BadgingCommands.cs
├── BadgeType.cs              → Layout/Badging/BadgeType.cs
└── [other .cs files]         → Layout/Badging/
```

**Steps:**

1. Create `Luxify.Layout/Badging/` folder
2. Move all `.cs` files from `Luxify.Badging/` to `Luxify.Layout/Badging/`
3. Update namespaces from `Luxify.Badging` to `Luxify.Layout.Badging`
4. Remove `Luxify.Badging` project reference from `Luxify.Layout.csproj`
5. Remove `Luxify.Badging` from solution
6. Delete `Luxify.Badging/` folder
7. Update `LuxifyInitializer.cs` CommandClass references
8. Build and verify

**Verification:**

```bash
dotnet build Luxify.Layout/Luxify.Layout.csproj
# Expected: 0 errors
```

#### 2.1.2 Merge Luxify.Legends → Luxify.Layout

**Steps:**

1. Create `Luxify.Layout/Legends/` folder
2. Move all `.cs` files from `Luxify.Legends/` to `Luxify.Layout/Legends/`
3. Update namespaces from `Luxify.Legends` to `Luxify.Layout.Legends`
4. Remove `Luxify.Legends` project reference from `Luxify.Layout.csproj`
5. Remove `Luxify.Legends` from solution
6. Delete `Luxify.Legends/` folder
7. Update `LuxifyInitializer.cs` CommandClass references
8. Build and verify

---

### 2.2 Vitest Configuration Consolidation

**Location:** `Clawdbot/`

**Current State (6 configs):**

```text
vitest.config.ts           → Base config
vitest.unit.config.ts      → Unit tests (duplicate?)
vitest.e2e.config.ts       → End-to-end tests
vitest.extensions.config.ts → Extension tests
vitest.gateway.config.ts   → Gateway tests
vitest.live.config.ts      → Live tests
```

**Target State (3 configs):**

```text
vitest.config.ts           → Base config (unit tests)
vitest.integration.config.ts → E2E + gateway + live
vitest.extensions.config.ts  → Extension tests
```

**Steps:**

1. Audit differences between configs
2. Merge `vitest.e2e.config.ts`, `vitest.gateway.config.ts`, `vitest.live.config.ts` into `vitest.integration.config.ts`
3. Delete redundant `vitest.unit.config.ts` if identical to base
4. Update `package.json` scripts
5. Run all test suites to verify

**Verification:**

```bash
npm run test:unit
npm run test:integration
npm run test:extensions
# All should pass
```

---

### 2.3 Documentation Index

**Create:** `Dejavara/docs/INDEX.md`

**Content:**

```markdown
# Dejavara Platform Documentation Index

## Platform Overview

- [CLAUDE.md](../CLAUDE.md) - AI assistant context

## Domains

### Cambium (Work)

- [CLAUDE.md](../Cambium/CLAUDE.md) - Work domain context
- [Architecture](../Cambium/CLAUDE-ARCHITECTURE.md)
- [Build & Deploy](../Cambium/CLAUDE-BUILD-DEPLOY.md)
- [Troubleshooting](../Cambium/CLAUDE-TROUBLESHOOTING.md)

### Phteah-pi (Home)

- [CLAUDE.md](../Phteah-pi/CLAUDE.md) - Home domain context
- [Development](../Phteah-pi/DEVELOPMENT.md)
- [Port Registry](../Phteah-pi/docs/PORT-REGISTRY.md)

### Clawdbot (AI)

- Located in `Clawdbot/` submodule

## Shared Utilities

- [FileOrganizer](../FileOrganizer/) - File organization CLI
- [AutoCAD-AHK](../AutoCAD-AHK/) - AutoCAD AutoHotkey scripts

## Architecture Decisions

- [Simplification Spec](SIMPLIFICATION-SPEC.md) - This document
```

---

### 2.4 Settings Schema Unification

**Current State:**

| Location | File | Lines | Content |
|----------|------|-------|---------|
| Root | `.claude/settings.local.json` | 9 | Minimal permissions |
| Cambium | `.claude/settings.local.json` | 3,237 | 108 permission rules |
| Phteah-pi | `.claude/settings/kfc-settings.json` | 386 | KFC settings |

**Target:** Create unified permission schema with domain inheritance

**Steps:**

1. Analyze common permissions across all settings files
2. Extract shared permissions to root settings
3. Keep domain-specific permissions in submodule settings
4. Document inheritance rules

---

## Phase 3: Refactoring [PENDING]

### 3.1 Clawdbot BaseMonitor Extraction

**Problem:** 8 nearly identical monitor implementations

**Files affected:**

```text
src/discord/monitor.ts
src/imessage/monitor.ts
src/line/monitor.ts
src/signal/monitor.ts
src/slack/monitor.ts
src/telegram/monitor.ts
src/web/auto-reply/monitor.ts
src/web/inbound/monitor.ts
```

**Solution:** Create `src/monitors/base-monitor.ts`

```typescript
// src/monitors/base-monitor.ts
export abstract class BaseMonitor {
  protected abstract readonly channelName: string;

  // Common message handling loop
  protected async processMessages(): Promise<void> { ... }

  // Standard event emission
  protected emit(event: string, data: unknown): void { ... }

  // Shared filtering logic
  protected shouldProcess(message: Message): boolean { ... }

  // Channel-specific implementations
  abstract connect(): Promise<void>;
  abstract disconnect(): Promise<void>;
  abstract fetchMessages(): Promise<Message[]>;
}
```

**Estimated savings:** 2,000-3,000 lines

---

### 3.2 Large File Splits

#### Clawdbot Files >1000 lines

| File | Lines | Split Strategy |
|------|-------|----------------|
| `telegram/bot.test.ts` | 3,032 | Split by test category |
| `memory/manager.ts` | 2,398 | Split: core, search, sync |
| `extensions/bluebubbles/monitor.ts` | 2,470 | Extract to BaseMonitor |
| `tts/tts.ts` | 1,581 | Split by provider |
| `agents/bash-tools.exec.ts` | 1,572 | Split by command type |
| `infra/exec-approvals.ts` | 1,377 | Split: approvals, workflow |
| `security/audit.ts` + `audit-extra.ts` | 2,051 | Consolidate, then split |

#### Cambium Managers >700 lines

| Manager | Lines | Split Strategy |
|---------|-------|----------------|
| `GisSpecificationsManager` | 1,142 | Split by operation type |
| `DocumentsManager` | 998 | Extract validation, sync |
| `BadgesManager` | 826 | Move to Ramus.Badges |
| `ItemSlotsManager` | 721 | Review for merge opportunity |
| `SyncManager` | 700 | Extract to dedicated service |

---

### 3.3 Barrel Export Reduction

**Problem:** 86 `export *` statements creating dependency chains

**Largest barrel files:**

- `src/gateway/protocol/index.ts` (522 lines)
- `src/plugin-sdk/index.ts` (373 lines)
- `src/plugins/runtime/index.ts` (361 lines)

**Strategy:**

1. Identify consumers of each barrel export
2. Replace `import { x } from './index'` with direct imports
3. Remove or minimize barrel files
4. Use TypeScript path aliases for common patterns

---

### 3.4 DTO Audit

**Problem:** DTOs in 3 locations with potential duplicates

**Locations:**

1. `Cambium.Shared/DTOs/` (288 classes - primary)
2. `Cambium.DocumentManagement/Rami/*/Dtos/`
3. Individual rami folders

**Steps:**

1. Generate list of all DTO classes with file paths
2. Identify duplicates by name
3. Compare for actual code differences
4. Consolidate or document differences

---

## Phase 4: Architecture Decision [FUTURE]

### 4.1 Luxify Architecture vs Monolith

**Current Reality:**

- Code claims "Luxify Architecture" with rami/grafts
- Actual implementation is monolithic (45 managers in Core)
- 8 active rami, 5 placeholder specs

**Options:**

**Option A: Commit to Luxify**

- Migrate Core managers to rami
- Each ramus becomes self-contained
- Effort: High (2-4 months)
- Risk: Major refactoring

**Option B: Abandon Luxify**

- Delete .ramus.md placeholder specs
- Document as intentional monolith
- Keep existing rami that are working
- Effort: Low (1-2 days)
- Risk: Low

**Recommendation:** Option B for now, revisit when team capacity allows

---

## Verification Checklist

After each phase:

- [ ] All projects build with 0 errors
- [ ] All test suites pass
- [ ] Manual smoke test of key features
- [ ] Git history is clean (incremental commits)
- [ ] Documentation updated
- [ ] Plan file updated with completion status

---

## File Paths Reference

### Luxify Projects

```text
c:\Dev\Dejavara\Cambium\AutoCAD-Tools\Luxify\
├── Luxify.sln
├── Luxify.Core\Luxify.Core.csproj
├── Luxify.Layout\Luxify.Layout.csproj
├── Luxify.Badging\Luxify.Badging.csproj
├── Luxify.Legends\Luxify.Legends.csproj
├── Luxify.Styles\Luxify.Styles.csproj
└── Luxify.CuttingBill\Luxify.CuttingBill.csproj
```

### Clawdbot Monitors

```text
c:\Dev\Dejavara\Clawdbot\src\
├── discord\monitor.ts
├── imessage\monitor.ts
├── line\monitor.ts
├── signal\monitor.ts
├── slack\monitor.ts
├── telegram\monitor.ts
└── web\
    ├── auto-reply\monitor.ts
    └── inbound\monitor.ts
```

### Settings Files

```text
c:\Dev\Dejavara\.claude\settings.local.json
c:\Dev\Dejavara\Cambium\.claude\settings.local.json
c:\Dev\Dejavara\Phteah-pi\.claude\settings\kfc-settings.json
```
