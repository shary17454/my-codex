from __future__ import annotations

import argparse
import json
import time
from datetime import datetime, timezone

from cdp_eval import call, connect, get_page_ws
from cdp_extract_y60_batch import OUT, PROGRESS, QUEUE, safe_filename, update_progress


DOM_DISCOVER = r"""
(() => {
  const abs = href => new URL(href, location.href).href;
  const clean = s => (s || '').replace(/\s+/g, ' ').trim();
  function tableData() {
    return [...document.querySelectorAll('table')].map((table, idx) => ({
      idx,
      headers: [...table.querySelectorAll('th')].map(th => clean(th.innerText)),
      rows: [...table.querySelectorAll('tr')].map(tr => [...tr.children].map(td => clean(td.innerText))).filter(r => r.length)
    }));
  }
  const groups = [];
  const seenGroups = new Set();
  for (const a of document.querySelectorAll('a[href*="/catalog/genuine/vehicle?"]')) {
    const href = abs(a.getAttribute('href'));
    if (!href.includes('cid=') || seenGroups.has(href)) continue;
    seenGroups.add(href);
    const u = new URL(href);
    groups.push({ href, text: clean(a.innerText), cid: u.searchParams.get('cid') || '', cname: u.searchParams.get('cname') || '' });
  }
  const units = [];
  let pendingImage = '';
  for (const a of document.querySelectorAll('a[href]')) {
    const href = abs(a.getAttribute('href'));
    if (/\.(gif|png|jpg|jpeg|webp)$/i.test(href) && href.includes('/source/')) {
      pendingImage = href;
      continue;
    }
    if (!href.includes('/catalog/genuine/unit?') || href === 'about:blank') continue;
    const text = clean(a.innerText);
    if (!text && !pendingImage) continue;
    const u = new URL(href);
    units.push({
      unit_url: href,
      uid: u.searchParams.get('uid') || '',
      cid: u.searchParams.get('cid') || '',
      group_text: '',
      title: text,
      diagram_hint: pendingImage
    });
    pendingImage = '';
  }
  return JSON.stringify({ url: location.href, title: document.title, groups, units, tables: tableData() });
})()
"""


DOM_UNIT = r"""
(() => {
  const abs = href => new URL(href, location.href).href;
  const clean = s => (s || '').replace(/\s+/g, ' ').trim();
  function tableData() {
    return [...document.querySelectorAll('table')].map((table, idx) => ({
      idx,
      headers: [...table.querySelectorAll('th')].map(th => clean(th.innerText)),
      rows: [...table.querySelectorAll('tr')].map(tr => [...tr.children].map(td => clean(td.innerText))).filter(r => r.length)
    }));
  }
  function parseParts() {
    const tables = tableData();
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
  const titleLink = [...document.querySelectorAll('a')].map(a => clean(a.innerText)).find(t => /^[0-9A-Z]+\s+[A-Z0-9]+\s*:/.test(t)) || document.title;
  const plate = parsePlate(titleLink);
  const diagram = [...document.querySelectorAll('a.fancybox[href], a[href*="/source/"], img[src*="/source/"]')]
    .map(x => abs(x.getAttribute('href') || x.getAttribute('src')))
    .find(h => /\.(gif|png|jpg|jpeg|webp)$/i.test(h)) || '';
  return JSON.stringify({
    unit_url: location.href,
    plate_code: plate.code,
    plate_title_en: plate.title,
    diagram_image_url: diagram,
    diagram_alt: titleLink,
    tables: tableData(),
    part_rows: parseParts()
  });
})()
"""


def eval_json(sock, expr: str, msg_id: int) -> dict:
    result = call(sock, msg_id, "Runtime.evaluate", {"expression": expr, "returnByValue": True, "timeout": 30000})
    if "exceptionDetails" in result:
        raise RuntimeError(json.dumps(result, ensure_ascii=False)[:1200])
    value = result["result"]["result"].get("value") or "{}"
    return json.loads(value)


def navigate(sock, url: str, msg_id: int) -> None:
    call(sock, msg_id, "Page.navigate", {"url": url})
    for i in range(120):
        state = eval_json(
            sock,
            "JSON.stringify({ready:document.readyState,title:document.title,text:document.body.innerText.slice(0,200),unitLinks:[...document.links].filter(x=>x.href.includes('/catalog/genuine/unit?')).length,groupLinks:[...document.links].filter(x=>x.href.includes('/catalog/genuine/vehicle?')).length,partRows:[...document.querySelectorAll('table tr')].length})",
            msg_id + 1000 + i,
        )
        title = state.get("title", "")
        text = state.get("text", "")
        blocked = ("Just a moment" in title or title.strip() == "لحظة…" or "Enable JavaScript" in text) and "PartSouq" not in title
        has_catalog_dom = state.get("unitLinks", 0) > 0 or state.get("groupLinks", 0) > 0 or state.get("partRows", 0) > 2
        if state.get("ready") == "complete" and not blocked and has_catalog_dom:
            return
        time.sleep(1)
    raise RuntimeError("Page did not finish loading without challenge: " + url)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--index", type=int, required=True)
    parser.add_argument("--limit-units", type=int, default=0)
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    queue = json.loads(QUEUE.read_text(encoding="utf-8"))["items"]
    item = queue[args.index]
    progress = json.loads(PROGRESS.read_text(encoding="utf-8"))
    by_id = {x.get("extract_id"): x for x in progress["items"]}

    sock = connect(get_page_ws(args.port, "partsouq.com"))
    sock.settimeout(180)
    call(sock, 1, "Runtime.enable")
    call(sock, 2, "Page.enable")

    navigate(sock, item["vehicle_url"], 10)
    vehicle = eval_json(sock, DOM_DISCOVER, 20)
    unit_map = {}
    for unit in vehicle["units"]:
        unit_map[unit.get("uid") or unit["unit_url"]] = unit
    for group in vehicle["groups"]:
        navigate(sock, group["href"], 30 + len(unit_map))
        found = eval_json(sock, DOM_DISCOVER, 40 + len(unit_map))
        for unit in found["units"]:
            unit["group_text"] = group.get("text") or group.get("cname") or ""
            unit_map[unit.get("uid") or unit["unit_url"]] = unit

    units = list(unit_map.values())
    if args.limit_units:
        units = units[: args.limit_units]

    data = {
        "extract_id": item["extract_id"],
        "category": item,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "source_vehicle_url": item["vehicle_url"],
        "vehicle_page": {"groups": vehicle["groups"], "tables": vehicle["tables"]},
        "units": [],
        "failures": [],
        "group_failures": [],
        "extraction_notes": ["navigation_cdp_extraction"],
    }
    path = OUT / safe_filename(item)
    for idx, unit in enumerate(units, start=1):
        try:
            navigate(sock, unit["unit_url"], 10000 + idx * 10)
            parsed = eval_json(sock, DOM_UNIT, 20000 + idx)
            parsed.update({"uid": unit.get("uid", ""), "cid": unit.get("cid", ""), "group_text": unit.get("group_text", "")})
            data["units"].append(parsed)
        except Exception as exc:
            data["failures"].append({"unit": unit, "error": str(exc)})
        data["extracted_at"] = datetime.now(timezone.utc).isoformat()
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({"unit": idx, "total": len(units), "parts": sum(len(u.get("part_rows", [])) for u in data["units"]), "failures": len(data["failures"])}, ensure_ascii=False))

    pitem = by_id.get(item["extract_id"], item)
    pitem["queue_index"] = args.index
    pitem["detail_status"] = "extracted" if data["units"] else "no_groups_visible_verification_required"
    pitem["extracted_units"] = len(data["units"])
    pitem["part_rows"] = sum(len(u.get("part_rows", [])) for u in data["units"])
    pitem["unit_failures"] = len(data["failures"])
    pitem["detail_file"] = str(path)
    update_progress(progress)
    print(json.dumps({"file": str(path), "units": pitem["extracted_units"], "parts": pitem["part_rows"], "failures": pitem["unit_failures"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
