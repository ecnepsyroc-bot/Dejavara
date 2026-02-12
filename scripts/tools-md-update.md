# TOOLS.md Update for Dejavara
# Apply this to: /home/node/.openclaw/workspace/TOOLS.md on the Pi
# Command: ssh dejavara@192.168.1.76 "cat > /mnt/data/docker/openclaw/workspace/TOOLS.md" < tools-md-update.md

# Tools & Environment

## Container

- **OS**: Debian 12 (bookworm), aarch64
- **Runtime**: Node v22.22.0, npm 10.9.4, Python 3.11.2, git 2.39.5
- **Memory limit**: 512MB
- **Restart policy**: unless-stopped

## Paths

| What | Where |
|------|-------|
| OpenClaw source | `/app` |
| Home | `/home/node` |
| Config | `/home/node/.openclaw` (mounted from Pi: `/mnt/data/docker/openclaw/config`) |
| Workspace | `/home/node/.openclaw/workspace` (mounted from Pi: `/mnt/data/docker/openclaw/workspace`) |
| Memory bank | `/home/node/.openclaw/workspace/memory-bank/` |
| Bundled skills | `/app/skills/` (54 skills) |

## Network

### Direct Access (Always Available)

| Service | Address | Status |
|---------|---------|--------|
| Container | 172.18.0.11 | Active |
| Pi host | 192.168.1.76 | Active |
| Home Assistant | 192.168.1.76:8123 | Reachable |
| Uptime Kuma | 192.168.1.76:3001 | Reachable |

### Via Laptop Node (When Online)

| Service | Address | Status |
|---------|---------|--------|
| Cory-Laptop | 192.168.1.70 (home) / 192.168.0.x (shop) | Paired, caps: browser + system |
| Cambium API (dev) | localhost:3000 on P16 | Available via node |
| Cambium API (prod) | localhost:5001 on P16 | Available via node |
| Windows filesystem | P16 drives | Available via node |
| Browser automation | P16 Chrome/Edge | Available via node |
| AutoCAD named pipe | \\.\pipe\LuxifyCommandBridge | Untested |

### Not Available

| Service | Address | Status |
|---------|---------|--------|
| PostgreSQL | :5432 | Not running |

## Connected Nodes

| Node | Home IP | Shop IP | Capabilities | Status |
|------|---------|---------|--------------|--------|
| Cory-Laptop (P16/Dejavara) | 192.168.1.70 | 192.168.0.x | browser, system | Service installed |

## Location Detection

Cory moves between home and shop with the P16 laptop. The node's reachability depends on location:

| Location | Network | Laptop IP | Pi Reachable | Node Status |
|----------|---------|-----------|--------------|-------------|
| **Home** | 192.168.1.x | 192.168.1.70 | Direct (LAN) | Auto-connects to Pi |
| **Shop** | 192.168.0.x | 192.168.0.x | Via tunnel | Needs tunnel or manual start |

### Available Machines by Location

**At Home (192.168.1.x)**
| Machine | Address | Access |
|---------|---------|--------|
| Pi (OpenClaw gateway) | 192.168.1.76 | Direct |
| Cory-Laptop (P16) | 192.168.1.70 | Node auto-connects |

**At Shop (192.168.0.x)**
| Machine | Address | Access |
|---------|---------|--------|
| CAMBIUM (shop server) | Shop LAN | `ssh cambium-server-tunnel` |
| Cory-s (shop workstation) | Shop LAN | Local |
| Cory-Laptop (P16) | 192.168.0.x | Node needs tunnel config |
| Pi | 192.168.1.76 | NOT reachable (different network) |

### Reconnecting the Node

**When at home:**
- Node should auto-connect to Pi (192.168.1.76:18789)
- If not connected, ask Cory to run: `openclaw node start`

**When at shop:**
- Pi is NOT directly reachable from shop LAN
- Options:
  1. Set up Cloudflare tunnel for Pi gateway (TODO)
  2. Use Tailscale/WireGuard VPN (TODO)
  3. Work without node - use SSH to CAMBIUM for shop tasks

### Shop Resources via SSH

When node is down but Cory is at shop, these are still reachable:
- **CAMBIUM server**: `ssh cambium-server-tunnel`
- **Shop database**: Via CAMBIUM
- **Shop file shares**: Via CAMBIUM or direct LAN

### What To Do When Node Is Offline

1. **Check Cory's location:**
   - Work hours (8am-5pm PST weekdays) → likely at shop
   - Evening/weekend → likely at home
   - Ask if uncertain

2. **If at home but node offline:**
   - Ask Cory to run `openclaw node start`
   - Check if laptop is awake

3. **If at shop:**
   - Node may not be connected (no tunnel yet)
   - Use SSH to CAMBIUM for shop-related tasks
   - Don't claim laptop node capabilities

4. **Never assume:**
   - Don't claim capabilities that require the node when it's offline
   - Be explicit about what you can and can't reach

## Auth

- `anthropic:dejavara` — API token (active, lastGood)
- `anthropic:claude-cli` — OAuth
- `anthropic:manual` — Token (backup)

## Known Issues

- `skills.load.extraDirs` in openclaw.json points to `C:\Dev\Dejavara\skills` — Windows path, doesn't exist in container
- Laptop node offline when at shop (no tunnel configured yet)
- Git workspace initialized but no commits yet
