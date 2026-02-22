# Domain-Driven Design (DDD)

## What It Is

DDD is an approach to software development that centers the design on the business domain. It uses a shared ubiquitous language between developers and domain experts, and structures code around bounded contexts, aggregates, and domain events.

## Core Principles (Non-Negotiables)

- **Ubiquitous Language** — Same terms used by developers and domain experts
- **Bounded Contexts** — Explicit boundaries where a model applies
- **Aggregates** — Cluster of entities with a root that enforces invariants
- **Entities** — Objects with identity that persists over time
- **Value Objects** — Immutable objects defined by their attributes
- **Domain Events** — Record of something significant that happened
- **Repositories** — Abstract persistence, return aggregates

## How It Applies to Cambium

### Where We Align

- **Ubiquitous language**: Domain terms used consistently (Job, FactoryOrder, Badge, Laminate, Specification)
- **Bounded contexts**: Modules represent bounded contexts with MODULE.md boundaries
- **Entities**: Domain entities in `modules/*/Domain/Entities/`
- **Repositories**: Repository interfaces in `Ports/Outbound/`
- **Value objects**: `JobAddress` is a value object

**Evidence**:

- `modules/Cambium.Module.Jobs/Domain/Entities/Job.cs`
- `modules/Cambium.Module.Jobs/MODULE.md` documents boundaries

### Where We Dont

- **No aggregate roots**: Entities arent clustered with enforced invariants
- **Domain events narrow**: `IEventBus` + `InMemoryEventBus` exist and publish 4 Job lifecycle events (`JobCreated`, `JobRenamed`, `JobArchived`, `JobDeleted`), but broader event adoption is Phase 1 contracts only. SignalR is a separate UI broadcast layer, not the domain event bus.
- **Anemic domain model (Gen 1)**: Gen 1 entities in `Cambium.Data/Entities/` are pure data bags with no behavior
- **No domain services**: Complex domain logic not encapsulated

**Rich domain entity example (Gen 2)**: `modules/Cambium.Module.Inventory/Domain/Entities/Laminate.cs` — private setters, `Create()` factory method, `Reconstitute()` for ORM hydration, `ComputeStockStatus()` behavior, and `SampleInfo` as a value object (C# `record`). This is a textbook DDD entity.

### Compliance Desirable?

Selectively. Adopt for new complex domains:

- **Aggregates**: For modules with complex invariants (Purchasing?)
- **Domain events**: Expand `IEventBus` adoption as modules migrate from Gen 1 to Gen 2
- **Rich domain model**: Follow the `Laminate.cs` pattern for new domain entities

## Cambium Architectural Context

Two generations of code coexist (see `docs/architecture/CLEAN-ARCHITECTURE-AUDIT.md`):

- **Gen 2 (target)**: Domain entities like `Laminate.cs` have behavior, encapsulation, and factory methods — genuine DDD entities. `SampleInfo` is a proper value object. Repository interfaces (`ILaminateRepository`) abstract persistence. The "Where We Align" section above primarily describes this generation.
- **Gen 1 (dominant)**: ~80 entity classes in `Cambium.Data/Entities/` are anemic persistence models — `[Table]`/`[Column]` attributes, public setters, no behavior methods. Business logic lives in managers, not entities. This is the anti-pattern DDD explicitly warns against.

When Gen 1 entities are migrated, each will gain behavior methods, factory methods, and encapsulation following the `Laminate.cs` pattern.

## Key Terms

| Term                  | Definition                                             |
| --------------------- | ------------------------------------------------------ |
| Ubiquitous Language   | Shared vocabulary between code and domain experts      |
| Bounded Context       | Boundary where a domain model is valid                 |
| Aggregate             | Cluster of objects treated as a unit                   |
| Aggregate Root        | Entry point to an aggregate, enforces invariants       |
| Entity                | Object with identity (e.g., Job with JobId)            |
| Value Object          | Immutable object defined by attributes (e.g., Address) |
| Domain Event          | Record of something that happened in the domain        |
| Repository            | Abstraction for aggregate persistence                  |
| Domain Service        | Stateless logic that doesnt belong to an entity        |
| Anti-Corruption Layer | Translator between bounded contexts                    |
