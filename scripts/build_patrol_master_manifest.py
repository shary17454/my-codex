from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "sources" / "partsouq"
PDF_ROOT = ROOT / "output" / "pdf"
OUT = ROOT / "data" / "patrol_master_manifest.json"


GEN_ORDER = {"PRE_Y60": 0, "Y60": 1, "Y61": 2, "Y62": 3, "Y63": 4, "UNKNOWN": 99}


def detect_generation(text: str) -> str:
    for gen in ("Y63", "Y62", "Y61", "Y60"):
        if re.search(rf"\b{gen}\b", text, re.I):
            return gen
    if re.search(r"\b(160|260|MQ|MK|4W60|G60)\b", text, re.I):
        return "PRE_Y60"
    return "UNKNOWN"


def first_year(text: str) -> str:
    years = re.findall(r"\b(19[5-9]\d|20[0-3]\d)\b", text)
    return min(years) if years else "9999"


def summarize_json(path: Path) -> dict[str, object] | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
    text = json.dumps(data, ensure_ascii=False)
    if not isinstance(data, dict):
        return None
    units = data.get("units", [])
    rows = data.get("rows", [])
    generation = detect_generation(text)
    source_kind = "unknown"
    if "full_y60" in str(path):
        source_kind = "detail_extract_y60"
    elif "full_patrol_safari" in str(path):
        source_kind = "detail_extract_patrol_safari"
    elif "navigation" in str(path):
        source_kind = "navigation_index"
    elif "current_vehicle" in str(path):
        source_kind = "current_vehicle_extract"
    if not units and not rows and source_kind == "unknown":
        return None
    category = data.get("category", {}) if isinstance(data, dict) else {}
    source_row = data.get("source_row", {}) if isinstance(data, dict) else {}
    cells = source_row.get("cells") or []
    name_text = " | ".join(str(x) for x in cells) or path.stem
    return {
        "generation": generation,
        "year": first_year(text),
        "source_kind": source_kind,
        "json": str(path),
        "units": len(units),
        "part_rows": sum(len(u.get("part_rows", [])) for u in units),
        "market": data.get("market") or category.get("market") or source_row.get("market") or "",
        "title": name_text,
        "status": "extracted_json" if units else "index_or_plan_only",
    }


def summarize_navigation_rows(path: Path) -> list[dict[str, object]]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []
    out = []
    for row in data.get("rows", []):
        text = row.get("raw_text") or " | ".join(str(x) for x in row.get("cells", []))
        out.append(
            {
                "generation": row.get("detected_generation") or detect_generation(text),
                "year": first_year(text),
                "source_kind": "partsouq_navigation_row",
                "json": str(path),
                "vehicle_url": row.get("vehicle_url", ""),
                "vid": row.get("vid", ""),
                "market": row.get("market", ""),
                "title": text,
                "status": "needs_detail_extraction",
            }
        )
    return out


def summarize_discovery_rows(path: Path) -> list[dict[str, object]]:
    if path.name == "patrol_model_filter_discovery.json":
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []
    out = []
    for row in data.get("rows", []):
        text = row.get("raw_text") or " | ".join(str(x) for x in row.get("cells", []))
        if not re.search(r"\b(PATROL|SAFARI|ARMADA|Y60|Y61|Y62|Y63|160|260|MQ|MK|4W60|G60)\b", text, re.I):
            continue
        out.append(
            {
                "generation": row.get("detected_generation") or detect_generation(text),
                "year": row.get("year_filter") or first_year(text),
                "source_kind": "partsouq_filtered_discovery_row",
                "json": str(path),
                "vehicle_url": row.get("vehicle_url", ""),
                "vid": row.get("vid", ""),
                "market": row.get("market", data.get("market", "")),
                "title": text,
                "status": "needs_detail_extraction",
            }
        )
    return out


def pdf_records() -> list[dict[str, object]]:
    records = []
    for path in PDF_ROOT.rglob("*.pdf"):
        text = str(path)
        records.append(
            {
                "generation": detect_generation(text),
                "year": first_year(text),
                "pdf": str(path),
                "bytes": path.stat().st_size,
            }
        )
    return records


def main() -> None:
    source_records: list[dict[str, object]] = []
    for path in SOURCES.rglob("*.json"):
        if "image_cache" in path.parts:
            continue
        summary = summarize_json(path)
        if summary:
            source_records.append(summary)
        if path.name == "partsouq_all_markets_patrol_safari_index.json":
            source_records.extend(summarize_navigation_rows(path))
        if path.parent.name == "navigation" and path.name.startswith("patrol") and path.name.endswith("_discovery.json"):
            source_records.extend(summarize_discovery_rows(path))

    pdfs = pdf_records()
    source_records.sort(key=lambda r: (GEN_ORDER.get(str(r["generation"]), 99), str(r["year"]), str(r.get("market", "")), str(r.get("title", ""))))
    pdfs.sort(key=lambda r: (GEN_ORDER.get(str(r["generation"]), 99), str(r["year"]), str(r.get("pdf", ""))))

    summary = {
        "scope": ["PRE_Y60", "Y60", "Y61", "Y62", "Y63"],
        "rules": [
            "Do not fabricate part numbers or diagrams.",
            "Use Verification Required for unavailable plates, diagrams, applicability, or translations.",
            "Generate one PDF per extracted catalog/model and sort outputs chronologically.",
        ],
        "source_counts_by_generation": dict(Counter(str(r["generation"]) for r in source_records)),
        "pdf_counts_by_generation": dict(Counter(str(r["generation"]) for r in pdfs)),
        "source_records": source_records,
        "pdf_records": pdfs,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"manifest": str(OUT), "source_counts_by_generation": summary["source_counts_by_generation"], "pdf_counts_by_generation": summary["pdf_counts_by_generation"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
