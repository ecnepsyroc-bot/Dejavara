# OpenClaw Network Status Tray Icon
# Shows connection status: Home, Shop, VPN, Disconnected

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Config
$HomeNetwork = "TELUS7838"
$ShopSubnet = "192.168.0."
$TunnelName = "phteah-pi"
$TunnelConfig = "C:\Users\cory\phteah-pi.conf"
$PiGateway = "192.168.1.76"
$PiPort = 18789
$RefreshInterval = 10000  # 10 seconds

# Create icons (colored circles)
function New-StatusIcon {
    param($Color)
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $brush = New-Object System.Drawing.SolidBrush($Color)
    $g.FillEllipse($brush, 1, 1, 14, 14)
    $g.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

$IconGreen = New-StatusIcon ([System.Drawing.Color]::LimeGreen)   # Home - direct
$IconBlue = New-StatusIcon ([System.Drawing.Color]::DodgerBlue)   # VPN connected
$IconOrange = New-StatusIcon ([System.Drawing.Color]::Orange)     # Shop no VPN
$IconRed = New-StatusIcon ([System.Drawing.Color]::Red)           # Disconnected

# Create notify icon
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true

# Context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$menuStatus = New-Object System.Windows.Forms.ToolStripMenuItem
$menuStatus.Text = "Checking..."
$menuStatus.Enabled = $false
$contextMenu.Items.Add($menuStatus) | Out-Null

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$menuConnect = New-Object System.Windows.Forms.ToolStripMenuItem
$menuConnect.Text = "Connect VPN"
$menuConnect.Add_Click({
    & "C:\Program Files\WireGuard\wireguard.exe" /installtunnelservice $TunnelConfig 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Update-Status
})
$contextMenu.Items.Add($menuConnect) | Out-Null

$menuDisconnect = New-Object System.Windows.Forms.ToolStripMenuItem
$menuDisconnect.Text = "Disconnect VPN"
$menuDisconnect.Add_Click({
    & "C:\Program Files\WireGuard\wireguard.exe" /uninstalltunnelservice $TunnelName 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Update-Status
})
$contextMenu.Items.Add($menuDisconnect) | Out-Null

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$menuOpenDashboard = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOpenDashboard.Text = "Open Dashboard"
$menuOpenDashboard.Add_Click({
    Start-Process "http://localhost:18789"
})
$contextMenu.Items.Add($menuOpenDashboard) | Out-Null

$menuLogs = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLogs.Text = "View Logs"
$menuLogs.Add_Click({
    Start-Process "notepad.exe" "C:\tmp\openclaw\node-debug.log"
})
$contextMenu.Items.Add($menuLogs) | Out-Null

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator)) | Out-Null

$menuExit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExit.Text = "Exit"
$menuExit.Add_Click({
    $script:notifyIcon.Visible = $false
    $script:timer.Stop()
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.Items.Add($menuExit) | Out-Null

$notifyIcon.ContextMenuStrip = $contextMenu

# Double-click opens dashboard
$notifyIcon.Add_DoubleClick({
    Start-Process "http://localhost:18789"
})

# Status update function
function Update-Status {
    # Get network info
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*WireGuard*" -and $_.Name -ne $TunnelName }
    $networks = Get-NetConnectionProfile | Where-Object { $_.InterfaceAlias -notlike "*WireGuard*" -and $_.InterfaceAlias -ne $TunnelName }

    $onHomeNetwork = $networks | Where-Object { $_.Name -eq $HomeNetwork }

    $onShopNetwork = $false
    foreach ($adapter in $adapters) {
        $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($ip -and $ip.IPAddress.StartsWith($ShopSubnet)) {
            $onShopNetwork = $true
            break
        }
    }

    $wgAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" -or $_.Name -eq $TunnelName } -ErrorAction SilentlyContinue
    $wgConnected = $wgAdapter -and $wgAdapter.Status -eq "Up"

    # Test Pi connectivity
    $piReachable = Test-Connection -ComputerName $PiGateway -Count 1 -Quiet -ErrorAction SilentlyContinue

    # Determine status
    if ($onHomeNetwork) {
        $script:notifyIcon.Icon = $IconGreen
        $status = "HOME - Direct to Pi"
        $menuConnect.Enabled = $true
        $menuDisconnect.Enabled = $wgConnected
    }
    elseif ($onShopNetwork -and $wgConnected) {
        $script:notifyIcon.Icon = $IconBlue
        $status = "SHOP + VPN - Pi via tunnel"
        $menuConnect.Enabled = $false
        $menuDisconnect.Enabled = $true
    }
    elseif ($onShopNetwork -and -not $wgConnected) {
        $script:notifyIcon.Icon = $IconOrange
        $status = "SHOP - Need VPN for Pi!"
        $menuConnect.Enabled = $true
        $menuDisconnect.Enabled = $false
    }
    elseif ($wgConnected) {
        $script:notifyIcon.Icon = $IconBlue
        $status = "REMOTE + VPN - Pi via tunnel"
        $menuConnect.Enabled = $false
        $menuDisconnect.Enabled = $true
    }
    else {
        $script:notifyIcon.Icon = $IconRed
        $status = "DISCONNECTED - No Pi access"
        $menuConnect.Enabled = $true
        $menuDisconnect.Enabled = $false
    }

    $piStatus = if ($piReachable) { "Pi: OK" } else { "Pi: Unreachable" }
    $script:notifyIcon.Text = "OpenClaw`n$status`n$piStatus"
    $menuStatus.Text = "$status | $piStatus"
}

# Timer for periodic updates
$script:timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $RefreshInterval
$timer.Add_Tick({ Update-Status })
$timer.Start()

# Initial update
Update-Status

# Run
[System.Windows.Forms.Application]::Run()
