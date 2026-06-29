from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SEARCH_DIR = ROOT / "flutter_y60_catalog" / "assets" / "catalog" / "search"
FULL_INDEX = SEARCH_DIR / "catalog_search_index.json"
SECTION_INDEX = SEARCH_DIR / "catalog_section_index.json"


SECTION_ORDER = [
    "vehicle",
    "engine",
    "transmission",
    "axle",
    "brake",
    "body",
    "interior",
    "electrical",
    "cooling_ac",
    "general",
]


SECTION_TITLES = {
    "vehicle": "بطاقة السيارة",
    "engine": "المحرك والوقود",
    "transmission": "القير والدبل",
    "axle": "الدفرنسات والمحاور",
    "brake": "الفرامل",
    "body": "البدي والخارجية",
    "interior": "الداخلية والفرش",
    "electrical": "الكهرباء والظفيرة",
    "cooling_ac": "التكييف والثلاجات",
    "general": "عام وباقي الصفحات",
}


def compact_entry(entry: dict) -> dict:
    return {
        "id": entry.get("id", ""),
        "type": entry.get("type", ""),
        "year": entry.get("year", ""),
        "titleAr": entry.get("titleAr", ""),
        "subtitleAr": entry.get("subtitleAr", ""),
        "sectionId": entry.get("sectionId", "general"),
        "sectionTitleAr": entry.get("sectionTitleAr", ""),
        "sourcePdfPath": entry.get("sourcePdfPath", ""),
        "pageNumber": entry.get("pageNumber", 0),
        "keywords": entry.get("keywords", [])[:12],
        "snippet": (entry.get("snippet", "") or "")[:180],
        "queryText": "",
    }


def main() -> None:
    data = json.loads(FULL_INDEX.read_text(encoding="utf-8"))
    grouped: dict[str, list[dict]] = defaultdict(list)

    for entry in data["entries"]:
        section_id = entry.get("sectionId") or "general"
        grouped[section_id].append(entry)

    sections = []
    ordered_ids = SECTION_ORDER + [
        key for key in sorted(grouped.keys()) if key not in SECTION_ORDER
    ]

    for section_id in ordered_ids:
        entries = grouped.get(section_id, [])
        if not entries:
            continue
        sections.append(
            {
                "id": section_id,
                "titleAr": SECTION_TITLES.get(
                    section_id,
                    entries[0].get("sectionTitleAr", section_id),
                ),
                "count": len(entries),
                "entries": [compact_entry(entry) for entry in entries[:180]],
            }
        )

    output = {
        "schemaVersion": 1,
        "sourceGeneratedAt": data.get("generatedAt"),
        "totalEntries": len(data["entries"]),
        "sections": sections,
    }
    SECTION_INDEX.write_text(
        json.dumps(output, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"Wrote {SECTION_INDEX}")
    print(f"Sections: {len(sections)}")
    print(f"Size: {SECTION_INDEX.stat().st_size}")


if __name__ == "__main__":
    main()
