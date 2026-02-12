# C:\Dev\Dejavara\scripts\audit-project-structure.ps1
# V5.4 Project Structure Auditor
# Verifies each project has all required folders and metadata

param(
    [string]$ProjectsRoot = "C:\Projects",
    [string]$OutputPath = "C:\Projects\_audit"
)

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd"
$outputFile = "$OutputPath\structure-audit-$timestamp.csv"

# V5.4 required folders (00-11 + system folders)
$requiredFolders = @(
    "00-contract",
    "01-admin",
    "02-financial",
    "03-cad",
    "03-cad/working",
    "03-cad/archive",
    "04-drawings",
    "05-materials",
    "06-samples",
    "07-production",
    "08-buyout",
    "09-coordination",
    "10-site",
    "11-awmac",
    "_archive",
    "_cambium"
)

$requiredFiles = @(
    "_cambium/index.json",
    "07-production/_fo-index.md"
)

$results = @()

# Get all project folders (exclude system folders starting with _)
$projects = Get-ChildItem -Path $ProjectsRoot -Directory | Where-Object { $_.Name -notmatch "^_" }

Write-Host "Auditing $($projects.Count) projects in $ProjectsRoot" -ForegroundColor Cyan
Write-Host ""

foreach ($project in $projects) {
    $projectPath = $project.FullName
    $projectName = $project.Name

    Write-Host "Checking: $projectName" -ForegroundColor White

    # Check folders
    foreach ($folder in $requiredFolders) {
        $folderPath = Join-Path $projectPath $folder
        $exists = Test-Path $folderPath

        $results += [PSCustomObject]@{
            Project = $projectName
            Type = "Folder"
            Item = $folder
            Exists = $exists
            Path = $folderPath
        }

        if (-not $exists) {
            Write-Host "  MISSING: $folder" -ForegroundColor Yellow
        }
    }

    # Check files
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $projectPath $file
        $exists = Test-Path $filePath

        # Check index.json version if it exists
        $version = ""
        if ($exists -and $file -eq "_cambium/index.json") {
            try {
                $json = Get-Content $filePath -Raw | ConvertFrom-Json
                $version = $json.version
            } catch {
                $version = "INVALID JSON"
            }
        }

        $results += [PSCustomObject]@{
            Project = $projectName
            Type = "File"
            Item = $file
            Exists = $exists
            Path = $filePath
            Version = $version
        }

        if (-not $exists) {
            Write-Host "  MISSING: $file" -ForegroundColor Yellow
        } elseif ($version -and $version -ne "5.4") {
            Write-Host "  VERSION: $file = $version (expected 5.4)" -ForegroundColor DarkYellow
        }
    }

    # Check for files in project root (inbox should be empty ideally)
    $rootFiles = Get-ChildItem -Path $projectPath -File -ErrorAction SilentlyContinue
    if ($rootFiles.Count -gt 0) {
        Write-Host "  INBOX: $($rootFiles.Count) file(s) in project root" -ForegroundColor Magenta
        foreach ($f in $rootFiles) {
            $results += [PSCustomObject]@{
                Project = $projectName
                Type = "InboxFile"
                Item = $f.Name
                Exists = $true
                Path = $f.FullName
            }
        }
    }
}

# Export results
$results | Export-Csv -Path $outputFile -NoTypeInformation

# Summary
Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
$missing = $results | Where-Object { $_.Exists -eq $false }
$inboxFiles = $results | Where-Object { $_.Type -eq "InboxFile" }

Write-Host "Total projects: $($projects.Count)" -ForegroundColor White
Write-Host "Missing items: $($missing.Count)" -ForegroundColor $(if ($missing.Count -eq 0) { "Green" } else { "Yellow" })
Write-Host "Inbox files: $($inboxFiles.Count)" -ForegroundColor $(if ($inboxFiles.Count -eq 0) { "Green" } else { "Magenta" })
Write-Host ""
Write-Host "Results saved to: $outputFile" -ForegroundColor Green
