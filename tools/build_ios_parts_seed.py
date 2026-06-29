from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "work" / "partsouq_full" / "units_structured.json"
OUTPUT = ROOT / "SafariY60Parts" / "Resources" / "parts_seed.json"
sys.path.insert(0, str(ROOT / "tools"))

from add_arabic_part_names_to_cards import translate_name


SYSTEM_MAP = {
    "وقود و تحكم المحرك": ("engineFuel", "المحرك والوقود"),
    "العادم و تبريد": ("coolingExhaust", "التبريد والعادم"),
    "كهرباء المحرك": ("engineElectrical", "كهرباء المحرك"),
    "كهرباء الهيكل": ("bodyElectrical", "كهرباء الهيكل"),
    "POWER TRAIN": ("drivetrain", "نظام نقل الحركة"),
    "محور و نظام التعليق": ("axleSuspension", "المحاور والتعليق"),
    "فرامل": ("brakes", "الفرامل"),
    "STEERING": ("steering", "التوجيه"),
    "BODY(FRONT,ROOF & FLOOR)": ("bodyExterior", "الهيكل الخارجي"),
    "هيكل(جانبي و خلفي)": ("bodyRearSide", "الهيكل الجانبي والخلفي"),
    "المقعد و حزام الأمان": ("interiorSeats", "المقصورة والمقاعد"),
    "BODY(BACK DOOR & REAR BODY)": ("rearBody", "الخلفية والباب الخلفي"),
    "MISCELLANEOUS": ("specialAccessories", "الملحقات الخاصة"),
}


def clean(value: str) -> str:
    return " ".join((value or "").replace("\n", " ").split())


def compatible_years(date_range: str) -> list[int]:
    years = [int(year) for year in re.findall(r"(?:^|\D)(19\d{2}|20\d{2})(?:\D|$)", date_range or "")]
    if len(years) >= 2:
        start, end = min(years), max(years)
    elif len(years) == 1:
        start = end = years[0]
    else:
        start, end = 1988, 1997
    return [year for year in range(max(1988, start), min(1997, end) + 1)]


def engine_tags(*values: str) -> list[str]:
    text = " ".join(values).upper()
    engines = sorted(set(re.findall(r"\b(?:TB42S|TB42|TD42|RD28T|RD28|RB30S|RB30)\b", text)))
    return engines or ["TB42S"]


def load_units() -> list[dict]:
    return json.loads(SOURCE.read_text(encoding="utf-8"))


def build_seed(units: list[dict]) -> dict:
    records = []
    seen = set()

    for unit in units:
        table = unit.get("table") or []
        rows = table[1:] if len(table) > 1 else []
        system_key, system_name_ar = SYSTEM_MAP.get(
            clean(unit.get("category", "")),
            ("other", clean(unit.get("category", "")) or "أخرى"),
        )

        for row_index, row in enumerate(rows, start=1):
            padded = list(row) + [""] * max(0, 7 - len(row))
            part_number = clean(padded[0])
            if not part_number:
                continue

            record_id = f"{part_number}|{unit.get('uid','')}|{clean(padded[2])}|{row_index}"
            if record_id in seen:
                continue
            seen.add(record_id)

            records.append(
                {
                    "id": record_id,
                    "partNumber": part_number,
                    "name": clean(padded[1]),
                    "nameAr": translate_name(clean(padded[1])),
                    "diagramCode": clean(padded[2]),
                    "quantity": clean(padded[3]),
                    "application": clean(padded[4]),
                    "specification": clean(padded[5]),
                    "dateRange": clean(padded[6]),
                    "compatibleYears": compatible_years(clean(padded[6])),
                    "engineTags": engine_tags(clean(padded[4]), clean(unit.get("info", "")), clean(unit.get("title", ""))),
                    "condition": "OEM",
                    "systemKey": system_key,
                    "systemNameAr": system_name_ar,
                    "sourceCategory": clean(unit.get("category", "")),
                    "unitTitle": clean(unit.get("title", "")),
                    "unitInfo": clean(unit.get("info", "")),
                    "unitIndex": unit.get("index"),
                    "unitId": clean(unit.get("uid", "")),
                    "unitUrl": clean(unit.get("url", "")),
                    "diagramImageURL": clean((unit.get("diagram") or {}).get("src", "")),
                }
            )

    systems = []
    seen_systems = set()
    for record in records:
        key = record["systemKey"]
        if key in seen_systems:
            continue
        seen_systems.add(key)
        systems.append({"key": key, "nameAr": record["systemNameAr"]})

    systems.sort(key=lambda item: item["nameAr"])
    records.sort(key=lambda item: (item["systemNameAr"], item["partNumber"], item["unitTitle"]))

    return {
        "vehicle": {
            "name": "Nissan Patrol Safari Y60 SGL",
            "chassisNumber": "WGY60-348567",
            "modelCode": "WLGY60JFRC5",
            "productionDate": "10/1991",
            "registrationModel": "1992",
            "engine": "TB42S",
            "transmission": "FS5R50A",
            "market": "Gulf / Saudi Arabia",
        },
        "systems": systems,
        "parts": records,
    }


def main() -> None:
    units = load_units()
    seed = build_seed(units)
    OUTPUT.write_text(json.dumps(seed, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(seed['parts'])} parts to {OUTPUT}")


if __name__ == "__main__":
    main()
