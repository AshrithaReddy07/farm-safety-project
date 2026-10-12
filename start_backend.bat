@echo off
title Farm Safety - Backend
cd /d "%~dp0backend"
echo Starting FastAPI Backend on http://localhost:8000...
echo API Docs available at http://localhost:8000/docs
"..\python_embed\python.exe" -m uvicorn main:app --app-dir . --reload --port 8000
pause
