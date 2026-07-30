import http from "node:http";
import { createHash, randomBytes, randomUUID, timingSafeEqual } from "node:crypto";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const port = Number(process.env.PORT || 8787);
const dataFile = resolve(process.env.WESH_ALRAY_DATA_FILE || "data/store.json");
const allowedOrigin = process.env.CORS_ORIGIN || "*";
const apiToken = process.env.WESH_ALRAY_API_TOKEN || "";
const rateWindowMs = Number(process.env.RATE_LIMIT_WINDOW_MS || 60_000);
const rateLimit = Number(process.env.RATE_LIMIT_MAX || 120);
const isProduction = process.env.NODE_ENV === "production";
const blockedClientHashes = new Set(
  String(process.env.WESH_ALRAY_BLOCKED_CLIENT_HASHES || "")
    .split(",")
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean)
);
const requestCounts = new Map();
let mutationQueue = Promise.resolve();

if (!Number.isInteger(port) || port < 1 || port > 65_535) {
  throw new Error("PORT must be an integer between 1 and 65535.");
}
if (!Number.isFinite(rateWindowMs) || rateWindowMs <= 0 || !Number.isFinite(rateLimit) || rateLimit <= 0) {
  throw new Error("Rate limit configuration is invalid.");
}
if (isProduction && !apiToken) {
  throw new Error("WESH_ALRAY_API_TOKEN is required when NODE_ENV=production.");
}
if (isProduction && allowedOrigin === "*") {
  throw new Error("CORS_ORIGIN must be explicit when NODE_ENV=production.");
}

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
  "access-control-allow-origin": allowedOrigin,
  "access-control-allow-methods": "GET,POST,OPTIONS",
  "access-control-allow-headers": "content-type,x-client-id,x-invite-code,authorization",
  "cache-control": "no-store",
  "x-content-type-options": "nosniff"
};

class RequestError extends Error {
  constructor(status, message) {
    super(message);
    this.name = "RequestError";
    this.status = status;
  }
}

function emptyStore() {
  return {
    comparisons: [],
    votes: [],
    comments: [],
    reports: [],
    auditEvents: []
  };
}

function normalizedStore(value) {
  const fallback = emptyStore();
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Stored data root must be an object.");
  }
  for (const key of Object.keys(fallback)) {
    if (value[key] !== undefined && !Array.isArray(value[key])) {
      throw new Error(`Stored data field ${key} must be an array.`);
    }
  }
  return Object.fromEntries(
    Object.keys(fallback).map((key) => [key, Array.isArray(value[key]) ? value[key] : []])
  );
}

async function loadStore() {
  try {
    return normalizedStore(JSON.parse(await readFile(dataFile, "utf8")));
  } catch (error) {
    if (error && typeof error === "object" && error.code === "ENOENT") {
      return emptyStore();
    }
    throw new Error("Local data store is unreadable.", { cause: error });
  }
}

async function saveStore(store) {
  await mkdir(dirname(dataFile), { recursive: true });
  const temporaryFile = `${dataFile}.${process.pid}.${randomUUID()}.tmp`;
  try {
    await writeFile(temporaryFile, `${JSON.stringify(store, null, 2)}\n`, {
      encoding: "utf8",
      mode: 0o600
    });
    await rename(temporaryFile, dataFile);
  } finally {
    await rm(temporaryFile, { force: true }).catch(() => {});
  }
}

function withStoreMutation(operation) {
  const queued = mutationQueue.then(async () => {
    const store = await loadStore();
    const result = await operation(store);
    await saveStore(store);
    return result;
  });
  mutationQueue = queued.catch(() => {});
  return queued;
}

function send(res, status, body) {
  res.writeHead(status, jsonHeaders);
  res.end(JSON.stringify(body));
}

function sendError(res, status, message) {
  send(res, status, { error: { message } });
}

function stringsEqual(lhs, rhs) {
  const left = Buffer.from(lhs);
  const right = Buffer.from(rhs);
  return left.length === right.length && timingSafeEqual(left, right);
}

function requireAuth(req) {
  if (!apiToken) return;
  const header = String(req.headers.authorization || "");
  if (!stringsEqual(header, `Bearer ${apiToken}`)) {
    throw new RequestError(401, "غير مصرح.");
  }
}

function rateLimitRequest(req) {
  const window = Math.floor(Date.now() / rateWindowMs);
  const key = `${req.socket.remoteAddress || "unknown"}:${window}`;
  const count = (requestCounts.get(key) || 0) + 1;
  requestCounts.set(key, count);
  if (requestCounts.size > 10_000) requestCounts.clear();
  if (count > rateLimit) {
    throw new RequestError(429, "طلبات كثيرة جدًا. حاول لاحقًا.");
  }
}

async function readBody(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 128 * 1024) {
      throw new RequestError(413, "حجم الطلب أكبر من المسموح.");
    }
    chunks.push(chunk);
  }
  const raw = Buffer.concat(chunks).toString("utf8");
  if (!raw) return {};
  try {
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new RequestError(400, "بيانات الطلب غير صحيحة.");
    }
    return parsed;
  } catch (error) {
    if (error instanceof RequestError) throw error;
    throw new RequestError(400, "تعذر قراءة بيانات الطلب.");
  }
}

function cleanText(value, maxLength = 500) {
  return String(value ?? "").trim().slice(0, maxLength);
}

function normalizeArabic(value) {
  return String(value ?? "")
    .toLocaleLowerCase("ar")
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ؤ/g, "و")
    .replace(/ئ/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/ـ/g, "")
    .replace(/[\u064B-\u065F\u0670\u06D6-\u06ED]/g, "")
    .replace(/[^\p{Script=Arabic}a-z0-9\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function parseOptionalDate(value) {
  if (value === undefined || value === null || value === "") return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new RequestError(400, "تاريخ انتهاء التصويت غير صحيح.");
  }
  return date.toISOString();
}

function clientHash(req, required = false) {
  const raw = cleanText(req.headers["x-client-id"], 200);
  if (!raw && required) {
    throw new RequestError(400, "معرّف العميل مطلوب لمنع التصويت المكرر.");
  }
  if (!raw) return null;
  const hash = createHash("sha256").update(raw, "utf8").digest("hex");
  if (blockedClientHashes.has(hash)) {
    throw new RequestError(403, "لا يمكن تنفيذ العملية من هذا الحساب.");
  }
  return hash;
}

function inviteCodeFrom(req, url, body = {}) {
  return cleanText(req.headers["x-invite-code"] || url.searchParams.get("invite") || body.inviteCode, 20)
    .toUpperCase();
}

function makeInviteCode(store) {
  for (let attempt = 0; attempt < 10; attempt += 1) {
    const code = randomBytes(5).toString("hex").toUpperCase();
    if (!store.comparisons.some((comparison) => comparison.inviteCode === code)) return code;
  }
  throw new Error("Unable to allocate a unique invite code.");
}

function findComparison(store, id) {
  return store.comparisons.find((comparison) => comparison.id === id);
}

function hasPrivateAccess(comparison, req, url, body = {}) {
  if ((comparison.visibility || "publicRoom") === "publicRoom") return true;
  const viewerHash = clientHash(req, false);
  if (viewerHash && viewerHash === comparison.ownerClientHash) return true;
  const suppliedCode = inviteCodeFrom(req, url, body);
  return Boolean(suppliedCode && comparison.inviteCode && stringsEqual(suppliedCode, comparison.inviteCode));
}

function assertPrivateAccess(comparison, req, url, body = {}) {
  if (!hasPrivateAccess(comparison, req, url, body)) {
    throw new RequestError(404, "لم يتم العثور على المقارنة.");
  }
}

function publicComparison(comparison, store, viewerHash = null) {
  const votes = store.votes.filter((vote) => vote.comparisonID === comparison.id);
  const comments = store.comments.filter((comment) => comment.comparisonID === comparison.id);
  const viewerHasVoted = Boolean(
    viewerHash && votes.some((vote) => vote.clientHash === viewerHash)
  );
  const resultsHidden = Boolean(comparison.hideResultsUntilVote && !viewerHasVoted);
  const options = comparison.options.map((option) => ({
    ...option,
    votes: resultsHidden ? 0 : votes.filter((vote) => vote.optionID === option.id).length
  }));
  const optionNames = new Map(comparison.options.map((option) => [option.id, option.title]));

  return {
    ...comparison,
    ownerClientHash: undefined,
    options,
    voteCount: votes.length,
    commentCount: resultsHidden ? 0 : comments.length,
    comments: resultsHidden
      ? []
      : comments.slice().sort((a, b) => b.createdAt.localeCompare(a.createdAt)),
    voteTrend: resultsHidden
      ? []
      : votes
          .slice()
          .sort((a, b) => a.createdAt.localeCompare(b.createdAt))
          .map((vote) => ({
            id: vote.id,
            optionID: vote.optionID,
            optionName: optionNames.get(vote.optionID) || "خيار",
            createdAt: vote.createdAt
          })),
    resultsHidden,
    viewerHasVoted
  };
}

function appendAudit(store, action, details = {}) {
  store.auditEvents.push({
    id: randomUUID(),
    action,
    details,
    createdAt: new Date().toISOString()
  });
  if (store.auditEvents.length > 10_000) {
    store.auditEvents.splice(0, store.auditEvents.length - 10_000);
  }
}

function publicComparisonsForAI(store, req) {
  const viewerHash = clientHash(req, false);
  return store.comparisons
    .filter((comparison) => (comparison.visibility || "publicRoom") === "publicRoom")
    .slice(0, 50)
    .map((comparison) => publicComparison(comparison, store, viewerHash));
}

function scoreAIComparison(comparison, query) {
  if (!query) return 0;
  const haystack = normalizeArabic(
    [
      comparison.title,
      comparison.details,
      comparison.category,
      ...(comparison.tags || []),
      ...(comparison.options || []).map((option) => option.title),
      ...(comparison.comments || []).map((comment) => comment.text)
    ].flat().join(" ")
  );
  const tokens = query.split(" ").filter((token) => token.length >= 2);
  return tokens.reduce((score, token) => score + (haystack.includes(token) ? 1 : 0), haystack.includes(query) ? 3 : 0);
}

function summarizeComparisonForAI(comparison) {
  const options = (comparison.options || []).slice().sort((a, b) => b.votes - a.votes);
  const winner = options[0];
  const runnerUp = options[1];
  const totalVotes = options.reduce((sum, option) => sum + Number(option.votes || 0), 0);
  const reasons = (comparison.comments || []).filter((comment) => comment.optionID);
  const winnerPercent = winner && totalVotes > 0 ? Math.round((winner.votes / totalVotes) * 100) : 0;
  const margin = winner && runnerUp && totalVotes > 0 ? Math.round(((winner.votes - runnerUp.votes) / totalVotes) * 100) : 0;
  const state = totalVotes < 10 ? "بيانات غير كافية" : margin < 5 ? "نتيجة متقاربة" : margin >= 25 ? "ميل واضح" : "ميل متوسط";

  return {
    id: comparison.id,
    title: comparison.title,
    state,
    totalVotes,
    reasonCount: reasons.length,
    winner: winner ? { title: winner.title, percentage: winnerPercent } : null,
    margin,
    summary: winner
      ? `${winner.title} في الصدارة بنسبة ${winnerPercent}%، والفارق ${margin} نقطة.`
      : "لا توجد أصوات كافية لتحديد متصدر."
  };
}

function aiSearch(store, req, query) {
  const normalizedQuery = normalizeArabic(query);
  return publicComparisonsForAI(store, req)
    .map((comparison) => ({ comparison, score: scoreAIComparison(comparison, normalizedQuery) }))
    .filter((item) => item.score > 0)
    .sort((lhs, rhs) => rhs.score - lhs.score)
    .slice(0, 6)
    .map((item) => summarizeComparisonForAI(item.comparison));
}

async function aiChat(req, store) {
  const body = await readBody(req);
  const prompt = cleanText(body.prompt, 800);
  if (prompt.length < 2) throw new RequestError(400, "اكتب سؤالًا أوضح للمساعد.");
  const query = normalizeArabic(prompt);
  const matches = aiSearch(store, req, prompt);
  const asksForSuggestion = ["اقترح", "اقتراح", "التالي", "وش اسوي", "تحسين"].some((term) => query.includes(term));
  const asksForSummary = ["لخص", "تلخيص", "ملخص", "خلاصه"].some((term) => query.includes(term));

  let answer;
  if (asksForSuggestion) {
    const weak = publicComparisonsForAI(store, req)
      .map(summarizeComparisonForAI)
      .filter((item) => item.state === "بيانات غير كافية" || item.state === "نتيجة متقاربة")
      .slice(0, 3);
    answer = [
      "إجابة ذكية إرشادية من بيانات التطبيق المتاحة.",
      "اقتراحي: ركّز على المقارنات التي تحتاج أصواتًا وأسبابًا أكثر، ولا تعتمد على النسبة وحدها.",
      ...weak.map((item) => `- ${item.title}: ${item.state}، الأصوات ${item.totalVotes}، الأسباب ${item.reasonCount}.`)
    ].join("\n");
  } else if (asksForSummary && matches[0]) {
    const item = matches[0];
    answer = [
      "إجابة ذكية إرشادية من بيانات التطبيق المتاحة.",
      `${item.title}`,
      item.summary,
      `الحالة: ${item.state}. الأصوات: ${item.totalVotes}. الأسباب: ${item.reasonCount}.`
    ].join("\n");
  } else if (matches.length) {
    answer = [
      "إجابة ذكية إرشادية من بيانات التطبيق المتاحة.",
      "أقرب النتائج:",
      ...matches.slice(0, 4).map((item) => `- ${item.title}: ${item.summary} الحالة ${item.state}.`)
    ].join("\n");
  } else {
    answer = "ما لقيت بيانات كافية داخل المقارنات العامة للإجابة بثقة. جرّب سؤالًا باسم خيار أو تصنيف محدد.";
  }

  return {
    answer,
    sources: matches.map((item) => ({ id: item.id, title: item.title })).slice(0, 4),
    stored: false
  };
}

async function aiSearchEndpoint(req, store) {
  const body = await readBody(req);
  const query = cleanText(body.query, 300);
  if (query.length < 2) throw new RequestError(400, "اكتب عبارة بحث أوضح.");
  return { results: aiSearch(store, req, query), stored: false };
}

async function aiSummarizeEndpoint(req, store) {
  const body = await readBody(req);
  const comparisonID = cleanText(body.comparisonID, 80);
  const comparison = findComparison(store, comparisonID);
  if (!comparison) throw new RequestError(404, "لم يتم العثور على المقارنة.");
  const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
  assertPrivateAccess(comparison, req, url, body);
  return { summary: summarizeComparisonForAI(publicComparison(comparison, store, clientHash(req, false))), stored: false };
}

async function aiSuggestionsEndpoint(req, store) {
  await readBody(req);
  const candidates = publicComparisonsForAI(store, req)
    .map(summarizeComparisonForAI)
    .filter((item) => item.state === "بيانات غير كافية" || item.state === "نتيجة متقاربة")
    .slice(0, 5);
  return {
    suggestions: candidates.map((item) => ({
      comparisonID: item.id,
      title: item.title,
      recommendation: item.totalVotes < 10
        ? "اطلب مشاركات أكثر قبل الاعتماد على النتيجة."
        : "الفارق متقارب؛ راجع الأسباب وأضف معايير قرار واضحة."
    })),
    stored: false
  };
}

async function createComparison(req, url, store) {
  requireAuth(req);
  const body = await readBody(req);
  const title = cleanText(body.title, 180);
  const details = cleanText(body.details, 1000);
  const rawOptions = Array.isArray(body.options) ? body.options : [];
  const optionTitles = rawOptions
    .map((option) => cleanText(option?.title ?? option, 120))
    .filter(Boolean);
  const uniqueOptions = new Set(optionTitles.map(normalizeArabic));
  const allowedVisibilities = new Set(["publicRoom", "linkOnly", "inviteCode"]);
  const visibility = cleanText(body.visibility, 20) || "publicRoom";

  if (!title) throw new RequestError(400, "عنوان المقارنة مطلوب.");
  if (optionTitles.length < 2 || optionTitles.length > 10) {
    throw new RequestError(400, "يجب إضافة من خيارين إلى عشرة خيارات.");
  }
  if (uniqueOptions.size !== optionTitles.length) {
    throw new RequestError(400, "أسماء الخيارات يجب أن تكون مختلفة.");
  }
  if (!allowedVisibilities.has(visibility)) {
    throw new RequestError(400, "نوع الغرفة غير صحيح.");
  }

  const now = new Date().toISOString();
  const comparison = {
    id: randomUUID(),
    title,
    details,
    category: cleanText(body.category, 40) || "other",
    author: Boolean(body.isAnonymous) ? "مجهول" : cleanText(body.author, 120) || "مجهول",
    createdAt: now,
    expiresAt: parseOptionalDate(body.expiresAt),
    isAnonymous: Boolean(body.isAnonymous),
    allowsComments: body.allowsComments !== false,
    allowsVoteReasons: body.allowsVoteReasons !== false,
    tags: Array.isArray(body.tags)
      ? [...new Set(body.tags.map((tag) => cleanText(tag, 40)).filter(Boolean))].slice(0, 10)
      : [],
    visibility,
    inviteCode: visibility === "publicRoom" ? null : makeInviteCode(store),
    hideResultsUntilVote: Boolean(body.hideResultsUntilVote),
    ownerClientHash: clientHash(req, false),
    options: optionTitles.map((option, index) => ({
      id: randomUUID(),
      title: option,
      sortIndex: index
    }))
  };

  store.comparisons.unshift(comparison);
  appendAudit(store, "comparison.created", { comparisonID: comparison.id, visibility });
  return publicComparison(comparison, store, clientHash(req, false));
}

async function castVote(req, url, store, comparisonID) {
  requireAuth(req);
  const comparison = findComparison(store, comparisonID);
  if (!comparison) throw new RequestError(404, "لم يتم العثور على المقارنة.");
  const body = await readBody(req);
  assertPrivateAccess(comparison, req, url, body);
  if (comparison.expiresAt && new Date(comparison.expiresAt) <= new Date()) {
    throw new RequestError(409, "انتهى التصويت في هذه المقارنة.");
  }

  const optionID = cleanText(body.optionID, 80);
  const option = comparison.options.find((item) => item.id === optionID);
  if (!option) throw new RequestError(400, "الخيار لا ينتمي إلى هذه المقارنة.");
  const voterHash = clientHash(req, true);
  if (store.votes.some((vote) => vote.comparisonID === comparisonID && vote.clientHash === voterHash)) {
    throw new RequestError(409, "سبق وصوّت في هذه المقارنة.");
  }

  const rawReason = String(body.reason ?? "").trim();
  if (rawReason.length > 300) {
    throw new RequestError(400, "السبب لا يمكن أن يتجاوز 300 حرف.");
  }
  const reason = comparison.allowsVoteReasons ? rawReason : "";
  const vote = {
    id: randomUUID(),
    comparisonID,
    optionID,
    clientHash: voterHash,
    reason: reason || null,
    reasonCategory: cleanText(body.reasonCategory, 80) || null,
    isVerifiedExperience: Boolean(body.isVerifiedExperience),
    isAnonymous: Boolean(body.isAnonymous),
    createdAt: new Date().toISOString()
  };
  store.votes.push(vote);

  if (vote.reason) {
    store.comments.unshift({
      id: randomUUID(),
      comparisonID,
      optionID,
      optionTitle: option.title,
      author: vote.isAnonymous ? "مجهول" : cleanText(body.author, 120) || "مستخدم",
      text: vote.reason,
      likes: 0,
      trustBadge: vote.isVerifiedExperience ? "مجرّب فعليًا" : null,
      reasonCategory: vote.reasonCategory,
      createdAt: vote.createdAt
    });
  }

  appendAudit(store, "vote.created", { comparisonID, optionID, voterHash });
  return {
    vote: { ...vote, clientHash: undefined },
    comparison: publicComparison(comparison, store, voterHash)
  };
}

async function addComment(req, url, store, comparisonID) {
  requireAuth(req);
  const comparison = findComparison(store, comparisonID);
  if (!comparison) throw new RequestError(404, "لم يتم العثور على المقارنة.");
  const body = await readBody(req);
  assertPrivateAccess(comparison, req, url, body);
  if (comparison.allowsComments === false) {
    throw new RequestError(403, "التعليقات مغلقة لهذه المقارنة.");
  }
  const rawText = String(body.text ?? "").trim();
  if (!rawText) throw new RequestError(400, "اكتب تعليقًا أولًا.");
  if (rawText.length > 800) throw new RequestError(400, "التعليق لا يمكن أن يتجاوز 800 حرف.");

  const comment = {
    id: randomUUID(),
    comparisonID,
    optionID: null,
    optionTitle: null,
    author: cleanText(body.author, 120) || "مستخدم",
    text: rawText,
    likes: 0,
    trustBadge: null,
    reasonCategory: null,
    createdAt: new Date().toISOString()
  };
  store.comments.unshift(comment);
  appendAudit(store, "comment.created", { comparisonID, commentID: comment.id });
  return comment;
}

async function createReport(req, store) {
  requireAuth(req);
  const body = await readBody(req);
  const contentID = cleanText(body.contentID, 80);
  const contentType = cleanText(body.contentType, 40);
  const reason = cleanText(body.reason, 40);
  if (!contentID || !contentType || !reason) {
    throw new RequestError(400, "بيانات البلاغ غير مكتملة.");
  }
  const report = {
    id: randomUUID(),
    contentID,
    contentType,
    reason,
    details: cleanText(body.details, 1000) || null,
    createdAt: new Date().toISOString(),
    status: "open"
  };
  store.reports.push(report);
  appendAudit(store, "report.created", { reportID: report.id, contentType });
  return report;
}

const server = http.createServer(async (req, res) => {
  const method = req.method || "GET";
  const path = req.url || "/";
  try {
    if (method === "OPTIONS") {
      res.writeHead(204, jsonHeaders);
      res.end();
      return;
    }
    rateLimitRequest(req);

    const url = new URL(path, `http://${req.headers.host || "localhost"}`);
    const segments = url.pathname.split("/").filter(Boolean);

    if (method === "GET" && url.pathname === "/health") {
      await loadStore();
      send(res, 200, { ok: true, service: "wesh-alray-backend", storage: "local-json-development" });
      return;
    }

    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "rooms" && segments[3]) {
      if (method !== "GET" || segments[4]) throw new RequestError(404, "المسار غير موجود.");
      const store = await loadStore();
      const inviteCode = cleanText(segments[3], 20).toUpperCase();
      const comparison = store.comparisons.find((item) => item.inviteCode === inviteCode);
      if (!comparison) throw new RequestError(404, "لم يتم العثور على المقارنة.");
      const viewerHash = clientHash(req, false);
      send(res, 200, publicComparison(comparison, store, viewerHash));
      return;
    }

    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "ai") {
      if (method !== "POST" || segments[4]) throw new RequestError(404, "المسار غير موجود.");
      requireAuth(req);
      const store = await loadStore();
      if (segments[3] === "chat") {
        send(res, 200, await aiChat(req, store));
        return;
      }
      if (segments[3] === "search") {
        send(res, 200, await aiSearchEndpoint(req, store));
        return;
      }
      if (segments[3] === "summarize") {
        send(res, 200, await aiSummarizeEndpoint(req, store));
        return;
      }
      if (segments[3] === "suggestions") {
        send(res, 200, await aiSuggestionsEndpoint(req, store));
        return;
      }
      throw new RequestError(404, "المسار غير موجود.");
    }

    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "comparisons") {
      const comparisonID = segments[3];
      if (method === "GET" && !comparisonID) {
        const store = await loadStore();
        const category = url.searchParams.get("category");
        const query = normalizeArabic(url.searchParams.get("q"));
        const viewerHash = clientHash(req, false);
        const comparisons = store.comparisons
          .filter((comparison) => (comparison.visibility || "publicRoom") === "publicRoom")
          .filter((comparison) => !category || category === "all" || comparison.category === category)
          .filter((comparison) => {
            if (!query) return true;
            const options = comparison.options.map((option) => option.title).join(" ");
            return normalizeArabic(`${comparison.title} ${comparison.details} ${options} ${(comparison.tags || []).join(" ")}`)
              .includes(query);
          })
          .map((comparison) => publicComparison(comparison, store, viewerHash));
        send(res, 200, { comparisons });
        return;
      }
      if (method === "POST" && !comparisonID) {
        const result = await withStoreMutation((store) => createComparison(req, url, store));
        send(res, 201, result);
        return;
      }
      if (method === "GET" && comparisonID && !segments[4]) {
        const store = await loadStore();
        const comparison = findComparison(store, comparisonID);
        if (!comparison) throw new RequestError(404, "لم يتم العثور على المقارنة.");
        assertPrivateAccess(comparison, req, url);
        send(res, 200, publicComparison(comparison, store, clientHash(req, false)));
        return;
      }
      if (method === "POST" && comparisonID && segments[4] === "votes" && !segments[5]) {
        const result = await withStoreMutation((store) => castVote(req, url, store, comparisonID));
        send(res, 201, result);
        return;
      }
      if (method === "POST" && comparisonID && segments[4] === "comments" && !segments[5]) {
        const result = await withStoreMutation((store) => addComment(req, url, store, comparisonID));
        send(res, 201, result);
        return;
      }
    }

    if (method === "POST" && url.pathname === "/api/v1/reports") {
      const result = await withStoreMutation((store) => createReport(req, store));
      send(res, 201, result);
      return;
    }

    throw new RequestError(404, "المسار غير موجود.");
  } catch (requestError) {
    if (requestError instanceof RequestError) {
      sendError(res, requestError.status, requestError.message);
      return;
    }
    console.error("request_failed", {
      method,
      path: path.split("?")[0],
      error: requestError instanceof Error ? requestError.message : "unknown"
    });
    sendError(res, 500, "تعذر إكمال العملية. حاول مرة أخرى.");
  }
});

await loadStore();
server.on("error", (error) => {
  console.error("server_start_failed", {
    code: error instanceof Error && "code" in error ? error.code : "unknown",
    message: error instanceof Error ? error.message : "unknown"
  });
  process.exitCode = 1;
});
server.listen(port, () => {
  console.log(`Wesh Alray development backend listening on http://localhost:${port}`);
});

function shutdown(signal) {
  console.log(`Received ${signal}; shutting down.`);
  server.close((closeError) => {
    process.exit(closeError ? 1 : 0);
  });
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));
