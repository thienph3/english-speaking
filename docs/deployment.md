# Deployment Guide — SpeakEng

## Overview

SpeakEng is code-complete. This guide covers deploying the backend and building the APK.

**Time estimate:** ~50 minutes (excluding account creation wait times)

**Architecture:**
```
Flutter App (Android)
    ↓ HTTPS
Supabase Edge Functions (4)
    ↓
├── Azure Speech (pronunciation assessment)
├── OpenAI Whisper (speech-to-text)
├── OpenAI GPT-4o-mini (AI conversation)
├── OpenAI TTS (conversation voice)
└── Supabase (auth, DB, storage)
```

**Offline fallback:** App uses sherpa_onnx (Piper TTS + Whisper tiny) when network unavailable.

---

## Quick Start (Scripted)

```bash
# 1. Create accounts and get API keys (see Step 1 below)

# 2. Run setup script
./scripts/setup.sh        # Creates .env template on first run

# 3. Fill .env with your credentials

# 4. Run setup again to deploy
./scripts/setup.sh        # Deploys migrations + edge functions

# 5. Generate voice files
pip install elevenlabs
python3 scripts/generate_voices.py

# 6. Build APK
./scripts/build.sh
```

---

## Step-by-Step (Manual)

### Step 1: Create Accounts (15 min)

| Service | Purpose | Free Tier | Required? |
|---------|---------|-----------|-----------|
| [Supabase](https://supabase.com) | Auth, DB, Storage, Edge Functions | 500MB DB, 1GB storage | **Yes** |
| [Azure Speech](https://portal.azure.com) | Phoneme-level pronunciation scoring | 5 hours/month | Optional* |
| [OpenAI](https://platform.openai.com) | Whisper STT + GPT-4o-mini + TTS | Pay-as-you-go | Optional* |
| [ElevenLabs](https://elevenlabs.io) | Pre-generate shadowing audio | 10,000 chars/month | Optional* |

*Without Azure: shadowing works but no accuracy scoring.
*Without OpenAI: conversation feature disabled, shadowing still works.
*Without ElevenLabs: app uses offline Piper TTS for reference audio.

#### Supabase Setup
1. New Project → note **Project URL** and **Anon Key** (Settings → API)
2. Note **Service Role Key** (Settings → API → service_role)
3. Note **Project Ref** (from URL: `https://PROJECT_REF.supabase.co`)
4. Storage → New Bucket → Name: `recordings` → Public: No

#### Azure Speech Setup
1. Azure Portal → Create "Speech Services" resource → **Free F0** tier
2. Note **Endpoint** (e.g., `https://eastus.api.cognitive.microsoft.com`)
3. Note **Key 1**

#### OpenAI Setup
1. platform.openai.com → API Keys → Create new key
2. Add $5 credits (minimum for pay-as-you-go)

#### ElevenLabs Setup
1. Sign up (free tier sufficient for 100 sentences)
2. Profile → API Key

---

### Step 2: Configure Environment (2 min)

Create `.env` at project root (gitignored):

```bash
# Required
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
SUPABASE_PROJECT_REF=xxxxx

# Optional (app works without these via offline fallback)
AZURE_SPEECH_ENDPOINT=https://eastus.api.cognitive.microsoft.com
AZURE_SPEECH_KEY=your-key
OPENAI_API_KEY=sk-your-key
ELEVENLABS_API_KEY=your-key
```

---

### Step 3: Deploy Database (5 min)

```bash
cd supabase

# Link to your project
supabase link --project-ref $SUPABASE_PROJECT_REF

# Push all migrations
supabase db push
```

Creates tables:
- `recordings` — user audio recordings (before/after)
- `sentence_progress` — per-sentence accuracy tracking
- `daily_metrics` — daily aggregated stats
- `user_profiles` — placement results + level
- `api_usage` — server-side quota tracking

All tables have Row Level Security (RLS) — users can only access their own data.

---

### Step 4: Deploy Edge Functions (5 min)

```bash
# Set secrets for edge functions
supabase secrets set \
  AZURE_SPEECH_ENDPOINT="$AZURE_SPEECH_ENDPOINT" \
  AZURE_SPEECH_KEY="$AZURE_SPEECH_KEY" \
  OPENAI_API_KEY="$OPENAI_API_KEY"

# Deploy all 4 functions
supabase functions deploy pronounce
supabase functions deploy transcribe
supabase functions deploy chat
supabase functions deploy tts
```

Verify: `supabase functions list` → 4 functions, status "Active".

| Function | Purpose | External API |
|----------|---------|-------------|
| `/pronounce` | Pronunciation assessment | Azure Speech |
| `/transcribe` | Speech-to-text | OpenAI Whisper |
| `/chat` | AI conversation | OpenAI GPT-4o-mini |
| `/tts` | Text-to-speech | OpenAI TTS |

---

### Step 5: Generate Shadowing Audio (10 min)

```bash
export ELEVENLABS_API_KEY="your-key"
pip install elevenlabs

# Generate MP3 for all 100 sentences
python3 scripts/generate_voices.py

# Update sentences.json with audio paths
python3 scripts/update_sentences_audio_paths.py
```

Output: `assets/voices/{sentence_id}.mp3` (100 files, ~50MB)

> **Skip this step** if you don't have ElevenLabs. The app will use offline TTS as fallback (lower quality but functional).

---

### Step 6: Build & Install APK (5 min)

```bash
# Debug build (for testing)
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Release build
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Install: `adb install build/app/outputs/flutter-apk/app-release.apk`

---

### Step 7: End-to-End Verification

| # | Test | Expected |
|---|------|----------|
| 1 | Register with email/password | Account created, redirected to placement |
| 2 | Complete placement (3 sentences) | Level assigned, redirected to onboarding |
| 3 | Finish onboarding | Redirected to daily flow |
| 4 | Shadowing: play reference audio | Audio plays at selected speed |
| 5 | Shadowing: record & submit | Color-coded word feedback + scores |
| 6 | Conversation: record response | AI responds with voice + text |
| 7 | Complete daily flow | Summary screen with stats |
| 8 | Progress screen | Shows mastery count, accuracy chart |
| 9 | Turn on airplane mode | Offline banner shows, app still usable |
| 10 | Settings: download offline models | sherpa_onnx models download (~70MB) |

---

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| "Supabase not initialized" | Missing dart-define | Pass `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `--dart-define` |
| Edge function returns 500 | Missing secrets | `supabase secrets list` — verify all keys set |
| No audio in shadowing | Voice files not generated | Run `scripts/generate_voices.py` or enable offline TTS |
| Pronunciation always 0% | Azure region mismatch | Endpoint region must match key region |
| Conversation timeout | OpenAI no credits | Add credits at platform.openai.com/account/billing |
| "No providers available" | All quotas exceeded | Check Settings screen → quota usage |
| Offline models not working | Models not downloaded | Settings → Download Models |

---

## Cost Estimate

### <10 DAU (Personal/Testing)

| Service | Monthly Cost |
|---------|-------------|
| Supabase | $0 (free tier) |
| Azure Speech | $0 (free tier: 5hr/month) |
| OpenAI | ~$12 (Whisper $0.006/min + GPT $0.15/1M tokens + TTS $15/1M chars) |
| ElevenLabs | $0 (one-time pre-generation) |
| **Total** | **~$12/month** |

### 50 DAU (Beta)

| Service | Monthly Cost |
|---------|-------------|
| Supabase | $0 (free tier still sufficient) |
| Azure Speech | $0 (free tier: ~2,500 assessments/month) |
| OpenAI | ~$60 |
| **Total** | **~$60/month** |

---

## Production Checklist (Before Beta)

- [ ] Enable email confirmation in Supabase Auth settings
- [ ] Set rate limits on Edge Functions (Supabase dashboard)
- [ ] Enable Supabase database backups (daily, free tier)
- [ ] Set up error alerting (Supabase logs → webhook/email)
- [ ] Test on 3+ Android devices (different screen sizes)
- [ ] Add Firebase Crashlytics (optional, for crash reporting)
- [ ] Configure ProGuard rules for release build
- [ ] Test full flow with slow network (3G simulation)
