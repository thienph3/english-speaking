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
SUPABASE_PROJECT_REF=your-project-ref
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your-anon-key
AZURE_SPEECH_ENDPOINT=https://eastus.api.cognitive.microsoft.com
AZURE_SPEECH_KEY=your-azure-key
OPENAI_API_KEY=sk-your-openai-key
ELEVENLABS_API_KEY=your-elevenlabs-key
TEMPLATE
  echo "Created .env template at $ENV_FILE"
  echo "Fill in your credentials, then run this script again."
  exit 0
fi

source "$ENV_FILE"

# Validate required vars
for var in SUPABASE_PROJECT_REF SUPABASE_URL SUPABASE_ANON_KEY AZURE_SPEECH_ENDPOINT AZURE_SPEECH_KEY OPENAI_API_KEY ELEVENLABS_API_KEY; do
  if [ -z "${!var}" ] || [[ "${!var}" == your-* ]]; then
    echo "❌ $var not set in .env"; exit 1
  fi
done

echo "✅ All credentials loaded"

# Step 1: Link Supabase
echo ""
echo "📦 Step 1/4: Linking Supabase project..."
cd "$(dirname "$0")/../supabase"
supabase link --project-ref "$SUPABASE_PROJECT_REF" 2>/dev/null || true

# Step 2: Push migrations
echo "📦 Step 2/4: Running database migrations..."
supabase db push

# Step 3: Set secrets & deploy functions
echo "📦 Step 3/4: Deploying Edge Functions..."
supabase secrets set \
  AZURE_SPEECH_ENDPOINT="$AZURE_SPEECH_ENDPOINT" \
  AZURE_SPEECH_KEY="$AZURE_SPEECH_KEY" \
  OPENAI_API_KEY="$OPENAI_API_KEY" \
  ELEVENLABS_API_KEY="$ELEVENLABS_API_KEY"

supabase functions deploy pronounce
supabase functions deploy transcribe
supabase functions deploy chat
supabase functions deploy tts

# Step 4: Flutter deps
echo "📦 Step 4/4: Getting Flutter dependencies..."
cd "$(dirname "$0")/.."
flutter pub get

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Generate voices:  ELEVENLABS_API_KEY=$ELEVENLABS_API_KEY python3 scripts/generate_voices.py"
echo "  2. Run app:          flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
echo "  3. Build APK:        ./scripts/build.sh"
