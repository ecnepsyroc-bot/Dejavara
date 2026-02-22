# Composition over Inheritance

## What It Is

This principle favors composing objects (has-a) over inheriting behavior (is-a). Instead of building deep inheritance hierarchies, you assemble functionality by combining simpler objects. This leads to more flexible, maintainable designs.

## Core Principles (Non-Negotiables)

- **Has-a over is-a** — Objects contain other objects rather than extend them
- **Shallow hierarchies** — Avoid deep inheritance trees
- **Interfaces over abstract classes** — Define contracts, not partial implementations
- **Delegation** — Forward requests to composed objects
- **Flexible assembly** — Change behavior by swapping components

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**DI-based composition**:

- Services composed via dependency injection, not inheritance
- Controllers inject services, dont extend base controllers with business logic

**Interface-based polymorphism**:

```csharp
// Interface, not inheritance
public class JobService : IJobService  // implements, not extends
{
    private readonly IJobRepository _repository;  // composed
    private readonly ILogger<JobService> _logger;  // composed
}
```

**No deep hierarchies**:

- No `BaseManager -> SpecializedManager -> MoreSpecializedManager`
- Flat class structures throughout

### Where We Dont

- Generally strong compliance

### Compliance Desirable?

**Yes — ALREADY PRACTICING.** Continue using composition.

## Key Terms

| Term             | Definition                                 |
| ---------------- | ------------------------------------------ |
| Composition      | Assembling objects from simpler parts      |
| Inheritance      | Deriving a class from a parent class       |
| Has-A            | Composition relationship                   |
| Is-A             | Inheritance relationship                   |
| Delegation       | Forwarding method calls to composed object |
| Mixin            | Reusable component added to classes        |
| Strategy Pattern | Composition example: inject algorithm      |
