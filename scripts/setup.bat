@echo off
REM SpeakEng — One-command setup script (Windows)
REM Usage: scripts\setup.bat

echo 🚀 SpeakEng Setup
echo ==================

where supabase >nul 2>&1 || (echo ❌ supabase CLI not found. Install: scoop install supabase & exit /b 1)
where flutter >nul 2>&1 || (echo ❌ flutter not found. Install: https://flutter.dev/docs/get-started/install & exit /b 1)

set "ENV_FILE=%~dp0..\.env"

if not exist "%ENV_FILE%" (
    echo.
    echo 📝 Create .env file with your credentials:
    echo.
    (
        echo SUPABASE_PROJECT_REF=your-project-ref
        echo SUPABASE_URL=https://xxxxx.supabase.co
        echo SUPABASE_ANON_KEY=your-anon-key
        echo AZURE_SPEECH_ENDPOINT=https://eastus.api.cognitive.microsoft.com
        echo AZURE_SPEECH_KEY=your-azure-key
        echo OPENAI_API_KEY=sk-your-openai-key
        echo ELEVENLABS_API_KEY=your-elevenlabs-key
    ) > "%ENV_FILE%"
    echo Created .env template at %ENV_FILE%
    echo Fill in your credentials, then run this script again.
    exit /b 0
)

REM Load .env
for /f "usebackq tokens=1,* delims==" %%a in ("%ENV_FILE%") do set "%%a=%%b"

REM Validate
if "%SUPABASE_PROJECT_REF%"=="your-project-ref" (echo ❌ SUPABASE_PROJECT_REF not set in .env & exit /b 1)
if "%SUPABASE_URL%"=="https://xxxxx.supabase.co" (echo ❌ SUPABASE_URL not set in .env & exit /b 1)

echo ✅ All credentials loaded

REM Run all supabase commands from project root
cd /d "%~dp0.."

REM Step 1: Link Supabase
echo.
echo 📦 Step 1/4: Linking Supabase project...
supabase link --project-ref %SUPABASE_PROJECT_REF% 2>nul

REM Step 2: Push migrations
echo 📦 Step 2/4: Running database migrations...
supabase db push

REM Step 3: Set secrets & deploy
echo 📦 Step 3/4: Deploying Edge Functions...
supabase secrets set AZURE_SPEECH_ENDPOINT="%AZURE_SPEECH_ENDPOINT%" AZURE_SPEECH_KEY="%AZURE_SPEECH_KEY%" OPENAI_API_KEY="%OPENAI_API_KEY%" ELEVENLABS_API_KEY="%ELEVENLABS_API_KEY%"
supabase functions deploy pronounce
supabase functions deploy transcribe
supabase functions deploy chat
supabase functions deploy tts

REM Step 4: Flutter deps
echo 📦 Step 4/4: Getting Flutter dependencies...
flutter pub get

echo.
echo ✅ Setup complete!
echo.
echo Next steps:
echo   1. Generate voices:  python scripts\generate_voices.py
echo   2. Run app:          scripts\run.bat
echo   3. Build APK:        scripts\build.bat
