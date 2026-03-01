# sync-openclaw-oauth.ps1 v2 - Sync Claude Code OAuth tokens to OpenClaw gateway
# Runs every 2 hours via scheduled task to keep agent tokens fresh
# v2: Auto-refresh, 30-min buffer, better error messages

$ErrorActionPreference = "Stop"
$logDir = "C:\tmp\openclaw"
$logFile = "$logDir\oauth-sync.log"
$sshHost = "phteah-pi"
$credFile = "$env:USERPROFILE\.claude\.credentials.json"
$agents = @("chair", "claude", "grok", "gemini", "deepseek", "wife", "main")
$basePath = "/mnt/data/docker/openclaw/config/agents"
$bufferMs = 30 * 60 * 1000  # 30 minutes buffer before expiry

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts $msg"
    Write-Host $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

function Get-NowMs {
    [long]((Get-Date).ToUniversalTime() - [datetime]"1970-01-01").TotalMilliseconds
}

function Get-ExpiryDate($ms) {
    (Get-Date "1970-01-01 00:00:00").AddMilliseconds($ms)
}

# Ensure log directory exists
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

Log "=== OAuth Sync v2 Started ==="

# 1. Trigger Claude CLI to refresh tokens if needed
Log "Triggering Claude CLI auth check..."
$authResult = & claude auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "WARNING: Claude auth status returned non-zero exit code"
    Log "Output: $authResult"
}

# 2. Read Claude Code credentials
if (-not (Test-Path $credFile)) {
    Log "ERROR: Claude Code credentials not found at $credFile"
    Log "ACTION: Run 'claude auth login' on this machine"
    exit 1
}

$creds = Get-Content $credFile -Raw | ConvertFrom-Json
$oauth = $creds.claudeAiOauth

if (-not $oauth) {
    Log "ERROR: claudeAiOauth section missing from credentials"
    Log "ACTION: Run 'claude auth login' on this machine"
    exit 1
}

$accessToken = $oauth.accessToken
$refreshToken = $oauth.refreshToken
$expiresAt = $oauth.expiresAt
$nowMs = Get-NowMs

# 3. Check if tokens are expired or expiring soon
if ($expiresAt -lt $nowMs) {
    Log "ERROR: Source tokens already expired"
    Log "Expired at: $(Get-ExpiryDate $expiresAt) UTC"
    Log "ACTION: Run 'claude auth login' on this machine"
    exit 1
}

if ($expiresAt -lt ($nowMs + $bufferMs)) {
    Log "WARNING: Tokens expire within 30 minutes. Attempting refresh..."

    # Force refresh by running auth status again
    $null = & claude auth status 2>&1
    Start-Sleep -Seconds 2

    # Re-read credentials after refresh attempt
    $creds = Get-Content $credFile -Raw | ConvertFrom-Json
    $oauth = $creds.claudeAiOauth
    $accessToken = $oauth.accessToken
    $refreshToken = $oauth.refreshToken
    $expiresAt = $oauth.expiresAt
    $nowMs = Get-NowMs

    if ($expiresAt -lt ($nowMs + $bufferMs)) {
        Log "ERROR: Token refresh failed. Tokens still expiring soon."
        Log "Expires at: $(Get-ExpiryDate $expiresAt) UTC"
        Log "ACTION: Run 'claude auth login' on this machine"
        exit 1
    }
    Log "Token refresh successful"
}

$expiresDate = Get-ExpiryDate $expiresAt
$remainingHours = [math]::Round(($expiresAt - $nowMs) / 3600000, 1)
Log "Source tokens valid until $expiresDate UTC ($remainingHours hours remaining)"

# 4. Test SSH connectivity
$sshTest = ssh -o ConnectTimeout=5 -o BatchMode=yes $sshHost "echo ok" 2>&1
if ($sshTest -ne "ok") {
    Log "ERROR: SSH connection failed"
    Log "Output: $sshTest"
    Log "ACTION: Check VPN connection or SSH config"
    exit 1
}
Log "SSH connection to ${sshHost} - OK"

# 5. Update each agent's auth-profiles.json
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

# 6. Handle results
if ($updated -eq 0) {
    Log "WARNING: No agents updated. Check:"
    Log "  1. SSH connectivity to Pi"
    Log "  2. Agent auth-profiles.json files exist"
    Log "  3. jq is installed on Pi"
} elseif ($updated -gt 0) {
    Log "Restarting openclaw container..."
    $restart = ssh $sshHost "docker restart openclaw 2>&1"
    Log "Container restart: $restart"
}

Log "=== OAuth Sync v2 Complete ==="
