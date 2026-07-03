from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws


ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "sources" / "partsouq" / "full_patrol_all_iab" / "Y60_1988_201350_General_Asia_LHD_HIGH_ROOF_WAGON_TD42_DX.progressive.json"


def make_expr(targets: list[dict]) -> str:
    return f"""
(async () => {{
  const targets = {json.dumps(targets, ensure_ascii=False)};
  const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
  const abs = (href, base) => new URL(href, base).href;
  const clean = value => (value || '').replace(/\\s+/g, ' ').trim();
  async function fetchDoc(url) {{
    let last = '';
    for (let attempt = 0; attempt < 4; attempt++) {{
      const response = await fetch(url, {{ credentials: 'include' }});
      last = await response.text();
      if (response.status === 200 && !/cf_chl|challenge-platform|Just a moment|Verify you are human|blocked/i.test(last)) {{
        return new DOMParser().parseFromString(last, 'text/html');
      }}
      await sleep(1500 + attempt * 1000);
    }}
    throw new Error('Verification Required: challenge/block page, not EPC unit');
  }}
  function tableData(doc) {{
    return [...doc.querySelectorAll('table')].map((table, idx) => ({{
      idx,
      headers: [...table.querySelectorAll('th')].map(th => clean(th.innerText)),
      rows: [...table.querySelectorAll('tr')]
        .map(tr => [...tr.children].map(td => clean(td.innerText)))
        .filter(row => row.length)
    }}));
  }}
  function parsePlate(title) {{
    const text = clean(title);
    const m = text.match(/^([0-9A-Z]+\\s+[A-Z0-9]+)\\s*:\\s*(.+)$/i);
    if (m) return {{ code: m[1], title: m[2] }};
    const parts = text.split(':');
    return {{ code: clean(parts.shift() || ''), title: clean(parts.join(':') || text) }};
  }}
  function parseParts(doc) {{
    const tables = tableData(doc);
    const table = tables.find(t => t.headers.includes('Number') && t.headers.includes('Quantity'))
      || tables.find(t => t.rows.some(r => r.length >= 6 && /^\\d/.test(r[0] || '')));
    if (!table) return [];
    const header = table.headers.length ? table.headers : table.rows[0];
    const index = Object.fromEntries(header.map((name, pos) => [clean(name), pos]));
    const rows = table.rows.slice(1);
    const cell = (row, name, fallback) => {{
      const pos = index[name];
      if (pos !== undefined && pos < row.length) return clean(row[pos]);
      return clean(row[fallback] || '');
    }};
    return rows.map(row => ({{
      part_number: cell(row, 'Number', 0),
      part_name_en: cell(row, 'Name', 1),
      reference_code: cell(row, 'Code', 2),
      quantity: cell(row, 'Quantity', 3),
      applicable_models: cell(row, 'Applicable Models', 4),
      specifications: [cell(row, 'Specification', 5), cell(row, 'Range', 6)].filter(Boolean).join(' | '),
      raw_cells: row
    }})).filter(row => row.part_number || row.part_name_en || row.reference_code);
  }}
  const units = [];
  const failures = [];
  for (const target of targets) {{
    try {{
      const doc = await fetchDoc(target.unit_url);
      const title = target.title || doc.title || '';
      const plate = parsePlate(title);
      const diagram = [...doc.querySelectorAll('a.fancybox[href], a[href*="/source/"], img[src*="/source/"]')]
        .map(node => abs(node.getAttribute('href') || node.getAttribute('src'), target.unit_url))
        .find(href => /\\.(gif|png|jpg|jpeg|webp)$/i.test(href)) || target.diagram_hint || '';
      units.push({{
        uid: target.uid,
        cid: target.cid,
        group_text: target.group_text,
        unit_url: target.unit_url,
        plate_code: plate.code,
        plate_title_en: plate.title,
        diagram_image_url: diagram,
        diagram_alt: title || doc.title,
        tables: tableData(doc),
        part_rows: parseParts(doc)
      }});
    }} catch (error) {{
      failures.push({{ unit: target, error: String(error && error.message || error) }});
    }}
    await sleep(200);
  }}
  return JSON.stringify({{ units, failures, extracted_at: new Date().toISOString() }});
}})()
"""


def uid_of_failure(failure: dict) -> str:
    return str(failure.get("unit", {}).get("uid", ""))


def main() -> None:
    data = json.loads(TARGET.read_text(encoding="utf-8"))
    existing_uids = {str(unit.get("uid", "")) for unit in data.get("units", []) if unit.get("uid")}
    failure_by_uid = {uid_of_failure(failure): failure for failure in data.get("failures", []) if uid_of_failure(failure)}
    targets_by_uid: dict[str, dict] = {}
    for unit in data.get("discovered_units", []):
        uid = str(unit.get("uid", ""))
        if uid and uid not in existing_uids:
            targets_by_uid[uid] = unit
    for failure in data.get("failures", []):
        unit = failure.get("unit", {})
        uid = str(unit.get("uid", ""))
        if uid and uid not in existing_uids:
            targets_by_uid[uid] = unit

    targets = list(targets_by_uid.values())
    sock = connect(get_page_ws(9222, "partsouq.com"))
    sock.settimeout(950)
    call(sock, 1, "Runtime.enable")

    added = 0
    new_failures: list[dict] = []
    for start in range(0, len(targets), 20):
        chunk = targets[start : start + 20]
        result = call(
            sock,
            100 + start,
            "Runtime.evaluate",
            {
                "expression": make_expr(chunk),
                "awaitPromise": True,
                "returnByValue": True,
                "timeout": 420000,
            },
        )
        inner = result.get("result", {}).get("result", {})
        if "exceptionDetails" in result or inner.get("subtype") == "error":
            for target in chunk:
                new_failures.append({"unit": target, "error": "Verification Required: CDP chunk failed"})
            continue
        payload = json.loads(inner.get("value") or "{}")
        units = payload.get("units", [])
        failed = payload.get("failures", [])
        data.setdefault("units", []).extend(units)
        added += len(units)
        extracted_uids = {str(unit.get("uid", "")) for unit in units}
        for failure in failed:
            uid = uid_of_failure(failure)
            if uid not in extracted_uids:
                new_failures.append(failure)
        current_uids = {str(unit.get("uid", "")) for unit in data.get("units", []) if unit.get("uid")}
        data["failures"] = [
            failure
            for failure in data.get("failures", [])
            if uid_of_failure(failure) and uid_of_failure(failure) not in current_uids
        ] + [
            failure
            for failure in new_failures
            if uid_of_failure(failure) and uid_of_failure(failure) not in current_uids
        ]
        data["extracted_at"] = datetime.now(timezone.utc).isoformat()
        TARGET.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({"chunk_start": start, "chunk_size": len(chunk), "added": len(units), "failed": len(failed)}, ensure_ascii=False))

    discovered = len(data.get("discovered_units", []))
    units_count = len(data.get("units", []))
    failures_count = len(data.get("failures", []))
    data["complete"] = discovered > 0 and units_count + failures_count >= discovered
    data["extracted_at"] = datetime.now(timezone.utc).isoformat()
    TARGET.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"targets": len(targets), "added": added, "discovered": discovered, "units": units_count, "failures": failures_count, "remaining": discovered - units_count - failures_count, "complete": data["complete"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
