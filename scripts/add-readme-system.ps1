# C:\Dev\Dejavara\scripts\add-readme-system.ps1
# V5.5 README System Retrofit
# Adds _README.txt files to existing projects

param(
    [string]$ProjectsRoot = "C:\Projects",
    [switch]$DryRun = $false
)

$added = 0
$skipped = 0
$projects = 0

Write-Host "Adding README system to existing projects (v5.5)..." -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "(DRY RUN - no changes will be made)" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# README CONTENT - Full training system (same as new-project.ps1)
# ============================================================================

$readmes = @{}

$readmes["."] = @"
-- PROJECT ROOT = INBOX -----------------------------

Any file sitting here is UNSORTED and needs to be filed NOW.
This is not a parking lot. Process immediately.

Naming: [Job]-[Type]-[Seq]-R[#]-[Date].[ext]
Example: 2419-RFI-003-R0-20260128.pdf

See Filing Decision Guide in P:\standards\doc-standards\
"@

$readmes["00-contract"] = @"
-- 00-CONTRACT --------------------------------------

CONTRACT DOCUMENTS - what defines the scope of work.
Documents FROM the architect/client that form the agreement.

What goes here: Signed contracts, architectural drawings,
  specifications, addenda, insurance certificates.

What does NOT go here: Your submittals, your shop drawings,
  RFIs, correspondence (those go in 01-admin/).

Rule: If it defines what you agreed to build, it's contract.
"@

$readmes["00-contract\addenda"] = @"
-- 00-contract / addenda ----------------------------

CONTRACT ADDENDA from architect.
File as received - keep their naming.

Examples:
  Addendum-01-2025-12-15.pdf
  Addendum-02-Revised-Specs-2026-01-10.pdf
"@

$readmes["00-contract\agreement"] = @"
-- 00-contract / agreement --------------------------

SIGNED CONTRACTS, AMENDMENTS, SCOPE DOCUMENTS

Examples:
  2419-CON-001-R0-20260115.pdf
  Feature-Millwork-Subcontract-Signed.pdf
"@

$readmes["00-contract\drawings"] = @"
-- 00-contract / drawings ---------------------------

ARCHITECT / CONSULTANT DRAWINGS

IFC, IFT, reference drawings, sketches.
File as received - keep their naming.

Examples:
  A100-Floor-Plan-IFC-2025-12-01.pdf
  SK-Reception-Detail-2026-01-15.pdf
"@

$readmes["00-contract\insurance"] = @"
-- 00-contract / insurance --------------------------

INSURANCE CERTIFICATES, COIs, WCB CLEARANCE

Examples:
  Feature-Millwork-COI-2026.pdf
  WCB-Clearance-2026-01.pdf
"@

$readmes["00-contract\specifications"] = @"
-- 00-contract / specifications ---------------------

CONTRACT SPECIFICATIONS - Div 06, Div 09, etc.
File as received.

Examples:
  064023-Interior-Architectural-Woodwork.pdf
  099113-Exterior-Painting.pdf
"@

$readmes["01-admin"] = @"
-- 01-ADMIN -----------------------------------------

PROJECT ADMINISTRATION - external correspondence
that crosses the project boundary.

Rule: External comms go here.
      Internal outputs go in 04-drawings/.
"@

$readmes["01-admin\ccn"] = @"
-- 01-admin / ccn -----------------------------------

CONTEMPLATED CHANGE NOTICES
(also called PCN, CCD at other firms)

Change questions from architect/GC asking for pricing.
NOT direction to proceed - that's a Change Order.

Your pricing response at root level.
Original CCN/PCN from architect/GC in _received/.

Naming: [Job]-CCN-[Seq]-R[#]-[Date].[ext]

Examples:
  2419-CCN-001-R0-20260128.pdf
  2419-CCN-002-R0-20260205.pdf
"@

$readmes["01-admin\ccn\_received"] = @"
-- ccn / _received ----------------------------------

ORIGINAL CCN/PCN DOCUMENTS from architect or GC.
Filed as-is with their naming.

Your pricing responses stay at the ccn/ root level.
"@

$readmes["01-admin\certs"] = @"
-- 01-admin / certs ---------------------------------

TRADE CERTIFICATIONS
AWMAC MSE certs, trade qualifications.
Keep current - expired cert = rejected inspection.

Examples:  AWMAC-MSE-Cert.pdf
"@

$readmes["01-admin\change-order"] = @"
-- 01-admin / change-order --------------------------

CHANGE ORDERS - approved scope/cost changes.
A CCN becomes a CO once pricing is accepted.

Naming: [Job]-CO-[Seq]-R[#]-[Date].[ext]

Examples:
  2419-CO-001-R0-20260210.pdf
  2419-CO-002-R0-20260301.pdf
"@

$readmes["01-admin\close-out"] = @"
-- 01-admin / close-out -----------------------------

CLOSE-OUT DOCUMENTS
Warranties, maintenance manuals, completion certs.

Examples:
  2419-Warranty-Letter-20260501.pdf
  Substantial-Completion-Certificate.pdf
"@

$readmes["01-admin\deficiencies"] = @"
-- 01-admin / deficiencies --------------------------

DEFICIENCY LISTS & PUNCHLISTS
Can occur at any phase, not just close-out.

Naming: [Job]-PUN-[Seq]-R[#]-[Date].[ext]

Examples:
  2419-PUN-001-R0-20260401.pdf
"@

$readmes["01-admin\email"] = @"
-- 01-admin / email ---------------------------------

SAVED EMAILS & GENERAL LETTERS
Catch-all for correspondence that doesn't fit
RFI, CCN, CO, or other specific categories.

Naming: [Job]-COR-[Seq]-R[#]-[Date].[ext]

Examples:
  2419-COR-001-R0-20260128.pdf
"@

$readmes["01-admin\field-notice"] = @"
-- 01-admin / field-notice --------------------------

FIELD NOTICES - from the GC.
Site conditions, schedule changes, access restrictions.

(Site Instructions from architect go in site-instruction/)
"@

$readmes["01-admin\install"] = @"
-- 01-admin / install -------------------------------

INSTALLATION COORDINATION
Feature's admin comms TO installers.
Schedules, scope, delivery coordination.

(Other trades go in 09-coordination/)
"@

$readmes["01-admin\meeting-minutes"] = @"
-- 01-admin / meeting-minutes -----------------------

MEETING RECORDS - site meetings, OAC meetings.

Naming: [Job]-MTG-[Seq]-R[#]-[Date].[ext]

Examples:
  2419-MTG-001-R0-20260128.pdf
"@

$readmes["01-admin\rfi"] = @"
-- 01-admin / rfi -----------------------------------

REQUESTS FOR INFORMATION
RFIs you send TO architect/consultant/GC at root level.
Responses in _received/. RFI form template in _template/.

Naming: [Job]-RFI-[Seq]-R[#]-[Date].[ext]

Examples:
  2419-RFI-001-R0-20260128.pdf     (your question)
  2419-RFI-002-R0-20260210.pdf     (second RFI)
"@

$readmes["01-admin\rfi\_received"] = @"
-- rfi / _received ----------------------------------

RFI RESPONSES from architect/consultant.
Filed as-is with their naming.

Your issued RFIs stay at the rfi/ root level.
"@

$readmes["01-admin\rfi\_template"] = @"
-- rfi / _template ----------------------------------

RFI FORM TEMPLATE - blank, unsigned, reusable.

Naming: feature-RFI-001-R0-template.docx

On use: Save-As with job code + date.
  feature-RFI-001-R0-template.docx
    -> 2419-RFI-001-R0-20260128.pdf
"@

$readmes["01-admin\rfp"] = @"
-- 01-admin / rfp -----------------------------------

REQUESTS FOR PRICING
Pricing requests received from GC/client.

Naming: [Job]-RFP-[Seq]-R[#]-[Date].[ext]
"@

$readmes["01-admin\schedule"] = @"
-- 01-admin / schedule ------------------------------

PROJECT SCHEDULES
Gantt charts, milestones, look-ahead schedules.
"@

$readmes["01-admin\shipping"] = @"
-- 01-admin / shipping ------------------------------

SHIPPING & DELIVERY
Courier waybills, manifests, bills of lading.
"@

$readmes["01-admin\site-instruction"] = @"
-- 01-admin / site-instruction ----------------------

SITE INSTRUCTIONS - from the ARCHITECT.
(Field notices from GC go in field-notice/)

Naming: [Job]-SI-[Seq]-R[#]-[Date].[ext]

Examples:
  2419-SI-001-R0-20260128.pdf
"@

$readmes["01-admin\submittal"] = @"
-- 01-admin / submittal -----------------------------

ALL SUBMITTALS - shop drawings + materials.
Build pieces in _source/. Responses in _received/.

Naming: [Job]-SUB-[Seq]-feature-millwork-R[#]-[Date].pdf

Examples:
  2419-SUB-001-feature-millwork-R0-20260128.pdf
  2419-SUB-002-feature-millwork-R0-20260205.pdf
"@

$readmes["01-admin\submittal\_source"] = @"
-- submittal / _source ------------------------------

BUILD PIECES - not for distribution.
One subfolder per submittal: sub-001/, sub-002/, etc.
Contents use descriptive names (no formal convention).
"@

$readmes["01-admin\submittal\_received"] = @"
-- submittal / _received ----------------------------

ARCHITECT RESPONSES - stamped returns.
Filed as-is with their original filename.

Examples:
  FM-SD-Package-1-Reviewed-AAN.pdf
"@

$readmes["01-admin\submittal\_template"] = @"
-- submittal / _template ----------------------------

SUBMITTAL TEMPLATES - transmittal cover page,
blank forms. Unsigned, reusable.

Naming: feature-SUB-001-R0-template.pdf

On use: Save-As with job code + date, then sign.
"@

$readmes["02-financial"] = @"
-- 02-FINANCIAL -------------------------------------

MONEY IN - client paying Feature.
Budgets, billing, invoices, progress claims.

(Money OUT to vendors goes in 08-buyout/)
"@

$readmes["02-financial\budget"] = @"
-- 02-financial / budget ----------------------------

BUDGETS & ESTIMATES - bid pricing, cost tracking.
(Production takeoffs go in 05-materials/takeoff/)

Naming: [Job]-EST-[Seq]-R[#]-[Date].[ext]
"@

$readmes["02-financial\invoices"] = @"
-- 02-financial / invoices --------------------------

INVOICES sent to / received from client.

Naming: [Job]-INV-[Seq]-R[#]-[Date].[ext]
"@

$readmes["02-financial\po-log"] = @"
-- 02-financial / po-log ----------------------------

PURCHASE ORDER REGISTER - overview index only.
Actual PO documents live in 08-buyout/{vendor}/po/.
"@

$readmes["02-financial\progress-claims"] = @"
-- 02-financial / progress-claims -------------------

PROGRESS BILLING - claims, payment certs, draws.
"@

$readmes["03-cad"] = @"
-- 03-CAD -------------------------------------------

CAD SOURCE FILES - .dwg working files.
This is where you WORK. PDFs go to 04-drawings/.
Working files have NO revision or date in filename.
"@

$readmes["03-cad\archive"] = @"
-- 03-cad / archive ---------------------------------

SUPERSEDED CAD VERSIONS - dated when archived.

Examples:
  netflix-cabinets-20260126.dwg
"@

$readmes["03-cad\as-built"] = @"
-- 03-cad / as-built --------------------------------

AS-BUILT DWG SOURCE - issued PDFs go to 04-drawings/as-built/.

Naming: {jobname}-asbuilt-R[#]-[Date].dwg
"@

$readmes["03-cad\coordination"] = @"
-- 03-cad / coordination ----------------------------

TRADE COORDINATION OVERLAYS

Naming: {jobname}-coord-{trade}.dwg

Example: netflix-coord-electrical.dwg
"@

$readmes["03-cad\library"] = @"
-- 03-cad / library ---------------------------------

DETAIL LIBRARY - reusable blocks and details.

Naming: detail-{category}.dwg
"@

$readmes["03-cad\working"] = @"
-- 03-cad / working ---------------------------------

ACTIVE DRAWINGS - always current. NO date in filename.

Naming:
  Single DWG:  {jobname}.dwg
  Multi DWG:   {jobname}-{descriptor}.dwg

Examples:
  chambers.dwg
  netflix-lobby.dwg
  netflix-ceiling.dwg
"@

$readmes["04-drawings"] = @"
-- 04-DRAWINGS --------------------------------------

ISSUED DRAWING OUTPUTS - PDFs only.
Internal outputs organized by destination.

(Submittals sent externally go in 01-admin/submittal/)
"@

$readmes["04-drawings\approved"] = @"
-- 04-drawings / approved ---------------------------

RETURNED WITH APPROVAL STAMPS
Filed as-is with their naming.
"@

$readmes["04-drawings\as-built"] = @"
-- 04-drawings / as-built ---------------------------

AS-BUILT RECORD PDFs for close-out.
DWG source stays in 03-cad/as-built/.
"@

$readmes["04-drawings\buyout"] = @"
-- 04-drawings / buyout -----------------------------

DRAWINGS ISSUED FOR PROCUREMENT
Sent to vendors/subcontractors for quoting/fabrication.
"@

$readmes["04-drawings\install"] = @"
-- 04-drawings / install ----------------------------

INSTALLATION DRAWINGS for site crew.
"@

$readmes["04-drawings\production"] = @"
-- 04-drawings / production -------------------------

SHOP FLOOR PRODUCTION DRAWINGS
Individual per-sheet PDFs named with FO number.

Naming: FO[#]-[Sheet]-[Desc]-R[#]-[Date].pdf

Examples:
  FO15961-1.0-office-cabinets-R1-20260128.pdf
  FO15961-1.1-office-cabinets-R1-20260128.pdf
"@

$readmes["04-drawings\revision"] = @"
-- 04-drawings / revision ---------------------------

REVISION SNAPSHOTS - one subfolder per drawing.
Never delete - you need history for disputes.

Structure:
  {drawing-id}/
    r0_2025-02-05.dwg
    r0_2025-02-05.pdf
    revision-log.json
"@

$readmes["05-materials"] = @"
-- 05-MATERIALS -------------------------------------

MATERIAL SPECIFICATIONS - what things are made of.
Spec sheets organized by material type.

(Physical samples go in 06-samples/)
"@

$readmes["05-materials\countertops"] = @"
-- 05-materials / countertops -----------------------

COUNTERTOP SPECS - by material type subfolder.
"@

$readmes["05-materials\custom"] = @"
-- 05-materials / custom ----------------------------

CUSTOM / SPECIALTY MATERIALS - one-offs, specialty composites.
"@

$readmes["05-materials\doors"] = @"
-- 05-materials / doors -----------------------------

DOOR SPECS - fire ratings, glazing, keying schedules.
"@

$readmes["05-materials\finish"] = @"
-- 05-materials / finish ----------------------------

FINISH SPECS - subfolders: paint/ and stain/.
"@

$readmes["05-materials\glass"] = @"
-- 05-materials / glass -----------------------------

GLASS & MIRROR SPECIFICATIONS
"@

$readmes["05-materials\hardware"] = @"
-- 05-materials / hardware --------------------------

HARDWARE SPECS - hinges, slides, pulls, locks.

Naming: [Job]-HW-[Seq]-R[#]-[Date].[ext]
"@

$readmes["05-materials\laminate"] = @"
-- 05-materials / laminate --------------------------

LAMINATE SPECS - HPL, TFL, melamine.
"@

$readmes["05-materials\metals"] = @"
-- 05-materials / metals ----------------------------

METAL SPECIFICATIONS - trim, cladding, components.
"@

$readmes["05-materials\sheet-goods"] = @"
-- 05-materials / sheet-goods -----------------------

SHEET GOODS - MDF, plywood, particle board, FR ply.
"@

$readmes["05-materials\solid"] = @"
-- 05-materials / solid -----------------------------

SOLID WOOD - species, grades, moisture content.
"@

$readmes["05-materials\takeoff"] = @"
-- 05-materials / takeoff ---------------------------

PRODUCTION MATERIAL TAKEOFFS - "how much to order."
(Estimator takeoffs for bidding go in 02-financial/budget/)
"@

$readmes["05-materials\upholstery"] = @"
-- 05-materials / upholstery ------------------------

UPHOLSTERY - fabric, leather, vinyl, foam specs.
"@

$readmes["05-materials\veneer"] = @"
-- 05-materials / veneer ----------------------------

VENEER - specs, flitch records, matching requirements.
"@

$readmes["06-samples"] = @"
-- 06-SAMPLES ---------------------------------------

SAMPLE RECORDS - photos, approvals, documentation.
Mirrors 05-materials/ structure.

(Material spec sheets go in 05-materials/)
"@

$readmes["06-samples\countertops"] = @"
-- 06-samples / countertops -------------------------

COUNTERTOP SAMPLES - photos, approval records.
"@

$readmes["06-samples\doors"] = @"
-- 06-samples / doors -------------------------------

DOOR SAMPLES - finish samples, stain on door species.
"@

$readmes["06-samples\mockup"] = @"
-- 06-samples / mockup ------------------------------

FULL-SIZE MOCKUP DOCUMENTATION
Photos, approval records, measurements.
"@

$readmes["07-production"] = @"
-- 07-PRODUCTION ------------------------------------

PRODUCTION DOCUMENTS - per Factory Order.
Working cutlists (pre-FO#) at this level.
_fo-index.md links FO numbers to C:\FO\ paths.

Pre-FO naming: {jobname}-cutlist.xlsx
FO structure:  {fo-number}/cut-lists/, parts-list/,
               preglue/, revision/, work-orders/
"@

$readmes["08-buyout"] = @"
-- 08-BUYOUT ----------------------------------------

MONEY OUT - Feature paying vendors.
One subfolder per vendor. Create subfolders as needed:
  po/ + quotes/  (simple purchase)
  + drawings/ + wo/ + _received/ + correspondence/ (full)

quotes/ at root = comparing vendors for same scope.
Once vendor selected, quote moves into their folder.
"@

$readmes["08-buyout\quotes"] = @"
-- 08-buyout / quotes -------------------------------

PRE-DECISION VENDOR COMPARISON

Competing quotes for the same scope before you've
picked a vendor. Once PO is issued, move the winning
quote into 08-buyout/{vendor}/quotes/.

This folder may stay empty on projects where you
go straight to a known vendor.
"@

$readmes["09-coordination"] = @"
-- 09-COORDINATION ----------------------------------

OTHER TRADES - cross-trade communications.
Create additional trade folders as needed.

(Feature's install coordination goes in 01-admin/install/)
"@

$readmes["10-site"] = @"
-- 10-SITE ------------------------------------------

FIELD DATA - site visits and measurements.
"@

$readmes["10-site\measure"] = @"
-- 10-site / measure --------------------------------

SITE MEASUREMENTS - field dimensions, surveys.
"@

$readmes["10-site\photo"] = @"
-- 10-site / photo ----------------------------------

SITE PHOTOS - rename on same day taken.

Naming: YYYYMMDD-[location]-[description].jpg

Examples:
  20260211-reception-backing-verification.jpg
  20260305-lobby-damage-before-install.jpg
"@

$readmes["11-awmac"] = @"
-- 11-AWMAC -----------------------------------------

AWMAC / GIS QUALITY PROGRAM
submissions/ = what you send
qc/ = your internal checks
_received/ = what comes back
"@

$readmes["11-awmac\submissions"] = @"
-- 11-awmac / submissions ---------------------------

SENT TO AWMAC/GIS - inspection requests, humidity reports.
Types: INSI (initial), INSF (final), HUM, GIS

Examples:
  esdc-INSI-001-R0-20251024.pdf
  esdc-GIS-001-R0-20251029.pdf
"@

$readmes["11-awmac\qc"] = @"
-- 11-awmac / qc ------------------------------------

INTERNAL QC - your checklists, inspection photos.
"@

$readmes["11-awmac\_source"] = @"
-- 11-awmac / _source -------------------------------

BUILD PIECES for AWMAC submissions.
One subfolder per submission: gis-001/, etc.
"@

$readmes["11-awmac\_received"] = @"
-- 11-awmac / _received -----------------------------

FROM AWMAC/GIS - reports, signed inspections.
Filed as-is.

Examples:
  gis-report-01-signed-all-20251218.pdf
"@

$readmes["11-awmac\_template"] = @"
-- 11-awmac / _template -----------------------------

AWMAC FORM TEMPLATES - INSI, INSF, HUM forms.
Unsigned, reusable.

Naming:
  awmac-INSI-001-R0-template.pdf
  awmac-INSF-001-R0-template.pdf
  awmac-HUM-001-R0-template.pdf

On use: Save-As with job code + date, then sign.
"@

$readmes["_archive"] = @"
-- _ARCHIVE -----------------------------------------

SUPERSEDED / OBSOLETE DOCUMENTS
Never delete project documents - archive them.
"@

$readmes["_cambium"] = @"
-- _CAMBIUM -----------------------------------------

CAMBIUM PLATFORM METADATA - do not manually edit.
"@

# ============================================================================
# PROCESS PROJECTS
# ============================================================================

function Add-ReadmesToProject {
    param(
        [string]$ProjectPath,
        [string]$ProjectName
    )

    $projectAdded = 0

    foreach ($key in $script:readmes.Keys) {
        if ($key -eq ".") {
            $folderPath = $ProjectPath
            $readmePath = Join-Path $ProjectPath "_README.txt"
        } else {
            $folderPath = Join-Path $ProjectPath $key
            $readmePath = Join-Path $folderPath "_README.txt"
        }

        # Only add README if folder exists and README doesn't
        if ((Test-Path $folderPath) -and -not (Test-Path $readmePath)) {
            if (-not $script:DryRun) {
                $script:readmes[$key] | Set-Content -Path $readmePath -Encoding UTF8
            }
            $projectAdded++
            $script:added++
        } elseif (Test-Path $readmePath) {
            $script:skipped++
        }
    }

    return $projectAdded
}

# Scan projects (flat structure - no nesting per v5.4.4+ spec)
$items = Get-ChildItem -Path $ProjectsRoot -Directory | Where-Object { $_.Name -notmatch "^_" }

foreach ($item in $items) {
    $projectPath = $item.FullName
    $projectName = $item.Name

    # Check if this is a Cambium project (has _cambium folder)
    if (Test-Path (Join-Path $projectPath "_cambium")) {
        $projects++
        $count = Add-ReadmesToProject -ProjectPath $projectPath -ProjectName $projectName

        if ($count -gt 0) {
            Write-Host "  $projectName`: +$count READMEs" -ForegroundColor Green
        } else {
            Write-Host "  $projectName`: already has READMEs" -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Cyan
Write-Host "Projects scanned: $projects" -ForegroundColor White
Write-Host "READMEs added: $added" -ForegroundColor Green
Write-Host "READMEs skipped (already exist): $skipped" -ForegroundColor DarkGray

if ($DryRun) {
    Write-Host ""
    Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
}
