# Sync Server Projects to Local Mirror on Cambium
# Runs Mon-Fri at 7:30 AM, 12:30 PM (before Dejavara syncs)
# Source: P:\ (\\Server\Projects)
# Destination: C:\Server-Mirror\

$source = "P:\"
$destination = "C:\Server-Mirror"
$logDir = "C:\Server-Mirror\_sync-logs"
$logFile = "$logDir\sync-$(Get-Date -Format 'yyyy-MM-dd_HHmm').log"

# Ensure log directory exists
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Ensure P: drive is mapped (credentials embedded for scheduled task)
if (-not (Test-Path $source)) {
    Write-Output "$(Get-Date): P: drive not accessible. Mapping..." | Out-File $logFile
    $result = net use P: \\Server\Projects /persistent:yes /user:steves-p-drive 7328 2>&1
    Write-Output $result | Out-File $logFile -Append
    Start-Sleep -Seconds 3
    if (-not (Test-Path $source)) {
        Write-Output "$(Get-Date): FAILED - Could not connect to P: drive" | Out-File $logFile -Append
        exit 1
    }
}

Write-Output "$(Get-Date): Starting sync from $source to $destination" | Out-File $logFile -Append

# Robocopy — copy new/updated files from server, never delete local files
robocopy $source $destination /E /Z /W:5 /R:3 /MT:8 /XO /XD "$destination\_sync-logs" /LOG+:$logFile /NP /NDL /TEE

$exitCode = $LASTEXITCODE

if ($exitCode -le 7) {
    Write-Output "$(Get-Date): Sync completed successfully (exit code: $exitCode)" | Out-File $logFile -Append
} else {
    Write-Output "$(Get-Date): Sync completed with errors (exit code: $exitCode)" | Out-File $logFile -Append
}

# Clean up old logs (keep last 30 days)
Get-ChildItem "$logDir\sync-*.log" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force

exit $exitCode