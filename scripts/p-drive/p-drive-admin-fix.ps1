# P: Drive Admin Fix — runs as SYSTEM via scheduled task (every 1 minute)
# SMB1 required for \\192.168.0.116 — server does not support SMB2+. Remove when server is replaced.
#
# Logic:
#   - ALWAYS check needs-admin.flag (fast)
#   - Full SMB1/network-profile checks ONLY during business hours (Mon-Fri 7am-4pm) OR when flag exists
#   - Outside business hours without flag: exit immediately

$LogDir = "C:\tmp\p-drive"
$LogFile = "$LogDir\p.log"
$FlagFile = "$LogDir\needs-admin.flag"
$MaxLogSize = 5MB

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
    $entry = "[$timestamp] [ADMIN] [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry -Encoding UTF8

    # For loud warnings, also write to Windows Event Log
    if ($Level -eq "WARN" -or $Level -eq "LOUD") {
        try {
            Write-EventLog -LogName Application -Source "P-Drive Admin" -EventId 1001 -EntryType Warning -Message $Message -ErrorAction SilentlyContinue
        } catch {}
    }
}

function Test-BusinessHours {
    $now = Get-Date
    $dayOfWeek = $now.DayOfWeek
    $hour = $now.Hour

    # Mon-Fri (1-5), 7am-4pm (7-16)
    $isWeekday = $dayOfWeek -ge [DayOfWeek]::Monday -and $dayOfWeek -le [DayOfWeek]::Friday
    $isBusinessHour = $hour -ge 7 -and $hour -lt 16

    return ($isWeekday -and $isBusinessHour)
}

function Test-SMB1Enabled {
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol-Client -ErrorAction Stop
        return ($feature.State -eq "Enabled")
    } catch {
        Write-PLog "Failed to check SMB1 status: $_" "ERROR"
        return $null
    }
}

function Enable-SMB1 {
    Write-PLog "========================================" "LOUD"
    Write-PLog "SMB1 WAS DISABLED - RE-ENABLING NOW" "LOUD"
    Write-PLog "This is a SECURITY RISK but required for \\192.168.0.116" "LOUD"
    Write-PLog "Root cause: Windows Update or security policy disabled SMB1" "LOUD"
    Write-PLog "Long-term fix: Replace file server with SMB2+ compatible system" "LOUD"
    Write-PLog "========================================" "LOUD"

    try {
        Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -All -NoRestart -ErrorAction Stop
        Write-PLog "SMB1 re-enabled successfully. Reboot may be required for full effect." "WARN"
        return $true
    } catch {
        Write-PLog "FAILED to enable SMB1: $_" "ERROR"
        return $false
    }
}

function Test-NetworkProfilePrivate {
    try {
        # Find active Ethernet adapter with internet connectivity
        $profile = Get-NetConnectionProfile -ErrorAction Stop | Where-Object {
            $_.InterfaceAlias -match "Ethernet" -and $_.IPv4Connectivity -eq "Internet"
        } | Select-Object -First 1

        if (-not $profile) {
            return @{ Found = $false; IsPrivate = $false; InterfaceAlias = $null }
        }

        return @{
            Found = $true
            IsPrivate = ($profile.NetworkCategory -eq "Private")
            InterfaceAlias = $profile.InterfaceAlias
        }
    } catch {
        Write-PLog "Failed to check network profile: $_" "ERROR"
        return @{ Found = $false; IsPrivate = $false; InterfaceAlias = $null }
    }
}

function Set-NetworkProfilePrivate {
    param([string]$InterfaceAlias)

    Write-PLog "Network profile is Public - changing to Private for file sharing" "WARN"

    try {
        Set-NetConnectionProfile -InterfaceAlias $InterfaceAlias -NetworkCategory Private -ErrorAction Stop
        Write-PLog "Network profile changed to Private successfully" "INFO"
        return $true
    } catch {
        Write-PLog "FAILED to change network profile: $_" "ERROR"
        return $false
    }
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

$flagExists = Test-Path $FlagFile
$isBusinessHours = Test-BusinessHours

# Always clear flag if it exists (we're handling it now)
if ($flagExists) {
    Write-PLog "Flag file detected - running full diagnostics" "INFO"
    Remove-Item $FlagFile -Force -ErrorAction SilentlyContinue
}

# Outside business hours and no flag? Exit fast.
if (-not $isBusinessHours -and -not $flagExists) {
    # Silent exit - don't even log to avoid log spam every minute
    exit 0
}

# Log that we're running (but only during business hours or with flag)
if ($isBusinessHours) {
    # Only log periodically during business hours to avoid spam
    $lastRunFile = "$LogDir\last-admin-run.txt"
    $shouldLog = $true
    if (Test-Path $lastRunFile) {
        $lastRun = Get-Content $lastRunFile -ErrorAction SilentlyContinue
        if ($lastRun) {
            try {
                $lastRunTime = [DateTime]::Parse($lastRun)
                # Only log every 15 minutes during normal operation
                if ((Get-Date) - $lastRunTime -lt [TimeSpan]::FromMinutes(15)) {
                    $shouldLog = $false
                }
            } catch {}
        }
    }

    if ($shouldLog) {
        Write-PLog "Running scheduled check (business hours)" "INFO"
        Set-Content $lastRunFile (Get-Date).ToString("o") -Force
    }
}

# Check SMB1
$smb1Enabled = Test-SMB1Enabled
if ($smb1Enabled -eq $false) {
    Enable-SMB1
} elseif ($smb1Enabled -eq $null) {
    Write-PLog "Could not determine SMB1 status" "WARN"
}

# Check network profile
$networkStatus = Test-NetworkProfilePrivate
if ($networkStatus.Found -and -not $networkStatus.IsPrivate) {
    Set-NetworkProfilePrivate -InterfaceAlias $networkStatus.InterfaceAlias
}

exit 0
