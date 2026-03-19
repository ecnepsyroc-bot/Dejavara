@echo off
:: DEPRECATED - Use the new P: drive monitoring system instead
:: Replacement: openclaw-tray.ps1 now monitors and auto-reconnects P: drive
:: Setup: Run scripts/p-drive/setup-p-drive-v2.ps1 as admin
:: This file kept for manual use or as fallback startup shortcut.
:: ============================================================================
::
:: Map P: drive to shop file server (\\Server\Projects)
:: This runs at user logon to ensure P: appears in Explorer
:: SMB1 protocol is managed separately by ensure-p-drive.ps1 (admin task)

:: Check if already mapped
net use P: >nul 2>&1
if %errorlevel% equ 0 (
    echo P: drive already mapped.
    exit /b 0
)

:: Check if on shop network (192.168.0.x)
ping -n 1 -w 1000 192.168.0.116 >nul 2>&1
if %errorlevel% neq 0 (
    echo Not on shop network, skipping P: drive mapping.
    exit /b 0
)

:: Map the drive with guest credentials
net use P: \\192.168.0.116\Projects /user:guest "" /persistent:yes
if %errorlevel% equ 0 (
    echo P: drive mapped successfully.
) else (
    echo Failed to map P: drive. SMB1 may need to be enabled.
)