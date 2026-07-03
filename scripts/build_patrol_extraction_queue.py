from __future__ import annotations

import csv
import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ACCEPTED = ROOT / "output" / "reports" / "patrol_all_generations_discovery_accepted.csv"
OUT = ROOT / "sources" / "partsouq" / "patrol_extraction_queue.json"


GEN_ORDER = {"PRE_Y60": 0, "Y60": 1, "Y61": 2, "Y62": 3, "Y63": 4, "UNKNOWN": 99}


def first_year(text: str, fallback: str = "") -> str:
    if fallback and fallback.isdigit():
        return fallback
    years = re.findall(r"\b(19[7-9]\d|20[0-3]\d)\b", text or "")
    return min(years) if years else "9999"


def parse_cells(raw: str) -> list[str]:
    return [x.strip() for x in (raw or "").split("|")]


def make_item(row: dict[str, str]) -> dict[str, object]:
    raw = row.get("raw_text", "")
    cells = parse_cells(raw)
    digest = hashlib.sha1((row.get("vehicle_url", "") + raw).encode("utf-8")).hexdigest()[:10]
    gen = row.get("detected_generation", "") or "UNKNOWN"
    year = first_year(raw, row.get("year_filter", ""))
    # Common PartSouq row shapes are:
    # NAME | BODY | ENGINE | GRADE | MARKET | MODEL | FROM | TO/OPTIONS | GEARBOX
    body = cells[1] if len(cells) > 1 else ""
    engine = cells[2] if len(cells) > 2 else ""
    grade = cells[3] if len(cells) > 3 else ""
    return {
        "extract_id": f"{gen}_{year}_{row.get('vid') or digest}",
        "detected_generation": gen,
        "year": year,
        "market": row.get("market", ""),
        "model_filter": row.get("model_filter", ""),
        "year_filter": row.get("year_filter", ""),
        "vehicle_url": row.get("vehicle_url", ""),
        "vid": row.get("vid", ""),
        "raw_text": raw,
        "cells": cells,
        "source_file": row.get("source_file", ""),
        "body_style": body,
        "engine": engine,
        "grade_or_frame": grade,
        "detail_status": "pending",
    }


def main() -> None:
    with ACCEPTED.open("r", encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    items = [make_item(r) for r in rows if r.get("vehicle_url")]
    seen: set[str] = set()
    unique = []
    for item in items:
        key = str(item["vehicle_url"])
        if key in seen:
            continue
        seen.add(key)
        unique.append(item)
    unique.sort(key=lambda x: (GEN_ORDER.get(str(x["detected_generation"]), 99), str(x["year"]), str(x["market"]), str(x["raw_text"])))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        json.dumps(
            {
                "source": str(ACCEPTED),
                "sort": "generation_order_then_year_then_market",
                "items": unique,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    by_gen: dict[str, int] = {}
    for item in unique:
        by_gen[str(item["detected_generation"])] = by_gen.get(str(item["detected_generation"]), 0) + 1
    print(json.dumps({"queue": str(OUT), "items": len(unique), "by_generation": by_gen}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
