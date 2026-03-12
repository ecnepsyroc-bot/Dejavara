# Ensure P: Drive Connection and SMB1 Protocol
# Run this on startup or when P: drive is not accessible
# Purpose: Prevent Windows Updates from breaking shop file server access
#
# NOTE: This script handles SMB1 enablement (requires admin).
# Drive mapping is handled by map-p-drive.cmd in user startup folder
# because admin-context drive mappings don't appear in user Explorer.

$ErrorActionPreference = "Stop"

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "=== P: Drive Connection Check ===" -ForegroundColor Cyan

# 1. Check SMB1 Protocol Status (requires admin to fix)
Write-Host "`nChecking SMB1 Protocol..." -ForegroundColor Yellow
$smb1Client = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol-Client -ErrorAction SilentlyContinue

if ($smb1Client.State -ne "Enabled") {
    Write-Host "SMB1 is DISABLED. Attempting to enable..." -ForegroundColor Red

    if (-not $isAdmin) {
        Write-Host "ERROR: Administrator privileges required to enable SMB1." -ForegroundColor Red
        Write-Host "Please run this script as Administrator." -ForegroundColor Red
        exit 1
    }

    try {
        Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -All -NoRestart
        Write-Host "SMB1 Protocol enabled successfully." -ForegroundColor Green
        Write-Host "NOTE: A reboot may be required for changes to take full effect." -ForegroundColor Yellow
    } catch {
        Write-Host "Failed to enable SMB1: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "SMB1 Protocol is enabled." -ForegroundColor Green
}

# 2. Check if P: drive is mapped
Write-Host "`nChecking P: drive mapping..." -ForegroundColor Yellow
$pDrive = Get-PSDrive -Name P -ErrorAction SilentlyContinue

if (-not $pDrive) {
    Write-Host "P: drive is NOT mapped. Mapping now..." -ForegroundColor Red
    try {
        # Use New-PSDrive which is more reliable than net use for SMB1 shares
        # Try IP first (more reliable than hostname), fall back to hostname
        $root = "\\192.168.0.116\Projects"
        if (-not (Test-Connection -ComputerName "192.168.0.116" -Count 1 -Quiet)) {
            Write-Host "IP not reachable, trying hostname..." -ForegroundColor Yellow
            $root = "\\Server\Projects"
        }
        New-PSDrive -Name "P" -PSProvider FileSystem -Root $root -Persist -Scope Global -ErrorAction Stop
        Write-Host "P: drive mapped successfully to $root" -ForegroundColor Green
    } catch {
        Write-Host "New-PSDrive failed, trying net use as fallback..." -ForegroundColor Yellow
        try {
            net use P: $root /persistent:yes 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "P: drive mapped via net use." -ForegroundColor Green
            } else {
                throw "net use failed with exit code $LASTEXITCODE"
            }
        } catch {
            Write-Host "Failed to map P: drive: $_" -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "P: drive is mapped." -ForegroundColor Green
}

# 3. Test P: drive accessibility
Write-Host "`nTesting P: drive access..." -ForegroundColor Yellow
if (Test-Path "P:\") {
    Write-Host "P: drive is ACCESSIBLE." -ForegroundColor Green
    $itemCount = (Get-ChildItem P:\ -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "Found $itemCount items in P:\" -ForegroundColor Cyan
} else {
    Write-Host "P: drive is mapped but NOT ACCESSIBLE." -ForegroundColor Red
    Write-Host "This usually means SMB1 needs to be enabled and a reboot is required." -ForegroundColor Yellow
    exit 1
}

# 4. Check network profile (should be Private for shop network)
Write-Host "`nChecking network profile..." -ForegroundColor Yellow
$shopNetworkProfile = Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -like "*Ethernet*" -and $_.IPv4Connectivity -eq "Internet" }

if ($shopNetworkProfile) {
    if ($shopNetworkProfile.NetworkCategory -eq "Public") {
        Write-Host "WARNING: Network is set to Public. Should be Private for file sharing." -ForegroundColor Yellow

        if ($isAdmin) {
            Write-Host "Changing to Private..." -ForegroundColor Yellow
            Set-NetConnectionProfile -InterfaceAlias $shopNetworkProfile.InterfaceAlias -NetworkCategory Private
            Write-Host "Network profile changed to Private." -ForegroundColor Green
        } else {
            Write-Host "Run as Administrator to change network profile to Private." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Network profile is Private." -ForegroundColor Green
    }
}

Write-Host "`n=== All Checks Passed ===" -ForegroundColor Green
Write-Host "P: drive is ready to use." -ForegroundColor Cyan