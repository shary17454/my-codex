from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path")
    args = parser.parse_args()
    path = Path(args.path)
    if not path.is_absolute():
        path = ROOT / path
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    vehicle = data.get("vehicle", {})
    cells = vehicle.get("cells") or []
    data["detected_generation"] = data.get("detected_generation") or data.get("generation")
    data["source_vehicle_url"] = data.get("source_vehicle_url") or data.get("vehicle_url")
    data["source_row"] = data.get("source_row") or {
        "raw_text": vehicle.get("raw_text", ""),
        "cells": cells,
        "vid": vehicle.get("vid", ""),
    }
    data["category"] = data.get("category") or {
        "year": vehicle.get("year", ""),
        "market": vehicle.get("market", ""),
        "body_style": vehicle.get("body_style", ""),
        "engine": vehicle.get("engine", ""),
        "grade_or_frame": vehicle.get("grade", ""),
        "production_from": cells[6] if len(cells) > 6 else "",
        "production_to": cells[7] if len(cells) > 7 else "",
    }
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"path": str(path), "category": data["category"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
