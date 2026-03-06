---
name: cambium-hosting
description: "Cambium platform hosting configuration and deployment. Covers 3-environment architecture (shop, Pi, Railway), Windows Service management, Cloudflare tunnel, database replication, and manual deploy procedures. Use when: deploying API updates, managing Windows Service, configuring tunnels, replicating databases, troubleshooting connectivity, or discussing hosting architecture. Triggers include: deploy, hosting, service, tunnel, Railway, replication, sync, VPN, environments."
---

# Cambium Hosting & Deployment

## Architecture Overview

3 environments: Shop server (source of truth), Phteah-Pi (home replica), Railway (cloud replica).

**Principle:** Shop server is the authoritative source. It must operate offline. Railway is a convenience replica for remote access — never treat it as the source of truth.

## Environments

### Shop Server (DEJAVARA)

- Windows 11, hostname DEJAVARA (was cambium-server, now at 192.168.0.108 on shop network)
- CambiumApi runs as Windows Service on port 5001
- PostgreSQL 17 on port 5432 (PG 16 legacy on 5433 — shop_chat only)
- Static IP: 192.168.0.108 (also accessible at 192.168.0.40 — old address)
- Cloudflare tunnel: api.luxifyspecgen.com -> localhost:5001
- Web apps served at: /laminate-inventory/, /workflow-builder/, /document-creator/, /document-staging/
- Mobile access via QR codes at workstations

### Phteah-Pi (Home Server)

- Raspberry Pi 5 (8GB), IP 192.168.1.76, hostname phteah-pi
- PostgreSQL 17 on port 5432, database `cambium`, owner `cambium`
- SSH: `ssh dejavara@192.168.1.76`
- WireGuard VPN: 10.8.0.0/24 subnet (DEJAVARA is 10.8.0.3)
- VPN provides sufficient encryption — HTTPS parked for now
- Restore flags for Railway dumps: `--no-owner --no-privileges` (Railway dump is postgres-owned)
- Ownership fix: targeted ALTER in DO $$ loop (REASSIGN OWNED fails on system objects)

### Railway (Cloud)

- Auto-deploys from GitHub main — every `git push origin main` triggers redeploy
- Connection: trolley.proxy.rlwy.net:44567, db railway, user postgres
- SSL quirk: `sslrootcert=nonexistent` required
- Password rotates — check dashboard if auth fails
- 109 of 164 tables present (55 missing = unshipped features, expected)
- Schema drift kills login — run `scripts/check-railway-schema.sql` BEFORE pushing
- BCrypt hashes contain `$` — use .sql files with `psql -f`, not inline bash

## Windows Service Management

```powershell
# Check service status
sc query CambiumApi

# Restart (requires admin elevation)
net stop CambiumApi && net start CambiumApi

# Or: Win+R > services.msc > find "CambiumApi" > Restart
```

**IMPORTANT:** Claude Code bash cannot elevate. For service management, the user must open an Admin prompt or use Chrome Remote Desktop.

**Service location:** `C:\dev\cambium\BottaERisposta\publish\` (NOT the development source at `C:\dev\cambium\Cambium\src\Cambium.Api\`)

## Cloudflare Tunnel

- Tunnel: api.luxifyspecgen.com -> localhost:5001
- Also: cambium-ssh.luxifyspecgen.com (SSH tunnel, ID 6c9be33d-e122-42f4-9b80-bf50c0ac1efa)
- cloudflared runs as Windows service (LocalSystem, AUTO_START, restart on failure)
- Config: `C:\Windows\System32\config\systemprofile\.cloudflared\config.yml`

## Database Replication

### SyncCli (Shop -> Pi)

- Runs every 20 minutes
- Replication script: `C:\tmp\sync-to-railway.cmd`

### Railway sync

- Not automatic — manual pg_dump/pg_restore workflow
- Backup script: `Cambium/scripts/backup-railway.ps1`
- Full DR: see `docs/runbooks/RAILWAY-DR-RUNBOOK.md`

## Manual Deploy Procedure (Shop Server)

No CI/CD for shop server — this is deliberate. Shop must operate offline.

### API updates

1. Build: `dotnet publish Cambium/src/Cambium.Api -c Release -o publish/`
2. Stop service: `net stop CambiumApi` (admin required)
3. Copy publish output to `C:\dev\cambium\BottaERisposta\publish\`
4. Start service: `net start CambiumApi`

### Frontend updates

1. Build the client: `cd Cambium/clients/{name} && npm run build`
2. Output goes to `Cambium/src/Cambium.Api/wwwroot/{name}/` (vite config)
3. Copy to service: `cp -r wwwroot/{name}/* BottaERisposta/publish/wwwroot/{name}/`
4. No service restart needed for static files

## Port Assignments

| Service | Port | Host |
|---------|------|------|
| CambiumApi | 5001 | All environments |
| PostgreSQL 17 | 5432 | DEJAVARA, Pi |
| PostgreSQL 16 (legacy) | 5433 | DEJAVARA only |
| Railway PG | 44567 | trolley.proxy.rlwy.net |
| WireGuard VPN | 51820 | Pi (10.8.0.0/24) |

## Network

- TP-Link ER605 dual-WAN failover (shop)
- WireGuard VPN for Pi <-> DEJAVARA connectivity
- SSH keepalives configured both sides (30s interval)

## Anti-Patterns

| Bad | Why | Good |
|-----|-----|------|
| CI/CD to shop server | Shop must work offline | Manual publish deploy |
| Railway as source of truth | It's a replica only | Shop server is authoritative |
| Hardcoded Railway password | Rotates periodically | Read from dashboard/env var |
| `git push origin main` without schema check | Schema drift crashes API | Run check-railway-schema.sql first |
| Inline bash with BCrypt hashes | `$` breaks in bash | Use .sql files with `psql -f` |
