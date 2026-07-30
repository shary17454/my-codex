const base = process.env.BASE_URL || "http://localhost:8787";
const token = process.env.WESH_ALRAY_API_TOKEN || "";

function headers(clientID, inviteCode) {
  const value = {
    "content-type": "application/json",
    "x-client-id": clientID
  };
  if (inviteCode) value["x-invite-code"] = inviteCode;
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

async function expectStatus(status, path, options = {}) {
  const response = await fetch(`${base}${path}`, options);
  const body = await response.json();
  if (response.status !== status) {
    throw new Error(
      `${options.method || "GET"} ${path} expected ${status}, received ${response.status}: ${JSON.stringify(body)}`
    );
  }
  return body;
}

const suffix = Date.now();
const health = await request("/health");
if (!health.ok || health.storage !== "local-json-development") {
  throw new Error("Health check did not identify the development storage.");
}

await expectStatus(400, "/api/v1/comparisons", {
  method: "POST",
  headers: headers(`duplicate-${suffix}`),
  body: JSON.stringify({
    title: "خيارات مكررة",
    options: [{ title: "آيفون" }, { title: "إيفون" }]
  })
});

const comparison = await request("/api/v1/comparisons", {
  method: "POST",
  headers: headers(`owner-public-${suffix}`),
  body: JSON.stringify({
    title: `آيفون أم سامسونج؟ ${suffix}`,
    details: "Smoke test",
    category: "phones",
    author: "Smoke",
    visibility: "publicRoom",
    options: [{ title: "آيفون" }, { title: "سامسونج" }]
  })
});

const optionID = comparison.options[0].id;
await expectStatus(400, `/api/v1/comparisons/${comparison.id}/votes`, {
  method: "POST",
  headers: headers(`long-reason-${suffix}`),
  body: JSON.stringify({ optionID, reason: "س".repeat(301) })
});

const voterHeaders = headers(`voter-${suffix}`);
const publicVote = await request(`/api/v1/comparisons/${comparison.id}/votes`, {
  method: "POST",
  headers: voterHeaders,
  body: JSON.stringify({
    optionID,
    author: "Smoke",
    reason: "الكاميرا أفضل",
    reasonCategory: "الكاميرا",
    isVerifiedExperience: true
  })
});
if (publicVote.comparison.voteTrend.length !== 1) {
  throw new Error("Public vote trend did not include the accepted vote.");
}
await expectStatus(409, `/api/v1/comparisons/${comparison.id}/votes`, {
  method: "POST",
  headers: voterHeaders,
  body: JSON.stringify({ optionID })
});

await request(`/api/v1/comparisons/${comparison.id}/comments`, {
  method: "POST",
  headers: headers(`commenter-${suffix}`),
  body: JSON.stringify({ author: "Smoke", text: "تعليق اختبار" })
});

const privateOwnerHeaders = headers(`owner-private-${suffix}`);
const privateComparison = await request("/api/v1/comparisons", {
  method: "POST",
  headers: privateOwnerHeaders,
  body: JSON.stringify({
    title: `غرفة خاصة ${suffix}`,
    category: "travel",
    visibility: "inviteCode",
    hideResultsUntilVote: true,
    options: [{ title: "الرياض" }, { title: "جدة" }]
  })
});
if (!privateComparison.inviteCode || privateComparison.visibility !== "inviteCode") {
  throw new Error("Private comparison did not receive an invite code.");
}

const list = await request("/api/v1/comparisons", {
  headers: headers(`reader-${suffix}`)
});
if (!list.comparisons.some((item) => item.id === comparison.id)) {
  throw new Error("Public comparison is missing from discovery.");
}
if (list.comparisons.some((item) => item.id === privateComparison.id)) {
  throw new Error("Private comparison leaked into public discovery.");
}

await expectStatus(404, `/api/v1/comparisons/${privateComparison.id}`, {
  headers: headers(`outsider-${suffix}`)
});
const hiddenPrivate = await request(`/api/v1/rooms/${privateComparison.inviteCode}`, {
  headers: headers(`guest-${suffix}`)
});
if (!hiddenPrivate.resultsHidden || hiddenPrivate.options.some((option) => option.votes !== 0)) {
  throw new Error("Private results should be hidden before the guest votes.");
}

const guestHeaders = headers(`guest-${suffix}`, privateComparison.inviteCode);
const privateVote = await request(`/api/v1/comparisons/${privateComparison.id}/votes`, {
  method: "POST",
  headers: guestHeaders,
  body: JSON.stringify({ optionID: privateComparison.options[0].id })
});
if (
  privateVote.comparison.resultsHidden ||
  privateVote.comparison.options[0].votes !== 1 ||
  privateVote.comparison.voteTrend.length !== 1
) {
  throw new Error("Results were not revealed to the voter.");
}

await request("/api/v1/reports", {
  method: "POST",
  headers: headers(`reporter-${suffix}`),
  body: JSON.stringify({
    contentID: comparison.id,
    contentType: "comparison",
    reason: "misleading",
    details: "بلاغ اختبار"
  })
});

await expectStatus(400, "/api/v1/ai/chat", {
  method: "POST",
  headers: headers(`ai-empty-${suffix}`),
  body: JSON.stringify({ prompt: "" })
});

const aiSearch = await request("/api/v1/ai/search", {
  method: "POST",
  headers: headers(`ai-search-${suffix}`),
  body: JSON.stringify({ query: "الكاميرا" })
});
if (!aiSearch.results.some((item) => item.id === comparison.id)) {
  throw new Error("AI search did not return the expected public comparison.");
}

const aiSummary = await request("/api/v1/ai/summarize", {
  method: "POST",
  headers: headers(`ai-summary-${suffix}`),
  body: JSON.stringify({ comparisonID: comparison.id })
});
if (!aiSummary.summary || aiSummary.summary.id !== comparison.id || aiSummary.summary.totalVotes !== 1) {
  throw new Error("AI summarize did not return the expected comparison summary.");
}

const aiChat = await request("/api/v1/ai/chat", {
  method: "POST",
  headers: headers(`ai-chat-${suffix}`),
  body: JSON.stringify({ prompt: "لخص مقارنة الكاميرا" })
});
if (!aiChat.answer.includes("إجابة ذكية") || !aiChat.sources.some((item) => item.id === comparison.id)) {
  throw new Error("AI chat did not produce a sourced answer.");
}

const aiSuggestions = await request("/api/v1/ai/suggestions", {
  method: "POST",
  headers: headers(`ai-suggestions-${suffix}`),
  body: JSON.stringify({})
});
if (!Array.isArray(aiSuggestions.suggestions)) {
  throw new Error("AI suggestions response shape is invalid.");
}

console.log("PASS backend smoke test", {
  publicComparisonID: comparison.id,
  privateComparisonID: privateComparison.id
});
