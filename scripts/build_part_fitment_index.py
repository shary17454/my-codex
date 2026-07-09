#!/usr/bin/env python3
"""Export a lightweight part fitment and catalog reference index.

The app can ship this JSON without bundling the heavy PDF files. Each part keeps
its OEM numbers, compatibility hints, diagram/reference code, source pages, and
shared-fitment candidates extracted from the audited SQLite database.
"""

from __future__ import annotations

import json
import re
import sqlite3
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "app_database.sqlite"
OUT_PATHS = [
    ROOT / "data" / "part_fitment_index.json",
    ROOT / "ios" / "BatalAlDroob" / "BatalAlDroob" / "Web" / "data" / "part_fitment_index.json",
]

SOURCE_ASSET_PATHS = {
    "01_combined_catalog_1988_1997": "catalog/patrol_full_unique/Y60/unknown/patrol_catalog_0098__Y60_1988-1997_all_11_catalogs_combined.pdf",
    "02_vin_report_VIN": "catalog/patrol_full_unique/Y60/unknown/patrol_catalog_0087__WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.reportlab.pdf",
    "03_year_catalog_1988": "catalog/pdfs/y60_1988.pdf",
    "05_year_catalog_1989": "catalog/pdfs/y60_1989.pdf",
    "06_year_catalog_1990": "catalog/pdfs/y60_1990.pdf",
    "07_year_catalog_1991": "catalog/pdfs/y60_1991.pdf",
    "08_year_catalog_1992": "catalog/pdfs/y60_1992.pdf",
    "09_year_catalog_1993": "catalog/pdfs/y60_1993.pdf",
    "10_year_catalog_1994": "catalog/pdfs/y60_1994.pdf",
    "11_year_catalog_1995": "catalog/pdfs/y60_1995.pdf",
    "12_year_catalog_1996": "catalog/pdfs/y60_1996.pdf",
    "13_year_catalog_1997": "catalog/pdfs/y60_1997.pdf",
}

PART_NUMBER_RE = re.compile(r"\b[0-9A-Z]{5}-?[0-9A-Z]{5}\b")


def load_json(value: str | None, fallback: Any) -> Any:
    if not value:
        return fallback
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return fallback


def format_part_number(value: str) -> str:
    raw = re.sub(r"[^0-9A-Z]", "", (value or "").upper())
    if len(raw) != 10:
        return ""
    return f"{raw[:5]}-{raw[5:]}"


def numbers_from_text(*values: Any) -> list[str]:
    numbers: list[str] = []
    for value in values:
        if value is None:
            continue
        text = value if isinstance(value, str) else json.dumps(value, ensure_ascii=False)
        for match in PART_NUMBER_RE.findall(text.upper()):
            formatted = format_part_number(match)
            if formatted and formatted not in numbers:
                numbers.append(formatted)
    return numbers[:24]


def rows(con: sqlite3.Connection, query: str, params: tuple[Any, ...] = ()) -> list[sqlite3.Row]:
    return list(con.execute(query, params))


def source_catalog(con: sqlite3.Connection) -> dict[str, dict[str, Any]]:
    output: dict[str, dict[str, Any]] = {}
    for row in rows(con, "SELECT source_id, filename, source_year, kind, page_count FROM sources ORDER BY source_id"):
        source_id = row["source_id"]
        output[source_id] = {
            "source_id": source_id,
            "filename": row["filename"],
            "year": row["source_year"],
            "kind": row["kind"],
            "page_count": row["page_count"],
            "bundled_pdf": False,
            "asset_path": SOURCE_ASSET_PATHS.get(source_id, ""),
            "remote_url": "",
        }
    return output


def evidence_for_part(con: sqlite3.Connection, part_number: str) -> list[dict[str, Any]]:
    items = []
    seen = set()
    for row in rows(
        con,
        """
        SELECT source_id, source_year, page, reference, quantity, context
        FROM evidence
        WHERE part_number = ?
        ORDER BY
          CASE WHEN source_id LIKE '%year_catalog%' THEN 0 ELSE 1 END,
          page IS NULL,
          page,
          id
        LIMIT 24
        """,
        (part_number,),
    ):
        key = (row["source_id"], row["page"], row["reference"])
        if key in seen:
            continue
        seen.add(key)
        items.append({
            "source_id": row["source_id"],
            "year": row["source_year"],
            "page": row["page"],
            "reference": row["reference"] or "",
            "quantity": row["quantity"] or "",
            "context": (row["context"] or "")[:700],
            "source_pdf_path": SOURCE_ASSET_PATHS.get(row["source_id"], ""),
        })
    return items[:8]


def build_index() -> dict[str, Any]:
    con = sqlite3.connect(DB_PATH)
    con.row_factory = sqlite3.Row
    try:
        sources = source_catalog(con)
        parts: dict[str, dict[str, Any]] = {}
        shared_candidates: list[dict[str, Any]] = []
        for row in rows(
            con,
            """
            SELECT part_number, name_ar, name_en, model, category, category_ar,
                   occurrence_count, source_count, confidence, rarity,
                   part_numbers_json, primary_oem_number, diagram_key
            FROM parts
            ORDER BY part_number
            """,
        ):
            part_number = row["part_number"]
            years = [r[0] for r in con.execute("SELECT year FROM part_years WHERE part_number = ? ORDER BY year", (part_number,))]
            engines = [r[0] for r in con.execute("SELECT engine FROM part_engines WHERE part_number = ? ORDER BY engine", (part_number,))]
            date_ranges = [r[0] for r in con.execute("SELECT date_range FROM part_date_ranges WHERE part_number = ? ORDER BY date_range", (part_number,))]
            evidence = evidence_for_part(con, part_number)
            part_numbers = load_json(row["part_numbers_json"], [])
            for number in numbers_from_text(part_number, row["primary_oem_number"], row["part_numbers_json"], evidence):
                if number not in part_numbers:
                    part_numbers.append(number)
            primary_source = evidence[0] if evidence else {}
            shared_score = (len(years) * 2) + (len(engines) * 3) + int(row["source_count"] or 0)
            item = {
                "part_number": part_number,
                "part_numbers": part_numbers[:24],
                "primary_oem_number": row["primary_oem_number"] or part_number,
                "name_ar": row["name_ar"] or "",
                "name_en": row["name_en"] or "",
                "model": row["model"] or "",
                "category": row["category"] or "general",
                "category_ar": row["category_ar"] or "عام",
                "years": years,
                "engines": engines,
                "date_ranges": date_ranges[:12],
                "source_count": row["source_count"] or 0,
                "occurrence_count": row["occurrence_count"] or 0,
                "confidence": row["confidence"] or 0,
                "rarity": row["rarity"] or "",
                "diagram_key": row["diagram_key"] or (primary_source.get("reference") or part_number),
                "diagram_reference": primary_source.get("reference", ""),
                "source_pdf_path": primary_source.get("source_pdf_path", ""),
                "page_number": primary_source.get("page"),
                "evidence": evidence,
                "shared_fitment_score": shared_score,
            }
            parts[part_number] = item
            if len(years) >= 4 or len(engines) >= 2 or int(row["source_count"] or 0) >= 4:
                shared_candidates.append({
                    "part_number": part_number,
                    "score": shared_score,
                    "years": years,
                    "engines": engines,
                    "source_count": row["source_count"] or 0,
                    "occurrence_count": row["occurrence_count"] or 0,
                })

        shared_candidates.sort(key=lambda item: (-item["score"], item["part_number"]))
        return {
            "schema_version": 1,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "app_name": "بطل الدروب",
            "strategy": "Ship searchable part data and catalog references; keep heavy PDF files external/on-demand.",
            "pdfs_bundled": False,
            "source_count": len(sources),
            "part_count": len(parts),
            "sources": sources,
            "parts": parts,
            "shared_fitment_candidates": shared_candidates[:500],
        }
    finally:
        con.close()


def main() -> None:
    index = build_index()
    encoded = json.dumps(index, ensure_ascii=False, separators=(",", ":"))
    for path in OUT_PATHS:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(encoded, encoding="utf-8")
    print(json.dumps({
        "outputs": [str(path.relative_to(ROOT)) for path in OUT_PATHS],
        "part_count": index["part_count"],
        "source_count": index["source_count"],
        "shared_candidates": len(index["shared_fitment_candidates"]),
        "bytes": len(encoded.encode("utf-8")),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
