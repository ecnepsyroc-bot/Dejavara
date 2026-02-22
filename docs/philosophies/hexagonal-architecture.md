# Hexagonal Architecture (Ports and Adapters)

## What It Is

Hexagonal Architecture isolates business logic from external concerns (databases, UIs, APIs) by defining ports (interfaces) that adapters implement. The domain sits at the center with no dependencies on infrastructure, making it testable and swappable.

## Core Principles (Non-Negotiables)

- **Domain at the center** — Business logic has ZERO infrastructure dependencies
- **Ports define boundaries** — Inbound ports (use cases) and outbound ports (repositories)
- **Adapters implement ports** — Infrastructure code lives in adapters
- **Dependencies point inward** — Adapters depend on domain, never reverse
- **Swappable infrastructure** — Change database or UI without touching domain

## How It Applies to Cambium

### Where We Align (COMMITTED PHILOSOPHY)

Cambium explicitly adopted hexagonal architecture. See `docs/ARCHITECTURE.md`.

```
modules/Cambium.Module.{Name}/
+-- Domain/Entities/      <- Pure business logic (no EF annotations)
+-- Ports/Inbound/        <- Service interfaces (IJobService)
+-- Ports/Outbound/       <- Repository interfaces (IJobRepository)
+-- Adapters/Persistence/ <- EF Core implementations
+-- MODULE.md             <- Boundary specification
```

**Compliant modules**: Jobs, Badges, Purchasing, Production, Documents, DrawingCheckout, Inventory, Staging, Chat, Workflow, Specifications

**Evidence**:

- `modules/Cambium.Module.Jobs/Ports/Inbound/IJobService.cs`
- `modules/Cambium.Module.Jobs/Adapters/Persistence/JobRepository.cs`
- `adapters/` folder contains orchestrators for cross-module coordination

### Where We Dont (Gaps)

- **~38 managers in Core**: `src/Cambium.Core/Managers/` not yet migrated
- **Some EF annotations in Domain**: Should be in DbContext OnModelCreating
- **Entities in Cambium.Data**: Should eventually move to module Domain folders

### Compliance Desirable?

**Yes — ALREADY COMMITTED.** Continue migration per `docs/MODULE-MIGRATION-PATTERN.md`.

## Key Terms

| Term                     | Definition                                          |
| ------------------------ | --------------------------------------------------- |
| Port                     | Interface defining a boundary (inbound or outbound) |
| Inbound Port             | What the world can ask the module to do (use cases) |
| Outbound Port            | What the module needs from infrastructure           |
| Adapter                  | Implementation of a port using specific technology  |
| Primary/Driving Adapter  | Initiates action (API controller, CLI)              |
| Secondary/Driven Adapter | Responds to domain needs (database, external API)   |
| Domain                   | Pure business logic, no infrastructure dependencies |
| Application Service      | Orchestrates use cases, implements inbound ports    |
