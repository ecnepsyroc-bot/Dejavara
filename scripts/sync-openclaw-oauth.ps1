# sync-openclaw-oauth.ps1 - Sync Claude Code OAuth tokens to OpenClaw gateway
# Runs every 6 hours via scheduled task to keep agent tokens fresh

$ErrorActionPreference = "Stop"
$logDir = "C:\tmp\openclaw"
$logFile = "$logDir\oauth-sync.log"
$sshHost = "phteah-pi"
$credFile = "$env:USERPROFILE\.claude\.credentials.json"
$agents = @("chair", "claude", "grok", "gemini", "deepseek", "wife", "main")
$basePath = "/mnt/data/docker/openclaw/config/agents"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

# Ensure log directory exists
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

Log "=== OAuth Sync Started ==="

# 1. Read Claude Code credentials
if (-not (Test-Path $credFile)) {
    Log "ERROR: Claude Code credentials not found at $credFile"
    exit 1
}

$creds = Get-Content $credFile -Raw | ConvertFrom-Json
$oauth = $creds.claudeAiOauth

if (-not $oauth) {
    Log "ERROR: claudeAiOauth section missing from credentials"
    exit 1
}

$accessToken = $oauth.accessToken
$refreshToken = $oauth.refreshToken
$expiresAt = $oauth.expiresAt

# 2. Check if tokens are already expired
$nowMs = [long]((Get-Date).ToUniversalTime() - [datetime]"1970-01-01").TotalMilliseconds
if ($expiresAt -lt $nowMs) {
    Log "WARNING: Source tokens already expired (expiresAt=$expiresAt, now=$nowMs). Skipping sync."
    exit 0
}

$expiresDate = (Get-Date "1970-01-01 00:00:00").AddMilliseconds($expiresAt)
Log "Source tokens valid until $expiresDate UTC"

# 3. Test SSH connectivity
$sshTest = ssh -o ConnectTimeout=5 -o BatchMode=yes $sshHost "echo ok" 2>&1
if ($sshTest -ne "ok") {
    Log "ERROR: SSH connection failed ($sshTest). VPN may be down. Will retry next cycle."
    exit 1
}
Log "SSH connection to ${sshHost} - OK"

# 4. Update each agent's auth-profiles.json
$updated = 0
foreach ($agent in $agents) {
    $authFile = "$basePath/$agent/agent/auth-profiles.json"

    # Check if file exists
    $exists = ssh $sshHost "test -f '$authFile' && echo yes || echo no"
    if ($exists -ne "yes") {
        Log "SKIP: $agent - auth-profiles.json not found"
        continue
    }

    # Update with jq using --arg for all values including the key name
    # This avoids all quoting issues by passing everything as jq variables
    $jqFilter = '.profiles[$k].access = $a | .profiles[$k].refresh = $r | .profiles[$k].expires = ($e | tonumber)'
    $result = ssh $sshHost "jq --arg k 'anthropic:claude-cli' --arg a '$accessToken' --arg r '$refreshToken' --arg e '$expiresAt' '$jqFilter' '$authFile' > '$authFile.tmp' && mv '$authFile.tmp' '$authFile' && echo ok || echo fail"

    if ($result -eq "ok") {
        Log "OK: $agent"
        $updated++
    } else {
        Log "FAIL: $agent - $result"
    }
}

Log "Updated $updated/$($agents.Count) agent profiles"

# 6. Restart gateway container if any updates succeeded
if ($updated -gt 0) {
    Log "Restarting openclaw container..."
    $restart = ssh $sshHost "docker restart openclaw 2>&1"
    Log "Container restart: $restart"
}

Log "=== OAuth Sync Complete ==="
