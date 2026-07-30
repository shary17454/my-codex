import test from "node:test";
import assert from "node:assert/strict";
import http from "node:http";
import {
  buildSafeContext,
  createServer,
  redactSensitiveText,
  validatePayload
} from "./server.mjs";

function listen(server) {
  return new Promise((resolve) => {
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      resolve(`http://127.0.0.1:${address.port}`);
    });
  });
}

function close(server) {
  return new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
}

function post(url, body, token = "test-token") {
  return new Promise((resolve, reject) => {
    const request = http.request(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Batal-AI-Client-Token": token
      }
    }, (response) => {
      const chunks = [];
      response.on("data", (chunk) => chunks.push(chunk));
      response.on("end", () => {
        resolve({
          statusCode: response.statusCode,
          json: JSON.parse(Buffer.concat(chunks).toString("utf8"))
        });
      });
    });
    request.on("error", reject);
    request.end(JSON.stringify(body));
  });
}

const basePayload = {
  message: "وش أقرب قطعة؟",
  language: "ar",
  currentSearch: "21082-4W000",
  selectedCategory: "الكل",
  vehicleSummary: "Y60 · 1997 · TB48",
  savedRequestCount: 1,
  parts: [
    {
      protectedNumber: "21••••00",
      partNumber: "21082-4W000",
      title: "Exact part",
      category: "تبريد",
      model: "Y60",
      years: ["1997"],
      engines: ["TB48"],
      confidence: 70,
      evidenceCount: 0,
      unlocked: false
    }
  ],
  maintenance: []
};

test("validates required message and limits", () => {
  assert.equal(validatePayload({}), "missing_message");
  assert.equal(validatePayload({ message: " " }), "invalid_message_length");
  assert.equal(validatePayload({ message: "a".repeat(801) }), "invalid_message_length");
  assert.equal(validatePayload({ message: "ok", language: "fr" }), "invalid_language");
  assert.equal(validatePayload(basePayload), null);
});

test("redacts sensitive strings", () => {
  const redacted = redactSensitiveText("VIN JN8AZ2NF0E9555555 token=abc sk-proj-abcdefghijklmnopqrstuvwxyz");
  assert.match(redacted, /\[REDACTED_VIN\]/);
  assert.match(redacted, /token=\[REDACTED\]/);
  assert.match(redacted, /\[REDACTED_SECRET\]/);
});

test("safe context does not expose locked part numbers", () => {
  const context = buildSafeContext(basePayload);
  assert.equal(context.parts[0].partNumber, "");
  assert.equal(context.parts[0].protectedNumber, "21••••00");
  assert.doesNotMatch(JSON.stringify(context), /21082-4W000/);
});

test("requires client token", async () => {
  const server = createServer({ env: { OPENAI_API_KEY: "test", BATAL_AI_CLIENT_TOKEN: "test-token" } });
  const baseURL = await listen(server);
  try {
    const response = await post(`${baseURL}/api/ai/chat`, basePayload, "wrong");
    assert.equal(response.statusCode, 401);
    assert.equal(response.json.error, "unauthorized");
  } finally {
    await close(server);
  }
});

test("calls OpenAI with store false and returns structured answer", async () => {
  let outboundBody;
  const fetchImpl = async (_url, options) => {
    outboundBody = JSON.parse(options.body);
    return {
      ok: true,
      async json() {
        return { output_text: "أقرب نتيجة هي الرقم المقنع 21••••00." };
      }
    };
  };
  const server = createServer({
    fetchImpl,
    env: { OPENAI_API_KEY: "test", BATAL_AI_CLIENT_TOKEN: "test-token", AI_MODEL: "test-model" }
  });
  const baseURL = await listen(server);
  try {
    const response = await post(`${baseURL}/api/ai/chat`, basePayload);
    assert.equal(response.statusCode, 200);
    assert.equal(response.json.generatedByAI, true);
    assert.equal(outboundBody.store, false);
    assert.equal(outboundBody.model, "test-model");
  } finally {
    await close(server);
  }
});

test("returns provider failure as safe structured error", async () => {
  const fetchImpl = async () => ({ ok: false, async json() { return {}; } });
  const server = createServer({
    fetchImpl,
    env: { OPENAI_API_KEY: "test", BATAL_AI_CLIENT_TOKEN: "test-token" }
  });
  const baseURL = await listen(server);
  try {
    const response = await post(`${baseURL}/api/ai/chat`, basePayload);
    assert.equal(response.statusCode, 502);
    assert.equal(response.json.error, "provider_error");
  } finally {
    await close(server);
  }
});
