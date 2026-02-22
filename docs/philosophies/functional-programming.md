# Functional Programming

## What It Is

Functional programming treats computation as evaluation of mathematical functions. It emphasizes immutability, pure functions (no side effects), and declarative code. Functions are first-class citizens that can be passed around and composed.

## Core Principles (Non-Negotiables)

- **Pure functions** — Same input always produces same output, no side effects
- **Immutability** — Data doesnt change after creation
- **First-class functions** — Functions as values, passed and returned
- **Declarative style** — Describe what, not how
- **Function composition** — Build complex functions from simple ones

## How It Applies to Cambium

### Where We Align

- **LINQ**: Functional-style queries throughout
- **Lambda expressions**: Used extensively
- **Some pure functions**: Utility/helper functions

**Evidence**:

```csharp
// LINQ - declarative, functional style
var activeJobs = jobs
    .Where(j => !j.IsArchived)
    .OrderBy(j => j.Name)
    .Select(j => new JobDto { Id = j.Id, Name = j.Name });
```

### Where We Dont

- **Mutable entities**: EF entities are mutable by design
- **Side effects**: Services modify database state
- **Imperative code**: Most business logic is imperative
- **Object-oriented core**: C# is primarily OOP

### Compliance Desirable?

**Selectively.** Apply FP where it helps:

- **LINQ for queries**: Already doing this
- **Pure utilities**: Validation, formatting, calculations
- **Immutable DTOs**: Consider `record` types

Full FP adoption inappropriate for EF Core/CRUD application.

## Key Terms

| Term                  | Definition                                           |
| --------------------- | ---------------------------------------------------- |
| Pure Function         | No side effects, deterministic output                |
| Side Effect           | Observable interaction with outside world            |
| Immutability          | Data cannot be modified after creation               |
| Higher-Order Function | Function that takes/returns functions                |
| Closure               | Function capturing variables from enclosing scope    |
| Currying              | Converting multi-arg function to chain of single-arg |
| Functor               | Type that can be mapped over                         |
| Monad                 | Pattern for composing computations                   |
