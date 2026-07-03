from __future__ import annotations

import argparse
import json
import time
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws
from fill_iab_missing_from_cdp import uid_of_failure


ROOT = Path(__file__).resolve().parents[1]


PARSE_UNIT_EXPR = """
JSON.stringify((() => {
  const target = window.__codexUnitTarget || {};
  const clean = value => (value || '').replace(/\\s+/g, ' ').trim();
  const abs = href => new URL(href, location.href).href;
  function tableData() {
    return [...document.querySelectorAll('table')].map((table, idx) => ({
      idx,
      headers: [...table.querySelectorAll('th')].map(th => clean(th.innerText)),
      rows: [...table.querySelectorAll('tr')].map(tr => [...tr.children].map(td => clean(td.innerText))).filter(row => row.length)
    }));
  }
  function parsePlate(title) {
    const text = clean(title);
    const m = text.match(/^([0-9A-Z]+\\s+[A-Z0-9]+)\\s*:\\s*(.+)$/i);
    if (m) return { code: m[1], title: m[2] };
    const parts = text.split(':');
    return { code: clean(parts.shift() || ''), title: clean(parts.join(':') || text) };
  }
  function parseParts(tables) {
    const table = tables.find(t => t.headers.includes('Number') && t.headers.includes('Quantity'))
      || tables.find(t => t.rows.some(r => r.length >= 6 && /^\\d/.test(r[0] || '')));
    if (!table) return [];
    const header = table.headers.length ? table.headers : table.rows[0];
    const index = Object.fromEntries(header.map((name, pos) => [clean(name), pos]));
    const cell = (row, name, fallback) => {
      const pos = index[name];
      if (pos !== undefined && pos < row.length) return clean(row[pos]);
      return clean(row[fallback] || '');
    };
    return table.rows.slice(1).map(row => ({
      part_number: cell(row, 'Number', 0),
      part_name_en: cell(row, 'Name', 1),
      reference_code: cell(row, 'Code', 2),
      quantity: cell(row, 'Quantity', 3),
      applicable_models: cell(row, 'Applicable Models', 4),
      specifications: [cell(row, 'Specification', 5), cell(row, 'Range', 6)].filter(Boolean).join(' | '),
      raw_cells: row
    })).filter(row => row.part_number || row.part_name_en || row.reference_code);
  }
  const html = document.documentElement.innerHTML;
  const challenge = /cf_chl|challenge-platform|Just a moment|Verify you are human|blocked/i.test(html);
  const title = target.title || document.title || '';
  const plate = parsePlate(title);
  const tables = tableData();
  const diagram = [...document.querySelectorAll('a.fancybox[href], a[href*="/source/"], img[src*="/source/"]')]
    .map(node => abs(node.getAttribute('href') || node.getAttribute('src')))
    .find(href => /\\.(gif|png|jpg|jpeg|webp)$/i.test(href)) || target.diagram_hint || '';
  return {
    challenge,
    title: document.title,
    url: location.href,
    unit: {
      uid: target.uid,
      cid: target.cid,
      group_text: target.group_text,
      unit_url: target.unit_url,
      plate_code: plate.code,
      plate_title_en: plate.title,
      diagram_image_url: diagram,
      diagram_alt: title || document.title,
      tables,
      part_rows: parseParts(tables)
    }
  };
})())
"""


def open_partsouq_socket(port: int):
    sock = connect(get_page_ws(port, "partsouq.com"))
    sock.settimeout(120)
    call(sock, 1, "Runtime.enable")
    call(sock, 2, "Page.enable")
    return sock


def extract_unit(sock, target: dict, idx: int, wait: float) -> dict:
    call(sock, 1000 + idx * 3, "Page.navigate", {"url": target["unit_url"]})
    time.sleep(wait)
    call(
        sock,
        1001 + idx * 3,
        "Runtime.evaluate",
        {"expression": f"window.__codexUnitTarget = {json.dumps(target, ensure_ascii=False)}", "returnByValue": True},
    )
    result = call(sock, 1002 + idx * 3, "Runtime.evaluate", {"expression": PARSE_UNIT_EXPR, "returnByValue": True, "timeout": 60000})
    payload = json.loads(result.get("result", {}).get("result", {}).get("value") or "{}")
    unit = payload.get("unit", {})
    if not unit.get("tables"):
        raise RuntimeError("Verification Required: no EPC tables")
    return unit


def is_connection_error(exc: Exception) -> bool:
    text = str(exc).lower()
    return any(marker in text for marker in ("socket closed", "10053", "10054", "connection", "aborted"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path")
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--wait", type=float, default=2.5)
    parser.add_argument("--retry-failures", action="store_true")
    args = parser.parse_args()

    path = Path(args.path)
    if not path.is_absolute():
        path = ROOT / path
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    if args.retry_failures:
        data["failures"] = []
    existing = {str(unit.get("uid", "")) for unit in data.get("units", []) if unit.get("uid")}
    failed = {uid_of_failure(failure) for failure in data.get("failures", []) if uid_of_failure(failure)}
    targets = [
        unit for unit in data.get("discovered_units", [])
        if str(unit.get("uid", "")) not in existing and str(unit.get("uid", "")) not in failed
    ]
    if args.limit:
        targets = targets[: args.limit]

    sock = open_partsouq_socket(args.port)

    added = 0
    failures = 0
    for idx, target in enumerate(targets):
        try:
            try:
                unit = extract_unit(sock, target, idx, args.wait)
            except Exception as exc:
                if not is_connection_error(exc):
                    raise
                sock = open_partsouq_socket(args.port)
                unit = extract_unit(sock, target, idx + 100000, args.wait)
            data.setdefault("units", []).append(unit)
            added += 1
        except Exception as exc:
            data.setdefault("failures", []).append({"unit": target, "error": str(exc)})
            failures += 1
        discovered = len(data.get("discovered_units", []))
        data["complete"] = discovered > 0 and len(data.get("units", [])) + len(data.get("failures", [])) >= discovered
        data["extracted_at"] = datetime.now(timezone.utc).isoformat()
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({"idx": idx, "uid": target.get("uid"), "saved_units": len(data.get("units", [])), "failures": len(data.get("failures", [])), "complete": data["complete"]}, ensure_ascii=False), flush=True)

    print(json.dumps({"targets": len(targets), "added": added, "new_failures": failures, "units": len(data.get("units", [])), "failures": len(data.get("failures", [])), "complete": data.get("complete")}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
