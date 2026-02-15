# Dejavara Network Topology

> Complete network map covering home infrastructure, shop network, and the 3-2-1 Cambium development pipeline.
>
> **Last Updated:** 2026-02-14

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                          │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────────┐
│   HOME NETWORK  │   │  SHOP NETWORK   │   │   CLOUD SERVICES    │
│   192.168.1.x   │   │  192.168.0.x    │   │                     │
│                 │   │                 │   │  Railway (SSOT)     │
│  Phteah-Pi      │◄──┼──Dejavara P16   │   │  Cloudflare Tunnel  │
│  192.168.1.76   │   │  192.168.0.100  │   │  GitHub             │
│                 │   │                 │   │                     │
│  OpenClaw       │   │  Cambium-server │   │                     │
│  172.18.0.11    │   │  192.168.0.108  │   │                     │
└─────────────────┘   └─────────────────┘   └─────────────────────┘
         │                       │                       │
         └───────────────────────┴───────────────────────┘
                    WireGuard VPN (10.8.0.x)
                    Cloudflare Tunnel
                    SSH (cambium-server-tunnel)
```

---

## 1. Home Network (Maple Ridge)

### Physical Setup

| Device | IP | Purpose |
|--------|-----|--------|
| Telus Router | 192.168.1.254 | ISP gateway |
| Phteah-Pi (RPi 5) | 192.168.1.76 | Server host |
| Dejavara (P16) | 192.168.1.70 | Dev workstation (when home) |

### Phteah-Pi Services

**Docker Containers (10):**

| Service | Port | Purpose |
|---------|------|--------|
| Traefik | 80, 443, 8083 | Reverse proxy |
| Portainer | 9000 | Container management |
| Pi-hole | 53, 8080 | DNS ad blocking |
| Home Assistant | 8123 | Smart home |
| WireGuard | 51820, 51821 | VPN server |
| DuckDNS | — | Dynamic DNS |
| Uptime Kuma | 3001 | Service monitoring |
| Jellyfin | 8096 | Media streaming |
| Samba | 445 | Network shares |
| OpenClaw | 18789, 18790 | AI gateway |

**Native Services (3):**

| Service | Port | Purpose |
|---------|------|--------|
| Cambium API | 5001 | .NET millwork API (dev) |
| PostgreSQL 17 | 5432 (localhost) | Local database |
| Syncthing | 22000 | File sync |

### Docker Network

```
Docker bridge: 172.18.0.0/16
OpenClaw container: 172.18.0.11
Gateway binds to Docker network (not LAN interface)
```

### Storage

| Mount | Device | Size | Purpose |
|-------|--------|------|--------|
| / | SD Card | 115 GB | OS + Docker |
| /mnt/hdd | USB HDD | 72 GB | Cambium data |
| /mnt/data | — | — | Docker volumes, media |

---

## 2. Shop Network (Feature Millwork, Coquitlam)

### Physical Topology

```
INTERNET (Telus Fibre)
    │
[Telus T2200M] Modem
    │
[TP-Link ER605] VPN Gateway (192.168.0.1)
    │
[TRENDnet TEG-S24Dg] 24-port backbone
    │
    ├── Desktops, laptops (DHCP .50-.199)
    ├── CNC machines (.30, .31)
    ├── Printers (.98, .99, .150)
    ├── FileServe NAS (.32)
    ├── Cambium-server (.108)
    └── Polycom phones (11 units)
```

### Key Devices

| Device | IP | Purpose |
|--------|-----|--------|
| ER605 Gateway | 192.168.0.1 | LAN router, DHCP |
| Dejavara (P16) | 192.168.0.100 | Cory''s workstation |
| Cambium-server | 192.168.0.108 | Local Cambium instance |
| FileServe NAS | 192.168.0.32 | CNC programs, office files |
| Morbidelli CNC | 192.168.0.30 | Router (Windows XP) |
| Beam Saw | 192.168.0.31 | Panel saw |
| Canon Down | 192.168.0.98 | MFP downstairs |
| Canon Up | 192.168.0.99 | MFP upstairs |
| Ricoh Plotter | 192.168.0.150 | Wide-format 36" |

### IP Scheme

| Range | Purpose |
|-------|--------|
| .1 | Gateway |
| .2-.29 | Infrastructure |
| .30-.31 | CNC machines |
| .32-.49 | NAS, servers |
| .50-.199 | DHCP pool |
| .200-.254 | Static assignments |

---

## 3. Remote Access

### WireGuard VPN

```
Pi runs wg-easy container
Server: 10.8.0.1
Clients: 10.8.0.2+ (laptop gets 10.8.0.3)

AllowedIPs must include:
  - 192.168.1.0/24 (home LAN)
  - 172.18.0.0/16 (Docker network)
```

**Node connection via VPN:**
```bash
openclaw node --host 172.18.0.11 --port 18789
```

### Cloudflare Tunnel

| Subdomain | Target | Purpose |
|-----------|--------|--------|
| gateway.luxifysystems.com | Pi tunnel | Remote gateway access |
| personal.luxifysystems.com | Cambium personal | Personal DB |

### SSH to Cambium-server

```bash
# From shop network (direct)
ssh cambium-server

# From anywhere (via Cloudflare)
ssh cambium-server-tunnel
```

Both aliases configured on laptop with key auth, no prompts.

---

## 4. Cambium 3-2-1 Development Pipeline

### The "3-2-1" Model

```
┌─────────────────────────────────────────────────────────────────┐
│                     3 COPIES OF CODE                            │
│                                                                 │
│   [Laptop]  ←→  [GitHub]  ←→  [Railway]                        │
│      │              │             │                             │
│      │              └──────┬──────┘                             │
│      │                     │                                    │
│      └─────────────────────┼──── [Cambium-server]              │
│                            │            (SSH pull)              │
│                            ▼                                    │
│                   2 DIFFERENT MEDIA                             │
│                   (Local SSD + Cloud)                           │
│                                                                 │
│                   1 OFFSITE (Railway)                           │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
Pi (Telegram) → Laptop node → GitHub ─┬─► Railway (auto on main)
                                      │
                                      └─► Cambium-server (SSH pull)
```

### Components

| Location | Role | Connection |
|----------|------|------------|
| **Railway** | **SSOT** (production) | trolley.proxy.rlwy.net:44567 |
| Laptop (P16) | Development | Direct to Railway |
| Cambium-server | Local cache | SSH pull from GitHub |
| Pi (PostgreSQL) | Dev/test | localhost:5432 |

### Why Railway is SSOT

**Decision (2026-02-14):** Shop internet is unreliable. Railway is always-on.

- Laptop connects directly to Railway for migrations
- Cambium-server sync **disabled** (was causing drift)
- Cross-auth verified (JWT keys match)

### Deployment Triggers

| Target | Trigger | Method |
|--------|---------|--------|
| Railway | Merge to `main` | Auto-deploy |
| Cambium-server | Manual | `ssh cambium-server "cd C:\Dev\cambium && git pull"` |

---

## 5. OpenClaw Node Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        OpenClaw Gateway                         │
│                     (Pi: 172.18.0.11:18789)                    │
│                                                                 │
│   ┌─────────────────┐              ┌─────────────────┐         │
│   │   Telegram      │              │   Laptop Node   │         │
│   │   (inbound)     │              │   (outbound)    │         │
│   └────────┬────────┘              └────────┬────────┘         │
│            │                                │                   │
│            ▼                                ▼                   │
│   ┌─────────────────────────────────────────────────┐          │
│   │              Dejavara (Agent)                    │          │
│   │                                                  │          │
│   │   Capabilities:                                  │          │
│   │   - File ops (workspace)                         │          │
│   │   - Shell commands (Pi)                          │          │
│   │   - Browser automation (via node)                │          │
│   │   - System commands (via node)                   │          │
│   │   - Memory persistence (memory-bank/)            │          │
│   └─────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### Node Connection Modes

| Location | Method | Address |
|----------|--------|--------|
| Home LAN | Direct | 192.168.1.76:18789 |
| Shop (VPN) | WireGuard | 172.18.0.11:18789 |
| Remote | Tunnel | gateway.luxifysystems.com |

### Laptop Node Capabilities

- `browser` - Chrome automation via managed profile "clawd"
- `system` - PowerShell commands, file access
- Windows filesystem access to C:\Dev\Dejavara\

---

## 6. Connection Strings

### PostgreSQL

```
# Railway (SSOT - production)
Host=trolley.proxy.rlwy.net;Port=44567;Database=railway;Username=postgres;Password=[REDACTED]

# Cambium-server (local cache)
Host=192.168.0.108;Port=5432;Database=Cambium;Username=postgres;Password=[REDACTED]

# Laptop local (dev/test)
Host=localhost;Port=5433;Database=Cambium  # PG16
Host=localhost;Port=5432;Database=Cambium  # PG17

# Pi local
Host=localhost;Port=5432;Database=cambium
```

### Unified Password

All PostgreSQL instances use the same password for cross-system compatibility.
Stored in: Railway env vars, appsettings.json, Pi env.

---

## 7. Firewall Rules (Pi)

```bash
# UFW rules for OpenClaw
ufw allow from 192.168.1.0/24 to any port 18789  # LAN
ufw allow from 10.8.0.0/24 to any port 18789     # VPN
```

---

## 8. Critical Lessons Learned

| Issue | Root Cause | Fix |
|-------|------------|-----|
| WebSocket dies after 47 min | Linux TCP keepalive = 2 hours | `sysctl tcp_keepalive_time=60` |
| VPN can''t reach containers | AllowedIPs missing Docker network | Add `172.18.0.0/16` |
| JWT tokens fail cross-system | Different signing keys | Match `Jwt:Key` everywhere |
| Gateway unreachable via VPN | Bound to LAN interface only | Bind to Docker IP |
| Node commands timeout | 10s gateway limit | Use background exec or batch files |

---

## Related Documents

- `Phteah-pi/docs/BUILD.md` - Pi hardware/software inventory
- `Phteah-pi/docs/PORT-REGISTRY.md` - Port assignments
- `docs/NETWORK-AUDIT-2026-02-10.md` - Shop network details
- `MEMORY.md` (OpenClaw workspace) - Operational decisions

