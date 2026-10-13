# Field Watch - GitHub Push Helper (PowerShell)
param(
    [string]$RepoUrl
)

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  Field Watch - GitHub Deployment Helper" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $PSScriptRoot

# Check git
try {
    & git status | Out-Null
} catch {
    Write-Error "Git is not installed or not in PATH."
    exit 1
}

$origin = & git remote get-url origin 2>$null
if (-not $origin) {
    if (-not $RepoUrl) {
        Write-Host "Remote 'origin' is not configured yet." -ForegroundColor Yellow
        Write-Host "Create a new repo on GitHub (https://github.com/new), then enter the URL below:" -ForegroundColor Yellow
        $RepoUrl = Read-Host "Enter your GitHub Repository URL (e.g. https://github.com/user/farm-safety.git)"
    }
    if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
        Write-Error "No repository URL provided. Aborting."
        exit 1
    }
    & git remote add origin $RepoUrl.Trim()
    Write-Host "[OK] Added remote origin: $RepoUrl" -ForegroundColor Green
} else {
    Write-Host "Current remote origin: $origin" -ForegroundColor Green
    if ($RepoUrl) {
        & git remote set-url origin $RepoUrl.Trim()
        Write-Host "[OK] Updated remote origin: $RepoUrl" -ForegroundColor Green
    }
}

Write-Host "`nStaging and committing latest changes..." -ForegroundColor Yellow
& git add -A
& git commit -m "Configure instant Railway cloud and GitHub deployment" 2>$null

Write-Host "`nEnsuring branch is 'main'..." -ForegroundColor Yellow
& git branch -M main

Write-Host "`nPushing code to GitHub..." -ForegroundColor Yellow
& git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] Code successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "You can now connect this repo on Railway (https://railway.app)." -ForegroundColor Green
    Write-Host "=======================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[ERROR] Git push failed. Verify your GitHub permissions / credentials." -ForegroundColor Red
}
