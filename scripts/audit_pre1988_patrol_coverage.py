from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CAT_CSV = ROOT / "output" / "database" / "nissan_y60_all_categories.csv"
OUT_DIR = ROOT / "output" / "reports"


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = list(csv.DictReader(CAT_CSV.open("r", encoding="utf-8-sig", newline="")))

    # In the current PartSouq index, model_code=160 is the older Patrol generation
    # represented before the Y60 era. Y60 rows that begin in 08.1987 stay with Y60.
    old_rows = [r for r in rows if r.get("model_code") == "160"]
    for row in old_rows:
        row["detail_status"] = "VERIFICATION_REQUIRED_FULL_EPC_NOT_EXTRACTED"
        row["catalog_scope"] = "Nissan Patrol 160 / pre-1988 generation"

    fieldnames = sorted({key for row in old_rows for key in row.keys()})
    all_path = OUT_DIR / "pre1988_patrol_160_coverage_all.csv"
    missing_path = OUT_DIR / "pre1988_patrol_160_missing.csv"
    with all_path.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(old_rows)
    with missing_path.open("w", encoding="utf-8-sig", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(old_rows)

    summary = {
        "scope": "Nissan Patrol 160 / pre-1988 generation currently visible in PartSouq index",
        "catalog_rows": len(old_rows),
        "detailed_extracted_rows": 0,
        "missing_detailed_rows": len(old_rows),
        "markets": sorted({r.get("market", "") for r in old_rows}),
        "engines": sorted({r.get("engine", "") for r in old_rows}),
        "body_styles": sorted({r.get("body_style", "") for r in old_rows}),
        "reports": {
            "all": str(all_path),
            "missing": str(missing_path),
        },
    }
    summary_path = OUT_DIR / "pre1988_patrol_160_coverage_summary.json"
    summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
