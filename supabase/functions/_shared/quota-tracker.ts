/**
 * Shared quota tracker for ElevenLabs free plan limits.
 *
 * Tracks monthly usage of TTS (characters) and STT (minutes)
 * to determine whether to use ElevenLabs (free) or fallback to OpenAI (paid).
 *
 * Usage is stored in Supabase DB table `api_usage`.
 * Resets automatically at the start of each month.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ELEVENLABS_TTS_LIMIT_CHARS = 10_000; // Free plan: 10K chars/month
const ELEVENLABS_STT_LIMIT_MINUTES = 300;  // Free plan: 300 min/month

// Safety margin: stop using ElevenLabs at 90% to avoid hitting hard limit
const SAFETY_FACTOR = 0.9;

interface UsageRecord {
  tts_chars_used: number;
  stt_minutes_used: number;
  month: string; // "2026-05"
}

function getCurrentMonth(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

function getSupabaseAdmin() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

/**
 * Get current month's usage from DB.
 */
async function getUsage(): Promise<UsageRecord> {
  const month = getCurrentMonth();
  const supabase = getSupabaseAdmin();

  const { data } = await supabase
    .from("api_usage")
    .select("tts_chars_used, stt_minutes_used, month")
    .eq("month", month)
    .maybeSingle();

  if (data) return data as UsageRecord;

  // First request this month — create record
  return { tts_chars_used: 0, stt_minutes_used: 0, month };
}

/**
 * Increment TTS character usage.
 */
export async function incrementTtsUsage(chars: number): Promise<void> {
  const month = getCurrentMonth();
  const supabase = getSupabaseAdmin();

  await supabase.from("api_usage").upsert(
    {
      month,
      tts_chars_used: chars,
      stt_minutes_used: 0,
    },
    { onConflict: "month" },
  );

  // Actually increment (not set)
  await supabase.rpc("increment_tts_usage", { p_month: month, p_chars: chars });
}

/**
 * Increment STT minutes usage.
 */
export async function incrementSttUsage(minutes: number): Promise<void> {
  const month = getCurrentMonth();
  const supabase = getSupabaseAdmin();

  await supabase.rpc("increment_stt_usage", { p_month: month, p_minutes: minutes });
}

/**
 * Check if ElevenLabs TTS quota is available for given text.
 */
export async function canUseElevenLabsTts(textLength: number): Promise<boolean> {
  const usage = await getUsage();
  const limit = ELEVENLABS_TTS_LIMIT_CHARS * SAFETY_FACTOR;
  return (usage.tts_chars_used + textLength) <= limit;
}

/**
 * Check if ElevenLabs STT quota is available for given audio duration.
 */
export async function canUseElevenLabsStt(estimatedMinutes: number): Promise<boolean> {
  const usage = await getUsage();
  const limit = ELEVENLABS_STT_LIMIT_MINUTES * SAFETY_FACTOR;
  return (usage.stt_minutes_used + estimatedMinutes) <= limit;
}
