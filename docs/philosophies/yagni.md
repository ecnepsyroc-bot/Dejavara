# YAGNI (You Arent Gonna Need It)

## What It Is

YAGNI is an XP principle stating you should only implement things when you actually need them, not when you foresee needing them. Speculative features add complexity, maintenance burden, and are often wrong anyway.

## Core Principles (Non-Negotiables)

- **Implement when needed** — Not when you think you might need it
- **Avoid speculative generalization** — Dont build frameworks for one use case
- **Simplest thing that works** — Solve todays problem today
- **Refactor when requirements emerge** — Generalize based on real patterns

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**Evidence of YAGNI**:

- **BOM module is a stub**: `modules/Cambium.Module.Bom/` exists but minimal until needed
- **Workflow is minimal**: Basic workflow support, not full workflow engine
- **No speculative abstractions**: Direct EF Core, not custom ORM layer
- **Shared DbContext**: Pragmatic choice to avoid premature separation

**Example**:

```
// modules/Cambium.Module.Bom/ - Stub until BOM features needed
modules/Cambium.Module.Bom/
+-- MODULE.md
+-- Domain/Entities/
    (minimal implementation)
```

### Where We Dont

- Generally strong compliance with YAGNI

### Compliance Desirable?

**Yes — ALREADY PRACTICING.** Continue resisting speculative features.

## Key Terms

| Term                       | Definition                                |
| -------------------------- | ----------------------------------------- |
| YAGNI                      | You Arent Gonna Need It                   |
| Speculative Generalization | Building for imagined future needs        |
| Gold Plating               | Adding unrequested features               |
| Last Responsible Moment    | Defer decisions until necessary           |
| Technical Debt             | Cost of shortcuts (sometimes intentional) |
