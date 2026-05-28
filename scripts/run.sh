#!/bin/bash
# SpeakEng — Run in debug mode with env vars
# Usage: ./scripts/run.sh
set -e

ENV_FILE="$(dirname "$0")/../.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ .env not found. Run ./scripts/setup.sh first."; exit 1
fi
source "$ENV_FILE"

cd "$(dirname "$0")/.."
flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
