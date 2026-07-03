from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

from cdp_eval import call, connect, get_page_ws
from cdp_extract_y60_nav import DOM_DISCOVER, DOM_UNIT, eval_json, navigate


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "sources" / "partsouq" / "current_vehicle"


def safe_name(text: str) -> str:
    text = re.sub(r"[^A-Za-z0-9._-]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text[:150] or "partsouq_vehicle"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=9223)
    parser.add_argument("--name", default="WGY60348567")
    parser.add_argument("--limit-units", type=int, default=0)
    args = parser.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    sock = connect(get_page_ws(args.port, "partsouq.com"))
    sock.settimeout(180)
    call(sock, 1, "Runtime.enable")
    call(sock, 2, "Page.enable")

    vehicle = eval_json(sock, DOM_DISCOVER, 20)
    unit_by_key = {}
    for unit in vehicle["units"]:
        key = unit.get("uid") or unit["unit_url"]
        if key not in unit_by_key or unit.get("title"):
            unit_by_key[key] = unit
    units = list(unit_by_key.values())[: args.limit_units or None]
    data = {
        "extract_id": safe_name(args.name),
        "category": {
            "name": args.name,
            "vehicle_url": vehicle["url"],
            "page_title": vehicle["title"],
        },
        "started_at": datetime.now(timezone.utc).isoformat(),
        "source_vehicle_url": vehicle["url"],
        "vehicle_page": {"groups": vehicle["groups"], "tables": vehicle["tables"]},
        "units": [],
        "failures": [],
        "group_failures": [],
        "extraction_notes": ["current_visible_page_navigation_extraction"],
    }
    path = OUT / f"{safe_name(args.name)}.json"
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
    print(json.dumps({"file": str(path), "units": len(data["units"]), "parts": sum(len(u.get("part_rows", [])) for u in data["units"]), "failures": len(data["failures"])}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
