# KISS (Keep It Simple, Stupid)

## What It Is

KISS states that systems work best when kept simple. Complexity should be avoided unless absolutely necessary. Simple solutions are easier to understand, maintain, debug, and extend.

## Core Principles (Non-Negotiables)

- **Simplicity is a feature** — Simple code is correct code
- **Avoid cleverness** — Clear beats clever
- **Minimal moving parts** — Fewer components, fewer failure modes
- **Understandable by others** — If it needs explanation, simplify it

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**Simple patterns**:

- **Direct EF Core**: No custom ORM abstraction layer
- **Standard CRUD**: Create, Read, Update, Delete patterns where appropriate
- **React SPA pattern**: Straightforward component structure
- **REST conventions**: Standard HTTP methods and status codes

**Evidence**:

```csharp
// Simple, direct repository pattern
public async Task<Job?> GetByIdAsync(int id)
{
    return await _context.Jobs.FindAsync(id);
}
```

### Where We Dont

- Some legacy managers are complex (1,000+ lines)
- Migration adds temporary complexity (dual interfaces)

### Compliance Desirable?

**Yes — ALREADY PRACTICING.** Module migration should simplify, not complicate.

## Key Terms

| Term                  | Definition                                |
| --------------------- | ----------------------------------------- |
| KISS                  | Keep It Simple, Stupid                    |
| Complexity            | Difficulty understanding or changing code |
| Accidental Complexity | Complexity from poor design choices       |
| Essential Complexity  | Complexity inherent to the problem        |
| Cognitive Load        | Mental effort to understand code          |
