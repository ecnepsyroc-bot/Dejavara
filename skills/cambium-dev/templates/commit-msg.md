# Conventional Commit Format

## Structure

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

## Types

| Type | When to Use |
|------|-------------|
| `fix` | Bug fix (doesn't change API) |
| `feat` | New feature (adds capability) |
| `refactor` | Code change (no fix or feature) |
| `docs` | Documentation only |
| `style` | Formatting, whitespace (no logic change) |
| `test` | Adding or updating tests |
| `chore` | Build, config, tooling |
| `perf` | Performance improvement |

## Scopes (Cambium)

Use Luxify architecture components as scopes:

- `ramus-inventory` - Inventory ramus
- `ramus-courier` - Courier ramus
- `graft-spec-master` - SpecToMaster graft
- `water` - Event contracts
- `sap` - Validation/auth
- `leaves` - UI/presentation
- `api` - BottaERisposta
- `autocad` - AutoCAD Tools

## Examples

```
fix(ramus-inventory): handle dashes in project number validation

feat(api): add batch badge lookup endpoint

refactor(graft-spec-master): simplify flag overlay command parsing

docs(autocad): update SHEET_NUM attribute documentation

chore: update EF Core to 8.0.12
```

## Rules

1. Use imperative mood: "add" not "added" or "adds"
2. Don't capitalize first letter after type
3. No period at end of description
4. Keep description under 72 characters
5. Body explains *what* and *why*, not *how*

## Breaking Changes

Add `!` after type or `BREAKING CHANGE:` in footer:

```
feat(api)!: change badge response format

BREAKING CHANGE: Badge lookup now returns array instead of object
```
