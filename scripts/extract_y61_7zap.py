#!/usr/bin/env python3
import json
import re
import time
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urljoin
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "data" / "extracted"
OUTPUT = OUTPUT_DIR / "y61_7zap_parts_database.json"
BASE_URL = "https://nissan.7zap.com/en/europe/patrol-y61-parts-catalog/"


PART_RE = re.compile(r"^(?P<num>(?:[A-Z0-9]{2}\s*){2,6}[A-Z0-9]{4,6})\s+(?P<name>.+?)\s+x(?P<qty>[0-9.]+)$")
REF_RE = re.compile(r"^[0-9A-Z+]{4,8}$")


class LinkTextParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self._href = None
        self._text = []
        self.h1 = ""
        self._in_h1 = False
        self.lines = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "a":
            self._href = attrs.get("href")
            self._text = []
        if tag == "h1":
            self._in_h1 = True
            self._text = []

    def handle_endtag(self, tag):
        if tag == "a" and self._href:
            text = " ".join("".join(self._text).split())
            if text:
                self.links.append((self._href, text))
            self._href = None
            self._text = []
        if tag == "h1" and self._in_h1:
            self.h1 = " ".join("".join(self._text).split())
            self._in_h1 = False
            self._text = []

    def handle_data(self, data):
        text = data.strip()
        if text:
            self.lines.append(text)
        if self._href is not None or self._in_h1:
            self._text.append(data)


def fetch(url):
    request = Request(url, headers={"User-Agent": "BatalAlDroobDataBuilder/1.0"})
    with urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", errors="replace")


def parse(url):
    parser = LinkTextParser()
    parser.feed(fetch(url))
    return parser


def normalize_part_number(raw):
    compact = re.sub(r"[^A-Z0-9]", "", raw.upper())
    if len(compact) >= 10:
        return f"{compact[:5]}-{compact[5:10]}"
    return compact


def infer_category(section_name):
    text = section_name.upper()
    rules = [
        ("engine", "محرك", ["CYLINDER", "PISTON", "CRANK", "MANIFOLD", "TURBO", "ENGINE", "OIL", "CAMSHAFT", "VALVE"]),
        ("cooling", "تبريد", ["WATER", "COOLING", "RADIATOR", "THERMOSTAT", "HEATER"]),
        ("fuel", "وقود", ["FUEL", "TANK", "INJECTION", "ACCELERATOR"]),
        ("electrical", "كهرباء", ["LAMP", "HARNESS", "SWITCH", "ELECTRICAL", "METER", "SENSOR", "CONTROL"]),
        ("brake", "فرامل", ["BRAKE", "ABS", "ANTI SKID"]),
        ("suspension", "تعليق ودفرنس", ["SUSPENSION", "AXLE", "DIFF", "PROPELLER", "TRANSFER", "STEERING"]),
        ("body", "هيكل وديكور", ["BODY", "DOOR", "FENDER", "PANEL", "BUMPER", "GRILLE", "GLASS", "HOOD", "ROOF", "FRAME"]),
        ("interior", "داخلية", ["SEAT", "TRIM", "CARPET", "CONSOLE", "INSTRUMENT", "AIR CONDITIONER"]),
    ]
    for key, label, words in rules:
        if any(word in text for word in words):
            return key, label
    return "general", "عام"


def section_links():
    parser = parse(BASE_URL)
    seen = set()
    links = []
    for href, text in parser.links:
        absolute = urljoin(BASE_URL, href)
        if "/patrol-y61-parts-catalog/" not in absolute:
            continue
        if absolute.rstrip("/") == BASE_URL.rstrip("/"):
            continue
        if "Offers" in text:
            continue
        key = absolute.rstrip("/")
        if key in seen:
            continue
        seen.add(key)
        name = re.sub(r"\s+Patrol Y61 1997\s*-\s*2010$", "", text).strip()
        links.append({"name": name, "url": absolute})
    return links


def extract_section(section, index):
    parser = parse(section["url"])
    category, category_ar = infer_category(section["name"])
    records = []
    last_ref = ""
    for line in parser.lines:
        line = " ".join(line.split())
        if REF_RE.fullmatch(line):
            last_ref = line
            continue
        match = PART_RE.match(line)
        if not match:
            continue
        raw_number = match.group("num")
        name = match.group("name").strip()
        if name.lower() == "offers":
            continue
        part_number = normalize_part_number(raw_number)
        records.append(
            {
                "part_number": part_number,
                "reference": last_ref,
                "name_en": name.title(),
                "model": "Y61",
                "years": ["1997-2010"],
                "category": category,
                "category_ar": category_ar,
                "quantity": match.group("qty"),
                "source_id": f"y61_7zap_{index:03d}",
                "source_url": section["url"],
                "section": section["name"],
                "context": f"{section['name']} | {last_ref} | {part_number} | {name} | x{match.group('qty')}",
            }
        )
    return records


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    sections = section_links()
    all_records = []
    sources = []
    for index, section in enumerate(sections, start=1):
        records = extract_section(section, index)
        if records:
            sources.append(
                {
                    "source_id": f"y61_7zap_{index:03d}",
                    "filename": section["url"],
                    "year": "1997-2010",
                    "kind": "online_oem_catalog_7zap",
                    "page_count": 1,
                    "section": section["name"],
                    "record_count": len(records),
                    "duplicate_group": [f"y61_7zap_{index:03d}"],
                }
            )
            all_records.extend(records)
        time.sleep(0.15)

    grouped = {}
    for record in all_records:
        part = grouped.setdefault(
            record["part_number"],
            {
                "part_number": record["part_number"],
                "name_ar": "",
                "name_en": record["name_en"],
                "model": "Y61",
                "years": ["1997-2010"],
                "category": record["category"],
                "category_ar": record["category_ar"],
                "occurrence_count": 0,
                "source_count": 0,
                "weighted_source_score": 0,
                "confidence": 72,
                "audit_status": "مستخرج من كتالوج موثوق ويحتاج مطابقة VIN",
                "rarity": "تحتاج تدقيق توفر",
                "evidence": [],
            },
        )
        part["occurrence_count"] += 1
        part["weighted_source_score"] += 1
        if len(part["evidence"]) < 6:
            part["evidence"].append(
                {
                    "source_id": record["source_id"],
                    "year": "1997-2010",
                    "page": 1,
                    "reference": record["reference"],
                    "quantity": record["quantity"],
                    "context": record["context"],
                }
            )

    for part in grouped.values():
        part["source_count"] = len({item["source_id"] for item in part["evidence"]})
        if part["occurrence_count"] >= 3:
            part["confidence"] = 78

    payload = {
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "model": "Nissan Patrol Y61",
        "market": "Europe",
        "source": "7zap public OEM catalog pages",
        "source_count": len(sources),
        "record_count": len(all_records),
        "part_count": len(grouped),
        "sources": sources,
        "parts": sorted(grouped.values(), key=lambda item: item["part_number"]),
        "records": all_records,
    }
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"output": str(OUTPUT.relative_to(ROOT)), "sources": len(sources), "records": len(all_records), "parts": len(grouped)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
