# Feature Millwork — New Project Scaffold
# Usage: powershell -ExecutionPolicy Bypass -File new-project.ps1 -Name "job-name"
# Creates C:\Projects\{job-name}\ with full template per Documentation Standards v5.5

param(
    [Parameter(Mandatory=$true)]
    [string]$Name
)

$root = "C:\Projects"
$projectPath = Join-Path $root $Name

if (Test-Path $projectPath) {
    Write-Host "ERROR: $projectPath already exists" -ForegroundColor Red
    exit 1
}

# Full folder template — v5.5
$template = @(
    "00-contract\addenda"
    "00-contract\agreement"
    "00-contract\drawings"
    "00-contract\insurance"
    "00-contract\specifications"
    "01-admin\ccn"
    "01-admin\ccn\_received"
    "01-admin\certs"
    "01-admin\change-order"
    "01-admin\change-order\_received"
    "01-admin\close-out"
    "01-admin\email-disputes"
    "01-admin\deficiencies"
    "01-admin\field-notice"
    "01-admin\install"
    "01-admin\meeting-minutes"
    "01-admin\rfi"
    "01-admin\rfi\_received"
    "01-admin\rfi\_template"
    "01-admin\rfp"
    "01-admin\schedule"
    "01-admin\shipping"
    "01-admin\site-instruction"
    "01-admin\submittal"
    "01-admin\submittal\_source"
    "01-admin\submittal\_received"
    "01-admin\submittal\_template"
    "02-financial\budget"
    "02-financial\invoices"
    "02-financial\po-log"
    "02-financial\progress-claims"
    "03-cad\archive"
    "03-cad\as-built"
    "03-cad\coordination"
    "03-cad\library"
    "03-cad\working"
    "04-drawings\approved"
    "04-drawings\as-built"
    "04-drawings\buyout"
    "04-drawings\install"
    "04-drawings\production"
    "04-drawings\revision"
    "05-materials\countertops\custom"
    "05-materials\countertops\laminate"
    "05-materials\countertops\porcelain"
    "05-materials\countertops\quartz"
    "05-materials\countertops\solid-surface"
    "05-materials\countertops\stone"
    "05-materials\custom"
    "05-materials\doors"
    "05-materials\finish\paint"
    "05-materials\finish\stain"
    "05-materials\glass"
    "05-materials\hardware"
    "05-materials\laminate"
    "05-materials\metals"
    "05-materials\powdercoating"
    "05-materials\sheet-goods"
    "05-materials\solid"
    "05-materials\takeoff"
    "05-materials\upholstery"
    "05-materials\veneer"
    "06-samples\countertops\custom"
    "06-samples\countertops\laminate"
    "06-samples\countertops\porcelain"
    "06-samples\countertops\quartz"
    "06-samples\countertops\solid-surface"
    "06-samples\countertops\stone"
    "06-samples\custom"
    "06-samples\doors"
    "06-samples\finish\paint"
    "06-samples\finish\stain"
    "06-samples\glass"
    "06-samples\hardware"
    "06-samples\laminate"
    "06-samples\metals"
    "06-samples\powdercoating"
    "06-samples\mockup"
    "06-samples\sheet-goods"
    "06-samples\solid"
    "06-samples\upholstery"
    "06-samples\veneer"
    "07-production"
    "08-buyout"
    "08-buyout\quotes"
    "09-coordination\custom"
    "09-coordination\doors"
    "09-coordination\doors\_received"
    "09-coordination\doors\_source"
    "09-coordination\doors\_template"
    "09-coordination\drywall"
    "09-coordination\electrical"
    "09-coordination\glazing"
    "09-coordination\hvac"
    "09-coordination\mechanical"
    "09-coordination\plumbing"
    "10-site\measure"
    "10-site\photo"
    "11-awmac\submissions"
    "11-awmac\qc"
    "11-awmac\_source"
    "11-awmac\_received"
    "11-awmac\_template"
    "_archive"
    "_cambium\cache"
)

# Create all folders
foreach ($folder in $template) {
    New-Item -ItemType Directory -Path (Join-Path $projectPath $folder) -Force | Out-Null
}

# Create _fo-index.md
@"
# FO Index — $Name

| FO# | Scope | Date Claimed | Status |
|-----|-------|-------------|--------|
"@ | Set-Content -Path (Join-Path $projectPath "07-production\_fo-index.md") -Encoding UTF8

# ── README CONTENT ──
# Lightweight: only key folders get READMEs in single-project mode.
# Full README set is deployed by scaffold-projects.ps1 for batch operations.

$readmes = @{
    "." = "── PROJECT ROOT = INBOX ──`nAny file here is UNSORTED. File it NOW.`nNaming: [Job]-[Type]-[Seq]-R[#]-[Date].[ext]"
    "00-contract" = "── 00-CONTRACT ──`nDocuments that define the scope of work.`nFrom architect/client. If it defines what you build, it's contract."
    "01-admin" = "── 01-ADMIN ──`nExternal correspondence crossing the project boundary.`nRule: External comms here. Internal outputs in 04-drawings/."
    "01-admin\rfi" = "── RFI ──`nNaming: [Job]-RFI-[Seq]-R[#]-[Date].[ext]`nExample: 2419-RFI-001-R0-20260128.pdf`nYour RFIs at root. Responses in _received/. Form in _template/."
    "01-admin\rfi\_received" = "── rfi / _received ──`nRFI responses from architect/consultant. Filed as-is."
    "01-admin\rfi\_template" = "── rfi / _template ──`nBlank RFI form. Save-As with job code + date on use."
    "01-admin\ccn\_received" = "── ccn / _received ──`nOriginal CCN/PCN from architect/GC. Filed as-is."
    "01-admin\submittal" = "── SUBMITTALS ──`nNaming: [Job]-SUB-[Seq]-feature-millwork-R[#]-[Date].pdf`nBuild pieces in _source/. Responses in _received/. Forms in _template/."
    "01-admin\submittal\_template" = "── submittal / _template ──`nTransmittal cover page + blank forms. Unsigned, reusable."
    "11-awmac\_template" = "── 11-awmac / _template ──`nAWMAC forms: INSI, INSF, HUM. Save-As with job + date on use."
    "03-cad\working" = "── ACTIVE DRAWINGS ── always current, NO date in filename.`nSingle: {jobname}.dwg  Multi: {jobname}-{descriptor}.dwg"
    "04-drawings\production" = "── PRODUCTION DRAWINGS ──`nNaming: FO[#]-[Sheet]-[Desc]-R[#]-[Date].pdf`nExample: FO15961-1.0-office-cabinets-R1-20260128.pdf"
    "07-production" = "── PRODUCTION ──`nPer FO subfolder once assigned. Working cutlists at this level.`n_fo-index.md links FO numbers to C:\FO\ paths."
    "10-site\photo" = "── SITE PHOTOS ──`nNaming: YYYYMMDD-[location]-[description].jpg`nExample: 20260211-reception-backing-verification.jpg"
}

foreach ($key in $readmes.Keys) {
    if ($key -eq ".") {
        $readmePath = Join-Path $projectPath "_README.txt"
    } else {
        $readmePath = Join-Path $projectPath "$key\_README.txt"
    }
    $parentDir = Split-Path $readmePath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    $readmes[$key] | Set-Content -Path $readmePath -Encoding UTF8
}

Write-Host "Created: $projectPath (14 folders + READMEs + _fo-index.md)" -ForegroundColor Green
