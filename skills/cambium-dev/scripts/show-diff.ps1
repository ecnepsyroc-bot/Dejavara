<#
.SYNOPSIS
    Phone-friendly diff formatting for Telegram approval workflow.

.DESCRIPTION
    Formats git diff output for phone screens (max 60 char width, 20 lines).
    Summarizes large diffs and allows drilling into specific files.

.PARAMETER File
    Specific file to diff (optional). If omitted, shows all changes.

.PARAMETER Staged
    Show staged changes only (git diff --cached).

.PARAMETER MaxLines
    Max context lines around each change (default: 3).

.PARAMETER TopN
    Max files to show in summary for large diffs (default: 3).

.PARAMETER RepoPath
    Path to the repository. Default is C:\Dev\Dejavara\Cambium.

.EXAMPLE
    .\show-diff.ps1
    .\show-diff.ps1 -File "src/Api/Controllers/BadgeController.cs"
    .\show-diff.ps1 -Staged -TopN 5
#>

param(
    [string]$File,
    [switch]$Staged,
    [int]$MaxLines = 3,
    [int]$TopN = 3,
    [string]$RepoPath = 'C:\Dev\Dejavara\Cambium'
)

$ErrorActionPreference = 'Stop'
$MaxWidth = 60
$MaxOutputLines = 20

Push-Location $RepoPath
try {
    # Build git diff command
    $diffArgs = @('diff', '--no-color', "-U$MaxLines")
    if ($Staged) { $diffArgs += '--cached' }
    if ($File) { $diffArgs += '--', $File }

    $rawDiff = & git @diffArgs 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $rawDiff) {
        Write-Host "No changes to show."
        exit 0
    }

    # Parse diff into file chunks
    $files = @()
    $currentFile = $null
    $currentHunks = @()

    foreach ($line in $rawDiff -split "`n") {
        if ($line -match '^diff --git a/(.+) b/(.+)$') {
            if ($currentFile) {
                $files += [PSCustomObject]@{
                    Path = $currentFile
                    Hunks = $currentHunks
                }
            }
            $currentFile = $Matches[2]
            $currentHunks = @()
        }
        elseif ($line -match '^@@.*@@') {
            $currentHunks += [PSCustomObject]@{
                Header = $line
                Lines = @()
            }
        }
        elseif ($currentHunks.Count -gt 0 -and ($line -match '^[-+]' -or $line -match '^ ')) {
            $currentHunks[-1].Lines += $line
        }
    }
    if ($currentFile) {
        $files += [PSCustomObject]@{
            Path = $currentFile
            Hunks = $currentHunks
        }
    }

    # Count total changes
    $totalFiles = $files.Count
    $totalAdditions = ($rawDiff | Select-String '^\+[^+]' | Measure-Object).Count
    $totalDeletions = ($rawDiff | Select-String '^-[^-]' | Measure-Object).Count

    # Check if we need to summarize
    $needsSummary = $totalFiles -gt $TopN

    if ($needsSummary -and -not $File) {
        # Summary mode
        Write-Host "=== Diff Summary ===" -ForegroundColor Cyan
        Write-Host "$totalFiles files changed, showing top $TopN"
        Write-Host "+$totalAdditions -$totalDeletions lines`n"

        $shown = 0
        foreach ($f in $files | Select-Object -First $TopN) {
            $adds = ($f.Hunks | ForEach-Object { $_.Lines } | Where-Object { $_ -match '^\+' } | Measure-Object).Count
            $dels = ($f.Hunks | ForEach-Object { $_.Lines } | Where-Object { $_ -match '^-' } | Measure-Object).Count
            Write-Host "  $($f.Path) (+$adds -$dels)"
            $shown++
        }

        if ($totalFiles -gt $shown) {
            Write-Host "`n  ...and $($totalFiles - $shown) more files"
        }

        Write-Host "`n--- Telegram ---"
        Write-Host "$totalFiles files changed (+$totalAdditions -$totalDeletions)"
        Write-Host "Top $TopN shown. Say 'show <filename>' for details."
    }
    else {
        # Detailed mode - show actual diff
        $output = @()

        foreach ($f in $files | Select-Object -First $TopN) {
            # Truncate path for display
            $displayPath = $f.Path
            if ($displayPath.Length -gt ($MaxWidth - 5)) {
                $displayPath = "..." + $displayPath.Substring($displayPath.Length - ($MaxWidth - 8))
            }

            $output += ""
            $output += ([char]0x1F4C1) + " $displayPath"  # 📁 emoji

            foreach ($hunk in $f.Hunks) {
                # Extract line numbers from header
                if ($hunk.Header -match '@@ -(\d+)') {
                    $lineNum = $Matches[1]
                    $output += "(line $lineNum)"
                }

                foreach ($line in $hunk.Lines) {
                    # Truncate long lines
                    $displayLine = $line
                    if ($displayLine.Length -gt $MaxWidth) {
                        $displayLine = $displayLine.Substring(0, $MaxWidth - 3) + "..."
                    }
                    $output += $displayLine
                }
            }
        }

        # Apply line limit
        if ($output.Count -gt $MaxOutputLines) {
            $output = $output | Select-Object -First ($MaxOutputLines - 2)
            $output += ""
            $output += "... (truncated, $($totalFiles) files total)"
        }

        # Output
        foreach ($line in $output) {
            if ($line -match '^\+') {
                Write-Host $line -ForegroundColor Green
            }
            elseif ($line -match '^-') {
                Write-Host $line -ForegroundColor Red
            }
            else {
                Write-Host $line
            }
        }

        Write-Host ""
        Write-Host "Approve? Reply 'approved' or suggest changes."
    }

} finally {
    Pop-Location
}
