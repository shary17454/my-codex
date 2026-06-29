#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INPUT = ROOT / "data" / "extracted" / "y60_parts_database.json"
OUTPUT = ROOT / "data" / "y60_app_catalog.json"

CATEGORY_RULES = [
    ("engine", "محرك", ["ENGINE", "MANIFOLD", "PISTON", "CRANK", "CYLINDER", "VALVE", "CAMSHAFT", "OIL PAN"]),
    ("cooling", "تبريد", ["RADIATOR", "FAN", "WATER PUMP", "THERMOSTAT", "COOLER"]),
    ("electrical", "كهرباء", ["LAMP", "SWITCH", "RELAY", "HARNESS", "METER", "SENSOR", "ALTERNATOR", "STARTER"]),
    ("brake", "فرامل", ["BRAKE", "CALIPER", "PAD", "ROTOR", "MASTER CYLINDER"]),
    ("suspension", "تعليق ودفرنس", ["SPRING", "SHOCK", "AXLE", "DIFFERENTIAL", "ARM", "STABILIZER"]),
    ("body", "هيكل وديكور", ["FENDER", "GRILLE", "MUDGUARD", "BUMPER", "DOOR", "GLASS", "MOULDING", "PANEL"]),
    ("interior", "داخلية", ["SEAT", "CARPET", "TRIM", "CONSOLE", "INSTRUMENT", "HANDLE"]),
    ("fuel", "وقود", ["FUEL", "CARBURETOR", "TANK", "PUMP", "INJECTOR"]),
]


def normalize_context(context):
    return " ".join((context or "").split())[:260]


def infer_category(contexts):
    haystack = " ".join(contexts).upper()
    for key, label, words in CATEGORY_RULES:
        if any(word in haystack for word in words):
            return key, label
    return "general", "عام"


def infer_name(context, part_number):
    text = context.replace(part_number, " ")
    text = re.sub(r"[\u0600-\u06ff]+", " ", text)
    candidates = re.findall(r"\b[A-Z][A-Z0-9/-]*(?:-[A-Z0-9/-]+)*(?: [A-Z][A-Z0-9/-]*(?:-[A-Z0-9/-]+)*){0,3}\b", text)
    blocked = {"NISSAN", "FORD", "MAVERICK", "W", "RH", "LH", "FR", "RR"}
    for candidate in candidates:
        candidate = candidate.strip(" |")
        if len(candidate) < 4:
            continue
        if candidate in blocked:
            continue
        if re.fullmatch(r"[0-9A-Z/-]+", candidate) and not any("-" in word for word in candidate.split()):
            continue
        return candidate.title()
    return "قطعة Y60 موثقة"


def rarity_from_sources(source_count):
    if source_count >= 7:
        return "موثقة عبر سنوات كثيرة"
    if source_count >= 3:
        return "موثقة في عدة مصادر"
    return "تحتاج تدقيق توفر"


def main():
    data = json.loads(INPUT.read_text(encoding="utf-8"))
    sources = [
        {
            "source_id": source["source_id"],
            "filename": source.get("filename", ""),
            "year": source["year"],
            "kind": source["kind"],
            "page_count": source.get("page_count", 0),
            "status": source["status"],
        }
        for source in data["sources"]
    ]

    parts = []
    for part in data["parts"]:
        evidence = part.get("evidence", [])[:4]
        contexts = [item.get("context", "") for item in evidence]
        category, category_ar = infer_category(contexts)
        first_context = normalize_context(contexts[0] if contexts else "")
        parts.append(
            {
                "part_number": part["part_number"],
                "name_ar": "",
                "name_en": infer_name(first_context, part["part_number"]),
                "model": "Y60",
                "years": part["years"],
                "category": category,
                "category_ar": category_ar,
                "occurrence_count": part["occurrence_count"],
                "source_count": part["source_count"],
                "rarity": rarity_from_sources(part["source_count"]),
                "evidence": [
                    {
                        "source_id": item["source_id"],
                        "year": item["year"],
                        "page": item["page"],
                        "context": normalize_context(item["context"]),
                    }
                    for item in evidence
                ],
            }
        )

    app_data = {
        "generated_at": data["generated_at"],
        "model": data["model"],
        "source_count": data["source_count"],
        "part_count": len(parts),
        "sources": sources,
        "parts": parts,
    }
    OUTPUT.write_text(json.dumps(app_data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"output": str(OUTPUT.relative_to(ROOT)), "part_count": len(parts)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
