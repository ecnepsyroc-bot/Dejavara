# Migrate Chambers from V5.0 to V5.1
$project = "C:\Projects\0001-chambers"

Write-Host "Migrating Chambers to V5.1..." -ForegroundColor Cyan

# Step 1: Merge 02-received into 00-contract (V5.1 has received folders in 00-contract)
if (Test-Path "$project\02-received") {
    $received = Get-ChildItem "$project\02-received" -Directory
    foreach ($dir in $received) {
        $target = "$project\00-contract\$($dir.Name)"
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Force -Path $target | Out-Null
        }
        # Move contents
        Get-ChildItem $dir.FullName -Recurse | Move-Item -Destination $target -ErrorAction SilentlyContinue
    }
    Remove-Item "$project\02-received" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Merged 02-received -> 00-contract" -ForegroundColor Green
}

# Step 2: Merge 12-correspondence into 01-admin
if (Test-Path "$project\12-correspondence") {
    # email -> 01-admin/email
    if (Test-Path "$project\12-correspondence\email") {
        New-Item -ItemType Directory -Force -Path "$project\01-admin\email" | Out-Null
        Get-ChildItem "$project\12-correspondence\email" | Move-Item -Destination "$project\01-admin\email" -ErrorAction SilentlyContinue
    }
    # install -> 01-admin/install
    if (Test-Path "$project\12-correspondence\install") {
        New-Item -ItemType Directory -Force -Path "$project\01-admin\install" | Out-Null
        Get-ChildItem "$project\12-correspondence\install" | Move-Item -Destination "$project\01-admin\install" -ErrorAction SilentlyContinue
    }
    # shipping -> 01-admin/shipping
    if (Test-Path "$project\12-correspondence\shipping") {
        New-Item -ItemType Directory -Force -Path "$project\01-admin\shipping" | Out-Null
        Get-ChildItem "$project\12-correspondence\shipping" | Move-Item -Destination "$project\01-admin\shipping" -ErrorAction SilentlyContinue
    }
    Remove-Item "$project\12-correspondence" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Merged 12-correspondence -> 01-admin" -ForegroundColor Green
}

# Step 3: Renumber folders (03-financial -> 02-financial, etc.)
$renames = @{
    "03-financial" = "02-financial"
    "04-cad" = "03-cad"
    "05-drawings" = "04-drawings"
    "06-materials" = "05-materials"
    "07-samples" = "06-samples"
    "08-production" = "07-production"
    "09-buyout" = "08-buyout"
    "10-coordination" = "09-coordination"
    "11-site" = "10-site"
    "13-awmac" = "11-awmac"
}

foreach ($old in $renames.Keys) {
    $oldPath = "$project\$old"
    $newPath = "$project\$($renames[$old])"
    if ((Test-Path $oldPath) -and (-not (Test-Path $newPath))) {
        Rename-Item $oldPath $renames[$old]
        Write-Host "  Renamed $old -> $($renames[$old])" -ForegroundColor Green
    }
}

Write-Host "" -ForegroundColor Green
Write-Host "Migration complete!" -ForegroundColor Green
Write-Host "Verify structure:" -ForegroundColor Cyan
Get-ChildItem $project -Directory | Select-Object Name | Sort-Object Name
