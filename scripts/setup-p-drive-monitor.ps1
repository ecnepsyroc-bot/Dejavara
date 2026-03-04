# Setup Scheduled Task to Monitor P: Drive Connection
# Run this ONCE as Administrator to create the scheduled task
# The task will run on startup and ensure P: drive stays connected

$ErrorActionPreference = "Stop"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

$taskName = "Ensure P-Drive Connection"
$scriptPath = "C:\Dev\Dejavara\scripts\ensure-p-drive.ps1"

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: ensure-p-drive.ps1 not found at $scriptPath" -ForegroundColor Red
    exit 1
}

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Removing existing task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create the scheduled task
Write-Host "Creating scheduled task: $taskName" -ForegroundColor Cyan

# Task action: Run the PowerShell script with elevated privileges
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Task triggers:
# 1. At system startup
# 2. At user logon
# 3. When network connection is established
$trigger1 = New-ScheduledTaskTrigger -AtStartup
$trigger2 = New-ScheduledTaskTrigger -AtLogOn
$trigger3 = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Task settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

# Task principal: Run with highest privileges (Administrator)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the task
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger1, $trigger2, $trigger3 `
    -Settings $settings `
    -Principal $principal `
    -Description "Ensures P: drive (\\Server\Projects) stays connected and SMB1 protocol remains enabled. Prevents Windows Updates from breaking shop file server access."

Write-Host "`nScheduled task created successfully!" -ForegroundColor Green
Write-Host "`nTask Details:" -ForegroundColor Cyan
Write-Host "  Name: $taskName" -ForegroundColor White
Write-Host "  Runs: At startup, at logon, and when network connects" -ForegroundColor White
Write-Host "  Privilege: SYSTEM (Administrator)" -ForegroundColor White
Write-Host "  Script: $scriptPath" -ForegroundColor White

Write-Host "`nTesting the task now..." -ForegroundColor Yellow
Start-ScheduledTask -TaskName $taskName

Start-Sleep -Seconds 3

Write-Host "`nTask status:" -ForegroundColor Cyan
Get-ScheduledTask -TaskName $taskName | Select-Object TaskName, State, LastRunTime, LastTaskResult

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "P: drive will now be automatically reconnected on startup." -ForegroundColor Cyan
Write-Host "If Windows Update disables SMB1, it will be automatically re-enabled." -ForegroundColor Cyan
