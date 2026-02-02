<#
.SYNOPSIS
    Remote diagnostics and management for Cambium production server.

.DESCRIPTION
    Helper script for common remote operations on the Cambium server.
    Uses cambium-ssh.ps1 for tunnel access.

.PARAMETER Action
    The action to perform: Status, Health, Logs, Restart, Resources

.PARAMETER LogLines
    Number of log lines to retrieve (default: 50)

.EXAMPLE
    .\cambium-remote.ps1 -Action Status
    # Check CambiumApi service status

.EXAMPLE
    .\cambium-remote.ps1 -Action Health
    # Hit health endpoint

.EXAMPLE
    .\cambium-remote.ps1 -Action Logs -LogLines 100
    # Get last 100 lines of API logs

.EXAMPLE
    .\cambium-remote.ps1 -Action Restart
    # Restart CambiumApi service (requires confirmation)

.EXAMPLE
    .\cambium-remote.ps1 -Action Resources
    # Show CPU, memory, disk usage
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Status', 'Health', 'Logs', 'Restart', 'Resources')]
    [string]$Action,

    [int]$LogLines = 50
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sshScript = Join-Path $scriptDir "cambium-ssh.ps1"

function Invoke-Remote {
    param([string]$Command)
    & $sshScript -Command $Command
}

Write-Host "=== Cambium Remote: $Action ===" -ForegroundColor Cyan

switch ($Action) {
    'Status' {
        Write-Host "Checking CambiumApi service status..." -ForegroundColor Yellow
        Invoke-Remote "Get-Service CambiumApi | Select-Object Name, Status, StartType | Format-List"
    }

    'Health' {
        Write-Host "Checking health endpoint..." -ForegroundColor Yellow
        $healthCmd = @"
try {
    `$response = Invoke-WebRequest -Uri 'http://localhost:5001/api/health' -UseBasicParsing -TimeoutSec 10
    Write-Output "Status: `$(`$response.StatusCode)"
    Write-Output "Response: `$(`$response.Content)"
} catch {
    Write-Output "Health check failed: `$_"
}
"@
        Invoke-Remote $healthCmd
    }

    'Logs' {
        Write-Host "Fetching last $LogLines log lines..." -ForegroundColor Yellow
        # Adjust log path as needed
        $logCmd = @"
`$logPath = 'C:\dev\cambium_v1\BottaERisposta\publish\logs'
if (Test-Path `$logPath) {
    `$latestLog = Get-ChildItem `$logPath -Filter '*.log' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (`$latestLog) {
        Write-Output "Log file: `$(`$latestLog.Name)"
        Get-Content `$latestLog.FullName -Tail $LogLines
    } else {
        Write-Output 'No log files found'
    }
} else {
    Write-Output "Log directory not found: `$logPath"
}
"@
        Invoke-Remote $logCmd
    }

    'Restart' {
        Write-Host "WARNING: This will restart the CambiumApi service on production!" -ForegroundColor Red
        $confirm = Read-Host "Type 'RESTART' to confirm"
        if ($confirm -ne 'RESTART') {
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit 0
        }

        Write-Host "Restarting CambiumApi service..." -ForegroundColor Yellow
        $restartCmd = @"
Stop-Service CambiumApi -Force
Start-Sleep -Seconds 3
Start-Service CambiumApi
Start-Sleep -Seconds 5
`$svc = Get-Service CambiumApi
Write-Output "Service status: `$(`$svc.Status)"
try {
    `$health = Invoke-WebRequest -Uri 'http://localhost:5001/api/health' -UseBasicParsing -TimeoutSec 10
    Write-Output "Health check: `$(`$health.StatusCode)"
} catch {
    Write-Output "Health check failed: `$_"
}
"@
        Invoke-Remote $restartCmd
    }

    'Resources' {
        Write-Host "Checking server resources..." -ForegroundColor Yellow
        $resourceCmd = @"
Write-Output '=== CPU ==='
Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 | ForEach-Object { `$_.CounterSamples.CookedValue.ToString('F1') + '% CPU' }

Write-Output '`n=== Memory ==='
`$mem = Get-CimInstance Win32_OperatingSystem
`$total = [math]::Round(`$mem.TotalVisibleMemorySize / 1MB, 1)
`$free = [math]::Round(`$mem.FreePhysicalMemory / 1MB, 1)
`$used = `$total - `$free
Write-Output "`$used GB / `$total GB used"

Write-Output '`n=== Disk ==='
Get-PSDrive -PSProvider FileSystem | Where-Object { `$_.Used -gt 0 } | ForEach-Object {
    `$usedGB = [math]::Round(`$_.Used / 1GB, 1)
    `$freeGB = [math]::Round(`$_.Free / 1GB, 1)
    Write-Output "`$(`$_.Name): `$usedGB GB used, `$freeGB GB free"
}

Write-Output '`n=== CambiumApi Process ==='
Get-Process | Where-Object { `$_.ProcessName -like '*Cambium*' -or `$_.ProcessName -like '*dotnet*' } | Select-Object ProcessName, Id, @{N='Memory(MB)';E={[math]::Round(`$_.WorkingSet64/1MB,1)}} | Format-Table
"@
        Invoke-Remote $resourceCmd
    }
}

Write-Host "`nDone." -ForegroundColor Green
