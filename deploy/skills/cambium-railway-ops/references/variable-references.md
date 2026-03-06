# Railway Variable References

## The Rule

`DATABASE_URL` in the Cambium service's Railway Variables must always be:

```
${{Postgres.DATABASE_URL}}
```

Never a hardcoded connection string like `postgresql://postgres:abc123@...`.

## Why This Matters

When Railway's Postgres service regenerates its password (manual or automatic), the Variable Reference auto-updates. Hardcoded strings break immediately and silently — the only symptom is `28P01: password authentication failed` in deploy logs.

## Internal vs Public Hosts

| Context | Host | Use Case |
|---------|------|----------|
| Service-to-service | `postgres.railway.internal:5432` | Cambium API to Postgres (no public hop) |
| External access | `trolley.proxy.rlwy.net:44567` | psql from local machine, pg_dump |

The Variable Reference resolves to the internal host automatically. External scripts must use the public host with SSL.

## How to Verify

1. Railway dashboard > Cambium service > Variables tab
2. `DATABASE_URL` should show `${{Postgres.DATABASE_URL}}`
3. Click "Show resolved" to see the actual connection string

## How to Fix

If DATABASE_URL is hardcoded:

```bash
# Via Railway CLI
railway variables --set "DATABASE_URL=\${{Postgres.DATABASE_URL}}" --service Cambium
```

Or manually in the Railway dashboard: delete the current value, type `${{Postgres.DATABASE_URL}}` exactly.

## Connection String Parsing

Cambium parses the DATABASE_URL URI into an Npgsql connection string at startup (`Program.cs` lines 43-55). The URI format is:

```
postgresql://username:password@host:port/database
```

This is converted to:

```
Host=host;Port=port;Database=database;Username=username;Password=password;SSL Mode=Require;Trust Server Certificate=true
```

## psql Connection Quirk

When connecting to Railway from a local machine:

```bash
psql "postgresql://postgres:PASSWORD@trolley.proxy.rlwy.net:44567/railway?sslmode=require&sslrootcert=nonexistent"
```

The `sslrootcert=nonexistent` is required because a `root.crt` in `%APPDATA%/postgresql/` (if present) forces certificate verification which fails against Railway's self-signed cert.
