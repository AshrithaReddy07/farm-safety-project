@echo off
title Field Watch - Farm Safety System Launcher
echo =========================================================
echo   Field Watch - Farm Safety System Local Deployment
echo =========================================================

cd /d "%~dp0"

echo [1/2] Launching Backend API on http://localhost:8000 ...
start "Farm Safety - Backend" cmd /k "cd /d "%~dp0backend" && "..\python_embed\python.exe" -m uvicorn main:app --app-dir . --reload --port 8000"

timeout /t 2 /nobreak >nul

echo [2/2] Launching Frontend Dashboard on http://localhost:5173 ...
start "Farm Safety - Frontend" cmd /k "cd /d "%~dp0frontend" && npm run dev"

echo.
echo =========================================================
echo  Deployment complete!
echo  - Backend API:  http://localhost:8000
echo  - Swagger Docs: http://localhost:8000/docs
echo  - Frontend App: http://localhost:5173
echo =========================================================
echo.
