import http from "node:http";

const base = process.env.BASE_URL || "http://localhost:8787";
const token = process.env.WESH_ALRAY_API_TOKEN || "";

function headers(clientID) {
  const value = {
    "content-type": "application/json",
    "x-client-id": clientID
  };
  if (token) value.authorization = `Bearer ${token}`;
  return value;
}

async function request(path, options = {}) {
  const response = await fetch(`${base}${path}`, options);
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`${options.method || "GET"} ${path} failed: ${response.status} ${JSON.stringify(body)}`);
  }
  return body;
}

let receivedAuthorization = "";
let receivedResponses = 0;

const mockOpenAI = http.createServer(async (req, res) => {
  if (req.method !== "POST" || req.url !== "/v1/responses") {
    res.writeHead(404, { "content-type": "application/json" });
    res.end(JSON.stringify({ error: { message: "not found" } }));
    return;
  }

  receivedResponses += 1;
  receivedAuthorization = req.headers.authorization || "";
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const body = JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}");
  const input = String(body.input || "");
  const isCameraDraft = input.includes("recognizedText");
  const text = isCameraDraft
    ? JSON.stringify({
        title: "كاميرا OpenAI أم بديل مناسب؟",
        details: "مسودة محسنة من مزود الذكاء الاصطناعي بناءً على النص المستخرج فقط.",
        primaryOption: "كاميرا OpenAI",
        options: ["كاميرا OpenAI", "بديل مناسب"],
        tags: ["كاميرا", "اختبار"],
        criteria: ["السعر", "الجودة", "سهولة الاستخدام"],
        category: "services",
        confidence: 0.91
      })
    : "إجابة OpenAI اختبارية مبنية على سياق وش الرأي المرسل من الخادم.";

  res.writeHead(200, { "content-type": "application/json" });
  res.end(JSON.stringify({ output_text: text }));
});

await new Promise((resolve) => mockOpenAI.listen(8788, "127.0.0.1", resolve));

try {
  const suffix = Date.now();
  const comparison = await request("/api/v1/comparisons", {
    method: "POST",
    headers: headers(`ai-provider-owner-${suffix}`),
    body: JSON.stringify({
      title: `اختبار مزود الذكاء ${suffix}`,
      details: "مقارنة لاختبار OpenAI provider",
      category: "services",
      author: "Smoke",
      visibility: "publicRoom",
      options: [{ title: "الخيار الأول" }, { title: "الخيار الثاني" }]
    })
  });

  const aiChat = await request("/api/v1/ai/chat", {
    method: "POST",
    headers: headers(`ai-provider-chat-${suffix}`),
    body: JSON.stringify({ prompt: "لخص اختبار مزود الذكاء" })
  });
  if (aiChat.provider !== "openai" || !aiChat.answer.includes("OpenAI")) {
    throw new Error("AI chat did not use the OpenAI provider.");
  }
  if (!aiChat.sources.some((source) => source.id === comparison.id)) {
    throw new Error("AI chat did not keep sourced app context.");
  }

  const aiSummary = await request("/api/v1/ai/summarize", {
    method: "POST",
    headers: headers(`ai-provider-summary-${suffix}`),
    body: JSON.stringify({ comparisonID: comparison.id })
  });
  if (aiSummary.provider !== "openai" || !aiSummary.aiSummary.includes("OpenAI")) {
    throw new Error("AI summarize did not use the OpenAI provider.");
  }

  const cameraDraft = await request("/api/v1/ai/camera-draft", {
    method: "POST",
    headers: headers(`ai-provider-camera-${suffix}`),
    body: JSON.stringify({
      recognizedText: ["Camera Pro", "service plan"],
      fallbackCategory: "services"
    })
  });
  if (cameraDraft.provider !== "openai" || !cameraDraft.options.includes("كاميرا OpenAI")) {
    throw new Error("AI camera draft did not use the OpenAI provider.");
  }
  if (!receivedAuthorization.startsWith("Bearer test-openai-key")) {
    throw new Error("OpenAI provider did not send the configured bearer key.");
  }
  if (receivedResponses < 3) {
    throw new Error("OpenAI mock did not receive all expected requests.");
  }

  console.log("PASS AI provider smoke test", {
    comparisonID: comparison.id,
    openAIRequests: receivedResponses
  });
} finally {
  await new Promise((resolve) => mockOpenAI.close(resolve));
}
