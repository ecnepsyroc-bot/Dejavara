<#
.SYNOPSIS
    Deploy latest Cambium build to production.

.DESCRIPTION
    Full deployment pipeline:
    1. Verify local state (no uncommitted changes)
    2. Build locally (Release)
    3. Push to git
    4. SSH into Cambium
    5. Pull latest code
    6. Build on server
    7. Stop CambiumApi service
    8. Publish and deploy
    9. Start CambiumApi service
    10. Verify health endpoint

.PARAMETER DryRun
    Show what would happen without making changes.

.PARAMETER SkipLocalBuild
    Skip local build step (use if you just built).

.PARAMETER Branch
    Branch to deploy. Default: current branch.

.EXAMPLE
    .\deploy-cambium.ps1
    # Full deployment with confirmation

.EXAMPLE
    .\deploy-cambium.ps1 -DryRun
    # Preview deployment without executing

.EXAMPLE
    .\deploy-cambium.ps1 -Branch main
    # Deploy specific branch

.NOTES
    Prerequisites:
    - SSH access configured via Cloudflare tunnel
    - Git configured and authenticated
    - No uncommitted changes in local repo
#>

param(
    [switch]$DryRun,
    [switch]$SkipLocalBuild,
    [string]$Branch = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$localRepoPath = "C:\Dev\Dejavara\Cambium"
$localProjectPath = Join-Path $localRepoPath "BottaERisposta\src\BottaERisposta.Api"
$remoteRepoPath = "C:\dev\cambium_v1"
$remoteProjectPath = "$remoteRepoPath\BottaERisposta\src\BottaERisposta.Api"
$remotePublishPath = "C:\dev\cambium_v1\BottaERisposta\publish"
$serviceName = "CambiumApi"
$healthUrl = "http://localhost:5001/api/health"
$sshHostname = "ssh.luxifyspecgen.com"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sshScript = Join-Path $scriptDir "cambium-ssh.ps1"

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host "`n[$Step] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Invoke-Remote {
    param([string]$Command)
    & $sshScript -Command $Command
    return $LASTEXITCODE
}

Write-Host "=== Cambium Deployment ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "[DRY RUN MODE - No changes will be made]" -ForegroundColor Magenta
}

# Step 1: Verify local state
Write-Step "1/7" "Checking local state..."
Push-Location $localRepoPath

$status = git status --porcelain
if ($status) {
    Write-Fail "ERROR: Uncommitted changes detected!"
    git status --short
    Pop-Location
    exit 1
}

if (-not $Branch) {
    $Branch = git rev-parse --abbrev-ref HEAD
}
$commitHash = git rev-parse --short HEAD
$commitMsg = git log -1 --format="%s"

Write-Host "Branch: $Branch"
Write-Host "Commit: $commitHash - $commitMsg"
Write-Success "Local state clean."

# Step 2: Build locally
if (-not $SkipLocalBuild) {
    Write-Step "2/7" "Building locally..."
    if (-not $DryRun) {
        Push-Location $localProjectPath
        $buildResult = dotnet build --configuration Release 2>&1
        $buildExitCode = $LASTEXITCODE
        Pop-Location

        if ($buildExitCode -ne 0) {
            Write-Fail "ERROR: Local build failed!"
            Write-Host $buildResult
            Pop-Location
            exit 1
        }
        Write-Success "Local build succeeded."
    } else {
        Write-Host "[DRY RUN] Would run: dotnet build --configuration Release"
    }
} else {
    Write-Host "Skipping local build (--SkipLocalBuild)"
}

# Step 3: Push to git
Write-Step "3/7" "Pushing to remote..."
if (-not $DryRun) {
    git push origin $Branch
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "ERROR: Git push failed!"
        Pop-Location
        exit 1
    }
    Write-Success "Pushed to origin/$Branch"
} else {
    Write-Host "[DRY RUN] Would run: git push origin $Branch"
}

Pop-Location

# Confirmation before remote operations
Write-Host "`n" -NoNewline
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "About to deploy to PRODUCTION:" -ForegroundColor Yellow
Write-Host "  Commit: $commitHash" -ForegroundColor White
Write-Host "  Branch: $Branch" -ForegroundColor White
Write-Host "  Message: $commitMsg" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

if (-not $DryRun) {
    $confirm = Read-Host "Type 'DEPLOY' to proceed"
    if ($confirm -ne 'DEPLOY') {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Step 4: Pull on remote
Write-Step "4/7" "Pulling latest on Cambium..."
if (-not $DryRun) {
    $pullCmd = "cd $remoteRepoPath; git fetch origin; git checkout $Branch; git pull origin $Branch"
    $exitCode = Invoke-Remote $pullCmd
    if ($exitCode -ne 0) {
        Write-Fail "ERROR: Git pull failed on remote!"
        exit 1
    }
    Write-Success "Remote repo updated."
} else {
    Write-Host "[DRY RUN] Would pull $Branch on Cambium"
}

# Step 5: Build on remote
Write-Step "5/7" "Building on Cambium..."
if (-not $DryRun) {
    $buildCmd = "cd $remoteProjectPath; dotnet build --configuration Release"
    $exitCode = Invoke-Remote $buildCmd
    if ($exitCode -ne 0) {
        Write-Fail "ERROR: Remote build failed!"
        exit 1
    }
    Write-Success "Remote build succeeded."
} else {
    Write-Host "[DRY RUN] Would build on Cambium"
}

# Step 6: Stop service, publish, start service
Write-Step "6/7" "Deploying to production..."
if (-not $DryRun) {
    $deployCmd = @"
Write-Output 'Stopping $serviceName...'
Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Output 'Publishing...'
cd $remoteProjectPath
dotnet publish --configuration Release --output $remotePublishPath --no-build

Write-Output 'Starting $serviceName...'
Start-Service $serviceName
Start-Sleep -Seconds 5

`$svc = Get-Service $serviceName
Write-Output "Service status: `$(`$svc.Status)"
"@
    $exitCode = Invoke-Remote $deployCmd
    if ($exitCode -ne 0) {
        Write-Fail "WARNING: Deployment may have issues. Check service status."
    }
} else {
    Write-Host "[DRY RUN] Would stop service, publish, and restart"
}

# Step 7: Health check
Write-Step "7/7" "Verifying health endpoint..."
if (-not $DryRun) {
    Start-Sleep -Seconds 3
    $healthCmd = @"
try {
    `$response = Invoke-WebRequest -Uri '$healthUrl' -UseBasicParsing -TimeoutSec 15
    Write-Output "Health: `$(`$response.StatusCode)"
    Write-Output `$response.Content
} catch {
    Write-Output "Health check failed: `$_"
    exit 1
}
"@
    $exitCode = Invoke-Remote $healthCmd
    if ($exitCode -ne 0) {
        Write-Fail "WARNING: Health check failed! Check logs on Cambium."
    } else {
        Write-Success "Health check passed."
    }
} else {
    Write-Host "[DRY RUN] Would verify health endpoint"
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN COMPLETE" -ForegroundColor Magenta
    Write-Host "Run without -DryRun to execute deployment."
} else {
    Write-Success "DEPLOYMENT COMPLETE"
    Write-Host "Deployed: $commitHash ($Branch)"
    Write-Host "Verify: https://api.luxifyspecgen.com/api/health"
}
Write-Host "========================================" -ForegroundColor Cyan
