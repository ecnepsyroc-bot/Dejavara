<#
.SYNOPSIS
    Safe git workflow for remote code fixes via Telegram.

.DESCRIPTION
    Creates a rollback point, switches to a feature branch, and prepares for safe code changes.
    Never commits to main, always creates a branch first.

.PARAMETER BranchName
    Name for the new branch (without prefix). Will be prefixed with fix/ or feat/.

.PARAMETER Type
    Branch type: 'fix' or 'feat'. Default is 'fix'.

.PARAMETER RepoPath
    Path to the repository. Default is C:\Dev\Dejavara\Cambium.

.EXAMPLE
    .\git-safe-fix.ps1 -BranchName "dash-in-project-number" -Type fix
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$BranchName,

    [ValidateSet('fix', 'feat', 'refactor', 'chore')]
    [string]$Type = 'fix',

    [string]$RepoPath = 'C:\Dev\Dejavara\Cambium'
)

$ErrorActionPreference = 'Stop'

Push-Location $RepoPath
try {
    Write-Host "=== Git Safe Fix Workflow ===" -ForegroundColor Cyan

    # Check current branch
    $currentBranch = git rev-parse --abbrev-ref HEAD
    Write-Host "Current branch: $currentBranch"

    # Check for uncommitted changes
    $status = git status --porcelain
    if ($status) {
        Write-Host "`nUncommitted changes detected. Stashing..." -ForegroundColor Yellow
        git stash push -m "Auto-stash before $Type/$BranchName"
        Write-Host "Changes stashed successfully." -ForegroundColor Green
    } else {
        Write-Host "Working directory clean." -ForegroundColor Green
    }

    # Create and switch to feature branch
    $fullBranchName = "$Type/$BranchName"
    Write-Host "`nCreating branch: $fullBranchName" -ForegroundColor Cyan

    # Check if branch exists
    $branchExists = git branch --list $fullBranchName
    if ($branchExists) {
        Write-Host "Branch already exists. Switching to it..." -ForegroundColor Yellow
        git checkout $fullBranchName
    } else {
        git checkout -b $fullBranchName
        Write-Host "Branch created and checked out." -ForegroundColor Green
    }

    # Report status
    Write-Host "`n=== Ready for Changes ===" -ForegroundColor Green
    Write-Host "Branch: $fullBranchName"
    Write-Host "Previous branch: $currentBranch"
    if ($status) {
        Write-Host "Stashed changes: Yes (run 'git stash pop' to restore)"
    }

    # Output for Telegram
    Write-Host "`n--- Telegram Summary ---"
    Write-Host "Ready on branch: $fullBranchName"
    Write-Host "Make changes, then show diff for approval."

} finally {
    Pop-Location
}
