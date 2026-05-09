# Technical Analysis (v2)

## Architecture

No backend server. Flutter app + Supabase + OpenAI APIs.

```
┌─────────────────────────────────────────┐
│              Flutter App                  │
├─────────────────────────────────────────┤
│  UI: Shadowing | Conversation | Progress │
│  State: Riverpod                         │
│  Audio: record + playback                │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│           Supabase (free tier)            │
├─────────────────────────────────────────┤
│  Auth         → login/signup             │
│  Edge Functions → proxy API calls        │
│  Database     → user progress, metrics   │
│  Storage      → user recordings          │
└──────────────────┬──────────────────────┘
                   │
          ┌────────┴────────┐
          ▼                 ▼
┌──────────────────┐ ┌─────────────────────┐
│   Azure Speech   │ │    OpenAI APIs       │
├──────────────────┤ ├─────────────────────┤
│  Pronunciation   │ │  Whisper (STT)       │
│  Assessment      │ │  GPT-4o-mini (AI)    │
│  (shadowing)     │ │  TTS (voice output)  │
└──────────────────┘ └─────────────────────┘
```

---

## Tech Stack

| Layer | Tech | Cost (<10 DAU) |
|-------|------|----------------|
| Frontend | Flutter (Android first) | $0 |
| Auth | Supabase Auth | $0 (50K MAU free) |
| DB | Supabase PostgreSQL | $0 (500MB free) |
| Storage | Supabase Storage | $0 (1GB free) |
| API Proxy | Supabase Edge Functions | $0 (500K invocations free) |
| Pronunciation | Azure Speech Pronunciation Assessment | ~$15/mo |
| STT | OpenAI Whisper API (conversation only) | ~$0.36/mo |
| AI | OpenAI GPT-4o-mini | ~$0.30/mo |
| TTS | OpenAI TTS | ~$0.90/mo |
| **Total** | | **~$16/month** |

---

## Supabase Edge Functions (API Proxy)

4 functions that keep API keys server-side:

### /pronounce (Shadowing — Azure)
```typescript
serve(async (req) => {
  const formData = await req.formData()
  const audio = formData.get("audio") as File
  const referenceText = formData.get("reference_text") as string

  const response = await fetch(
    `${Deno.env.get("AZURE_SPEECH_ENDPOINT")}/speech/recognition/conversation/cognitiveservices/v1?language=en-US`,
    {
      method: "POST",
      headers: {
        "Ocp-Apim-Subscription-Key": Deno.env.get("AZURE_SPEECH_KEY")!,
        "Content-Type": "audio/wav",
        "Pronunciation-Assessment": btoa(JSON.stringify({
          ReferenceText: referenceText,
          GradingSystem: "HundredMark",
          Granularity: "Phoneme",
          Dimension: "Comprehensive"
        }))
      },
      body: await audio.arrayBuffer()
    }
  )

  return new Response(JSON.stringify(await response.json()))
})
```

### /transcribe (Conversation — Whisper)
```typescript
serve(async (req) => {
  const formData = await req.formData()
  const audio = formData.get("audio")

  const fd = new FormData()
  fd.append("file", audio, "audio.wav")
  fd.append("model", "whisper-1")
  fd.append("response_format", "verbose_json")
  fd.append("timestamp_granularities[]", "word")

  const response = await fetch("https://api.openai.com/v1/audio/transcriptions", {
    method: "POST",
    headers: { "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}` },
    body: fd
  })

  return new Response(JSON.stringify(await response.json()))
})
```

### /chat
```typescript
serve(async (req) => {
  const { messages, scenario } = await req.json()

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [{ role: "system", content: scenario.system_prompt }, ...messages]
    })
  })

  return new Response(JSON.stringify(await response.json()))
})
```

### /tts
```typescript
serve(async (req) => {
  const { text } = await req.json()

  const response = await fetch("https://api.openai.com/v1/audio/speech", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ model: "tts-1", voice: "nova", input: text })
  })

  return new Response(await response.arrayBuffer(), {
    headers: { "Content-Type": "audio/mpeg" }
  })
})
```

---

## Pillar 1: Shadowing + Pronunciation Feedback

### How It Works

```
Play sentence → User records → Upload to /pronounce (Azure)
  → Azure returns phoneme-level scores per word
  → Highlight: correct (green) / mispronounced (red) / missed (gray)
  → Show specific phoneme feedback for red words
```

### Azure Pronunciation Assessment

Designed specifically for language learners. Requires reference text (perfect for shadowing).

**Response structure:**
```json
{
  "NBest": [{
    "PronunciationAssessment": {
      "AccuracyScore": 78,
      "FluencyScore": 85,
      "CompletenessScore": 100,
      "PronScore": 82
    },
    "Words": [
      {
        "Word": "think",
        "PronunciationAssessment": {
          "AccuracyScore": 62,
          "ErrorType": "Mispronunciation"
        },
        "Phonemes": [
          {"Phoneme": "θ", "PronunciationAssessment": {"AccuracyScore": 15}},
          {"Phoneme": "ɪ", "PronunciationAssessment": {"AccuracyScore": 95}},
          {"Phoneme": "ŋ", "PronunciationAssessment": {"AccuracyScore": 88}},
          {"Phoneme": "k", "PronunciationAssessment": {"AccuracyScore": 92}}
        ]
      }
    ]
  }]
}
```

### What Azure Gives Us (vs Whisper)

| | Whisper | Azure Pronunciation |
|--|--|--|
| Purpose | Transcription | **Pronunciation scoring** |
| Phoneme-level scores | ❌ | ✅ |
| Word accuracy score | ❌ | ✅ |
| Fluency score | ❌ | ✅ |
| Completeness score | ❌ | ✅ |
| Needs reference text | No | Yes (perfect for shadowing) |
| Cost/min | $0.006 | $0.017 |

### Scoring & Feedback Logic

```dart
class PronunciationFeedback {
  final List<WordFeedback> words;
  final double overallAccuracy;
  final double fluency;
  final double completeness;
}

class WordFeedback {
  final String word;
  final double accuracyScore;
  final String? errorType; // "Mispronunciation", "Omission", "Insertion"
  final List<PhonemeFeedback> phonemes;
  
  bool get isCorrect => accuracyScore >= 80;
  bool get needsWork => accuracyScore >= 50 && accuracyScore < 80;
  bool get isWrong => accuracyScore < 50;
}

class PhonemeFeedback {
  final String phoneme;
  final double accuracyScore;
}

/// Generate user-facing tip for mispronounced words
String? getTip(WordFeedback word) {
  if (word.isCorrect) return null;
  
  // Find worst phoneme
  final worst = word.phonemes.reduce((a, b) => 
    a.accuracyScore < b.accuracyScore ? a : b);
  
  return vietnameseTips[worst.phoneme] ?? 
    'Focus on the /${worst.phoneme}/ sound in "${word.word}"';
}
```

### Vietnamese-Specific Phoneme Tips

```dart
const vietnameseTips = {
  'θ': 'Đặt lưỡi giữa 2 răng, thổi hơi ra nhẹ. Không phải /t/ hay /s/.',
  'ð': 'Đặt lưỡi giữa 2 răng, rung dây thanh. Không phải /d/ hay /z/.',
  'r': 'Cong lưỡi ra sau, KHÔNG chạm vòm miệng. Khác hoàn toàn "r" tiếng Việt.',
  'l': 'Đầu lưỡi chạm vòm miệng phía trước. Khác với /r/.',
  'ʃ': 'Môi tròn, lưỡi lùi ra sau. Giống "s" nhưng dày hơn.',
  'ʒ': 'Giống /ʃ/ nhưng rung dây thanh.',
  'z': 'Giống /s/ nhưng rung dây thanh. Tiếng Việt không có âm này.',
  'ŋ': 'Âm "ng" cuối từ — giữ nguyên, không thêm /g/ phía sau.',
  'p': 'Phụ âm cuối — ngậm môi, bật hơi nhẹ. Không nuốt âm.',
  't': 'Phụ âm cuối — đầu lưỡi chạm vòm, bật nhẹ. Không nuốt.',
  'k': 'Phụ âm cuối — cuống lưỡi chạm vòm mềm, bật nhẹ.',
};
```

### When to Use Azure vs Whisper

| Mode | API | Why |
|------|-----|-----|
| **Shadowing** | Azure Pronunciation | Has reference text, needs phoneme feedback |
| **Conversation** | Whisper | No reference text, just need transcription |

---

## Pillar 2: AI Conversation

### Flow & Latency

```
User speaks → Upload audio (0.5s)
  → Whisper transcribe (1–3s)
  → Send to GPT-4o-mini (1–2s)
  → TTS generate (1–2s)
  → Play AI response
Total latency: 3–7 seconds
```

### Latency Mitigation

| Strategy | How |
|----------|-----|
| Loading animation | Show "thinking..." with typing indicator while waiting |
| Stream AI text | Display AI text as it generates, before TTS finishes |
| Pre-generate first message | AI's opening line is pre-cached (no wait on start) |
| Accept the delay | Real conversations have pauses too — 3–5s is acceptable |

**Not a dealbreaker.** Voice assistants (Siri, Alexa) have similar latency. Users accept it when the response is good.

### Scenario Config

See [Roadmap — Content Format](roadmap.md#content-format) for JSON schema.

### Feedback Quality

GPT-4o-mini with structured output format. Use `response_format: { type: "json_object" }` on the final turn to ensure consistent feedback JSON. Test prompts with real Vietnamese speaker transcripts before shipping.

---

## Pillar 3: Progress Tracking

### Supabase Tables

```sql
create table recordings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  sentence_id text,
  audio_path text,
  accuracy float,
  created_at timestamptz default now()
);

create table sentence_progress (
  user_id uuid references auth.users(id),
  sentence_id text,
  correct_streak int default 0,
  best_accuracy float,
  last_practiced timestamptz,
  primary key (user_id, sentence_id)
);

create table daily_metrics (
  user_id uuid references auth.users(id),
  date date,
  sentences_practiced int default 0,
  sentences_mastered int default 0,
  avg_accuracy float,
  avg_response_time_ms int,
  primary key (user_id, date)
);
```

---

## Error Handling

| Scenario | UX |
|----------|-----|
| No internet | Show cached progress, disable shadowing/conversation, prompt to reconnect |
| Azure timeout (>10s) | "Couldn't process audio. Try again?" + retry button |
| Azure rejects audio (<1s or >60s) | "Recording too short/long. Aim for 2–10 seconds." |
| Whisper timeout (>10s) | "Couldn't process audio. Try again?" + retry button |
| Empty recording (silence) | "Didn't hear anything. Make sure microphone is working." |
| User speaks Vietnamese | Whisper transcribes Vietnamese → 0% match → "Try again in English" |
| Accuracy < 20% | "Couldn't understand clearly. Try speaking slower." |
| TTS fails | Show AI text response without audio, offer "Read aloud" option |
| Edge Function cold start | First request may take 1–2s extra. Pre-warm on app launch. |

---

## Scaling Path

| Users | Infra | Change needed |
|-------|-------|---------------|
| <10 | Supabase free + Azure + OpenAI API | None |
| 10–1,000 | Supabase Pro ($25/mo) | Upgrade plan |
| 1,000–5,000 | Same + self-hosted Whisper | Add GPU server (~$115/mo) |
| 5,000+ | Dedicated backend | Migrate Edge Functions → own API |

**Note:** Azure Pronunciation Assessment has no self-hosted option. Cost scales linearly (~$0.017/min/user). At 5,000 DAU × 3 min/day = ~$7,650/month for Azure alone. At that scale, evaluate on-device pronunciation models (wav2vec2) or negotiate Azure volume pricing.

---

## Vocabulary Data

Bundled JSON (`data/word_levels_enriched.json`, ~200KB) with 2,801 words from NGSL (CC-BY):

```json
{
  "want": {"level": "a1", "ipa": "/wɒnt/", "definition": "to feel that you would like something"},
  "opportunity": {"level": "b1", "ipa": "/ˌɒpəˈtjuːnɪti/", "definition": "a time when you can do something"}
}
```

**MVP usage:** Tap any word → see IPA + definition. Vocabulary suggestions handled by GPT prompt.

**v0.2 usage:** Adaptive difficulty (serve harder sentences based on mastery rate), active vocabulary tracking (words user actually uses in conversation).

---

## MVP Timeline

See [Roadmap](roadmap.md) for detailed weekly breakdown.
