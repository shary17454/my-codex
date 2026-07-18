const base = process.env.BASE_URL || "http://localhost:8787";
const token = process.env.WESH_ALRAY_API_TOKEN || "";

const headers = {
  "content-type": "application/json",
  "x-client-id": `smoke-${Date.now()}`
};
if (token) headers.authorization = `Bearer ${token}`;

async function request(path, options = {}) {
  const response = await fetch(`${base}${path}`, options);
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`${options.method || "GET"} ${path} failed: ${response.status} ${JSON.stringify(body)}`);
  }
  return body;
}

const health = await request("/health");
if (!health.ok) throw new Error("Health check failed");

const comparison = await request("/api/v1/comparisons", {
  method: "POST",
  headers,
  body: JSON.stringify({
    title: "آيفون أم سامسونج؟",
    details: "Smoke test",
    category: "phones",
    author: "Smoke",
    options: [{ title: "آيفون" }, { title: "سامسونج" }]
  })
});

const optionID = comparison.options[0].id;
await request(`/api/v1/comparisons/${comparison.id}/votes`, {
  method: "POST",
  headers,
  body: JSON.stringify({
    optionID,
    author: "Smoke",
    reason: "الكاميرا أفضل",
    reasonCategory: "الكاميرا أفضل",
    isVerifiedExperience: true
  })
});

await request(`/api/v1/comparisons/${comparison.id}/comments`, {
  method: "POST",
  headers,
  body: JSON.stringify({ author: "Smoke", text: "تعليق اختبار" })
});

await request("/api/v1/reports", {
  method: "POST",
  headers,
  body: JSON.stringify({
    contentID: comparison.id,
    contentType: "comparison",
    reason: "misleading",
    details: "بلاغ اختبار"
  })
});

const list = await request("/api/v1/comparisons");
if (!Array.isArray(list.comparisons) || list.comparisons.length === 0) {
  throw new Error("Comparison list is empty");
}

console.log("PASS backend smoke test", comparison.id);
