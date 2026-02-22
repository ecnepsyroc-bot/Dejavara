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
- **No domain events (internal)**: SignalR events are UI notifications, not domain events
- **Anemic domain model**: Business logic often in services, not entities
- **No domain services**: Complex domain logic not encapsulated

### Compliance Desirable?

Selectively. Adopt for new complex domains:

- **Aggregates**: For modules with complex invariants (Purchasing?)
- **Domain events**: If audit requirements grow
- **Rich domain model**: Move validation logic into entities

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
