@echo off
setlocal enabledelayedexpansion
title Field Watch - Instant Railway Deployment

echo =======================================================
echo   Field Watch - Instant Railway Cloud Deployment
echo =======================================================
echo.

cd /d "%~dp0"

echo [1/3] Checking Railway CLI login status...
call npx -y @railway/cli whoami >nul 2>&1
if errorlevel 1 (
    echo.
    echo You are not logged in to Railway yet.
    echo A browser tab will open to log in or create a free Railway account.
    echo Press any key to open Railway login...
    pause >nul
    call npx -y @railway/cli login
    if errorlevel 1 (
        echo [ERROR] Login failed or was cancelled.
        pause
        exit /b 1
    )
)

echo.
echo [2/3] Uploading and deploying project to Railway...
call npx -y @railway/cli up -y

if errorlevel 1 (
    echo.
    echo [ERROR] Deployment failed. Check the error messages above.
    pause
    exit /b 1
)

echo.
echo [3/3] Generating public domain (if not already set)...
call npx -y @railway/cli domain

echo.
echo =======================================================
echo [SUCCESS] Your Farm Safety project is deployed to Railway!
echo View logs and status anytime: npx @railway/cli status
echo =======================================================
echo.
pause
