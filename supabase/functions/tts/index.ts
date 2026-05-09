import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { canUseElevenLabsTts, incrementTtsUsage } from "../_shared/quota-tracker.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const TIMEOUT_MS = 10_000;

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
    const body = await req.json();
    const { text } = body;

    if (!text || typeof text !== "string") {
      return new Response(
        JSON.stringify({ error: "Missing or invalid text field" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    // Check ElevenLabs quota first
    const useElevenLabs = await canUseElevenLabsTts(text.length);

    let audioBuffer: ArrayBuffer;

    if (useElevenLabs) {
      audioBuffer = await elevenLabsTts(text);
      await incrementTtsUsage(text.length);
    } else {
      audioBuffer = await openAiTts(text);
    }

    return new Response(audioBuffer, {
      status: 200,
      headers: {
        ...CORS_HEADERS,
        "Content-Type": "audio/mpeg",
        "Content-Length": audioBuffer.byteLength.toString(),
      },
    });
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
 * ElevenLabs TTS — free tier, highest quality.
 */
async function elevenLabsTts(text: string): Promise<ArrayBuffer> {
  const apiKey = Deno.env.get("ELEVENLABS_API_KEY");
  if (!apiKey) throw new Error("ELEVENLABS_API_KEY not configured");

  // Rachel voice — clear American English
  const voiceId = "21m00Tcm4TlvDq8ikWAM";

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
      {
        method: "POST",
        headers: {
          "xi-api-key": apiKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          text,
          model_id: "eleven_monolingual_v1",
          voice_settings: { stability: 0.75, similarity_boost: 0.75 },
        }),
        signal: controller.signal,
      },
    );

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`ElevenLabs error ${response.status}`);
    }

    return response.arrayBuffer();
  } catch (err) {
    clearTimeout(timeoutId);
    if (err instanceof DOMException && err.name === "AbortError") {
      throw new Error("timeout");
    }
    throw err;
  }
}

/**
 * OpenAI TTS — fallback, pay-as-you-go.
 */
async function openAiTts(text: string): Promise<ArrayBuffer> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY not configured");

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(
      "https://api.openai.com/v1/audio/speech",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ model: "tts-1", voice: "nova", input: text }),
        signal: controller.signal,
      },
    );

    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`OpenAI TTS error ${response.status}`);
    }

    return response.arrayBuffer();
  } catch (err) {
    clearTimeout(timeoutId);
    if (err instanceof DOMException && err.name === "AbortError") {
      throw new Error("timeout");
    }
    throw err;
  }
}
