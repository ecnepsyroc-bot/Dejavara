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

(skipped for brevity)