# P: Drive Connect — User-context reconnection with retry/backoff
# Called by openclaw-tray.ps1 when P: drive is disconnected
#
# Returns: $true if connected successfully, $false otherwise
# Side effects: Creates needs-admin.flag if all retries exhausted

param(
    [switch]$Silent  # Don't write to console, only log
)

$LogDir = "C:\tmp\p-drive"
$LogFile = "$LogDir\p.log"
$FlagFile = "$LogDir\needs-admin.flag"
$MaxLogSize = 5MB
$SharePath = "\\192.168.0.116\Projects"
$DriveLetter = "P:"

$MaxRetries = 5
$BaseDelay = 2  # seconds

# Ensure log directory exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-PLog {
    param([string]$Message, [string]$Level = "INFO")

    # Rotate log if too large
    if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt $MaxLogSize) {
        $oldLog = "$LogDir\p.old.log"
        if (Test-Path $oldLog) { Remove-Item $oldLog -Force }
        Rename-Item $LogFile $oldLog -Force
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [CONNECT] [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry -Encoding UTF8

    if (-not $Silent) {
        switch ($Level) {
            "ERROR" { Write-Host $Message -ForegroundColor Red }
            "WARN"  { Write-Host $Message -ForegroundColor Yellow }
            "OK"    { Write-Host $Message -ForegroundColor Green }
            default { Write-Host $Message }
        }
    }
}

function Remove-StaleConnection {
    # Remove stale P: drive connection with timeout
    # net use /delete can hang if server is unreachable

    Write-PLog "Clearing stale connections..."

    # Start the delete in a job with timeout
    $job = Start-Job -ScriptBlock {
        param($DriveLetter)
        $result = net use $DriveLetter /delete /y 2>&1
        return $result
    } -ArgumentList $DriveLetter

    $completed = Wait-Job $job -Timeout 5
    if ($completed) {
        $result = Receive-Job $job
        Remove-Job $job -Force
        Write-PLog "Stale connection cleanup: $result"
    } else {
        Stop-Job $job
        Remove-Job $job -Force
        Write-PLog "Stale connection cleanup timed out (5s) - continuing anyway" "WARN"
    }

    # Also try to clear any cached connections to the IP
    Start-Job -ScriptBlock {
        net use * /delete /y 2>&1 | Where-Object { $_ -match "192.168.0.116" }
    } | Wait-Job -Timeout 3 | Remove-Job -Force -ErrorAction SilentlyContinue
}

function Test-PDriveAccessible {
    # Verify we can actually read from the drive (not just that it's mapped)
    try {
        $null = Get-ChildItem "$DriveLetter\" -ErrorAction Stop | Select-Object -First 1
        return $true
    } catch {
        return $false
    }
}

function Connect-PDrive {
    # Attempt to connect with implicit Windows auth (matches existing map-p-drive.cmd)
    $result = net use $DriveLetter $SharePath /persistent:yes 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        # Verify we can actually access it
        if (Test-PDriveAccessible) {
            return @{ Success = $true; Message = "Connected and accessible" }
        } else {
            return @{ Success = $false; Message = "Mapped but not accessible"; NeedsAdmin = $true }
        }
    } else {
        # Parse common error codes
        $errorMsg = "$result"
        $needsAdmin = $false

        if ($errorMsg -match "error 53") {
            $errorMsg = "Network path not found (error 53)"
        } elseif ($errorMsg -match "error 5") {
            $errorMsg = "Access denied (error 5)"
            $needsAdmin = $true  # Might be SMB1 or credential issue
        } elseif ($errorMsg -match "error 67") {
            $errorMsg = "Network name not found (error 67)"
        } elseif ($errorMsg -match "error 1219") {
            $errorMsg = "Multiple connections not allowed (error 1219)"
            # Try to clear and retry
            Remove-StaleConnection
        } elseif ($errorMsg -match "error 85") {
            $errorMsg = "Drive letter already in use (error 85)"
        }

        return @{ Success = $false; Message = $errorMsg; NeedsAdmin = $needsAdmin }
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

Write-PLog "Starting P: drive reconnection attempt"

# First, clear any stale connections
Remove-StaleConnection

# Retry loop with exponential backoff
$needsAdminFlag = $false

for ($i = 1; $i -le $MaxRetries; $i++) {
    Write-PLog "Attempt $i of $MaxRetries..."

    $result = Connect-PDrive

    if ($result.Success) {
        Write-PLog "Connected successfully on attempt $i" "OK"
        return $true
    }

    Write-PLog "Attempt $i failed: $($result.Message)" "WARN"

    if ($result.NeedsAdmin) {
        $needsAdminFlag = $true
    }

    if ($i -lt $MaxRetries) {
        $delay = [math]::Pow(2, $i - 1) * $BaseDelay
        Write-PLog "Waiting $delay seconds before retry..."
        Start-Sleep -Seconds $delay
    }
}

# All retries exhausted
Write-PLog "All $MaxRetries retries exhausted" "ERROR"

if ($needsAdminFlag -or $true) {
    # Always flag for admin check when we can't connect
    Write-PLog "Creating needs-admin.flag for admin task to investigate" "WARN"
    Set-Content $FlagFile (Get-Date).ToString("o") -Force
}

return $false
