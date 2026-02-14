# Feature Millwork - Upgrade to v5.5.5
# Updates from v5.5.4 to v5.5.5
# Main change: README headers use Unicode box-drawing (──) instead of ASCII (--)

param(
    [string]$ProjectsRoot = "C:\Projects",
    [switch]$WhatIf
)

$stats = @{
    Upgraded = 0
    Skipped = 0
}

Write-Host "=== Upgrade to v5.5.5 ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "DRY RUN - No changes will be made" -ForegroundColor Yellow
}
Write-Host ""

# READMEs for v5.5.4 folders - now with Unicode box-drawing
$newReadmes = @{}

$newReadmes["01-admin\email-disputes"] = @"

── 01-admin / email-disputes ──────────────────────

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

── 05-materials / powdercoating ───────────────────

POWDERCOAT SPECS – colour chips, RAL/custom codes,
finish standards, manufacturer spec sheets.
"@

$newReadmes["06-samples\powdercoating"] = @"

── 06-samples / powdercoating ─────────────────────

POWDERCOAT SAMPLES – colour chips, texture samples,
RAL/custom colour approvals, spray-out records.
"@

$newReadmes["09-coordination\doors"] = @"

── 09-coordination / doors ────────────────────────

DOOR & HARDWARE COORDINATION

Multi-party coordination: Feature (frames/panels),
hardware supplier, door manufacturer, GC.

YOUR issued coordination drawings at root level.
Their drawings/schedules in _received/.
Assembly pieces in _source/.
Coordination transmittal template in _template/.

⚠  LIABILITY: Feature's drawings issued for COORDINATION
ONLY. Other trades must NOT use these for fabrication.
Use the transmittal template – it contains the disclaimer.
"@

$newReadmes["09-coordination\doors\_received"] = @"

── doors / _received ──────────────────────────────

FROM OTHER PARTIES – hardware schedules, door
manufacturer shop drawings, GC coordination docs.
Filed as-is with their naming.

Track who sent what and when – this is your
evidence if another trade fabricates from your
coordination drawing instead of their own.
"@

$newReadmes["09-coordination\doors\_source"] = @"

── doors / _source ────────────────────────────────

WORKING PIECES for door coordination packages.
Elevations, hardware schedules, frame details
before they're assembled into the issued package.

Not for distribution – assembly area only.
"@

$newReadmes["09-coordination\doors\_template"] = @"

── doors / _template ──────────────────────────────

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

    # 1. Update index.json version
    $indexPath = Join-Path $ProjectPath "_cambium\index.json"
    if (Test-Path $indexPath) {
        try {
            $index = Get-Content $indexPath -Raw | ConvertFrom-Json
            if ($index.version -ne "5.5.5") {
                $index.version = "5.5.5"
                if (-not $WhatIf) {
                    $index | ConvertTo-Json -Depth 10 | Set-Content -Path $indexPath -Encoding UTF8
                }
                $changes += "UPDATE: index.json version -> 5.5.5"
            }
        } catch {
            $changes += "ERROR: Could not update index.json"
        }
    }

    # 2. Deploy Unicode READMEs for v5.5.4 folders
    foreach ($key in $newReadmes.Keys) {
        $readmePath = Join-Path $ProjectPath "$key\_README.txt"
        $parentDir = Split-Path $readmePath -Parent

        if (Test-Path $parentDir) {
            if (-not $WhatIf) {
                $newReadmes[$key] | Set-Content -Path $readmePath -Encoding UTF8
            }
            $changes += "README: $key (Unicode)"
        }
    }

    return $changes
}

# Main execution
$projects = Get-ChildItem -Path $ProjectsRoot -Directory | Where-Object { $_.Name -notmatch "^_" }

foreach ($project in $projects) {
    $projectPath = $project.FullName
    $projectName = $project.Name

    # Check if this is a Feature Millwork project (has _cambium)
    $hasCambium = Test-Path (Join-Path $projectPath "_cambium")

    if (-not $hasCambium) {
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

if ($WhatIf) {
    Write-Host ""
    Write-Host "DRY RUN complete. Run without -WhatIf to apply changes." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "v5.5.5 upgrade complete." -ForegroundColor Green
}
