---
name: ssh-manage
description: SSH connection management, troubleshooting, and key setup for Dejavara infrastructure
user-invocable: true
metadata: {"openclaw":{"emoji":"🔐","os":["win32"]}}
---

# SSH Management Skill

Diagnose, fix, and manage SSH connections across Dejavara infrastructure.

## Quick Reference

| Host | IP | User | Notes |
|------|----|----- |-------|
| cambium-server | 192.168.0.108 (DHCP) | User | Shop server, Windows |
| cambium-server-tunnel | via Cloudflare | User | Remote fallback |
| phteah-pi | 192.168.1.76 | dejavara | Home Pi, Linux |

**SSH Config:** `~/.ssh/config`
**Laptop Key:** `~/.ssh/id_ed25519.pub`

## Commands

### /ssh status
Test connectivity to all configured hosts.

```powershell
# Test all hosts
@("cambium-server", "phteah-pi") | ForEach-Object {
    $result = ssh -o ConnectTimeout=3 -o BatchMode=yes $_ "hostname" 2>&1
    if ($LASTEXITCODE -eq 0) { "✅ $_`: $result" } else { "❌ $_`: Connection failed" }
}
```

### /ssh fix <host>
Diagnose and fix connection issues.

**Diagnostic steps:**
1. Test basic connectivity: `ssh -v -o ConnectTimeout=5 <host> hostname`
2. Check if host key changed: Look for "REMOTE HOST IDENTIFICATION HAS CHANGED"
3. Check auth method: BatchMode will fail if key auth isn't set up

**Common fixes:**
- **Host key changed:** `ssh-keygen -R <hostname>` then reconnect
- **IP changed:** Update `~/.ssh/config` with new IP
- **Key not authorized:** Add public key to remote authorized_keys

### /ssh setup <host>
Set up key-based authentication for a new host.

**For Windows servers (like Cambium-server):**
```powershell
# Get your public key
$pubkey = Get-Content ~/.ssh/id_ed25519.pub

# On the Windows server (for admin users):
# Add to C:\ProgramData\ssh\administrators_authorized_keys
# NOT to %USERPROFILE%\.ssh\authorized_keys

# Verify permissions (must be owned by SYSTEM/Admins only)
icacls "C:\ProgramData\ssh\administrators_authorized_keys"
```

**For Linux servers (like Phteah-pi):**
```bash
# Copy key to server
ssh-copy-id user@hostname

# Or manually:
cat ~/.ssh/id_ed25519.pub | ssh user@hostname "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

## Troubleshooting Flowchart

```
SSH fails
    │
    ├─ "Connection timed out"
    │   └─ Wrong IP? Check: ping <ip>
    │       └─ If no ping: host down or IP changed
    │       └─ If ping OK: firewall blocking port 22
    │
    ├─ "Connection refused"
    │   └─ SSH service not running on target
    │       └─ Windows: Get-Service sshd
    │       └─ Linux: systemctl status sshd
    │
    ├─ "Permission denied (publickey)"
    │   └─ Key not in authorized_keys
    │       └─ Windows admin: C:\ProgramData\ssh\administrators_authorized_keys
    │       └─ Windows user: %USERPROFILE%\.ssh\authorized_keys
    │       └─ Linux: ~/.ssh/authorized_keys
    │
    └─ "Host key verification failed"
        └─ Server reinstalled or IP reused
            └─ Fix: ssh-keygen -R <hostname>
```

## Host-Specific Notes

### cambium-server (Shop Windows Server)

**DHCP IP** - May change. If connection fails:
1. Check actual IP via Chrome Remote Desktop: `ipconfig | findstr IPv4`
2. Update `~/.ssh/config`: `HostName 192.168.0.XXX`

**Windows SSH quirk:** Admin users read keys from `C:\ProgramData\ssh\administrators_authorized_keys`, not user profile.

**Firewall rule:** "OpenSSH SSH Server (sshd)" must be Enabled/Allow.

**Fallback:** Use `cambium-server-tunnel` (Cloudflare) if LAN unreachable.

### phteah-pi (Home Raspberry Pi)

**Static IP:** 192.168.1.76 on home LAN.

**Remote access:** Via WireGuard VPN (laptop gets 10.8.0.3).

**User:** `dejavara` (not root).

## Scripts

### Test all connections
```powershell
# ssh-test-all.ps1
$hosts = @(
    @{Name="cambium-server"; Timeout=3},
    @{Name="cambium-server-tunnel"; Timeout=10},
    @{Name="phteah-pi"; Timeout=3}
)

foreach ($h in $hosts) {
    Write-Host -NoNewline "$($h.Name): "
    $result = ssh -o ConnectTimeout=$($h.Timeout) -o BatchMode=yes $h.Name "hostname" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ $result" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed" -ForegroundColor Red
    }
}
```

### Update SSH config IP
```powershell
# update-ssh-ip.ps1 -Host cambium-server -NewIP 192.168.0.XXX
param([string]$Host, [string]$NewIP)

$config = Get-Content ~/.ssh/config -Raw
$config = $config -replace "(?<=Host $Host\r?\n\s+HostName )\d+\.\d+\.\d+\.\d+", $NewIP
$config | Set-Content ~/.ssh/config
Write-Host "Updated $Host to $NewIP"
```

## Response Format

When reporting SSH status:
```
🔐 SSH Status
├─ cambium-server [LAN]: ✅ Connected (192.168.0.108)
├─ cambium-server-tunnel [WAN]: ✅ Available
└─ phteah-pi [VPN]: ❌ VPN not connected
```