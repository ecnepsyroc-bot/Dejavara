# Setup scheduled task for auto-connecting to shop server

$TaskName = "Connect Shop Server"
$ScriptPath = "C:\Dev\Dejavara\scripts\connect-server.ps1"

# Create action
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

# Trigger at logon for current user
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Create and register task
$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings -Description "Auto-connect to shop server P: drive at login"
Register-ScheduledTask -TaskName $TaskName -InputObject $Task -Force

Write-Host "Scheduled task '$TaskName' created successfully!"
Write-Host "It will run at each login to ensure P: drive is connected to \\Server\Projects"
