from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws
from cdp_extract_y60_batch import extract_one


ROOT = Path(__file__).resolve().parents[1]
QUEUE = ROOT / "sources" / "partsouq" / "patrol_extraction_queue.json"
OUT = ROOT / "sources" / "partsouq" / "full_patrol_all_iab"


def safe_name(item: dict) -> str:
    bits = [
        item.get("extract_id", ""),
        item.get("market", ""),
        item.get("body_style", ""),
        item.get("engine", ""),
        item.get("grade_or_frame", ""),
    ]
    name = "_".join(str(bit) for bit in bits if bit)
    safe = "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in name)
    while "__" in safe:
        safe = safe.replace("__", "_")
    return f"{safe.strip('_')[:170]}.progressive.json"


def existing_ids() -> set[str]:
    ids = set()
    for path in OUT.glob("*.progressive.json"):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if data.get("extract_id"):
                ids.add(str(data["extract_id"]))
        except Exception:
            continue
    return ids


def normalize_data(item: dict, data: dict) -> dict:
    units = data.get("units", [])
    failures = data.get("failures", []) + data.get("group_failures", [])
    discovered = []
    seen = set()
    for unit in units:
        uid = str(unit.get("uid", ""))
        key = uid or unit.get("unit_url", "")
        if key and key not in seen:
            seen.add(key)
            discovered.append(
                {
                    "cid": unit.get("cid", ""),
                    "diagram_hint": unit.get("diagram_image_url", ""),
                    "group_text": unit.get("group_text", ""),
                    "title": unit.get("plate_title_en", "") or unit.get("diagram_alt", ""),
                    "uid": uid,
                    "unit_url": unit.get("unit_url", ""),
                }
            )
    for failure in failures:
        unit = failure.get("unit", {})
        uid = str(unit.get("uid", ""))
        key = uid or unit.get("unit_url", "")
        if key and key not in seen:
            seen.add(key)
            discovered.append(unit)

    data["market"] = item.get("market", "")
    data["detected_generation"] = item.get("detected_generation", "")
    data["source_row"] = {
        "cells": item.get("cells", []),
        "raw_text": item.get("raw_text", ""),
        "vid": item.get("vid", ""),
        "vehicle_url": item.get("vehicle_url", ""),
    }
    data["category"] = item
    data["discovered_units"] = discovered
    data["complete"] = len(discovered) > 0 and len(units) + len(failures) >= len(discovered)
    data["extracted_at"] = datetime.now(timezone.utc).isoformat()
    return data


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=9222)
    parser.add_argument("--count", type=int, default=1)
    parser.add_argument("--start-index", type=int, default=0)
    parser.add_argument("--generation", default="")
    parser.add_argument("--force-id", default="")
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    queue = json.loads(QUEUE.read_text(encoding="utf-8"))["items"]
    done = existing_ids()
    candidates = []
    for index, item in enumerate(queue):
        if index < args.start_index:
            continue
        if args.generation and item.get("detected_generation") != args.generation:
            continue
        if args.force_id and item.get("extract_id") != args.force_id:
            continue
        if not args.force_id and item.get("extract_id") in done:
            continue
        candidates.append((index, item))
        if len(candidates) >= args.count:
            break

    sock = connect(get_page_ws(args.port, "partsouq.com"))
    sock.settimeout(950)
    call(sock, 1, "Runtime.enable")
    results = []
    for index, item in candidates:
        try:
            data = normalize_data(item, extract_one(sock, item, max_units=0))
            path = OUT / safe_name(item)
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
            results.append(
                {
                    "index": index,
                    "extract_id": item.get("extract_id"),
                    "file": str(path),
                    "units": len(data.get("units", [])),
                    "failures": len(data.get("failures", [])) + len(data.get("group_failures", [])),
                    "complete": data.get("complete"),
                }
            )
        except Exception as exc:
            results.append({"index": index, "extract_id": item.get("extract_id"), "error": str(exc)})
        print(json.dumps(results[-1], ensure_ascii=False))
    print(json.dumps({"processed": len(results), "results": results}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
