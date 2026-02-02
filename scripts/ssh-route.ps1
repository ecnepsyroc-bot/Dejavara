<#
.SYNOPSIS
    Smart SSH routing for Cambium server.

.DESCRIPTION
    Tests LAN first (1-second timeout), falls back to Cloudflare tunnel.
    Provides functions for route detection and SSH command execution.

.NOTES
    SSH hosts (defined in ~/.ssh/config):
    - cambium        : LAN direct connection to shop server
    - cambium-tunnel : Cloudflare tunnel via cambium-ssh.luxifyspecgen.com
#>

function Get-CambiumRoute {
    <#
    .SYNOPSIS
        Determine the best SSH route to Cambium server.
    .OUTPUTS
        String: "cambium" (LAN) or "cambium-tunnel" (Cloudflare)
    #>
    param(
        [int]$TimeoutMs = 1000
    )

    # Test LAN connectivity to shop server IP directly (192.168.0.40)
    # Use -Timeout (milliseconds) for Windows PowerShell compatibility
    $lanReachable = Test-Connection -ComputerName 192.168.0.40 -Count 1 -Quiet -ErrorAction SilentlyContinue

    if ($lanReachable) {
        return "cambium"
    } else {
        return "cambium-tunnel"
    }
}

function Invoke-CambiumSSH {
    <#
    .SYNOPSIS
        Execute SSH command on Cambium with smart routing.
    .PARAMETER Command
        The command to run on the remote server.
    .PARAMETER Route
        Force a specific route: Auto (default), LAN, or Tunnel.
    .PARAMETER Silent
        Suppress route indicator output.
    .OUTPUTS
        Returns the command output. Sets $LASTEXITCODE.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,

        [ValidateSet('Auto', 'LAN', 'Tunnel')]
        [string]$Route = 'Auto',

        [switch]$Silent
    )

    # Determine route
    $sshHost = switch ($Route) {
        'LAN'    { "cambium" }
        'Tunnel' { "cambium-tunnel" }
        'Auto'   { Get-CambiumRoute }
    }

    $label = if ($sshHost -eq "cambium") { "[LAN]" } else { "[TUNNEL]" }
    $desc = if ($sshHost -eq "cambium") { "shop network" } else { "Cloudflare tunnel" }

    if (-not $Silent) {
        Write-Host "$label Connecting via $desc" -ForegroundColor $(if ($sshHost -eq "cambium") { "Green" } else { "Yellow" })
    }

    # Execute SSH command
    & ssh $sshHost $Command
    return $LASTEXITCODE
}

# Note: Functions are available when dot-sourced (. .\ssh-route.ps1)
