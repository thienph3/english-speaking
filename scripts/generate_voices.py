#!/usr/bin/env python3
"""
Pre-process script: Generate TTS voice files for shadowing sentences.

Reads lib/data/sentences.json, checks if voice file already exists in
assets/voices/, and generates missing ones using ElevenLabs TTS API.

Usage:
    export ELEVENLABS_API_KEY="your-api-key"
    python3 scripts/generate_voices.py

Output:
    assets/voices/{sentence_id}.mp3

Requirements:
    pip install requests
"""

import json
import os
import sys
import time
from pathlib import Path

try:
    import requests
except ImportError:
    print("Error: 'requests' package required. Run: pip install requests")
    sys.exit(1)

# Configuration
SENTENCES_PATH = Path("lib/data/sentences.json")
VOICES_DIR = Path("assets/voices")
ELEVENLABS_API_URL = "https://api.elevenlabs.io/v1/text-to-speech"

# ElevenLabs voice IDs (pre-made voices, no custom voice needed)
# "Rachel" - clear female American English, good for language learning
VOICE_ID = "21m00Tcm4TlvDq8ikWAM"  # Rachel

# TTS settings optimized for shadowing (clear pronunciation)
TTS_SETTINGS = {
    "stability": 0.75,        # Higher = more consistent pronunciation
    "similarity_boost": 0.75, # Higher = closer to voice character
    "style": 0.0,             # No style exaggeration
    "use_speaker_boost": True,
}


def load_sentences() -> list[dict]:
    """Load sentences from JSON file."""
    if not SENTENCES_PATH.exists():
        print(f"Error: {SENTENCES_PATH} not found")
        sys.exit(1)

    with open(SENTENCES_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def get_missing_sentences(sentences: list[dict]) -> list[dict]:
    """Filter sentences that don't have a voice file yet."""
    missing = []
    for sentence in sentences:
        voice_path = VOICES_DIR / f"{sentence['id']}.mp3"
        if not voice_path.exists():
            missing.append(sentence)
    return missing


def generate_voice(text: str, output_path: Path, api_key: str) -> bool:
    """Generate TTS audio using ElevenLabs API.

    Returns True on success, False on failure.
    """
    url = f"{ELEVENLABS_API_URL}/{VOICE_ID}"

    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json",
    }

    payload = {
        "text": text,
        "model_id": "eleven_flash_v2_5",
        "voice_settings": TTS_SETTINGS,
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)

        if response.status_code == 200:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "wb") as f:
                f.write(response.content)
            return True

        print(f"  Error {response.status_code}: {response.text[:100]}")
        return False

    except requests.exceptions.Timeout:
        print("  Error: Request timeout")
        return False
    except requests.exceptions.RequestException as e:
        print(f"  Error: {e}")
        return False


def main():
    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key:
        print("Error: ELEVENLABS_API_KEY environment variable not set")
        print("Get your free API key at: https://elevenlabs.io")
        sys.exit(1)

    sentences = load_sentences()
    print(f"Total sentences: {len(sentences)}")

    missing = get_missing_sentences(sentences)
    print(f"Missing voice files: {len(missing)}")

    if not missing:
        print("All voice files already exist. Nothing to do.")
        return

    # Estimate characters
    total_chars = sum(len(s["text"]) for s in missing)
    print(f"Total characters to generate: {total_chars}")
    print(f"ElevenLabs free tier: 10,000 chars/month")
    print()

    if total_chars > 10000:
        print("Warning: exceeds free tier limit. Will generate in batches.")
        print()

    VOICES_DIR.mkdir(parents=True, exist_ok=True)

    success_count = 0
    fail_count = 0

    for i, sentence in enumerate(missing, 1):
        output_path = VOICES_DIR / f"{sentence['id']}.mp3"
        print(f"[{i}/{len(missing)}] {sentence['id']}: \"{sentence['text'][:50]}...\"")

        if generate_voice(sentence["text"], output_path, api_key):
            success_count += 1
            print(f"  ✓ Saved: {output_path}")
        else:
            fail_count += 1
            print(f"  ✗ Failed")

        # Rate limit: ElevenLabs free tier allows ~2-3 requests/second
        if i < len(missing):
            time.sleep(0.5)

    print()
    print(f"Done! Success: {success_count}, Failed: {fail_count}")
    print(f"Voice files saved to: {VOICES_DIR}/")


if __name__ == "__main__":
    main()
