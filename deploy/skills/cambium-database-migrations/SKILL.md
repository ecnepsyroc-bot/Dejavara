---
name: cambium-database-migrations
description: >
  EF Core migration management and schema drift handling for Cambium. Use when:
  adding new entities, adding columns, running migrations, debugging column-not-found
  errors (42703), debugging table-not-found errors (42P01), writing self-healing
  startup code, checking Railway schema state, or any situation where the database
  schema and EF Core entity mapping might be out of sync. Critical reading before
  any Railway deployment that changes database schema.
---

# Cambium Database Migrations

Cambium uses EF Core with PostgreSQL (Npgsql). The migration pattern deliberately avoids `MigrateAsync()`. Initialize or append to AUDIT.log before starting any migration work.

## The v5 Migration Pattern (No MigrateAsync)

```
NEVER add MigrateAsync() to Program.cs.

Cambium v5 deliberately removed MigrateAsync() from startup. Earlier versions
had MigrateAsync() which caused destructive schema recreation on Railway.

Current pattern: migrations are tracked in __EFMigrationsHistory but NEVER
auto-applied. Apply migrations manually via scripts or ALTER TABLE self-healing.
```

## Column-Drift Failure Chain

This is the single most dangerous failure mode in Cambium:

```
Entity has 14 columns mapped
  → EF generates SELECT with all 14 columns
    → Railway DB missing 1 column
      → PostgreSQL error 42703: column "x" does not exist
        → Every query against that entity fails
          → All related endpoints return generic 500
            → Error message: "An error occurred" — no schema indication
```

**Key insight:** The error is not isolated to the endpoint that uses the missing column. EF always selects ALL mapped columns, so ANY endpoint that touches the entity fails.

## Current Migration State

| Item | Count |
|------|-------|
| Total migrations | 117 |
| Date range | 2025-12-23 to 2026-03-04 |
| DbSets | 182 total (91 unique types) |
| Railway tables present | 109 |
| Railway tables missing | 55 (unshipped features) |

## Highest-Drift-Risk Columns (users table)

These 6 columns were added by recent migrations and are most likely to be missing on Railway after a fresh deploy or schema drift:

| Column | Migration | Risk |
|--------|-----------|------|
| `failed_login_attempts` | 20260221144403 | Auth-critical — login crashes if missing |
| `lockout_until` | 20260221144403 | Auth-critical — login crashes if missing |
| `must_change_password` | 20260302055651 | Auth-critical — login crashes if missing |
| `user_type` | 20260124175751 | User query crashes if missing |
| `last_login_at` | 20260124175751 | User query crashes if missing |
| `last_seen` | 20260124175751 | User query crashes if missing |

All 6 are handled by the self-healing startup block in `Program.cs` (lines 622-642).

## Self-Healing Pattern

Individual try/catch per ALTER ensures one failure doesn't skip the rest. See `aspnet-api-development` skill for the full code pattern.

**Location:** `Program.cs` lines 622-642 (ALTER loop), 644-674 (verification).

## When to Use Migration vs Self-Healing

| Scenario | Approach |
|----------|----------|
| New entity (new table) | EF Core migration |
| New column on existing entity | EF Core migration **AND** self-healing ALTER if auth-critical |
| Auth-critical column (anything in user login path) | Add to self-healing block in Program.cs |
| Non-critical column | EF Core migration only |

## How to Add a Migration

```bash
dotnet ef migrations add MigrationName \
  --project Cambium/src/Cambium.Data \
  --startup-project Cambium/src/Cambium.Api
```

## How to Apply to Railway

**Never use `MigrateAsync()`.** Generate SQL, review it, then apply manually:

```bash
# Generate SQL from migration
dotnet ef migrations script \
  --project Cambium/src/Cambium.Data \
  --startup-project Cambium/src/Cambium.Api \
  --output migration.sql

# Review the SQL for destructive operations (DROP, ALTER TYPE, etc.)
# Then apply to Railway
psql "$DATABASE_PUBLIC_URL" -f migration.sql
```

## Pre-Push Gate

Before any `git push origin main` that involves schema changes:

1. Run `scripts/check-railway-schema.sql` — confirm critical tables are clean
2. If new columns were added to entities, apply `ALTER TABLE` on Railway first
3. Record manual migrations in `docs/migrations/manual/YYYYMMDD_Description.sql`

See `cambium-railway-ops` skill for the full deployment sequence.
