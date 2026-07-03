import fs from "node:fs/promises";
import path from "node:path";

const root = globalThis.nodeRepl?.cwd || ".";
const csvPath = path.join(root, "deliverables", "Y61_status", "Y61_discovered_models.csv");
const outDir = path.join(root, "sources", "partsouq", "full_y61_iab");

function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = "";
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    const next = text[i + 1];
    if (quoted) {
      if (ch === '"' && next === '"') {
        field += '"';
        i++;
      } else if (ch === '"') {
        quoted = false;
      } else {
        field += ch;
      }
    } else if (ch === '"') {
      quoted = true;
    } else if (ch === ",") {
      row.push(field);
      field = "";
    } else if (ch === "\n") {
      row.push(field);
      rows.push(row);
      row = [];
      field = "";
    } else if (ch !== "\r") {
      field += ch;
    }
  }
  if (field.length || row.length) {
    row.push(field);
    rows.push(row);
  }
  const headers = (rows.shift() || []).map((h, index) => index === 0 ? h.replace(/^\uFEFF/, "") : h);
  return rows.filter(r => r.length && r.some(Boolean)).map(r => Object.fromEntries(headers.map((h, i) => [h, r[i] || ""])));
}

function safeName(value) {
  return String(value || "")
    .replace(/[^A-Za-z0-9._-]+/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, 180) || "catalog";
}

function cssString(value) {
  return String(value || "").replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function cellsFromRaw(raw) {
  return String(raw || "").split("|").map(x => x.trim()).filter(x => x.length);
}

function categoryFromRow(row) {
  const cells = cellsFromRaw(row.raw_text);
  return {
    extract_id: `Y61_${row.year_filter || "YEAR"}_${row.vid}`,
    detected_generation: "Y61",
    year: row.year_filter || "",
    market: row.market || "",
    model_filter: row.model_filter || "",
    year_filter: row.year_filter || "",
    vehicle_url: row.vehicle_url || "",
    vid: row.vid || "",
    raw_text: row.raw_text || "",
    cells,
    body_style: cells[1] || "",
    engine: cells[2] || "",
    grade_or_frame: cells[3] || "",
    production_from: cells[6] || "",
    production_to: cells[7] || "",
  };
}

function outputPathFor(row) {
  const c = categoryFromRow(row);
  return path.join(
    outDir,
    `${safeName(["Y61", c.year, c.vid, c.market, c.body_style, c.engine, c.grade_or_frame].filter(Boolean).join("_"))}.progressive.json`,
  );
}

async function readJsonIfExists(file) {
  try {
    return JSON.parse(await fs.readFile(file, "utf8"));
  } catch {
    return null;
  }
}

async function discoverUnits(tab, row, outFile) {
  const category = categoryFromRow(row);
  let data = {
    extract_id: category.extract_id,
    market: row.market,
    detected_generation: "Y61",
    source_row: row,
    category,
    started_at: new Date().toISOString(),
    source_vehicle_url: row.vehicle_url,
    vehicle_page: {},
    discovered_units: [],
    units: [],
    failures: [],
    group_failures: [],
    discovery_complete: false,
    complete: false,
  };
  await fs.writeFile(outFile, JSON.stringify(data, null, 2), "utf8");
  await tab.goto(row.vehicle_url);
  try {
    await tab.playwright.waitForLoadState({ state: "domcontentloaded", timeoutMs: 8000 });
  } catch {}
  const categoryUrls = await tab.playwright.evaluate(() => {
    const clean = v => (v || "").replace(/\s+/g, " ").trim();
    const abs = href => new URL(href, location.href).href;
    const current = location.href;
    const links = [...document.querySelectorAll("a[href]")]
      .map(a => ({ text: clean(a.innerText), href: abs(a.getAttribute("href")) }))
      .filter(l => /\/catalog\/genuine\/vehicle\?/.test(l.href) && /[?&]cid=/.test(l.href) && l.text && !l.href.includes("cid=&"));
    return [{ text: "ENGINE MECHANICAL", href: current }].concat(links);
  }, undefined, { timeoutMs: 60000 });

  const unitMap = new Map();
  for (let catIndex = 0; catIndex < categoryUrls.length; catIndex++) {
    const cat = categoryUrls[catIndex];
    if (catIndex === 0) {
      await tab.goto(cat.href);
    } else {
      const locator = tab.playwright.locator(`a[href="${cssString(cat.href)}"]`);
      try {
        if (await locator.count() === 1) {
          await locator.click({ timeoutMs: 10000 });
          await tab.playwright.waitForTimeout(3500);
        } else {
          await tab.goto(cat.href);
        }
      } catch {
        await tab.goto(cat.href);
      }
    }
    try {
      await tab.playwright.waitForLoadState({ state: "domcontentloaded", timeoutMs: 5000 });
    } catch {}
    const units = await tab.playwright.evaluate((groupText) => {
      const clean = v => (v || "").replace(/\s+/g, " ").trim();
      const abs = href => new URL(href, location.href).href;
      return [...document.querySelectorAll("a[href]")]
        .map(a => ({ text: clean(a.innerText), href: abs(a.getAttribute("href")) }))
        .filter(l => /\/catalog\/genuine\/unit\?/.test(l.href) && l.text)
        .map(l => {
          const u = new URL(l.href);
          const m = l.text.match(/^([0-9A-Z]+\s+[0-9A-Z]+)\s*:\s*(.+)$/i);
          return {
            uid: u.searchParams.get("uid") || "",
            cid: u.searchParams.get("cid") || "",
            group_text: groupText,
            unit_url: l.href,
            title: l.text,
            plate_code: m ? m[1] : "",
            plate_title_en: m ? m[2] : l.text,
          };
        });
    }, cat.text, { timeoutMs: 60000 });
    for (const unit of units) {
      if (unit.uid && !unitMap.has(unit.uid)) unitMap.set(unit.uid, unit);
    }
    data.vehicle_page = { title: await tab.title(), url: await tab.url() };
    data.discovered_units = [...unitMap.values()];
    await fs.writeFile(outFile, JSON.stringify(data, null, 2), "utf8");
  }
  data.discovery_complete = true;
  await fs.writeFile(outFile, JSON.stringify(data, null, 2), "utf8");

  return data;
}

async function parseCurrentUnit(tab, target) {
  return await tab.playwright.evaluate((target) => {
    const clean = value => (value || "").replace(/\s+/g, " ").trim();
    const abs = href => new URL(href, location.href).href;
    const tables = [...document.querySelectorAll("table")].map((table, idx) => ({
      idx,
      headers: [...table.querySelectorAll("th")].map(th => clean(th.innerText)),
      rows: [...table.querySelectorAll("tr")].map(tr => [...tr.children].map(td => clean(td.innerText))).filter(row => row.length),
    }));
    function parseParts(tables) {
      const table = tables.find(t => t.headers.includes("Number") && t.headers.includes("Quantity"))
        || tables.find(t => t.rows.some(r => r.length >= 6 && /^\d/.test(r[0] || "")));
      if (!table) return [];
      const header = table.headers.length ? table.headers : table.rows[0];
      const index = Object.fromEntries(header.map((name, pos) => [clean(name), pos]));
      const cell = (row, name, fallback) => {
        const pos = index[name];
        return pos !== undefined && pos < row.length ? clean(row[pos]) : clean(row[fallback] || "");
      };
      return table.rows.slice(1).map(row => ({
        part_number: cell(row, "Number", 0),
        part_name_en: cell(row, "Name", 1),
        reference_code: cell(row, "Code", 2),
        quantity: cell(row, "Quantity", 3),
        applicable_models: cell(row, "Applicable Models", 4),
        specifications: [cell(row, "Specification", 5), cell(row, "Range", 6)].filter(Boolean).join(" | "),
        raw_cells: row,
      })).filter(row => row.part_number || row.part_name_en || row.reference_code);
    }
    const html = document.documentElement.innerHTML;
    const challenge = /cf_chl|challenge-platform|Just a moment|Verify you are human|blocked/i.test(html);
    const diagram = [...document.querySelectorAll('a.fancybox[href], a[href*="/source/"], img[src*="/source/"]')]
      .map(node => abs(node.getAttribute("href") || node.getAttribute("src")))
      .find(href => /\.(gif|png|jpg|jpeg|webp)$/i.test(href)) || "";
    return {
      challenge,
      unit: {
        uid: target.uid,
        cid: target.cid,
        group_text: target.group_text,
        unit_url: target.unit_url,
        plate_code: target.plate_code,
        plate_title_en: target.plate_title_en || target.title,
        diagram_image_url: diagram,
        diagram_alt: target.title || document.title,
        tables,
        part_rows: parseParts(tables),
      },
    };
  }, target, { timeoutMs: 60000 });
}

export async function runY61Extraction({ browser, limitVehicles = 1, limitUnits = 9999 } = {}) {
  await fs.mkdir(outDir, { recursive: true });
  const rows = parseCsv(await fs.readFile(csvPath, "utf8"));
  const existingFiles = await fs.readdir(outDir).catch(() => []);
  const completeVids = new Set();
  for (const name of existingFiles.filter(name => name.endsWith(".progressive.json"))) {
    const data = await readJsonIfExists(path.join(outDir, name));
    if (data?.complete) {
      const vid = String(data.category?.vid || data.source_row?.vid || "");
      if (vid) completeVids.add(vid);
    }
  }
  const tabs = await browser.tabs.list();
  const tab = tabs.length ? await browser.tabs.get(tabs[0].id) : await browser.tabs.new();
  const summary = [];

  for (const row of rows) {
    if (summary.length >= limitVehicles) break;
    if (completeVids.has(String(row.vid || ""))) continue;
    const outFile = outputPathFor(row);
    let data = await readJsonIfExists(outFile);
    if (data?.complete) continue;
    if (!data) {
      data = await discoverUnits(tab, row, outFile);
      await fs.writeFile(outFile, JSON.stringify(data, null, 2), "utf8");
    } else if (!data.discovery_complete) {
      data = await discoverUnits(tab, row, outFile);
    }

    const existing = new Set((data.units || []).map(u => String(u.uid || "")));
    const failed = new Set((data.failures || []).map(f => String((f.unit || f).uid || "")));
    const targets = (data.discovered_units || [])
      .filter(u => !existing.has(String(u.uid || "")) && !failed.has(String(u.uid || "")))
      .slice(0, limitUnits);

    let added = 0;
    let failures = 0;
    for (const target of targets) {
      try {
        await tab.goto(target.unit_url);
        await tab.playwright.waitForLoadState({ state: "domcontentloaded", timeoutMs: 60000 });
        const payload = await parseCurrentUnit(tab, target);
        if (payload.challenge) throw new Error("Verification Required: Cloudflare challenge");
        if (!payload.unit.tables?.length) throw new Error("Verification Required: no EPC tables");
        data.units.push(payload.unit);
        added++;
      } catch (err) {
        data.failures.push({ unit: target, error: String(err?.message || err) });
        failures++;
      }
      data.complete = (data.units.length + data.failures.length) >= data.discovered_units.length;
      data.extracted_at = new Date().toISOString();
      await fs.writeFile(outFile, JSON.stringify(data, null, 2), "utf8");
    }

    summary.push({
      vid: row.vid,
      file: outFile,
      discovered: data.discovered_units.length,
      units: data.units.length,
      failures: data.failures.length,
      added,
      new_failures: failures,
      complete: data.complete,
    });
  }
  return summary;
}
