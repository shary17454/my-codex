import http from "node:http";
import http2 from "node:http2";
import { createHash, createSign, randomBytes, randomUUID, timingSafeEqual } from "node:crypto";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const port = Number(process.env.PORT || 8787);
const dataFile = resolve(process.env.WESH_ALRAY_DATA_FILE || "data/store.json");
const backupDir = resolve(process.env.WESH_ALRAY_BACKUP_DIR || "data/backups");
const allowedOrigin = process.env.CORS_ORIGIN || "*";
const apiToken = process.env.WESH_ALRAY_API_TOKEN || "";
const rateWindowMs = Number(process.env.RATE_LIMIT_WINDOW_MS || 60_000);
const rateLimit = Number(process.env.RATE_LIMIT_MAX || 120);
const isProduction = process.env.NODE_ENV === "production";
const aiProvider = String(process.env.AI_PROVIDER || "local").trim().toLowerCase();
const openAIAPIKey = process.env.OPENAI_API_KEY || "";
const openAIModel = process.env.OPENAI_MODEL || "gpt-4.1-mini";
const openAIBaseURL = (process.env.OPENAI_API_BASE_URL || "https://api.openai.com/v1").replace(/\/+$/, "");
const aiRequestTimeoutMs = Number(process.env.AI_REQUEST_TIMEOUT_MS || 12_000);
const publicWebBaseURL = (process.env.WESH_ALRAY_PUBLIC_WEB_BASE_URL || "").replace(/\/+$/, "");
const appleAppSiteAppID = process.env.APPLE_APP_SITE_APP_ID || "";
const apnsKeyID = process.env.APNS_KEY_ID || "";
const apnsTeamID = process.env.APNS_TEAM_ID || "";
const apnsBundleID = process.env.APNS_BUNDLE_ID || "";
const apnsPrivateKeyBase64 = process.env.APNS_PRIVATE_KEY_BASE64 || "";
const apnsEnvironment = String(process.env.APNS_ENV || "sandbox").trim().toLowerCase();
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
if (!Number.isFinite(aiRequestTimeoutMs) || aiRequestTimeoutMs < 1_000 || aiRequestTimeoutMs > 30_000) {
  throw new Error("AI_REQUEST_TIMEOUT_MS must be between 1000 and 30000.");
}
if (isProduction && aiProvider === "openai" && !openAIAPIKey) {
  throw new Error("OPENAI_API_KEY is required when AI_PROVIDER=openai in production.");
}
if (isProduction && [apnsKeyID, apnsTeamID, apnsBundleID, apnsPrivateKeyBase64].some(Boolean) &&
    ![apnsKeyID, apnsTeamID, apnsBundleID, apnsPrivateKeyBase64].every(Boolean)) {
  throw new Error("APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, and APNS_PRIVATE_KEY_BASE64 must be set together.");
}

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
  "access-control-allow-origin": allowedOrigin,
  "access-control-allow-methods": "GET,POST,PATCH,OPTIONS",
  "access-control-allow-headers": "content-type,x-client-id,x-invite-code,authorization",
  "cache-control": "no-store",
  "x-content-type-options": "nosniff"
};

const htmlHeaders = {
  "content-type": "text/html; charset=utf-8",
  "cache-control": "public, max-age=60",
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer-when-downgrade",
  "content-security-policy": "default-src 'none'; img-src 'self' data:; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'"
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
    devices: [],
    notificationSubscriptions: [],
    notificationEvents: [],
    blockedClients: [],
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

function sendHTML(res, status, html) {
  res.writeHead(status, htmlHeaders);
  res.end(html);
}

function sendError(res, status, message) {
  send(res, status, { error: { message } });
}

function escapeHTML(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function absolutePublicURL(req, path) {
  if (publicWebBaseURL) return `${publicWebBaseURL}${path}`;
  const host = req.headers.host || `localhost:${port}`;
  const proto = host.startsWith("localhost") || host.startsWith("127.0.0.1") ? "http" : "https";
  return `${proto}://${host}${path}`;
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

function assertClientAllowed(store, req) {
  const hash = clientHash(req, true);
  if (store.blockedClients.some((client) => client.clientHash === hash && client.active !== false)) {
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

function leaderOptionIDFor(comparison, store) {
  const votes = store.votes.filter((vote) => vote.comparisonID === comparison.id);
  if (!votes.length) return null;
  const counts = new Map(comparison.options.map((option) => [option.id, 0]));
  for (const vote of votes) {
    counts.set(vote.optionID, (counts.get(vote.optionID) || 0) + 1);
  }
  return comparison.options
    .slice()
    .sort((lhs, rhs) => {
      const voteDiff = (counts.get(rhs.id) || 0) - (counts.get(lhs.id) || 0);
      return voteDiff || lhs.sortIndex - rhs.sortIndex;
    })[0]?.id || null;
}

function interestedClientHashes(store, comparison) {
  const targets = new Set();
  if (comparison.ownerClientHash) targets.add(comparison.ownerClientHash);
  for (const subscription of store.notificationSubscriptions) {
    if (subscription.comparisonID === comparison.id && subscription.enabled !== false) {
      targets.add(subscription.clientHash);
    }
  }
  return [...targets];
}

function enqueueNotification(store, notification) {
  const createdAt = notification.createdAt || new Date().toISOString();
  const event = {
    id: randomUUID(),
    type: notification.type || "system",
    comparisonID: notification.comparisonID || null,
    title: cleanText(notification.title, 140),
    body: cleanText(notification.body, 360),
    createdAt,
    deliverAt: notification.deliverAt || createdAt,
    targetClientHashes: Array.isArray(notification.targetClientHashes)
      ? notification.targetClientHashes.filter(Boolean)
      : [],
    readByClientHashes: []
  };
  if (!event.title || !event.body || !event.targetClientHashes.length) return null;
  store.notificationEvents.unshift(event);
  if (store.notificationEvents.length > 5_000) {
    store.notificationEvents.splice(5_000);
  }
  appendAudit(store, "notification.queued", {
    notificationID: event.id,
    type: event.type,
    comparisonID: event.comparisonID
  });
  return event;
}

function scheduleClosingNotification(store, comparison) {
  if (!comparison.expiresAt) return;
  const deliverAtDate = new Date(comparison.expiresAt);
  if (Number.isNaN(deliverAtDate.getTime())) return;
  deliverAtDate.setHours(deliverAtDate.getHours() - 1);
  if (deliverAtDate <= new Date()) return;
  const alreadyScheduled = store.notificationEvents.some((event) =>
    event.type === "closingSoon" && event.comparisonID === comparison.id
  );
  if (alreadyScheduled) return;
  enqueueNotification(store, {
    type: "closingSoon",
    comparisonID: comparison.id,
    title: "اقترب انتهاء المقارنة",
    body: `تبقى أقل من ساعة على انتهاء: ${comparison.title}`,
    deliverAt: deliverAtDate.toISOString(),
    targetClientHashes: interestedClientHashes(store, comparison)
  });
}

function scheduleOutcomeFollowUp(store, comparison, clientHashValue) {
  if (!clientHashValue) return;
  const deliverAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
  enqueueNotification(store, {
    type: "outcomeFollowUp",
    comparisonID: comparison.id,
    title: "وش اخترت بالنهاية؟",
    body: `سجّل رضاك بعد تجربة قرار: ${comparison.title}`,
    deliverAt,
    targetClientHashes: [clientHashValue]
  });
}

function apnsConfigured() {
  return Boolean(apnsKeyID && apnsTeamID && apnsBundleID && apnsPrivateKeyBase64);
}

function base64URL(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function apnsJWT() {
  const header = base64URL(JSON.stringify({ alg: "ES256", kid: apnsKeyID }));
  const claims = base64URL(JSON.stringify({ iss: apnsTeamID, iat: Math.floor(Date.now() / 1000) }));
  const signer = createSign("sha256");
  signer.update(`${header}.${claims}`);
  signer.end();
  const privateKey = Buffer.from(apnsPrivateKeyBase64, "base64").toString("utf8");
  const signature = signer
    .sign(privateKey, "base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  return `${header}.${claims}.${signature}`;
}

async function sendAPNSNotification(device, event) {
  if (!apnsConfigured() || !device.pushToken || device.notificationsEnabled === false) {
    return { sent: false, reason: "apns_not_configured_or_token_missing" };
  }
  const host = apnsEnvironment === "production" ? "https://api.push.apple.com" : "https://api.sandbox.push.apple.com";
  const client = http2.connect(host);
  const payload = JSON.stringify({
    aps: {
      alert: {
        title: event.title,
        body: event.body
      },
      sound: "default"
    },
    comparisonID: event.comparisonID,
    type: event.type
  });

  return await new Promise((resolve) => {
    const request = client.request({
      ":method": "POST",
      ":path": `/3/device/${device.pushToken}`,
      authorization: `bearer ${apnsJWT()}`,
      "apns-topic": apnsBundleID,
      "apns-push-type": "alert",
      "content-type": "application/json"
    });
    let responseStatus = 0;
    let responseBody = "";
    request.setEncoding("utf8");
    request.on("response", (headers) => {
      responseStatus = Number(headers[":status"] || 0);
    });
    request.on("data", (chunk) => {
      responseBody += chunk;
    });
    request.on("error", () => {
      client.close();
      resolve({ sent: false, reason: "apns_request_failed" });
    });
    request.on("end", () => {
      client.close();
      resolve({
        sent: responseStatus >= 200 && responseStatus < 300,
        status: responseStatus,
        reason: responseBody ? "apns_response" : null
      });
    });
    request.end(payload);
  });
}

async function dispatchDueNotifications(req, store) {
  requireAuth(req);
  const now = new Date();
  if (!apnsConfigured()) {
    return { configured: false, attempted: 0, sent: 0, message: "APNs secrets are not configured." };
  }
  const dueEvents = store.notificationEvents
    .filter((event) => new Date(event.deliverAt || event.createdAt) <= now)
    .filter((event) => !event.dispatchedAt)
    .slice(0, 50);
  let attempted = 0;
  let sent = 0;
  for (const event of dueEvents) {
    const targetDevices = store.devices.filter((device) => event.targetClientHashes?.includes(device.clientHash));
    for (const device of targetDevices) {
      attempted += 1;
      const result = await sendAPNSNotification(device, event);
      if (result.sent) sent += 1;
    }
    event.dispatchedAt = new Date().toISOString();
  }
  appendAudit(store, "notifications.dispatched", { attempted, sent });
  return { configured: true, attempted, sent };
}

function adminOverview(store) {
  const openReports = store.reports.filter((report) => report.status === "open").length;
  const activeBlocked = store.blockedClients.filter((client) => client.active !== false).length;
  return {
    comparisons: store.comparisons.length,
    publicComparisons: store.comparisons.filter((item) => (item.visibility || "publicRoom") === "publicRoom").length,
    privateComparisons: store.comparisons.filter((item) => (item.visibility || "publicRoom") !== "publicRoom").length,
    votes: store.votes.length,
    comments: store.comments.length,
    reports: store.reports.length,
    openReports,
    devices: store.devices.length,
    notificationSubscriptions: store.notificationSubscriptions.length,
    queuedNotifications: store.notificationEvents.length,
    blockedClients: activeBlocked,
    generatedAt: new Date().toISOString()
  };
}

function adminMetrics(store) {
  const now = Date.now();
  const last24h = new Date(now - 24 * 60 * 60 * 1000);
  const last7d = new Date(now - 7 * 24 * 60 * 60 * 1000);
  const recent = (items, field = "createdAt", since = last24h) =>
    items.filter((item) => new Date(item[field] || 0) >= since).length;
  return {
    last24Hours: {
      comparisons: recent(store.comparisons),
      votes: recent(store.votes),
      comments: recent(store.comments),
      reports: recent(store.reports)
    },
    last7Days: {
      comparisons: recent(store.comparisons, "createdAt", last7d),
      votes: recent(store.votes, "createdAt", last7d),
      comments: recent(store.comments, "createdAt", last7d),
      reports: recent(store.reports, "createdAt", last7d)
    },
    rateLimit: {
      windowMs: rateWindowMs,
      maxRequests: rateLimit,
      activeWindows: requestCounts.size
    },
    apns: {
      configured: apnsConfigured(),
      environment: apnsEnvironment
    }
  };
}

async function blockClient(req, store) {
  requireAuth(req);
  const body = await readBody(req);
  const rawClientID = cleanText(body.clientID, 200);
  const reason = cleanText(body.reason, 500) || "abuse";
  if (!rawClientID) throw new RequestError(400, "معرّف العميل مطلوب.");
  const hash = createHash("sha256").update(rawClientID, "utf8").digest("hex");
  const existing = store.blockedClients.find((client) => client.clientHash === hash);
  const now = new Date().toISOString();
  if (existing) {
    existing.active = true;
    existing.reason = reason;
    existing.updatedAt = now;
  } else {
    store.blockedClients.push({
      id: randomUUID(),
      clientHash: hash,
      reason,
      active: true,
      createdAt: now,
      updatedAt: now
    });
  }
  appendAudit(store, "admin.client_blocked", { reason });
  return { ok: true, clientHash: hash };
}

async function createBackup(req, store) {
  requireAuth(req);
  const createdAt = new Date().toISOString();
  await mkdir(backupDir, { recursive: true });
  const fileName = `wesh-alray-backup-${createdAt.replace(/[:.]/g, "-")}.json`;
  const backupPath = resolve(backupDir, fileName);
  await writeFile(backupPath, `${JSON.stringify({ createdAt, store }, null, 2)}\n`, {
    encoding: "utf8",
    mode: 0o600
  });
  appendAudit(store, "admin.backup_created", { fileName });
  return { ok: true, fileName, createdAt };
}

function comparisonSharePath(comparison) {
  const basePath = `/c/${comparison.id}`;
  if (comparison.inviteCode && (comparison.visibility || "publicRoom") !== "publicRoom") {
    return `${basePath}?invite=${encodeURIComponent(comparison.inviteCode)}`;
  }
  return basePath;
}

function renderComparisonPage(req, comparison, store, viewerHash = null) {
  const publicView = publicComparison(comparison, store, viewerHash);
  const sharePath = comparisonSharePath(comparison);
  const shareURL = absolutePublicURL(req, sharePath);
  const appURL = `weshalray://comparison/${encodeURIComponent(comparison.id)}${
    comparison.inviteCode && (comparison.visibility || "publicRoom") !== "publicRoom"
      ? `?invite=${encodeURIComponent(comparison.inviteCode)}`
      : ""
  }`;
  const options = (publicView.options || [])
    .slice()
    .sort((lhs, rhs) => Number(rhs.votes || 0) - Number(lhs.votes || 0));
  const totalVotes = Number(publicView.voteCount || 0);
  const winner = options[0];
  const title = escapeHTML(publicView.title || "مقارنة في وش الرأي");
  const details = escapeHTML(publicView.details || "قارن الخيارات وشاهد رأي المشاركين.");
  const rows = options.map((option) => {
    const votes = Number(option.votes || 0);
    const percentage = totalVotes > 0 ? Math.round((votes / totalVotes) * 100) : 0;
    return `
      <article class="option">
        <div class="option-title">${escapeHTML(option.title)}</div>
        <div class="option-value">${percentage}%</div>
        <div class="bar" aria-hidden="true"><span style="width:${percentage}%"></span></div>
        <div class="meta">${votes} صوت</div>
      </article>`;
  }).join("");
  const summary = totalVotes > 0 && winner
    ? `${escapeHTML(winner.title)} في الصدارة من أصل ${totalVotes} صوت.`
    : "بانتظار أول الأصوات لإظهار الاتجاه.";

  return `<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${title} - وش الرأي</title>
  <meta name="description" content="${details}">
  <meta property="og:title" content="${title}">
  <meta property="og:description" content="${escapeHTML(summary)}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="${escapeHTML(shareURL)}">
  <meta name="twitter:card" content="summary">
  <style>
    :root{color-scheme:dark;--bg:#0b0e13;--surface:#151a21;--line:rgba(255,255,255,.10);--text:#f7f8fa;--muted:#a8b0ba;--green:#27b58a;--gold:#d7ae63}
    *{box-sizing:border-box}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"SF Arabic","Segoe UI",sans-serif;background:radial-gradient(circle at 30% 10%,rgba(39,181,138,.20),transparent 32%),linear-gradient(180deg,#0b0e13,#07110f);color:var(--text)}
    main{width:min(760px,100%);margin:0 auto;padding:32px 18px 44px}.brand{display:flex;align-items:center;gap:12px;margin-bottom:28px}.logo{width:52px;height:52px;border-radius:18px;display:grid;place-items:center;background:linear-gradient(135deg,var(--green),#10241f);box-shadow:0 12px 36px rgba(39,181,138,.24)}
    h1{font-size:clamp(30px,8vw,54px);line-height:1.1;margin:0 0 12px}p{color:var(--muted);font-size:18px;line-height:1.8}.card{background:rgba(21,26,33,.88);border:1px solid var(--line);border-radius:28px;padding:24px;box-shadow:0 24px 80px rgba(0,0,0,.35)}
    .pill{display:inline-flex;gap:8px;align-items:center;color:var(--gold);font-weight:800;margin-bottom:12px}.summary{font-size:22px;color:var(--gold);font-weight:800}.grid{display:grid;gap:12px;margin-top:18px}.option{padding:16px;border:1px solid var(--line);border-radius:20px;background:rgba(255,255,255,.04)}.option-title{font-size:20px;font-weight:800}.option-value{font-size:32px;color:var(--green);font-weight:900}.bar{height:8px;border-radius:99px;background:rgba(255,255,255,.10);overflow:hidden}.bar span{display:block;height:100%;background:linear-gradient(90deg,var(--green),#56d2ad)}.meta{margin-top:8px;color:var(--muted)}
    .actions{display:grid;gap:12px;margin-top:22px}.button{display:block;text-align:center;text-decoration:none;border-radius:18px;padding:16px 18px;font-weight:900}.primary{background:linear-gradient(135deg,var(--green),#56d2ad);color:#06110e}.secondary{border:1px solid var(--line);color:var(--text);background:rgba(255,255,255,.05)}footer{margin-top:22px;color:var(--muted);font-size:14px;line-height:1.7}
  </style>
</head>
<body>
  <main>
    <div class="brand"><div class="logo">✓</div><div><strong>وش الرأي</strong><br><span style="color:var(--muted)">قرارك أوضح</span></div></div>
    <section class="card">
      <div class="pill">⌁ ${escapeHTML(publicView.category || "مقارنة")}</div>
      <h1>${title}</h1>
      <p>${details}</p>
      <div class="summary">${summary}</div>
      <div class="grid">${rows || "<p>لا توجد خيارات متاحة.</p>"}</div>
      <div class="actions">
        <a class="button primary" href="${escapeHTML(appURL)}">افتح في التطبيق</a>
        <a class="button secondary" href="https://wa.me/?text=${encodeURIComponent(`وش الرأي؟\n${publicView.title}\n${shareURL}`)}">مشاركة عبر WhatsApp</a>
        <a class="button secondary" href="https://twitter.com/intent/tweet?text=${encodeURIComponent(`وش الرأي؟ ${publicView.title}`)}&url=${encodeURIComponent(shareURL)}">مشاركة عبر X</a>
      </div>
    </section>
    <footer>النتيجة إرشادية وتعتمد على أصوات وأسباب المشاركين داخل المقارنة. لا تمثل تقييمًا رسميًا أو نتيجة علمية.</footer>
  </main>
</body>
</html>`;
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

function openAIEnabled() {
  return aiProvider === "openai" && Boolean(openAIAPIKey);
}

function compactAIContext(items) {
  return items.slice(0, 8).map((item) => ({
    id: item.id,
    title: item.title,
    category: item.category,
    state: item.state,
    totalVotes: item.totalVotes,
    reasonCount: item.reasonCount,
    summary: item.summary,
    options: item.options?.slice(0, 6).map((option) => ({
      title: option.title,
      votes: option.votes,
      percentage: option.percentage
    }))
  }));
}

function parseJSONFromText(text) {
  const clean = String(text || "").trim();
  if (!clean) return null;
  try {
    return JSON.parse(clean);
  } catch {
    const start = clean.indexOf("{");
    const end = clean.lastIndexOf("}");
    if (start === -1 || end === -1 || end <= start) return null;
    try {
      return JSON.parse(clean.slice(start, end + 1));
    } catch {
      return null;
    }
  }
}

function extractOpenAIText(payload) {
  if (typeof payload?.output_text === "string") return payload.output_text;
  const chunks = [];
  for (const item of payload?.output || []) {
    for (const content of item.content || []) {
      if (typeof content.text === "string") chunks.push(content.text);
    }
  }
  return chunks.join("\n").trim();
}

async function callOpenAI({ instructions, input, textFormat }) {
  if (!openAIEnabled()) return null;

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), aiRequestTimeoutMs);
  try {
    const response = await fetch(`${openAIBaseURL}/responses`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${openAIAPIKey}`
      },
      body: JSON.stringify({
        model: openAIModel,
        instructions,
        input,
        text: textFormat ? { format: textFormat } : undefined
      }),
      signal: controller.signal
    });

    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      console.error("openai_request_failed", {
        status: response.status,
        code: body?.error?.code || null
      });
      return null;
    }
    return extractOpenAIText(body);
  } catch (error) {
    console.error("openai_request_error", { name: error?.name || "Error" });
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

async function openAIChatAnswer(prompt, matches) {
  const text = await callOpenAI({
    instructions: [
      "أنت مساعد قرار داخل تطبيق وش الرأي.",
      "أجب بالعربية بإيجاز وبناءً على السياق المرسل فقط.",
      "لا تخترع بيانات أو نتائج. إذا لا يكفي السياق، قل ذلك بوضوح.",
      "لا تدّعي تنفيذ إجراء داخل التطبيق."
    ].join("\n"),
    input: JSON.stringify({
      userPrompt: prompt,
      allowedContext: compactAIContext(matches)
    })
  });
  return text && text.length >= 10 ? text.slice(0, 1600) : null;
}

async function openAISummary(summary) {
  const text = await callOpenAI({
    instructions: [
      "لخص المقارنة للمستخدم العربي في تطبيق وش الرأي.",
      "استخدم فقط البيانات المرسلة، واذكر أن الخلاصة إرشادية.",
      "ركز على المتصدر، الفارق، الأسباب، والملاحظات."
    ].join("\n"),
    input: JSON.stringify({ comparison: compactAIContext([summary])[0] })
  });
  return text && text.length >= 10 ? text.slice(0, 1600) : null;
}

async function aiChat(req, store) {
  const body = await readBody(req);
  const prompt = cleanText(body.prompt, 800);
  if (prompt.length < 2) throw new RequestError(400, "اكتب سؤالًا أوضح للمساعد.");
  const query = normalizeArabic(prompt);
  const matches = aiSearch(store, req, prompt);
  const providerAnswer = await openAIChatAnswer(prompt, matches);
  if (providerAnswer) {
    return {
      answer: providerAnswer,
      sources: matches.map((item) => ({ id: item.id, title: item.title })).slice(0, 4),
      provider: "openai",
      stored: false
    };
  }

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
    provider: "local",
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
  const summary = summarizeComparisonForAI(publicComparison(comparison, store, clientHash(req, false)));
  const aiSummary = await openAISummary(summary);
  return {
    summary,
    aiSummary,
    provider: aiSummary ? "openai" : "local",
    stored: false
  };
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

function inferCameraDraftCategory(text, fallbackCategory = "other") {
  const normalized = normalizeArabic(text);
  if (normalized.includes("ايفون") || normalized.includes("سامسونج") || normalized.includes("جوال") || normalized.includes("هاتف")) {
    return "phones";
  }
  if (normalized.includes("سياره") || normalized.includes("كامري") || normalized.includes("اكورد") || normalized.includes("تويوتا")) {
    return "cars";
  }
  if (normalized.includes("مطعم") || normalized.includes("وجبه") || normalized.includes("قهوه") || normalized.includes("برجر")) {
    return "restaurants";
  }
  if (normalized.includes("لابتوب") || normalized.includes("ماك") || normalized.includes("ويندوز") || normalized.includes("كمبيوتر")) {
    return "laptops";
  }
  if (normalized.includes("اشتراك") || normalized.includes("باقه") || normalized.includes("نتفلكس") || normalized.includes("شاهد")) {
    return "subscriptions";
  }
  if (normalized.includes("خدمه") || normalized.includes("ضمان") || normalized.includes("صيانه")) {
    return "services";
  }
  return fallbackCategory;
}

function criteriaForCameraCategory(category) {
  if (category === "phones") return ["السعر", "الكاميرا", "البطارية", "سهولة الاستخدام"];
  if (category === "cars") return ["السعر", "الاعتمادية", "استهلاك الوقود", "إعادة البيع"];
  if (category === "restaurants") return ["السعر", "الطعم", "الخدمة", "الموقع"];
  if (category === "laptops") return ["السعر", "الأداء", "البطارية", "سهولة الحمل"];
  if (category === "subscriptions") return ["السعر", "المحتوى", "سهولة الاستخدام", "القيمة"];
  if (category === "services") return ["السعر", "جودة الخدمة", "الدعم", "السرعة"];
  return ["السعر", "الجودة", "التجربة", "القيمة"];
}

function fallbackOptionForCategory(category) {
  if (category === "phones") return "جوال بديل";
  if (category === "cars") return "سيارة بديلة";
  if (category === "restaurants") return "خيار مطعم آخر";
  if (category === "laptops") return "جهاز بديل";
  if (category === "subscriptions") return "اشتراك بديل";
  if (category === "services") return "خدمة بديلة";
  return "بديل مناسب";
}

function bestCameraOption(lines, category) {
  const candidate = lines
    .map((line) => cleanText(line, 80))
    .find((line) => line.length >= 3 && line.length <= 42);
  if (candidate) return candidate;
  if (category === "phones") return "الجهاز المصوّر";
  if (category === "cars") return "السيارة المصوّرة";
  if (category === "services") return "الخدمة المصوّرة";
  return "الخيار المصوّر";
}

function localCameraDraft(lines, fallbackCategory = "other") {
  const joinedText = lines.join(" ");
  const category = inferCameraDraftCategory(joinedText, fallbackCategory);
  const primaryOption = bestCameraOption(lines, category);
  const fallbackOption = fallbackOptionForCategory(category);
  const criteria = criteriaForCameraCategory(category);
  const tags = normalizeArabic(joinedText)
    .split(" ")
    .filter((word) => word.length >= 3)
    .filter((word, index, array) => array.indexOf(word) === index)
    .slice(0, 6);

  return {
    title: `${primaryOption} أم ${fallbackOption}؟`,
    details: `اقتراح Backend مبني على النص المستخرج من الصورة: ${lines.slice(0, 4).join("، ")}. راجع التفاصيل قبل النشر.`,
    primaryOption,
    options: [primaryOption, fallbackOption],
    tags,
    criteria,
    category,
    confidence: Math.min(0.96, Math.max(0.42, lines.length / 10)),
    provider: "local",
    stored: false
  };
}

async function openAICameraDraft(lines, fallbackDraft) {
  const text = await callOpenAI({
    instructions: [
      "أنت محلل قرار داخل تطبيق وش الرأي.",
      "استخرج من النصوص المصورة مسودة مقارنة عربية قابلة للتعديل.",
      "لا تستخدم إلا النصوص المرسلة. لا تضف حقائق خارجية.",
      "أعد خيارين إلى ستة خيارات ومعايير قرار مناسبة.",
      "اكتب عنوانًا قصيرًا بصيغة مقارنة."
    ].join("\n"),
    input: JSON.stringify({
      recognizedText: lines,
      fallbackDraft
    }),
    textFormat: {
      type: "json_schema",
      name: "wesh_alray_camera_draft",
      strict: true,
      schema: {
        type: "object",
        additionalProperties: false,
        required: ["title", "details", "primaryOption", "options", "tags", "criteria", "category", "confidence"],
        properties: {
          title: { type: "string" },
          details: { type: "string" },
          primaryOption: { type: "string" },
          options: {
            type: "array",
            minItems: 2,
            maxItems: 6,
            items: { type: "string" }
          },
          tags: {
            type: "array",
            maxItems: 8,
            items: { type: "string" }
          },
          criteria: {
            type: "array",
            minItems: 2,
            maxItems: 8,
            items: { type: "string" }
          },
          category: {
            type: "string",
            enum: ["phones", "cars", "restaurants", "laptops", "subscriptions", "services", "travel", "education", "health", "gaming", "home", "finance", "other"]
          },
          confidence: {
            type: "number",
            minimum: 0,
            maximum: 1
          }
        }
      }
    }
  });
  const parsed = parseJSONFromText(text);
  if (!parsed || !Array.isArray(parsed.options) || parsed.options.length < 2) return null;

  const title = cleanText(parsed.title, 160);
  const details = cleanText(parsed.details, 700);
  const primaryOption = cleanText(parsed.primaryOption, 80) || cleanText(parsed.options[0], 80);
  const options = parsed.options.map((option) => cleanText(option, 80)).filter(Boolean).slice(0, 6);
  const tags = Array.isArray(parsed.tags) ? parsed.tags.map((tag) => cleanText(tag, 40)).filter(Boolean).slice(0, 8) : [];
  const criteria = Array.isArray(parsed.criteria)
    ? parsed.criteria.map((criterion) => cleanText(criterion, 60)).filter(Boolean).slice(0, 8)
    : [];
  const category = cleanText(parsed.category, 40) || fallbackDraft.category;
  const confidence = Number(parsed.confidence);

  if (!title || options.length < 2 || !criteria.length) return null;

  return {
    title,
    details: details || fallbackDraft.details,
    primaryOption,
    options,
    tags,
    criteria,
    category,
    confidence: Number.isFinite(confidence) ? Math.min(1, Math.max(0, confidence)) : fallbackDraft.confidence,
    provider: "openai",
    stored: false
  };
}

async function aiCameraDraftEndpoint(req) {
  const body = await readBody(req);
  const lines = Array.isArray(body.recognizedText)
    ? body.recognizedText.map((line) => cleanText(line, 160)).filter(Boolean).slice(0, 12)
    : [];
  if (!lines.length) {
    throw new RequestError(400, "لا توجد نصوص كافية من الصورة.");
  }
  const fallbackCategory = cleanText(body.fallbackCategory, 40) || "other";
  const fallbackDraft = localCameraDraft(lines, fallbackCategory);
  return (await openAICameraDraft(lines, fallbackDraft)) || fallbackDraft;
}

async function createComparison(req, url, store) {
  requireAuth(req);
  assertClientAllowed(store, req);
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
  scheduleClosingNotification(store, comparison);
  appendAudit(store, "comparison.created", { comparisonID: comparison.id, visibility });
  return publicComparison(comparison, store, clientHash(req, false));
}

async function castVote(req, url, store, comparisonID) {
  requireAuth(req);
  assertClientAllowed(store, req);
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
  const previousLeaderID = leaderOptionIDFor(comparison, store);
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
  const nextLeaderID = leaderOptionIDFor(comparison, store);
  const nextLeader = comparison.options.find((item) => item.id === nextLeaderID);
  const targets = interestedClientHashes(store, comparison).filter((hash) => hash !== voterHash);

  enqueueNotification(store, {
    type: "voteReceived",
    comparisonID,
    title: "تصويت جديد",
    body: `وصل تصويت جديد على: ${comparison.title}`,
    targetClientHashes: targets
  });

  if (previousLeaderID && nextLeaderID && previousLeaderID !== nextLeaderID && nextLeader) {
    enqueueNotification(store, {
      type: "leaderChanged",
      comparisonID,
      title: "تغير المتصدر",
      body: `${nextLeader.title} أصبح المتصدر في: ${comparison.title}`,
      targetClientHashes: targets
    });
  }
  scheduleClosingNotification(store, comparison);
  scheduleOutcomeFollowUp(store, comparison, voterHash);

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
  assertClientAllowed(store, req);
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
  assertClientAllowed(store, req);
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

async function updateReportStatus(req, store, reportID) {
  requireAuth(req);
  const body = await readBody(req);
  const allowedStatuses = new Set(["open", "reviewing", "resolved", "dismissed"]);
  const status = cleanText(body.status, 40);
  if (!allowedStatuses.has(status)) {
    throw new RequestError(400, "حالة البلاغ غير صحيحة.");
  }
  const report = store.reports.find((item) => item.id === reportID);
  if (!report) {
    throw new RequestError(404, "البلاغ غير موجود.");
  }
  report.status = status;
  report.reviewNote = cleanText(body.reviewNote, 1000) || null;
  report.reviewedAt = new Date().toISOString();
  appendAudit(store, "report.status_updated", { reportID: report.id, status });
  return report;
}

async function registerDevice(req, store) {
  requireAuth(req);
  assertClientAllowed(store, req);
  const body = await readBody(req);
  const hash = clientHash(req, true);
  const platform = cleanText(body.platform, 20) || "ios";
  if (platform !== "ios") {
    throw new RequestError(400, "منصة الجهاز غير مدعومة.");
  }
  const pushToken = cleanText(body.pushToken, 300) || null;
  const existing = store.devices.find((device) => device.clientHash === hash);
  const now = new Date().toISOString();
  if (existing) {
    existing.platform = platform;
    existing.pushToken = pushToken || existing.pushToken || null;
    existing.notificationsEnabled = body.notificationsEnabled !== false;
    existing.updatedAt = now;
  } else {
    store.devices.push({
      id: randomUUID(),
      clientHash: hash,
      platform,
      pushToken,
      notificationsEnabled: body.notificationsEnabled !== false,
      createdAt: now,
      updatedAt: now
    });
  }
  appendAudit(store, "device.registered", { platform, hasPushToken: Boolean(pushToken) });
  return { ok: true };
}

async function followComparison(req, url, store, comparisonID) {
  requireAuth(req);
  assertClientAllowed(store, req);
  const comparison = findComparison(store, comparisonID);
  if (!comparison) throw new RequestError(404, "لم يتم العثور على المقارنة.");
  const body = await readBody(req);
  assertPrivateAccess(comparison, req, url, body);
  const hash = clientHash(req, true);
  const existing = store.notificationSubscriptions.find((item) =>
    item.clientHash === hash && item.comparisonID === comparisonID
  );
  const now = new Date().toISOString();
  if (existing) {
    existing.enabled = true;
    existing.updatedAt = now;
  } else {
    store.notificationSubscriptions.push({
      id: randomUUID(),
      clientHash: hash,
      comparisonID,
      enabled: true,
      createdAt: now,
      updatedAt: now
    });
  }
  scheduleClosingNotification(store, comparison);
  appendAudit(store, "comparison.followed", { comparisonID });
  return { ok: true };
}

function notificationsFor(req, url, store) {
  requireAuth(req);
  const hash = clientHash(req, true);
  const includeScheduled = url.searchParams.get("includeScheduled") === "1";
  const now = new Date();
  return {
    notifications: store.notificationEvents
      .filter((event) => event.targetClientHashes?.includes(hash))
      .filter((event) => includeScheduled || new Date(event.deliverAt || event.createdAt) <= now)
      .slice()
      .sort((lhs, rhs) => String(rhs.deliverAt || rhs.createdAt).localeCompare(String(lhs.deliverAt || lhs.createdAt)))
      .slice(0, 80)
      .map((event) => ({
        id: event.id,
        type: event.type,
        comparisonID: event.comparisonID,
        title: event.title,
        body: event.body,
        createdAt: event.createdAt,
        deliverAt: event.deliverAt,
        readAt: event.readByClientHashes?.includes(hash) ? event.readAt || event.createdAt : null
      }))
  };
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

    if (method === "GET" && url.pathname === "/.well-known/apple-app-site-association") {
      const appIDs = appleAppSiteAppID
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean);
      send(res, 200, {
        applinks: {
          apps: [],
          details: appIDs.map((appID) => ({
            appID,
            paths: ["/c/*", "/comparisons/*"]
          }))
        }
      });
      return;
    }

    if (method === "GET" && (segments[0] === "c" || segments[0] === "comparisons") && segments[1] && !segments[2]) {
      const store = await loadStore();
      const comparison = findComparison(store, cleanText(segments[1], 80));
      if (!comparison) throw new RequestError(404, "لم يتم العثور على المقارنة.");
      assertPrivateAccess(comparison, req, url);
      sendHTML(res, 200, renderComparisonPage(req, comparison, store, clientHash(req, false)));
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
      if (segments[3] === "camera-draft") {
        send(res, 200, await aiCameraDraftEndpoint(req));
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
      if (method === "POST" && comparisonID && segments[4] === "follow" && !segments[5]) {
        const result = await withStoreMutation((store) => followComparison(req, url, store, comparisonID));
        send(res, 200, result);
        return;
      }
      if (method === "POST" && comparisonID && segments[4] === "comments" && !segments[5]) {
        const result = await withStoreMutation((store) => addComment(req, url, store, comparisonID));
        send(res, 201, result);
        return;
      }
    }

    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "devices" && !segments[3]) {
      if (method !== "POST") throw new RequestError(404, "المسار غير موجود.");
      const result = await withStoreMutation((store) => registerDevice(req, store));
      send(res, 201, result);
      return;
    }

    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "notifications" && !segments[3]) {
      if (method !== "GET") throw new RequestError(404, "المسار غير موجود.");
      const store = await loadStore();
      send(res, 200, notificationsFor(req, url, store));
      return;
    }
    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "notifications" && segments[3] === "dispatch" && !segments[4]) {
      if (method !== "POST") throw new RequestError(404, "المسار غير موجود.");
      const result = await withStoreMutation((store) => dispatchDueNotifications(req, store));
      send(res, 200, result);
      return;
    }

    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "admin") {
      requireAuth(req);
      if (method === "GET" && segments[3] === "overview" && !segments[4]) {
        const store = await loadStore();
        send(res, 200, adminOverview(store));
        return;
      }
      if (method === "GET" && segments[3] === "metrics" && !segments[4]) {
        const store = await loadStore();
        send(res, 200, adminMetrics(store));
        return;
      }
      if (method === "POST" && segments[3] === "blocked-clients" && !segments[4]) {
        const result = await withStoreMutation((store) => blockClient(req, store));
        send(res, 201, result);
        return;
      }
      if (method === "POST" && segments[3] === "backups" && !segments[4]) {
        const result = await withStoreMutation((store) => createBackup(req, store));
        send(res, 201, result);
        return;
      }
    }

    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "reports") {
      const reportID = segments[3];
      if (method === "GET" && !reportID) {
        requireAuth(req);
        const store = await loadStore();
        const status = cleanText(url.searchParams.get("status"), 40);
        const reports = store.reports
          .filter((report) => !status || report.status === status)
          .slice()
          .sort((lhs, rhs) => String(rhs.createdAt).localeCompare(String(lhs.createdAt)));
        send(res, 200, { reports });
        return;
      }
      if (method === "POST" && !reportID) {
        const result = await withStoreMutation((store) => createReport(req, store));
        send(res, 201, result);
        return;
      }
      if (method === "PATCH" && reportID && !segments[4]) {
        const result = await withStoreMutation((store) => updateReportStatus(req, store, reportID));
        send(res, 200, result);
        return;
      }
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
