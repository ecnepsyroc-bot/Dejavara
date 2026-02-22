# Strangler Fig Pattern

## What It Is

The Strangler Fig Pattern gradually replaces a legacy system by building new functionality alongside it. Like the strangler fig tree that grows around its host, the new system slowly takes over until the old one can be removed. Its a safe way to modernize without big-bang rewrites.

## Core Principles (Non-Negotiables)

- **Incremental migration** — Replace piece by piece, not all at once
- **Side-by-side operation** — Old and new coexist during transition
- **Facade/router** — Direct traffic to old or new as appropriate
- **Reversible** — Can fall back to old system if needed
- **No big bang** — Never attempt full rewrites

## How It Applies to Cambium

### Where We Align (ACTIVELY PRACTICING)

Cambium is using Strangler Fig for module migration:

**Current state**:

- Legacy managers in `src/Cambium.Core/Managers/`
- New modules in `modules/Cambium.Module.*/`
- Both coexist during migration

**Pattern in action** (from `docs/MODULE-MIGRATION-PATTERN.md`):

```csharp
// New service implements BOTH interfaces
public class BadgeService : IBadgeService, IBadgesManager
{
    // Implements new module interface
    // AND legacy manager interface for compatibility
}

// DI wires to same instance
services.AddScoped<IBadgeService>(sp => sp.GetRequiredService<BadgeService>());
services.AddScoped<IBadgesManager>(sp => sp.GetRequiredService<BadgeService>());
```

**Progress**:

- ~12 modules created
- ~44 managers still in Core awaiting migration
- Gradual replacement in progress

### Where We Dont

- Following the pattern well!

### Compliance Desirable?

**Yes — ALREADY PRACTICING.** Continue per `docs/MODULE-MIGRATION-PATTERN.md`.

## Cambium Architectural Context

The Strangler Fig pattern is the mechanism for Cambium's Gen 1 -> Gen 2 migration (see `docs/architecture/CLEAN-ARCHITECTURE-AUDIT.md`):

- **Gen 1 (host tree)**: ~44 managers in `Cambium.Core/Managers/` — direct `CambiumDbContext` injection, no ports, no domain isolation. This is the legacy system being strangled.
- **Gen 2 (strangler fig)**: 12 modules in `modules/Cambium.Module.*/` — hexagonal architecture with Domain/Ports/Adapters. This is the replacement growing alongside Gen 1.
- **Dual-interface facade**: The migration pattern uses `FooService : IFooService, IFooManager` — the new service implements both the module interface and the legacy manager interface. This is the "facade/router" that directs traffic to old or new code.
- **Current progress**: 3 modules fully migrated (Jobs, Badges, Inventory have complete hexagonal structure). Remaining managers are strangled incrementally, one at a time.

## Key Terms

| Term                  | Definition                                 |
| --------------------- | ------------------------------------------ |
| Strangler Fig         | Tree that grows around and replaces host   |
| Facade                | Interface that routes to old or new system |
| Legacy System         | Existing system being replaced             |
| Incremental Migration | Replacing system piece by piece            |
| Big Bang Rewrite      | Replacing entire system at once (risky)    |
| Feature Toggle        | Flag to switch between old and new         |
| Parallel Run          | Running old and new simultaneously         |
| Cutover               | Switching from old to new system           |
