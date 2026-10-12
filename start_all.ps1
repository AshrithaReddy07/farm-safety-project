# Field Watch - Local Deployment Runner
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   Field Watch - Farm Safety System Local Deployment    " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Start Backend
Write-Host "[1/2] Starting Backend API..." -ForegroundColor Yellow
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "cd '$rootDir\backend'; & '..\python_embed\python.exe' -m uvicorn main:app --app-dir . --reload --port 8000"

Start-Sleep -Seconds 2

# 2. Start Frontend
Write-Host "[2/2] Starting Frontend Dashboard..." -ForegroundColor Yellow
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "cd '$rootDir\frontend'; npm run dev"

Write-Host "`nServices started!" -ForegroundColor Green
Write-Host " - Backend API:  http://localhost:8000" -ForegroundColor Green
Write-Host " - Swagger Docs: http://localhost:8000/docs" -ForegroundColor Green
Write-Host " - Frontend:     http://localhost:5173" -ForegroundColor Green
