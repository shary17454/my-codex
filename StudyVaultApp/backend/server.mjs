import http from "node:http";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { randomUUID } from "node:crypto";

const port = Number(process.env.PORT || 8787);
const dataFile = resolve(process.env.WESH_ALRAY_DATA_FILE || "backend/data/store.json");
const allowedOrigin = process.env.CORS_ORIGIN || "*";
const apiToken = process.env.WESH_ALRAY_API_TOKEN || "";
const rateWindowMs = Number(process.env.RATE_LIMIT_WINDOW_MS || 60_000);
const rateLimit = Number(process.env.RATE_LIMIT_MAX || 120);
const requestCounts = new Map();

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
  "access-control-allow-origin": allowedOrigin,
  "access-control-allow-methods": "GET,POST,PUT,DELETE,OPTIONS",
  "access-control-allow-headers": "content-type,x-client-id,authorization"
};

async function loadStore() {
  try {
    return JSON.parse(await readFile(dataFile, "utf8"));
  } catch {
    return {
      comparisons: [],
      votes: [],
      comments: [],
      reports: []
    };
  }
}

async function saveStore(store) {
  await mkdir(dirname(dataFile), { recursive: true });
  await writeFile(dataFile, JSON.stringify(store, null, 2) + "\n", "utf8");
}

function send(res, status, body) {
  res.writeHead(status, jsonHeaders);
  res.end(JSON.stringify(body));
}

function error(res, status, message) {
  send(res, status, { error: { message } });
}

function requireAuth(req, res) {
  if (!apiToken) return true;
  const header = String(req.headers.authorization || "");
  if (header === `Bearer ${apiToken}`) return true;
  error(res, 401, "غير مصرح.");
  return false;
}

function rateLimitRequest(req, res) {
  const key = `${req.socket.remoteAddress || "unknown"}:${Math.floor(Date.now() / rateWindowMs)}`;
  const count = (requestCounts.get(key) || 0) + 1;
  requestCounts.set(key, count);
  if (requestCounts.size > 10_000) requestCounts.clear();
  if (count > rateLimit) {
    error(res, 429, "طلبات كثيرة جدًا. حاول لاحقًا.");
    return false;
  }
  return true;
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
    if (Buffer.concat(chunks).length > 128 * 1024) {
      throw new Error("Request body is too large");
    }
  }
  const raw = Buffer.concat(chunks).toString("utf8");
  return raw ? JSON.parse(raw) : {};
}

function cleanText(value, maxLength = 500) {
  return String(value || "").trim().slice(0, maxLength);
}

function publicComparison(comparison, store) {
  const votes = store.votes.filter((vote) => vote.comparisonID === comparison.id);
  const comments = store.comments.filter((comment) => comment.comparisonID === comparison.id);
  const options = comparison.options.map((option) => ({
    ...option,
    votes: votes.filter((vote) => vote.optionID === option.id).length
  }));

  return {
    ...comparison,
    options,
    voteCount: votes.length,
    commentCount: comments.length,
    comments: comments.slice().sort((a, b) => b.createdAt.localeCompare(a.createdAt))
  };
}

function findComparison(store, id) {
  return store.comparisons.find((comparison) => comparison.id === id);
}

async function handleCreateComparison(req, res, store) {
  const body = await readBody(req);
  const title = cleanText(body.title, 140);
  const details = cleanText(body.details, 1000);
  const rawOptions = Array.isArray(body.options) ? body.options : [];
  const optionTitles = rawOptions.map((option) => cleanText(option.title || option, 120)).filter(Boolean);
  const uniqueOptions = new Set(optionTitles.map((option) => option.toLocaleLowerCase("ar")));

  if (!title) return error(res, 400, "اكتب عنوان المقارنة.");
  if (optionTitles.length < 2) return error(res, 400, "أضف خيارين على الأقل.");
  if (uniqueOptions.size !== optionTitles.length) return error(res, 400, "أسماء الخيارات لا يجب أن تكون مكررة.");

  const now = new Date().toISOString();
  const comparison = {
    id: randomUUID(),
    title,
    details,
    category: cleanText(body.category, 40) || "other",
    author: cleanText(body.author, 120) || "مجهول",
    createdAt: now,
    expiresAt: body.expiresAt || null,
    isAnonymous: Boolean(body.isAnonymous),
    allowsComments: body.allowsComments !== false,
    allowsVoteReasons: body.allowsVoteReasons !== false,
    tags: Array.isArray(body.tags) ? body.tags.map((tag) => cleanText(tag, 40)).filter(Boolean).slice(0, 10) : [],
    options: optionTitles.slice(0, 10).map((option) => ({
      id: randomUUID(),
      title: option
    }))
  };

  store.comparisons.unshift(comparison);
  await saveStore(store);
  send(res, 201, publicComparison(comparison, store));
}

async function handleVote(req, res, store, comparisonID) {
  const comparison = findComparison(store, comparisonID);
  if (!comparison) return error(res, 404, "لم يتم العثور على المقارنة.");
  if (comparison.expiresAt && new Date(comparison.expiresAt) < new Date()) {
    return error(res, 409, "انتهى التصويت في هذه المقارنة.");
  }

  const body = await readBody(req);
  const optionID = cleanText(body.optionID, 80);
  const option = comparison.options.find((item) => item.id === optionID);
  if (!option) return error(res, 400, "الخيار غير صحيح.");

  const clientID = cleanText(req.headers["x-client-id"] || body.clientID, 120);
  if (clientID && store.votes.some((vote) => vote.comparisonID === comparisonID && vote.clientID === clientID)) {
    return error(res, 409, "سبق لك التصويت في هذه المقارنة.");
  }

  const vote = {
    id: randomUUID(),
    comparisonID,
    optionID,
    clientID: clientID || null,
    reason: cleanText(body.reason, 500) || null,
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

  await saveStore(store);
  send(res, 201, { vote, comparison: publicComparison(comparison, store) });
}

async function handleComment(req, res, store, comparisonID) {
  const comparison = findComparison(store, comparisonID);
  if (!comparison) return error(res, 404, "لم يتم العثور على المقارنة.");
  if (comparison.allowsComments === false) return error(res, 403, "التعليقات مغلقة لهذه المقارنة.");

  const body = await readBody(req);
  const text = cleanText(body.text, 800);
  if (!text) return error(res, 400, "اكتب تعليقًا أولًا.");

  const comment = {
    id: randomUUID(),
    comparisonID,
    optionID: null,
    optionTitle: null,
    author: cleanText(body.author, 120) || "مستخدم",
    text,
    likes: 0,
    trustBadge: null,
    reasonCategory: null,
    createdAt: new Date().toISOString()
  };
  store.comments.unshift(comment);
  await saveStore(store);
  send(res, 201, comment);
}

async function handleReport(req, res, store) {
  const body = await readBody(req);
  const contentID = cleanText(body.contentID, 80);
  const contentType = cleanText(body.contentType, 40);
  const reason = cleanText(body.reason, 40);
  if (!contentID || !contentType || !reason) {
    return error(res, 400, "بيانات البلاغ غير مكتملة.");
  }

  const report = {
    id: randomUUID(),
    contentID,
    contentType,
    reason,
    details: cleanText(body.details, 1000) || null,
    createdAt: new Date().toISOString()
  };
  store.reports.push(report);
  await saveStore(store);
  send(res, 201, report);
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === "OPTIONS") {
      res.writeHead(204, jsonHeaders);
      res.end();
      return;
    }

    if (!rateLimitRequest(req, res)) return;

    const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
    const store = await loadStore();
    const segments = url.pathname.split("/").filter(Boolean);

    if (req.method === "GET" && url.pathname === "/health") {
      send(res, 200, { ok: true, service: "wesh-alray-backend" });
      return;
    }

    if (segments[0] === "api" && segments[1] === "v1" && segments[2] === "comparisons") {
      const comparisonID = segments[3];
      if (req.method === "GET" && !comparisonID) {
        const category = url.searchParams.get("category");
        const query = cleanText(url.searchParams.get("q"), 120).toLocaleLowerCase("ar");
        const comparisons = store.comparisons
          .filter((comparison) => !category || category === "all" || comparison.category === category)
          .filter((comparison) => !query || `${comparison.title} ${comparison.details}`.toLocaleLowerCase("ar").includes(query))
          .map((comparison) => publicComparison(comparison, store));
        send(res, 200, { comparisons });
        return;
      }
      if (req.method === "POST" && !comparisonID) {
        if (!requireAuth(req, res)) return;
        await handleCreateComparison(req, res, store);
        return;
      }
      if (req.method === "GET" && comparisonID && !segments[4]) {
        const comparison = findComparison(store, comparisonID);
        if (!comparison) return error(res, 404, "لم يتم العثور على المقارنة.");
        send(res, 200, publicComparison(comparison, store));
        return;
      }
      if (req.method === "POST" && comparisonID && segments[4] === "votes") {
        if (!requireAuth(req, res)) return;
        await handleVote(req, res, store, comparisonID);
        return;
      }
      if (req.method === "POST" && comparisonID && segments[4] === "comments") {
        if (!requireAuth(req, res)) return;
        await handleComment(req, res, store, comparisonID);
        return;
      }
    }

    if (req.method === "POST" && url.pathname === "/api/v1/reports") {
      if (!requireAuth(req, res)) return;
      await handleReport(req, res, store);
      return;
    }

    error(res, 404, "المسار غير موجود.");
  } catch (err) {
    error(res, 500, err instanceof Error ? err.message : "حدث خطأ غير متوقع.");
  }
});

server.listen(port, () => {
  console.log(`Wesh Alray backend listening on http://localhost:${port}`);
});
