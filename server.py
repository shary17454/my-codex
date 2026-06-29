#!/usr/bin/env python3
import json
import sqlite3
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "data" / "app_database.sqlite"


def rows(con, query, params=()):
    con.row_factory = sqlite3.Row
    return [dict(row) for row in con.execute(query, params).fetchall()]


def part_payload(con, part):
    part_number = part["part_number"]
    part["years"] = [row["year"] for row in rows(con, "SELECT year FROM part_years WHERE part_number = ? ORDER BY year", (part_number,))]
    part["engines"] = [row["engine"] for row in rows(con, "SELECT engine FROM part_engines WHERE part_number = ? ORDER BY engine", (part_number,))]
    part["date_ranges"] = [row["date_range"] for row in rows(con, "SELECT date_range FROM part_date_ranges WHERE part_number = ? ORDER BY date_range", (part_number,))]
    part["evidence"] = rows(
        con,
        """
        SELECT source_id, source_year AS year, page, reference, quantity, context
        FROM evidence
        WHERE part_number = ?
        ORDER BY id
        LIMIT 6
        """,
        (part_number,),
    )
    return part


def load_catalog():
    with sqlite3.connect(DB_PATH) as con:
        parts = rows(
            con,
            """
            SELECT part_number, name_ar, name_en, model, category, category_ar,
                   occurrence_count, source_count, weighted_source_score, confidence, audit_status, rarity
            FROM parts
            ORDER BY confidence DESC, source_count DESC, part_number
            """,
        )
        parts = [part_payload(con, part) for part in parts]
        sources = rows(
            con,
            """
            SELECT source_id, filename, source_year AS year, kind, page_count, duplicate_group_json
            FROM sources
            ORDER BY source_id
            """,
        )
        for source in sources:
            source["duplicate_group"] = json.loads(source.pop("duplicate_group_json") or "[]")
        stats = rows(con, "SELECT * FROM catalog_stats")[0]
        metadata = {row["key"]: row["value"] for row in rows(con, "SELECT key, value FROM metadata")}

    return {
        "generated_at": metadata.get("generated_at", ""),
        "model": metadata.get("model", "Nissan Patrol Y60"),
        "app_name": "بطل الدروب",
        "audit_method": metadata.get("audit_method", ""),
        "database": {"engine": "sqlite", "path": "data/app_database.sqlite", "schema_version": 1},
        "source_count": stats["source_count"],
        "record_count": stats["evidence_count"],
        "part_count": stats["part_count"],
        "sources": sources,
        "parts": parts,
    }


def search_parts(query="", category="", limit=200):
    with sqlite3.connect(DB_PATH) as con:
        params = []
        where = []
        if category and category != "all":
            where.append("category = ?")
            params.append(category)
        if query:
            like = f"%{query}%"
            where.append("(part_number LIKE ? OR name_en LIKE ? OR category_ar LIKE ?)")
            params.extend([like, like, like])
        sql = """
            SELECT part_number, name_ar, name_en, model, category, category_ar,
                   occurrence_count, source_count, weighted_source_score, confidence, audit_status, rarity
            FROM parts
        """
        if where:
            sql += " WHERE " + " AND ".join(where)
        sql += " ORDER BY confidence DESC, source_count DESC, part_number LIMIT ?"
        params.append(limit)
        return [part_payload(con, part) for part in rows(con, sql, params)]


class Handler(SimpleHTTPRequestHandler):
    def send_json_headers(self, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()

    def send_json(self, payload, status=200):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_HEAD(self):
        parsed = urlparse(self.path)
        if parsed.path in {"/api/catalog", "/api/parts", "/api/stats"}:
            self.send_json_headers()
            return
        super().do_HEAD()

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/catalog":
            self.send_json(load_catalog())
            return
        if parsed.path == "/api/parts":
            params = parse_qs(parsed.query)
            self.send_json(
                {
                    "parts": search_parts(
                        query=params.get("q", [""])[0],
                        category=params.get("category", [""])[0],
                        limit=int(params.get("limit", ["200"])[0]),
                    )
                }
            )
            return
        if parsed.path == "/api/stats":
            with sqlite3.connect(DB_PATH) as con:
                self.send_json(rows(con, "SELECT * FROM catalog_stats")[0])
            return
        super().do_GET()


def main():
    if not DB_PATH.exists():
        raise SystemExit(f"Missing database: {DB_PATH}")
    server = ThreadingHTTPServer(("0.0.0.0", 5005), Handler)
    print("Serving Batal Al-Droob app with SQLite API on http://0.0.0.0:5005/")
    server.serve_forever()


if __name__ == "__main__":
    main()
