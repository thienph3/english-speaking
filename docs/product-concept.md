# Product Concept (v2)

## What This App Is

A **pronunciation trainer + speaking confidence builder**. Not a fluency app. Not a listening app.

Users will:
- ✅ Pronounce words/sentences more accurately (phoneme-level feedback)
- ✅ Feel more confident opening their mouth in English
- ✅ Learn useful phrases for specific situations
- ✅ See concrete proof of pronunciation improvement over time

Users will NOT:
- ❌ Become fluent speakers (fluency needs real-time human conversation)
- ❌ Improve listening comprehension (app uses clear TTS, not real-world audio)
- ❌ Train real-time reflexes (3–7s API latency in conversation mode)

## Problem

Vietnamese learners study English 10+ years. They know grammar, can read, but:
- **Freeze** when speaking — brain knows, mouth can't keep up
- **No feedback** — mispronounce words for years without knowing
- **No environment** — no one to practice with daily
- **Wrong practice** — reading aloud ≠ speaking, listening ≠ speaking

## Core Insight

Pronunciation is a **motor skill**. Like playing guitar or shooting basketball. You need:
1. Repetition **with correction** (not repeating mistakes 100 times)
2. Real situations (not "The cat is on the mat")
3. Progressive difficulty (easy sentences → harder sentences)
4. Proof of progress (concrete evidence, not XP)

## Solution: 3 Pillars

### Pillar 1: Shadowing + Pronunciation Feedback

**Purpose:** Fix pronunciation at the phoneme level. Train mouth muscles to produce correct sounds.

How it works:
- Listen to a sentence → repeat → Azure analyzes phoneme-by-phoneme
- Words pronounced wrong: highlighted red with specific phoneme feedback
  - "Word 'think': your /θ/ scored 15%. Place tongue between teeth, blow air gently."
- Words pronounced right: highlighted green
- Overall scores: accuracy, fluency, completeness
- Phrase-by-phrase mode for long sentences
- Speed control: 0.7x → 1.0x → 1.2x
- Before/after recording — hear yourself improve over weeks

**Why it works:** Immediate feedback loop at the phoneme level. Know exactly which sound is wrong → fix it → repeat. Proven method (same approach as ELSA), but situation-based.

**What it doesn't do:** Doesn't train fluency, connected speech, or intonation patterns. It trains accurate pronunciation of individual words and short phrases.

### Pillar 2: AI Conversation (Situation-Based)

**Purpose:** Train real-time speaking reflex in practical contexts.

How it works:
- User picks a situation: order coffee, job interview, small talk...
- AI plays the other person (voice output)
- User **speaks** (not types) → AI listens, understands, responds naturally
- After conversation, specific feedback:
  - "You used 'I think' 5 times — try 'In my opinion', 'I believe'"
  - "Average response time: 4s — target: 2s"
  - "Grammar: 'I am agree' → 'I agree'"

**Not a random chatbot.** Each scenario has:
- Target phrases and grammar patterns
- Difficulty that adapts (AI speaks slower/faster based on user level)
- End summary: what you used well, what to improve

**Why it works:** Closest to real conversation without needing a real person. Has pressure but is safe (no one judging).

### Pillar 3: Real Progress (Not XP)

**Purpose:** User sees concrete proof they're improving.

Metrics:
- **Sentences mastered** — accuracy ≥ 80% three times in a row
- **Response time** — time from hearing question to starting answer
- **Pronunciation accuracy %** — this week vs last week
- **Active vocabulary** — words user actually USES when speaking (not "learned")
- **Recording timeline** — listen to yourself 1 month ago vs today

No XP, no levels, no badges, no leaderboard, no streak punishment.

Instead: **"Last month you froze 5s before answering. Now it's 2s."** — that's real motivation.

---

## Content: Situation-Based

```
Situations/
├── Daily Life/
│   ├── Ordering food & drinks
│   ├── Small talk with neighbor
│   ├── Asking for directions
│   └── Shopping & returns
├── Work/
│   ├── Job interview
│   ├── Meeting discussion
│   ├── Presenting ideas
│   └── Email follow-up call
├── Travel/
│   ├── Airport & hotel
│   ├── Asking locals
│   └── Emergency situations
└── Social/
    ├── Making friends
    ├── Giving opinions
    └── Telling stories
```

Each situation contains:
- 10–20 shadowing sentences (target phrases for that situation)
- 1 AI conversation scenario
- Target grammar + vocabulary

**User doesn't need to know their "level."** App auto-adjusts difficulty based on performance.

---

## Target User

- Vietnamese English learner
- Knows A2–B1 grammar/vocabulary
- Weak in fluency, pronunciation, real-time response
- Goal: speak confidently in daily/work situations
- Has Android smartphone + internet (4G/wifi)
- Willing to spend 5 min/day

## Platform

**Android first.** Larger market in Vietnam/SEA. iOS later via Flutter cross-platform.

---

## Retention Mechanics

### What brings users back daily:

1. **Before/after recordings** — app saves first recording of each sentence. After mastery, prompts: "Listen to your first attempt vs now." User hears their own improvement. This is the strongest retention mechanic.

2. **5-minute daily flow** — always the same structure (3 shadow + 1 conversation + summary). Low decision fatigue. Becomes automatic like brushing teeth.

3. **Sentences mastered counter** — simple number that only goes up. "You've mastered 23 sentences." Not XP that means nothing — actual sentences you can say correctly.

4. **Response time tracking** — "Last week: 4.2s average. This week: 3.1s." Concrete proof of faster reflexes.

5. **Gentle notification** — "5 phút hôm nay?" once per day at user's chosen time. No guilt, no "Your streak is dying!"

6. **Situation relevance** — "Meeting tomorrow? Practice 5 opening phrases now." Content connects to real life.

### What we explicitly DON'T do:
- No streak punishment (miss a day = nothing bad happens)
- No XP/points (meaningless numbers)
- No leaderboard (comparison kills motivation for beginners)
- No daily login rewards (bribery ≠ learning)

---

## Non-Goals (for now)

- Business model / monetization
- Offline mode
- Gamification (XP, levels, badges)
- IELTS/TOEIC score prediction
- Reading/writing/listening-only features
- B2B / classroom features
