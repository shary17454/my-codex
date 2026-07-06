#!/usr/bin/env python3
"""Build a read-only catalog database from Patrol PDF folders.

The script does not modify source files. It reads file metadata, extracts
lightweight PDF info, computes hashes for duplicate detection, and writes JSON
indexes that the web/iOS app can load.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ENGINE_RE = re.compile(
    r"(?<![A-Z0-9])(TB42S|TB42E|TB45E|TD42T|TD42|RD28TI|RD28T|VK56VD|VK56DE)(?![A-Z0-9])",
    re.IGNORECASE,
)
MODEL_RE = re.compile(r"(?<![A-Z0-9])([A-Z]{1,4}Y6[0-3]|Y6[0-3])(?![A-Z0-9])", re.IGNORECASE)
YEAR_RE = re.compile(r"\b(19[8-9]\d|20[0-3]\d)\b")
VID_RE = re.compile(r"\bVID[-_ ]?(\d{5,})\b", re.IGNORECASE)

GRADE_WORDS = {
    "ad": "AD",
    "gr": "GR",
    "grl": "GRL",
    "kr": "KR",
    "rx": "RX",
    "xe": "XE",
    "se": "SE",
    "le": "LE",
    "premium": "Premium",
    "tp1": "TP1",
    "tp2": "TP2",
}

BODY_WORDS = {
    "wagon": "Wagon",
    "hard_top": "Hard Top",
    "hard-top": "Hard Top",
    "high_roof": "High Roof",
    "fire_truck": "Fire Truck",
}

MARKET_WORDS = {
    "japan": "Japan",
    "middle_east": "Middle East",
    "gom": "GOM",
    "gcc": "GCC",
    "saudi": "Saudi/GCC",
}


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(chunk_size), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run_pdfinfo(path: Path) -> dict[str, Any]:
    pdfinfo = shutil.which("pdfinfo")
    if not pdfinfo:
        return {"pages": None, "pdf_version": None, "page_size": None, "error": "pdfinfo not found"}

    try:
        result = subprocess.run(
            [pdfinfo, str(path)],
            check=False,
            capture_output=True,
            text=True,
            timeout=45,
        )
    except Exception as exc:  # pragma: no cover - defensive for local tooling
        return {"pages": None, "pdf_version": None, "page_size": None, "error": str(exc)}

    info: dict[str, Any] = {"pages": None, "pdf_version": None, "page_size": None}
    if result.returncode != 0:
        info["error"] = result.stderr.strip() or result.stdout.strip()
        return info

    for line in result.stdout.splitlines():
        if ":" not in line:
            continue
        key, value = [part.strip() for part in line.split(":", 1)]
        key_lower = key.lower()
        if key_lower == "pages":
            try:
                info["pages"] = int(value)
            except ValueError:
                info["pages"] = None
        elif key_lower == "pdf version":
            info["pdf_version"] = value
        elif key_lower == "page size":
            info["page_size"] = value
        elif key_lower in {"title", "author", "creator", "producer"} and value:
            info[key_lower.replace(" ", "_")] = value
    return info


def normalize_name(path: Path) -> str:
    return path.stem.replace("_", " ").replace("-", " ").strip()


def parse_metadata(path: Path, source_root: Path) -> dict[str, Any]:
    rel = path.relative_to(source_root)
    rel_text = str(rel)
    lower = rel_text.lower()

    generation = None
    for candidate in ("Y60", "Y61", "Y62", "Y63"):
        if candidate.lower() in lower:
            generation = candidate
            break

    years = sorted(set(YEAR_RE.findall(rel_text)))
    engines = sorted({match.upper() for match in ENGINE_RE.findall(rel_text)})
    model_codes = sorted({match.upper() for match in MODEL_RE.findall(rel_text)})
    vids = sorted(set(VID_RE.findall(rel_text)))

    grades = sorted({label for word, label in GRADE_WORDS.items() if re.search(rf"(^|[_\-\s]){re.escape(word)}([_\-\s]|$)", lower)})
    bodies = sorted({label for word, label in BODY_WORDS.items() if word in lower})
    markets = sorted({label for word, label in MARKET_WORDS.items() if word in lower})

    if "remaining_index" in lower:
        source_kind = "partsouq_remaining_index"
    elif "full_catalog" in lower or "الكتالوج الشامل" in lower or "all_11_catalogs_combined" in lower:
        source_kind = "full_catalog"
    elif "index" in lower:
        source_kind = "index"
    elif "schematic" in lower:
        source_kind = "schematic_supplement"
    else:
        source_kind = "catalog_pdf"

    return {
        "display_title": normalize_name(path),
        "relative_path": rel_text,
        "generation": generation or "unknown",
        "years": years,
        "primary_year": years[0] if years else None,
        "engines": engines,
        "model_codes": model_codes,
        "vids": vids,
        "grades": grades,
        "body_styles": bodies,
        "markets": markets,
        "source_kind": source_kind,
        "query_text": " ".join(
            part
            for part in [
                normalize_name(path),
                rel_text,
                generation or "",
                " ".join(years),
                " ".join(engines),
                " ".join(model_codes),
                " ".join(grades),
                " ".join(bodies),
                " ".join(markets),
            ]
            if part
        ),
    }


def build_database(source_root: Path) -> dict[str, Any]:
    pdf_files = sorted(path for path in source_root.rglob("*") if path.is_file() and path.suffix.lower() == ".pdf")
    records: list[dict[str, Any]] = []
    hashes: dict[str, list[str]] = defaultdict(list)

    for index, path in enumerate(pdf_files, start=1):
        stat = path.stat()
        metadata = parse_metadata(path, source_root)
        file_hash = sha256_file(path)
        pdf_info = run_pdfinfo(path)
        record = {
            "id": f"patrol_catalog_{index:04d}",
            "file_name": path.name,
            "absolute_path": str(path),
            "size_bytes": stat.st_size,
            "modified_at": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
            "sha256": file_hash,
            "duplicate_of": None,
            "pdf": pdf_info,
            **metadata,
        }
        records.append(record)
        hashes[file_hash].append(record["id"])

    duplicate_groups = []
    for digest, ids in sorted(hashes.items()):
        if len(ids) <= 1:
            continue
        keeper = ids[0]
        duplicate_groups.append({"sha256": digest, "canonical_id": keeper, "duplicates": ids[1:], "all_ids": ids})
        for record in records:
            if record["id"] in ids[1:]:
                record["duplicate_of"] = keeper

    generation_index: dict[str, Any] = {}
    for generation in sorted({record["generation"] for record in records}):
        generation_records = [record for record in records if record["generation"] == generation]
        unique_records = [record for record in generation_records if not record["duplicate_of"]]
        years = sorted({year for record in generation_records for year in record["years"]})
        engines = sorted({engine for record in generation_records for engine in record["engines"]})
        model_codes = sorted({code for record in generation_records for code in record["model_codes"]})
        total_pages = sum((record.get("pdf") or {}).get("pages") or 0 for record in unique_records)
        generation_index[generation] = {
            "generation": generation,
            "file_count": len(generation_records),
            "unique_file_count": len(unique_records),
            "duplicate_file_count": len(generation_records) - len(unique_records),
            "years": years,
            "engines": engines,
            "model_codes": model_codes,
            "total_pages": total_pages,
            "catalog_ids": [record["id"] for record in generation_records],
            "unique_catalog_ids": [record["id"] for record in unique_records],
        }

    summary = {
        "source_root": str(source_root),
        "total_files": len(records),
        "unique_files": sum(1 for record in records if not record["duplicate_of"]),
        "duplicate_files": sum(1 for record in records if record["duplicate_of"]),
        "total_bytes": sum(record["size_bytes"] for record in records if not record["duplicate_of"]),
        "total_pages": sum((record.get("pdf") or {}).get("pages") or 0 for record in records if not record["duplicate_of"]),
        "generations": generation_index,
    }

    return {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "read_only_source": True,
        "content_preservation_note": "Original PDF files were read only. No source file content, filename, or folder was modified.",
        "summary": summary,
        "files": records,
        "duplicate_groups": duplicate_groups,
    }


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_root", type=Path)
    parser.add_argument("--out", type=Path, default=Path("data/patrol_catalog_database.json"))
    parser.add_argument("--manifest", type=Path, default=Path("data/patrol_catalog_manifest.json"))
    args = parser.parse_args()

    source_root = args.source_root.expanduser().resolve()
    if not source_root.exists():
        raise SystemExit(f"Source folder not found: {source_root}")

    database = build_database(source_root)
    manifest = {
        "schema_version": database["schema_version"],
        "generated_at": database["generated_at"],
        "summary": database["summary"],
        "files": [
            {
                key: record[key]
                for key in [
                    "id",
                    "file_name",
                    "relative_path",
                    "generation",
                    "years",
                    "engines",
                    "model_codes",
                    "grades",
                    "body_styles",
                    "markets",
                    "source_kind",
                    "size_bytes",
                    "sha256",
                    "duplicate_of",
                ]
            }
            | {"pages": (record.get("pdf") or {}).get("pages")}
            for record in database["files"]
        ],
    }

    write_json(args.out, database)
    write_json(args.manifest, manifest)
    print(
        json.dumps(
            {
                "database": str(args.out),
                "manifest": str(args.manifest),
                "total_files": database["summary"]["total_files"],
                "unique_files": database["summary"]["unique_files"],
                "duplicate_files": database["summary"]["duplicate_files"],
                "total_pages": database["summary"]["total_pages"],
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
