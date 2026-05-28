#!/bin/bash
# SpeakEng — Build release APK
# Usage: ./scripts/build.sh
set -e

ENV_FILE="$(dirname "$0")/../.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env not found. Run ./scripts/setup.sh first."; exit 1
fi
source "$ENV_FILE"

echo "🔨 Building release APK..."
cd "$(dirname "$0")/.."

flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
SIZE=$(du -h "$APK_PATH" | cut -f1)

echo ""
echo "✅ APK built: $APK_PATH ($SIZE)"
echo "   Install: adb install $APK_PATH"
