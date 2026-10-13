# Field Watch - Instant Railway Cloud Deployment (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "  Field Watch - Instant Railway Cloud Deployment" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $PSScriptRoot

Write-Host "[1/3] Checking Railway CLI login status..." -ForegroundColor Yellow
$whoami = & npx -y @railway/cli whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "You are not logged in to Railway yet." -ForegroundColor Yellow
    Write-Host "A browser tab will open to log in or create your Railway account..." -ForegroundColor Yellow
    & npx -y @railway/cli login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Login failed or was cancelled."
        exit 1
    }
} else {
    Write-Host "Logged in to Railway." -ForegroundColor Green
}

Write-Host ""
Write-Host "[2/3] Uploading and deploying project to Railway..." -ForegroundColor Yellow
& npx -y @railway/cli up -y

if ($LASTEXITCODE -ne 0) {
    Write-Error "Deployment failed."
    exit 1
}

Write-Host ""
Write-Host "[3/3] Generating public domain (if not already set)..." -ForegroundColor Yellow
& npx -y @railway/cli domain

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Farm Safety project deployed to Railway!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
