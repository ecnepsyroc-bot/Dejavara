# Feature Millwork - Upgrade to v5.5.4
# Safely upgrades existing projects from v5.5 to v5.5.4
# NO FILES DELETED - orphaned content moves to project root for triage

param(
    [string]$ProjectsRoot = "C:\Projects",
    [switch]$WhatIf
)

$stats = @{
    Upgraded = 0
    Skipped = 0
    FilesTriaged = 0
}

Write-Host "=== Upgrade to v5.5.4 ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "DRY RUN - No changes will be made" -ForegroundColor Yellow
}
Write-Host ""

# v5.5.4 NEW folders to add
$newFolders = @(
    "05-materials\powdercoating"
    "06-samples\powdercoating"
    "09-coordination\doors\_received"
    "09-coordination\doors\_source"
    "09-coordination\doors\_template"
)

# READMEs for new/renamed folders (v5.5.4 style with Unicode box-drawing)
$newReadmes = @{}

$newReadmes["01-admin\email-disputes"] = @"

-- 01-admin / email-disputes --------------------------

EMAILS PRESERVED FOR DISPUTE / LEGAL RECORD

NOT for everyday correspondence. This folder is for
email threads you're saving because they may matter
in a claim, backcharge, or scope disagreement.

If it's routine coordination, leave it in Outlook.
If a lawyer might need it someday, save it here.

Naming: [Job]-COR-[Seq]-R[#]-[Date].[ext]

Examples:
  2601-COR-001-R0-20260128.pdf
"@

$newReadmes["05-materials\powdercoating"] = @"

-- 05-materials / powdercoating -----------------------

POWDERCOATING SPECIFICATIONS
Color codes, finish types, supplier specs.
"@

$newReadmes["06-samples\powdercoating"] = @"

-- 06-samples / powdercoating -------------------------

POWDERCOATING SAMPLES - photos, approval records.
"@

$newReadmes["09-coordination\doors"] = @"

-- 09-coordination / doors ----------------------------

DOOR & HARDWARE COORDINATION

Multi-party coordination: Feature (frames/panels),
hardware supplier, door manufacturer, GC.

YOUR issued coordination drawings at root level.
Their drawings/schedules in _received/.
Assembly pieces in _source/.
Coordination transmittal template in _template/.

  LIABILITY: Feature's drawings issued for COORDINATION
ONLY. Other trades must NOT use these for fabrication.
Use the transmittal template - it contains the disclaimer.
"@

$newReadmes["09-coordination\doors\_received"] = @"

-- doors / _received ----------------------------------

FROM OTHER PARTIES - hardware schedules, door
manufacturer shop drawings, GC coordination docs.
Filed as-is with their naming.

Track who sent what and when - this is your
evidence if another trade fabricates from your
coordination drawing instead of their own.
"@

$newReadmes["09-coordination\doors\_source"] = @"

-- doors / _source ------------------------------------

WORKING PIECES for door coordination packages.
Elevations, hardware schedules, frame details
before they're assembled into the issued package.

Not for distribution - assembly area only.
"@

$newReadmes["09-coordination\doors\_template"] = @"

-- doors / _template ----------------------------------

DOOR COORDINATION TRANSMITTAL TEMPLATE

Contains disclaimer: "Issued for coordination only.
Feature Millwork is not responsible for fabrication
by other trades based on this document."

ALWAYS use this transmittal when issuing door
coordination drawings. No exceptions.

Naming: feature-COORD-DOOR-001-R0-template.pdf
"@

function Upgrade-Project {
    param(
        [string]$ProjectPath,
        [string]$ProjectName
    )

    $changes = @()

    # 1. Add new folders
    foreach ($folder in $newFolders) {
        $fullPath = Join-Path $ProjectPath $folder
        if (-not (Test-Path $fullPath)) {
            if (-not $WhatIf) {
                New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            }
            $changes += "ADD folder: $folder"
        }
    }

    # 2. Handle email -> email-disputes rename
    $emailPath = Join-Path $ProjectPath "01-admin\email"
    $emailDisputesPath = Join-Path $ProjectPath "01-admin\email-disputes"

    if (Test-Path $emailPath) {
        $emailFiles = Get-ChildItem -Path $emailPath -File -Recurse -ErrorAction SilentlyContinue

        if ($emailFiles.Count -gt 0) {
            # Move files to project root for triage
            foreach ($file in $emailFiles) {
                $triageName = "_TRIAGE-email-$($file.Name)"
                $triagePath = Join-Path $ProjectPath $triageName
                if (-not $WhatIf) {
                    Move-Item -Path $file.FullName -Destination $triagePath -Force
                }
                $changes += "TRIAGE: $($file.Name) -> $triageName"
                $script:stats.FilesTriaged++
            }
        }

        # Remove empty email folder and create email-disputes
        if (-not $WhatIf) {
            Remove-Item -Path $emailPath -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $emailDisputesPath)) {
                New-Item -ItemType Directory -Path $emailDisputesPath -Force | Out-Null
            }
        }
        $changes += "RENAME: 01-admin/email -> 01-admin/email-disputes"
    } elseif (-not (Test-Path $emailDisputesPath)) {
        # email doesn't exist, ensure email-disputes does
        if (-not $WhatIf) {
            New-Item -ItemType Directory -Path $emailDisputesPath -Force | Out-Null
        }
        $changes += "ADD folder: 01-admin/email-disputes"
    }

    # 3. Handle _cambium\qr removal
    $qrPath = Join-Path $ProjectPath "_cambium\qr"
    if (Test-Path $qrPath) {
        $qrFiles = Get-ChildItem -Path $qrPath -File -Recurse -ErrorAction SilentlyContinue

        if ($qrFiles.Count -gt 0) {
            foreach ($file in $qrFiles) {
                $triageName = "_TRIAGE-qr-$($file.Name)"
                $triagePath = Join-Path $ProjectPath $triageName
                if (-not $WhatIf) {
                    Move-Item -Path $file.FullName -Destination $triagePath -Force
                }
                $changes += "TRIAGE: qr/$($file.Name) -> $triageName"
                $script:stats.FilesTriaged++
            }
        }

        if (-not $WhatIf) {
            Remove-Item -Path $qrPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        $changes += "REMOVE: _cambium/qr"
    }

    # 4. Update index.json version
    $indexPath = Join-Path $ProjectPath "_cambium\index.json"
    if (Test-Path $indexPath) {
        try {
            $index = Get-Content $indexPath -Raw | ConvertFrom-Json
            if ($index.version -ne "5.5.4") {
                $index.version = "5.5.4"
                if (-not $WhatIf) {
                    $index | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8
                }
                $changes += "UPDATE: index.json version -> 5.5.4"
            }
        } catch {
            $changes += "ERROR: Could not update index.json"
        }
    } else {
        # Create index.json if missing
        if (-not $WhatIf) {
            $cambiumPath = Join-Path $ProjectPath "_cambium"
            if (-not (Test-Path $cambiumPath)) {
                New-Item -ItemType Directory -Path $cambiumPath -Force | Out-Null
            }
            @{
                project = $ProjectName
                created = (Get-Date -Format 'yyyy-MM-dd')
                version = "5.5.4"
                factoryOrders = @()
            } | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8
        }
        $changes += "CREATE: _cambium/index.json (v5.5.4)"
    }

    # 5. Deploy new READMEs
    foreach ($key in $newReadmes.Keys) {
        $readmePath = Join-Path $ProjectPath "$key\_README.txt"
        $parentDir = Split-Path $readmePath -Parent

        if (-not (Test-Path $parentDir)) {
            if (-not $WhatIf) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }
        }

        if (-not $WhatIf) {
            $newReadmes[$key] | Set-Content -Path $readmePath -Encoding UTF8
        }
        $changes += "README: $key"
    }

    return $changes
}

# Main execution
$projects = Get-ChildItem -Path $ProjectsRoot -Directory | Where-Object { $_.Name -notmatch "^_" }

foreach ($project in $projects) {
    $projectPath = $project.FullName
    $projectName = $project.Name

    # Check if this is a Feature Millwork project (has _cambium or 00-contract)
    $isProject = (Test-Path (Join-Path $projectPath "_cambium")) -or (Test-Path (Join-Path $projectPath "00-contract"))

    if (-not $isProject) {
        Write-Host "SKIP  $projectName (not a FM project)" -ForegroundColor DarkGray
        $stats.Skipped++
        continue
    }

    $changes = Upgrade-Project -ProjectPath $projectPath -ProjectName $projectName

    if ($changes.Count -gt 0) {
        Write-Host "OK    $projectName" -ForegroundColor Green
        foreach ($change in $changes) {
            Write-Host "        $change" -ForegroundColor DarkCyan
        }
        $stats.Upgraded++
    } else {
        Write-Host "OK    $projectName (no changes needed)" -ForegroundColor Green
        $stats.Upgraded++
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Upgraded: $($stats.Upgraded)" -ForegroundColor Green
Write-Host "Skipped:  $($stats.Skipped)" -ForegroundColor Yellow
Write-Host "Files triaged to root: $($stats.FilesTriaged)" -ForegroundColor $(if ($stats.FilesTriaged -gt 0) { "Yellow" } else { "Green" })

if ($WhatIf) {
    Write-Host ""
    Write-Host "DRY RUN complete. Run without -WhatIf to apply changes." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "v5.5.4 upgrade complete." -ForegroundColor Green
    if ($stats.FilesTriaged -gt 0) {
        Write-Host "Review _TRIAGE-* files in project roots." -ForegroundColor Yellow
    }
}
