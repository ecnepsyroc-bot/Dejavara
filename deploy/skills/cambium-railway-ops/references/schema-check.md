# Railway Schema Check

## Script

**Location:** `scripts/check-railway-schema.sql`

**Purpose:** Pre-push safety net to detect schema drift before `git push origin main`.

**Why it exists:** EF Core generates `SELECT` with ALL mapped columns. One missing column causes PostgreSQL error 42703, which crashes every endpoint that queries that entity.

## How to Run

```bash
# From repo root — requires DATABASE_PUBLIC_URL env var
psql "$DATABASE_PUBLIC_URL" -f scripts/check-railway-schema.sql

# Or with explicit connection (check Railway dashboard for current password)
psql "postgresql://postgres:PASSWORD@trolley.proxy.rlwy.net:44567/railway?sslmode=require&sslrootcert=nonexistent" \
  -f scripts/check-railway-schema.sql
```

## Output

Each column shows `OK` or `*** MISSING ***`:

```
users.failed_login_attempts: OK
users.lockout_until: OK
users.must_change_password: *** MISSING ***
```

## Critical Tables

These tables are queried by active production endpoints. Missing columns here cause immediate user-visible failures:

| Table | Expected Columns | Risk Level |
|-------|-----------------|------------|
| `users` | 14 | **CRITICAL** — login breaks |
| `factory_orders` | 18 | **HIGH** — FO module is active |
| `jobs` | 31 | **HIGH** — core entity |
| `laminates` | 20 | **CRITICAL** — production system |
| `user_preferences` | 7 | **MEDIUM** — settings break |

## Expected-Missing Tables (55)

These feature groups have EF entity classes but NO corresponding Railway tables. This is **normal** — they are unshipped features. Ignore `42P01` errors for these:

- **GIS Specifications** (9 tables) — GIS spec lookup system
- **Cutting/Ardis workflow** (4 tables) — CNC cutting integration
- **Purchasing** (6 tables) — purchase order management
- **Drawings subsystem** (5 tables) — drawing management extensions
- Various other feature tables

## Medium-Risk Missing Tables

These belong to the active FO module but don't have Railway tables yet. They will crash if any deployed code queries them:

- `fo_parts`
- `fo_checkpoints`
- `fo_status_history`
- `fo_sequences`
- `project_factory_orders`
- `projects`

## Emergency Repair

If critical tables are missing columns:

```bash
psql "$DATABASE_PUBLIC_URL" -f scripts/fix-railway-emergency.sql
```

This script is **idempotent** — safe to run multiple times. It uses `ADD COLUMN IF NOT EXISTS` for all critical columns.
