# Roadmap

## Platform: Android first, iOS later (Flutter cross-platform)

---

## Content Contract (align before building)

Before writing sentences or code, define what a "situation" contains:

### Shadowing Sentence
```json
{
  "id": "daily_order_001",
  "text": "I'd like a latte, please.",
  "situation": "ordering_food",
  "phrases": ["I'd like", "a latte", "please"],
  "target_grammar": "would like + noun",
  "difficulty": "easy"
}
```

### Conversation Scenario
```json
{
  "id": "order_coffee",
  "situation": "Ordering at a coffee shop",
  "ai_role": "Friendly barista",
  "first_message": "Hi! What can I get for you today?",
  "target_phrases": ["I'd like a...", "Can I get...", "For here / to go"],
  "target_grammar": ["would like + noun", "Can I + verb"],
  "max_turns": 5,
  "hints": ["Try: I'd like a...", "Try: Can I get a..."],
  "system_prompt": "You are a friendly barista at a coffee shop. Keep responses short (1-2 sentences). Be natural and conversational. After the final turn, provide feedback as JSON with keys: grammar_errors, vocabulary_suggestions, positive, improve."
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

User's Azure accuracy on these 3 sentences → assign starting difficulty:
- Avg ≥ 80%: start medium/hard
- Avg 50–79%: start easy/medium
- Avg < 50%: start easy only

---

## MVP (v0.1) — 4 Weeks

### Strategy: Ship shadowing first (week 1–2), validate, then add conversation (week 3–4)

---

### 🔧 Code Track

| Week | Deliverable |
|------|-------------|
| 1 | Flutter project setup, audio record/playback, Supabase setup, Azure /pronounce edge function, basic shadowing flow (play → record → show results) |
| 2 | Phoneme feedback UI (color-coded words, tap for detail), Vietnamese tips, phrase-by-phrase mode, speed control, before/after recording storage, mini placement (3 sentences) |
| 3 | Whisper /transcribe + /chat + /tts edge functions, conversation flow (AI speaks → user speaks → AI responds), loading states, hint system |
| 4 | Post-conversation feedback UI, progress dashboard, daily flow (3 shadow + 1 conversation + summary), error handling, streak tracking, polish |

**Week 2 checkpoint:** Deploy shadowing-only to 10 test users. Validate:
- Do they complete 3 sentences/day?
- Is Azure feedback useful?
- Do they come back day 2, day 3?

---

### 📝 Content Track (parallel with code)

| Week | Deliverable |
|------|-------------|
| 1 | Define 10 situations. Write 10 sentences each for first 5 situations (50 sentences). Write 3 placement sentences. |
| 2 | Write 10 sentences each for remaining 5 situations (50 more = 100 total). Write 3 conversation scenario configs. |
| 3 | Test & refine scenarios with GPT prompt (fake 5 user transcripts per scenario, check feedback quality). Adjust system prompts. |
| 4 | Review all 100 sentences for naturalness. Add phrase breakdowns. Tag difficulty. Buffer: write 20 extra sentences for weak situations. |

**Content output:** 100 shadowing sentences, 3 conversation scenarios, 10 situations, 3 placement sentences.

---

### 10 Situations (MVP)

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

## v0.2 — Week 5–6 (More Content + Adaptive)

### Code
- Adaptive difficulty (serve harder sentences when accuracy > 85% consistently)
- Recording timeline (listen to yourself over time)
- Push notification ("5 phút hôm nay?")
- Conversation replay (transcript + audio)

### Content
- 50 more sentences (expand weak situations based on user data)
- 5 more conversation scenarios
- Pronunciation heatmap data collection (which phonemes users fail most)

---

## v0.3 — Week 7–8 (Social + Retention)

### Code
- Share recording with friend (link/audio clip)
- Weekly progress summary
- Situation recommendations based on weak areas

### Content
- Situation-specific vocabulary lists
- "Quick response" drill sentences (for response time training)

---

## v1.0 — Month 3 (Full Launch)

- 200+ sentences across 20 situations
- 15+ conversation scenarios
- Pronunciation heatmap UI
- Custom situation request ("I have a meeting tomorrow about X")
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
| Ship shadowing first (week 2), conversation later (week 4) | De-risk: validate core value prop before building second feature |
| 100 sentences instead of 50 | 50 hết trong 3 ngày. 100 cho ~10 ngày content trước khi repeat |
| Mini placement (3 sentences) | Avoid serving wrong difficulty. Cheap to build (1–2 hours) |
| Content track parallel with code | Don't block coding on content, don't block content on code |
| Test prompts before building conversation UI | Avoid building UI for bad feedback. Validate GPT output first |
