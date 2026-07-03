from __future__ import annotations

import csv
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NAV = ROOT / "sources" / "partsouq" / "navigation"
OUT = ROOT / "output" / "reports"


def detect_generation(text: str) -> str:
    s = (text or "").upper()
    if re.search(r"\b(Y63|GY63|WGY63|FGY63)\b", s):
        return "Y63"
    if re.search(r"\b(Y62|GY62|WGY62|FGY62)\b", s):
        return "Y62"
    if re.search(r"\b(Y61|GY61|WGY61|FGY61|GCY61)\b", s):
        return "Y61"
    if re.search(r"\b(Y60|GY60|WGY60|FGY60|WGY60)\b", s):
        return "Y60"
    if re.search(r"\b(160|260|MQ|MK|4W60|G60)\b", s):
        return "PRE_Y60"
    return "UNKNOWN"


def date_years(text: str) -> list[int]:
    return [int(y) for _m, y in re.findall(r"\b(0[1-9]|1[0-2])\.(19[7-9]\d|20[0-3]\d)\b", text or "")]


def applies_to_year(row: dict) -> bool:
    yf = str(row.get("year_filter") or "")
    if not yf.isdigit():
        return True
    target = int(yf)
    years = date_years(row.get("raw_text", ""))
    if not years:
        return True
    if len(years) == 1:
        return target >= years[0]
    return min(years) <= target <= max(years)


def load_rows() -> list[dict]:
    rows: list[dict] = []
    for path in sorted(NAV.glob("patrol*_discovery.json")):
        if path.name == "patrol_model_filter_discovery.json":
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        for row in data.get("rows", []):
            raw = row.get("raw_text") or " | ".join(str(x) for x in row.get("cells", []))
            if not re.search(r"\b(PATROL|SAFARI|ARMADA|Y60|Y61|Y62|Y63|160|260|MQ|MK|4W60|G60)\b", raw, re.I):
                continue
            row = dict(row)
            row["source_file"] = str(path)
            row["raw_text"] = raw
            row["detected_generation"] = detect_generation(raw)
            row["year_applicability_status"] = "applies" if applies_to_year(row) else "verification_required_year_filter_mismatch"
            rows.append(row)
    seen: set[tuple[str, str, str, str]] = set()
    unique: list[dict] = []
    for row in rows:
        key = (
            row.get("market", ""),
            row.get("vid", ""),
            row.get("raw_text", ""),
            row.get("source_file", ""),
        )
        if key in seen:
            continue
        seen.add(key)
        unique.append(row)
    return unique


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    rows = load_rows()
    accepted = [r for r in rows if r["year_applicability_status"] == "applies"]
    verification = [r for r in rows if r["year_applicability_status"] != "applies"]
    summary = {
        "captured_at": datetime.now(timezone.utc).isoformat(),
        "scope": ["PRE_Y60", "Y60", "Y61", "Y62", "Y63"],
        "source": "PartSouq filtered Nissan Patrol/Safari/Armada discovery plus existing local extractions",
        "rules": [
            "Rows are discovery records only until EPC plate detail extraction is completed.",
            "Rows failing date applicability are kept in verification report, not used as confirmed coverage.",
            "No part numbers or diagrams are inferred here.",
        ],
        "accepted_rows": len(accepted),
        "verification_required_rows": len(verification),
        "accepted_by_generation": dict(Counter(r["detected_generation"] for r in accepted)),
        "verification_by_generation": dict(Counter(r["detected_generation"] for r in verification)),
    }
    (OUT / "patrol_all_generations_collection_status.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    fields = ["market", "model_filter", "year_filter", "detected_generation", "year_applicability_status", "vid", "raw_text", "vehicle_url", "source_file"]
    for name, data in [
        ("patrol_all_generations_discovery_accepted.csv", accepted),
        ("patrol_all_generations_discovery_verification_required.csv", verification),
    ]:
        with (OUT / name).open("w", encoding="utf-8-sig", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
            w.writeheader()
            w.writerows(data)
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
