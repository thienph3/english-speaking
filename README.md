# SpeakEng — English Pronunciation & Speaking Confidence App

A Flutter app that fixes pronunciation and builds speaking confidence through **shadowing with phoneme-level feedback** and **AI conversation practice**. Built for Vietnamese learners who know grammar but freeze when speaking.

## Core Idea

Pronunciation is a motor skill. You fix it by **doing reps with immediate correction**. This app provides:

1. **Shadowing + Phoneme Feedback** — Listen → repeat → get phoneme-level pronunciation correction (Azure Speech)
2. **AI Conversation** — Practice real situations with AI, build confidence speaking in context
3. **Real Progress** — Before/after recordings, pronunciation accuracy trends, sentences mastered

## Daily Flow (5 minutes)

```
Open app
  → 3 sentences shadowing (with pronunciation feedback)  [2 min]
  → 1 mini conversation (3–5 turns)                      [3 min]
  → Summary: "Today: 2 new sentences mastered,
    response time improved 0.3s"
Done.
```

## Documentation

| Doc | Description |
|-----|-------------|
| [Product Concept](docs/product-concept.md) | 3 pillars, user flow, situation-based content |
| [Technical Analysis](docs/technical-analysis.md) | Architecture, APIs, scoring, error handling |
| [Roadmap](docs/roadmap.md) | MVP scope, timeline, content format |
| [Deployment Guide](docs/deployment.md) | Step-by-step deploy: accounts, backend, APK build |

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter (Android first, iOS later) |
| Backend | Supabase (Auth + DB + Storage + Edge Functions) |
| Pronunciation | Azure Speech Pronunciation Assessment (phoneme-level) |
| STT | OpenAI Whisper API (online) / sherpa_onnx Whisper tiny (offline) |
| TTS | OpenAI TTS (online) / sherpa_onnx Piper VITS (offline) |
| Offline Engine | sherpa_onnx 1.13.2 (on-device TTS/STT) |
| State | Riverpod + freezed |
| Cost (<10 DAU) | ~$12/month |

## Status

- [x] Product concept defined (v2 — learning-first)
- [x] Technical architecture designed
- [x] Vocabulary data prepared (2,801 words with IPA + definitions)
- [x] Shadowing audio classified (483 LibriSpeech sentences)
- [x] Build shadowing mode + Azure Pronunciation integration
- [x] Build AI conversation mode (with TTS playback)
- [x] Build progress tracking (dashboard + before/after player)
- [x] Build daily flow (sentence selection + persistence)
- [x] AI Service Orchestrator (online/offline fallback, quota tracking)
- [x] Offline TTS/STT (sherpa_onnx + model download UI)
- [x] Tests (184 passing — state machines, routing, orchestrator, widgets)
- [ ] Setup accounts (Supabase, Azure, OpenAI)
- [ ] Generate voice files (edge-tts for shadowing)
- [ ] Deploy Edge Functions + run migrations
- [ ] Beta testing (50 users)
