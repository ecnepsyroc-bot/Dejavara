# Add 04-drawings/as-built to all existing projects
$ProjectsRoot = "C:\Projects"
$created = 0
$exists = 0

Get-ChildItem -Path $ProjectsRoot -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "_cambium")
} | ForEach-Object {
    $asBuiltPath = Join-Path $_.FullName "04-drawings\as-built"
    if (-not (Test-Path $asBuiltPath)) {
        New-Item -ItemType Directory -Force -Path $asBuiltPath | Out-Null
        Write-Host "Created: $($_.Name)/04-drawings/as-built" -ForegroundColor Green
        $script:created++
    } else {
        Write-Host "Exists: $($_.Name)/04-drawings/as-built" -ForegroundColor DarkGray
        $script:exists++
    }
}

Write-Host ""
Write-Host "Created: $created folders" -ForegroundColor Green
Write-Host "Already existed: $exists folders" -ForegroundColor DarkGray
