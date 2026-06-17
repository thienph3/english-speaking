# Roadmap

## Platform: Android first, iOS later (Flutter cross-platform)

---

## Current Status (2026-06-17)

### ✅ Code — Done

| Component | Status | Notes |
|-----------|--------|-------|
| Flutter project (feature-first architecture) | ✅ | Riverpod, GoRouter, freezed |
| Auth (Supabase email/password) | ✅ | Login/Register screen + redirect logic |
| Mini Placement Test (3 câu) | ✅ | Azure pronunciation → assign level |
| Shadowing flow (play → record → results) | ✅ | Color-coded words, phoneme tips, phrase mode, speed control |
| AI Conversation (5 turns max) | ✅ | Whisper STT → GPT-4o-mini → TTS |
| Post-conversation feedback | ✅ | Grammar errors, vocab suggestions, target phrases usage |
| Daily Flow (3 shadow + 1 conversation + summary) | ✅ | State machine, orchestration |
| Progress Dashboard | ✅ | Mastery count, accuracy, response time, week comparison |
| Before/After recordings | ✅ | Supabase Storage upload/download |
| Error handling | ✅ | Offline banner, timeout retry, audio validation |
| AI Service Orchestrator | ✅ | Online/offline fallback, quota tracking, provider selection |
| Offline TTS/STT (sherpa_onnx) | ✅ | Piper VITS + Whisper tiny, model download UI |
| Onboarding screen | ✅ | Feature introduction for new users |
| Supabase Edge Functions (4) | ✅ | /pronounce, /transcribe, /chat, /tts |
| Database schema (SQL migrations) | ✅ | recordings, sentence_progress, daily_metrics, user_profiles, api_usage |
| Tests (184 passing) | ✅ | Unit, widget, state machine, router, orchestrator integration |
| Deployment scripts | ✅ | setup.sh, build.sh, run.sh (macOS + Windows) |

### ✅ Content — Done

| Content | Status | Notes |
|---------|--------|-------|
| 100 shadowing sentences (10 situations × 10) | ✅ | JSON with phrases, grammar, difficulty |
| 3 conversation scenarios | ✅ | Coffee, directions, job interview |
| 3 placement sentences | ✅ | Easy/medium/hard |
| Vietnamese phoneme tips (11 phonemes) | ✅ | θ, ð, r, l, ʃ, ʒ, z, ŋ, p/t/k final |

### ⏳ Preprocess — Pending

| Task | Status | Notes |
|------|--------|-------|
| Generate voice files (ElevenLabs TTS) | ⏳ | Script ready (`scripts/generate_voices.py`), needs API key |
| Update sentences.json with audio paths | ⏳ | Script ready (`scripts/update_sentences_audio_paths.py`) |

### ⏳ Setup — Pending (cần trước khi chạy app)

| Task | Status | Notes |
|------|--------|-------|
| Supabase project | ⏳ | Tạo project, lấy URL + anon key |
| Run SQL migrations | ⏳ | `supabase/migrations/001_*.sql`, `002_*.sql` |
| Azure Speech account | ⏳ | Lấy endpoint + key cho pronunciation assessment |
| OpenAI API key | ⏳ | Cho Whisper, GPT-4o-mini, TTS (conversation) |
| ElevenLabs account (free) | ⏳ | Cho pre-generate shadowing audio |
| Set environment variables | ⏳ | SUPABASE_URL, SUPABASE_ANON_KEY, AZURE_*, OPENAI_* |

### 📦 Data Files

```
data/
├── word_levels_enriched.json    # 2,801 words + IPA + definitions (chưa dùng trong MVP)
├── ipa_en_us.txt                # IPA reference
├── ngsl.csv                     # NGSL word list (source)
└── ngsl_spoken.csv              # NGSL spoken frequency

lib/data/
├── sentences.json               # 100 câu shadowing (app content)
├── scenarios.json               # 3 conversation scenarios
├── placement.json               # 3 câu placement test
└── phoneme_tips.json            # Vietnamese pronunciation tips

assets/voices/                   # Pre-generated TTS audio (chưa generate)
└── {sentence_id}.mp3            # 1 file per sentence
```

---

## Content Contract

### Shadowing Sentence
```json
{
  "id": "ordering_food_001",
  "text": "I'd like a latte, please.",
  "situation": "ordering_food",
  "phrases": ["I'd like", "a latte", "please"],
  "target_grammar": "would like + noun",
  "difficulty": "easy",
  "audio_asset_path": "assets/voices/ordering_food_001.mp3"
}
```

### Conversation Scenario
```json
{
  "id": "order_coffee",
  "situation": "Ordering at a coffee shop",
  "ai_role": "barista",
  "first_message": "Hi! What can I get for you today?",
  "target_phrases": ["I'd like", "Could I have", "What do you recommend"],
  "target_grammar": ["polite requests with could/would"],
  "max_turns": 5,
  "hints": ["Try: I'd like a...", "Ask: What do you recommend?"],
  "system_prompt": "You are a friendly barista..."
}
```

### Mini Placement (3 sentences)
```json
[
  {"id": "placement_easy", "text": "I want some water, please.", "difficulty": "easy"},
  {"id": "placement_medium", "text": "Could you tell me where the nearest station is?", "difficulty": "medium"},
  {"id": "placement_hard", "text": "I'd appreciate it if you could reschedule the meeting to Thursday.", "difficulty": "hard"}
]
```

Placement scoring: avg ≥ 80% → medium/hard, 50–79% → easy/medium, < 50% → easy only.

---

## 10 Situations (MVP)

| # | Situation | Category |
|---|-----------|----------|
| 1 | Ordering food & drinks | Daily Life |
| 2 | Small talk with neighbor/colleague | Daily Life |
| 3 | Asking for directions | Daily Life |
| 4 | Shopping & paying | Daily Life |
| 5 | Making a phone call | Daily Life |
| 6 | Job interview basics | Work |
| 7 | Meeting — giving opinions | Work |
| 8 | Airport & hotel check-in | Travel |
| 9 | Making friends / introducing yourself | Social |
| 10 | Describing your day / telling stories | Social |

---

## Next Steps (to ship MVP)

> See [docs/deployment.md](deployment.md) for detailed instructions.

1. **Setup accounts** (~15 min): Supabase, Azure Speech, OpenAI, ElevenLabs (free)
2. **Deploy backend** (~10 min): `supabase db push` + `supabase functions deploy`
3. **Generate voices** (~10 min): `python3 scripts/generate_voices.py`
4. **Build APK** (~5 min): `flutter build apk --release`
5. **Test on device** (~10 min): Full daily flow end-to-end
6. **Distribute to beta testers** (50 users)

---

## v0.2 — After MVP validation

### Code
- Tap word → show IPA + definition (dùng `data/word_levels_enriched.json`)
- Adaptive difficulty (serve harder sentences when accuracy > 85% consistently)
- Recording timeline (listen to yourself over time)
- Push notification ("5 phút hôm nay?")
- Conversation replay (transcript + audio)

### Content
- 50 more sentences (expand weak situations based on user data)
- 5 more conversation scenarios
- Pronunciation heatmap data collection

---

## v0.3 — Social + Retention

### Code
- Share recording with friend
- Weekly progress summary
- Situation recommendations based on weak areas

### Content
- Situation-specific vocabulary lists
- "Quick response" drill sentences

---

## v1.0 — Full Launch (Month 3)

- 200+ sentences across 20 situations
- 15+ conversation scenarios
- Pronunciation heatmap UI
- Custom situation request
- iOS launch
- Light gamification if retention data shows it's needed

---

## Future (if validated)

- Self-hosted Whisper (reduce cost at scale)
- Group conversation mode
- Accent training
- Monetization

---

## Success Metrics

| Metric | Target (MVP) |
|--------|-------------|
| Users complete daily 5-min flow | > 60% |
| Sentences mastered per week | > 5 per active user |
| Response time improvement (week 1 → 4) | > 1s faster |
| Pronunciation accuracy improvement | > 10% over 4 weeks |
| D7 retention | > 25% |
| Users who listen to before/after | > 40% |
| "Would recommend to friend" | > 70% |

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| ElevenLabs TTS pre-generate (not runtime) | Chất lượng tốt nhất, free tier đủ 100 câu, không tốn API mỗi lần user mở app |
| LibriSpeech removed | Audiobook fragments không phù hợp cho conversational shadowing |
| OpenAI TTS cho conversation runtime | Đã integrate, latency OK cho real-time response |
| Azure Speech cho pronunciation | Phoneme-level scoring, designed for language learners |
| Offline TTS/STT via sherpa_onnx | Piper VITS (~30MB) + Whisper tiny.en (~40MB), fallback khi mất mạng |
| AI Service Orchestrator | Auto-select online/offline provider, quota tracking, fallback chain |
| Feature-first architecture | Scale tốt, mỗi feature isolated, dễ maintain |
