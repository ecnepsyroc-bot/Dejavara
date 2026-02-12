# C:\Dev\Dejavara\scripts\update-index-versions.ps1
# Update all project index.json files to version 5.4.3

param(
    [string]$ProjectsRoot = "C:\Projects",
    [switch]$DryRun = $false
)

$updated = 0
$skipped = 0
$errors = 0

Write-Host "Updating index.json versions to 5.4.3..." -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "(DRY RUN - no changes will be made)" -ForegroundColor Yellow
}
Write-Host ""

function Update-IndexVersion {
    param([string]$Path)

    $indexPath = Join-Path $Path "_cambium/index.json"

    if (-not (Test-Path $indexPath)) {
        return $null
    }

    try {
        $content = Get-Content $indexPath -Raw
        $json = $content | ConvertFrom-Json

        if ($json.version -eq "5.4.3") {
            return "skip"
        }

        $json.version = "5.4.3"

        if (-not $script:DryRun) {
            $json | ConvertTo-Json -Depth 10 | Set-Content $indexPath -Encoding UTF8
        }

        return "updated"
    } catch {
        return "error"
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
            $result = Update-IndexVersion -Path $projectPath

            switch ($result) {
                "updated" {
                    Write-Host "  Updated: $projectName" -ForegroundColor Green
                    $script:updated++
                }
                "skip" {
                    Write-Host "  Already 5.4.3: $projectName" -ForegroundColor DarkGray
                    $script:skipped++
                }
                "error" {
                    Write-Host "  Error: $projectName" -ForegroundColor Red
                    $script:errors++
                }
            }

            # Check for child projects
            Scan-Projects -Path $projectPath
        }
    }
}

Scan-Projects -Path $ProjectsRoot

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Cyan
Write-Host "Updated: $updated" -ForegroundColor Green
Write-Host "Already 5.4.3: $skipped" -ForegroundColor DarkGray
Write-Host "Errors: $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "DarkGray" })
