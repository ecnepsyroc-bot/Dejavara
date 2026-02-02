<#
.SYNOPSIS
    File organization helper for the three-domain strategy.

.DESCRIPTION
    Analyzes files and proposes categorization into Luxify, Personal, or Phone-Inbox.
    Always shows proposed moves and waits for approval.

.PARAMETER SourcePath
    Path to scan for files to organize.

.PARAMETER DryRun
    Show what would be moved without executing (default: true for safety).

.EXAMPLE
    .\file-sort.ps1 -SourcePath "C:\Users\cory\Downloads"
    .\file-sort.ps1 -SourcePath "G:\My Drive" -DryRun $false
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [bool]$DryRun = $true
)

$ErrorActionPreference = 'Stop'

# Domain classification rules
$categories = @{
    'Luxify' = @{
        Extensions = @('.cs', '.ts', '.tsx', '.js', '.json', '.sln', '.csproj', '.md', '.yml', '.yaml', '.ps1', '.sh')
        Keywords = @('cambium', 'luxify', 'workflow', 'api', 'dev', 'code', 'project', 'autocad', 'feature')
        Destination = 'G:\My Drive\Luxify'
    }
    'FeatureMillwork' = @{
        Extensions = @('.dwg', '.dxf', '.pdf', '.xlsx', '.xls')
        Keywords = @('shop', 'drawing', 'cut', 'cabinet', 'millwork', 'rfq', 'submittal', 'unit', 'project')
        Destination = 'C:\Users\cory\OneDrive - Feature Millwork'
    }
    'Personal' = @{
        Extensions = @('.jpg', '.jpeg', '.png', '.heic', '.mp4', '.mov')
        Keywords = @('photo', 'family', 'vacation', 'personal', 'receipt', 'tax', 'finance')
        Destination = 'G:\My Drive\Personal'
    }
    'PhoneInbox' = @{
        Extensions = @()
        Keywords = @()
        Destination = 'G:\My Drive\Phone-Inbox'
    }
}

function Get-FileCategory {
    param([System.IO.FileInfo]$File)

    $ext = $File.Extension.ToLower()
    $name = $File.Name.ToLower()

    # Check by extension first
    foreach ($cat in $categories.Keys) {
        if ($categories[$cat].Extensions -contains $ext) {
            return $cat
        }
    }

    # Check by keywords
    foreach ($cat in $categories.Keys) {
        foreach ($keyword in $categories[$cat].Keywords) {
            if ($name -like "*$keyword*") {
                return $cat
            }
        }
    }

    # Default to PhoneInbox for unknown
    return 'PhoneInbox'
}

Write-Host "=== File Organization ===" -ForegroundColor Cyan
Write-Host "Source: $SourcePath"
Write-Host "Mode: $(if ($DryRun) { 'DRY RUN (no changes)' } else { 'EXECUTE' })"
Write-Host ""

if (-not (Test-Path $SourcePath)) {
    Write-Host "Source path not found: $SourcePath" -ForegroundColor Red
    exit 1
}

# Get files (not directories, not hidden)
$files = Get-ChildItem -Path $SourcePath -File | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) }

if ($files.Count -eq 0) {
    Write-Host "No files found to organize." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($files.Count) files to analyze.`n"

# Categorize files
$proposals = @()
foreach ($file in $files) {
    $category = Get-FileCategory -File $file
    $destination = $categories[$category].Destination
    $destPath = Join-Path $destination $file.Name

    $proposals += [PSCustomObject]@{
        File = $file.Name
        Size = "{0:N2} MB" -f ($file.Length / 1MB)
        Category = $category
        Source = $file.FullName
        Destination = $destPath
    }
}

# Display proposals grouped by category
$grouped = $proposals | Group-Object -Property Category
foreach ($group in $grouped) {
    Write-Host "=== $($group.Name) ($($group.Count) files) ===" -ForegroundColor Cyan
    foreach ($item in $group.Group) {
        Write-Host "  $($item.File) ($($item.Size))"
        Write-Host "    -> $($item.Destination)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Summary for Telegram
Write-Host "--- Telegram Summary ---" -ForegroundColor Yellow
Write-Host "Files to organize: $($files.Count)"
foreach ($group in $grouped) {
    Write-Host "  $($group.Name): $($group.Count)"
}

if ($DryRun) {
    Write-Host "`nDRY RUN - No files moved."
    Write-Host "Run with -DryRun `$false to execute after approval."
} else {
    Write-Host "`nExecuting moves..." -ForegroundColor Yellow
    $moved = 0
    $errors = 0

    foreach ($proposal in $proposals) {
        try {
            $destDir = Split-Path $proposal.Destination
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Move-Item -Path $proposal.Source -Destination $proposal.Destination -Force
            $moved++
        } catch {
            Write-Host "Error moving $($proposal.File): $_" -ForegroundColor Red
            $errors++
        }
    }

    Write-Host "`nComplete: $moved moved, $errors errors" -ForegroundColor $(if ($errors -gt 0) { 'Yellow' } else { 'Green' })
}
