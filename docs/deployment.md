# Deployment Guide — SpeakEng

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- Python 3.8+ (for voice generation script)
- Accounts: Supabase, Azure Speech, OpenAI, ElevenLabs (free tier)

---

## Step 1: Create Supabase Project (10 min)

1. Go to [supabase.com](https://supabase.com) → New Project
2. Note down:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Anon Key**: (Settings → API → anon/public)
   - **Service Role Key**: (Settings → API → service_role)

3. Create Storage bucket:
   - Storage → New Bucket → Name: `recordings` → Public: No

---

## Step 2: Run Database Migrations (5 min)

```bash
cd supabase

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations in order
supabase db push
```

This creates tables: `user_profiles`, `recordings`, `sentence_progress`, `daily_metrics`, `api_usage`, `events`.

---

## Step 3: Setup API Keys (15 min)

### Azure Speech
1. [Azure Portal](https://portal.azure.com) → Create "Speech Services" resource (Free F0 tier)
2. Note: **Endpoint** and **Key 1**

### OpenAI
1. [platform.openai.com](https://platform.openai.com) → API Keys → Create
2. Note: **API Key**

### ElevenLabs
1. [elevenlabs.io](https://elevenlabs.io) → Sign up (free tier: 10,000 chars/month)
2. Profile → API Key
3. Note: **API Key**

---

## Step 4: Deploy Edge Functions (10 min)

```bash
# Set secrets
supabase secrets set AZURE_SPEECH_ENDPOINT="https://YOUR_REGION.api.cognitive.microsoft.com"
supabase secrets set AZURE_SPEECH_KEY="your-azure-key"
supabase secrets set OPENAI_API_KEY="sk-your-openai-key"
supabase secrets set ELEVENLABS_API_KEY="your-elevenlabs-key"

# Deploy all functions
supabase functions deploy pronounce
supabase functions deploy transcribe
supabase functions deploy chat
supabase functions deploy tts
```

Verify: `supabase functions list` should show 4 functions with status "Active".

---

## Step 5: Generate Voice Files (30 min)

```bash
# Install dependencies
pip install elevenlabs

# Set API key
export ELEVENLABS_API_KEY="your-elevenlabs-key"

# Generate audio for all 100 sentences
python3 scripts/generate_voices.py

# Update sentences.json with audio paths
python3 scripts/update_sentences_audio_paths.py
```

Output: `assets/voices/{sentence_id}.mp3` (100 files, ~50MB total)

---

## Step 6: Configure Flutter App (5 min)

The app reads Supabase credentials from compile-time environment variables:

```bash
# Create .env file (gitignored)
cat > .env << EOF
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
EOF
```

Build with env vars:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

---

## Step 7: Build APK (5 min)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Step 8: Test on Device

1. Install APK on Android phone
2. Sign up with email/password
3. Complete placement test (3 sentences)
4. Do daily flow: 3 shadowing + 1 conversation
5. Check progress dashboard

---

## Verify Checklist

| Step | Verify |
|------|--------|
| Supabase | Can sign up/login from app |
| Migrations | Tables visible in Supabase Dashboard → Table Editor |
| Edge Functions | `curl -X POST https://xxx.supabase.co/functions/v1/pronounce` returns 401 (auth required) |
| Azure Speech | Shadowing returns pronunciation scores |
| OpenAI | Conversation AI responds |
| ElevenLabs/TTS | AI voice plays in conversation |
| Voice files | Shadowing plays reference audio |
| Storage | Before/after recordings upload successfully |
| Notifications | Daily reminder appears at 8 AM next day |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Supabase not initialized" | Check SUPABASE_URL and SUPABASE_ANON_KEY are passed via --dart-define |
| Edge function 500 | Check `supabase functions logs pronounce` for missing env vars |
| No audio in shadowing | Verify `assets/voices/` files exist and pubspec.yaml has `assets/voices/` entry |
| Pronunciation always 0% | Azure endpoint region must match key region |
| Conversation timeout | Check OpenAI API key has credits |

---

## Cost Estimate (<10 DAU)

| Service | Free Tier | Monthly Cost |
|---------|-----------|-------------|
| Supabase | 500MB DB, 1GB storage, 500K edge invocations | $0 |
| Azure Speech | 500K chars/month | $0 |
| OpenAI (Whisper + GPT + TTS) | — | ~$12 |
| ElevenLabs | 10K chars/month (pre-generated only) | $0 |
| **Total** | | **~$12/month** |
