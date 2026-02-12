# C:\Dev\Dejavara\scripts\new-project.ps1
# V5.3.1 Project Structure Generator
param(
    [Parameter(Mandatory)][string]$Name,
    [string]$JobNumber
)

$projectName = if ($JobNumber) { "$JobNumber-$Name".ToLower() } else { $Name.ToLower() }
$root = "C:\Projects\$projectName"

if (Test-Path $root) {
    Write-Host "Project already exists: $root" -ForegroundColor Yellow
    exit 1
}

# V5.3 12-folder structure (00-11) + system folders
$folders = @(
    "00-contract/addenda",
    "00-contract/agreement",
    "00-contract/drawings",
    "00-contract/ifc",
    "00-contract/ift",
    "00-contract/insurance",
    "00-contract/scope",
    "00-contract/specifications",
    "01-admin/ccn",
    "01-admin/certs",           # v5.3: AWMAC MSE certificate
    "01-admin/change-order",
    "01-admin/close-out",
    "01-admin/deficiencies",
    "01-admin/email",
    "01-admin/field-notice",
    "01-admin/install",
    "01-admin/meeting-minutes",
    "01-admin/rfi",
    "01-admin/rfp",
    "01-admin/schedule",
    "01-admin/shipping",
    "01-admin/site-instruction",
    "01-admin/submittal",
    "01-admin/transmittal",
    "02-financial/budget",
    "02-financial/invoices",
    "02-financial/po-log",
    "02-financial/progress-claims",
    "03-cad/archive",
    "03-cad/as-built",
    "03-cad/coordination",
    "03-cad/library",
    "03-cad/working",
    "04-drawings/approved",
    "04-drawings/buyout",
    "04-drawings/install",
    "04-drawings/production",
    "04-drawings/revision",
    "04-drawings/submittal",
    "04-drawings/submittal/_source",  # v5.3: Source files
    "05-materials/countertops/custom",
    "05-materials/countertops/laminate",
    "05-materials/countertops/porcelain",
    "05-materials/countertops/quartz",
    "05-materials/countertops/solid-surface",
    "05-materials/countertops/stone",
    "05-materials/custom",
    "05-materials/finish/paint",
    "05-materials/finish/stain",
    "05-materials/glass",
    "05-materials/hardware",
    "05-materials/laminate",
    "05-materials/metals",
    "05-materials/sheet-goods",
    "05-materials/solid",
    "05-materials/takeoff",
    "05-materials/upholstery",
    "05-materials/veneer",
    "06-samples/countertops/custom",
    "06-samples/countertops/laminate",
    "06-samples/countertops/porcelain",
    "06-samples/countertops/quartz",
    "06-samples/countertops/solid-surface",
    "06-samples/countertops/stone",
    "06-samples/custom",
    "06-samples/finish/paint",
    "06-samples/finish/stain",
    "06-samples/glass",
    "06-samples/hardware",
    "06-samples/laminate",
    "06-samples/metals",
    "06-samples/mockup",
    "06-samples/sheet-goods",
    "06-samples/solid",
    "06-samples/upholstery",
    "06-samples/veneer",
    "07-production",
    "08-buyout",
    "09-coordination/custom",
    "09-coordination/drywall",
    "09-coordination/electrical",
    "09-coordination/glazing",
    "09-coordination/hvac",
    "09-coordination/mechanical",
    "09-coordination/plumbing",
    "10-site/measure",
    "10-site/photo",
    "11-awmac/gis-reports",
    "11-awmac/inspections",
    "11-awmac/monitoring",
    "11-awmac/qc",
    "11-awmac/reports",
    "11-awmac/submissions",
    "11-awmac/_source",         # v5.3: Working AWMAC files
    "11-awmac/_received",       # v5.3: External AWMAC files
    "_archive",
    "_cambium/cache",
    "_cambium/qr"
)

foreach ($f in $folders) {
    New-Item -ItemType Directory -Force -Path "$root/$f" | Out-Null
}

# Create FO index
@"
# Factory Orders - $projectName

| FO# | Description | Status | Sheets | Location |
|-----|-------------|--------|--------|----------|
"@ | Out-File "$root/07-production/_fo-index.md" -Encoding UTF8

# Create Cambium index.json
@"
{
  "project": "$projectName",
  "created": "$(Get-Date -Format 'yyyy-MM-dd')",
  "version": "5.3",
  "factoryOrders": []
}
"@ | Out-File "$root/_cambium/index.json" -Encoding UTF8

Write-Host "V5.3 Project created: $root" -ForegroundColor Green
Write-Host "  12 numbered folders (00-11)" -ForegroundColor Cyan
Write-Host "  FO index at 07-production/_fo-index.md" -ForegroundColor Cyan
