@echo off
REM Firebase Cloud Functions Deployment Script (Windows)
REM Run this from the firebase_functions directory

echo.
echo 🚀 Starting Firebase Cloud Functions Deployment...
echo.

REM Step 1: Install dependencies
echo 📦 Installing npm dependencies...
call npm install

if %ERRORLEVEL% NEQ 0 (
  echo ❌ Failed to install dependencies
  exit /b 1
)

echo ✅ Dependencies installed
echo.

REM Step 2: Set Firebase configuration
echo ⚙️  Setting Firebase configuration...

call firebase functions:config:set supabase.url="https://jbhlbukxankrtcwhqoll.supabase.co"
call firebase functions:config:set supabase.key="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpiaGxidWt4YW5rcnRjd2hxb2xsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NDQ3MDE4OCwiZXhwIjoyMDkwMDQ2MTg4fQ.IzVTOEgPim0sNNZMzLtvLjJlf5HHZxVXYg9OCRnuEyI"

echo ✅ Firebase configuration set
echo.

REM Step 3: Deploy functions
echo 🔄 Deploying Cloud Functions...
call firebase deploy --only functions

if %ERRORLEVEL% EQU 0 (
  echo.
  echo ✅ Deployment successful!
  echo.
  echo 📋 Functions deployed:
  echo   - syncUserOnSignUp (triggered on user registration^)
  echo   - updateUserLoginTime (callable from app^)
  echo.
  echo Next steps:
  echo 1. Test by creating a new user in Firebase Auth
  echo 2. Check Supabase users table to verify sync
  echo 3. Refresh admin dashboard to see user count
) else (
  echo ❌ Deployment failed
  exit /b 1
)

pause
