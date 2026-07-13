#!/usr/bin/env python3
import csv
import json
import re
import sqlite3
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "app_database.sqlite"
APP_JSON = ROOT / "data" / "y60_app_catalog.json"
DEFAULT_CSV = Path(
    "/Users/shrybnhshymbnmrzwqbnhwyd/Documents/Codex/2026-07-04/"
    "pdf-1-y60-y60-y61-y62/outputs/الكتلوج النهائي الشامل الكامل المترجم/"
    "الكتلوج النهائي الشامل الكامل المترجم.csv"
)

SOURCE_ID = "translated_full_catalog_by_model_y62"
SOURCE_FILENAME = "الكتلوج النهائي الشامل الكامل المترجم.csv"


CATEGORY_MAP = {
    "AXLE & SUSPENSION": ("suspension", "تعليق ومحاور"),
    "ELECTRICAL UNIT": ("electrical", "كهرباء"),
    "BODY ELECTRICAL": ("electrical", "كهرباء"),
    "ENGINE ELECTRICAL": ("electrical", "كهرباء"),
    "BODY": ("body", "هيكل"),
    "BRAKE": ("brake", "فرامل"),
    "FUEL": ("fuel", "وقود"),
    "COOLING": ("cooling", "تبريد"),
    "EXHAUST": ("cooling", "عادم وتبريد"),
    "POWER TRAIN": ("drivetrain", "مجموعة نقل الحركة"),
    "SEAT": ("interior", "داخلية"),
}


def normalize_part_number(value):
    return re.sub(r"[^A-Z0-9]", "", (value or "").upper())


def clean(value):
    return " ".join((value or "").strip().split())


def infer_category(row):
    en = (row.get("category_name") or "").upper()
    ar = clean(row.get("category_name_ar"))
    for key, value in CATEGORY_MAP.items():
        if key in en:
            return value
    if "كهرباء" in ar:
        return "electrical", "كهرباء"
    if "تعليق" in ar or "محاور" in ar:
        return "suspension", ar or "تعليق ومحاور"
    if "فرامل" in ar:
        return "brake", "فرامل"
    if "وقود" in ar:
        return "fuel", "وقود"
    if "تبريد" in ar or "عادم" in ar:
        return "cooling", ar or "تبريد"
    if "مقاعد" in ar or "أحزمة" in ar:
        return "interior", ar or "داخلية"
    if "هيكل" in ar:
        return "body", ar or "هيكل"
    return "general", ar or "عام"


def years_from_range(value):
    years = []
    for match in re.findall(r"(19\d{2}|20\d{2})", value or ""):
        if match not in years:
            years.append(match)
    return years


def engines_from_row(row):
    text = " ".join(
        clean(row.get(field))
        for field in ("engine", "applicable_models", "applicable_models_ar")
    )
    engines = []
    for engine in re.findall(r"\b(?:TB|TD|RD|ZD|VK)\d{2}[A-Z]*\b", text.upper()):
        if engine not in engines:
            engines.append(engine)
    return engines


def source_context(row):
    bits = [
        clean(row.get("model_code")),
        clean(row.get("market_ar") or row.get("market")),
        clean(row.get("engine")),
        clean(row.get("grade_ar") or row.get("grade")),
        clean(row.get("category_name_ar") or row.get("category_name")),
        clean(row.get("unit_code")),
        clean(row.get("figure_no")),
        clean(row.get("unit_name_ar") or row.get("unit_name")),
        clean(row.get("position_code")),
        clean(row.get("part_number")),
        clean(row.get("part_name_ar") or row.get("part_name")),
        clean(row.get("quantity")),
        clean(row.get("applicable_models_ar") or row.get("applicable_models")),
        clean(row.get("range")),
    ]
    return " | ".join(bit for bit in bits if bit)[:1000]


def ensure_extra_columns(con):
    columns = {row[1] for row in con.execute("PRAGMA table_info(parts)").fetchall()}
    for name, ddl in {
        "part_numbers_json": "ALTER TABLE parts ADD COLUMN part_numbers_json TEXT",
        "primary_oem_number": "ALTER TABLE parts ADD COLUMN primary_oem_number TEXT",
        "diagram_key": "ALTER TABLE parts ADD COLUMN diagram_key TEXT",
    }.items():
        if name not in columns:
            con.execute(ddl)


def reset_source(con):
    con.execute("DELETE FROM evidence WHERE source_id = ?", (SOURCE_ID,))
    con.execute("DELETE FROM part_records WHERE source_id = ?", (SOURCE_ID,))
    con.execute("DELETE FROM sources WHERE source_id = ?", (SOURCE_ID,))
    con.execute(
        """
        INSERT INTO sources(source_id, filename, source_year, kind, page_count, duplicate_group_json)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            SOURCE_ID,
            SOURCE_FILENAME,
            "Y62",
            "translated_catalog_csv",
            None,
            json.dumps([], ensure_ascii=False),
        ),
    )


def collect_parts(csv_path):
    parts = {}
    records = []
    seen_records = set()
    total_rows = 0
    skipped_blank = 0
    skipped_duplicate_rows = 0

    with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            total_rows += 1
            raw_part_number = clean(row.get("part_number")).upper()
            normalized = normalize_part_number(raw_part_number)
            if not normalized:
                skipped_blank += 1
                continue

            part_number = raw_part_number or normalized
            category, category_ar = infer_category(row)
            context = source_context(row)
            record_key = (
                normalized,
                clean(row.get("unit_code")),
                clean(row.get("figure_no")),
                clean(row.get("position_code")),
                clean(row.get("range")),
                clean(row.get("quantity")),
                clean(row.get("part_url")),
            )
            if record_key in seen_records:
                skipped_duplicate_rows += 1
                continue
            seen_records.add(record_key)

            item = parts.setdefault(
                normalized,
                {
                    "part_number": part_number,
                    "name_ar": "",
                    "name_en": "",
                    "model": clean(row.get("model_code")) or "Y62",
                    "category": category,
                    "category_ar": category_ar,
                    "occurrence_count": 0,
                    "years": set(),
                    "engines": set(),
                    "date_ranges": set(),
                    "primary_oem_number": part_number,
                    "diagram_key": clean(row.get("position_code")) or part_number,
                    "evidence_context": context,
                },
            )
            item["occurrence_count"] += 1
            if not item["name_ar"]:
                item["name_ar"] = clean(row.get("part_name_ar"))
            if not item["name_en"]:
                item["name_en"] = clean(row.get("part_name"))
            if not item["name_ar"] or item["name_ar"] == "غير مذكور في المصدر":
                item["name_ar"] = clean(row.get("unit_name_ar")) or item["name_ar"]
            if not item["name_en"]:
                item["name_en"] = clean(row.get("unit_name"))
            for year in years_from_range(row.get("range")):
                item["years"].add(year)
            for engine in engines_from_row(row):
                item["engines"].add(engine)
            date_range = clean(row.get("range"))
            if date_range:
                item["date_ranges"].add(date_range)

            records.append(
                {
                    "part_number": part_number,
                    "reference": clean(row.get("position_code")),
                    "name_en": clean(row.get("part_name")),
                    "name_ar": clean(row.get("part_name_ar")),
                    "source_year": clean(row.get("model_code")) or "Y62",
                    "page": None,
                    "quantity": clean(row.get("quantity")),
                    "engines": engines_from_row(row),
                    "date_ranges": [date_range] if date_range else [],
                    "context": context,
                    "source_weight": 1.0,
                }
            )

    return parts, records, {
        "total_rows": total_rows,
        "skipped_blank_part_number": skipped_blank,
        "skipped_duplicate_rows": skipped_duplicate_rows,
    }


def existing_part_number_map(con):
    result = {}
    for (part_number,) in con.execute("SELECT part_number FROM parts"):
        normalized = normalize_part_number(part_number)
        if normalized:
            result[normalized] = part_number
    return result


def upsert_parts(con, parts):
    existing = existing_part_number_map(con)
    inserted = 0
    enriched = 0
    for normalized, part in parts.items():
        db_part_number = existing.get(normalized, part["part_number"])
        years = sorted(part["years"])
        engines = sorted(part["engines"])
        date_ranges = sorted(part["date_ranges"])
        confidence = 88 if part["name_ar"] and part["name_en"] else 75
        rarity = "مدمج من الكتالوج الشامل المترجم"
        part_numbers_json = json.dumps([db_part_number], ensure_ascii=False)

        if normalized in existing:
            enriched += 1
            con.execute(
                """
                UPDATE parts
                SET
                  name_ar = COALESCE(NULLIF(name_ar, ''), ?),
                  name_en = COALESCE(NULLIF(name_en, ''), ?),
                  occurrence_count = MAX(occurrence_count, ?),
                  source_count = MAX(source_count, 1),
                  confidence = MAX(confidence, ?),
                  audit_status = COALESCE(NULLIF(audit_status, ''), ?),
                  rarity = COALESCE(NULLIF(rarity, ''), ?),
                  part_numbers_json = COALESCE(NULLIF(part_numbers_json, ''), ?),
                  primary_oem_number = COALESCE(NULLIF(primary_oem_number, ''), ?),
                  diagram_key = COALESCE(NULLIF(diagram_key, ''), ?)
                WHERE part_number = ?
                """,
                (
                    part["name_ar"],
                    part["name_en"],
                    part["occurrence_count"],
                    confidence,
                    "مدقق من كتالوج مترجم",
                    rarity,
                    part_numbers_json,
                    db_part_number,
                    part["diagram_key"],
                    db_part_number,
                ),
            )
        else:
            inserted += 1
            con.execute(
                """
                INSERT INTO parts(
                  part_number, name_ar, name_en, model, category, category_ar,
                  occurrence_count, source_count, weighted_source_score, confidence,
                  audit_status, rarity, part_numbers_json, primary_oem_number, diagram_key
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    db_part_number,
                    part["name_ar"],
                    part["name_en"],
                    part["model"],
                    part["category"],
                    part["category_ar"],
                    part["occurrence_count"],
                    1,
                    1.0,
                    confidence,
                    "مدقق من كتالوج مترجم",
                    rarity,
                    part_numbers_json,
                    db_part_number,
                    part["diagram_key"],
                ),
            )
            existing[normalized] = db_part_number

        for year in years:
            con.execute("INSERT OR IGNORE INTO part_years(part_number, year) VALUES (?, ?)", (db_part_number, year))
        for engine in engines:
            con.execute("INSERT OR IGNORE INTO part_engines(part_number, engine) VALUES (?, ?)", (db_part_number, engine))
        for date_range in date_ranges:
            con.execute("INSERT OR IGNORE INTO part_date_ranges(part_number, date_range) VALUES (?, ?)", (db_part_number, date_range))

    return inserted, enriched, existing


def insert_records(con, records, part_map):
    record_batch = []
    evidence_batch = []
    inserted = 0
    for record in records:
        normalized = normalize_part_number(record["part_number"])
        db_part_number = part_map.get(normalized, record["part_number"])
        record_batch.append(
            (
                db_part_number,
                record["reference"],
                record["name_en"],
                record["name_ar"],
                SOURCE_ID,
                record["source_year"],
                "translated_catalog_csv",
                record["page"],
                record["quantity"],
                json.dumps(record["engines"], ensure_ascii=False),
                json.dumps(record["date_ranges"], ensure_ascii=False),
                record["context"],
                record["source_weight"],
            )
        )
        evidence_batch.append(
            (
                db_part_number,
                SOURCE_ID,
                record["source_year"],
                record["page"],
                record["reference"],
                record["quantity"],
                record["context"],
            )
        )
        if len(record_batch) >= 5000:
            flush_records(con, record_batch, evidence_batch)
            inserted += len(record_batch)
            record_batch.clear()
            evidence_batch.clear()
    if record_batch:
        flush_records(con, record_batch, evidence_batch)
        inserted += len(record_batch)
    return inserted


def flush_records(con, records, evidence):
    con.executemany(
        """
        INSERT INTO part_records(
          part_number, reference, name_en, name_ar, source_id, source_year,
          source_kind, page, quantity, engines_json, date_ranges_json, context, source_weight
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        records,
    )
    con.executemany(
        """
        INSERT INTO evidence(part_number, source_id, source_year, page, reference, quantity, context)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        evidence,
    )


def rebuild_fts(con):
    if con.execute("SELECT name FROM sqlite_master WHERE name='parts_fts'").fetchone():
        con.execute("DROP TABLE parts_fts")
    try:
        con.execute(
            """
            CREATE VIRTUAL TABLE parts_fts USING fts5(
              part_number,
              name_en,
              name_ar,
              category_ar,
              engines,
              years,
              evidence,
              content=''
            )
            """
        )
        for row in con.execute(
            """
            SELECT p.part_number, p.name_en, p.name_ar, p.category_ar,
                   GROUP_CONCAT(DISTINCT pe.engine),
                   GROUP_CONCAT(DISTINCT py.year)
            FROM parts p
            LEFT JOIN part_engines pe ON pe.part_number = p.part_number
            LEFT JOIN part_years py ON py.part_number = p.part_number
            GROUP BY p.part_number
            """
        ):
            con.execute(
                """
                INSERT INTO parts_fts(part_number, name_en, name_ar, category_ar, engines, years, evidence)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (row[0], row[1] or "", row[2] or "", row[3] or "", row[4] or "", row[5] or "", ""),
            )
        return True
    except sqlite3.DatabaseError:
        return False


def export_app_json(con):
    data = {
        "generated_at": con.execute("SELECT datetime('now')").fetchone()[0],
        "app_name": "بطل الدروب",
        "model": "Nissan Patrol",
        "audit_method": "Y60 audited catalog + translated full catalog by model",
        "database": {"engine": "sqlite", "path": "data/app_database.sqlite", "schema_version": 1},
        "source_count": con.execute("SELECT COUNT(*) FROM sources").fetchone()[0],
        "record_count": con.execute("SELECT COUNT(*) FROM part_records").fetchone()[0],
        "part_count": con.execute("SELECT COUNT(*) FROM parts").fetchone()[0],
        "sources": [],
        "parts": [],
    }
    for row in con.execute("SELECT source_id, filename, source_year, kind, page_count, duplicate_group_json FROM sources ORDER BY source_id"):
        data["sources"].append(
            {
                "source_id": row[0],
                "filename": row[1],
                "year": row[2],
                "kind": row[3],
                "page_count": row[4],
                "duplicate_group": json.loads(row[5] or "[]"),
            }
        )
    cursor = con.execute(
        """
        SELECT part_number, name_ar, name_en, model, category, category_ar,
               occurrence_count, source_count, weighted_source_score, confidence,
               audit_status, rarity, part_numbers_json, primary_oem_number, diagram_key
        FROM parts
        ORDER BY model, category_ar, part_number
        """
    )
    for row in cursor:
        part_number = row[0]
        part_numbers = json.loads(row[12] or "[]")
        if not part_numbers:
            part_numbers = [part_number]
        evidence = [
            {
                "source_id": ev[0],
                "year": ev[1],
                "page": ev[2],
                "reference": ev[3],
                "quantity": ev[4],
                "context": ev[5],
            }
            for ev in con.execute(
                """
                SELECT source_id, source_year, page, reference, quantity, context
                FROM evidence
                WHERE part_number = ?
                ORDER BY id
                LIMIT 6
                """,
                (part_number,),
            )
        ]
        data["parts"].append(
            {
                "part_number": part_number,
                "name_ar": row[1] or "",
                "name_en": row[2] or "",
                "model": row[3] or "",
                "years": [r[0] for r in con.execute("SELECT year FROM part_years WHERE part_number = ? ORDER BY year", (part_number,))],
                "engines": [r[0] for r in con.execute("SELECT engine FROM part_engines WHERE part_number = ? ORDER BY engine", (part_number,))],
                "date_ranges": [r[0] for r in con.execute("SELECT date_range FROM part_date_ranges WHERE part_number = ? ORDER BY date_range", (part_number,))],
                "category": row[4] or "",
                "category_ar": row[5] or "",
                "occurrence_count": row[6] or 0,
                "source_count": row[7] or 0,
                "weighted_source_score": row[8] or 0,
                "confidence": row[9] or 0,
                "audit_status": row[10] or "",
                "rarity": row[11] or "",
                "evidence": evidence,
                "part_numbers": part_numbers,
                "primary_oem_number": row[13] or part_number,
                "diagram_key": row[14] or part_number,
            }
        )
    APP_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def main():
    csv_path = Path(__import__("sys").argv[1]) if len(__import__("sys").argv) > 1 else DEFAULT_CSV
    if not csv_path.exists():
        raise SystemExit(f"Missing translated catalog CSV: {csv_path}")
    if not DB_PATH.exists():
        raise SystemExit(f"Missing app database: {DB_PATH}")

    parts, records, metrics = collect_parts(csv_path)
    with sqlite3.connect(DB_PATH) as con:
        con.execute("PRAGMA foreign_keys = ON")
        con.execute("PRAGMA journal_mode = WAL")
        ensure_extra_columns(con)
        reset_source(con)
        inserted_parts, enriched_parts, part_map = upsert_parts(con, parts)
        inserted_records = insert_records(con, records, part_map)
        con.execute(
            "INSERT OR REPLACE INTO metadata(key, value) VALUES (?, ?)",
            ("translated_catalog_import", SOURCE_FILENAME),
        )
        con.execute(
            "INSERT OR REPLACE INTO metadata(key, value) VALUES (?, ?)",
            ("translated_catalog_rows", str(metrics["total_rows"])),
        )
        fts_rebuilt = rebuild_fts(con)
        con.commit()
        export_app_json(con)
        stats = dict(
            zip(
                ["part_count", "source_count", "record_count", "evidence_count", "needs_review_count", "average_confidence"],
                con.execute(
                    "SELECT part_count, source_count, record_count, evidence_count, needs_review_count, average_confidence FROM catalog_stats"
                ).fetchone(),
            )
        )

    print(
        json.dumps(
            {
                "source": str(csv_path),
                "unique_parts_in_source": len(parts),
                "inserted_parts": inserted_parts,
                "enriched_existing_parts": enriched_parts,
                "inserted_records": inserted_records,
                "fts_rebuilt": fts_rebuilt,
                "metrics": metrics,
                "stats": stats,
                "app_json": str(APP_JSON.relative_to(ROOT)),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
