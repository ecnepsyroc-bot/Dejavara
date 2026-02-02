<#
.SYNOPSIS
    Health check for Cambium services and infrastructure.

.DESCRIPTION
    Checks database connectivity, API status, and build health.

.PARAMETER Check
    What to check: 'All', 'Database', 'Api', 'Build', 'Git'.

.EXAMPLE
    .\health-check.ps1 -Check All
    .\health-check.ps1 -Check Database
#>

param(
    [ValidateSet('All', 'Database', 'Api', 'Build', 'Git')]
    [string]$Check = 'All'
)

$ErrorActionPreference = 'SilentlyContinue'
$results = @()

function Test-Database {
    Write-Host "`n=== Database Check ===" -ForegroundColor Cyan

    # Check if PostgreSQL is running
    $pgService = Get-Service -Name 'postgresql*' -ErrorAction SilentlyContinue
    if ($pgService) {
        $status = $pgService.Status
        Write-Host "PostgreSQL service: $status"
        if ($status -eq 'Running') {
            # Try to connect using psql
            $env:PGPASSWORD = $env:CAMBIUM_DB_PASSWORD
            $connTest = & psql -h localhost -U postgres -d shop_chat -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Database 'shop_chat': Connected" -ForegroundColor Green
                Write-Host "Tables: $($connTest | Select-String -Pattern '\d+' | ForEach-Object { $_.Matches.Value })"
                return @{Status='Healthy'; Details='Connected to shop_chat'}
            } else {
                Write-Host "Database connection failed" -ForegroundColor Red
                return @{Status='Error'; Details='Cannot connect to shop_chat'}
            }
        }
    } else {
        Write-Host "PostgreSQL service not found" -ForegroundColor Yellow
        return @{Status='Warning'; Details='PostgreSQL service not found'}
    }
}

function Test-Api {
    Write-Host "`n=== API Check ===" -ForegroundColor Cyan

    # Check if BottaERisposta process is running
    $apiProcess = Get-Process -Name 'Cambium.Api' -ErrorAction SilentlyContinue
    if (-not $apiProcess) {
        $apiProcess = Get-Process -Name 'dotnet' -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowTitle -like '*Cambium*' -or $_.Path -like '*Cambium*' }
    }

    if ($apiProcess) {
        Write-Host "API process: Running (PID: $($apiProcess.Id))" -ForegroundColor Green
    } else {
        Write-Host "API process: Not detected" -ForegroundColor Yellow
    }

    # Try health endpoint
    $healthUrl = 'http://localhost:5000/health'
    try {
        $response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 5 -ErrorAction Stop
        Write-Host "Health endpoint: OK" -ForegroundColor Green
        return @{Status='Healthy'; Details='API responding'}
    } catch {
        # Try alternate ports
        foreach ($port in @(5001, 5236, 7236)) {
            try {
                $response = Invoke-RestMethod -Uri "http://localhost:$port/health" -TimeoutSec 2 -ErrorAction Stop
                Write-Host "Health endpoint (port $port): OK" -ForegroundColor Green
                return @{Status='Healthy'; Details="API responding on port $port"}
            } catch {
                continue
            }
        }
        Write-Host "Health endpoint: Not responding" -ForegroundColor Yellow
        return @{Status='Warning'; Details='No health endpoint response'}
    }
}

function Test-Build {
    Write-Host "`n=== Build Check ===" -ForegroundColor Cyan

    $solutionPath = 'C:\Dev\Dejavara\Cambium\Cambium\Cambium.sln'
    if (-not (Test-Path $solutionPath)) {
        $solutionPath = 'C:\Dev\cambium_V1\Cambium\Cambium.sln'
    }

    if (Test-Path $solutionPath) {
        Write-Host "Solution: $solutionPath"
        Write-Host "Running: dotnet build --no-restore..." -ForegroundColor Yellow

        Push-Location (Split-Path $solutionPath)
        $buildOutput = & dotnet build Cambium.sln --no-restore 2>&1
        $exitCode = $LASTEXITCODE
        Pop-Location

        if ($exitCode -eq 0) {
            Write-Host "Build: Success" -ForegroundColor Green
            return @{Status='Healthy'; Details='Build succeeded'}
        } else {
            $errors = $buildOutput | Select-String -Pattern 'error CS\d+' | Select-Object -First 5
            Write-Host "Build: Failed" -ForegroundColor Red
            foreach ($err in $errors) {
                Write-Host "  $err" -ForegroundColor Red
            }
            return @{Status='Error'; Details="Build failed with $($errors.Count)+ errors"}
        }
    } else {
        Write-Host "Solution not found" -ForegroundColor Red
        return @{Status='Error'; Details='Cambium.sln not found'}
    }
}

function Test-Git {
    Write-Host "`n=== Git Status ===" -ForegroundColor Cyan

    $repoPath = 'C:\Dev\Dejavara\Cambium'
    if (-not (Test-Path "$repoPath\.git")) {
        $repoPath = 'C:\Dev\cambium_V1'
    }

    Push-Location $repoPath

    $branch = git rev-parse --abbrev-ref HEAD
    $lastCommit = git log -1 --oneline
    $status = git status --porcelain
    $uncommitted = if ($status) { ($status | Measure-Object).Count } else { 0 }

    Write-Host "Branch: $branch"
    Write-Host "Last commit: $lastCommit"
    Write-Host "Uncommitted files: $uncommitted"

    Pop-Location

    return @{
        Status = if ($uncommitted -gt 0) { 'Warning' } else { 'Healthy' }
        Details = "Branch: $branch, Uncommitted: $uncommitted"
    }
}

# Run checks
Write-Host "=== Cambium Health Check ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

switch ($Check) {
    'All' {
        $results += @{Name='Git'; Result=Test-Git}
        $results += @{Name='Database'; Result=Test-Database}
        $results += @{Name='Api'; Result=Test-Api}
        # Skip build by default in 'All' - it's slow
    }
    'Database' { $results += @{Name='Database'; Result=Test-Database} }
    'Api' { $results += @{Name='Api'; Result=Test-Api} }
    'Build' { $results += @{Name='Build'; Result=Test-Build} }
    'Git' { $results += @{Name='Git'; Result=Test-Git} }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
foreach ($r in $results) {
    $color = switch ($r.Result.Status) {
        'Healthy' { 'Green' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        default { 'White' }
    }
    Write-Host "$($r.Name): $($r.Result.Status) - $($r.Result.Details)" -ForegroundColor $color
}
