import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const TIMEOUT_MS = 10_000;

serve(async (req: Request): Promise<Response> => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }

  const azureEndpoint = Deno.env.get("AZURE_SPEECH_ENDPOINT");
  const azureKey = Deno.env.get("AZURE_SPEECH_KEY");

  if (!azureEndpoint || !azureKey) {
    return new Response(
      JSON.stringify({ error: "Azure Speech credentials not configured" }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }

  try {
    const formData = await req.formData();
    const audio = formData.get("audio") as File | null;
    const referenceText = formData.get("reference_text") as string | null;

    if (!audio) {
      return new Response(
        JSON.stringify({ error: "Missing audio file" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    if (!referenceText) {
      return new Response(
        JSON.stringify({ error: "Missing reference_text" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    }

    const pronunciationConfig = btoa(JSON.stringify({
      ReferenceText: referenceText,
      GradingSystem: "HundredMark",
      Granularity: "Phoneme",
      Dimension: "Comprehensive",
    }));

    const azureUrl =
      `${azureEndpoint}/speech/recognition/conversation/cognitiveservices/v1?language=en-US`;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), TIMEOUT_MS);

    try {
      const response = await fetch(azureUrl, {
        method: "POST",
        headers: {
          "Ocp-Apim-Subscription-Key": azureKey,
          "Content-Type": "audio/wav",
          "Pronunciation-Assessment": pronunciationConfig,
        },
        body: await audio.arrayBuffer(),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorBody = await response.text();
        return new Response(
          JSON.stringify({ error: "Azure API error", status: response.status, detail: errorBody }),
          { status: response.status, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
        );
      }

      const result = await response.json();

      return new Response(
        JSON.stringify(result),
        { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
      );
    } catch (err) {
      clearTimeout(timeoutId);

      if (err instanceof DOMException && err.name === "AbortError") {
        return new Response(
          JSON.stringify({ error: "Request timeout", message: "Azure Speech API did not respond within 10 seconds" }),
          { status: 504, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
        );
      }

      throw err;
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: "Internal server error", message }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } },
    );
  }
});
