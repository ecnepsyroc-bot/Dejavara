# Clean Architecture

## What It Is

Clean Architecture (Robert C. Martin) organizes code into concentric layers where dependencies only point inward. The innermost layer contains enterprise business rules, surrounded by application logic, then interface adapters, then frameworks. Its a generalization of hexagonal architecture.

## Core Principles (Non-Negotiables)

- **Dependency Rule** — Dependencies only point inward (toward higher-level policies)
- **Entities** — Enterprise-wide business rules (innermost layer)
- **Use Cases** — Application-specific business rules
- **Interface Adapters** — Convert data between use cases and external formats
- **Frameworks and Drivers** — Outermost layer (databases, web, UI)
- **Independence** — Business rules dont know about UI, database, or frameworks

## How It Applies to Cambium

### Where We Align

Hexagonal architecture (Cambiums committed pattern) is a variant of Clean Architecture.

```
# Clean Architecture Layers -> Cambium Mapping
Entities          -> modules/*/Domain/Entities/
Use Cases         -> modules/*/Ports/Inbound/ (service interfaces)
Interface Adapters -> modules/*/Adapters/
Frameworks        -> src/Cambium.Api/, src/Cambium.Data/
```

**Evidence**:

- Domain entities have no EF Core dependencies (goal, some exceptions remain)
- Controllers depend on service interfaces, not implementations
- `services.AddScoped<IJobService, JobService>()` wires dependencies at startup

### Where We Dont

- **Legacy Core layer**: `src/Cambium.Core/Managers/` mixes use cases with some infrastructure
- **Entities in Data project**: `src/Cambium.Data/Entities/` should be in module domains

### Compliance Desirable?

**Yes — aligned via hexagonal adoption.** Same principles, different terminology.

## Key Terms

| Term                   | Definition                                         |
| ---------------------- | -------------------------------------------------- |
| Dependency Rule        | Source code dependencies point inward only         |
| Entity                 | Enterprise business object (domain model)          |
| Use Case               | Application-specific business rule (interactor)    |
| Interface Adapter      | Gateway, presenter, controller — format conversion |
| Framework              | External tool (web framework, database driver)     |
| Screaming Architecture | Folder structure reveals intent, not framework     |
| Humble Object          | Thin adapter that defers to testable logic         |
