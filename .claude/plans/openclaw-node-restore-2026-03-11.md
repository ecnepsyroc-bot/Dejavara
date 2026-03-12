# Plan: OpenClaw Full System Restoration

**Date:** 2026-03-11
**Author:** Claude Code
**Status:** PENDING EXTERNAL REVIEW

---

## Problem Statement

OpenClaw system has multiple issues requiring attention:

1. **CRITICAL:** Laptop node not running - scheduled task missing, 0 paired nodes
2. **CRITICAL:** No remote SSH access to Pi - cloudflared installed but unconfigured (node.cmd hardcodes LAN IP `192.168.1.76`, fails from shop/mobile)
3. **WARNING:** Gateway auth-profiles errors on every operation (malformed JSON entries)
4. **WARNING:** Telegram groupPolicy misconfigured - wife bot drops all group messages

## Validated Current State

### Infrastructure Status

| Component | Status | Evidence |
|-----------|--------|----------|
| Pi Gateway container | ✅ Healthy | `docker ps` shows "Up ~1 hour (healthy)" |
| Gateway port binding | ✅ Working | Telegram bots started, port 18789 bound |
| Paired nodes | ❌ **0** | `openclaw nodes list` output |
| Laptop SSH tunnel | ❌ Missing | No `ssh.exe` process running |
| Laptop node process | ❌ Missing | No OpenClaw node in process list |
| Scheduled task | ❌ **Missing** | `schtasks /query` finds no matching task |
| node.cmd config | ✅ Present | `~/.openclaw/node.cmd` exists, token valid |
| node.cmd connectivity | ⚠️ **LAN only** | Hardcodes `PI_HOST=192.168.1.76` — fails from shop/mobile |
| Pi cloudflared | ⚠️ **Unconfigured** | Binary installed (v2026.2.0), no tunnel/config/certs |
| OpenClaw build | ✅ Present | `OpenClaw/dist/index.js` exists |

### Gateway Warnings Analysis

**Warning 1: auth-profiles**
```text
[agents/auth-profiles] ignored invalid auth profile entries during store load
```
**Root cause:** `main` agent's `auth-profiles.json` has incomplete `anthropic:claude-cli` entry - missing `type` and `provider` fields. Compare:
- `chair` agent: Has `"type": "oauth", "provider": "anthropic"` ✅
- `main` agent: Only has `access`, `refresh`, `expires` ❌

**Warning 2: Telegram groupPolicy**
```text
[channels.telegram] groupPolicy is "allowlist" but groupAllowFrom is empty
```
**Root cause:** In `openclaw.json`, the `wife` account has:
```json
"groupPolicy": "allowlist"  // but no groupAllowFrom array
```

---

## Proposed Solution

### Phase 0: Set up Cloudflare tunnel to Pi for SSH (Pi-side)

**Goal:** Enable SSH access to Pi from shop (192.168.0.x) and mobile/traveling — required for node.cmd to work outside home LAN.

**Context:** cambium-server already has a working Cloudflare tunnel (`cambium-ssh.luxifyspecgen.com`). This replicates that pattern for the Pi. cloudflared v2026.2.0 is installed but has no config, certs, or tunnel.

**Actions:**
```bash
ssh phteah-pi

# 1. Authenticate with Cloudflare (opens browser on Pi or provides URL)
sudo cloudflared tunnel login

# 2. Create the tunnel
sudo cloudflared tunnel create phteah-pi

# 3. Add DNS route (adjust domain as needed)
sudo cloudflared tunnel route dns phteah-pi phteah-pi-ssh.luxifyspecgen.com

# 4. Create config
sudo mkdir -p /etc/cloudflared
sudo tee /etc/cloudflared/config.yml << 'EOF'
tunnel: phteah-pi
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: phteah-pi-ssh.luxifyspecgen.com
    service: ssh://localhost:22
  - service: http_status:404
EOF

# 5. Install as systemd service
sudo cloudflared service install

# 6. Start and enable
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

**Note:** Step 1 (`tunnel login`) requires browser access on the Pi or copying a URL to authenticate. If the Pi is headless, copy the URL it prints and open it on the laptop.

**Rollback:**
```bash
sudo systemctl stop cloudflared
sudo systemctl disable cloudflared
sudo cloudflared service uninstall
```

**Success criteria:**
```bash
# From laptop (not on home LAN) or from shop:
ssh -o ProxyCommand="cloudflared access ssh --hostname phteah-pi-ssh.luxifyspecgen.com" dejavara@phteah-pi-ssh.luxifyspecgen.com
```

**Laptop SSH config addition** (`~/.ssh/config`):
```
Host phteah-pi-tunnel
    HostName phteah-pi-ssh.luxifyspecgen.com
    User dejavara
    ProxyCommand cloudflared access ssh --hostname %h
    ServerAliveInterval 30
    ServerAliveCountMax 3
```

---

### Phase 0b: Update node.cmd to use Cloudflare tunnel (Laptop-side)

**Goal:** Make node.cmd work from any network (home, shop, mobile).

**File:** `C:\Users\cory\.openclaw\node.cmd`

**Change:** Replace the hardcoded LAN IP with the Cloudflare tunnel, or add fallback logic.

**Option A — Tunnel only (simplest, always works):**
```batch
set "PI_HOST=phteah-pi-tunnel"
set "SSH_EXE=C:\Windows\System32\OpenSSH\ssh.exe"
```
This uses the `~/.ssh/config` Host alias which includes the `ProxyCommand` for cloudflared.

**Option B — Try LAN first, fall back to tunnel (faster on home network):**
```batch
rem Try LAN first (faster), fall back to Cloudflare tunnel
ping -n 1 -w 500 192.168.1.76 >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set "PI_HOST=192.168.1.76"
) else (
    set "PI_HOST=phteah-pi-tunnel"
)
```

**Rollback:** Restore original `PI_HOST=192.168.1.76` line.

**Success criteria:** `node.cmd` connects to Pi gateway from shop network or mobile hotspot.

---

### Phase 1: Fix auth-profiles (Pi-side)

**Goal:** Eliminate "invalid auth profile entries" warnings

**Actions:**
```bash
ssh phteah-pi

# Backup current state
sudo cp /mnt/data/docker/openclaw/config/agents/main/agent/auth-profiles.json \
       /mnt/data/docker/openclaw/config/agents/main/agent/auth-profiles.json.bak.$(date +%Y%m%d-%H%M%S)

# Fix the main agent's auth-profiles.json - add missing fields to anthropic:claude-cli
# Edit to add: "type": "oauth", "provider": "anthropic"
```

**File to modify:** `/mnt/data/docker/openclaw/config/agents/main/agent/auth-profiles.json`

**Change:** Add missing `type` and `provider` fields to `anthropic:claude-cli` entry:
```json
"anthropic:claude-cli": {
  "type": "oauth",           // ADD
  "provider": "anthropic",   // ADD
  "access": "sk-ant-oat01-...",
  "refresh": "sk-ant-ort01-...",
  "expires": 1773294974801
}
```

**Rollback:** Restore from `.bak` file

**Success criteria:** `openclaw nodes list` runs without auth-profiles warning

---

### Phase 2: Fix Telegram groupPolicy (Pi-side)

**Goal:** Either enable group messages for wife bot OR explicitly disable them

**Actions:** Edit `/mnt/data/docker/openclaw/config/openclaw.json`

**Option A - Disable groups for wife (simpler, if not needed):**
```json
"wife": {
  "groupPolicy": "disabled"  // Change from "allowlist"
}
```

**Option B - Enable specific groups (if groups are needed):**
```json
"wife": {
  "groupPolicy": "allowlist",
  "groupAllowFrom": ["<group_chat_id>"]  // Add the group IDs
}
```

**Rollback:** Restore previous config

**Success criteria:** Warning disappears from `openclaw nodes list` output

---

### Phase 3: Restart gateway to apply config changes

**Actions:**
```bash
ssh phteah-pi 'docker restart openclaw'
```

**Wait:** 30 seconds for container to become healthy

**Success criteria:** `docker ps` shows healthy, no warnings on `openclaw nodes list`

---

### Phase 4: Validate node.cmd works manually (Laptop-side)

**Actions:**
1. Open terminal on laptop
2. Execute `C:\Users\cory\.openclaw\node.cmd`
3. Verify SSH tunnel establishes (check port 18789 listening)
4. Verify node pairs with gateway: `ssh phteah-pi "docker exec openclaw openclaw nodes list"`

**Rollback:** Ctrl+C kills the node; SSH tunnel cleanup is built into node.cmd

**Success criteria:** Gateway shows "Paired: 1" with node name "Cory-Laptop"

---

### Phase 5: Create scheduled task (Laptop-side)

**Actions:**
```powershell
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c C:\Users\cory\.openclaw\node.cmd"
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User "cory"
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask `
    -TaskName "OpenClaw Node" `
    -Action $action `
    -Trigger $triggerLogon `
    -Settings $settings `
    -RunLevel Limited `
    -Description "OpenClaw node host with SSH tunnel to Pi gateway"
```

**Rollback:** `Unregister-ScheduledTask -TaskName "OpenClaw Node" -Confirm:$false`

**Success criteria:** `schtasks /query /tn "OpenClaw Node"` shows task with Status: Ready

---

### Phase 6: Verify task-based startup

**Actions:**
1. Stop the manual node (Ctrl+C from Phase 4)
2. Wait 5 seconds for SSH tunnel to close
3. Run `schtasks /run /tn "OpenClaw Node"`
4. Verify gateway shows paired node

**Rollback:** `schtasks /end /tn "OpenClaw Node"`

**Success criteria:** Node reconnects automatically via scheduled task

---

## Files Modified

| Location | File | Change |
|----------|------|--------|
| Pi | `/etc/cloudflared/config.yml` | **New** — Cloudflare tunnel config for SSH |
| Pi | systemd `cloudflared` service | **New** — enable tunnel on boot |
| Pi | `/mnt/data/docker/openclaw/config/agents/main/agent/auth-profiles.json` | Add missing `type`, `provider` fields |
| Pi | `/mnt/data/docker/openclaw/config/openclaw.json` | Fix wife account groupPolicy |
| Laptop | `C:\Users\cory\.openclaw\node.cmd` | Update `PI_HOST` to use Cloudflare tunnel |
| Laptop | `~/.ssh/config` | Add `phteah-pi-tunnel` host entry |
| Laptop | Windows Task Scheduler | Create "OpenClaw Node" task |

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Cloudflare tunnel login fails (headless Pi) | Medium | Medium | Copy auth URL to laptop browser; Pi has no display |
| Cloudflare tunnel breaks direct SSH | Low | High | Tunnel is additive — direct LAN SSH (`192.168.1.76`) still works independently |
| node.cmd tunnel fallback adds latency | Low | Low | Option B tries LAN first (500ms timeout); tunnel only used when LAN unreachable |
| Auth-profiles edit breaks auth | Low | High | Backup before edit; chair agent has working copy to reference |
| Config edit breaks gateway | Low | High | Backup config; docker restart reverts to last good state |
| node.cmd has stale config | Low | Medium | Phase 4 validates before creating task |
| SSH tunnel fails to Pi | Low | High | node.cmd has built-in verification with error exit |
| Task runs but node crashes | Low | Low | RestartCount=3 in task settings |

---

## Questions for Reviewer

1. **Phase 0:** Is `phteah-pi-ssh.luxifyspecgen.com` the right hostname? (Must be on a domain you control in Cloudflare.)
2. **Phase 0b:** Option A (tunnel only) or Option B (LAN fallback)? Option B is faster at home but adds complexity.
3. **Phase 2:** Should wife bot have group access? If yes, what group IDs? If unknown, default to `"groupPolicy": "disabled"`.
4. **Phase 5:** Should we add a workstation unlock trigger in addition to logon?
5. **Phase 5:** Should the task run hidden or visible for debugging?
6. Should other agent auth-profiles be checked/fixed (deepseek, gemini, grok, wife)?

---

## Review Checklist (for Claude.ai)

- [ ] Does the plan address all four identified issues (node, tunnel, auth-profiles, groupPolicy)?
- [ ] Is the Cloudflare tunnel setup correct and complete?
- [ ] Will the SSH ProxyCommand approach work with node.cmd's `start /b` SSH tunnel?
- [ ] Is the auth-profiles fix correct (adding type/provider fields)?
- [ ] Is the groupPolicy fix appropriate?
- [ ] Are backup/rollback procedures adequate for all phases?
- [ ] Any security concerns with the scheduled task configuration?
- [ ] Should MEMORY.md be updated after completion (remove WireGuard refs, add Cloudflare tunnel)?
- [ ] Is the phase ordering correct (Cloudflare tunnel → Pi config fixes → gateway restart → laptop node)?

---

**This plan is ready for external review before execution. Copy to Claude.ai for adversarial review.**