#!/usr/bin/env python3
import csv
import hashlib
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / "vendor"
if VENDOR.exists():
    sys.path.insert(0, str(VENDOR))

from pypdf import PdfReader

PDFS = [
    {
        "year": "1988-1997",
        "kind": "combined_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/93643739-D450-44F8-926B-88A803000DC1/Y60_1988-1997_all_11_catalogs_combined.pdf",
    },
    {
        "year": "VIN",
        "kind": "vin_report",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/324D3152-6BAC-4239-A3EA-75BEE02A3ABD/WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.reportlab.pdf",
    },
    {
        "year": "1988",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/03995EEE-5FC0-4FC2-A9DB-4C49D325BCD1/Y60 1988.pdf",
    },
    {
        "year": "1988",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/97A2C0AE-E479-428A-A392-70FA16AC233E/Y60 1988.pdf",
    },
    {
        "year": "1989",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/6ED6AD1A-6F3D-42B5-BC9E-A4C27C394EA1/Y60 1989.pdf",
    },
    {
        "year": "1990",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/0CB36AF3-A935-48CD-A0A7-0E69ADCA0D80/Y60 1990.pdf",
    },
    {
        "year": "1991",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/54EEA57D-68F2-4569-85F9-919CDB20A0D7/Y60 1991.pdf",
    },
    {
        "year": "1992",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/08831A0F-532A-4274-A909-665D6D819A83/Y60 1992.pdf",
    },
    {
        "year": "1993",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/09C6A195-6C25-492B-BEDA-B0DBEA6A9209/Y60 1993.pdf",
    },
    {
        "year": "1994",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/C52AAF96-859C-40E1-9AD8-3EDA8617DFCB/Y60 1994.pdf",
    },
    {
        "year": "1995",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/4E674A88-98AE-430B-BC29-D8A6399B639D/Y60 1995.pdf",
    },
    {
        "year": "1996",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/D62419C5-7C62-4026-9AF0-6B34B04BFBAB/Y60 1996.pdf",
    },
    {
        "year": "1997",
        "kind": "year_catalog",
        "path": "/Users/shrybnhshymbnmrzwqbnhwyd/Library/Containers/net.whatsapp.WhatsApp/Data/tmp/documents/AC7A2881-8846-4D6D-824D-F50C7811D845/Y60 1997.pdf",
    },
]

# Nissan EPC part numbers in these catalogs commonly appear as 10 characters
# such as 6385005J91 or with a hyphen as 63850-05J91.
PART_PATTERN = re.compile(r"\b(?:\d{5}-?[A-Z0-9]{5})\b")
FIG_PATTERN = re.compile(r"\b(?:FIG|Fig|SECTION|Section)\.?\s*([A-Z0-9-]+)?")
VIN_PATTERN = re.compile(r"\b[A-HJ-NPR-Z0-9]{10,17}\b")


def sha256(path):
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def clean_text(text):
    text = text or ""
    text = text.replace("\x00", " ")
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def context_for(text, start, end, radius=90):
    left = max(0, start - radius)
    right = min(len(text), end + radius)
    return " ".join(text[left:right].split())


def source_id(item, index):
    year = item["year"].replace("-", "_")
    return f"{index:02d}_{item['kind']}_{year}"


def extract_pdf(item, index, raw_dir):
    path = Path(item["path"])
    sid = source_id(item, index)
    if not path.exists():
        return {
            "source_id": sid,
            "status": "missing",
            "path": str(path),
            "year": item["year"],
            "kind": item["kind"],
        }, []

    reader = PdfReader(str(path))
    pages = []
    part_rows = []
    raw_path = raw_dir / f"{sid}.txt"

    with raw_path.open("w", encoding="utf-8") as raw:
        for page_number, page in enumerate(reader.pages, start=1):
            try:
                text = clean_text(page.extract_text())
            except Exception as exc:
                text = f"[EXTRACTION_ERROR] {exc}"

            raw.write(f"\n\n--- PAGE {page_number} ---\n{text}\n")
            part_numbers = sorted(set(match.group(0) for match in PART_PATTERN.finditer(text)))
            figures = sorted(set(match.group(0) for match in FIG_PATTERN.finditer(text)))
            vins = sorted(set(match.group(0) for match in VIN_PATTERN.finditer(text)))
            pages.append(
                {
                    "page": page_number,
                    "char_count": len(text),
                    "part_number_count": len(part_numbers),
                    "figure_count": len(figures),
                    "vin_count": len(vins),
                    "sample": text[:500],
                }
            )

            for match in PART_PATTERN.finditer(text):
                part_rows.append(
                    {
                        "part_number": match.group(0),
                        "source_id": sid,
                        "source_year": item["year"],
                        "source_kind": item["kind"],
                        "page": page_number,
                        "context": context_for(text, match.start(), match.end()),
                    }
                )

    meta = {
        "source_id": sid,
        "status": "ok",
        "path": str(path),
        "filename": path.name,
        "year": item["year"],
        "kind": item["kind"],
        "size_bytes": path.stat().st_size,
        "sha256": sha256(path),
        "page_count": len(reader.pages),
        "raw_text_path": str(raw_path.relative_to(ROOT)),
        "pages": pages,
    }
    return meta, part_rows


def build_parts(part_rows):
    grouped = defaultdict(list)
    for row in part_rows:
        grouped[row["part_number"]].append(row)

    parts = []
    for part_number, rows in sorted(grouped.items()):
        years = sorted(set(row["source_year"] for row in rows if row["source_year"].isdigit()))
        sources = sorted(set(row["source_id"] for row in rows))
        pages = [
            {
                "source_id": row["source_id"],
                "year": row["source_year"],
                "page": row["page"],
                "context": row["context"],
            }
            for row in rows[:20]
        ]
        parts.append(
            {
                "part_number": part_number,
                "model": "Y60",
                "years": years,
                "occurrence_count": len(rows),
                "source_count": len(sources),
                "sources": sources,
                "evidence": pages,
                "name_ar": "",
                "name_en": "",
                "category": "",
                "oem_status": "unverified",
                "fitment_notes": "",
                "maintenance_notes": "",
            }
        )
    return parts


def write_csv(path, rows):
    if not rows:
        return
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def main():
    data_dir = ROOT / "data"
    raw_dir = data_dir / "raw_text"
    extracted_dir = data_dir / "extracted"
    raw_dir.mkdir(parents=True, exist_ok=True)
    extracted_dir.mkdir(parents=True, exist_ok=True)

    sources = []
    part_rows = []
    for index, item in enumerate(PDFS, start=1):
        meta, rows = extract_pdf(item, index, raw_dir)
        sources.append(meta)
        part_rows.extend(rows)

    parts = build_parts(part_rows)
    generated_at = datetime.now(timezone.utc).isoformat()

    database = {
        "generated_at": generated_at,
        "model": "Nissan Patrol Y60",
        "source_count": len(sources),
        "part_count": len(parts),
        "sources": sources,
        "parts": parts,
    }

    (extracted_dir / "y60_sources.json").write_text(
        json.dumps(sources, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (extracted_dir / "y60_parts_database.json").write_text(
        json.dumps(database, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    write_csv(extracted_dir / "y60_part_occurrences.csv", part_rows)
    write_csv(
        extracted_dir / "y60_parts_index.csv",
        [
            {
                "part_number": part["part_number"],
                "years": ",".join(part["years"]),
                "occurrence_count": part["occurrence_count"],
                "source_count": part["source_count"],
                "first_context": part["evidence"][0]["context"] if part["evidence"] else "",
            }
            for part in parts
        ],
    )

    summary = {
        "generated_at": generated_at,
        "source_count": len(sources),
        "ok_sources": sum(1 for source in sources if source["status"] == "ok"),
        "part_occurrence_count": len(part_rows),
        "unique_part_count": len(parts),
        "outputs": [
            "data/extracted/y60_sources.json",
            "data/extracted/y60_parts_database.json",
            "data/extracted/y60_part_occurrences.csv",
            "data/extracted/y60_parts_index.csv",
        ],
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
