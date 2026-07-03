from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "sources" / "partsouq" / "full_patrol_all_iab"
OUT = ROOT / "output" / "reports"


def summarize_file(path: Path) -> dict[str, object]:
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    units = data.get("units", [])
    discovered = data.get("discovered_units", [])
    failures = data.get("failures", []) + data.get("group_failures", [])
    discovered_count = len(discovered) if discovered else len(units)
    accounted_count = len(units) + len(failures)
    return {
        "file": str(path),
        "extract_id": data.get("extract_id", ""),
        "generation": data.get("detected_generation", ""),
        "market": data.get("market", ""),
        "vehicle": data.get("source_row", {}).get("raw_text", ""),
        "discovered_units": discovered_count,
        "extracted_units": len(units),
        "part_rows": sum(len(u.get("part_rows", [])) for u in units),
        "diagrams": sum(1 for u in units if u.get("diagram_image_url")),
        "failures": len(failures),
        "status": "complete" if discovered_count and accounted_count >= discovered_count else "in_progress",
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    if SRC.exists():
        rows = [summarize_file(path) for path in sorted(SRC.glob("*.json")) if ".iab_test." not in path.name]
    summary = {
        "files": len(rows),
        "complete_files": sum(1 for r in rows if r["status"] == "complete"),
        "in_progress_files": sum(1 for r in rows if r["status"] == "in_progress"),
        "extracted_units": sum(int(r["extracted_units"]) for r in rows),
        "part_rows": sum(int(r["part_rows"]) for r in rows),
        "diagrams": sum(int(r["diagrams"]) for r in rows),
        "failures": sum(int(r["failures"]) for r in rows),
    }
    (OUT / "patrol_iab_extraction_summary.json").write_text(json.dumps({"summary": summary, "rows": rows}, ensure_ascii=False, indent=2), encoding="utf-8")
    with (OUT / "patrol_iab_extraction_summary.csv").open("w", encoding="utf-8-sig", newline="") as f:
        fields = ["extract_id", "generation", "market", "status", "discovered_units", "extracted_units", "part_rows", "diagrams", "failures", "vehicle", "file"]
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
