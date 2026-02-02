<#
.SYNOPSIS
    Pull a snapshot of Cambium's production database for local debugging.

.DESCRIPTION
    Copies production database to local dev environment.
    WARNING: This copies REAL DATA to your dev machine. Use responsibly.

    Safety: Always requires -Confirm flag.

.PARAMETER Confirm
    Required flag to acknowledge you understand this copies production data.

.PARAMETER BackupOnly
    Only create the dump file, don't restore to local database.

.PARAMETER DumpFile
    Custom path for the dump file. Default: backups/prod-snapshot-YYYY-MM-DD.sql

.EXAMPLE
    .\snapshot-prod-db.ps1
    # Shows warning and exits (requires -Confirm)

.EXAMPLE
    .\snapshot-prod-db.ps1 -Confirm
    # Dumps production database and restores to local dev DB

.EXAMPLE
    .\snapshot-prod-db.ps1 -Confirm -BackupOnly
    # Only creates dump file, doesn't restore

.NOTES
    Prerequisites:
    - SSH access to Cambium via tunnel
    - pg_dump available on Cambium
    - Local dev database running (docker-compose.dev.yml)
    - psql available locally (in Docker container)
#>

param(
    [switch]$Confirm,
    [switch]$BackupOnly,
    [string]$DumpFile = ""
)

$ErrorActionPreference = "Stop"

# Configuration
$localBackupDir = "C:\Dev\Dejavara\Cambium\backups"
$prodDbName = "shop_chat"
$prodDbUser = "postgres"
$devDbName = "shop_chat_dev"
$devDbUser = "cambium_dev"
$devDbPassword = "dev_password_change_me"
$devDbPort = 5433

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sshScript = Join-Path $scriptDir "cambium-ssh.ps1"

Write-Host "=== Production Database Snapshot ===" -ForegroundColor Cyan

if (-not $Confirm) {
    Write-Host "`nWARNING: This will copy PRODUCTION DATA to your local machine." -ForegroundColor Yellow
    Write-Host "The production database contains real customer and business data." -ForegroundColor Yellow
    Write-Host "`nRun with -Confirm to proceed." -ForegroundColor White
    Write-Host "Example: .\snapshot-prod-db.ps1 -Confirm" -ForegroundColor DarkGray
    exit 0
}

# Set up dump file path
if (-not $DumpFile) {
    if (-not (Test-Path $localBackupDir)) {
        New-Item -ItemType Directory -Path $localBackupDir -Force | Out-Null
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
    $DumpFile = Join-Path $localBackupDir "prod-snapshot-$timestamp.sql"
}

Write-Host "Dump file: $DumpFile" -ForegroundColor White

# Step 1: Dump production database via SSH
Write-Host "`n[1/3] Dumping production database..." -ForegroundColor Yellow
Write-Host "This may take a few minutes depending on database size." -ForegroundColor DarkGray

# Create dump command - outputs to stdout so we can capture it
$dumpCmd = "pg_dump -U $prodDbUser -d $prodDbName --no-owner --no-privileges --clean --if-exists"

Write-Host "Running: $dumpCmd" -ForegroundColor DarkGray

# Use cloudflared directly to capture output
$cloudflaredArgs = @(
    "access", "ssh",
    "--hostname", "ssh.luxifyspecgen.com",
    "--", $dumpCmd
)

try {
    & cloudflared $cloudflaredArgs > $DumpFile 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Host "ERROR: pg_dump failed with exit code $exitCode" -ForegroundColor Red
        if (Test-Path $DumpFile) {
            $content = Get-Content $DumpFile -Head 20
            Write-Host "Output:" -ForegroundColor Yellow
            $content | ForEach-Object { Write-Host $_ }
        }
        exit 1
    }

    $fileSize = (Get-Item $DumpFile).Length / 1MB
    Write-Host "Dump complete: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to dump database: $_" -ForegroundColor Red
    exit 1
}

if ($BackupOnly) {
    Write-Host "`nBackup complete (restore skipped with -BackupOnly)." -ForegroundColor Green
    Write-Host "Dump file: $DumpFile" -ForegroundColor White
    exit 0
}

# Step 2: Check local dev database is running
Write-Host "`n[2/3] Checking local dev database..." -ForegroundColor Yellow

$container = docker ps --filter "name=cambium-dev-db" --format "{{.Names}}" 2>$null
if (-not $container) {
    Write-Host "ERROR: cambium-dev-db container not running." -ForegroundColor Red
    Write-Host "Start it with: docker compose -f docker-compose.dev.yml up -d" -ForegroundColor Yellow
    exit 1
}
Write-Host "Dev database running: $container" -ForegroundColor Green

# Step 3: Restore to local dev database
Write-Host "`n[3/3] Restoring to local dev database..." -ForegroundColor Yellow
Write-Host "Target: $devDbName on localhost:$devDbPort" -ForegroundColor White

# Copy dump file into container and restore
$containerPath = "/tmp/prod-snapshot.sql"
docker cp $DumpFile "cambium-dev-db:$containerPath"

$restoreResult = docker exec cambium-dev-db psql -U $devDbUser -d $devDbName -f $containerPath 2>&1
$restoreExitCode = $LASTEXITCODE

# Clean up temp file in container
docker exec cambium-dev-db rm -f $containerPath 2>$null

if ($restoreExitCode -ne 0) {
    Write-Host "WARNING: Restore completed with warnings/errors." -ForegroundColor Yellow
    # Show last few lines of output (may include harmless notices)
    $restoreResult | Select-Object -Last 10 | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Restore complete." -ForegroundColor Green
}

# Verify
Write-Host "`nVerifying restore..." -ForegroundColor Yellow
$tableCount = docker exec cambium-dev-db psql -U $devDbUser -d $devDbName -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
Write-Host "Tables in $devDbName: $($tableCount.Trim())" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SNAPSHOT COMPLETE" -ForegroundColor Green
Write-Host "Production data now in: $devDbName (localhost:$devDbPort)" -ForegroundColor White
Write-Host "Dump file saved: $DumpFile" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
