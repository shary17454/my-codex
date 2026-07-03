from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws


ROOT = Path(__file__).resolve().parents[1]
QUEUE = ROOT / "sources" / "partsouq" / "y60_extraction_queue.json"
PROGRESS = ROOT / "sources" / "partsouq" / "y60_extraction_progress.json"
OUT = ROOT / "sources" / "partsouq" / "full_y60"


def safe_filename(item: dict) -> str:
    bits = [
        item.get("extract_id", ""),
        item.get("market", ""),
        item.get("body_style", ""),
        item.get("engine", ""),
        item.get("grade_or_frame", ""),
    ]
    name = "_".join(str(x) for x in bits if x)
    name = re.sub(r"[^A-Za-z0-9._-]+", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")
    return f"{name[:150]}.json"


def make_expr(item: dict, max_units: int = 0) -> str:
    item_json = json.dumps(item, ensure_ascii=False)
    max_units_json = json.dumps(max_units)
    return f"""
(async () => {{
  const item = {item_json};
  const maxUnits = {max_units_json};
  const startedAt = new Date().toISOString();
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const abs = (href, base) => new URL(href, base).href;
  const clean = s => (s || '').replace(/\\s+/g, ' ').trim();
  async function fetchDoc(url) {{
    let last = '';
    for (let attempt = 0; attempt < 3; attempt++) {{
      const res = await fetch(url, {{ credentials: 'include' }});
      last = await res.text();
      if (!/Just a moment|Enable JavaScript|cf_chl|challenge-platform/i.test(last)) {{
        return new DOMParser().parseFromString(last, 'text/html');
      }}
      await sleep(2500 + attempt * 1500);
    }}
    throw new Error('Cloudflare challenge or blocked page: ' + url);
  }}
  function tableData(doc) {{
    return [...doc.querySelectorAll('table')].map((table, idx) => ({{
      idx,
      headers: [...table.querySelectorAll('th')].map(th => clean(th.innerText)),
      rows: [...table.querySelectorAll('tr')].map(tr => [...tr.children].map(td => clean(td.innerText))).filter(r => r.length)
    }}));
  }}
  function groupLinks(doc, base) {{
    const out = [];
    const seen = new Set();
    for (const a of doc.querySelectorAll('a[href*="/catalog/genuine/vehicle?"]')) {{
      const href = abs(a.getAttribute('href'), base);
      if (!href.includes('cid=') || seen.has(href)) continue;
      seen.add(href);
      const u = new URL(href);
      out.push({{ href, text: clean(a.innerText), cid: u.searchParams.get('cid') || '', cname: u.searchParams.get('cname') || '' }});
    }}
    return out;
  }}
  function unitLinks(doc, base, group) {{
    const out = [];
    let pendingImage = '';
    for (const a of doc.querySelectorAll('a[href]')) {{
      const href = abs(a.getAttribute('href'), base);
      if (/\\.(gif|png|jpg|jpeg|webp)$/i.test(href) && href.includes('/source/')) {{
        pendingImage = href;
        continue;
      }}
      if (!href.includes('/catalog/genuine/unit?') || href === 'about:blank') continue;
      const text = clean(a.innerText);
      if (!text && !pendingImage) continue;
      const u = new URL(href);
      const uid = u.searchParams.get('uid') || '';
      const cid = u.searchParams.get('cid') || group.cid || '';
      out.push({{ unit_url: href, uid, cid, group_text: group.text || group.cname || '', title: text, diagram_hint: pendingImage }});
      pendingImage = '';
    }}
    return out;
  }}
  function parseParts(doc) {{
    const tables = tableData(doc);
    let table = tables.find(t => t.headers.includes('الرقم') && t.headers.includes('الكمية'));
    if (!table) table = tables.find(t => t.rows.some(r => r.length >= 6 && /^\\d/.test(r[0] || '')));
    if (!table) return [];
    const rows = table.rows.filter(r => r.length >= 4 && r[0] !== 'الرقم' && r[0] !== 'Part Number');
    return rows.map(r => ({{
      part_number: r[0] || '',
      part_name_en: r[1] || '',
      reference_code: r[2] || '',
      quantity: r[3] || '',
      applicable_models: r[4] || '',
      specifications: [r[5] || '', r[6] || ''].filter(Boolean).join(' | '),
      raw_cells: r
    }})).filter(r => r.part_number || r.part_name_en || r.reference_code);
  }}
  function parsePlate(title) {{
    const m = clean(title).match(/^([0-9A-Z]+\\s+[A-Z0-9]+)\\s*:\\s*(.+)$/i);
    if (m) return {{ code: m[1], title: m[2] }};
    return {{ code: clean(title).split(':')[0] || '', title: clean(title).split(':').slice(1).join(':') || clean(title) }};
  }}
  const vehicleDoc = await fetchDoc(item.vehicle_url);
  const groups = groupLinks(vehicleDoc, item.vehicle_url);
  const allUnits = [];
  const seenUnits = new Set();
  const groupFailures = [];
  for (const group of [{{href: item.vehicle_url, text: 'Initial group', cid: '', cname: ''}}, ...groups]) {{
    try {{
      const doc = group.href === item.vehicle_url ? vehicleDoc : await fetchDoc(group.href);
      for (const unit of unitLinks(doc, group.href, group)) {{
        const key = unit.uid || unit.unit_url;
        if (seenUnits.has(key)) continue;
        seenUnits.add(key);
        allUnits.push(unit);
      }}
    }} catch (err) {{
      groupFailures.push({{ group, error: String(err && err.message || err) }});
    }}
  }}
  const selectedUnits = maxUnits ? allUnits.slice(0, maxUnits) : allUnits;
  const units = [];
  const failures = [];
  for (let i = 0; i < selectedUnits.length; i++) {{
    const unit = selectedUnits[i];
    try {{
      const doc = await fetchDoc(unit.unit_url);
      const plate = parsePlate(unit.title || doc.title);
      const diagram = [...doc.querySelectorAll('a.fancybox[href], a[href*="/source/"], img[src*="/source/"]')]
        .map(x => abs(x.getAttribute('href') || x.getAttribute('src'), unit.unit_url))
        .find(h => /\\.(gif|png|jpg|jpeg|webp)$/i.test(h)) || unit.diagram_hint || '';
      units.push({{
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
      }});
    }} catch (err) {{
      failures.push({{ unit, error: String(err && err.message || err) }});
    }}
    await sleep(250);
  }}
  return JSON.stringify({{
    extract_id: item.extract_id,
    category: item,
    started_at: startedAt,
    extracted_at: new Date().toISOString(),
    source_vehicle_url: item.vehicle_url,
    vehicle_page: {{ groups, tables: tableData(vehicleDoc) }},
    units,
    failures,
    group_failures: groupFailures,
    extraction_notes: maxUnits ? ['limited test extraction'] : []
  }});
}})()
"""


def extract_one(sock, item: dict, max_units: int = 0) -> dict:
    result = call(
        sock,
        10,
        "Runtime.evaluate",
        {
            "expression": make_expr(item, max_units=max_units),
            "awaitPromise": True,
            "returnByValue": True,
            "timeout": 900000,
        },
    )
    inner = result.get("result", {}).get("result", {})
    if inner.get("subtype") == "error" or "exceptionDetails" in result:
        raise RuntimeError(json.dumps(result, ensure_ascii=False)[:2000])
    return json.loads(inner.get("value") or "{}")


def load_progress() -> dict:
    if PROGRESS.exists():
        return json.loads(PROGRESS.read_text(encoding="utf-8"))
    return {"summary": {}, "items": json.loads(QUEUE.read_text(encoding="utf-8"))["items"]}


def update_progress(progress: dict) -> None:
    items = progress["items"]
    extracted = [x for x in items if x.get("detail_status") == "extracted"]
    no_groups = [x for x in items if x.get("detail_status") == "no_groups_visible_verification_required"]
    progress["summary"] = {
        "total_vehicle_links": len(items),
        "detail_extracted_links": len(extracted),
        "no_groups_visible": len(no_groups),
        "pending_or_verification_required": len(items) - len(extracted),
        "extracted_units": sum(int(x.get("extracted_units") or 0) for x in items),
        "part_rows": sum(int(x.get("part_rows") or 0) for x in items),
        "unit_failures": sum(int(x.get("unit_failures") or 0) for x in items),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    PROGRESS.write_text(json.dumps(progress, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--start-index", type=int, default=0)
    parser.add_argument("--count", type=int, default=1)
    parser.add_argument("--max-units", type=int, default=0)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    queue = json.loads(QUEUE.read_text(encoding="utf-8"))["items"]
    progress = load_progress()
    progress_by_id = {x.get("extract_id"): x for x in progress["items"]}
    ws_url = get_page_ws(args.port, "partsouq.com")
    sock = connect(ws_url)
    sock.settimeout(950)
    call(sock, 1, "Runtime.enable")

    done = []
    candidates = [
        item
        for item in queue
        if item.get("extract_id")
        and item.get("vehicle_url")
        and (queue.index(item) >= args.start_index)
        and (
            args.force
            or progress_by_id.get(item.get("extract_id"), {}).get("detail_status")
            not in {"extracted", "no_groups_visible_verification_required"}
        )
    ][: args.count]
    for item in candidates:
        data = extract_one(sock, item, max_units=args.max_units)
        path = OUT / safe_filename(item)
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        pitem = progress_by_id.get(item["extract_id"], item)
        pitem["queue_index"] = queue.index(item)
        pitem["detail_status"] = "extracted" if data.get("units") else "no_groups_visible_verification_required"
        pitem["extracted_units"] = len(data.get("units", []))
        pitem["part_rows"] = sum(len(u.get("part_rows", [])) for u in data.get("units", []))
        pitem["unit_failures"] = len(data.get("failures", [])) + len(data.get("group_failures", []))
        pitem["detail_file"] = str(path)
        done.append({"extract_id": item["extract_id"], "file": str(path), "units": pitem["extracted_units"], "parts": pitem["part_rows"], "failures": pitem["unit_failures"]})
    update_progress(progress)
    print(json.dumps({"done": done, "summary": progress["summary"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
