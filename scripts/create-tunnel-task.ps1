$action = New-ScheduledTaskAction -Execute 'C:\Users\cory\.openclaw\tunnel-watchdog.cmd'
$trigger = New-ScheduledTaskTrigger -AtLogOn -User 'cory'
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 72) -MultipleInstances IgnoreNew -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId 'cory' -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName 'OpenClaw Tunnel' -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force

# Add wake-from-sleep trigger (Event ID 1 from Power-Troubleshooter)
$task = Get-ScheduledTask -TaskName 'OpenClaw Tunnel'
$xml = Export-ScheduledTask -TaskName 'OpenClaw Tunnel'
# Insert event trigger before closing </Triggers>
$eventTrigger = @"
    <EventTrigger>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0"&gt;&lt;Select Path="System"&gt;*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
"@
$xml = $xml -replace '</Triggers>', "$eventTrigger`n  </Triggers>"
Unregister-ScheduledTask -TaskName 'OpenClaw Tunnel' -Confirm:$false
Register-ScheduledTask -TaskName 'OpenClaw Tunnel' -Xml $xml

Write-Host "Scheduled task 'OpenClaw Tunnel' created successfully"
