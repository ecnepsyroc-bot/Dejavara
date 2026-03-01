# setup-oauth-sync-task.ps1 - Register scheduled task for OAuth token sync v2
# Runs every 2 hours (was 6 in v1) to match community best practices

$taskName = "OpenClaw OAuth Sync"
$scriptPath = "C:\Dev\Dejavara\scripts\sync-openclaw-oauth.ps1"

# Remove existing task if any
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Create trigger that runs every 2 hours (v2: was 6 hours)
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Hours 2) `
    -RepetitionDuration (New-TimeSpan -Days 9999)

# Create action
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Settings - run even on battery, start if missed
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Register task
Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings `
    -Description "Sync OAuth tokens from Claude Code to OpenClaw gateway (v2: every 2 hours)"

Write-Host "Registered task: $taskName (every 2 hours)"
Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State
