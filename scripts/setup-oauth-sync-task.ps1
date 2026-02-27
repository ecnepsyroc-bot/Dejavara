# setup-oauth-sync-task.ps1 - Register scheduled task for OAuth token sync

$taskName = "OpenClaw OAuth Sync"
$scriptPath = "C:\Dev\Dejavara\scripts\sync-openclaw-oauth.ps1"

# Remove existing task if any
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Create trigger that runs every 6 hours (indefinitely = 9999 days)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6) -RepetitionDuration (New-TimeSpan -Days 9999)

# Create action
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Settings - run even on battery, start if missed
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Register task
Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings `
    -Description "Sync OAuth tokens from Claude Code to OpenClaw gateway every 6 hours"

Write-Host "Registered task: $taskName"
Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State
