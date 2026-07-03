from __future__ import annotations

import csv
import hashlib
import json
import re
import shutil
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deliverables" / "final_patrol_catalogs"
REPORTS = OUT / "_reports"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def page_count(path: Path) -> int | None:
    try:
        return len(PdfReader(str(path)).pages)
    except Exception:
        return None


def classify(path: Path) -> tuple[str, str]:
    text = str(path.relative_to(ROOT)).replace("\\", "/").lower()
    name = path.name
    if "/tmp/" in f"/{text}" or text.startswith("tmp/"):
        return "IGNORE", "Temporary PDF"
    if "divider" in text or "/all_11_dividers/" in text or "/yearly_wgy_dividers/" in text:
        return "IGNORE", "Divider page"
    if "missing_epc_plates_report" in text:
        return "Reports", "Missing EPC Plates Report"
    if "pre_y60" in text or any(token in name.lower() for token in ("4w60", "60_g60", "160_mq", "260_series")):
        return "Pre_Y60", "Pre-Y60"
    if "patrol_iab_merged_master" in text:
        return "Y60", "Y60 master"
    if "y60" in text or "wgy60348567" in text:
        if re.search(r"Y60 19(8[8-9]|9[0-7])\.pdf$", name):
            return "Y60", "Y60 yearly"
        return "Y60", "Y60 vehicle"
    if "y61" in text:
        return "Y61", "Y61"
    if "y62" in text or "2010_y62" in text:
        return "Y62", "Y62"
    if "y63" in text:
        return "Y63", "Y63"
    return "Other_Verification_Required", "Verification Required"


def logical_key(record: dict) -> str:
    name = Path(record["name"]).stem
    name = re.sub(r"_[0-9a-f]{8}$", "", name, flags=re.I)
    if record["generation"] == "Y60" and record["category"] == "Y60 yearly":
        match = re.search(r"Y60 19(8[8-9]|9[0-7])", name)
        if match:
            return f"Y60_YEAR_{match.group(0)}"
    if record["generation"] == "Y60" and record["category"] == "Y60 vehicle":
        vid = re.search(r"_([0-9]{6})_", name)
        if vid:
            return f"Y60_VID_{vid.group(1)}"
        prefix = re.match(r"([0-9a-f]{12}|WGY60348567)", name, flags=re.I)
        if prefix:
            return f"Y60_SOURCE_{prefix.group(1).upper()}"
    return f"{record['generation']}::{record['category']}::{name.lower()}"


def priority(path: Path) -> int:
    text = str(path.relative_to(ROOT)).replace("\\", "/").lower()
    ordered = [
        "output/pdf/patrol_iab_merged/",
        "output/pdf/full_y60/",
        "output/pdf/yearly_with_available_missing/",
        "output/pdf/yearly_with_wgy60348567/",
        "output/pdf/pre_y60/",
        "output/pdf/patrol_safari_detailed/",
        "output/pdf/",
        "deliverables/saved_catalog_pdfs/",
    ]
    for idx, marker in enumerate(ordered):
        if marker in text:
            return idx
    return 100


def safe_name(name: str) -> str:
    return re.sub(r'[<>:"/\\|?*]+', "_", name).strip()


def main() -> None:
    if OUT.exists():
        resolved = OUT.resolve()
        expected = (ROOT / "deliverables" / "final_patrol_catalogs").resolve()
        if resolved != expected:
            raise RuntimeError(f"Refusing to clear unexpected path: {resolved}")
        shutil.rmtree(OUT)
    REPORTS.mkdir(parents=True, exist_ok=True)
    pdfs = [p for p in (ROOT / "output" / "pdf").rglob("*.pdf") if ".git" not in p.parts]
    records: list[dict] = []
    for path in pdfs:
        generation, category = classify(path)
        if generation == "IGNORE":
            continue
        records.append(
            {
                "path": str(path),
                "relative_path": str(path.relative_to(ROOT)),
                "name": path.name,
                "length": path.stat().st_size,
                "sha256": sha256(path),
                "pages": page_count(path),
                "generation": generation,
                "category": category,
                "priority": priority(path),
                "mtime": path.stat().st_mtime,
            }
        )

    by_hash: dict[str, list[dict]] = defaultdict(list)
    for record in records:
        by_hash[record["sha256"]].append(record)

    hash_unique: list[dict] = []
    duplicates: list[dict] = []
    for digest, group in by_hash.items():
        group = sorted(group, key=lambda r: (r["priority"], -int(r["length"]), r["relative_path"]))
        keep = group[0]
        hash_unique.append(keep)
        for duplicate in group[1:]:
            duplicates.append(
                {
                    "sha256": digest,
                    "duplicate_type": "Exact SHA256 duplicate",
                    "kept": keep["relative_path"],
                    "duplicate": duplicate["relative_path"],
                    "length": duplicate["length"],
                }
            )

    by_logical: dict[str, list[dict]] = defaultdict(list)
    for record in hash_unique:
        by_logical[logical_key(record)].append(record)

    canonical: list[dict] = []
    for key, group in by_logical.items():
        group = sorted(group, key=lambda r: (-int(r["length"]), r["priority"], r["relative_path"]))
        keep = group[0]
        canonical.append(keep)
        for duplicate in group[1:]:
            duplicates.append(
                {
                    "sha256": duplicate["sha256"],
                    "duplicate_type": f"Logical duplicate: {key}",
                    "kept": keep["relative_path"],
                    "duplicate": duplicate["relative_path"],
                    "length": duplicate["length"],
                }
            )

    for generation in ["Pre_Y60", "Y60", "Y61", "Y62", "Y63", "Reports", "Other_Verification_Required"]:
        (OUT / generation).mkdir(parents=True, exist_ok=True)

    copied: list[dict] = []
    for record in sorted(canonical, key=lambda r: (r["generation"], r["category"], r["name"])):
        src = Path(record["path"])
        generation_dir = OUT / record["generation"]
        if record["generation"] == "Y60" and record["category"] == "Y60 yearly":
            generation_dir = generation_dir / "Yearly_1988_1997"
        elif record["generation"] == "Y60" and record["category"] == "Y60 vehicle":
            generation_dir = generation_dir / "Vehicle_Model_Catalogs"
        generation_dir.mkdir(parents=True, exist_ok=True)
        dest = generation_dir / safe_name(src.name)
        if dest.exists() and dest.resolve() != src.resolve():
            dest = generation_dir / f"{src.stem}_{record['sha256'][:8]}{src.suffix}"
        shutil.copy2(src, dest)
        item = dict(record)
        item["delivered_path"] = str(dest.relative_to(ROOT))
        copied.append(item)

    summary = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_pdf_files_scanned": len(pdfs),
        "candidate_pdf_files": len(records),
        "unique_pdf_files_delivered": len(copied),
        "duplicate_or_less_complete_pdf_files_excluded": len(duplicates),
        "delivered_by_generation": dict(sorted(defaultdict(int, {g: sum(1 for r in copied if r["generation"] == g) for g in {r["generation"] for r in copied}}).items())),
        "notes": [
            "No source PDFs were deleted. Duplicates are excluded from the curated deliverable folder and listed in duplicate_pdfs.csv.",
            "Completeness is limited to locally extracted/source-backed data. Missing generations or vehicles are marked Verification Required in coverage reports.",
        ],
    }

    (REPORTS / "curated_pdf_manifest.json").write_text(json.dumps(copied, ensure_ascii=False, indent=2), encoding="utf-8")
    (REPORTS / "curated_pdf_summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    (REPORTS / "duplicate_pdfs.json").write_text(json.dumps(duplicates, ensure_ascii=False, indent=2), encoding="utf-8")
    with (REPORTS / "curated_pdf_manifest.csv").open("w", newline="", encoding="utf-8-sig") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(copied[0].keys()) if copied else ["path"])
        writer.writeheader()
        writer.writerows(copied)
    with (REPORTS / "duplicate_pdfs.csv").open("w", newline="", encoding="utf-8-sig") as fh:
        writer = csv.DictWriter(fh, fieldnames=["sha256", "duplicate_type", "kept", "duplicate", "length"])
        writer.writeheader()
        writer.writerows(duplicates)

    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
