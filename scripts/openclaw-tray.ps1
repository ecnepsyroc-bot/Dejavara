# OpenClaw Service Status Tray Icon (v2 — Cloudflare-only)
# Three independent health checks via Cloudflare tunnels. No VPN, no network detection.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Health check URLs (all through Cloudflare)
$PiHealthUrl = "https://cambium-home.luxifysystems.com/health"
$ServerHealthUrl = "https://api.luxifyspecgen.com/api/version"
$RailwayHealthUrl = "https://cambium-production.up.railway.app/api/version"

# Cloudflare Service Token (bypasses Access login for Pi and Server)
$CfTokenId = "54b4dda94cf3350d082fbf2859464d3f.access"
$CfTokenSecret = "0ced21fcd5dd650005b041cda37259969c58cd0466d168fa7c935bc2e269fc73"
$CfHeaders = @{
    "CF-Access-Client-Id"     = $CfTokenId
    "CF-Access-Client-Secret" = $CfTokenSecret
}

# Timing
$HealthCheckInterval = 30000  # 30 seconds for all checks

# State
$script:piOk = $null
$script:serverOk = $null
$script:railwayOk = $null

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

$IconGreen  = New-StatusIcon ([System.Drawing.Color]::LimeGreen)
$IconYellow = New-StatusIcon ([System.Drawing.Color]::Gold)
$IconRed    = New-StatusIcon ([System.Drawing.Color]::Red)

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

# Health check helper
function Test-Endpoint {
    param($Url, $Headers)
    try {
        $params = @{
            Uri             = $Url
            UseBasicParsing = $true
            TimeoutSec      = 5
            ErrorAction     = 'Stop'
        }
        if ($Headers) { $params.Headers = $Headers }
        $response = Invoke-WebRequest @params
        return ($response.StatusCode -eq 200)
    }
    catch {
        return $false
    }
}

# Status update function
function Update-Status {
    # Three independent health checks
    $script:piOk      = Test-Endpoint -Url $PiHealthUrl -Headers $CfHeaders
    $script:serverOk   = Test-Endpoint -Url $ServerHealthUrl -Headers $CfHeaders
    $script:railwayOk  = Test-Endpoint -Url $RailwayHealthUrl

    # Count
    $up = 0
    if ($script:piOk) { $up++ }
    if ($script:serverOk) { $up++ }
    if ($script:railwayOk) { $up++ }

    # Icon: green (3/3), yellow (1-2/3), red (0/3)
    if ($up -eq 3) {
        $script:notifyIcon.Icon = $IconGreen
    } elseif ($up -gt 0) {
        $script:notifyIcon.Icon = $IconYellow
    } else {
        $script:notifyIcon.Icon = $IconRed
    }

    # Budget query (local tunnel, no auth needed)
    $budgetText = "Budget: ?"
    try {
        $b = Invoke-WebRequest -Uri "http://localhost:18789/api/budget" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $bd = $b.Content | ConvertFrom-Json
        if ($bd.ok -and $bd.limit -gt 0) {
            $budgetText = "Budget: $($bd.used)/$($bd.limit)"
        }
    } catch {}

    # Per-service status
    $piLabel      = if ($script:piOk) { "OK" } else { "DOWN" }
    $serverLabel  = if ($script:serverOk) { "OK" } else { "DOWN" }
    $railwayLabel = if ($script:railwayOk) { "OK" } else { "DOWN" }

    # Tooltip (63 char limit for NotifyIcon.Text)
    $tooltip = "Pi:$piLabel Srv:$serverLabel Rwy:$railwayLabel | $budgetText"
    if ($tooltip.Length -gt 63) { $tooltip = $tooltip.Substring(0, 63) }
    $script:notifyIcon.Text = $tooltip
    $menuStatus.Text = "Pi: $piLabel | Server: $serverLabel | Railway: $railwayLabel | $budgetText"
}

# Timer for periodic updates
$script:timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $HealthCheckInterval
$timer.Add_Tick({ Update-Status })
$timer.Start()

# Initial update
Update-Status

# Run
[System.Windows.Forms.Application]::Run()
