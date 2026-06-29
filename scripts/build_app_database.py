#!/usr/bin/env python3
import json
import csv
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDITED_JSON = ROOT / "data" / "audited" / "y60_audited_database.json"
AUDITED_RECORDS_CSV = ROOT / "data" / "audited" / "y60_audited_records.csv"
DB_PATH = ROOT / "data" / "app_database.sqlite"
APP_JSON = ROOT / "data" / "y60_app_catalog.json"


SCHEMA = """
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS metadata;
DROP TABLE IF EXISTS evidence;
DROP TABLE IF EXISTS part_records;
DROP TABLE IF EXISTS part_years;
DROP TABLE IF EXISTS part_engines;
DROP TABLE IF EXISTS part_date_ranges;
DROP TABLE IF EXISTS parts;
DROP TABLE IF EXISTS sources;

CREATE TABLE metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE sources (
  source_id TEXT PRIMARY KEY,
  filename TEXT,
  source_year TEXT,
  kind TEXT,
  page_count INTEGER,
  duplicate_group_json TEXT
);

CREATE TABLE parts (
  part_number TEXT PRIMARY KEY,
  name_ar TEXT,
  name_en TEXT,
  model TEXT NOT NULL,
  category TEXT,
  category_ar TEXT,
  occurrence_count INTEGER NOT NULL DEFAULT 0,
  source_count INTEGER NOT NULL DEFAULT 0,
  weighted_source_score REAL NOT NULL DEFAULT 0,
  confidence INTEGER NOT NULL DEFAULT 0,
  audit_status TEXT,
  rarity TEXT
);

CREATE TABLE part_years (
  part_number TEXT NOT NULL REFERENCES parts(part_number) ON DELETE CASCADE,
  year TEXT NOT NULL,
  PRIMARY KEY (part_number, year)
);

CREATE TABLE part_engines (
  part_number TEXT NOT NULL REFERENCES parts(part_number) ON DELETE CASCADE,
  engine TEXT NOT NULL,
  PRIMARY KEY (part_number, engine)
);

CREATE TABLE part_date_ranges (
  part_number TEXT NOT NULL REFERENCES parts(part_number) ON DELETE CASCADE,
  date_range TEXT NOT NULL,
  PRIMARY KEY (part_number, date_range)
);

CREATE TABLE evidence (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  part_number TEXT NOT NULL REFERENCES parts(part_number) ON DELETE CASCADE,
  source_id TEXT REFERENCES sources(source_id),
  source_year TEXT,
  page INTEGER,
  reference TEXT,
  quantity TEXT,
  context TEXT
);

CREATE TABLE part_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  part_number TEXT NOT NULL REFERENCES parts(part_number) ON DELETE CASCADE,
  reference TEXT,
  name_en TEXT,
  name_ar TEXT,
  source_id TEXT REFERENCES sources(source_id),
  source_year TEXT,
  source_kind TEXT,
  page INTEGER,
  quantity TEXT,
  engines_json TEXT,
  date_ranges_json TEXT,
  context TEXT,
  source_weight REAL
);

CREATE INDEX idx_parts_category ON parts(category);
CREATE INDEX idx_parts_confidence ON parts(confidence);
CREATE INDEX idx_parts_name_en ON parts(name_en);
CREATE INDEX idx_evidence_part ON evidence(part_number);
CREATE INDEX idx_evidence_source ON evidence(source_id);
CREATE INDEX idx_part_records_part ON part_records(part_number);
CREATE INDEX idx_part_records_source ON part_records(source_id);
CREATE INDEX idx_part_records_page ON part_records(page);
CREATE INDEX idx_part_years_year ON part_years(year);
CREATE INDEX idx_part_engines_engine ON part_engines(engine);

CREATE VIEW catalog_stats AS
SELECT
  (SELECT COUNT(*) FROM parts) AS part_count,
  (SELECT COUNT(*) FROM sources) AS source_count,
  (SELECT COUNT(*) FROM part_records) AS record_count,
  (SELECT COUNT(*) FROM evidence) AS evidence_count,
  (SELECT COUNT(*) FROM parts WHERE confidence < 70) AS needs_review_count,
  (SELECT ROUND(AVG(confidence), 2) FROM parts) AS average_confidence;
"""


def connect():
    if DB_PATH.exists():
        DB_PATH.unlink()
    con = sqlite3.connect(DB_PATH)
    con.execute("PRAGMA journal_mode = WAL")
    con.execute("PRAGMA synchronous = NORMAL")
    con.executescript(SCHEMA)
    return con


def create_fts(con):
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
        return True
    except sqlite3.OperationalError:
        return False


def insert_data(con, data):
    con.executemany(
        "INSERT INTO metadata(key, value) VALUES (?, ?)",
        [
            ("generated_at", data.get("generated_at", "")),
            ("app_name", "بطل الدروب"),
            ("model", data.get("model", "")),
            ("audit_method", data.get("audit_method", "")),
            ("source_count", str(data.get("source_count", 0))),
            ("record_count", str(data.get("record_count", 0))),
            ("part_count", str(data.get("part_count", 0))),
            ("unique_source_hash_count", str(data.get("unique_source_hash_count", 0))),
        ],
    )

    con.executemany(
        """
        INSERT INTO sources(source_id, filename, source_year, kind, page_count, duplicate_group_json)
        VALUES (:source_id, :filename, :year, :kind, :page_count, :duplicate_group_json)
        """,
        [
            {
                **source,
                "duplicate_group_json": json.dumps(source.get("duplicate_group", []), ensure_ascii=False),
            }
            for source in data["sources"]
        ],
    )

    for part in data["parts"]:
        con.execute(
            """
            INSERT INTO parts(
              part_number, name_ar, name_en, model, category, category_ar,
              occurrence_count, source_count, weighted_source_score, confidence, audit_status, rarity
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                part["part_number"],
                part.get("name_ar", ""),
                part.get("name_en", ""),
                part.get("model", "Y60"),
                part.get("category", ""),
                part.get("category_ar", ""),
                part.get("occurrence_count", 0),
                part.get("source_count", 0),
                part.get("weighted_source_score", 0),
                part.get("confidence", 0),
                part.get("audit_status", ""),
                part.get("rarity", ""),
            ),
        )

        con.executemany(
            "INSERT OR IGNORE INTO part_years(part_number, year) VALUES (?, ?)",
            [(part["part_number"], year) for year in part.get("years", [])],
        )
        con.executemany(
            "INSERT OR IGNORE INTO part_engines(part_number, engine) VALUES (?, ?)",
            [(part["part_number"], engine) for engine in part.get("engines", [])],
        )
        con.executemany(
            "INSERT OR IGNORE INTO part_date_ranges(part_number, date_range) VALUES (?, ?)",
            [(part["part_number"], date_range) for date_range in part.get("date_ranges", [])],
        )
        con.executemany(
            """
            INSERT INTO evidence(part_number, source_id, source_year, page, reference, quantity, context)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    part["part_number"],
                    item.get("source_id", ""),
                    str(item.get("year", "")),
                    item.get("page"),
                    item.get("reference", ""),
                    item.get("quantity", ""),
                    item.get("context", ""),
                )
                for item in part.get("evidence", [])
            ],
        )


def fill_fts(con, parts):
    row = con.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='parts_fts'").fetchone()
    if not row:
        return
    for part in parts:
        con.execute(
            """
            INSERT INTO parts_fts(part_number, name_en, name_ar, category_ar, engines, years, evidence)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                part["part_number"],
                part.get("name_en", ""),
                part.get("name_ar", ""),
                part.get("category_ar", ""),
                " ".join(part.get("engines", [])),
                " ".join(part.get("years", [])),
                " ".join(item.get("context", "") for item in part.get("evidence", [])),
            ),
        )


def insert_full_records(con):
    with AUDITED_RECORDS_CSV.open(encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        batch = []
        for row in reader:
            batch.append(
                (
                    row["part_number"],
                    row["reference"],
                    row["name_en"],
                    row["name_ar"],
                    row["source_id"],
                    row["source_year"],
                    row["source_kind"],
                    int(row["page"]) if row["page"] else None,
                    row["quantity"],
                    row["engines"],
                    row["date_ranges"],
                    row["context"],
                    float(row["source_weight"]) if row["source_weight"] else 0.0,
                )
            )
            if len(batch) >= 5000:
                con.executemany(
                    """
                    INSERT INTO part_records(
                      part_number, reference, name_en, name_ar, source_id, source_year,
                      source_kind, page, quantity, engines_json, date_ranges_json, context, source_weight
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    batch,
                )
                batch = []
        if batch:
            con.executemany(
                """
                INSERT INTO part_records(
                  part_number, reference, name_en, name_ar, source_id, source_year,
                  source_kind, page, quantity, engines_json, date_ranges_json, context, source_weight
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                batch,
            )


def export_app_json(con, data):
    parts = []
    rows = con.execute(
        """
        SELECT part_number, name_ar, name_en, model, category, category_ar,
               occurrence_count, source_count, weighted_source_score, confidence, audit_status, rarity
        FROM parts
        ORDER BY confidence DESC, source_count DESC, part_number
        """
    ).fetchall()
    for row in rows:
        part_number = row[0]
        evidence = [
            {
                "source_id": item[0],
                "year": item[1],
                "page": item[2],
                "reference": item[3],
                "quantity": item[4],
                "context": item[5],
            }
            for item in con.execute(
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
        parts.append(
            {
                "part_number": part_number,
                "name_ar": row[1],
                "name_en": row[2],
                "model": row[3],
                "years": [r[0] for r in con.execute("SELECT year FROM part_years WHERE part_number = ? ORDER BY year", (part_number,))],
                "engines": [r[0] for r in con.execute("SELECT engine FROM part_engines WHERE part_number = ? ORDER BY engine", (part_number,))],
                "date_ranges": [r[0] for r in con.execute("SELECT date_range FROM part_date_ranges WHERE part_number = ? ORDER BY date_range", (part_number,))],
                "category": row[4],
                "category_ar": row[5],
                "occurrence_count": row[6],
                "source_count": row[7],
                "weighted_source_score": row[8],
                "confidence": row[9],
                "audit_status": row[10],
                "rarity": row[11],
                "evidence": evidence,
            }
        )

    sources = [
        {
            "source_id": row[0],
            "filename": row[1],
            "year": row[2],
            "kind": row[3],
            "page_count": row[4],
            "duplicate_group": json.loads(row[5] or "[]"),
        }
        for row in con.execute("SELECT source_id, filename, source_year, kind, page_count, duplicate_group_json FROM sources ORDER BY source_id")
    ]

    output = {
        "generated_at": data.get("generated_at", ""),
        "app_name": "بطل الدروب",
        "model": data.get("model", "Nissan Patrol Y60"),
        "audit_method": data.get("audit_method", ""),
        "database": {
            "engine": "sqlite",
            "path": "data/app_database.sqlite",
            "schema_version": 1,
        },
        "source_count": len(sources),
        "record_count": con.execute("SELECT COUNT(*) FROM part_records").fetchone()[0],
        "part_count": len(parts),
        "sources": sources,
        "parts": parts,
    }
    APP_JSON.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")


def main():
    data = json.loads(AUDITED_JSON.read_text(encoding="utf-8"))
    con = connect()
    try:
        create_fts(con)
        insert_data(con, data)
        insert_full_records(con)
        fill_fts(con, data["parts"])
        con.commit()
        export_app_json(con, data)
        stats = dict(
            zip(
                ["part_count", "source_count", "record_count", "needs_review_count", "average_confidence"],
                con.execute("SELECT part_count, source_count, record_count, needs_review_count, average_confidence FROM catalog_stats").fetchone(),
            )
        )
    finally:
        con.close()

    print(json.dumps({
        "database": str(DB_PATH.relative_to(ROOT)),
        "app_export": str(APP_JSON.relative_to(ROOT)),
        "stats": stats,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
