# Sync Server Projects from Cambium (via tunnel) to Dejavara
# For after-hours use when not on shop LAN
# Source: Cambium C:\Server-Mirror (via SSH tunnel)
# Destination: C:\Server-Mirror\

$destination = "C:\Server-Mirror"
$logDir = "C:\Server-Mirror\_sync-logs"
$logFile = "$logDir\tunnel-sync-$(Get-Date -Format 'yyyy-MM-dd_HHmm').log"
$sshHost = "cambium-server-tunnel"
$remoteSource = "/cygdrive/c/Server-Mirror/"

# Ensure directories exist
if (-not (Test-Path $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
}
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

Write-Output "$(Get-Date): Starting tunnel sync from Cambium to Dejavara" | Out-File $logFile

# Check if we're on shop LAN (if so, use direct P: sync instead)
$lanTest = Test-Connection -ComputerName 192.168.0.116 -Count 1 -Quiet -ErrorAction SilentlyContinue
if ($lanTest) {
    Write-Output "$(Get-Date): On shop LAN - use sync-server-projects.ps1 instead for direct P: access" | Out-File $logFile -Append
    Write-Host "You're on the shop LAN. Use .\sync-server-projects.ps1 for faster direct sync." -ForegroundColor Yellow
    exit 0
}

Write-Output "$(Get-Date): Not on shop LAN, using tunnel to Cambium..." | Out-File $logFile -Append

# Test tunnel connectivity
$tunnelTest = ssh $sshHost "echo OK" 2>&1
if ($tunnelTest -ne "OK") {
    Write-Output "$(Get-Date): FAILED - Cannot connect to Cambium via tunnel" | Out-File $logFile -Append
    Write-Host "Cannot connect to Cambium tunnel. Check cloudflared and VPN." -ForegroundColor Red
    exit 1
}

Write-Output "$(Get-Date): Tunnel connected, starting rsync..." | Out-File $logFile -Append

# Use rsync over SSH (requires rsync in WSL or Git Bash)
# Alternative: Use robocopy with mounted network path if available

# Option 1: rsync via Git Bash (if available)
$rsyncPath = "C:\Program Files\Git\usr\bin\rsync.exe"
if (Test-Path $rsyncPath) {
    Write-Output "$(Get-Date): Using rsync" | Out-File $logFile -Append

    # Convert Windows path to rsync format
    $destPath = $destination -replace '\\', '/' -replace 'C:', '/cygdrive/c'

    & $rsyncPath -avz --progress --delete `
        -e "ssh -o ProxyCommand='cloudflared access ssh --hostname cambium-ssh.luxifyspecgen.com'" `
        "User@cambium-ssh.luxifyspecgen.com:/cygdrive/c/Server-Mirror/" `
        "$destPath/" 2>&1 | Out-File $logFile -Append

    $exitCode = $LASTEXITCODE
} else {
    # Option 2: Use SCP (slower, no incremental)
    Write-Output "$(Get-Date): rsync not found, using scp (slower)" | Out-File $logFile -Append

    scp -r -o "ProxyCommand=cloudflared access ssh --hostname cambium-ssh.luxifyspecgen.com" `
        "User@cambium-ssh.luxifyspecgen.com:C:/Server-Mirror/*" `
        "$destination/" 2>&1 | Out-File $logFile -Append

    $exitCode = $LASTEXITCODE
}

if ($exitCode -eq 0) {
    Write-Output "$(Get-Date): Tunnel sync completed successfully" | Out-File $logFile -Append
    Write-Host "Sync complete!" -ForegroundColor Green
} else {
    Write-Output "$(Get-Date): Tunnel sync completed with errors (exit code: $exitCode)" | Out-File $logFile -Append
    Write-Host "Sync completed with errors. Check log: $logFile" -ForegroundColor Yellow
}

exit $exitCode