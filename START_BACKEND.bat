@echo off
REM Quick start script to fix reporter names showing as Anonymous

echo.
echo ====================================
echo  Reporter Name Fix - Quick Start
echo ====================================
echo.

echo Step 1: Installing backend dependencies...
cd backend
call npm install @supabase/supabase-js
if errorlevel 1 (
    echo Error installing dependencies
    exit /b 1
)

echo.
echo Step 2: Starting backend server...
echo.
echo Backend server starting on http://localhost:5000
echo.
echo Keep this terminal open and open a new terminal for next steps.
echo.
call npm start
