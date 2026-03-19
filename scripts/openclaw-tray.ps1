# OpenClaw Service Status Tray Icon (v3 — with P: drive monitoring)
# Four health checks: Pi, Cambium Server, Railway (via Cloudflare), P: drive (local)

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

# P: Drive config
$PDriveServer = "192.168.0.116"
$PDriveLetter = "P:"
$PDriveLogDir = "C:\tmp\p-drive"
$PDriveLogFile = "$PDriveLogDir\p.log"
$PDriveConnectScript = "C:\Dev\Dejavara\scripts\p-drive\p-drive-connect.ps1"

# Timing
$HealthCheckInterval = 30000  # 30 seconds for all checks
$PDriveBackoffInterval = 300000  # 5 minutes when server unreachable
$ServerUnreachableThreshold = 3  # failures before backoff

# State
$script:piOk = $null
$script:serverOk = $null
$script:railwayOk = $null
$script:pDriveStatus = $null  # "OK", "DOWN", "N/A", "RECONNECTING"
$script:pDrivePreviousStatus = $null
$script:serverUnreachableCount = 0
$script:pDriveCheckInterval = $HealthCheckInterval  # can increase during backoff
$script:lastPDriveCheck = $null
$script:reconnectInProgress = $false

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

$menuReconnectPDrive = New-Object System.Windows.Forms.ToolStripMenuItem
$menuReconnectPDrive.Text = "Reconnect P: Drive"
$menuReconnectPDrive.Add_Click({
    if ($script:pDriveStatus -eq "N/A") {
        Show-Notification -Title "P: Drive" -Message "Not on shop network" -Icon "Info"
    } elseif ($script:reconnectInProgress) {
        Show-Notification -Title "P: Drive" -Message "Reconnection already in progress" -Icon "Info"
    } else {
        Start-PDriveReconnect
    }
})
$contextMenu.Items.Add($menuReconnectPDrive) | Out-Null

$menuPDriveLogs = New-Object System.Windows.Forms.ToolStripMenuItem
$menuPDriveLogs.Text = "P: Drive Log..."
$menuPDriveLogs.Add_Click({
    if (Test-Path $PDriveLogFile) {
        Start-Process "notepad.exe" $PDriveLogFile
    } else {
        Show-Notification -Title "P: Drive" -Message "No log file yet" -Icon "Info"
    }
})
$contextMenu.Items.Add($menuPDriveLogs) | Out-Null

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

# P: Drive ping gate — 1 second timeout
function Test-ServerReachable {
    try {
        $ping = Test-Connection -ComputerName $PDriveServer -Count 1 -Quiet -ErrorAction SilentlyContinue
        return $ping
    } catch {
        return $false
    }
}

# P: Drive health check with backoff logic
function Test-PDriveHealth {
    # Check if we should skip this check (backoff mode)
    if ($script:lastPDriveCheck -and $script:pDriveCheckInterval -gt $HealthCheckInterval) {
        $elapsed = (Get-Date) - $script:lastPDriveCheck
        if ($elapsed.TotalMilliseconds -lt $script:pDriveCheckInterval) {
            return $script:pDriveStatus  # Return cached status
        }
    }
    $script:lastPDriveCheck = Get-Date

    # Ping gate — fast fail if server unreachable
    if (-not (Test-ServerReachable)) {
        $script:serverUnreachableCount++

        if ($script:serverUnreachableCount -ge $ServerUnreachableThreshold) {
            # Enter backoff mode
            $script:pDriveCheckInterval = $PDriveBackoffInterval
            return "N/A"
        }
        return "N/A"
    }

    # Server is reachable — reset backoff
    $script:serverUnreachableCount = 0
    $script:pDriveCheckInterval = $HealthCheckInterval

    # Check if P: is mounted and accessible
    if (Test-Path "$PDriveLetter\") {
        try {
            $null = Get-ChildItem "$PDriveLetter\" -ErrorAction Stop | Select-Object -First 1
            return "OK"
        } catch {
            return "DOWN"  # Mounted but can't read
        }
    } else {
        return "DOWN"  # Not mounted
    }
}

# Balloon notification helper
function Show-Notification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Icon = "Warning"  # None, Info, Warning, Error
    )
    $script:notifyIcon.BalloonTipTitle = $Title
    $script:notifyIcon.BalloonTipText = $Message
    $script:notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$Icon
    $script:notifyIcon.ShowBalloonTip(5000)
}

# P: Drive reconnection (runs async to not block UI)
function Start-PDriveReconnect {
    if ($script:reconnectInProgress) { return }
    $script:reconnectInProgress = $true
    $script:pDriveStatus = "RECONNECTING"

    Show-Notification -Title "P: Drive" -Message "Disconnected - reconnecting..." -Icon "Warning"

    # Run reconnect script in background
    $job = Start-Job -ScriptBlock {
        param($ScriptPath)
        & $ScriptPath -Silent
    } -ArgumentList $PDriveConnectScript

    # Check job completion on next timer tick
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        $job = $Event.Sender
        if ($job.State -eq "Completed") {
            $result = Receive-Job $job
            Remove-Job $job -Force

            if ($result -eq $true) {
                $script:pDriveStatus = "OK"
                Show-Notification -Title "P: Drive" -Message "Reconnected successfully" -Icon "Info"
            } else {
                $script:pDriveStatus = "DOWN"
                Show-Notification -Title "P: Drive" -Message "Reconnection failed - check log" -Icon "Error"
            }
            $script:reconnectInProgress = $false

            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
        }
    } | Out-Null
}

# Status update function
function Update-Status {
    # Three independent health checks (Cloudflare)
    $script:piOk      = Test-Endpoint -Url $PiHealthUrl -Headers $CfHeaders
    $script:serverOk   = Test-Endpoint -Url $ServerHealthUrl -Headers $CfHeaders
    $script:railwayOk  = Test-Endpoint -Url $RailwayHealthUrl

    # P: Drive health check (local, with backoff)
    $script:pDrivePreviousStatus = $script:pDriveStatus
    if (-not $script:reconnectInProgress) {
        $script:pDriveStatus = Test-PDriveHealth
    }

    # Trigger reconnect if P: went from OK to DOWN
    if ($script:pDrivePreviousStatus -eq "OK" -and $script:pDriveStatus -eq "DOWN") {
        Start-PDriveReconnect
    }

    # Count services up (P: drive doesn't count toward service health - it's local)
    $up = 0
    if ($script:piOk) { $up++ }
    if ($script:serverOk) { $up++ }
    if ($script:railwayOk) { $up++ }

    # Icon: green (3/3 services + P: OK or N/A), yellow (degraded), red (all down)
    $pDriveOk = ($script:pDriveStatus -eq "OK" -or $script:pDriveStatus -eq "N/A")
    if ($up -eq 3 -and $pDriveOk) {
        $script:notifyIcon.Icon = $IconGreen
    } elseif ($up -gt 0 -or $pDriveOk) {
        $script:notifyIcon.Icon = $IconYellow
    } else {
        $script:notifyIcon.Icon = $IconRed
    }

    # Budget query (local tunnel, no auth needed)
    $budgetText = "?"
    try {
        $b = Invoke-WebRequest -Uri "http://localhost:18789/api/budget" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $bd = $b.Content | ConvertFrom-Json
        if ($bd.ok -and $bd.limit -gt 0) {
            $budgetText = "$($bd.used)/$($bd.limit)"
        }
    } catch {}

    # Per-service status labels
    $piLabel      = if ($script:piOk) { "OK" } else { "DN" }
    $serverLabel  = if ($script:serverOk) { "OK" } else { "DN" }
    $railwayLabel = if ($script:railwayOk) { "OK" } else { "DN" }
    $pDriveLabel  = switch ($script:pDriveStatus) {
        "OK"          { "OK" }
        "DOWN"        { "DN" }
        "RECONNECTING" { ".." }
        default       { "-" }
    }

    # Tooltip (63 char limit for NotifyIcon.Text)
    # Format: Pi:OK Srv:OK Rwy:OK P:OK | 5/10
    $tooltip = "Pi:$piLabel Srv:$serverLabel Rwy:$railwayLabel P:$pDriveLabel | $budgetText"
    if ($tooltip.Length -gt 63) { $tooltip = $tooltip.Substring(0, 63) }
    $script:notifyIcon.Text = $tooltip

    # Menu status (can be longer)
    $pDriveMenuLabel = switch ($script:pDriveStatus) {
        "OK"          { "OK" }
        "DOWN"        { "DOWN" }
        "RECONNECTING" { "Reconnecting..." }
        default       { "N/A (not on shop network)" }
    }
    $menuStatus.Text = "Pi: $piLabel | Srv: $serverLabel | Rwy: $railwayLabel | P: $pDriveMenuLabel"
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
