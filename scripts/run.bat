@echo off
REM SpeakEng - Run in debug mode (Windows)
REM Usage: scripts\run.bat

set "ENV_FILE=%~dp0..\.env"
if not exist "%ENV_FILE%" (echo ❌ .env not found. Run scripts\setup.bat first. & exit /b 1)

for /f "usebackq tokens=1,* delims==" %%a in ("%ENV_FILE%") do set "%%a=%%b"

cd /d "%~dp0.."
flutter run --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
