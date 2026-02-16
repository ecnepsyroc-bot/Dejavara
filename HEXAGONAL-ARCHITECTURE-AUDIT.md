# DEJAVARA HEXAGONAL ARCHITECTURE AUDIT
**Comprehensive Assessment Report**
**Date**: 2026-02-16
**Auditor**: Claude Sonnet 4.5
**Scope**: Full Dejavara platform (OpenClaw, Cambium, Phteah-pi, FileOrganizer, AutoCAD-AHK)

## Executive Summary

The Dejavara platform demonstrates **strong architectural principles** with clear separation of concerns and deliberate hexagonal (ports & adapters) patterns. However, there are **significant gaps in application across components**, inconsistent layer enforcement, and emerging anti-patterns that require attention.

**Overall Assessment: 7/10** — Good foundation, but inconsistent implementation and emerging debt.

---

## 1. CAMBIUM (Work Domain) — 8/10

### ✅ EXCELLENT PATTERNS FOUND

#### **Port & Adapter Excellence**
Cambium has the most mature hexagonal implementation in the platform:

- **Clear Port Interfaces**: Every capability is exposed through interfaces (IBadgesManager, IChatManager, IJobsManager, etc.)
  - Location: `src/Cambium.Core/Managers/I*.cs`
  - Pattern: Core defines interfaces; API layer injects implementations

- **Orchestrator/Adapter Pattern**: Deliberately implemented cross-module communication
  - Location: `adapters/` directory with 6+ documented adapters
  - Examples:
    - `Cambium.Adapter.JobToChat`: Bridges job lifecycle → chat broadcasts
    - `Cambium.Adapter.FlagToOverlay`: Badges → AutoCAD overlays
    - `Cambium.Adapter.SpecToMaster`: Specs → Master drawing updates
  - Each has `.adapter.md` documentation defining connections

- **Architecture Documentation**: CLAUDE-ARCHITECTURE.md explicitly prohibits cross-module imports and requires adapters
  ```
  Rule: "Modules do NOT import from other modules — ever"
  Enforcement: Adapter pattern mandatory for cross-module communication
  ```

#### **Clean Layer Separation**
```
Cambium.Api (ASP.NET Controllers)
    ↓ depends on ↓
Cambium.Core (Domain logic, Managers, Services)
    ↓ depends on ↓
Cambium.Data (EF Core DbContext, Repositories)
    ↓ depends on ↓
Cambium.Shared (DTOs, Interfaces)
```
- **Dependencies flow downward only** ✓
- **Minimal reverse dependencies** ✓
- **Domain logic isolated from infrastructure** ✓

#### **Service Layer Design**
- **HybridAiService** (src/Cambium.Core/Services/AI/):
  - Clear interface: `IHybridAiService`
  - Implements "rules-first, LLM-fallback" pattern
  - Depends on abstractions: `IRuleBasedShorthandGenerator`, `IClaudeService`, `IAiValidationService`
  - Domain logic pure (no HTTP, no DB access in service itself)

#### **Repository Pattern**
- `ChatRepository` implements `IChatRepository`
- Properly abstracts EF Core operations
- Used by managers, not directly by API

### ❌ VIOLATIONS & ARCHITECTURAL DEBT

#### **1. Layering Violations in API Controllers**
- **BadgesController** directly injects managers AND multiple cross-cutting dependencies:
  ```csharp
  public BadgesController(
      IBadgesManager badgesManager,        // ✓ correct
      ISpecParserService specParserService,
      IHybridAiService hybridAiService,
      IFinishMatchValidatorService finishValidator,
      ICommandBridgeClient bridge,        // ❌ infrastructure leak
      ILogger<BadgesController> logger)
  ```
  **Problem**: Controller is orchestrating AI, validation, AND bridge operations. Should delegate to a use-case service.

#### **2. Adapter Dependency in Api Layer**
- **Program.cs** registers `Cambium.Adapter.JobToChat`, `Cambium.Adapter.StagingToProduction` directly in API
- Controllers call adapters directly:
  ```csharp
  // In JobsController
  await _jobToChatOrchestrator.OnJobCreatedAsync(jobId, jobName);
  ```
  **Problem**: Controllers shouldn't know about adapters. Adapters should be invoked by domain events, not direct calls.

#### **3. Insufficient Event-Driven Coordination**
- **Current State**: Controllers directly call orchestrators
- **Better State**: Domain events fire → Event handlers → Orchestrators invoke
- Event schema exists (`event-schema/Cambium.EventSchema.Contracts`) but underutilized
- Many cross-module triggers are imperative (direct calls) rather than event-driven

#### **4. Shared Layer Creep**
- `Cambium.Shared` contains DTOs, Interfaces, and Config
- Growing risk of becoming a "grab-bag" shared folder
- Should distinguish: **Contract interfaces** (belong in adapters) vs **DTOs** (belong in Api)

#### **5. Early-Stage Module Incompleteness**
- Only 2 formal modules exist:
  - `Cambium.Courier` (external integration)
  - `Cambium.Module.Inventory` (laminate tracking)
- Remaining features (Badges, Chat, Jobs, etc.) in `src/Cambium.Core` — not yet modularized
- Modules **are planned** (see archived module specs) but not yet migrated

#### **6. Missing Application/Use-Case Layer**
- **Current**: Manager → Domain → Repo
- **Missing**: Use-case services that orchestrate managers
  - Example: "CreateBadgeForJob" use case should:
    1. Validate job exists
    2. Create badge
    3. Fire `BadgeCreated` event
    4. Let orchestrators handle chat/autocad updates
  - **Instead**: Controllers directly inject managers and orchestrators

### 🔄 REFACTORING OPPORTUNITIES

| Issue | Priority | Effort | Benefit |
|-------|----------|--------|---------|
| Extract use-case services from controllers | High | Medium | Cleaner separation, testability |
| Event-driven orchestrator invocation | High | Medium | Loose coupling, scalability |
| Finish module migration (Badges, Chat, Jobs) | Medium | High | Enforced isolation, future safety |
| Separate adapter interfaces from shared | Low | Low | Clarity, prevents circular deps |

---

## 2. OPENCLAW (AI Controller) — 6/10

### ✅ PATTERNS FOUND

#### **ACP Protocol Abstraction**
- `src/acp/` implements Agent Control Protocol
- Clean type definitions: `AcpSession`, `AcpServerOptions`, `AcpClientHandle`
- Port-like abstraction over SDK:
  ```typescript
  export type AcpClientHandle = {
    client: ClientSideConnection;    // SDK abstraction
    agent: ChildProcess;             // Process adapter
    sessionId: string;               // Protocol contract
  };
  ```

#### **Infrastructure Isolation**
- `src/infra/` contains OS-level operations (ports, env, binaries, warnings)
- `src/gateway/` handles server protocol
- `src/agents/` manages agent lifecycle
- Clear folder organization by concern

#### **CLI Abstraction**
- `src/cli/` provides command interface
- Dependency injection via `createDefaultDeps()`
- Config isolation in `src/config/`

### ❌ VIOLATIONS & ARCHITECTURAL DEBT

#### **1. Domain Logic Scattered Across Layers**
- **Session management** mixed between:
  - `src/acp/session.ts` (session model)
  - `src/config/sessions.ts` (persistence)
  - `src/gateway/server-session-key.ts` (routing)
  - `src/routing/session-key.ts` (parsing)
- **No single source of truth** for session domain model

#### **2. Weak Port Definition**
- Few explicit "port" interfaces
- Most integration is **direct dependency on SDK types**:
  ```typescript
  import { ClientSideConnection } from "@agentclientprotocol/sdk";
  import { ndJsonStream } from "@agentclientprotocol/sdk";
  ```
- If SDK changes, massive refactor needed across codebase
- **Should**: Define `ISessionTransport`, `IProtocolConnection` ports

#### **3. Infrastructure Concerns in Domain**
- **agent-scope.ts** (agent resolution):
  ```typescript
  import path from "node:path";
  import os from "node:os";

  export function resolveAgentIdFromSessionKey(key: string) { ... }
  ```
  - Mixing file paths with domain logic
  - Config resolution is environment-aware, not testable

- **auth-profiles/** folder mixes:
  - Domain logic (auth profile resolution)
  - Infrastructure (OAuth, token storage)
  - No adapter for auth system

#### **4. Event-Driven, But Without Clear Events**
- Heavy use of event handlers in `src/agents/` and `src/channels/`
- **No centralized event schema** like Cambium's
- Hard to trace event flows:
  - What events are emitted?
  - What handlers exist?
  - What's the order?

#### **5. Gateway Server Complexity**
- `src/gateway/server.ts` and related files (100+ files in gateway/)
- Monolithic server handling:
  - Protocol negotiation
  - Session management
  - Agent routing
  - Chat streaming
  - WebSocket bridging
  - Browser relay
- **No clear subdivision** of responsibilities
- Hard to add new gateway features without cascading changes

#### **6. Testing Isolation Issues**
- `src/agents/test-helpers/` provides test utilities
- But production code imports from test utilities:
  ```typescript
  import { ... } from "../test-helpers/...";
  ```
  ❌ **Anti-pattern**: Test code should never be imported by production

#### **7. Unused/Incomplete Layers**
- `src/canvas-host/` — unclear purpose
- `src/compat/` — compatibility layer with no clear contracts
- `src/commands/` — command definitions scattered
- **Missing**: Clear application layer / use-case service layer

### 🔄 REFACTORING OPPORTUNITIES

| Issue | Priority | Effort | Benefit |
|-------|----------|--------|---------|
| Define protocol ports (ISessionTransport, IProtocolHandler) | High | High | SDK-agnostic, testable |
| Consolidate session domain model | High | Medium | Single source of truth |
| Extract application layer for agent operations | Medium | High | Clear use cases, testability |
| Centralize event schema & routing | Medium | Medium | Visibility, debugging |
| Decompose gateway server | Low | Very High | But valuable long-term |

---

## 3. PHTEAH-PI (Home Infrastructure) — 5/10

### ✅ PATTERNS FOUND

#### **Clear Service Abstraction**
- `services/` directory with distinct concerns:
  - proxy/ (Traefik)
  - dns/ (Pi-hole)
  - vpn/ (WireGuard)
  - automation/ (Home Assistant)
  - media/ (Jellyfin)

#### **Infrastructure Documentation**
- `docs/BUILD.md` — inventory of deployed state
- `docs/PORT-REGISTRY.md` — port assignments
- `CLAUDE.md` — service overview
- **Doctrine**: Keep docs in sync with reality

#### **Docker Compose Orchestration**
- Centralized in `docker-compose.yml`
- Health checks defined
- Volume management explicit

### ❌ VIOLATIONS & ARCHITECTURAL DEBT

#### **1. Configuration Sprawl**
- Services defined in:
  - `docker-compose.yml` (Docker services)
  - `.env` file (environment variables)
  - Service-specific YAML files (some services)
  - `justfile` (operational commands)
- **No unified configuration schema**
- Hard to understand full state at a glance

#### **2. No Clear Adapter for Cambium Integration**
- Cambium API deployed as native service on Pi
- No documented interface contract
- Integration with other services (OpenClaw, Syncthing) unclear
- **Should**: Define port interfaces for Cambium API, define service contracts

#### **3. Infrastructure as Implicit Code**
- Operational knowledge in `justfile` and README
- No formal "port" definitions for Pi capabilities
- Services treated as black boxes (deploy them, check health)
- **Missing**: Port interfaces like `IBackupService`, `IDnsService`, `IStorageManager`

#### **4. No Application Layer**
- Services exist but no orchestration layer
- Manual operational commands (just start, just logs)
- No programmatic health checks beyond docker health
- **Missing**: An application service layer that could be called by other components

### 🔄 REFACTORING OPPORTUNITIES

| Issue | Priority | Effort | Benefit |
|-------|----------|--------|---------|
| Centralized service configuration schema | Medium | Medium | Clarity, discoverability |
| Define service contracts/ports | Low | Medium | Future integration |
| Extract health check aggregator | Low | Low | Better observability |

---

## 4. FILE ORGANIZER — 7/10

### ✅ PATTERNS FOUND

#### **Clear Architectural Intent**
- Documentation explicitly defines boundaries:
  ```
  src/
  └── FolderOrganizer.Cli/
      ├── Commands/            # CLI handlers
      ├── Rules/               # Rule definitions & matching
      └── FileSystem/          # File I/O operations
  ```

#### **Logical Separation**
- Rules produce **actions** (not side effects)
- FileSystem layer handles I/O
- CLI orchestrates but doesn't contain logic

### ❌ VIOLATIONS & ARCHITECTURAL DEBT

#### **1. Minimal Implementation**
- Only `Program.cs` exists with "Hello, World!"
- No actual domain logic implemented
- Can't assess real patterns until implementation starts

#### **2. Missing Test Layer**
- No tests found
- Hard to verify boundaries without tests

### 🔄 REFACTORING OPPORTUNITIES

| Issue | Priority | Effort | Benefit |
|-------|----------|--------|---------|
| Implement domain layer with interfaces | High | Medium | Establish patterns early |
| Add unit tests around rule matching | High | Medium | Verify boundaries |

---

## 5. AUTOCAD-AHK (AutoHotkey Scripts) — N/A

### ✅ PATTERNS FOUND
- Two simple scripts: `AutoPan.ahk`, `StickyPan.ahk`
- Pure utility code (no architecture to audit)
- No domain logic

### ⚠️ OBSERVATIONS
- Not part of hexagonal architecture audit (utility scripts)
- Properly isolated from main platform

---

## 6. CROSS-PLATFORM ARCHITECTURE ANALYSIS

### Dependency Flow (should point inward)

```
CAMBIUM:
  ✓ Api → Core → Data → Shared
  ✓ Adapters → Modules (via ports only)
  ✗ Controllers → Adapters directly (should be event-driven)

OPENCLAW:
  ✓ CLI → Config → Infra
  ✓ Agents → Gateway
  ✗ Domain mixed with Infrastructure (sessions, auth)
  ✗ Test utilities imported by production code

PHTEAH-PI:
  ✓ Services logically separated
  ✗ No programmatic ports / contracts
  ✗ Configuration implicit in docker-compose + env + just commands

FILE ORGANIZER:
  ✓ Intended architecture clear
  ✗ Not yet implemented
```

### Port Definition Maturity

| Component | Explicit Interfaces | Domain-Specific | Infrastructure-Agnostic |
|-----------|---------------------|-----------------|------------------------|
| **Cambium** | ✓✓ Excellent (40+ manager interfaces) | ✓ Good | ⚠️ Partial (Services okay, Controllers weak) |
| **OpenClaw** | ⚠️ Some | ⚠️ Mixed | ✗ Weak (SDK types leak everywhere) |
| **Phteah-Pi** | ✗ None | ✗ None | ✗ None |
| **FileOrganizer** | ⚠️ Planned | ⚠️ Planned | ⚠️ Planned |

---

## CRITICAL ISSUES

### 1. **Test Code in Production** (OpenClaw) ✅ **FIXED 2026-02-16**

~~Production code imported test-helpers from src/ directory~~
```typescript
// BEFORE (anti-pattern):
// src/agents/test-helpers/index.ts
export function createTestAgent() { ... }

// src/agents/something.ts
import { createTestAgent } from '../test-helpers';  // ❌ WRONG
```

**RESOLUTION** (commit 26e9ffcec):
- Moved all test-helpers from `src/` to `tests/helpers/`
- Updated 88 import paths in .test.ts files
- Test utilities now in dedicated test infrastructure directory
- Production code cannot import test utilities

### 2. **Adapter-Aware Controllers** (Cambium) ✅ **FIXED 2026-02-16**

~~Controllers called adapters directly instead of emitting domain events~~

**RESOLUTION** (commit 22d1bf7 in Cambium):

- Extracted JobsController to event-driven use cases (Create, Rename, Archive, Delete)
- Removed IJobToChatOrchestrator dependency from controller
- Event handlers now subscribe to domain events and invoke orchestrators
- Clean separation: Controller → UseCase → Manager + EventBus → Handler → Orchestrator

**Previous pattern:**
```
Controller → Use Case Service → Manager + Event Emitter
                                    ↓
                            Event Handler → Adapter
```

### 3. **Scattered Session/Auth Domain** (OpenClaw)
Session model defined in 4+ places. Consolidate into single domain model with clear ports.

### 4. **No Application Layer** (All Components)

- Cambium: ~~Missing use-case services~~ **Partially addressed** - Jobs domain has use cases (CreateJob, RenameJob, etc.), other domains (Badges, Chat) still need extraction
- OpenClaw: Missing agent operation services
- Phteah-Pi: Missing orchestration service
- File Organizer: Not yet implemented

**Pattern**: Domain → Application → Infrastructure should exist in all components.

---

## RECOMMENDATIONS (Priority Order)

### IMMEDIATE (1-2 weeks)
1. **Cambium**: Remove test code from production imports
2. **Cambium**: Extract application/use-case layer (CreateJobUseCase, UpdateBadgeUseCase, etc.)
3. **OpenClaw**: Move test helpers to separate directory
4. **OpenClaw**: Consolidate session domain model

### SHORT TERM (1-2 months)
5. **Cambium**: Event-driven orchestrator invocation (don't call adapters directly from controllers)
6. **OpenClaw**: Define protocol ports (ISessionTransport, IProtocolHandler)
7. **OpenClaw**: Separate auth domain from infrastructure (create IAuthService port)
8. **Phteah-Pi**: Define service contracts (IBackupService, IHealthCheckService, etc.)

### MEDIUM TERM (2-3 months)
9. **Cambium**: Migrate Chat, Jobs, Badges to formal modules
10. **OpenClaw**: Decompose gateway server (separate concerns)
11. **File Organizer**: Implement domain layer with proper ports

### LONG TERM (3+ months)
12. **OpenClaw**: Centralize event schema (like Cambium)
13. **Phteah-Pi**: Extract application orchestration layer
14. **All**: Cross-platform port registry (document all external integrations)

---

## BEST PRACTICES TO ESTABLISH

### For All Components

1. **Layer Enforcement**
   ```
   Domain     (pure business logic, no imports from layers below)
      ↑
   Application (use cases, orchestration, pure functions)
      ↑
   Infrastructure (DB, HTTP, file system, external services)
   ```

2. **Port Definition**
   ```typescript
   // In domain layer
   export interface IUserRepository {
     getById(id: string): Promise<User>;
   }

   // Infrastructure layer implements
   export class PostgresUserRepository implements IUserRepository { ... }
   ```

3. **Event-Driven Cross-Module Communication**
   ```csharp
   // Module A publishes
   await eventBus.PublishAsync(new UserCreatedEvent { ... });

   // Module B subscribes (via adapter)
   public class UserCreatedHandler : IEventHandler<UserCreatedEvent>
   {
       public async Task HandleAsync(UserCreatedEvent @event) { ... }
   }
   ```

4. **Test Isolation**
   - Test utilities in `src/__tests__/` or `tests/` directory
   - Never importable from production code
   - Use dependency injection for testability

---

## FILE PATHS FOR KEY ARCHITECTURE PATTERNS

### Cambium (Exemplar Patterns)
- **Adapters**: `Cambium/adapters/`
- **Manager Interfaces**: `Cambium/src/Cambium.Core/Managers/I*.cs`
- **Architecture Doc**: `Cambium/CLAUDE-ARCHITECTURE.md`
- **Adapter Documentation**: `Cambium/adapters/ORCHESTRATOR.md`

### OpenClaw (Mixed Patterns)
- **ACP Protocol Abstraction**: `OpenClaw/src/acp/`
- **Infrastructure Layer**: `OpenClaw/src/infra/`
- **Gateway Server**: `OpenClaw/src/gateway/`
- **Session Management** (scattered):
  - `OpenClaw/src/acp/session.ts`
  - `OpenClaw/src/config/sessions.ts`
  - `OpenClaw/src/routing/session-key.ts`

### Phteah-Pi (Docker Composition)
- **Service Definitions**: `Phteah-pi/docker-compose.yml`
- **Service Docs**: `Phteah-pi/services/`
- **Orchestration**: `Phteah-pi/justfile`

---

## CONCLUSION

**Dejavara has excellent architectural intentions** with clear separation of concerns, well-documented patterns (especially in Cambium), and deliberate port/adapter usage. However, **execution is inconsistent across components**:

- **Cambium** ✓ Strong foundation, minor violations (adapters in controllers)
- **OpenClaw** ⚠️ Good infrastructure layer, weak port definitions, scattered domain logic
- **Phteah-Pi** ⚠️ Clear service separation, but no programmatic ports
- **FileOrganizer** ✓ Clear architectural intent, not yet implemented

**Key gap**: No component has a fully realized Application/Use-Case layer. All jump from Domain directly to API/CLI.

**Recommendation**: Use Cambium's adapter pattern as the model, address the immediate issues (test code, scattered domain logic), and incrementally build out proper use-case layers and explicit port definitions across all components.

---

**Next Steps**:
1. Review this audit with the team
2. Prioritize issues based on impact and effort
3. Create tracking tasks for each recommendation
4. Establish architecture review process for future changes
5. Update CLAUDE.md files in each component with architectural guidelines
