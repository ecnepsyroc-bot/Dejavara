# Separation of Concerns (SoC)

## What It Is

Separation of Concerns divides a program into distinct sections, each addressing a separate concern. A concern is a set of information or behavior. UI, business logic, and data access should be separate, changeable independently.

## Core Principles (Non-Negotiables)

- **One concern per unit** — Classes/modules handle one type of responsibility
- **Loose coupling** — Changes in one area dont cascade to others
- **High cohesion** — Related functionality grouped together
- **Layer separation** — Presentation, business, data layers distinct

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**Layer structure**:

```
src/
+-- Cambium.Api/        <- HTTP concerns (controllers, middleware)
+-- Cambium.Core/       <- Business logic (managers, services)
+-- Cambium.Data/       <- Persistence (DbContext, migrations)
+-- Cambium.Shared/     <- Cross-cutting (DTOs, enums)

modules/
+-- Cambium.Module.*/
    +-- Domain/         <- Business rules
    +-- Ports/          <- Interfaces
    +-- Adapters/       <- Infrastructure implementations
```

**Evidence**:

- Controllers dont contain business logic
- Services dont contain SQL
- DTOs separate from entities

### Where We Dont

- Some legacy managers mix concerns (need migration)

### Compliance Desirable?

**Yes — ALREADY PRACTICING.** Hexagonal architecture enforces SoC.

## Key Terms

| Term                  | Definition                                |
| --------------------- | ----------------------------------------- |
| Concern               | Set of related information or behavior    |
| Coupling              | Degree of interdependence between modules |
| Cohesion              | Degree to which elements belong together  |
| Layer                 | Horizontal slice of functionality         |
| Cross-Cutting Concern | Concern that spans layers (logging, auth) |
| Aspect                | Modularized cross-cutting concern         |
