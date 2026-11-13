@echo off
echo Starting Gilda Medical...

:: Start Flask backend
start "Backend" cmd /k "cd /d D:\Pharma_ai\GildaMedical && venv\Scripts\activate && python app.py"

:: Wait for backend to start
timeout /t 3 /nobreak >nul

:: Serve Flutter web
start "Frontend" cmd /k "cd /d D:\Pharma_ai\gilda_medical_app\build\web && python -m http.server 3000"

:: Open browser
timeout /t 2 /nobreak >nul
start http://localhost:3000

echo Done! Backend on :5001, Frontend on :3000
