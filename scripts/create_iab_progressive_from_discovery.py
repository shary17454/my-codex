from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("discovery_json")
    parser.add_argument("output_json")
    args = parser.parse_args()

    discovery = Path(args.discovery_json)
    if not discovery.is_absolute():
        discovery = ROOT / discovery
    output = Path(args.output_json)
    if not output.is_absolute():
        output = ROOT / output

    payload = json.loads(discovery.read_text(encoding="utf-8-sig"))
    item = payload.get("item", {})
    data = {
        "extract_id": item.get("extract_id") or f"{item.get('detected_generation', 'Verification Required')}_{item.get('year', '')}_{item.get('vid', '')}",
        "generation": item.get("detected_generation", "Verification Required"),
        "source": "PartSouq via Codex in-app browser",
        "vehicle_url": item.get("vehicle_url", ""),
        "vehicle": {
            "vid": str(item.get("vid", "")),
            "raw_text": item.get("raw_text", ""),
            "cells": item.get("cells", []),
            "vehicle_info": payload.get("vehicleInfo", ""),
            "year": item.get("year", ""),
            "market": item.get("market", ""),
            "body_style": item.get("body_style", ""),
            "engine": item.get("engine", ""),
            "grade": item.get("grade_or_frame", ""),
        },
        "discovered_units": payload.get("discovered_units", []),
        "units": [],
        "failures": [],
        "complete": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "extracted_at": None,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({
        "output": str(output),
        "extract_id": data["extract_id"],
        "discovered_units": len(data["discovered_units"]),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
