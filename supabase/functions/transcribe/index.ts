import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { canUseElevenLabsStt, incrementSttUsage } from "../_shared/quota-tracker.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const TIMEOUT_MS = 10_000;

// Estimate: average conversation recording ~10 seconds = ~0.17 minutes
const ESTIMATED_AUDIO_MINUTES = 0.2;

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }

  try {
    const formData = await req.formData();
    const audio = formData.get("audio") as File | null;

    if (!audio) {
      return new Response(
        JSON.stringify({ error: "Missing audio file" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    // Check ElevenLabs STT quota
    const useElevenLabs = await canUseElevenLabsStt(ESTIMATED_AUDIO_MINUTES);

    let result: { text: string; language: string; words: unknown[] };

    if (useElevenLabs) {
      result = await elevenLabsStt(audio);
      await incrementSttUsage(ESTIMATED_AUDIO_MINUTES);
    } else {
      result = await openAiWhisper(audio);
    }

    return new Response(
      JSON.stringify(result),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";

    if (message.includes("timeout")) {
      return new Response(
        JSON.stringify({ error: "Request timeout" }),
        { status: 504, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ error: "Internal server error", message }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }
});

/**
 * ElevenLabs Scribe v2 STT — free tier (300 min/month).
 */
async function elevenLabsStt(audio: File): Promise<{ text: string; language: string; words: unknown[] }> {
  const apiKey = Deno.env.get("ELEVENLABS_API_KEY");
  if (!apiKey) throw new Error("ELEVENLABS_API_KEY not configured");

  const formData = new FormData();
  formData.append("file", audio, audio.name || "audio.wav");
  formData.append("model_id", "scribe_v2");

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(
      "https://api.elevenlabs.io/v1/speech-to-text",
      {
        method: "POST",
        headers: { "xi-api-key": apiKey },
        body: formData,
        signal: controller.signal,
      },
    );

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`ElevenLabs STT error ${response.status}`);
    }

    const data = await response.json();

    return {
      text: data.text ?? "",
      language: data.language_code ?? "en",
      words: data.words ?? [],
    };
  } catch (err) {
    clearTimeout(timeoutId);
    if (err instanceof DOMException && err.name === "AbortError") {
      throw new Error("timeout");
    }
    throw err;
  }
}

/**
 * OpenAI Whisper STT — fallback, $0.006/min.
 */
async function openAiWhisper(audio: File): Promise<{ text: string; language: string; words: unknown[] }> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY not configured");

  const formData = new FormData();
  formData.append("file", audio, audio.name || "audio.wav");
  formData.append("model", "whisper-1");
  formData.append("response_format", "verbose_json");
  formData.append("timestamp_granularities[]", "word");

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { "Authorization": `Bearer ${apiKey}` },
        body: formData,
        signal: controller.signal,
      },
    );

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`OpenAI Whisper error ${response.status}`);
    }

    const data = await response.json();

    return {
      text: data.text ?? "",
      language: data.language ?? "en",
      words: data.words ?? [],
    };
  } catch (err) {
    clearTimeout(timeoutId);
    if (err instanceof DOMException && err.name === "AbortError") {
      throw new Error("timeout");
    }
    throw err;
  }
}
