from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from cdp_extract_y60_batch import extract_one, safe_filename, update_progress
from cdp_eval import call, connect, get_page_ws


ROOT = Path(__file__).resolve().parents[1]
QUEUE = ROOT / "sources" / "partsouq" / "patrol_extraction_queue.json"
PROGRESS = ROOT / "sources" / "partsouq" / "patrol_extraction_progress.json"
OUT = ROOT / "sources" / "partsouq" / "full_patrol_all"


def load_progress(queue_items: list[dict]) -> dict:
    if PROGRESS.exists():
        return json.loads(PROGRESS.read_text(encoding="utf-8"))
    return {"summary": {}, "items": queue_items}


def summarize(progress: dict) -> None:
    items = progress["items"]
    extracted = [x for x in items if x.get("detail_status") == "extracted"]
    no_groups = [x for x in items if x.get("detail_status") == "no_groups_visible_verification_required"]
    failed = [x for x in items if x.get("detail_status") == "failed_verification_required"]
    progress["summary"] = {
        "total_vehicle_links": len(items),
        "detail_extracted_links": len(extracted),
        "no_groups_visible": len(no_groups),
        "failed_verification_required": len(failed),
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

    queue = json.loads(QUEUE.read_text(encoding="utf-8"))["items"]
    progress = load_progress(queue)
    by_id = {x.get("extract_id"): x for x in progress["items"]}
    OUT.mkdir(parents=True, exist_ok=True)

    candidates = []
    for idx, item in enumerate(queue):
        if idx < args.start_index:
            continue
        pitem = by_id.get(item.get("extract_id"), item)
        if not args.force and pitem.get("detail_status") in {"extracted", "no_groups_visible_verification_required"}:
            continue
        candidates.append((idx, item))
        if len(candidates) >= args.count:
            break

    sock = connect(get_page_ws(args.port, "partsouq.com"))
    sock.settimeout(950)
    call(sock, 1, "Runtime.enable")

    done = []
    for idx, item in candidates:
        pitem = by_id.get(item["extract_id"], item)
        try:
            data = extract_one(sock, item, max_units=args.max_units)
            data["market"] = item.get("market", "")
            data["detected_generation"] = item.get("detected_generation", "")
            data["source_row"] = {
                "cells": item.get("cells", []),
                "raw_text": item.get("raw_text", ""),
                "vid": item.get("vid", ""),
                "vehicle_url": item.get("vehicle_url", ""),
            }
            data["category"] = item
            path = OUT / safe_filename(item)
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
            pitem["detail_status"] = "extracted" if data.get("units") else "no_groups_visible_verification_required"
            pitem["extracted_units"] = len(data.get("units", []))
            pitem["part_rows"] = sum(len(u.get("part_rows", [])) for u in data.get("units", []))
            pitem["unit_failures"] = len(data.get("failures", [])) + len(data.get("group_failures", []))
            pitem["detail_file"] = str(path)
            pitem["queue_index"] = idx
            done.append({"index": idx, "extract_id": item["extract_id"], "file": str(path), "units": pitem["extracted_units"], "parts": pitem["part_rows"], "failures": pitem["unit_failures"]})
        except Exception as exc:
            pitem["detail_status"] = "failed_verification_required"
            pitem["queue_index"] = idx
            pitem["error"] = str(exc)
            done.append({"index": idx, "extract_id": item["extract_id"], "error": str(exc)})
        summarize(progress)

    print(json.dumps({"done": done, "summary": progress["summary"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
