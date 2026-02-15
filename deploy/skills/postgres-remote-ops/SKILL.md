---
name: postgres-remote-ops
description: Execute PostgreSQL operations remotely via OpenClaw node. Use when gateway timeout kills long queries, when command escaping through node fails, or when direct psql execution isn't practical.
---

# PostgreSQL Remote Operations

Execute SQL against remote PostgreSQL when direct psql access isn't available or practical.

## Decision Tree

```
Need to run SQL against remote DB?
├─ Direct laptop access? → psql directly (P16 has all versions)
├─ Via OpenClaw node? → See "Node Command Execution" below
├─ Need to avoid escaping? → Node.js pg script or batch file
└─ Quick one-off? → Railway Data tab (web UI)
```

## Direct Laptop Access (Preferred)

P16 has PostgreSQL installed. Use psql directly:
```powershell
# Set password, run query
$env:PGPASSWORD = "password"
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -h host -p port -U postgres -d db -c "SELECT 1"
```

## Via OpenClaw Node (Gateway Timeout Issues)

When running psql through OpenClaw node from Pi:
- **Gateway timeout:** 10 seconds default — long queries get killed
- **Escaping hell:** PowerShell → node → cmd.exe quote handling differs
- **Solution:** Write batch file on laptop, run that instead

```powershell
# Create batch file with query baked in
@"
@echo off
set PGPASSWORD=password
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -h host -p port -U postgres -d db -c "YOUR SQL HERE"
"@ | Out-File -Encoding ASCII C:\tmp\run-query.bat

# Then just run the batch
C:\tmp\run-query.bat
```

## Method 1: Node.js with pg Package (Fallback)

When psql escaping is too painful or running from a system without PostgreSQL.

### One-liner for simple queries

```bash
# Windows PowerShell
node -e "const{Client}=require('pg');const c=new Client({connectionString:'postgresql://user:pass@host:port/db'});c.connect().then(()=>c.query('SELECT COUNT(*) FROM jobs')).then(r=>console.log(JSON.stringify(r.rows,null,2))).finally(()=>c.end())"

# Install pg first if needed
npm i -g pg
```

### Script for complex operations

Create `run-sql.js`:
```javascript
const { Client } = require('pg');

const connectionString = process.env.DATABASE_URL || 
  'postgresql://postgres:PASS@trolley.proxy.rlwy.net:44567/railway';

const sql = process.argv[2] || 'SELECT version()';

(async () => {
  const client = new Client({ connectionString });
  await client.connect();
  try {
    const result = await client.query(sql);
    console.log(JSON.stringify(result.rows, null, 2));
    console.log(`\n(${result.rowCount} rows)`);
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  } finally {
    await client.end();
  }
})();
```

Usage:
```bash
node run-sql.js "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS fo_folder_path varchar(500)"
node run-sql.js "SELECT COUNT(*) FROM jobs"
```

### DDL operations (ALTER TABLE, CREATE INDEX, etc.)

Same script works — pg handles DDL:
```bash
node run-sql.js "ALTER TABLE jobs ADD COLUMN IF NOT EXISTS fo_folder_path varchar(500)"
```

## Method 2: SSH to Cambium-server

Cambium-server has PostgreSQL and is accessible from anywhere via Cloudflare tunnel.

### SSH Access Methods

| Method | Command | When |
|--------|---------|------|
| Tunnel (anywhere) | `ssh cambium-server-tunnel` | Home, mobile, anywhere |
| Direct (shop only) | `ssh cambium-server` | On shop network (192.168.0.x) |

### Run psql via SSH

```bash
# Interactive session (recommended)
ssh cambium-server-tunnel
# Then: psql -h localhost -p 5433 -U postgres -d cambium

# One-liner (escaping required)
ssh cambium-server-tunnel "psql -h localhost -p 5433 -U postgres -d cambium -c 'SELECT 1'"
```

### Batch file approach (avoids escaping hell)

When inline escaping fails, create a batch file on the server:

```bash
# Create batch file via SSH
ssh cambium-server-tunnel "echo @echo off > C:\tmp\q.bat && echo set PGPASSWORD=password >> C:\tmp\q.bat && echo psql -h localhost -p 5433 -U postgres -d cambium -c \"SELECT COUNT(*) FROM jobs\" >> C:\tmp\q.bat"

# Run it
ssh cambium-server-tunnel "C:\tmp\q.bat"
```

### SSH Escaping Rules (4 layers: Bash → SSH → cmd.exe → PowerShell)

**Simple commands (no $ variables):** Double quotes work fine
```bash
ssh cambium-server-tunnel "schtasks /run /tn TaskName"
```

**Commands with $_ or $env:** Use SINGLE quotes outer
```bash
ssh cambium-server-tunnel 'powershell -Command "Get-Service | Where-Object { $_.Name -like \"*Cambium*\" }"'
```

**NEVER do this:** ($ gets mangled by local bash to `extglob.Name`)
```bash
ssh cambium-server-tunnel "powershell -Command ... $_.Name ..."
```

**When in doubt:** Interactive SSH session, then run commands directly

## Method 3: Web-Based Tools

### Railway Data Tab
1. Railway dashboard → Service → PostgreSQL → Data
2. Direct SQL query interface
3. Works for quick queries, clunky for scripts

### TablePlus / DBeaver / pgAdmin
- Install once, save connection
- GUI for complex operations
- TablePlus recommended for Mac/Windows

## Common Operations

### Verify column exists
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'jobs' AND column_name = 'fo_folder_path';
```

### Add missing column
```sql
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS fo_folder_path varchar(500);
```

### Check table row counts
```sql
SELECT 
  schemaname,
  relname as table_name,
  n_live_tup as row_count
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

### Kill connections (before restore)
```sql
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'railway' AND pid <> pg_backend_pid();
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `pg` module not found | `npm i pg` in project dir |
| Connection timeout | Check firewall, verify host/port |
| SSL required | Add `?sslmode=require` to connection string |
| Permission denied | Railway uses `postgres` user, not custom roles |
| Gateway timeout (OpenClaw) | Break into smaller queries or use batch file |

## Railway-Specific Notes

- External host: `*.proxy.rlwy.net` (not `.railway.internal`)
- Internal host: `*.railway.internal` (only from Railway services)
- Default user: `postgres`
- Default database: `railway`
- Connection string format: `postgresql://postgres:PASS@HOST:PORT/railway`

## See Also

- `INFRASTRUCTURE.md` — Full network topology and access methods
- `postgres-failover-sync` skill — Database sync patterns
