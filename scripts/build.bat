@echo off
REM SpeakEng — Build release APK (Windows)
REM Usage: scripts\build.bat

set "ENV_FILE=%~dp0..\.env"
if not exist "%ENV_FILE%" (echo ❌ .env not found. Run scripts\setup.bat first. & exit /b 1)

for /f "usebackq tokens=1,* delims==" %%a in ("%ENV_FILE%") do set "%%a=%%b"

echo 🔨 Building release APK...
cd /d "%~dp0.."

flutter build apk --release --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

echo.
echo ✅ APK built: build\app\outputs\flutter-apk\app-release.apk
echo    Install: adb install build\app\outputs\flutter-apk\app-release.apk
