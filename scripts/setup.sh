#!/bin/bash
# SpeakEng — One-command setup script
# Usage: ./scripts/setup.sh
set -e

echo "🚀 SpeakEng Setup"
echo "=================="

# Check prerequisites
command -v supabase >/dev/null 2>&1 || { echo "❌ supabase CLI not found. Install: brew install supabase/tap/supabase"; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "❌ flutter not found. Install: https://flutter.dev/docs/get-started/install"; exit 1; }

# Load .env if exists
ENV_FILE="$(dirname "$0")/../.env"
if [ ! -f "$ENV_FILE" ]; then
  echo ""
  echo "📝 Create .env file with your credentials:"
  echo ""
  cat > "$ENV_FILE" << 'TEMPLATE'
# Required — app won't start without these
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Optional — leave blank for offline-only mode
# Azure: needed for pronunciation assessment (phoneme-level feedback)
AZURE_SPEECH_ENDPOINT=https://eastus.api.cognitive.microsoft.com
AZURE_SPEECH_KEY=
# OpenAI: needed for conversation (GPT + Whisper + TTS online)
OPENAI_API_KEY=
# ElevenLabs: needed for pre-generating high-quality shadowing audio
ELEVENLABS_API_KEY=
TEMPLATE
  echo "Created .env template at $ENV_FILE"
  echo "Fill in your credentials, then run this script again."
  echo "(Azure/OpenAI/ElevenLabs keys are optional for offline-only mode)"
  exit 0
fi

source "$ENV_FILE"

# Validate required vars only
for var in SUPABASE_PROJECT_REF SUPABASE_URL SUPABASE_ANON_KEY; do
  if [ -z "${!var}" ] || [[ "${!var}" == your-* ]]; then
    echo "❌ $var not set in .env"; exit 1
  fi
done

echo "✅ Required credentials loaded"
[ -n "$OPENAI_API_KEY" ] && echo "   ✓ OpenAI (conversation)" || echo "   ⚠ OpenAI not set (conversation disabled)"
[ -n "$AZURE_SPEECH_KEY" ] && echo "   ✓ Azure Speech (pronunciation)" || echo "   ⚠ Azure not set (pronunciation disabled)"
[ -n "$ELEVENLABS_API_KEY" ] && echo "   ✓ ElevenLabs (voice generation)" || echo "   ⚠ ElevenLabs not set (use offline TTS)"

# All supabase commands run from project root
cd "$(dirname "$0")/.."

# Step 1: Link Supabase
echo ""
echo "📦 Step 1/4: Linking Supabase project..."
supabase link --project-ref "$SUPABASE_PROJECT_REF" 2>/dev/null || true

# Step 2: Push migrations
echo "📦 Step 2/4: Running database migrations..."
supabase db push

# Step 3: Set secrets & deploy functions
echo "📦 Step 3/4: Deploying Edge Functions..."
SECRETS=""
[ -n "$AZURE_SPEECH_ENDPOINT" ] && SECRETS="$SECRETS AZURE_SPEECH_ENDPOINT=$AZURE_SPEECH_ENDPOINT"
[ -n "$AZURE_SPEECH_KEY" ] && SECRETS="$SECRETS AZURE_SPEECH_KEY=$AZURE_SPEECH_KEY"
[ -n "$OPENAI_API_KEY" ] && SECRETS="$SECRETS OPENAI_API_KEY=$OPENAI_API_KEY"
[ -n "$ELEVENLABS_API_KEY" ] && SECRETS="$SECRETS ELEVENLABS_API_KEY=$ELEVENLABS_API_KEY"

if [ -n "$SECRETS" ]; then
  supabase secrets set $SECRETS
fi

[ -n "$AZURE_SPEECH_KEY" ] && supabase functions deploy pronounce && echo "  ✓ pronounce" || echo "  ⚠ skipping pronounce (no Azure key)"
[ -n "$OPENAI_API_KEY" ] && supabase functions deploy transcribe && supabase functions deploy chat && echo "  ✓ transcribe, chat" || echo "  ⚠ skipping transcribe/chat (no OpenAI key)"
[ -n "$OPENAI_API_KEY" ] || [ -n "$ELEVENLABS_API_KEY" ] && supabase functions deploy tts && echo "  ✓ tts" || echo "  ⚠ skipping tts (no keys)"

# Step 4: Flutter deps
echo "📦 Step 4/4: Getting Flutter dependencies..."
flutter pub get

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Generate voices:  ELEVENLABS_API_KEY=$ELEVENLABS_API_KEY python3 scripts/generate_voices.py"
echo "  2. Run app:          flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
echo "  3. Build APK:        ./scripts/build.sh"
