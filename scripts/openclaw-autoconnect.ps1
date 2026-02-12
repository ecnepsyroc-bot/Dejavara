# OpenClaw Node Auto-Connect Script
# Detects location (home/shop) and connects node appropriately

<#
.SYNOPSIS
    Auto-detect location (home/shop) and connect OpenClaw node appropriately.
.DESCRIPTION
    - Home (192.168.1.x): Connects directly to Pi at 192.168.1.76
    - Shop (192.168.0.x): Connects via Cloudflare tunnel (TODO: configure)
    - Unknown: Falls back to home config
#>

$ErrorActionPreference = 'Stop'

# === CONFIGURATION ===
$HomeGateway = "192.168.1.1"      # Home router IP
$ShopGateway = "192.168.0.1"      # Shop router IP
$HomePiAddress = "192.168.1.76"   # Pi at home
$GatewayPort = 18789

# === DETECT LOCATION ===
$gateway = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
            Where-Object { $_.NextHop -ne '::' } |
            Select-Object -First 1).NextHop

$location = switch -Wildcard ($gateway) {
    "192.168.1.*" { "home" }
    "192.168.0.*" { "shop" }
    default { "unknown" }
}

Write-Host "Detected location: $location (gateway: $gateway)" -ForegroundColor Cyan

# === CONNECT BASED ON LOCATION ===
switch ($location) {
    "home" {
        Write-Host "At HOME - connecting to Pi directly" -ForegroundColor Green
        $env:OPENCLAW_GATEWAY = "ws://${HomePiAddress}:${GatewayPort}"
        & openclaw node start
    }
    "shop" {
        Write-Host "At SHOP - connecting via tunnel" -ForegroundColor Yellow
        # TODO: Configure tunnel endpoint when Cloudflare tunnel is set up
        # $env:OPENCLAW_GATEWAY = "wss://openclaw.yourdomain.com"
        Write-Host "Shop tunnel not yet configured. Trying home config..." -ForegroundColor Red
        $env:OPENCLAW_GATEWAY = "ws://${HomePiAddress}:${GatewayPort}"
        & openclaw node start
    }
    default {
        Write-Host "Unknown network - trying home config" -ForegroundColor Red
        $env:OPENCLAW_GATEWAY = "ws://${HomePiAddress}:${GatewayPort}"
        & openclaw node start
    }
}

Write-Host "`nNode started for $location" -ForegroundColor Green
