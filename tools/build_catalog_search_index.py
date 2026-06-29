from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
PDF_DIR = ROOT / "flutter_y60_catalog" / "assets" / "catalog" / "pdfs"
OUT_DIR = ROOT / "flutter_y60_catalog" / "assets" / "catalog" / "search"
OUT_FILE = OUT_DIR / "catalog_search_index.json"
VEHICLE_PDF = PDF_DIR / "wgy60348567_vehicle_catalog.pdf"

PART_NUMBER_RE = re.compile(r"\b[A-Z0-9]{2,5}-?[A-Z0-9]{3,6}(?:-[A-Z0-9]{2,5})?\b")
CATALOG_CODE_RE = re.compile(r"\b\d{3}\s+[A-Z]\d{2}\b")


SECTION_RULES = [
    ("engine", "المحرك", ("ENGINE", "CYLINDER", "CARBURETOR", "FUEL", "EXHAUST")),
    ("transmission", "القير والدبل", ("TRANSMISSION", "TRANSFER", "CLUTCH", "PROPELLER")),
    ("axle", "الدفرنسات والمحاور", ("AXLE", "DIFFERENTIAL", "SUSPENSION")),
    ("brake", "الفرامل", ("BRAKE",)),
    ("body", "البدي والأجزاء الخارجية", ("BODY", "HOOD", "FENDER", "DOOR", "BUMPER")),
    ("interior", "الداخلية والفرش", ("TRIM", "SEAT", "INSTRUMENT", "CARPET", "ROOF")),
    ("electrical", "الكهرباء والظفيرة", ("ELECTRICAL", "HARNESS", "LAMP", "SWITCH", "METER")),
    ("cooling_ac", "التكييف والتبريد والثلاجات", ("AIR CONDITIONER", "COOLER", "VENTILATOR", "HEATER", "ICE")),
]


def compact_text(text: str) -> str:
    text = text.replace("\x00", " ")
    return re.sub(r"\s+", " ", text).strip()


def infer_section(text: str) -> tuple[str, str]:
    upper = text.upper()
    for section_id, title_ar, needles in SECTION_RULES:
        if any(needle in upper for needle in needles):
            return section_id, title_ar
    return "general", "عام"


def title_from_text(year: str, page_number: int, text: str) -> str:
    code_match = CATALOG_CODE_RE.search(text)
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    useful = [
        line
        for line in lines[:12]
        if len(line) >= 4 and not line.upper().startswith(("NISSAN", "MODEL", "ILLUST"))
    ]
    if code_match and useful:
        return f"{code_match.group(0)} - {useful[0][:80]}"
    if code_match:
        return code_match.group(0)
    if useful:
        return useful[0][:90]
    return f"Y60 {year} - صفحة {page_number}"


def build_vehicle_entries() -> list[dict]:
    return [
        {
            "id": "vehicle_wgy60_348567",
            "type": "vehicle",
            "year": "1991",
            "titleAr": "بطاقة السيارة - رقم الهيكل WGY60-348567",
            "titleEn": "Vehicle profile - WGY60-348567",
            "subtitleAr": "نيسان باترول Y60، محرك TB42S، قير FS5R50A، موديل WLGY60JFRC5",
            "sectionId": "vehicle",
            "sectionTitleAr": "بطاقة السيارة",
            "sourcePdfPath": "assets/catalog/pdfs/wgy60348567_vehicle_catalog.pdf",
            "pageNumber": 0,
            "keywords": [
                "WGY60",
                "WGY60-348567",
                "WGY60348567",
                "348567",
                "WLGY60JFRC5",
                "TB42S",
                "FS5R50A",
                "HG41",
                "2L3",
                "AH3",
            ],
            "snippet": "رقم الهيكل WGY60-348567، الموديل WLGY60JFRC5، الإنتاج 10/1991، المحرك TB42S، القير FS5R50A.",
        }
    ]


def build_index() -> dict:
    entries: list[dict] = build_vehicle_entries()
    stats: list[dict] = []

    for pdf_path in sorted(PDF_DIR.glob("y60_*.pdf")):
        year = pdf_path.stem.split("_", 1)[1]
        asset_path = f"assets/catalog/pdfs/{pdf_path.name}"
        pages_with_text = 0

        reader = PdfReader(str(pdf_path))
        total_pages = len(reader.pages)
        for index, page in enumerate(reader.pages, start=1):
            raw_text = page.extract_text() or ""
            text = compact_text(raw_text)
            if text:
                pages_with_text += 1

            section_id, section_title_ar = infer_section(text)
            part_numbers = sorted(set(PART_NUMBER_RE.findall(text.upper())))[:120]
            title = title_from_text(year, index, raw_text)
            snippet = text[:700]

            query_parts = [
                f"Y60 {year}",
                title,
                section_title_ar,
                " ".join(part_numbers),
                text[:8000],
            ]

            entries.append(
                {
                    "id": f"y60_{year}_p{index:04d}",
                    "type": "catalog_page",
                    "year": year,
                    "titleAr": title,
                    "titleEn": title,
                    "subtitleAr": f"كتالوج Y60 سنة {year} - صفحة {index} من {total_pages}",
                    "sectionId": section_id,
                    "sectionTitleAr": section_title_ar,
                    "sourcePdfPath": asset_path,
                    "pageNumber": index,
                    "keywords": part_numbers,
                    "snippet": snippet,
                    "queryText": compact_text(" ".join(query_parts)),
                }
            )

        stats.append(
            {
                "year": year,
                "pdf": pdf_path.name,
                "pages": total_pages,
                "pagesWithExtractedText": pages_with_text,
                "assetPath": asset_path,
            }
        )

    if VEHICLE_PDF.exists():
        asset_path = f"assets/catalog/pdfs/{VEHICLE_PDF.name}"
        pages_with_text = 0
        reader = PdfReader(str(VEHICLE_PDF))
        total_pages = len(reader.pages)
        for index, page in enumerate(reader.pages, start=1):
            raw_text = page.extract_text() or ""
            text = compact_text(raw_text)
            if text:
                pages_with_text += 1

            part_numbers = sorted(set(PART_NUMBER_RE.findall(text.upper())))[:120]
            title = title_from_text("WGY60348567", index, raw_text)
            snippet = text[:700]
            entries.append(
                {
                    "id": f"wgy60348567_p{index:04d}",
                    "type": "vehicle_pdf_page",
                    "year": "WGY",
                    "titleAr": title,
                    "titleEn": title,
                    "subtitleAr": f"ملف السيارة WGY60348567 - صفحة {index} من {total_pages}",
                    "sectionId": "vehicle",
                    "sectionTitleAr": "بطاقة السيارة",
                    "sourcePdfPath": asset_path,
                    "pageNumber": index,
                    "keywords": part_numbers
                    + [
                        "WGY60",
                        "WGY60-348567",
                        "WGY60348567",
                        "WLGY60JFRC5",
                        "TB42S",
                        "SGL",
                    ],
                    "snippet": snippet,
                    "queryText": compact_text(
                        " ".join(
                            [
                                "WGY60 WGY60-348567 WGY60348567 WLGY60JFRC5 TB42S SGL",
                                title,
                                " ".join(part_numbers),
                                text[:8000],
                            ]
                        )
                    ),
                }
            )

        stats.append(
            {
                "year": "WGY",
                "pdf": VEHICLE_PDF.name,
                "pages": total_pages,
                "pagesWithExtractedText": pages_with_text,
                "assetPath": asset_path,
            }
        )

    return {
        "schemaVersion": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "vehicle": "Nissan Patrol Safari Y60",
        "source": "Local Y60 PDF catalogs",
        "stats": stats,
        "entries": entries,
    }


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    index = build_index()
    OUT_FILE.write_text(
        json.dumps(index, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"Wrote {OUT_FILE}")
    print(f"Entries: {len(index['entries'])}")
    for item in index["stats"]:
        print(
            f"{item['pdf']}: {item['pagesWithExtractedText']}/{item['pages']} pages with text"
        )


if __name__ == "__main__":
    main()
