# C:\Dev\Dejavara\scripts\verify-v55-compliance.ps1
# V5.5.5 Compliance Verification Script
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
    V554IndexCount = 0
    ReadmeCount = 0
}

Write-Host "=== V5.5.5 Compliance Verification ===" -ForegroundColor Cyan
Write-Host ""

# Required folders for v5.5 (14 top-level)
$requiredFolders = @(
    "00-contract", "01-admin", "02-financial", "03-cad", "04-drawings",
    "05-materials", "06-samples", "07-production", "08-buyout",
    "09-coordination", "10-site", "11-awmac", "_archive", "_cambium"
)

# v5.5.5 required subfolders
$v554RequiredSubfolders = @(
    "01-admin/ccn/_received",
    "01-admin/email-disputes",
    "01-admin/rfi/_received",
    "01-admin/rfi/_template",
    "01-admin/submittal/_source",
    "01-admin/submittal/_received",
    "01-admin/submittal/_template",
    "05-materials/powdercoating",
    "06-samples/powdercoating",
    "08-buyout/quotes",
    "09-coordination/doors",
    "09-coordination/doors/_received",
    "09-coordination/doors/_source",
    "09-coordination/doors/_template",
    "11-awmac/_template"
)

# Deprecated folders that should NOT exist
# v5.4.1: ifc, ift, scope removed
# v5.4.2: transmittal, 04-drawings/submittal removed
# v5.4.4: 11-awmac/ consolidated to 4 subfolders
# v5.5.5: email renamed to email-disputes, _cambium/qr removed
$deprecatedFolders = @(
    "00-contract/ifc",
    "00-contract/ift",
    "00-contract/scope",
    "01-admin/transmittal",
    "01-admin/email",
    "04-drawings/submittal",
    "11-awmac/gis-reports",
    "11-awmac/inspections",
    "11-awmac/monitoring",
    "11-awmac/reports",
    "_cambium/qr"
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

    # Check v5.5.5 required subfolders
    foreach ($subfolder in $v554RequiredSubfolders) {
        $subfolderPath = Join-Path $ProjectPath $subfolder
        if (-not (Test-Path $subfolderPath)) {
            $script:warnings += "$ProjectName`: Missing v5.5.5 subfolder: $subfolder"
        }
    }

    # Check _cambium/index.json
    $indexPath = Join-Path $ProjectPath "_cambium/index.json"
    if (Test-Path $indexPath) {
        try {
            $index = Get-Content $indexPath -Raw | ConvertFrom-Json
            if ($index.version -eq "5.5.5") {
                $script:stats.V554IndexCount++
            } else {
                $issues += "index.json version is $($index.version), expected 5.5.5"
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

    # Check for deprecated folders (should not exist)
    foreach ($deprecated in $script:deprecatedFolders) {
        $deprecatedPath = Join-Path $ProjectPath $deprecated
        if (Test-Path $deprecatedPath) {
            $script:warnings += "$ProjectName`: Deprecated folder exists: $deprecated"
        }
    }

    # Check for README system (optional but recommended)
    $rootReadme = Join-Path $ProjectPath "_README.txt"
    if (Test-Path $rootReadme) {
        $script:stats.ReadmeCount++
    }

    return $issues
}

# Scan all projects (flat structure per v5.4.4+ spec)
function Scan-ProjectsFlat {
    param([string]$Path)

    $items = Get-ChildItem -Path $Path -Directory | Where-Object { $_.Name -notmatch "^_" }

    foreach ($item in $items) {
        $projectPath = $item.FullName
        $projectName = $item.Name

        # Check if this is a v5.5 project (has _cambium folder)
        $hasCambium = Test-Path (Join-Path $projectPath "_cambium")

        if ($hasCambium) {
            $stats.TotalProjects++

            $issues = Test-ProjectCompliance -ProjectPath $projectPath -ProjectName $projectName

            if ($issues.Count -eq 0) {
                $stats.CompliantProjects++
                Write-Host "$projectName" -ForegroundColor Green
            } else {
                Write-Host "$projectName" -ForegroundColor Yellow
                foreach ($issue in $issues) {
                    Write-Host "    - $issue" -ForegroundColor DarkYellow
                    $errors += "$projectName`: $issue"
                }
            }
        }
    }
}

Write-Host "Scanning projects in $ProjectsRoot..." -ForegroundColor White
Write-Host ""
Scan-ProjectsFlat -Path $ProjectsRoot

# Scan FO folders
Write-Host ""
Write-Host "Scanning FO folders in $FORoot..." -ForegroundColor White
if (Test-Path $FORoot) {
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
} else {
    Write-Host "FO root not found: $FORoot" -ForegroundColor DarkGray
}

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
    $warnings += "Missing C:\FO\_templates folder"
}

# Summary
Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Projects:" -ForegroundColor White
Write-Host "  Total: $($stats.TotalProjects)" -ForegroundColor White
Write-Host "  Compliant: $($stats.CompliantProjects)" -ForegroundColor $(if ($stats.CompliantProjects -eq $stats.TotalProjects) { "Green" } else { "Yellow" })
Write-Host "  V5.5.5 index.json: $($stats.V554IndexCount)" -ForegroundColor $(if ($stats.V554IndexCount -eq $stats.TotalProjects) { "Green" } else { "Yellow" })
Write-Host "  With README system: $($stats.ReadmeCount)" -ForegroundColor $(if ($stats.ReadmeCount -gt 0) { "Cyan" } else { "DarkGray" })

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
    Write-Host "V5.5.5 MIGRATION COMPLETE" -ForegroundColor Green
} else {
    Write-Host "V5.5.5 MIGRATION INCOMPLETE - Review errors above" -ForegroundColor Yellow
}
