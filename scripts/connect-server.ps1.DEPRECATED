# Connect to shop server (\\Server\Projects -> P:)
# Runs at logon to ensure network drives are connected

$ServerShare = "\\Server\Projects"
$DriveLetter = "P:"
$Server = "Server"
$MaxRetries = 5
$RetryDelay = 10  # seconds

# Wait for network to be ready (server reachable)
Write-Host "Waiting for network connection to $Server..."
for ($i = 1; $i -le $MaxRetries; $i++) {
    if (Test-Connection -ComputerName $Server -Count 1 -Quiet) {
        Write-Host "Server reachable on attempt $i"
        break
    }
    if ($i -eq $MaxRetries) {
        Write-Host "Could not reach $Server after $MaxRetries attempts - not on shop network?"
        exit 0  # Exit cleanly - probably working from home
    }
    Write-Host "Attempt $i - Server not reachable, waiting ${RetryDelay}s..."
    Start-Sleep -Seconds $RetryDelay
}

# Check if drive is already connected and accessible
if (Test-Path $DriveLetter) {
    Write-Host "Drive $DriveLetter already connected to $ServerShare"
    exit 0
}

# Try to reconnect
Write-Host "Connecting $DriveLetter to $ServerShare..."
try {
    # Remove stale connection if exists
    $existing = Get-PSDrive -Name ($DriveLetter -replace ':','') -ErrorAction SilentlyContinue
    if ($existing) {
        Remove-PSDrive -Name ($DriveLetter -replace ':','') -Force -ErrorAction SilentlyContinue
    }

    # Also try net use to clean up
    net use $DriveLetter /delete 2>$null

    # Create new connection
    net use $DriveLetter $ServerShare /persistent:yes

    if (Test-Path $DriveLetter) {
        Write-Host "Successfully connected $DriveLetter to $ServerShare"
    } else {
        Write-Host "Warning: Connection command succeeded but drive not accessible"
        exit 1
    }
} catch {
    Write-Host "Error connecting: $_"
    exit 1
}