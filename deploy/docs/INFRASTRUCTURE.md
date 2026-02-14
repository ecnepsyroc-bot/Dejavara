# Infrastructure Map

*Last audited: 2026-02-13*

## Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              CLOUDFLARE                                  │
│   luxifysystems.com (primary)  |  luxifyspecgen.com (legacy)            │
└─────────────────────────────────────────────────────────────────────────┘
         │                                    │
         │ Tunnels                            │ Tunnels
         ▼                                    ▼
┌─────────────────────┐             ┌─────────────────────────────────────┐
│   HOME (192.168.1.x)│             │   SHOP (192.168.0.x)                │
│                     │             │                                     │
│  ┌───────────────┐  │             │  ┌─────────────────────────────┐   │
│  │ Raspberry Pi  │  │             │  │ Cambium-server              │   │
│  │ 192.168.1.76  │  │             │  │ 192.168.0.108               │   │
│  │               │  │             │  │                             │   │
│  │ • OpenClaw    │  │             │  │ • PostgreSQL 16 (:5432)     │   │
│  │ • WireGuard   │  │             │  │ • PostgreSQL 17 (:5433)     │   │
│  │ • cloudflared │  │             │  │ • Cambium API (dev)         │   │
│  └───────────────┘  │             │  │ • cloudflared               │   │
│         ▲           │             │  └─────────────────────────────┘   │
│         │           │             │                                     │
│  ┌───────────────┐  │             └─────────────────────────────────────┘
│  │ P16 Laptop    │  │
│  │ 192.168.1.70  │  │
│  │ (node client) │  │
│  │               │  │
│  │ • PostgreSQL  │  │
│  │   16 & 17     │  │
│  │ • cloudflared │  │
│  │ • Dev tools   │  │
│  └───────────────┘  │
└─────────────────────┘
```

## Cloudflare Tunnels

| Tunnel | Status | Origin IP | Services |
|--------|--------|-----------|----------|
| **cambium-api** | ✅ healthy | 23.16.85.154 (shop) | SSH, DB, files, API |
| **dejavara-gateway** | ✅ healthy | 50.92.201.84 (home Pi) | OpenClaw gateway, personal apps |
| **filebrowser** | ✅ healthy | 23.16.85.154 (shop) | File server |
| **shop-relay** | ❌ down | - | (not in use) |

## DNS Records

### luxifysystems.com (primary)
| Subdomain | Target | Purpose |
|-----------|--------|---------|
| gateway | dejavara-gateway tunnel | OpenClaw remote access |
| personal | dejavara-gateway tunnel | Vara Personal app |
| (MX records) | Google Workspace | Email |

### luxifyspecgen.com (legacy)
| Subdomain | Target | Purpose |
|-----------|--------|---------|
| cambium-ssh | cambium-api tunnel | SSH to Cambium-server |
| db | cambium-api tunnel | Database access |
| files | cambium-api tunnel | File sharing |
| server | cambium-api tunnel | General server access |
| fileserver | filebrowser tunnel | File browser UI |
| api | shop-relay tunnel | (down) |
| ssh | shop-relay tunnel | (down) |

## Access Methods

### To Cambium-server

| Method | From | Command/Address |
|--------|------|-----------------|
| SSH (tunnel) | Anywhere | `ssh cambium-server-tunnel` |
| SSH (direct) | Shop only | `ssh cambium-server` |
| PostgreSQL | Via tunnel | Need cloudflared access or SSH tunnel |

**SSH Config on P16:**
```
Host cambium-server-tunnel
    HostName cambium-ssh.luxifyspecgen.com
    User User
    ProxyCommand cloudflared access ssh --hostname %h

Host cambium-server
    HostName 192.168.0.108
    User User
```

### To Raspberry Pi

| Method | From | Command/Address |
|--------|------|-----------------|
| Direct | Home LAN | `ssh dejavara@192.168.1.76` |
| VPN | Shop/Mobile | Connect WireGuard → 172.18.0.11 |
| Tunnel | Anywhere | gateway.luxifysystems.com |

### To Railway

| Service | Address |
|---------|---------|
| API | https://cambium-production.up.railway.app |
| PostgreSQL | postgresql://postgres:***@trolley.proxy.rlwy.net:44567/railway |

## PostgreSQL Instances

| Location | Port | Version | Purpose | Access |
|----------|------|---------|---------|--------|
| Cambium-server | 5432 | PG16? | Unknown | SSH tunnel |
| Cambium-server | 5433 | PG16 | **SSOT** Cambium DB | SSH tunnel |
| P16 Laptop | 5432 | PG16 | Dev | Local |
| P16 Laptop | 5433 | PG17 | Dev | Local |
| Railway | 44567 | PG17 | Production mirror | Direct external |

**Unified password:** `AyrcmZadEawHqbvDEMJTyNtewsEwqbRu`

## Running psql Against Cambium-server (from anywhere)

```bash
# Via SSH tunnel from P16
ssh cambium-server-tunnel "psql -h localhost -p 5433 -U postgres -d cambium -c 'SELECT 1'"

# Or open interactive session
ssh cambium-server-tunnel
# then: psql -h localhost -p 5433 -U postgres -d cambium
```

## Running psql Against Railway

```bash
# From P16 directly (has psql installed)
$env:PGPASSWORD = "AyrcmZadEawHqbvDEMJTyNtewsEwqbRu"
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -h trolley.proxy.rlwy.net -p 44567 -U postgres -d railway -c "SELECT 1"
```

## OpenClaw Node Connection

| Location | Method | Command |
|----------|--------|---------|
| Home LAN | Direct | `openclaw node --host 192.168.1.76 --port 18789` |
| Shop/VPN | Via WireGuard | `openclaw node --host 172.18.0.11 --port 18789` |
| Mobile | Via Cloudflare | `openclaw node --host gateway.luxifysystems.com --port 443 --tls` |

## Data Flow: Database Sync

```
Cambium-server (SSOT)
    │ pg_dump every 20 min
    │ via Task Scheduler
    ▼
Railway (production mirror)
    │ serves
    ▼
https://cambium-production.up.railway.app
```

**Sync script:** `C:\tmp\cambium-sync.bat` on Cambium-server

## Known Issues

1. **Gateway timeout:** OpenClaw commands timeout after 10s — use batch files for long operations
2. **SSH escaping (4 layers):** Bash → SSH → cmd.exe → PowerShell. `$_` gets mangled. Use single outer quotes for PowerShell vars. See `references/ssh-escaping.md`
3. **Column drift:** After restore, verify critical columns exist (e.g., `fo_folder_path`)
4. **shop-relay tunnel down:** Old tunnel, not currently used

## Credentials

| Secret | Location |
|--------|----------|
| Cloudflare API token | `~/.openclaw/secrets/cloudflare-token` |
| Railway token | `~/.openclaw/secrets/railway-token` |
| PostgreSQL password | `AyrcmZadEawHqbvDEMJTyNtewsEwqbRu` (all systems) |
