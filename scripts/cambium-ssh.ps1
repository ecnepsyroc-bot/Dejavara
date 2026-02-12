<#
.SYNOPSIS
    SSH to Cambium shop server with smart routing.

.DESCRIPTION
    Connects to the Cambium production server using smart route selection.
    Tests LAN first (fast, shop only), falls back to Cloudflare tunnel.
    Supports both interactive sessions and single command execution.

.PARAMETER Command
    Optional command to run remotely. If omitted, opens interactive session.

.PARAMETER Route
    Force a specific route: Auto (default), LAN, or Tunnel.
    - Auto: Test LAN first, fallback to tunnel
    - LAN: Force direct LAN connection (cambium-server)
    - Tunnel: Force Cloudflare tunnel (cambium-server-tunnel)

.PARAMETER Hostname
    Legacy parameter for direct cloudflared access. Deprecated in favor of Route.

.EXAMPLE
    .\cambium-ssh.ps1
    # Opens interactive SSH session via auto-detected route

.EXAMPLE
    .\cambium-ssh.ps1 -Command "hostname"
    # Runs single command and returns

.EXAMPLE
    .\cambium-ssh.ps1 -Route Tunnel -Command "Get-Service CambiumApi"
    # Force tunnel route for remote access

.EXAMPLE
    .\cambium-ssh.ps1 -Route LAN -Command "hostname"
    # Force LAN route when at the shop

.NOTES
    Prerequisites:
    - SSH config with 'cambium-server' (LAN) and 'cambium-server-tunnel' (Cloudflare) hosts
    - cloudflared installed for tunnel connections
    - Authenticated with Cloudflare Access
#>

param(
    [string]$Command = "",

    [ValidateSet('Auto', 'LAN', 'Tunnel')]
    [string]$Route = 'Auto',

    [string]$Hostname = ""  # Legacy parameter, kept for backward compatibility
)

$ErrorActionPreference = "Stop"

# Source the routing utility
. "$PSScriptRoot\ssh-route.ps1"

# Determine the SSH host to use
$sshHost = switch ($Route) {
    'LAN'    { "cambium-server" }
    'Tunnel' { "cambium-server-tunnel" }
    'Auto'   { Get-CambiumRoute }
}

$routeLabel = if ($sshHost -eq "cambium-server") { "[LAN]" } else { "[TUNNEL]" }
$routeDesc = if ($sshHost -eq "cambium-server") { "shop network" } else { "Cloudflare tunnel" }
$labelColor = if ($sshHost -eq "cambium-server") { "Green" } else { "Yellow" }

if ($Command) {
    # Run single command
    Write-Host "$routeLabel Running on Cambium via $routeDesc" -ForegroundColor $labelColor
    Write-Host "Command: $Command" -ForegroundColor Cyan

    & ssh $sshHost "powershell -Command `"$Command`""
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Host "Command failed with exit code: $exitCode" -ForegroundColor Red
    }
    exit $exitCode
} else {
    # Interactive session
    Write-Host "$routeLabel Connecting to Cambium via $routeDesc..." -ForegroundColor $labelColor
    Write-Host "Press Ctrl+D or type 'exit' to disconnect." -ForegroundColor DarkGray
    & ssh $sshHost
}
