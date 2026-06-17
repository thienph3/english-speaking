#!/usr/bin/env python3
"""
Generate TTS voice files for shadowing sentences using edge-tts.

edge-tts uses Microsoft Edge's free TTS service — no API key needed,
high quality, multiple English voices available.

Usage:
    pip install edge-tts
    python3 scripts/generate_voices.py

Output:
    assets/voices/{sentence_id}.mp3
"""

import asyncio
import json
import sys
from pathlib import Path

try:
    import edge_tts
except ImportError:
    print("Error: 'edge-tts' package required. Run: pip install edge-tts")
    sys.exit(1)

# Configuration
SENTENCES_PATH = Path("lib/data/sentences.json")
VOICES_DIR = Path("assets/voices")

# Microsoft Edge TTS voice — clear American English female
# Other options: en-US-GuyNeural (male), en-US-JennyNeural, en-US-AriaNeural
VOICE = "en-US-JennyNeural"


def load_sentences() -> list:
    if not SENTENCES_PATH.exists():
        print(f"Error: {SENTENCES_PATH} not found")
        sys.exit(1)
    with open(SENTENCES_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def get_missing_sentences(sentences: list) -> list:
    missing = []
    for s in sentences:
        voice_path = VOICES_DIR / f"{s['id']}.mp3"
        if not voice_path.exists():
            missing.append(s)
    return missing


async def generate_voice(text: str, output_path: Path) -> bool:
    try:
        communicate = edge_tts.Communicate(text, VOICE, rate="-10%")
        await communicate.save(str(output_path))
        return True
    except Exception as e:
        print(f"  Error: {e}")
        return False


async def main():
    sentences = load_sentences()
    print(f"Total sentences: {len(sentences)}")

    missing = get_missing_sentences(sentences)
    print(f"Missing voice files: {len(missing)}")

    if not missing:
        print("All voice files already exist. Nothing to do.")
        return

    VOICES_DIR.mkdir(parents=True, exist_ok=True)

    success = 0
    fail = 0

    for i, sentence in enumerate(missing, 1):
        output_path = VOICES_DIR / f"{sentence['id']}.mp3"
        print(f"[{i}/{len(missing)}] {sentence['id']}: \"{sentence['text'][:50]}\"")

        if await generate_voice(sentence["text"], output_path):
            success += 1
            print(f"  ✓ Saved")
        else:
            fail += 1
            print(f"  ✗ Failed")

    print(f"\nDone! Success: {success}, Failed: {fail}")
    print(f"Voice files: {VOICES_DIR}/")


if __name__ == "__main__":
    asyncio.run(main())
