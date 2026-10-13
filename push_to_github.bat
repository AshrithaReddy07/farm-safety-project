@echo off
setlocal enabledelayedexpansion
title Field Watch - Push to GitHub

echo =======================================================
echo   Field Watch - GitHub Deployment Helper
echo =======================================================
echo.

cd /d "%~dp0"

git status >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git is not initialized or not found in PATH.
    pause
    exit /b 1
)

:: Check if remote 'origin' exists
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    echo Remote 'origin' is not configured yet.
    echo Please create a new repository on GitHub (https://github.com/new).
    echo.
    set /p REPO_URL="Enter your GitHub Repository URL (e.g., https://github.com/username/farm-safety.git): "
    if "!REPO_URL!"=="" (
        echo [ERROR] No URL provided. Aborting.
        pause
        exit /b 1
    )
    git remote add origin !REPO_URL!
    echo [OK] Added remote origin: !REPO_URL!
) else (
    for /f "tokens=*" %%i in ('git remote get-url origin') do set CURRENT_URL=%%i
    echo Current remote origin: !CURRENT_URL!
    echo.
    set /p CONFIRM="Press ENTER to push to this remote, or type a new URL to replace it: "
    if not "!CONFIRM!"=="" (
        git remote set-url origin !CONFIRM!
        echo [OK] Updated remote origin to: !CONFIRM!
    )
)

echo.
echo Staging and committing changes...
git add .
git commit -m "Deploy update for Railway and GitHub" >nul 2>&1

echo.
echo Ensuring branch is 'main'...
git branch -M main

echo.
echo Pushing to GitHub...
git push -u origin main

if errorlevel 1 (
    echo.
    echo [ERROR] Push failed. Make sure you are authenticated with GitHub and have access to the repository.
) else (
    echo.
    echo =======================================================
    echo [SUCCESS] Code successfully pushed to GitHub!
    echo You can now connect this repo on Railway (https://railway.app).
    echo =======================================================
)

echo.
pause
