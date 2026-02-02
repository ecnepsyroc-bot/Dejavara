<#
.SYNOPSIS
    One-command Cambium status for Telegram.

.DESCRIPTION
    Outputs a concise, emoji-formatted status summary optimized for phone screens.
    Shows git status, last commit, and quick health indicators.

.PARAMETER RepoPath
    Path to the repository. Default is C:\Dev\Dejavara\Cambium.

.PARAMETER SkipHealth
    Skip health checks (faster, git-only status).

.EXAMPLE
    .\quick-status.ps1
    .\quick-status.ps1 -SkipHealth
#>

param(
    [string]$RepoPath = 'C:\Dev\Dejavara\Cambium',
    [switch]$SkipHealth
)

$ErrorActionPreference = 'SilentlyContinue'

Push-Location $RepoPath
try {
    # Git info
    $branch = git rev-parse --abbrev-ref HEAD
    $lastCommit = git log -1 --format="%h" 2>$null
    $lastCommitTime = git log -1 --format="%ar" 2>$null
    $status = git status --porcelain 2>$null

    # Count changes
    $modified = ($status | Where-Object { $_ -match '^.M' } | Measure-Object).Count
    $added = ($status | Where-Object { $_ -match '^\?\?' } | Measure-Object).Count
    $staged = ($status | Where-Object { $_ -match '^[MADRC]' } | Measure-Object).Count

    # Format changes
    $changes = @()
    if ($modified -gt 0) { $changes += "$modified modified" }
    if ($added -gt 0) { $changes += "$added new" }
    if ($staged -gt 0) { $changes += "$staged staged" }
    $changesStr = if ($changes.Count -gt 0) { $changes -join ", " } else { "clean" }

    # Health checks (quick)
    $healthItems = @()

    if (-not $SkipHealth) {
        # API check - just ping health endpoint
        try {
            $null = Invoke-RestMethod -Uri "http://localhost:5001/health" -TimeoutSec 2 -ErrorAction Stop
            $healthItems += ([char]0x2705) + " API"  # ✅
        } catch {
            # Try alternate port
            try {
                $null = Invoke-RestMethod -Uri "http://localhost:5000/health" -TimeoutSec 2 -ErrorAction Stop
                $healthItems += ([char]0x2705) + " API"
            } catch {
                $healthItems += ([char]0x274C) + " API"  # ❌
            }
        }

        # DB check - just verify service running
        $pgService = Get-Service -Name 'postgresql*' -ErrorAction SilentlyContinue
        if ($pgService -and $pgService.Status -eq 'Running') {
            $healthItems += ([char]0x2705) + " DB"
        } else {
            $healthItems += ([char]0x274C) + " DB"
        }

        # Git check - any uncommitted?
        if ($status) {
            $healthItems += ([char]0x26A0) + " Git"  # ⚠️
        } else {
            $healthItems += ([char]0x2705) + " Git"
        }
    }

    # Output
    Write-Host ([char]0x1F333) + " Cambium Status"  # 🌳
    Write-Host "Branch: $branch"
    Write-Host "Changes: $changesStr"
    Write-Host "Last commit: $lastCommit ($lastCommitTime)"

    if ($healthItems.Count -gt 0) {
        Write-Host "Health: $($healthItems -join ' ')"
    }

} finally {
    Pop-Location
}
