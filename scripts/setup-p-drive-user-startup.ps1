# Setup P: Drive Mapping at User Logon
# Run this ONCE to add map-p-drive.cmd to your startup folder
# This ensures P: drive appears in Explorer (not just admin sessions)

$scriptPath = "C:\Dev\Dejavara\scripts\map-p-drive.cmd"
$startupFolder = [Environment]::GetFolderPath("Startup")
$shortcutPath = Join-Path $startupFolder "Map P Drive.lnk"

Write-Host "=== P: Drive User Startup Setup ===" -ForegroundColor Cyan

# Check if script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: map-p-drive.cmd not found at $scriptPath" -ForegroundColor Red
    exit 1
}

# Create shortcut in startup folder
Write-Host "`nCreating startup shortcut..." -ForegroundColor Yellow
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $scriptPath
$shortcut.WorkingDirectory = "C:\Dev\Dejavara\scripts"
$shortcut.WindowStyle = 7  # Minimized
$shortcut.Description = "Map P: drive to shop file server"
$shortcut.Save()

Write-Host "Shortcut created: $shortcutPath" -ForegroundColor Green

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "P: drive will now be mapped at every logon when on shop network." -ForegroundColor Cyan
Write-Host "`nThis works alongside the admin scheduled task which handles SMB1." -ForegroundColor White