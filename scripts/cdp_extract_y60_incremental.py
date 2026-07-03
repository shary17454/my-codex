from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws
from cdp_extract_y60_batch import OUT, PROGRESS, QUEUE, safe_filename, update_progress


def js_string(value: object) -> str:
    return json.dumps(value, ensure_ascii=False)


DISCOVER_JS = r"""
(async () => {
  const item = ITEM_JSON;
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const abs = (href, base) => new URL(href, base).href;
  const clean = s => (s || '').replace(/\s+/g, ' ').trim();
  async function fetchDoc(url) {
    let last = '';
    for (let attempt = 0; attempt < 3; attempt++) {
      const res = await fetch(url, { credentials: 'include' });
      last = await res.text();
      if (!/Just a moment|Enable JavaScript|cf_chl|challenge-platform/i.test(last)) {
        return new DOMParser().parseFromString(last, 'text/html');
      }
      await sleep(2500 + attempt * 1500);
    }
    throw new Error('Cloudflare challenge or blocked page: ' + url);
  }
  function tableData(doc) {
    return [...doc.querySelectorAll('table')].map((table, idx) => ({
      idx,
      headers: [...table.querySelectorAll('th')].map(th => clean(th.innerText)),
      rows: [...table.querySelectorAll('tr')].map(tr => [...tr.children].map(td => clean(td.innerText))).filter(r => r.length)
    }));
  }
  function groupLinks(doc, base) {
    const out = [];
    const seen = new Set();
    for (const a of doc.querySelectorAll('a[href*="/catalog/genuine/vehicle?"]')) {
      const href = abs(a.getAttribute('href'), base);
      if (!href.includes('cid=') || seen.has(href)) continue;
      seen.add(href);
      const u = new URL(href);
      out.push({ href, text: clean(a.innerText), cid: u.searchParams.get('cid') || '', cname: u.searchParams.get('cname') || '' });
    }
    return out;
  }
  function unitLinks(doc, base, group) {
    const out = [];
    let pendingImage = '';
    for (const a of doc.querySelectorAll('a[href]')) {
      const href = abs(a.getAttribute('href'), base);
      if (/\.(gif|png|jpg|jpeg|webp)$/i.test(href) && href.includes('/source/')) {
        pendingImage = href;
        continue;
      }
      if (!href.includes('/catalog/genuine/unit?') || href === 'about:blank') continue;
      const text = clean(a.innerText);
      if (!text && !pendingImage) continue;
      const u = new URL(href);
      out.push({
        unit_url: href,
        uid: u.searchParams.get('uid') || '',
        cid: u.searchParams.get('cid') || group.cid || '',
        group_text: group.text || group.cname || '',
        title: text,
        diagram_hint: pendingImage
      });
      pendingImage = '';
    }
    return out;
  }
  const vehicleDoc = await fetchDoc(item.vehicle_url);
  const groups = groupLinks(vehicleDoc, item.vehicle_url);
  const allUnits = [];
  const seenUnits = new Set();
  const groupFailures = [];
  for (const group of [{href: item.vehicle_url, text: 'Initial group', cid: '', cname: ''}, ...groups]) {
    try {
      const doc = group.href === item.vehicle_url ? vehicleDoc : await fetchDoc(group.href);
      for (const unit of unitLinks(doc, group.href, group)) {
        const key = unit.uid || unit.unit_url;
        if (seenUnits.has(key)) continue;
        seenUnits.add(key);
        allUnits.push(unit);
      }
    } catch (err) {
      groupFailures.push({ group, error: String(err && err.message || err) });
    }
  }
  return JSON.stringify({ groups, units: allUnits, group_failures: groupFailures, vehicle_tables: tableData(vehicleDoc) });
})()
"""


UNIT_JS = r"""
(async () => {
  const unit = UNIT_JSON;
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const abs = (href, base) => new URL(href, base).href;
  const clean = s => (s || '').replace(/\s+/g, ' ').trim();
  async function fetchDoc(url) {
    let last = '';
    for (let attempt = 0; attempt < 3; attempt++) {
      const res = await fetch(url, { credentials: 'include' });
      last = await res.text();
      if (!/Just a moment|Enable JavaScript|cf_chl|challenge-platform/i.test(last)) {
        return new DOMParser().parseFromString(last, 'text/html');
      }
      await sleep(2000 + attempt * 1000);
    }
    throw new Error('Cloudflare challenge or blocked unit: ' + url);
  }
  function tableData(doc) {
    return [...doc.querySelectorAll('table')].map((table, idx) => ({
      idx,
      headers: [...table.querySelectorAll('th')].map(th => clean(th.innerText)),
      rows: [...table.querySelectorAll('tr')].map(tr => [...tr.children].map(td => clean(td.innerText))).filter(r => r.length)
    }));
  }
  function parseParts(doc) {
    const tables = tableData(doc);
    let table = tables.find(t => t.headers.includes('الرقم') && t.headers.includes('الكمية'));
    if (!table) table = tables.find(t => t.rows.some(r => r.length >= 6 && /^\d/.test(r[0] || '')));
    if (!table) return [];
    return table.rows
      .filter(r => r.length >= 4 && r[0] !== 'الرقم' && r[0] !== 'Part Number')
      .map(r => ({
        part_number: r[0] || '',
        part_name_en: r[1] || '',
        reference_code: r[2] || '',
        quantity: r[3] || '',
        applicable_models: r[4] || '',
        specifications: [r[5] || '', r[6] || ''].filter(Boolean).join(' | '),
        raw_cells: r
      }))
      .filter(r => r.part_number || r.part_name_en || r.reference_code);
  }
  function parsePlate(title) {
    const text = clean(title);
    const m = text.match(/^([0-9A-Z]+\s+[A-Z0-9]+)\s*:\s*(.+)$/i);
    if (m) return { code: m[1], title: m[2] };
    return { code: text.split(':')[0] || '', title: text.split(':').slice(1).join(':') || text };
  }
  const doc = await fetchDoc(unit.unit_url);
  const plate = parsePlate(unit.title || doc.title);
  const diagram = [...doc.querySelectorAll('a.fancybox[href], a[href*="/source/"], img[src*="/source/"]')]
    .map(x => abs(x.getAttribute('href') || x.getAttribute('src'), unit.unit_url))
    .find(h => /\.(gif|png|jpg|jpeg|webp)$/i.test(h)) || unit.diagram_hint || '';
  return JSON.stringify({
    uid: unit.uid,
    cid: unit.cid,
    group_text: unit.group_text,
    unit_url: unit.unit_url,
    plate_code: plate.code,
    plate_title_en: plate.title,
    diagram_image_url: diagram,
    diagram_alt: unit.title || doc.title,
    tables: tableData(doc),
    part_rows: parseParts(doc)
  });
})()
"""


def evaluate_json(sock, expr: str, msg_id: int, timeout_ms: int = 120000) -> dict:
    result = call(
        sock,
        msg_id,
        "Runtime.evaluate",
        {
            "expression": expr,
            "awaitPromise": True,
            "returnByValue": True,
            "timeout": timeout_ms,
        },
    )
    if "exceptionDetails" in result:
        raise RuntimeError(json.dumps(result, ensure_ascii=False)[:2000])
    inner = result.get("result", {}).get("result", {})
    value = inner.get("value")
    if value is None:
        raise RuntimeError(json.dumps(result, ensure_ascii=False)[:2000])
    if value == {}:
        raise RuntimeError(json.dumps(result, ensure_ascii=False)[:4000])
    if isinstance(value, str):
        return json.loads(value)
    return value


def load_progress() -> dict:
    if PROGRESS.exists():
        return json.loads(PROGRESS.read_text(encoding="utf-8"))
    return {"summary": {}, "items": json.loads(QUEUE.read_text(encoding="utf-8"))["items"]}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--index", type=int, required=True)
    parser.add_argument("--limit-units", type=int, default=0)
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    queue = json.loads(QUEUE.read_text(encoding="utf-8"))["items"]
    item = queue[args.index]
    progress = load_progress()
    by_id = {x.get("extract_id"): x for x in progress["items"]}

    ws_url = get_page_ws(args.port, "partsouq.com")
    sock = connect(ws_url)
    sock.settimeout(180)
    call(sock, 1, "Runtime.enable")

    discovery = evaluate_json(sock, DISCOVER_JS.replace("ITEM_JSON", js_string(item)), 20, timeout_ms=300000)
    if "units" not in discovery:
        raise RuntimeError(json.dumps(discovery, ensure_ascii=False)[:4000])
    unit_refs = discovery["units"][: args.limit_units or None]
    data = {
        "extract_id": item["extract_id"],
        "category": item,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "source_vehicle_url": item["vehicle_url"],
        "vehicle_page": {"groups": discovery["groups"], "tables": discovery["vehicle_tables"]},
        "units": [],
        "failures": [],
        "group_failures": discovery["group_failures"],
        "extraction_notes": ["incremental_cdp_extraction"],
    }
    path = OUT / safe_filename(item)
    for idx, unit in enumerate(unit_refs, start=1):
        try:
            parsed = evaluate_json(sock, UNIT_JS.replace("UNIT_JSON", js_string(unit)), 100 + idx, timeout_ms=120000)
            data["units"].append(parsed)
        except Exception as exc:
            data["failures"].append({"unit": unit, "error": str(exc)})
        data["extracted_at"] = datetime.now(timezone.utc).isoformat()
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({"unit": idx, "total": len(unit_refs), "parts": sum(len(u.get("part_rows", [])) for u in data["units"]), "failures": len(data["failures"])}, ensure_ascii=False))

    pitem = by_id.get(item["extract_id"], item)
    pitem["queue_index"] = args.index
    pitem["detail_status"] = "extracted" if data["units"] else "no_groups_visible_verification_required"
    pitem["extracted_units"] = len(data["units"])
    pitem["part_rows"] = sum(len(u.get("part_rows", [])) for u in data["units"])
    pitem["unit_failures"] = len(data["failures"]) + len(data["group_failures"])
    pitem["detail_file"] = str(path)
    update_progress(progress)
    print(json.dumps({"file": str(path), "units": pitem["extracted_units"], "parts": pitem["part_rows"], "failures": pitem["unit_failures"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
