# Setup "Connect Shop Server" Scheduled Task
# Triggers: logon + network connect (EventID 10000)
# Run as Administrator

$scriptPath = "C:\Dev\Dejavara\scripts\connect-server.ps1"
$taskName = "Connect Shop Server"

# Remove existing task if present
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Action
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Trigger 1: At logon
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Trigger 2: Network connected (EventID 10000 = new network profile connected)
$CIMClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler
$triggerNetwork = $CIMClass | New-CimInstance -ClientOnly
$triggerNetwork.Enabled = $true
$triggerNetwork.Subscription = @'
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational">
    <Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[EventID=10000]]</Select>
  </Query>
</QueryList>
'@
$triggerNetwork.Delay = "PT10S"  # 10-second delay for network to stabilize

# Settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($triggerLogon, $triggerNetwork) -Settings $settings -Description "Connect P: drive to \\Server\Projects on shop LAN (logon + network connect)"

Write-Host "Scheduled task '$taskName' registered." -ForegroundColor Green
Write-Host ""
Write-Host "Triggers:" -ForegroundColor Cyan
Write-Host "  1. At logon"
Write-Host "  2. On network connect (10s delay)"
Write-Host ""
Write-Host "Script: $scriptPath"
