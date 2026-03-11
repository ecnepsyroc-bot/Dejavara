# Dejavara Workstation Service Inventory

**Last Updated:** 2026-03-10
**Workstation:** DEJAVARA (Windows 11)
**Purpose:** Development laptop for Dejavara platform (work + home domains)

---

## Running Services & Autostart Chain

### 1. Shell:Startup Entries

#### User Startup (`shell:startup`)
**Location:** `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\`

| Item | Target | Purpose | Status |
|------|--------|---------|--------|
| OpenClaw Tray.lnk | `C:\Dev\Dejavara\scripts\openclaw-tray.ps1` | Network status tray icon (Home/Shop/VPN) | ✅ Active |

**How to verify:**
```powershell
Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
```

**How to restart:**
```powershell
Stop-Process -Name powershell -Force  # Kills tray script
# Tray will auto-restart on next logon, or manually run:
powershell -File C:\Dev\Dejavara\scripts\openclaw-tray.ps1
```

#### All Users Startup
**Location:** `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\`

| Item | Target | Purpose | Status |
|------|--------|---------|--------|
| Cloudflare WARP.lnk | Cloudflare WARP client | VPN/DNS service | ✅ Active |

---

### 2. Windows Scheduled Tasks

#### OpenClaw Node
**Path:** `\OpenClaw Node`
**Status:** Ready
**Last Run:** 2026-03-10 9:10:41 PM
**Trigger:** At logon + on workstation unlock
**Command:** `wscript.exe "C:\Users\cory\.openclaw\node-watchdog-hidden.vbs"`

**Purpose:** Runs OpenClaw node host (laptop agent for Pi-based gateway). Connects via SSH tunnel to `192.168.1.76:18789`.

**Environment Variables Needed:**
- `CLAWDBOT_GATEWAY_TOKEN` (set in node-autostart.cmd)
- `PI_HOST=192.168.1.76`
- `TUNNEL_PORT=18789`

**How to verify:**
```bash
# Check task status
schtasks /query /tn "OpenClaw Node"

# Check if node is running (port 18792 = Chrome extension relay)
netstat -an | grep "127.0.0.1:18792.*LISTEN"

# Check logs
tail -f C:\tmp\openclaw\node-autostart.log
```

**How to restart:**
```bash
schtasks /End /TN "OpenClaw Node"
schtasks /Run /TN "OpenClaw Node"
```

**Known Issues (FIXED 2026-03-10):**
- ✅ Environment variable name was `OPENCLAW_GATEWAY_TOKEN` instead of `CLAWDBOT_GATEWAY_TOKEN` (caused 1006 auth failures)
- ✅ PATH variable was 1,968 characters causing CMD parsing errors (`'ho'`, `'wershell'` errors) - reduced to 259 characters

**Script Chain:**
```
OpenClaw Node (Task)
  └─> node-watchdog-hidden.vbs (hides console window)
      └─> node-autostart.cmd (watchdog loop)
          ├─> Starts SSH tunnel (localhost:18789 → Pi:18789)
          └─> Runs: node C:\Dev\Dejavara\OpenClaw\dist\index.js node run
```

---

#### OpenClaw Gateway
**Path:** `\OpenClaw Gateway`
**Status:** Ready (not currently used)
**Command:** `C:\Users\cory\.openclaw\gateway.cmd`

**Purpose:** Legacy task for running gateway locally (gateway now runs on Pi).

**Current State:** Not active - gateway runs on Phteah-Pi via Docker.

---

#### OpenClaw OAuth Sync
**Path:** `\OpenClaw OAuth Sync`
**Status:** Ready
**Last Run:** 2026-03-10 10:08:04 PM
**Trigger:** Every 20 minutes
**Command:** `powershell.exe -File C:\Dev\Dejavara\scripts\sync-openclaw-oauth.ps1`

**Purpose:** Syncs OAuth tokens between OpenClaw gateway (on Pi) and local cache.

**How to verify:**
```bash
schtasks /query /tn "OpenClaw OAuth Sync"
cat C:\tmp\openclaw\oauth-sync.log
```

---

#### Sync-From-Cambium-Tunnel
**Path:** `\Sync-From-Cambium-Tunnel`
**Status:** Ready
**Last Run:** 2026-03-10 3:00:01 AM
**Trigger:** Daily at 3:00 AM
**Command:** `powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Dev\Dejavara\scripts\sync-from-cambium.ps1`

**Purpose:** Syncs data from Cambium server (shop) to laptop via SSH tunnel.

**How to verify:**
```bash
schtasks /query /tn "Sync-From-Cambium-Tunnel"
# Check if task is enabled
schtasks /query /tn "Sync-From-Cambium-Tunnel" /v /fo list | grep "Status"
```

---

#### Sync-Server-Projects
**Path:** `\Sync-Server-Projects`
**Status:** Running (3 instances currently)
**Next Run:** 2026-03-11 9:00:00 AM
**Command:** `powershell.exe -File C:\Dev\Dejavara\scripts\sync-server-projects.ps1`

**Purpose:** Syncs shop file server projects (\\\\Server\\Projects aka P: drive) to local cache.

**⚠️ Issue:** Multiple instances running - may need cleanup.

**How to verify:**
```bash
schtasks /query /tn "Sync-Server-Projects"
ps aux | grep "sync-server-projects"
```

**How to kill stale instances:**
```bash
Get-Process powershell | Where-Object { $_.CommandLine -like "*sync-server-projects*" } | Stop-Process -Force
```

---

#### Syncthing
**Path:** `\Syncthing`
**Status:** Ready
**Trigger:** At logon
**Purpose:** Syncs `C:\Dev\Dejavara\deploy\` (laptop) → `/mnt/data/dejavara-deploy/` (Pi)

**How to verify:**
```bash
# Check if Syncthing is running
ps aux | grep syncthing

# Open web UI
start http://localhost:8384
```

---

### 3. Windows Services

#### CambiumApi
**Service Name:** `CambiumApi`
**Display Name:** Cambium API (Botta e Risposta)
**Type:** WIN32_OWN_PROCESS
**Status:** STOPPED
**Start Type:** Manual (assumed)

**Purpose:** Legacy Windows service for Cambium API. **Not currently used** - API now runs via:
1. CambiumApi console app on shop server (`cambium-server` via SSH)
2. Railway deployment (production endpoint)

**⚠️ Known Issue:** Service has DI (dependency injection) bug and is disabled. Do not start unless rebuilt from current Dejavara monorepo.

**How to check:**
```bash
sc query CambiumApi
```

---

### 4. Dejavara Scripts Directory

**Location:** `C:\Dev\Dejavara\scripts\`

#### Boot/Autostart Scripts

| Script | Purpose | Used By | Status |
|--------|---------|---------|--------|
| `openclaw-tray.ps1` | Network status tray icon | User startup | ✅ Active |
| `sync-openclaw-oauth.ps1` | OAuth token sync | Scheduled task | ✅ Active |
| `sync-from-cambium.ps1` | Cambium data sync | Scheduled task | ✅ Active |
| `sync-server-projects.ps1` | P: drive sync | Scheduled task | ⚠️ Multiple instances |
| `ensure-p-drive.ps1` | Auto-fix P: drive disconnects | `setup-p-drive-monitor.ps1` | ℹ️ Setup script exists, monitor task not found |

#### Setup Scripts (run once)

| Script | Purpose | Status |
|--------|---------|--------|
| `setup-p-drive-monitor.ps1` | Creates "Ensure P-Drive Connection" task | Should be run as admin |
| `setup-oauth-sync-task.ps1` | Creates OAuth sync task | ✅ Already set up |
| `setup-sync-tasks.ps1` | Creates sync tasks | ✅ Already set up |
| `setup-connect-server-task.ps1` | Creates server connection task | Unknown if active |

---

### 5. OpenClaw Node Scripts

**Location:** `C:\Users\cory\.openclaw\`

| Script | Purpose | Invoked By |
|--------|---------|------------|
| `node-watchdog-hidden.vbs` | Hides console window | Scheduled task "OpenClaw Node" |
| `node-autostart.cmd` | SSH tunnel + node watchdog loop | node-watchdog-hidden.vbs |
| `node.cmd` | Standalone node runner (legacy) | Manual use only |
| `gateway.cmd` | Local gateway runner (legacy) | Scheduled task "OpenClaw Gateway" (not active) |
| `openclaw-tray.ps1` | Tray icon launcher | User startup (symlink to Dejavara/scripts) |
| `wireguard-auto.ps1` | WireGuard auto-connect helper | Unknown - may be legacy |

**Active Script:** `node-autostart.cmd`

**Environment Variables in node-autostart.cmd:**
- `CLAWDBOT_GATEWAY_TOKEN` - Gateway auth token
- `PI_HOST` - Pi IP address (192.168.1.76)
- `PI_USER` - SSH user (dejavara)
- `TUNNEL_PORT` - Gateway port (18789)
- `NODE_EXE` - Path to node.exe
- `OPENCLAW_ENTRY` - Path to OpenClaw dist/index.js

**Logs:**
- Main log: `C:\tmp\openclaw\node-autostart.log`
- Debug log: `C:\tmp\openclaw\node-debug.log` (older, from standalone node.cmd)

---

## Port Registry

### OpenClaw Ports

| Port | Service | Protocol | Binding |
|------|---------|----------|---------|
| 18789 | OpenClaw Gateway | WebSocket | localhost (SSH tunnel to Pi) |
| 18790 | OpenClaw Browser Relay | HTTP | localhost (Pi only) |
| 18791 | OpenClaw Browser Control | HTTP | localhost (Pi only) |
| 18792 | OpenClaw Node Chrome Extension Relay | TCP | localhost (node host) |

### Cambium Ports

| Port | Service | Protocol | Binding |
|------|---------|----------|---------|
| 5001 | CambiumApi (local dev) | HTTP | localhost |
| 5432 | PostgreSQL (local dev) | TCP | localhost |

**Note:** Production Cambium runs on:
- Shop server (cambium-server): Port 5001 (Cloudflare tunnel)
- Railway: `https://cambium-production.up.railway.app`

---

## Network Topology

### Home Network (TELUS7838)
- **Subnet:** 192.168.1.x
- **Laptop:** 192.168.1.80 (DHCP)
- **Pi (Phteah-pi):** 192.168.1.76
- **Connectivity:** Direct access to Pi, no VPN needed

### Shop Network
- **Subnet:** 192.168.0.x
- **File Server (\\\\Server):** 192.168.0.116 (SMB1 only, P: drive)
- **Cambium Server:** 192.168.0.108 (SSH via cambium-server)
- **Connectivity:** No direct Pi access - requires WireGuard VPN

### WireGuard VPN
- **Laptop VPN IP:** 10.8.0.3
- **Pi Gateway:** 10.8.0.1 or 192.168.1.76 (both work through VPN)
- **Endpoint:** 50.92.201.84:51820
- **Config:** `C:\Users\cory\phteah-pi.conf`

**⚠️ Rule:** Only use WireGuard when **NOT** on home network. VPN causes local routing issues when at home.

---

## Verification Commands

### Check All Services Status

```powershell
# OpenClaw Node
netstat -an | findstr "18792.*LISTEN"
tail -f C:\tmp\openclaw\node-autostart.log

# SSH Tunnel to Pi
netstat -an | findstr "127.0.0.1:18789.*LISTEN"

# PostgreSQL (local dev)
netstat -an | findstr ":5432.*LISTEN"

# Syncthing
netstat -an | findstr ":8384.*LISTEN"

# Scheduled Tasks
schtasks /query /fo table | findstr /i "OpenClaw Cambium Sync"
```

### Check Network Connectivity

```bash
# Pi (home network)
ping 192.168.1.76

# Shop file server (shop network only)
ping 192.168.0.116

# Cambium server SSH (shop network only)
ssh cambium-server "hostname"

# WireGuard status
wg show
```

---

## Restart Procedures

### Restart OpenClaw Node
```bash
schtasks /End /TN "OpenClaw Node"
sleep 3
schtasks /Run /TN "OpenClaw Node"

# Verify
sleep 10
tail -n 50 C:\tmp\openclaw\node-autostart.log
```

### Restart Syncthing
```bash
# Find Syncthing process
ps aux | grep syncthing

# Kill it
taskkill /IM syncthing.exe /F

# Will auto-restart on next logon, or run:
schtasks /Run /TN "Syncthing"
```

### Reconnect P: Drive (Shop Network)
```powershell
# Remove stale connection
net use P: /delete /yes

# Enable SMB1 (required for old server)
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -All

# Set network to Private
Set-NetConnectionProfile -InterfaceAlias "Ethernet 2" -NetworkCategory Private

# Reconnect
net use P: \\Server\Projects /persistent:yes
```

Or run the automated script:
```powershell
C:\Dev\Dejavara\scripts\ensure-p-drive.ps1
```

---

## Known Issues & Fixes

### Issue: OpenClaw Node 1006 Errors
**Status:** ✅ **FIXED 2026-03-10**
**Cause:** Environment variable name mismatch (`OPENCLAW_GATEWAY_TOKEN` vs `CLAWDBOT_GATEWAY_TOKEN`)
**Fix:** Updated `node-autostart.cmd` and `node.cmd` to use correct variable name.

### Issue: PowerShell Parsing Errors ('ho', 'wershell')
**Status:** ✅ **FIXED 2026-03-10**
**Cause:** PATH variable was 1,968 characters, exceeding CMD parsing limits
**Fix:** Reduced PATH in `node-autostart.cmd` to 259 characters (minimal essential paths only).

### Issue: P: Drive Disconnects After Windows Updates
**Status:** ⚠️ **ONGOING** (automated monitoring should prevent)
**Cause:** Windows Updates disable SMB1 or reset network profile to Public
**Mitigation:** Should be automated via "Ensure P-Drive Connection" task (if set up)
**Manual Fix:** Run `C:\Dev\Dejavara\scripts\ensure-p-drive.ps1`

### Issue: Multiple Sync-Server-Projects Instances
**Status:** ⚠️ **NEEDS INVESTIGATION**
**Symptom:** 3 instances of sync-server-projects.ps1 running simultaneously
**Impact:** May cause excessive disk I/O or sync conflicts
**Fix:**
```bash
Get-Process powershell | Where-Object { $_.CommandLine -like "*sync-server-projects*" } | Stop-Process -Force
```

### Issue: CambiumApi Service (Stopped)
**Status:** ℹ️ **EXPECTED** (service deprecated)
**Reason:** Service has DI bug and API now runs on cambium-server/Railway
**Action:** Do not start this service. It will fail due to missing dependencies.

---

## Zombie Process Check (Last Run: 2026-03-10)

**Results:**
- ✅ No stale Cambium processes found
- ✅ No stale OpenClaw processes found
- ✅ No zombie SSH tunnels (220 were cleaned up 2026-03-10)
- ⚠️ Multiple Sync-Server-Projects instances (see Known Issues)

**Ports in Use:**
- 18789 (SSH tunnel to Pi) - 1 process ✅
- 18792 (Node relay) - Not currently listening (node not running as of check)
- 5432 (PostgreSQL) - 1 process ✅

---

## Change Log

### 2026-03-10
- **Fixed:** OpenClaw node environment variable name (`CLAWDBOT_GATEWAY_TOKEN`)
- **Fixed:** node-autostart.cmd PATH length issue (1968 → 259 chars)
- **Cleanup:** Killed 110+ zombie SSH processes blocking port 18789
- **Created:** This inventory document

---

## References

- OpenClaw setup: `C:\Users\cory\.claude\projects\c--Dev-Dejavara\memory\openclaw-node-setup.md`
- Network topology: `C:\Users\cory\.claude\projects\c--Dev-Dejavara\memory\MEMORY.md`
- Cambium server sync: `C:\Users\cory\.claude\projects\c--Dev-Dejavara\memory\cambium-server-sync.md`
