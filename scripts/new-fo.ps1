# C:\Dev\Dejavara\scripts\new-fo.ps1
# V5.4 Factory Order Creator - Bare number naming
# v5.4: Part of v5.4 Documentation Standards migration
param(
    [Parameter(Mandatory)][string]$FONumber,
    [string]$Project,
    [string]$Description = "[description]"
)

$foRoot = "C:\FO\$FONumber"

if (Test-Path $foRoot) {
    Write-Host "FO already exists: $foRoot" -ForegroundColor Yellow
    exit 1
}

# Create FO folder and Shops subfolder
New-Item -ItemType Directory -Force -Path "$foRoot/Shops" | Out-Null

# Copy templates if they exist
$templatePath = "C:\FO\_templates"
if (Test-Path "$templatePath\*") {
    Copy-Item "$templatePath\*" $foRoot -ErrorAction SilentlyContinue
    Write-Host "Templates copied from $templatePath" -ForegroundColor Cyan
} else {
    Write-Host "No templates at $templatePath - create manually" -ForegroundColor Yellow
}

# Link to project if specified
if ($Project) {
    $projectPath = "C:\Projects\$Project"
    $indexPath = "$projectPath/07-production/_fo-index.md"
    
    if (Test-Path $indexPath) {
        # Add entry to FO index
        Add-Content $indexPath "| $FONumber | $Description | Not started | [sheets] | C:\FO\$FONumber\ |"
        Write-Host "Added to FO index: $indexPath" -ForegroundColor Cyan
        
        # Create production subfolder in project
        $prodFolders = @(
            "$projectPath/07-production/$FONumber/cut-lists",
            "$projectPath/07-production/$FONumber/parts-list",
            "$projectPath/07-production/$FONumber/preglue",
            "$projectPath/07-production/$FONumber/revision",
            "$projectPath/07-production/$FONumber/work-orders"
        )
        foreach ($f in $prodFolders) {
            New-Item -ItemType Directory -Force -Path $f | Out-Null
        }
        Write-Host "Created 07-production/$FONumber/ in project" -ForegroundColor Cyan
    } else {
        Write-Host "Project FO index not found: $indexPath" -ForegroundColor Yellow
    }
}

Write-Host "" -ForegroundColor Green
Write-Host "FO $FONumber created: $foRoot" -ForegroundColor Green
Write-Host "" -ForegroundColor Green
Write-Host "V5.4 naming - use bare FO number:" -ForegroundColor White
Write-Host "  $FONumber.R41     (not fo_$FONumber.R41)" -ForegroundColor DarkGray
Write-Host "  $FONumber.csv     (not fo_$FONumber.csv)" -ForegroundColor DarkGray
Write-Host "  $FONumber.xls     (not fo_$FONumber.xls)" -ForegroundColor DarkGray
