from __future__ import annotations

import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CAT_CSV = ROOT / "output" / "database" / "nissan_y60_all_categories.csv"
FULL_DIR = ROOT / "sources" / "partsouq" / "full_y60"
OUT_DIR = ROOT / "output" / "reports"

Y60_YEARS = set(range(1988, 1998))


def years_from_text(value: str) -> list[int]:
    return [int(x) for x in re.findall(r"(?:0[1-9]|1[0-2])\.(19\d{2}|20\d{2})", value or "")]


def row_years(row: dict[str, str]) -> list[int]:
    start_years = years_from_text(row.get("production_from", ""))
    end_years = years_from_text(row.get("production_to", ""))
    start = start_years[0] if start_years else 1988
    end = end_years[0] if end_years else 1997
    return [year for year in range(start, end + 1) if year in Y60_YEARS]


def source_vehicle_urls() -> set[str]:
    urls: set[str] = set()
    for path in FULL_DIR.glob("*.json"):
        if path.name.endswith(".units_index.json"):
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if not isinstance(data, dict):
            continue
        category = data.get("category") or {}
        url = category.get("vehicle_url") or data.get("vehicle_url")
        if url:
            urls.add(str(url))
    return urls


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = list(csv.DictReader(CAT_CSV.open("r", encoding="utf-8-sig", newline="")))
    extracted_urls = source_vehicle_urls()

    y60_rows = []
    missing_rows = []
    covered_rows = []
    for row in rows:
        years = row_years(row)
        if not years:
            continue
        item = dict(row)
        item["applicable_years_1988_1997"] = ",".join(map(str, years))
        item["detail_status"] = "DETAILED_EXTRACT_AVAILABLE" if row.get("vehicle_url") in extracted_urls else "VERIFICATION_REQUIRED_FULL_EPC_NOT_EXTRACTED"
        y60_rows.append(item)
        if item["detail_status"].startswith("DETAILED"):
            covered_rows.append(item)
        else:
            missing_rows.append(item)

    for name, data in [
        ("y60_detail_coverage_all.csv", y60_rows),
        ("y60_detail_coverage_missing.csv", missing_rows),
        ("y60_detail_coverage_extracted.csv", covered_rows),
    ]:
        path = OUT_DIR / name
        fieldnames = sorted({key for row in data for key in row.keys()})
        with path.open("w", encoding="utf-8-sig", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(data)

    summary = {
        "catalog_rows_applicable_to_1988_1997": len(y60_rows),
        "detailed_extracted_rows": len(covered_rows),
        "missing_detailed_rows": len(missing_rows),
        "extracted_source_count": len(extracted_urls),
        "reports": {
            "all": str(OUT_DIR / "y60_detail_coverage_all.csv"),
            "missing": str(OUT_DIR / "y60_detail_coverage_missing.csv"),
            "extracted": str(OUT_DIR / "y60_detail_coverage_extracted.csv"),
        },
    }
    (OUT_DIR / "y60_detail_coverage_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
