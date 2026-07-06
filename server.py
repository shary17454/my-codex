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


def init_app_tables(con):
    con.executescript(
        """
        CREATE TABLE IF NOT EXISTS app_users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          local_user_id TEXT NOT NULL UNIQUE,
          display_name TEXT,
          email TEXT,
          phone TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS app_vehicle_profiles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          local_user_id TEXT NOT NULL,
          vin TEXT,
          generation TEXT,
          year TEXT,
          trim TEXT,
          engine TEXT,
          transmission TEXT,
          color TEXT,
          plate_number TEXT,
          engine_number TEXT,
          country_of_origin TEXT,
          original_specs_json TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(local_user_id, vin)
        );

        CREATE TABLE IF NOT EXISTS app_maintenance_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          local_id TEXT,
          local_user_id TEXT NOT NULL,
          vin TEXT,
          service TEXT,
          service_date TEXT,
          odometer TEXT,
          cost TEXT,
          workshop TEXT,
          next_reminder TEXT,
          invoice_url TEXT,
          notes TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS app_part_requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          local_id TEXT,
          local_user_id TEXT NOT NULL,
          plan_id TEXT,
          product_id TEXT,
          fee_sar REAL,
          currency TEXT,
          status TEXT,
          generation TEXT,
          year TEXT,
          vin TEXT,
          engine TEXT,
          transmission TEXT,
          part_number TEXT,
          part_name TEXT,
          part_type TEXT,
          goal TEXT,
          notes TEXT,
          draft TEXT,
          payload_json TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS app_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          local_user_id TEXT,
          event_type TEXT NOT NULL,
          payload_json TEXT,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        """
    )
    con.commit()


def app_user_id(headers):
    value = headers.get("X-Batal-User") or ""
    return value.strip()[:80] or "local-demo-user"


def read_json_body(handler):
    length = int(handler.headers.get("Content-Length") or 0)
    if length <= 0:
        return {}
    body = handler.rfile.read(length)
    return json.loads(body.decode("utf-8") or "{}")


def upsert_user(con, local_user_id):
    con.execute(
        """
        INSERT INTO app_users (local_user_id)
        VALUES (?)
        ON CONFLICT(local_user_id) DO UPDATE SET updated_at = CURRENT_TIMESTAMP
        """,
        (local_user_id,),
    )


def save_vehicle_profile(payload, local_user_id):
    with sqlite3.connect(DB_PATH) as con:
        init_app_tables(con)
        upsert_user(con, local_user_id)
        con.execute(
            """
            INSERT INTO app_vehicle_profiles (
              local_user_id, vin, generation, year, trim, engine, transmission, color,
              plate_number, engine_number, country_of_origin, original_specs_json
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(local_user_id, vin) DO UPDATE SET
              generation = excluded.generation,
              year = excluded.year,
              trim = excluded.trim,
              engine = excluded.engine,
              transmission = excluded.transmission,
              color = excluded.color,
              plate_number = excluded.plate_number,
              engine_number = excluded.engine_number,
              country_of_origin = excluded.country_of_origin,
              original_specs_json = excluded.original_specs_json,
              updated_at = CURRENT_TIMESTAMP
            """,
            (
                local_user_id,
                payload.get("vin") or "NO-VIN",
                payload.get("generation"),
                payload.get("year"),
                payload.get("trim"),
                payload.get("engine"),
                payload.get("transmission"),
                payload.get("color"),
                payload.get("plate_number"),
                payload.get("engine_number"),
                payload.get("country_of_origin"),
                json.dumps(payload.get("original_specs") or {}, ensure_ascii=False),
            ),
        )
        con.commit()
    return {"ok": True, "saved": "vehicle_profile"}


def save_maintenance_log(payload, local_user_id):
    with sqlite3.connect(DB_PATH) as con:
        init_app_tables(con)
        upsert_user(con, local_user_id)
        con.execute(
            """
            INSERT INTO app_maintenance_logs (
              local_id, local_user_id, vin, service, service_date, odometer, cost,
              workshop, next_reminder, invoice_url, notes
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                payload.get("id"),
                local_user_id,
                payload.get("vin"),
                payload.get("service"),
                payload.get("date"),
                payload.get("odometer"),
                payload.get("cost"),
                payload.get("workshop"),
                payload.get("next"),
                payload.get("invoice_url"),
                payload.get("notes"),
            ),
        )
        con.commit()
    return {"ok": True, "saved": "maintenance_log"}


def save_part_request(payload, local_user_id):
    request = payload.get("request") or {}
    plan = payload.get("plan") or {}
    with sqlite3.connect(DB_PATH) as con:
        init_app_tables(con)
        upsert_user(con, local_user_id)
        con.execute(
            """
            INSERT INTO app_part_requests (
              local_id, local_user_id, plan_id, product_id, fee_sar, currency, status,
              generation, year, vin, engine, transmission, part_number, part_name,
              part_type, goal, notes, draft, payload_json
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                payload.get("id"),
                local_user_id,
                payload.get("plan_id") or plan.get("id"),
                payload.get("product_id") or plan.get("productId"),
                payload.get("fee_sar") or plan.get("priceSar"),
                payload.get("currency") or "SAR",
                payload.get("status") or "saved",
                request.get("generation"),
                request.get("year"),
                request.get("vin"),
                request.get("engine"),
                request.get("transmission"),
                request.get("part_number"),
                request.get("part_name"),
                request.get("part_type"),
                request.get("goal"),
                request.get("notes"),
                payload.get("draft"),
                json.dumps(payload, ensure_ascii=False),
            ),
        )
        con.commit()
    return {"ok": True, "saved": "part_request"}


def app_overview(local_user_id):
    with sqlite3.connect(DB_PATH) as con:
        init_app_tables(con)
        profile = rows(
            con,
            """
            SELECT * FROM app_vehicle_profiles
            WHERE local_user_id = ?
            ORDER BY updated_at DESC
            LIMIT 1
            """,
            (local_user_id,),
        )
        maintenance = rows(
            con,
            """
            SELECT * FROM app_maintenance_logs
            WHERE local_user_id = ?
            ORDER BY id DESC
            LIMIT 20
            """,
            (local_user_id,),
        )
        requests = rows(
            con,
            """
            SELECT * FROM app_part_requests
            WHERE local_user_id = ?
            ORDER BY id DESC
            LIMIT 20
            """,
            (local_user_id,),
        )
    return {
        "ok": True,
        "profile": profile[0] if profile else None,
        "maintenance": maintenance,
        "part_requests": requests,
    }


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
        if parsed.path in {"/api/catalog", "/api/parts", "/api/stats", "/api/app-overview"}:
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
        if parsed.path == "/api/app-overview":
            self.send_json(app_overview(app_user_id(self.headers)))
            return
        super().do_GET()

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path not in {"/api/vehicle-profile", "/api/maintenance", "/api/part-requests", "/api/events"}:
            self.send_json({"ok": False, "error": "Not found"}, status=404)
            return
        try:
            payload = read_json_body(self)
            local_user_id = app_user_id(self.headers)
            if parsed.path == "/api/vehicle-profile":
                self.send_json(save_vehicle_profile(payload, local_user_id), status=201)
                return
            if parsed.path == "/api/maintenance":
                self.send_json(save_maintenance_log(payload, local_user_id), status=201)
                return
            if parsed.path == "/api/part-requests":
                self.send_json(save_part_request(payload, local_user_id), status=201)
                return
            if parsed.path == "/api/events":
                with sqlite3.connect(DB_PATH) as con:
                    init_app_tables(con)
                    con.execute(
                        "INSERT INTO app_events (local_user_id, event_type, payload_json) VALUES (?, ?, ?)",
                        (
                            local_user_id,
                            str(payload.get("event_type") or "unknown")[:80],
                            json.dumps(payload, ensure_ascii=False),
                        ),
                    )
                    con.commit()
                self.send_json({"ok": True, "saved": "event"}, status=201)
                return
        except Exception as exc:
            self.send_json({"ok": False, "error": str(exc)}, status=400)


def main():
    if not DB_PATH.exists():
        raise SystemExit(f"Missing database: {DB_PATH}")
    server = ThreadingHTTPServer(("0.0.0.0", 5005), Handler)
    print("Serving Batal Al-Droob app with SQLite API on http://0.0.0.0:5005/")
    server.serve_forever()


if __name__ == "__main__":
    main()
