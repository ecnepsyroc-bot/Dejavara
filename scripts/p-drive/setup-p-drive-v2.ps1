# P: Drive Setup v2 — Self-verifying setup script
# Run once as Administrator to set up the P: drive monitoring system
#
# Creates:
#   - Log directory: C:\tmp\p-drive\
#   - Scheduled task: "P-Drive Admin Fix" (runs every 1 minute)

$ErrorActionPreference = "Stop"

$TaskName = "P-Drive Admin Fix"
$ScriptPath = "C:\Dev\Dejavara\scripts\p-drive\p-drive-admin-fix.ps1"
$LogDir = "C:\tmp\p-drive"

Write-Host "P: Drive Setup v2" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

$errors = @()
$warnings = @()

# 1. Create log directory
Write-Host "1. Log directory..." -NoNewline
if (-not (Test-Path $LogDir)) {
    try {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
        Write-Host " Created" -ForegroundColor Green
    } catch {
        Write-Host " FAILED: $_" -ForegroundColor Red
        $errors += "Failed to create log directory"
    }
} else {
    Write-Host " Already exists" -ForegroundColor Green
}

# 2. Verify script exists
Write-Host "2. Admin script..." -NoNewline
if (Test-Path $ScriptPath) {
    Write-Host " Found" -ForegroundColor Green
} else {
    Write-Host " NOT FOUND" -ForegroundColor Red
    $errors += "Admin script not found at $ScriptPath"
}

# 3. Create Windows Event Log source (for loud logging)
Write-Host "3. Event log source..." -NoNewline
try {
    if (-not [System.Diagnostics.EventLog]::SourceExists("P-Drive Admin")) {
        New-EventLog -LogName Application -Source "P-Drive Admin" -ErrorAction Stop
        Write-Host " Created" -ForegroundColor Green
    } else {
        Write-Host " Already exists" -ForegroundColor Green
    }
} catch {
    Write-Host " Skipped (non-critical)" -ForegroundColor Yellow
    $warnings += "Could not create event log source: $_"
}

# 4. Create or update scheduled task
Write-Host "4. Scheduled task..." -NoNewline

# Remove existing task if present
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host " Removed old task..." -NoNewline
}

try {
    # Action: Run PowerShell with the admin fix script
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

    # Triggers: Boot (30s delay) + repeat every 1 minute indefinitely
    $bootTrigger = New-ScheduledTaskTrigger -AtStartup
    $bootTrigger.Delay = "PT30S"

    # For minute-level repetition, we use a daily trigger with repetition
    $dailyTrigger = New-ScheduledTaskTrigger -Daily -At "00:00"
    $dailyTrigger.Repetition = New-Object -ComObject "Schedule.Service" | Out-Null  # We'll set this differently

    # Actually, use a different approach - create a time trigger that repeats
    # PowerShell's New-ScheduledTaskTrigger doesn't directly support minute intervals
    # So we'll register the task and then modify it

    # Create task with boot trigger first
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
        -MultipleInstances IgnoreNew

    # Register with boot trigger
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $bootTrigger -Principal $principal -Settings $settings -Force | Out-Null

    # Now add the repetition trigger using COM (PowerShell cmdlets don't support 1-minute intervals well)
    $taskService = New-Object -ComObject "Schedule.Service"
    $taskService.Connect()
    $rootFolder = $taskService.GetFolder("\")
    $task = $rootFolder.GetTask($TaskName)
    $definition = $task.Definition

    # Add a trigger that starts at midnight and repeats every minute
    $trigger = $definition.Triggers.Create(2)  # 2 = Daily trigger
    $trigger.StartBoundary = (Get-Date -Hour 0 -Minute 0 -Second 0).ToString("yyyy-MM-ddTHH:mm:ss")
    $trigger.Repetition.Interval = "PT1M"  # Every 1 minute
    $trigger.Repetition.Duration = ""  # Indefinitely
    $trigger.Repetition.StopAtDurationEnd = $false

    # Save the task
    $rootFolder.RegisterTaskDefinition($TaskName, $definition, 6, "SYSTEM", $null, 5) | Out-Null

    Write-Host " Created" -ForegroundColor Green
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    $errors += "Failed to create scheduled task: $_"
}

# 5. Verify task
Write-Host "5. Verifying task..." -NoNewline
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host " OK (State: $($task.State))" -ForegroundColor Green
} else {
    Write-Host " NOT FOUND" -ForegroundColor Red
    $errors += "Task verification failed"
}

# Summary
Write-Host ""
Write-Host "=================" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "Setup COMPLETE" -ForegroundColor Green
    Write-Host ""
    Write-Host "The P-Drive Admin Fix task will:" -ForegroundColor White
    Write-Host "  - Run every 1 minute" -ForegroundColor Gray
    Write-Host "  - Check SMB1 status during business hours (Mon-Fri 7am-4pm)" -ForegroundColor Gray
    Write-Host "  - Re-enable SMB1 if Windows disables it" -ForegroundColor Gray
    Write-Host "  - Fix network profile if set to Public" -ForegroundColor Gray
    Write-Host "  - Respond to needs-admin.flag at any time" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Logs: $LogDir\p.log" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To test, run:" -ForegroundColor Yellow
    Write-Host "  schtasks /run /tn `"$TaskName`"" -ForegroundColor White
    Write-Host "  Get-Content $LogDir\p.log -Tail 20" -ForegroundColor White
} else {
    Write-Host "Setup FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Errors:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

exit $errors.Count
