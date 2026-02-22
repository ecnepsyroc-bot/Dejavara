# Modular Monolith

## What It Is

A modular monolith is a single deployable application organized into well-defined modules with clear boundaries. Unlike a distributed system, everything runs in one process, but unlike a big ball of mud, modules have explicit interfaces and dont reach into each others internals.

## Core Principles (Non-Negotiables)

- **Module boundaries** — Each module has a clear public API
- **Internal encapsulation** — Modules hide implementation details
- **No cross-module database access** — Modules own their tables
- **Explicit dependencies** — Module dependencies are declared and visible
- **Single deployment** — Deploy as one unit (unlike microservices)

## How It Applies to Cambium

### Where We Align (COMMITTED PHILOSOPHY)

Cambium is explicitly a modular monolith. See `docs/ARCHITECTURE.md`.

**Module structure** (`modules/` folder):

```
Cambium.Module.Jobs        - Job lifecycle management
Cambium.Module.Badges      - Sample/badge tracking
Cambium.Module.Purchasing  - POs, vendors, materials
Cambium.Module.Documents   - Document management
Cambium.Module.Inventory   - Laminate inventory
Cambium.Module.Staging     - File staging workflow
Cambium.Module.Chat        - Messaging system
Cambium.Module.Workflow    - Workflow definitions
Cambium.Module.Specifications - GIS specifications
... (12 modules total)
```

**Evidence**:

- Each module has `MODULE.md` documenting boundaries
- Modules define what they **own** vs **reference** (read-only FK)
- Cross-module coordination via orchestrators in `adapters/`

### Where We Dont

- **Shared CambiumDbContext**: Most modules share one DbContext (pragmatic choice due to FKs)
- **Some cross-module entity access**: Migration in progress

### Compliance Desirable?

**Yes — ALREADY COMMITTED.** Shared DbContext is acceptable trade-off for FK integrity.

## Cambium Architectural Context

Two generations of code coexist (see `docs/architecture/CLEAN-ARCHITECTURE-AUDIT.md`):

- **Gen 2 (target)**: The 12 modules listed above are the modular-monolith structure. Each has `MODULE.md` boundaries, Domain/Ports/Adapters, and defined ownership. `Cambium.Module.Staging` has its own `StagingDbContext` — the proof-of-concept for per-module database contexts.
- **Gen 1 (dominant)**: ~44 managers in `Cambium.Core/Managers/` operate outside module boundaries. All share a monolithic `CambiumDbContext` with 80+ `DbSet<>` properties covering all domain areas. This is the primary gap in the modular monolith claim — module boundaries are enforced in code structure but not at the data layer.

When Gen 1 managers are migrated to Gen 2 modules, each module will own its tables explicitly. ADR-0004 documents the plan to pilot `LaminateDbContext` extraction as the next step toward per-module data isolation.

## Key Terms

| Term                       | Definition                                                      |
| -------------------------- | --------------------------------------------------------------- |
| Module                     | Self-contained unit with public interface and private internals |
| Module Boundary            | The public API that other modules can use                       |
| Module Owner               | The tables/entities a module can create/modify                  |
| Cross-Module Communication | How modules interact (events, orchestrators, shared DB)         |
| Orchestrator               | Coordinator that bridges multiple modules                       |
| Bounded Context            | DDD term for a module with its own ubiquitous language          |
| Deployment Monolith        | Single deployable artifact containing all modules               |
