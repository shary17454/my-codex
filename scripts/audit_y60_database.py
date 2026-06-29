#!/usr/bin/env python3
import csv
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES_PATH = ROOT / "data" / "extracted" / "y60_sources.json"
RAW_DIR = ROOT / "data" / "raw_text"
OUT_DIR = ROOT / "data" / "audited"
APP_OUT = ROOT / "data" / "y60_app_catalog.json"

PART_RE = re.compile(r"\b(\d{5})-?([A-Z0-9]{5})\b")
ROW_RE = re.compile(r"^(?P<ref>[0-9A-Z]{3,8})\s+(?P<part>\d{5}-?[A-Z0-9]{5})\s+(?P<name>[A-Z][A-Z0-9 ,./&()+-]{2,})$")
REF_RE = re.compile(r"^[0-9A-Z]{3,8}$")
QTY_RE = re.compile(r"\b\d{2}\b")
DATE_RE = re.compile(r"\b\d{2}\.\d{4}\s*-\s*(?:\d{2}\.\d{4}|\.\.\.)")
ENGINE_RE = re.compile(r"\b(?:TB42S|TB42E|TD42|RD28T|RB30S|TB45E|TB48DE)\b")
ARABIC_RE = re.compile(r"[\u0600-\u06ff]")

CATEGORY_RULES = [
    ("engine", "محرك", ["ENGINE", "MANIFOLD", "PISTON", "CRANK", "CYLINDER", "VALVE", "CAMSHAFT", "OIL PAN", "TIMING", "GASKET"]),
    ("cooling", "تبريد", ["RADIATOR", "FAN", "WATER PUMP", "THERMOSTAT", "COOLER", "HOSE-WATER"]),
    ("electrical", "كهرباء", ["LAMP", "SWITCH", "RELAY", "HARNESS", "METER", "SENSOR", "ALTERNATOR", "STARTER", "BATTERY"]),
    ("brake", "فرامل", ["BRAKE", "CALIPER", "PAD", "ROTOR", "MASTER CYLINDER", "BOOSTER"]),
    ("suspension", "تعليق ودفرنس", ["SPRING", "SHOCK", "AXLE", "DIFFERENTIAL", "ARM", "STABILIZER", "LINK", "BUSH"]),
    ("body", "هيكل وديكور", ["FENDER", "GRILLE", "MUDGUARD", "BUMPER", "DOOR", "GLASS", "MOULDING", "PANEL", "GUARD", "BRACKET"]),
    ("interior", "داخلية", ["SEAT", "CARPET", "TRIM", "CONSOLE", "INSTRUMENT", "HANDLE", "KNOB"]),
    ("fuel", "وقود", ["FUEL", "CARBURETOR", "TANK", "PUMP", "INJECTOR", "FILTER-FUEL"]),
]


def norm_part(value):
    match = PART_RE.search(value or "")
    if not match:
        return ""
    return f"{match.group(1)}-{match.group(2)}"


def compact(value, limit=None):
    text = " ".join((value or "").split())
    if limit and len(text) > limit:
        return text[: limit - 1].rstrip() + "…"
    return text


def clean_name(value):
    name = compact(value)
    name = re.sub(r"\s+\d{2}\s.*$", "", name)
    name = re.sub(r"\s+(?:08|09|10|11|12)\.\d{4}.*$", "", name)
    name = name.strip(" |")
    return name.title() if name else ""


def infer_category(names):
    haystack = " ".join(names).upper()
    for key, label, words in CATEGORY_RULES:
        if any(word in haystack for word in words):
            return key, label
    return "general", "عام"


def source_weight(source):
    # The combined PDF repeats the yearly catalogs and is useful evidence, but
    # yearly PDFs are stronger for fitment/year counting.
    if source.get("kind") == "combined_catalog":
        return 0.35
    if source.get("kind") == "vin_report":
        return 0.75
    return 1.0


def split_pages(raw_text):
    current_page = None
    lines = []
    for line in raw_text.splitlines():
        marker = re.match(r"^--- PAGE (\d+) ---$", line.strip())
        if marker:
            if current_page is not None:
                yield current_page, lines
            current_page = int(marker.group(1))
            lines = []
        else:
            lines.append(line.rstrip())
    if current_page is not None:
        yield current_page, lines


def neighborhood(lines, index, radius=3):
    start = max(0, index - radius)
    end = min(len(lines), index + radius + 1)
    return compact(" ".join(line for line in lines[start:end] if line.strip()), 320)


def extract_records_from_page(source, page, lines):
    records = []
    normalized = [compact(line) for line in lines]
    for index, line in enumerate(normalized):
        if not line:
            continue

        row_match = ROW_RE.match(line)
        if row_match:
            records.append(make_record(source, page, row_match.group("ref"), row_match.group("part"), row_match.group("name"), normalized, index))
            continue

        # Many reportlab pages split columns line by line:
        # ref / part number / english name / arabic name / qty / applicability.
        if REF_RE.match(line) and index + 2 < len(normalized):
            next_line = normalized[index + 1]
            next_next = normalized[index + 2]
            if PART_RE.fullmatch(next_line) and next_next and not PART_RE.fullmatch(next_next) and not QTY_RE.fullmatch(next_next):
                records.append(make_record(source, page, line, next_line, next_next, normalized, index + 1))
                continue

        # Fallback for lines containing reference + part only, with name on the
        # next meaningful English line.
        tokens = line.split()
        if len(tokens) == 2 and REF_RE.match(tokens[0]) and PART_RE.fullmatch(tokens[1]):
            name = ""
            for candidate in normalized[index + 1 : index + 5]:
                if candidate and not ARABIC_RE.search(candidate) and not PART_RE.fullmatch(candidate) and not QTY_RE.fullmatch(candidate):
                    name = candidate
                    break
            if name:
                records.append(make_record(source, page, tokens[0], tokens[1], name, normalized, index))

    return records


def make_record(source, page, ref, part, name, lines, index):
    scope = neighborhood(lines, index)
    dates = DATE_RE.findall(scope)
    engines = sorted(set(ENGINE_RE.findall(scope)))
    qty_match = QTY_RE.search(scope)
    return {
        "part_number": norm_part(part),
        "reference": ref,
        "name_en": clean_name(name),
        "name_ar": "",
        "source_id": source["source_id"],
        "source_year": source["year"],
        "source_kind": source["kind"],
        "page": page,
        "quantity": qty_match.group(0) if qty_match else "",
        "engines": engines,
        "date_ranges": dates[:4],
        "context": scope,
        "source_weight": source_weight(source),
    }


def confidence_for(records, best_name):
    score = 30
    unique_years = {r["source_year"] for r in records if str(r["source_year"]).isdigit()}
    unique_sources = {r["source_id"] for r in records}
    if best_name:
        score += 25
    score += min(20, len(unique_years) * 3)
    score += min(15, len(unique_sources) * 2)
    if any(r["engines"] for r in records):
        score += 5
    if any(r["date_ranges"] for r in records):
        score += 5
    return min(100, score)


def status_for(confidence):
    if confidence >= 85:
        return "مدقق آليًا بدرجة عالية"
    if confidence >= 70:
        return "مدقق آليًا"
    if confidence >= 55:
        return "يحتاج مراجعة اسم/تطبيق"
    return "يحتاج مراجعة يدوية"


def choose_name(records):
    names = [r["name_en"] for r in records if r["name_en"]]
    if not names:
        return ""
    counts = Counter(names)
    return counts.most_common(1)[0][0]


def write_csv(path, rows, fieldnames):
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sources = json.loads(SOURCES_PATH.read_text(encoding="utf-8"))

    hash_groups = defaultdict(list)
    for source in sources:
        hash_groups[source.get("sha256", "")].append(source["source_id"])

    seen_hashes = set()
    canonical_sources = []
    skipped_duplicates = []
    for source in sources:
        digest = source.get("sha256", "")
        if digest and digest in seen_hashes:
            skipped_duplicates.append(
                {
                    "skipped_source_id": source["source_id"],
                    "kept_source_id": hash_groups[digest][0],
                    "filename": source.get("filename", ""),
                    "year": source.get("year", ""),
                    "sha256": digest,
                }
            )
            continue
        if digest:
            seen_hashes.add(digest)
        canonical_sources.append(source)

    all_records = []
    for source in canonical_sources:
        raw_path = ROOT / source.get("raw_text_path", "")
        if not raw_path.exists():
            continue
        raw_text = raw_path.read_text(encoding="utf-8", errors="replace")
        for page, lines in split_pages(raw_text):
            all_records.extend(extract_records_from_page(source, page, lines))

    grouped = defaultdict(list)
    for record in all_records:
        if record["part_number"]:
            grouped[record["part_number"]].append(record)

    parts = []
    for part_number, records in sorted(grouped.items()):
        best_name = choose_name(records)
        category, category_ar = infer_category([best_name] + [record["context"] for record in records[:8]])
        years = sorted({record["source_year"] for record in records if str(record["source_year"]).isdigit()})
        engines = sorted({engine for record in records for engine in record["engines"]})
        date_ranges = sorted({date for record in records for date in record["date_ranges"]})
        confidence = confidence_for(records, best_name)
        evidence = [
            {
                "source_id": record["source_id"],
                "year": record["source_year"],
                "page": record["page"],
                "reference": record["reference"],
                "quantity": record["quantity"],
                "context": record["context"],
            }
            for record in records[:6]
        ]
        parts.append(
            {
                "part_number": part_number,
                "name_ar": "",
                "name_en": best_name or "Y60 Catalog Part",
                "model": "Y60",
                "years": years,
                "engines": engines,
                "date_ranges": date_ranges[:8],
                "category": category,
                "category_ar": category_ar,
                "occurrence_count": len(records),
                "source_count": len({record["source_id"] for record in records}),
                "weighted_source_score": round(sum(record["source_weight"] for record in records), 2),
                "confidence": confidence,
                "audit_status": status_for(confidence),
                "rarity": "موثق بقوة" if confidence >= 85 else ("موثق" if confidence >= 70 else "يحتاج تدقيق"),
                "evidence": evidence,
            }
        )

    generated_at = datetime.now(timezone.utc).isoformat()
    audited = {
        "generated_at": generated_at,
        "model": "Nissan Patrol Y60",
        "audit_method": "structured line parsing from extracted EPC PDF text with duplicate source removal by sha256",
        "source_count": len(canonical_sources),
        "skipped_duplicate_count": len(skipped_duplicates),
        "unique_source_hash_count": len([key for key in hash_groups if key]),
        "record_count": len(all_records),
        "part_count": len(parts),
        "skipped_duplicates": skipped_duplicates,
        "sources": [
            {
                "source_id": source["source_id"],
                "filename": source.get("filename", ""),
                "year": source["year"],
                "kind": source["kind"],
                "page_count": source.get("page_count", 0),
                "duplicate_group": hash_groups.get(source.get("sha256", ""), []),
            }
            for source in canonical_sources
        ],
        "parts": parts,
    }

    (OUT_DIR / "y60_audited_database.json").write_text(json.dumps(audited, ensure_ascii=False, indent=2), encoding="utf-8")
    (OUT_DIR / "duplicates_removed.json").write_text(json.dumps(skipped_duplicates, ensure_ascii=False, indent=2), encoding="utf-8")
    APP_OUT.write_text(json.dumps(audited, ensure_ascii=False, indent=2), encoding="utf-8")

    write_csv(
        OUT_DIR / "y60_audited_parts.csv",
        [
            {
                "part_number": part["part_number"],
                "name_en": part["name_en"],
                "category": part["category"],
                "years": ",".join(part["years"]),
                "engines": ",".join(part["engines"]),
                "confidence": part["confidence"],
                "audit_status": part["audit_status"],
                "occurrence_count": part["occurrence_count"],
                "source_count": part["source_count"],
                "first_evidence": part["evidence"][0]["context"] if part["evidence"] else "",
            }
            for part in parts
        ],
        ["part_number", "name_en", "category", "years", "engines", "confidence", "audit_status", "occurrence_count", "source_count", "first_evidence"],
    )

    write_csv(
        OUT_DIR / "y60_audited_records.csv",
        all_records,
        ["part_number", "reference", "name_en", "name_ar", "source_id", "source_year", "source_kind", "page", "quantity", "engines", "date_ranges", "context", "source_weight"],
    )

    category_counts = Counter(part["category"] for part in parts)
    status_counts = Counter(part["audit_status"] for part in parts)
    report = [
        "# Y60 Catalog Audit Report",
        "",
        f"Generated: {generated_at}",
        f"Sources after duplicate removal: {len(canonical_sources)} PDFs",
        f"Skipped duplicate PDFs: {len(skipped_duplicates)}",
        f"Unique source hashes: {audited['unique_source_hash_count']}",
        f"Structured records extracted: {len(all_records):,}",
        f"Unique parts: {len(parts):,}",
        "",
        "## Audit Status",
        *[f"- {status}: {count:,}" for status, count in status_counts.most_common()],
        "",
        "## Categories",
        *[f"- {category}: {count:,}" for category, count in category_counts.most_common()],
        "",
        "## Duplicate Source Groups",
        *[f"- {', '.join(group)}" for group in hash_groups.values() if len(group) > 1],
        "",
        "## Removed Duplicates",
        *[f"- skipped {item['skipped_source_id']} kept {item['kept_source_id']}" for item in skipped_duplicates],
        "",
        "## Notes",
        "- This audit parses structured EPC rows from the extracted PDF text.",
        "- Arabic names remain blank when the source extraction separates Arabic text unreliably.",
        "- Records marked for review are still indexed but should be checked against rendered diagrams before commercial use.",
    ]
    (OUT_DIR / "audit_report.md").write_text("\n".join(report) + "\n", encoding="utf-8")

    print(json.dumps({
        "record_count": len(all_records),
        "part_count": len(parts),
        "source_count": len(canonical_sources),
        "skipped_duplicate_count": len(skipped_duplicates),
        "skipped_duplicates": skipped_duplicates,
        "status_counts": dict(status_counts),
        "outputs": [
            "data/audited/y60_audited_database.json",
            "data/audited/y60_audited_parts.csv",
            "data/audited/y60_audited_records.csv",
            "data/audited/audit_report.md",
            "data/audited/duplicates_removed.json",
            "data/y60_app_catalog.json",
        ],
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
