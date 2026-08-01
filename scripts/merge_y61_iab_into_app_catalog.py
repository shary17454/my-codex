#!/usr/bin/env python3
import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_CATALOG = ROOT / "ios/BatalAlDroob/BatalAlDroob/Web/data/y60_app_catalog.json"
Y61_SOURCE_DIR = ROOT / "sources/partsouq/full_y61_iab"
SOURCE_ID = "y61_partsouq_iab_1997"
SOURCE_FILENAME = "sources/partsouq/full_y61_iab/*.progressive.json"

CATEGORY_RULES = [
    ("engine", "محرك", ["ENGINE", "MANIFOLD", "PISTON", "CRANK", "CYLINDER", "VALVE", "CAMSHAFT", "OIL PAN", "GASKET"]),
    ("cooling", "تبريد", ["RADIATOR", "FAN", "WATER PUMP", "THERMOSTAT", "COOLER", "EXHAUST", "MUFFLER"]),
    ("electrical", "كهرباء", ["LAMP", "SWITCH", "RELAY", "HARNESS", "METER", "SENSOR", "ALTERNATOR", "STARTER", "ELECTRICAL"]),
    ("brake", "فرامل", ["BRAKE", "CALIPER", "PAD", "ROTOR", "MASTER CYLINDER"]),
    ("suspension", "تعليق ودفرنس", ["SPRING", "SHOCK", "AXLE", "DIFFERENTIAL", "ARM", "STABILIZER", "LINK", "ROD"]),
    ("interior", "داخلية", ["SEAT", "CARPET", "TRIM", "CONSOLE", "INSTRUMENT", "HANDLE", "GARNISH", "FINISHER"]),
    ("body", "هيكل وديكور", ["FENDER", "GRILLE", "MUDGUARD", "BUMPER", "DOOR", "GLASS", "MOULDING", "PANEL", "BODY"]),
    ("fuel", "وقود", ["FUEL", "TANK", "PUMP", "INJECTOR", "NOZZLE"]),
]


def clean(value):
    return " ".join(str(value or "").strip().split())


def normalize_number(value):
    return re.sub(r"[^A-Z0-9]", "", clean(value).upper())


def years_from_text(value):
    years = []
    for year in re.findall(r"(19\d{2}|20\d{2})", clean(value)):
        if year not in years:
            years.append(year)
    return years


def engines_from_text(value):
    engines = []
    for engine in re.findall(r"\b(?:TB|TD|RD|ZD|VK)\d{2}[A-Z]*\b", clean(value).upper()):
        if engine not in engines:
            engines.append(engine)
    return engines


def infer_category(*texts):
    haystack = " ".join(clean(text).upper() for text in texts)
    for key, label, terms in CATEGORY_RULES:
        if any(term in haystack for term in terms):
            return key, label
    return "general", "عام"


def compact_context(*parts):
    return " | ".join(clean(part) for part in parts if clean(part))[:900]


def source_from_file(path, payload):
    category = payload.get("category") or {}
    year = clean(category.get("year") or payload.get("source_row", {}).get("year_filter") or "1997")
    return {
        "source_id": f"{SOURCE_ID}_{payload.get('extract_id') or path.stem}",
        "filename": path.name,
        "year": year,
        "kind": "partsouq_iab_progressive_json",
        "page_count": 0,
    }


def collect_y61_parts():
    parts = {}
    sources = {}
    source_files = sorted(Y61_SOURCE_DIR.glob("*.progressive.json"))
    raw_rows = 0
    skipped_blank = 0

    for path in source_files:
        payload = json.loads(path.read_text(encoding="utf-8"))
        source = source_from_file(path, payload)
        source_id = source["source_id"]
        sources[source_id] = source
        vehicle = payload.get("category") or payload.get("source_row") or {}
        vehicle_years = years_from_text(" ".join([
            clean(vehicle.get("year") or vehicle.get("year_filter")),
            clean(vehicle.get("production_from")),
            clean(vehicle.get("production_to")),
            clean(vehicle.get("raw_text")),
        ]))
        vehicle_engines = engines_from_text(" ".join([
            clean(vehicle.get("engine")),
            clean(vehicle.get("raw_text")),
        ]))

        for unit in payload.get("units") or []:
            group = clean(unit.get("group_text"))
            plate_code = clean(unit.get("plate_code"))
            plate_title = clean(unit.get("plate_title_en") or unit.get("diagram_alt"))
            diagram = clean(unit.get("diagram_image_url"))

            for row in unit.get("part_rows") or []:
                raw_rows += 1
                part_number = normalize_number(row.get("part_number"))
                if not part_number:
                    skipped_blank += 1
                    continue

                name_en = clean(row.get("part_name_en"))
                reference = clean(row.get("reference_code"))
                quantity = clean(row.get("quantity"))
                applicable = clean(row.get("applicable_models"))
                specs = clean(row.get("specifications"))
                category_key, category_ar = infer_category(group, plate_title, name_en)
                years = years_from_text(specs) or vehicle_years
                engines = engines_from_text(applicable) or vehicle_engines
                context = compact_context(
                    "Y61",
                    clean(vehicle.get("market")),
                    clean(vehicle.get("body_style")),
                    clean(vehicle.get("grade_or_frame")),
                    ",".join(engines),
                    group,
                    plate_code,
                    plate_title,
                    reference,
                    part_number,
                    name_en,
                    quantity,
                    applicable,
                    specs,
                )

                item = parts.setdefault(
                    part_number,
                    {
                        "part_number": part_number,
                        "name_ar": "",
                        "name_en": name_en or "Y61 catalog part",
                        "model": "Y61",
                        "years": set(),
                        "engines": set(),
                        "date_ranges": set(),
                        "category": category_key,
                        "category_ar": category_ar,
                        "occurrence_count": 0,
                        "source_count": 0,
                        "weighted_source_score": 0,
                        "confidence": 82,
                        "audit_status": "مدمج من فهرس Y61 مستخرج آليًا",
                        "rarity": "موثق من كتالوج Y61",
                        "evidence": [],
                        "part_numbers": [],
                        "primary_oem_number": part_number,
                        "diagram_key": reference or plate_code or part_number,
                    },
                )

                item["occurrence_count"] += 1
                if not item["name_en"] or item["name_en"] == "Y61 catalog part":
                    item["name_en"] = name_en or item["name_en"]
                if item["category"] == "general" and category_key != "general":
                    item["category"] = category_key
                    item["category_ar"] = category_ar
                item["years"].update(years)
                item["engines"].update(engines)
                if specs:
                    item["date_ranges"].add(specs)
                if diagram and diagram not in item["part_numbers"]:
                    # Keep the URL out of alternate part numbers; it belongs in evidence context.
                    pass
                if len(item["evidence"]) < 5:
                    item["evidence"].append(
                        {
                            "source_id": source_id,
                            "year": ",".join(years or vehicle_years) or "1997",
                            "page": None,
                            "reference": reference,
                            "quantity": quantity,
                            "context": context,
                        }
                    )

    final_parts = []
    for item in parts.values():
        item["years"] = sorted(item["years"])
        item["engines"] = sorted(item["engines"])
        item["date_ranges"] = sorted(item["date_ranges"])
        item["source_count"] = len({e["source_id"] for e in item["evidence"]})
        item["weighted_source_score"] = round(item["occurrence_count"] + item["source_count"] * 1.5, 2)
        item["confidence"] = min(95, 76 + min(12, item["source_count"] * 3) + min(7, item["occurrence_count"] // 4))
        final_parts.append(item)

    return {
        "sources": list(sources.values()),
        "parts": sorted(final_parts, key=lambda part: part["part_number"]),
        "raw_rows": raw_rows,
        "skipped_blank": skipped_blank,
        "source_files": len(source_files),
    }


def merge_catalog():
    catalog = json.loads(APP_CATALOG.read_text(encoding="utf-8"))
    y61 = collect_y61_parts()

    existing_sources = {
        source.get("source_id"): source
        for source in catalog.get("sources", [])
        if source.get("source_id") and not source.get("source_id", "").startswith(SOURCE_ID)
    }
    for source in y61["sources"]:
        existing_sources[source["source_id"]] = source

    existing_parts = {
        normalize_number(part.get("part_number")): part
        for part in catalog.get("parts", [])
        if normalize_number(part.get("part_number")) and (part.get("model") or "").upper() != "Y61"
    }
    replaced_or_added = 0
    for part in y61["parts"]:
        existing_parts[normalize_number(part["part_number"])] = part
        replaced_or_added += 1

    catalog["generated_at"] = datetime.now(timezone.utc).isoformat()
    catalog["app_name"] = catalog.get("app_name") or "بطل الدروب"
    catalog["model"] = "Y60/Y61/Y62"
    catalog["source_count"] = len(existing_sources)
    catalog["record_count"] = len(existing_parts)
    catalog["part_count"] = len(existing_parts)
    catalog["sources"] = sorted(existing_sources.values(), key=lambda item: item.get("source_id", ""))
    catalog["parts"] = sorted(existing_parts.values(), key=lambda item: (item.get("model") or "", item.get("part_number") or ""))

    APP_CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return {
        "output": str(APP_CATALOG.relative_to(ROOT)),
        "source_files": y61["source_files"],
        "raw_rows": y61["raw_rows"],
        "y61_unique_parts": len(y61["parts"]),
        "skipped_blank": y61["skipped_blank"],
        "total_parts": len(existing_parts),
        "total_sources": len(existing_sources),
        "replaced_or_added": replaced_or_added,
    }


if __name__ == "__main__":
    print(json.dumps(merge_catalog(), ensure_ascii=False, indent=2))
