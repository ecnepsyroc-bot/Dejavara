# DRY (Dont Repeat Yourself)

## What It Is

DRY states that every piece of knowledge should have a single, authoritative representation in a system. When you need to change something, you change it in one place, not hunt through the codebase for duplicates.

## Core Principles (Non-Negotiables)

- **Single source of truth** — One authoritative location for each piece of knowledge
- **Abstraction over duplication** — Extract common code into reusable units
- **Knowledge, not just code** — Applies to schemas, configs, documentation too

## How It Applies to Cambium

### Where We Align (STRONG COMPLIANCE)

**Shared code**:

- `src/Cambium.Shared/DTOs/` — Common DTOs used across modules
- `clients/shared/utilities/` — Shared frontend utilities
- `clients/shared/api/` — Single API client for all SPAs
- `clients/shared/components/` — Reusable React components
- `clients/shared/tokens/` — Design tokens (colors, spacing)

**Evidence**:

```
clients/shared/
+-- api/          <- Shared API client
+-- components/   <- Reusable components
+-- tokens/       <- Design tokens
+-- utilities/    <- Helper functions
```

### Where We Dont

- **Some entity duplication**: Entities in `Cambium.Data/Entities/` and `modules/*/Domain/Entities/`
- **Some DTO duplication**: Similar DTOs across modules

### Compliance Desirable?

**Yes — ALREADY PRACTICING.** Continue consolidating during module migration.

## Key Terms

| Term                   | Definition                             |
| ---------------------- | -------------------------------------- |
| DRY                    | Dont Repeat Yourself                   |
| WET                    | Write Everything Twice (anti-pattern)  |
| Abstraction            | Extracting common functionality        |
| Single Source of Truth | One authoritative location             |
| Code Duplication       | Same logic in multiple places          |
| Knowledge Duplication  | Same concept represented multiple ways |
