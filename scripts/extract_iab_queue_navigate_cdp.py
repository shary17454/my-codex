from __future__ import annotations

import argparse
import json
import time
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws
from extract_iab_queue_from_cdp import OUT, QUEUE, safe_name
from fill_iab_missing_from_cdp import make_expr


def complete_existing_ids() -> set[str]:
    ids = set()
    for path in OUT.glob("*.progressive.json"):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        discovered = len(data.get("discovered_units", []))
        if discovered and len(data.get("units", [])) + len(data.get("failures", [])) >= discovered:
            ids.add(str(data.get("extract_id", "")))
    return ids


def eval_json(sock, msg_id: int, expr: str, timeout: int = 60000) -> dict:
    result = call(sock, msg_id, "Runtime.evaluate", {"expression": expr, "returnByValue": True, "timeout": timeout})
    inner = result.get("result", {}).get("result", {})
    if inner.get("subtype") == "error" or "exceptionDetails" in result:
        raise RuntimeError(json.dumps(result, ensure_ascii=False)[:2000])
    return json.loads(inner.get("value") or "{}")


def navigate(sock, msg_id: int, url: str, wait: float = 5.0) -> None:
    call(sock, msg_id, "Page.navigate", {"url": url})
    time.sleep(wait)


PARSE_PAGE_EXPR = """
JSON.stringify((() => {
  const clean = value => (value || '').replace(/\\s+/g, ' ').trim();
  const abs = href => new URL(href, location.href).href;
  const vehicleLinks = [...document.querySelectorAll('a[href*="/catalog/genuine/vehicle?"]')]
    .map(a => ({ href: abs(a.getAttribute('href')), text: clean(a.innerText) }))
    .filter(x => x.href.includes('cid='));
  const unitsByKey = {};
  for (const a of document.querySelectorAll('a[href*="/catalog/genuine/unit?"]')) {
    const href = abs(a.getAttribute('href'));
    const url = new URL(href);
    const uid = url.searchParams.get('uid') || href;
    const text = clean(a.innerText);
    const existing = unitsByKey[uid] || { unit_url: href, uid, cid: url.searchParams.get('cid') || '', title: '', group_text: '', diagram_hint: '' };
    if (text && text.length > (existing.title || '').length) existing.title = text;
    unitsByKey[uid] = existing;
  }
  return {
    title: document.title,
    url: location.href,
    body: clean(document.body?.innerText || '').slice(0, 400),
    challenge: /cf_chl|challenge-platform|Just a moment|Verify you are human|blocked/i.test(document.documentElement.innerHTML),
    vehicleLinks,
    units: Object.values(unitsByKey)
  };
})())
"""


def discover_units(sock, item: dict) -> tuple[dict, list[dict]]:
    navigate(sock, 10, item["vehicle_url"], wait=8)
    first = eval_json(sock, 11, PARSE_PAGE_EXPR)
    if first.get("challenge") and not first.get("units") and not first.get("vehicleLinks"):
        time.sleep(8)
        first = eval_json(sock, 12, PARSE_PAGE_EXPR)
    groups = []
    seen_groups = set()
    for group in first.get("vehicleLinks", []):
        href = group.get("href", "")
        if href and href not in seen_groups:
            seen_groups.add(href)
            groups.append(group)

    units_by_uid: dict[str, dict] = {}
    def add_units(page: dict, group_text: str) -> None:
        for unit in page.get("units", []):
            uid = str(unit.get("uid") or unit.get("unit_url"))
            if not uid:
                continue
            current = units_by_uid.get(uid, {})
            merged = current | unit
            merged["group_text"] = group_text or current.get("group_text", "") or unit.get("group_text", "")
            if current.get("title") and len(current["title"]) > len(merged.get("title", "")):
                merged["title"] = current["title"]
            units_by_uid[uid] = merged

    add_units(first, "ENGINE MECHANICAL")
    for offset, group in enumerate(groups, start=20):
        text = group.get("text", "")
        if text == "CATEGORIES":
            continue
        navigate(sock, offset, group["href"], wait=3.5)
        page = eval_json(sock, offset + 1000, PARSE_PAGE_EXPR)
        add_units(page, text)
    return {"groups": groups, "first_page": first}, list(units_by_uid.values())


def extract_units(sock, targets: list[dict]) -> tuple[list[dict], list[dict]]:
    units: list[dict] = []
    failures: list[dict] = []
    for start in range(0, len(targets), 20):
        chunk = targets[start : start + 20]
        result = call(
            sock,
            50000 + start,
            "Runtime.evaluate",
            {"expression": make_expr(chunk), "awaitPromise": True, "returnByValue": True, "timeout": 420000},
        )
        inner = result.get("result", {}).get("result", {})
        if "exceptionDetails" in result or inner.get("subtype") == "error":
            failures.extend({"unit": target, "error": "Verification Required: CDP chunk failed"} for target in chunk)
            continue
        payload = json.loads(inner.get("value") or "{}")
        units.extend(payload.get("units", []))
        failures.extend(payload.get("failures", []))
        print(json.dumps({"chunk_start": start, "chunk_size": len(chunk), "units": len(payload.get("units", [])), "failures": len(payload.get("failures", []))}, ensure_ascii=False))
    return units, failures


def extract_units_incremental(sock, targets: list[dict], data: dict, path: Path) -> tuple[list[dict], list[dict]]:
    units: list[dict] = list(data.get("units", []))
    failures: list[dict] = list(data.get("failures", []))
    done_uids = {str(unit.get("uid", "")) for unit in units if unit.get("uid")}
    pending = [target for target in targets if str(target.get("uid", "")) not in done_uids]
    for start in range(0, len(pending), 20):
        chunk = pending[start : start + 20]
        result = call(
            sock,
            70000 + start,
            "Runtime.evaluate",
            {"expression": make_expr(chunk), "awaitPromise": True, "returnByValue": True, "timeout": 420000},
        )
        inner = result.get("result", {}).get("result", {})
        if "exceptionDetails" in result or inner.get("subtype") == "error":
            failed = [{"unit": target, "error": "Verification Required: CDP chunk failed"} for target in chunk]
            got_units = []
        else:
            payload = json.loads(inner.get("value") or "{}")
            got_units = payload.get("units", [])
            failed = payload.get("failures", [])
        units.extend(got_units)
        failures.extend(failed)
        data["units"] = units
        data["failures"] = failures
        data["complete"] = len(data.get("discovered_units", [])) > 0 and len(units) + len(failures) >= len(data.get("discovered_units", []))
        data["extracted_at"] = datetime.now(timezone.utc).isoformat()
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({"chunk_start": start, "chunk_size": len(chunk), "units": len(got_units), "failures": len(failed), "saved_units": len(units)}, ensure_ascii=False), flush=True)
    return units, failures


def build_data(item: dict, vehicle_page: dict, discovered: list[dict], units: list[dict], failures: list[dict]) -> dict:
    return {
        "extract_id": item.get("extract_id"),
        "market": item.get("market", ""),
        "detected_generation": item.get("detected_generation", ""),
        "source_row": {
            "cells": item.get("cells", []),
            "raw_text": item.get("raw_text", ""),
            "vid": item.get("vid", ""),
            "vehicle_url": item.get("vehicle_url", ""),
        },
        "category": item,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "extracted_at": datetime.now(timezone.utc).isoformat(),
        "source_vehicle_url": item.get("vehicle_url", ""),
        "vehicle_page": vehicle_page,
        "discovered_units": discovered,
        "units": units,
        "failures": failures,
        "group_failures": [],
        "complete": len(discovered) > 0 and len(units) + len(failures) >= len(discovered),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--count", type=int, default=1)
    parser.add_argument("--start-index", type=int, default=0)
    parser.add_argument("--force-id", default="")
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    queue = json.loads(QUEUE.read_text(encoding="utf-8"))["items"]
    complete_ids = complete_existing_ids()
    candidates = []
    for index, item in enumerate(queue):
        if index < args.start_index:
            continue
        if args.force_id and item.get("extract_id") != args.force_id:
            continue
        if not args.force_id and item.get("extract_id") in complete_ids:
            continue
        candidates.append((index, item))
        if len(candidates) >= args.count:
            break

    sock = connect(get_page_ws(args.port, "partsouq.com"))
    sock.settimeout(950)
    call(sock, 1, "Runtime.enable")
    call(sock, 2, "Page.enable")
    results = []
    for index, item in candidates:
        print(json.dumps({"index": index, "extract_id": item.get("extract_id"), "vehicle": item.get("raw_text")}, ensure_ascii=False))
        try:
            vehicle_page, discovered = discover_units(sock, item)
            units: list[dict] = []
            failures: list[dict] = []
            data = build_data(item, vehicle_page, discovered, units, failures)
            path = OUT / safe_name(item)
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
            units, failures = extract_units_incremental(sock, discovered, data, path)
            data["units"] = units
            data["failures"] = failures
            data["complete"] = len(discovered) > 0 and len(units) + len(failures) >= len(discovered)
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
            results.append({"index": index, "extract_id": item.get("extract_id"), "file": str(path), "discovered": len(discovered), "units": len(units), "failures": len(failures), "complete": data["complete"]})
        except Exception as exc:
            results.append({"index": index, "extract_id": item.get("extract_id"), "error": str(exc)})
        print(json.dumps(results[-1], ensure_ascii=False))
    print(json.dumps({"processed": len(results), "results": results}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
