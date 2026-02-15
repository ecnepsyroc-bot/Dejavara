# Thermal Monitor - Sleeps if CPU > 80C
$threshold = 80
$logFile = "C:\tmp\openclaw\thermal-monitor.log"

# Start LibreHardwareMonitor if not running
$lhm = Get-Process -Name LibreHardwareMonitor -ErrorAction SilentlyContinue
if (-not $lhm) {
    Start-Process "C:\Program Files\LibreHardwareMonitor\LibreHardwareMonitor.exe" -WindowStyle Hidden
    Start-Sleep 5
}

# Read temps from LHM WMI
try {
    $temps = Get-WmiObject -Namespace root\LibreHardwareMonitor -Class Sensor | 
        Where-Object { $_.SensorType -eq "Temperature" -and $_.Name -like "*CPU*" } |
        Select-Object -ExpandProperty Value
    
    $maxTemp = ($temps | Measure-Object -Maximum).Maximum
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Add-Content $logFile "$timestamp - CPU Max: $maxTemp C"
    
    if ($maxTemp -gt $threshold) {
        Add-Content $logFile "$timestamp - OVERHEAT! Forcing sleep..."
        rundll32.exe powrprof.dll,SetSuspendState 0,1,0
    }
} catch {
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Error: $_"
}
