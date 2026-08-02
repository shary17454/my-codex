import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");
const defaultEnvPath = path.join(projectRoot, ".env.local");
const MAX_BODY_BYTES = 32 * 1024;
const MAX_PARTS = 12;
const RATE_WINDOW_MS = 60_000;
const RATE_LIMIT = 20;
const DEFAULT_AI_MODEL = "gpt-4.1-mini";

export function loadLocalEnv(envPath = defaultEnvPath) {
  if (!fs.existsSync(envPath)) return;
  const raw = fs.readFileSync(envPath, "utf8");
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#") || !trimmed.includes("=")) continue;
    const [key, ...rest] = trimmed.split("=");
    if (!process.env[key]) process.env[key] = rest.join("=").trim();
  }
}

export function redactSensitiveText(value) {
  return String(value ?? "")
    .replace(/\b[A-HJ-NPR-Z0-9]{17}\b/gi, "[REDACTED_VIN]")
    .replace(/\b(?:sk|sk-proj)-[A-Za-z0-9_-]{16,}\b/g, "[REDACTED_SECRET]")
    .replace(/\b(password|token|secret)\s*[:=]\s*\S+/gi, "$1=[REDACTED]")
    .slice(0, 1200);
}

function maskPotentialPartNumbers(value) {
  return redactSensitiveText(value)
    .replace(/\b[A-Z0-9]{4,}-[A-Z0-9]{3,}\b/gi, "[PROTECTED_PART_NUMBER]")
    .replace(/\b[A-Z0-9]{9,12}\b/gi, "[PROTECTED_PART_NUMBER]");
}

export function validatePayload(payload) {
  if (!payload || typeof payload !== "object") return "invalid_payload";
  if (typeof payload.message !== "string") return "missing_message";
  const message = payload.message.trim();
  if (!message || message.length > 800) return "invalid_message_length";
  if (payload.language && !["ar", "en"].includes(payload.language)) return "invalid_language";
  if (payload.parts && !Array.isArray(payload.parts)) return "invalid_parts";
  if ((payload.parts ?? []).length > MAX_PARTS) return "too_many_parts";
  return null;
}

export function buildSafeContext(payload) {
  const parts = (payload.parts ?? []).slice(0, MAX_PARTS).map((part) => ({
    protectedNumber: redactSensitiveText(part.protectedNumber),
    partNumber: part.unlocked ? redactSensitiveText(part.partNumber) : "",
    title: redactSensitiveText(part.title),
    category: redactSensitiveText(part.category),
    model: redactSensitiveText(part.model),
    years: Array.isArray(part.years) ? part.years.slice(0, 8).map(redactSensitiveText) : [],
    engines: Array.isArray(part.engines) ? part.engines.slice(0, 6).map(redactSensitiveText) : [],
    confidence: Number.isFinite(part.confidence) ? part.confidence : null,
    evidenceCount: Number.isFinite(part.evidenceCount) ? part.evidenceCount : 0,
    unlocked: part.unlocked === true
  }));
  const maintenance = (payload.maintenance ?? []).slice(0, 5).map((item) => ({
    title: redactSensitiveText(item.title).slice(0, 100),
    odometer: redactSensitiveText(item.odometer).slice(0, 40),
    notesPreview: redactSensitiveText(item.notesPreview).slice(0, 160)
  }));
  return {
    language: payload.language === "en" ? "en" : "ar",
    message: maskPotentialPartNumbers(payload.message),
    currentSearch: maskPotentialPartNumbers(payload.currentSearch).slice(0, 180),
    selectedCategory: redactSensitiveText(payload.selectedCategory).slice(0, 80),
    vehicleSummary: redactSensitiveText(payload.vehicleSummary).slice(0, 160),
    savedRequestCount: Number.isFinite(payload.savedRequestCount) ? payload.savedRequestCount : 0,
    parts,
    maintenance
  };
}

function systemPrompt(language) {
  return [
    "You are the Batal Al-Droob in-app assistant for Nissan Patrol parts.",
    "Answer only from the supplied app context. If the context is insufficient, say you do not know.",
    "Never invent part numbers, fitment, prices, supplier partnerships, or completed actions.",
    "Do not reveal full part numbers unless the provided context marks that record as unlocked.",
    "Ask for confirmation before destructive or purchase-related actions.",
    "Keep the answer concise, practical, and in the user's language.",
    language === "ar" ? "Respond in Arabic." : "Respond in English."
  ].join("\n");
}

function parseResponseText(providerPayload) {
  if (typeof providerPayload.output_text === "string") return providerPayload.output_text;
  const chunks = [];
  for (const item of providerPayload.output ?? []) {
    for (const content of item.content ?? []) {
      if (content.type === "output_text" && typeof content.text === "string") chunks.push(content.text);
      if (typeof content.text === "string") chunks.push(content.text);
    }
  }
  return chunks.join("\n").trim();
}

async function readJSONBody(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) {
      const error = new Error("body_too_large");
      error.statusCode = 413;
      throw error;
    }
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}");
  } catch {
    const error = new Error("invalid_json");
    error.statusCode = 400;
    throw error;
  }
}

function writeJSON(response, statusCode, payload) {
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store"
  });
  response.end(JSON.stringify(payload));
}

function createRateLimiter() {
  const buckets = new Map();
  return function isAllowed(key) {
    const now = Date.now();
    const bucket = buckets.get(key) ?? { count: 0, resetAt: now + RATE_WINDOW_MS };
    if (bucket.resetAt <= now) {
      bucket.count = 0;
      bucket.resetAt = now + RATE_WINDOW_MS;
    }
    bucket.count += 1;
    buckets.set(key, bucket);
    return bucket.count <= RATE_LIMIT;
  };
}

async function callOpenAI(context, fetchImpl, env) {
  const apiKey = env.OPENAI_API_KEY;
  if (!apiKey) {
    const error = new Error("missing_openai_api_key");
    error.statusCode = 503;
    throw error;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 18_000);
  try {
    const result = await fetchImpl("https://api.openai.com/v1/responses", {
      method: "POST",
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: env.AI_MODEL || DEFAULT_AI_MODEL,
        store: false,
        max_output_tokens: 600,
        input: [
          { role: "system", content: systemPrompt(context.language) },
          { role: "user", content: JSON.stringify(context) }
        ]
      })
    });
    if (!result.ok) {
      const error = new Error("provider_error");
      error.statusCode = 502;
      throw error;
    }
    const providerPayload = await result.json();
    const text = parseResponseText(providerPayload);
    if (!text) {
      const error = new Error("empty_provider_response");
      error.statusCode = 502;
      throw error;
    }
    return text;
  } finally {
    clearTimeout(timeout);
  }
}

function suggestionsFor(context) {
  const ar = context.language !== "en";
  const suggestions = [];
  if (context.parts.length > 0) {
    suggestions.push({
      id: "review-top-result",
      title: ar ? "افتح أقرب نتيجة" : "Open the closest result",
      reason: ar ? "نتائج الكتالوج الحالية تحتوي مرشحين قابلين للمراجعة." : "Current catalog results include reviewable candidates."
    });
  }
  suggestions.push({
    id: "verify-fitment",
    title: ar ? "تحقق من التوافق" : "Verify fitment",
    reason: ar ? "مطابقة السنة والمحرك تقلل طلب القطعة الخطأ." : "Matching year and engine reduces wrong-part requests."
  });
  return suggestions;
}

export function createServer({ fetchImpl = globalThis.fetch, env = process.env } = {}) {
  const isAllowed = createRateLimiter();
  return http.createServer(async (request, response) => {
    try {
      const url = new URL(request.url, `http://${request.headers.host ?? "localhost"}`);
      if (request.method === "GET" && url.pathname === "/health") {
        writeJSON(response, 200, { ok: true, aiConfigured: Boolean(env.OPENAI_API_KEY) });
        return;
      }

      const validPaths = new Set(["/api/ai/chat", "/api/ai/search", "/api/ai/summarize", "/api/ai/suggestions"]);
      if (request.method !== "POST" || !validPaths.has(url.pathname)) {
        writeJSON(response, 404, { error: "not_found" });
        return;
      }

      const expectedToken = env.BATAL_AI_CLIENT_TOKEN;
      const actualToken = request.headers["x-batal-ai-client-token"];
      if (!expectedToken || actualToken !== expectedToken) {
        writeJSON(response, 401, { error: "unauthorized" });
        return;
      }

      const rateKey = `${request.socket.remoteAddress ?? "local"}:${actualToken}`;
      if (!isAllowed(rateKey)) {
        writeJSON(response, 429, { error: "rate_limited" });
        return;
      }

      const payload = await readJSONBody(request);
      const validationError = validatePayload(payload);
      if (validationError) {
        writeJSON(response, 400, { error: validationError });
        return;
      }

      const context = buildSafeContext(payload);
      const answer = await callOpenAI(context, fetchImpl, env);
      writeJSON(response, 200, {
        answer,
        suggestions: suggestionsFor(context),
        generatedByAI: true,
        privacyNote: context.language === "ar"
          ? "تمت معالجة السؤال عبر خادم بطل الدروب الآمن مع تقليل البيانات المرسلة."
          : "Processed through the secure Batal Al-Droob backend with minimized context."
      });
    } catch (error) {
      const statusCode = error.statusCode ?? (error.name === "AbortError" ? 504 : 500);
      console.error("AI backend request failed", { statusCode, reason: error.message });
      writeJSON(response, statusCode, { error: statusCode === 500 ? "internal_error" : error.message });
    }
  });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  loadLocalEnv();
  const port = Number(process.env.PORT || 8787);
  createServer().listen(port, "127.0.0.1", () => {
    console.log(`Batal AI backend listening on http://127.0.0.1:${port}`);
  });
}
