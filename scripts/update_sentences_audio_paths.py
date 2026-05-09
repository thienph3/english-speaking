#!/usr/bin/env python3
"""
Pre-process script: Update sentences.json with audio_asset_path fields.

Reads lib/data/sentences.json, adds audio_asset_path pointing to
assets/voices/{id}.mp3 for each sentence, and writes back.

Usage:
    python3 scripts/update_sentences_audio_paths.py

Run this AFTER generate_voices.py to update the JSON with paths.
"""

import json
from pathlib import Path

SENTENCES_PATH = Path("lib/data/sentences.json")
VOICES_DIR = Path("assets/voices")


def main():
    with open(SENTENCES_PATH, "r", encoding="utf-8") as f:
        sentences = json.load(f)

    updated = 0
    for sentence in sentences:
        voice_file = VOICES_DIR / f"{sentence['id']}.mp3"
        audio_path = f"assets/voices/{sentence['id']}.mp3"

        if voice_file.exists():
            sentence["audio_asset_path"] = audio_path
            updated += 1
        else:
            # Keep null if voice file doesn't exist yet
            sentence.setdefault("audio_asset_path", None)

    with open(SENTENCES_PATH, "w", encoding="utf-8") as f:
        json.dump(sentences, f, indent=2, ensure_ascii=False)

    print(f"Updated {updated}/{len(sentences)} sentences with audio paths")
    print(f"Sentences without audio: {len(sentences) - updated}")


if __name__ == "__main__":
    main()
