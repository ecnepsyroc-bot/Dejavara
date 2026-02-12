# Setup Scheduled Tasks for Server Projects Sync
# Run this script as Administrator

$scriptPath = "C:\Dev\Dejavara\scripts\sync-server-projects.ps1"
$taskName = "Sync-Server-Projects"

# Remove existing task if present
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Create triggers for 8 AM, 11 AM, 3 PM on weekdays
$triggers = @(
    New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 8:00AM
    New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 11:00AM
    New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At 3:00PM
)

# Action: Run PowerShell with the sync script
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Principal: Run as current user
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U -RunLevel Limited

# Register the task
Register-ScheduledTask -TaskName $taskName -Trigger $triggers -Action $action -Settings $settings -Principal $principal -Description "Sync P:\(Server Projects) to D:\Server-Mirror - Mon-Fri at 8am, 11am, 3pm"

Write-Host "Scheduled task '$taskName' created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Schedule:" -ForegroundColor Cyan
Write-Host "  - Monday-Friday at 8:00 AM"
Write-Host "  - Monday-Friday at 11:00 AM"
Write-Host "  - Monday-Friday at 3:00 PM"
Write-Host ""
Write-Host "Source: P:\ (\\Server\Projects)"
Write-Host "Destination: C:\Server-Mirror\"
Write-Host "Logs: C:\Server-Mirror\_sync-logs\"
Write-Host ""
Write-Host "To run manually: .\sync-server-projects.ps1" -ForegroundColor Yellow
Write-Host "To view task: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Yellow