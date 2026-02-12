# Sync Server Projects to Local Mirror
# Runs Mon-Fri at 8:00 AM, 11:00 AM, 3:00 PM
# Source: P:\ (\\Server\Projects)
# Destination: D:\Server-Mirror\

$source = "P:\"
$destination = "C:\Server-Mirror"
$logFile = "C:\Server-Mirror\_sync-logs\sync-$(Get-Date -Format 'yyyy-MM-dd_HHmm').log"

# Ensure log directory exists
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Check if P: drive is accessible
if (-not (Test-Path $source)) {
    Write-Output "$(Get-Date): ERROR - P: drive not accessible. Attempting to reconnect..."
    net use P: \\Server\Projects /persistent:yes 2>&1
    Start-Sleep -Seconds 5
    if (-not (Test-Path $source)) {
        Write-Output "$(Get-Date): FAILED - Could not connect to P: drive" | Out-File $logFile -Append
        exit 1
    }
}

Write-Output "$(Get-Date): Starting sync from $source to $destination" | Out-File $logFile

# Robocopy mirror mode
# /MIR = Mirror (copies new/changed, deletes removed)
# /Z = Restartable mode (for large files over network)
# /W:5 = Wait 5 seconds between retries
# /R:3 = Retry 3 times
# /MT:8 = 8 threads for faster copy
# /XD = Exclude directories
# /XF = Exclude files
# /LOG+ = Append to log
# /NP = No progress (cleaner logs)
# /NDL = No directory list (less verbose)

robocopy $source $destination /MIR /Z /W:5 /R:3 /MT:8 /XD "$destination\_sync-logs" /LOG+:$logFile /NP /NDL /TEE

$exitCode = $LASTEXITCODE

# Robocopy exit codes: 0-7 are success, 8+ are errors
if ($exitCode -le 7) {
    Write-Output "$(Get-Date): Sync completed successfully (exit code: $exitCode)" | Out-File $logFile -Append
} else {
    Write-Output "$(Get-Date): Sync completed with errors (exit code: $exitCode)" | Out-File $logFile -Append
}

# Clean up old logs (keep last 30 days)
Get-ChildItem "$logDir\sync-*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force

exit $exitCode