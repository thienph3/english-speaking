-- Migration: API usage tracking for ElevenLabs free tier quota management.
-- Tracks monthly TTS chars and STT minutes to enable fallback to OpenAI.

CREATE TABLE IF NOT EXISTS api_usage (
  month TEXT PRIMARY KEY,  -- "2026-05"
  tts_chars_used INT DEFAULT 0,
  stt_minutes_used FLOAT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Function to atomically increment TTS usage
CREATE OR REPLACE FUNCTION increment_tts_usage(p_month TEXT, p_chars INT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO api_usage (month, tts_chars_used)
  VALUES (p_month, p_chars)
  ON CONFLICT (month)
  DO UPDATE SET
    tts_chars_used = api_usage.tts_chars_used + p_chars,
    updated_at = now();
END;
$$ LANGUAGE plpgsql;

-- Function to atomically increment STT usage
CREATE OR REPLACE FUNCTION increment_stt_usage(p_month TEXT, p_minutes FLOAT)
RETURNS VOID AS $$
BEGIN
  INSERT INTO api_usage (month, stt_minutes_used)
  VALUES (p_month, p_minutes)
  ON CONFLICT (month)
  DO UPDATE SET
    stt_minutes_used = api_usage.stt_minutes_used + p_minutes,
    updated_at = now();
END;
$$ LANGUAGE plpgsql;
