# C:\Dev\Dejavara\scripts\verify-v54-compliance.ps1
# V5.4.3 Compliance Verification Script
# Run after migration to verify full compliance

param(
    [string]$ProjectsRoot = "C:\Projects",
    [string]$FORoot = "C:\FO"
)

$errors = @()
$warnings = @()
$stats = @{
    TotalProjects = 0
    CompliantProjects = 0
    ParentProjects = 0
    ChildProjects = 0
    TotalFOs = 0
    V54IndexCount = 0
}

Write-Host "=== V5.4.3 Compliance Verification ===" -ForegroundColor Cyan
Write-Host ""

# Required folders for v5.4.1
$requiredFolders = @(
    "00-contract", "01-admin", "02-financial", "03-cad", "04-drawings",
    "05-materials", "06-samples", "07-production", "08-buyout",
    "09-coordination", "10-site", "11-awmac", "_archive", "_cambium"
)

# Deprecated folders that should NOT exist
# v5.4.1: ifc, ift, scope removed
# v5.4.3: transmittal, 04-drawings/submittal removed
# v5.4.3: 11-awmac/ consolidated to 4 subfolders
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

function Test-ProjectCompliance {
    param(
        [string]$ProjectPath,
        [string]$ProjectName,
        [bool]$IsChild = $false
    )

    $issues = @()

    # Check required folders
    foreach ($folder in $requiredFolders) {
        $folderPath = Join-Path $ProjectPath $folder
        if (-not (Test-Path $folderPath)) {
            $issues += "Missing folder: $folder"
        }
    }

    # Check _cambium/index.json
    $indexPath = Join-Path $ProjectPath "_cambium/index.json"
    if (Test-Path $indexPath) {
        try {
            $index = Get-Content $indexPath -Raw | ConvertFrom-Json
            if ($index.version -eq "5.4.3") {
                $script:stats.V54IndexCount++
            } else {
                $issues += "index.json version is $($index.version), expected 5.4.3"
            }
        } catch {
            $issues += "index.json is invalid JSON"
        }
    } else {
        $issues += "Missing _cambium/index.json"
    }

    # Check 07-production/_fo-index.md
    $foIndexPath = Join-Path $ProjectPath "07-production/_fo-index.md"
    if (-not (Test-Path $foIndexPath)) {
        $issues += "Missing 07-production/_fo-index.md"
    }

    # Check CAD structure
    $cadWorking = Join-Path $ProjectPath "03-cad/working"
    $cadArchive = Join-Path $ProjectPath "03-cad/archive"
    if (-not (Test-Path $cadWorking)) { $issues += "Missing 03-cad/working" }
    if (-not (Test-Path $cadArchive)) { $issues += "Missing 03-cad/archive" }

    # Check for files in project root (should be empty - inbox processed)
    $rootFiles = Get-ChildItem -Path $ProjectPath -File -ErrorAction SilentlyContinue
    if ($rootFiles.Count -gt 0) {
        $script:warnings += "$ProjectName`: $($rootFiles.Count) file(s) in inbox (project root)"
    }

    # Check for deprecated folders (should not exist in v5.4.1)
    foreach ($deprecated in $script:deprecatedFolders) {
        $deprecatedPath = Join-Path $ProjectPath $deprecated
        if (Test-Path $deprecatedPath) {
            $script:warnings += "$ProjectName`: Deprecated folder exists: $deprecated"
        }
    }

    return $issues
}

# Scan all projects (including nested in parent folders)
function Scan-ProjectsRecursive {
    param([string]$Path, [int]$Depth = 0)

    $items = Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name -notmatch "^_" -and $_.Name -notmatch "^\d{2}-" }

    foreach ($item in $items) {
        $projectPath = $item.FullName
        $projectName = $item.Name

        # Check if this is a v5.4 project (has _cambium folder)
        $hasCambium = Test-Path (Join-Path $projectPath "_cambium")

        if ($hasCambium) {
            $stats.TotalProjects++

            # Check if it's a parent project (has children property in index.json)
            $indexPath = Join-Path $projectPath "_cambium/index.json"
            $isParent = $false
            if (Test-Path $indexPath) {
                try {
                    $index = Get-Content $indexPath -Raw | ConvertFrom-Json
                    if ($index.type -eq "parent" -or $index.children) {
                        $isParent = $true
                        $stats.ParentProjects++
                    }
                } catch {}
            }

            if ($Depth -gt 0) {
                $stats.ChildProjects++
            }

            $displayName = if ($Depth -gt 0) { "  -> $projectName" } else { $projectName }
            $issues = Test-ProjectCompliance -ProjectPath $projectPath -ProjectName $projectName -IsChild ($Depth -gt 0)

            if ($issues.Count -eq 0) {
                $stats.CompliantProjects++
                Write-Host "$displayName" -ForegroundColor Green -NoNewline
                if ($isParent) { Write-Host " (parent)" -ForegroundColor DarkCyan }
                else { Write-Host "" }
            } else {
                Write-Host "$displayName" -ForegroundColor Yellow
                foreach ($issue in $issues) {
                    Write-Host "    - $issue" -ForegroundColor DarkYellow
                    $errors += "$projectName`: $issue"
                }
            }

            # If it's a parent, scan children
            if ($isParent) {
                Scan-ProjectsRecursive -Path $projectPath -Depth ($Depth + 1)
            }
        }
    }
}

Write-Host "Scanning projects in $ProjectsRoot..." -ForegroundColor White
Write-Host ""
Scan-ProjectsRecursive -Path $ProjectsRoot

# Scan FO folders
Write-Host ""
Write-Host "Scanning FO folders in $FORoot..." -ForegroundColor White
$foFolders = Get-ChildItem -Path $FORoot -Directory | Where-Object { $_.Name -notmatch "^_" }
foreach ($fo in $foFolders) {
    $stats.TotalFOs++
    $foPath = $fo.FullName

    # Check for Shops subfolder
    $shopsPath = Join-Path $foPath "Shops"
    if (-not (Test-Path $shopsPath)) {
        $warnings += "FO $($fo.Name): Missing Shops subfolder"
    }
}
Write-Host "Found $($stats.TotalFOs) FO folder(s)" -ForegroundColor Green

# Check templates
Write-Host ""
Write-Host "Checking FO templates..." -ForegroundColor White
$templatesPath = Join-Path $FORoot "_templates"
if (Test-Path $templatesPath) {
    $templates = Get-ChildItem -Path $templatesPath -File
    Write-Host "Found $($templates.Count) template file(s)" -ForegroundColor Green
    foreach ($t in $templates) {
        if ($t.Name -match " ") {
            $warnings += "Template has space in name: $($t.Name)"
        }
    }
} else {
    $errors += "Missing C:\FO\_templates folder"
}

# Summary
Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Projects:" -ForegroundColor White
Write-Host "  Total: $($stats.TotalProjects)" -ForegroundColor White
Write-Host "  Compliant: $($stats.CompliantProjects)" -ForegroundColor $(if ($stats.CompliantProjects -eq $stats.TotalProjects) { "Green" } else { "Yellow" })
Write-Host "  Parent projects: $($stats.ParentProjects)" -ForegroundColor Cyan
Write-Host "  Child projects: $($stats.ChildProjects)" -ForegroundColor Cyan
Write-Host "  V5.4.3 index.json: $($stats.V54IndexCount)" -ForegroundColor $(if ($stats.V54IndexCount -eq $stats.TotalProjects) { "Green" } else { "Yellow" })

$compliancePercent = if ($stats.TotalProjects -gt 0) { [math]::Round(($stats.CompliantProjects / $stats.TotalProjects) * 100, 1) } else { 0 }
Write-Host ""
Write-Host "Compliance: $compliancePercent%" -ForegroundColor $(if ($compliancePercent -ge 95) { "Green" } elseif ($compliancePercent -ge 80) { "Yellow" } else { "Red" })

Write-Host ""
Write-Host "Factory Orders: $($stats.TotalFOs)" -ForegroundColor White

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "ERRORS ($($errors.Count)):" -ForegroundColor Red
    foreach ($e in $errors | Select-Object -First 10) {
        Write-Host "  - $e" -ForegroundColor DarkRed
    }
    if ($errors.Count -gt 10) {
        Write-Host "  ... and $($errors.Count - 10) more" -ForegroundColor DarkRed
    }
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($w in $warnings | Select-Object -First 10) {
        Write-Host "  - $w" -ForegroundColor DarkYellow
    }
    if ($warnings.Count -gt 10) {
        Write-Host "  ... and $($warnings.Count - 10) more" -ForegroundColor DarkYellow
    }
}

Write-Host ""
if ($compliancePercent -ge 95 -and $errors.Count -eq 0) {
    Write-Host "V5.4.3 MIGRATION COMPLETE" -ForegroundColor Green
} else {
    Write-Host "V5.4.3 MIGRATION INCOMPLETE - Review errors above" -ForegroundColor Yellow
}
