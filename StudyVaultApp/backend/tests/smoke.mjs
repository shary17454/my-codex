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

async function requestText(path, options = {}) {
  const response = await fetch(`${base}${path}`, options);
  const body = await response.text();
  if (!response.ok) {
    throw new Error(`${options.method || "GET"} ${path} failed: ${response.status} ${body}`);
  }
  return { body, contentType: response.headers.get("content-type") || "" };
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
    expiresAt: new Date(Date.now() + 3 * 60 * 60 * 1000).toISOString(),
    options: [{ title: "آيفون" }, { title: "سامسونج" }]
  })
});

await request("/api/v1/devices", {
  method: "POST",
  headers: headers(`owner-public-${suffix}`),
  body: JSON.stringify({ platform: "ios", pushToken: "test-owner-token", notificationsEnabled: true })
});
await request("/api/v1/devices", {
  method: "POST",
  headers: headers(`follower-${suffix}`),
  body: JSON.stringify({ platform: "ios", pushToken: "test-follower-token", notificationsEnabled: true })
});
await request(`/api/v1/comparisons/${comparison.id}/follow`, {
  method: "POST",
  headers: headers(`follower-${suffix}`),
  body: JSON.stringify({})
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
await request(`/api/v1/comparisons/${comparison.id}/votes`, {
  method: "POST",
  headers: headers(`voter-two-${suffix}`),
  body: JSON.stringify({ optionID: comparison.options[1].id })
});
await request(`/api/v1/comparisons/${comparison.id}/votes`, {
  method: "POST",
  headers: headers(`voter-three-${suffix}`),
  body: JSON.stringify({ optionID: comparison.options[1].id })
});

const ownerNotifications = await request("/api/v1/notifications?includeScheduled=1", {
  headers: headers(`owner-public-${suffix}`)
});
if (!ownerNotifications.notifications.some((item) => item.type === "voteReceived" && item.comparisonID === comparison.id)) {
  throw new Error("Owner did not receive a vote notification.");
}
if (!ownerNotifications.notifications.some((item) => item.type === "leaderChanged" && item.comparisonID === comparison.id)) {
  throw new Error("Owner did not receive a leader-changed notification.");
}
if (!ownerNotifications.notifications.some((item) => item.type === "closingSoon" && item.comparisonID === comparison.id)) {
  throw new Error("Owner did not receive a scheduled closing notification.");
}
const voterNotifications = await request("/api/v1/notifications?includeScheduled=1", {
  headers: voterHeaders
});
if (!voterNotifications.notifications.some((item) => item.type === "outcomeFollowUp" && item.comparisonID === comparison.id)) {
  throw new Error("Voter did not receive an outcome follow-up reminder.");
}
const dispatchResult = await request("/api/v1/notifications/dispatch", {
  method: "POST",
  headers: headers(`dispatcher-${suffix}`),
  body: JSON.stringify({})
});
if (dispatchResult.configured !== false) {
  throw new Error("APNs dispatch should report disabled when APNs secrets are not configured.");
}

const overview = await request("/api/v1/admin/overview", {
  headers: headers(`admin-${suffix}`)
});
if (overview.comparisons < 1 || overview.votes < 3 || overview.openReports < 0) {
  throw new Error("Admin overview did not return expected operational counts.");
}
const metrics = await request("/api/v1/admin/metrics", {
  headers: headers(`admin-${suffix}`)
});
if (!metrics.rateLimit || typeof metrics.apns?.configured !== "boolean") {
  throw new Error("Admin metrics response shape is invalid.");
}
const backup = await request("/api/v1/admin/backups", {
  method: "POST",
  headers: headers(`admin-${suffix}`),
  body: JSON.stringify({})
});
if (!backup.ok || !backup.fileName) {
  throw new Error("Admin backup did not report a created backup file.");
}
await request("/api/v1/admin/blocked-clients", {
  method: "POST",
  headers: headers(`admin-${suffix}`),
  body: JSON.stringify({ clientID: `blocked-${suffix}`, reason: "smoke-test" })
});
await expectStatus(403, "/api/v1/comparisons", {
  method: "POST",
  headers: headers(`blocked-${suffix}`),
  body: JSON.stringify({
    title: "طلب يجب منعه",
    options: [{ title: "أ" }, { title: "ب" }]
  })
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

const publicPage = await requestText(`/c/${comparison.id}`);
if (!publicPage.contentType.includes("text/html") || !publicPage.body.includes(comparison.title)) {
  throw new Error("Public comparison page did not render the comparison.");
}
if (!publicPage.body.includes("weshalray://comparison/")) {
  throw new Error("Public comparison page did not include the app deep link.");
}
await expectStatus(404, `/c/${privateComparison.id}`);
const privatePage = await requestText(`/c/${privateComparison.id}?invite=${privateComparison.inviteCode}`, {
  headers: headers(`private-page-${suffix}`)
});
if (!privatePage.body.includes(privateComparison.title)) {
  throw new Error("Private comparison page did not render with an invite code.");
}
const aasa = await request("/.well-known/apple-app-site-association");
if (!aasa.applinks || !Array.isArray(aasa.applinks.details)) {
  throw new Error("Apple App Site Association response shape is invalid.");
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

const report = await request("/api/v1/reports", {
  method: "POST",
  headers: headers(`reporter-${suffix}`),
  body: JSON.stringify({
    contentID: comparison.id,
    contentType: "comparison",
    reason: "misleading",
    details: "بلاغ اختبار"
  })
});
const reportsList = await request("/api/v1/reports", {
  method: "GET",
  headers: headers(`reviewer-${suffix}`)
});
if (!reportsList.reports.some((item) => item.id === report.id && item.status === "open")) {
  throw new Error("Created report was not available for moderation review.");
}
const reviewedReport = await request(`/api/v1/reports/${report.id}`, {
  method: "PATCH",
  headers: headers(`reviewer-${suffix}`),
  body: JSON.stringify({ status: "resolved", reviewNote: "تمت مراجعة بلاغ الاختبار" })
});
if (reviewedReport.status !== "resolved") {
  throw new Error("Report moderation status was not updated.");
}

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
if (!aiSummary.summary || aiSummary.summary.id !== comparison.id || aiSummary.summary.totalVotes !== 3) {
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

const cameraDraft = await request("/api/v1/ai/camera-draft", {
  method: "POST",
  headers: headers(`ai-camera-${suffix}`),
  body: JSON.stringify({
    recognizedText: ["iPhone 15 Pro", "camera", "battery"],
    fallbackTitle: "آيفون أم بديل؟",
    fallbackCategory: "phones"
  })
});
if (
  cameraDraft.category !== "phones" ||
  !cameraDraft.options.includes("iPhone 15 Pro") ||
  !cameraDraft.criteria.includes("الكاميرا")
) {
  throw new Error("AI camera draft did not return expected options and criteria.");
}

console.log("PASS backend smoke test", {
  publicComparisonID: comparison.id,
  privateComparisonID: privateComparison.id
});
