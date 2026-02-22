# SOLID Principles

## What It Is

SOLID is a set of five object-oriented design principles that make software more maintainable, flexible, and understandable. Each letter represents a principle: Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion.

## Core Principles (Non-Negotiables)

- **S - Single Responsibility** — A class should have only one reason to change
- **O - Open/Closed** — Open for extension, closed for modification
- **L - Liskov Substitution** — Subtypes must be substitutable for their base types
- **I - Interface Segregation** — Many specific interfaces beat one general interface
- **D - Dependency Inversion** — Depend on abstractions, not concretions

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**Single Responsibility**:

- Modules have clear single purpose (Jobs, Badges, Purchasing)
- Controllers handle HTTP concerns only
- Services handle business logic

**Open/Closed**:

- Port interfaces allow extending behavior without modifying existing code
- New adapters can implement existing ports

**Liskov Substitution**:

- Repository interfaces can swap implementations (`JobRepository` implements `IJobRepository`)
- Test mocks substitute for real implementations

**Interface Segregation**:

- Small focused interfaces: `IJobService`, `IJobRepository`
- Not one giant `IEverythingManager`

**Dependency Inversion**:

- Controllers depend on interfaces, not implementations
- DI wires everything in `Program.cs`

**Evidence**:

```csharp
// Controller depends on abstraction
public class JobsController(IJobService jobService)

// Program.cs wires implementation
services.AddScoped<IJobService, JobService>();
```

### Where We Dont

- Some legacy managers violate SRP (large classes with multiple responsibilities)

### Compliance Desirable?

**Yes — ALREADY PRACTICING.** Continue applying during module migration.

## Cambium Architectural Context

Two generations of code coexist (see `docs/architecture/CLEAN-ARCHITECTURE-AUDIT.md`):

- **Gen 2 (target)**: Modules like Jobs and Inventory follow SOLID well — single-purpose use cases (`CreateJobUseCase`), interface segregation (`IJobService`, `IJobRepository`), and dependency inversion (controllers depend on abstractions). The "Where We Align" examples above come from Gen 2 code.
- **Gen 1 (dominant)**: ~44 managers in `Cambium.Core/Managers/` violate SRP (each manager handles CRUD, mapping, and queries), violate DIP (direct `CambiumDbContext` injection), and have broad interfaces (`IJobsManager` with many methods). `GisSpecificationsManager` at 1,142 lines is the most acute SRP violation.

As Gen 1 managers migrate to Gen 2 modules, SOLID compliance improves naturally — each module's Ports/Adapters structure enforces separation and inversion.

## Key Terms

| Term        | Definition                                        |
| ----------- | ------------------------------------------------- |
| SRP         | Single Responsibility Principle                   |
| OCP         | Open/Closed Principle                             |
| LSP         | Liskov Substitution Principle                     |
| ISP         | Interface Segregation Principle                   |
| DIP         | Dependency Inversion Principle                    |
| Abstraction | Interface or abstract class hiding implementation |
| Concretion  | Specific implementation class                     |
