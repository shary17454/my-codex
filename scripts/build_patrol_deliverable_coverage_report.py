from __future__ import annotations

import csv
import json
import re
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deliverables" / "final_patrol_catalogs" / "_reports"


def load_json(path: Path):
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8-sig"))


def vid_from_name(name: str) -> str:
    match = re.search(r"_([0-9]{6})_", name)
    return match.group(1) if match else ""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = load_json(OUT / "curated_pdf_manifest.json") or []
    queue = load_json(ROOT / "sources" / "partsouq" / "patrol_extraction_queue.json") or []
    discovery = load_json(ROOT / "output" / "reports" / "patrol_all_generations_collection_status.json") or {}
    iab_summary = load_json(ROOT / "output" / "reports" / "patrol_iab_pdf_build_summary.json") or {}

    delivered_vids = {vid_from_name(item.get("name", "")) for item in manifest if vid_from_name(item.get("name", ""))}
    queue_rows = queue.get("items", queue if isinstance(queue, list) else [])
    missing_queue = []
    for row in queue_rows:
        vid = str(row.get("vid") or row.get("vehicle_id") or row.get("id") or "")
        generation = row.get("generation", "Verification Required")
        if vid and vid not in delivered_vids:
            missing_queue.append(
                {
                    "generation": generation,
                    "vid": vid,
                    "year": row.get("year", ""),
                    "market": row.get("market", ""),
                    "body": row.get("body", row.get("body_style", "")),
                    "engine": row.get("engine", ""),
                    "grade": row.get("grade", row.get("trim", "")),
                    "status": "Verification Required - no delivered vehicle PDF matched this VID",
                }
            )

    delivered_by_generation = {}
    for item in manifest:
        delivered_by_generation[item["generation"]] = delivered_by_generation.get(item["generation"], 0) + 1

    status_rows = [
        {
            "generation": generation,
            "discovered_accepted_rows": (discovery.get("accepted_by_generation") or {}).get(generation, 0),
            "delivered_pdf_files": delivered_by_generation.get(generation, 0),
            "status": "Available" if delivered_by_generation.get(generation, 0) else "Verification Required - no complete local PDF",
        }
        for generation in ["Pre_Y60", "Y60", "Y61", "Y62", "Y63"]
    ]

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "rules": [
            "No part numbers, diagrams, or applicability data are fabricated.",
            "Rows without a matching local delivered PDF are marked Verification Required.",
            "The current complete detailed extraction is strongest for Y60; Y61/Y63 are discovered but not locally extracted as complete PDFs.",
        ],
        "delivered_by_generation": delivered_by_generation,
        "discovery_status": discovery,
        "iab_pdf_build_summary": iab_summary,
        "generation_status": status_rows,
        "missing_queue_count": len(missing_queue),
        "missing_queue_sample": missing_queue[:100],
    }
    (OUT / "coverage_and_missing_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    with (OUT / "generation_status.csv").open("w", newline="", encoding="utf-8-sig") as fh:
        writer = csv.DictWriter(fh, fieldnames=["generation", "discovered_accepted_rows", "delivered_pdf_files", "status"])
        writer.writeheader()
        writer.writerows(status_rows)
    with (OUT / "missing_queue_items.csv").open("w", newline="", encoding="utf-8-sig") as fh:
        fields = ["generation", "vid", "year", "market", "body", "engine", "grade", "status"]
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        writer.writerows(missing_queue)

    print(json.dumps({k: report[k] for k in ("generated_at", "delivered_by_generation", "missing_queue_count", "generation_status")}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
