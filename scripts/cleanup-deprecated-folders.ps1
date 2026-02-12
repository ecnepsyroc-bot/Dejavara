# C:\Dev\Dejavara\scripts\cleanup-deprecated-folders.ps1
# V5.4.3 Deprecated Folder Cleanup
# v5.4.1: ifc/, ift/, scope/ removed from 00-contract/
# v5.4.2: transmittal/ removed, 04-drawings/submittal/ removed
# v5.4.3: 11-awmac/ consolidated to 4 subfolders

param(
    [string]$ProjectsRoot = "C:\Projects",
    [switch]$DryRun = $false
)

$deprecatedFolders = @(
    "00-contract/ifc",
    "00-contract/ift",
    "00-contract/scope",
    "01-admin/transmittal",
    "04-drawings/submittal",
    "11-awmac/gis-reports",
    "11-awmac/inspections",
    "11-awmac/monitoring",
    "11-awmac/reports"
)

$removed = 0
$movedFiles = 0
$skipped = 0

Write-Host "Cleaning up deprecated folders (v5.4.3)..." -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "(DRY RUN - no changes will be made)" -ForegroundColor Yellow
}
Write-Host ""

function Process-Project {
    param([string]$ProjectPath, [string]$ProjectName)

    foreach ($deprecated in $deprecatedFolders) {
        $deprecatedPath = Join-Path $ProjectPath $deprecated

        if (-not (Test-Path $deprecatedPath)) {
            continue
        }

        # Check if folder has files
        $files = Get-ChildItem -Path $deprecatedPath -File -Recurse -ErrorAction SilentlyContinue

        if ($files.Count -gt 0) {
            # Determine destination
            $destFolder = switch -Wildcard ($deprecated) {
                "*ifc" { "00-contract/drawings" }
                "*ift" { "00-contract/drawings" }
                "*scope" { "00-contract/agreement" }
                "*transmittal" { "01-admin/submittal" }
                "04-drawings/submittal" { "01-admin/submittal" }
                "11-awmac/gis-reports" { "11-awmac/_received" }
                "11-awmac/inspections" { "11-awmac/qc" }
                "11-awmac/monitoring" { "11-awmac/qc" }
                "11-awmac/reports" { "11-awmac/_received" }
            }
            $destPath = Join-Path $ProjectPath $destFolder

            Write-Host "  $ProjectName\$deprecated -> $destFolder ($($files.Count) file(s))" -ForegroundColor Yellow

            if (-not $DryRun) {
                foreach ($file in $files) {
                    $destFile = Join-Path $destPath $file.Name
                    Move-Item -Path $file.FullName -Destination $destFile -Force
                    $script:movedFiles++
                }
            } else {
                $script:movedFiles += $files.Count
            }
        }

        # Remove empty folder
        if (-not $DryRun) {
            Remove-Item -Path $deprecatedPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host "  Removed: $ProjectName\$deprecated" -ForegroundColor Green
        $script:removed++
    }
}

# Scan projects recursively
function Scan-Projects {
    param([string]$Path)

    $items = Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name -notmatch "^_" -and $_.Name -notmatch "^\d{2}-" }

    foreach ($item in $items) {
        $projectPath = $item.FullName
        $projectName = $item.Name

        # Check if this is a project (has _cambium folder)
        if (Test-Path (Join-Path $projectPath "_cambium")) {
            Process-Project -ProjectPath $projectPath -ProjectName $projectName

            # Check for child projects
            Scan-Projects -Path $projectPath
        }
    }
}

Scan-Projects -Path $ProjectsRoot

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Cyan
Write-Host "Folders removed: $removed" -ForegroundColor Green
Write-Host "Files moved: $movedFiles" -ForegroundColor $(if ($movedFiles -gt 0) { "Yellow" } else { "DarkGray" })

if ($DryRun) {
    Write-Host ""
    Write-Host "Run without -DryRun to execute these changes" -ForegroundColor Yellow
}
