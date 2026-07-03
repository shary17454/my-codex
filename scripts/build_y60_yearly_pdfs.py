from __future__ import annotations

import csv
import html
import json
import re
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CAT_CSV = ROOT / "output" / "database" / "nissan_y60_all_categories.csv"
WGY_JSON = ROOT / "sources" / "partsouq" / "wgy60348567_unit_details.json"
OUT = ROOT / "output" / "pdf" / "yearly"


YEARS = list(range(1988, 1998))


AR_TERMS = {
    "Nissan Patrol Y60": "نيسان باترول Y60",
    "Nissan Safari Y60": "نيسان سفاري Y60",
    "Year": "السنة",
    "Market": "السوق",
    "Model": "الموديل",
    "Body Style": "نوع الهيكل",
    "Engine": "المحرك",
    "Grade": "الفئة",
    "Production From": "بداية الإنتاج",
    "Production To": "نهاية الإنتاج",
    "Options": "التجهيزات",
    "Source": "المصدر",
    "Verification Required": "يتطلب التحقق",
    "Catalog Plates": "لوحات الكتالوج",
    "Exploded Diagram": "المخطط التفجيري",
    "Part Number": "رقم القطعة",
    "Reference": "رقم الإشارة",
    "Part Name": "اسم القطعة",
    "Quantity": "الكمية",
    "Applicability": "التطبيق",
    "Specifications": "المواصفات",
    "Notes": "ملاحظات",
    "Missing Detail Report": "تقرير التفاصيل الناقصة",
    "Complete parts extraction is not yet available for this model source.": "استخراج القطع الكامل غير متوفر بعد لمصدر هذا الموديل.",
    "This document contains only verified data extracted from the available PartSouq pages.": "يحتوي هذا المستند فقط على البيانات المتحقق منها والمستخرجة من صفحات PartSouq المتاحة.",
}


NAME_GLOSSARY = {
    "ENGINE": "محرك",
    "ASSY": "مجموعة",
    "ASSEMBLY": "مجموعة",
    "CYLINDER": "أسطوانة",
    "BLOCK": "بلوك المحرك",
    "HEAD": "رأس",
    "OIL": "زيت",
    "PAN": "حوض",
    "GASKET": "وجه/جلدة",
    "KIT": "طقم",
    "COVER": "غطاء",
    "VALVE": "صمام",
    "PISTON": "بستم",
    "RING": "شنبر",
    "BEARING": "سبايك/رمان",
    "PUMP": "طرمبة",
    "FUEL": "وقود",
    "WATER": "ماء",
    "AIR": "هواء",
    "FILTER": "فلتر",
    "HOSE": "لي",
    "PIPE": "ماسورة",
    "BRACKET": "حامل",
    "BOLT": "مسمار",
    "NUT": "صامولة",
    "WASHER": "واشر",
    "SEAL": "صوفة/مانع تسرب",
    "FRONT": "أمامي",
    "REAR": "خلفي",
    "SIDE": "جانبي",
    "RIGHT": "يمين",
    "LEFT": "يسار",
    "UPPER": "علوي",
    "LOWER": "سفلي",
    "BODY": "هيكل",
    "DOOR": "باب",
    "ROOF": "سقف",
    "FLOOR": "أرضية",
    "SEAT": "مقعد",
    "BELT": "حزام",
    "BRAKE": "فرامل",
    "STEERING": "دركسون",
    "AXLE": "محور",
    "SUSPENSION": "تعليق",
    "TRANSMISSION": "قير",
    "TRANSFER": "دبل",
    "CASE": "علبة",
    "SHAFT": "عمود",
    "GEAR": "ترس",
    "LAMP": "لمبة",
    "SWITCH": "مفتاح",
    "HARNESS": "ظفيرة",
    "RELAY": "ريليه",
}


def h(value: object) -> str:
    return html.escape(str(value or ""))


def ar(text: str) -> str:
    return AR_TERMS.get(text, "ترجمة فنية مطلوبة")


def translate_part_name(name: str) -> str:
    words = []
    changed = False
    for token in re.split(r"(\W+)", name or ""):
        key = re.sub(r"[^A-Za-z0-9]", "", token).upper()
        if key in NAME_GLOSSARY:
            words.append(NAME_GLOSSARY[key])
            changed = True
        else:
            words.append(token)
    return "".join(words) if changed else "ترجمة فنية مطلوبة"


def parse_years(value: str) -> list[int]:
    years: list[int] = []
    for match in re.findall(r"(?:0[1-9]|1[0-2])\.(19\d{2}|20\d{2})", value or ""):
        years.append(int(match))
    return years


def active_for_year(row: dict[str, str], year: int) -> bool:
    start_years = parse_years(row.get("production_from", ""))
    end_years = parse_years(row.get("production_to", ""))
    start = start_years[0] if start_years else 1988
    end = end_years[0] if end_years else 1997
    return start <= year <= end


def part_active_for_year(part: dict[str, object], year: int) -> bool:
    text = " ".join(str(part.get(k, "")) for k in ("specifications", "date_range", "applicable_models"))
    years = parse_years(text)
    if not years:
        return True
    if len(years) == 1:
        return years[0] <= year
    return min(years) <= year <= max(years)


def load_categories() -> list[dict[str, str]]:
    with CAT_CSV.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def load_wgy() -> dict[str, object]:
    return json.loads(WGY_JSON.read_text(encoding="utf-8"))


def vehicle_summary(vehicle: dict[str, object]) -> str:
    keys = ["name", "bodyStyle", "engine", "grade", "market", "model", "date", "framecolor"]
    return " | ".join(f"{k}: {vehicle.get(k, '')}" for k in keys)


def build_year_html(year: int, categories: list[dict[str, str]], wgy: dict[str, object]) -> str:
    active = [r for r in categories if active_for_year(r, year)]
    by_market = Counter(r["market"] for r in active)
    by_engine = Counter(r["engine"] for r in active)
    missing = [r for r in active if "WGY60348567" not in r.get("vehicle_url", "")]
    units = []
    for unit in wgy.get("units", []):
        parts = [p for p in unit.get("part_rows", []) if part_active_for_year(p, year)]
        if parts:
            cloned = dict(unit)
            cloned["part_rows"] = parts
            units.append(cloned)

    css = """
    @page { size: A4 landscape; margin: 12mm; }
    * { box-sizing: border-box; }
    body { font-family: Arial, "Segoe UI", Tahoma, sans-serif; color: #172026; margin: 0; background: #fff; }
    .cover { min-height: 118mm; display: flex; flex-direction: column; justify-content: center; border-bottom: 3px solid #1b4d3e; margin-bottom: 8mm; }
    h1 { font-size: 34px; margin: 0 0 10px; letter-spacing: 0; }
    h2 { font-size: 22px; margin: 22px 0 8px; color: #1b4d3e; break-after: avoid; }
    h3 { font-size: 17px; margin: 18px 0 8px; color: #263238; break-after: avoid; }
    .ar { direction: rtl; text-align: right; font-family: "Segoe UI", Tahoma, Arial, sans-serif; color: #35434b; }
    .muted { color: #5b6770; font-size: 12px; }
    .tag { display: inline-block; border: 1px solid #b9c8c2; padding: 3px 7px; margin: 2px; border-radius: 4px; background: #f3f7f5; font-size: 11px; }
    table { width: 100%; border-collapse: collapse; margin: 8px 0 16px; font-size: 10px; table-layout: fixed; }
    th { background: #1f3f36; color: #fff; text-align: left; padding: 6px; }
    td { border: 1px solid #ccd6d2; padding: 5px; vertical-align: top; overflow-wrap: anywhere; }
    tr:nth-child(even) td { background: #f8faf9; }
    .summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin: 14px 0; }
    .box { border: 1px solid #c9d5d0; padding: 10px; min-height: 45px; }
    .box strong { display: block; font-size: 18px; }
    .plate { break-before: page; }
    .diagram { max-width: 100%; max-height: 88mm; border: 1px solid #d5ddd9; background: #fff; object-fit: contain; }
    .notice { border-left: 5px solid #986b00; background: #fff8e5; padding: 10px 12px; margin: 10px 0; }
    .small { font-size: 9px; }
    """

    parts_count = sum(len(u["part_rows"]) for u in units)
    plates_count = len(units)

    out: list[str] = [
        "<!doctype html><html><head><meta charset='utf-8'>",
        f"<title>Y60 {year}</title><style>{css}</style></head><body>",
        "<section class='cover'>",
        f"<h1>Nissan Patrol / Safari Y60 {year}</h1>",
        f"<div class='ar'><h1>نيسان باترول / سفاري Y60 {year}</h1></div>",
        "<p>This document contains only verified data extracted from the available PartSouq pages.</p>",
        f"<p class='ar'>{ar('This document contains only verified data extracted from the available PartSouq pages.')}</p>",
        "<div class='summary'>",
        f"<div class='box'><span>Applicable Y60 rows</span><strong>{len(active)}</strong><div class='ar'>تطبيقات Y60 للسنة</div></div>",
        f"<div class='box'><span>Markets</span><strong>{len(by_market)}</strong><div class='ar'>الأسواق</div></div>",
        f"<div class='box'><span>Catalog plates available</span><strong>{plates_count}</strong><div class='ar'>لوحات كتالوج متاحة</div></div>",
        f"<div class='box'><span>Part rows available</span><strong>{parts_count}</strong><div class='ar'>صفوف قطع متاحة</div></div>",
        "</div>",
        f"<p class='muted'>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}</p>",
        "</section>",
        "<h2>Scope</h2><div class='ar'><h2>نطاق الملف</h2></div>",
        "<div class='notice'><strong>Verification Required</strong><br>",
        "Full EPC plates and diagrams are available only for sources already extracted. Remaining model links are listed in the missing detail report below.",
        f"<div class='ar'><strong>{ar('Verification Required')}</strong><br>اللوحات والمخططات الكاملة متاحة فقط للمصادر التي تم استخراجها فعلياً. روابط بقية الموديلات مدرجة في تقرير التفاصيل الناقصة أدناه.</div></div>",
        "<h2>Year Applicability Index</h2><div class='ar'><h2>فهرس تطبيقات السنة</h2></div>",
        "<h3>Markets</h3><div class='ar'><h3>الأسواق</h3></div>",
        "".join(f"<span class='tag'>{h(k)}: {v}</span>" for k, v in sorted(by_market.items())),
        "<h3>Engines</h3><div class='ar'><h3>المحركات</h3></div>",
        "".join(f"<span class='tag'>{h(k)}: {v}</span>" for k, v in sorted(by_engine.items())),
        "<table><thead><tr>",
        "".join(f"<th>{h(x)}<br><span class='ar'>{h(ar(x))}</span></th>" for x in ["Market", "Model", "Body Style", "Engine", "Grade", "Production From", "Production To", "Source"]),
        "</tr></thead><tbody>",
    ]
    for r in active:
        out.append("<tr>")
        for key in ["market", "filter_model", "body_style", "engine", "grade_or_frame", "production_from", "production_to", "vehicle_url"]:
            value = r.get(key, "")
            if key == "vehicle_url" and value:
                value = f"<a href='{h(value)}'>PartSouq vehicle</a>"
            else:
                value = h(value)
            out.append(f"<td>{value}</td>")
        out.append("</tr>")
    out.append("</tbody></table>")

    out.extend([
        "<h2>Available Complete Parts Source</h2><div class='ar'><h2>مصدر القطع الكامل المتاح</h2></div>",
        f"<p>{h(vehicle_summary(wgy.get('vehicle', {})))}</p>",
        "<p class='ar'>هذا القسم يمثل المركبة المستخرجة بالكامل فقط، ولا يعمم على جميع الفئات بدون تحقق.</p>",
        "<div class='notice'><strong>Supersession and replacement note</strong><br>Superseded and replacement part numbers are not shown unless they were present in the extracted source row. Missing values are treated as Verification Required, not blank verified data.<div class='ar'><strong>ملاحظة أرقام الاستبدال</strong><br>لا يتم عرض أرقام الاستبدال أو الأرقام البديلة إلا إذا كانت ظاهرة في صف المصدر المستخرج. القيم غير الموجودة تعتبر يتطلب التحقق وليست بيانات مؤكدة فارغة.</div></div>",
    ])

    for unit in units:
        title = unit.get("plate_title_en", "") or unit.get("page_title", "")
        plate = unit.get("plate_code", "")
        diagram = unit.get("diagram_image_url", "")
        parts = unit.get("part_rows", [])
        out.extend([
            "<section class='plate'>",
            f"<h2>{h(plate)} - {h(title)}</h2>",
            f"<div class='ar'><h2>{ar('Catalog Plates')} - ترجمة عنوان اللوحة تتطلب تحققاً فنياً</h2></div>",
            f"<p class='muted'>Group: {h(unit.get('group_text', ''))} | Source: <a href='{h(unit.get('unit_url', ''))}'>PartSouq unit</a></p>",
        ])
        if diagram:
            out.append(f"<h3>Exploded Diagram</h3><div class='ar'><h3>{ar('Exploded Diagram')}</h3></div><img class='diagram' src='{h(diagram)}' alt='{h(title)}'>")
            out.append(f"<p class='small'>{h(diagram)}</p>")
        out.append("<table><thead><tr>")
        for col in ["Reference", "Part Number", "Part Name", "Quantity", "Applicability", "Specifications"]:
            out.append(f"<th>{h(col)}<br><span class='ar'>{h(ar(col))}</span></th>")
        out.append("</tr></thead><tbody>")
        for p in parts:
            part_name = str(p.get("part_name_en", ""))
            out.append("<tr>")
            cells = [
                p.get("reference_code", ""),
                p.get("part_number", ""),
                f"{h(part_name)}<br><span class='ar'>{h(translate_part_name(part_name))}</span>",
                p.get("quantity", ""),
                p.get("applicable_models", ""),
                p.get("specifications", ""),
            ]
            for cell in cells:
                out.append(f"<td>{cell if isinstance(cell, str) and '<' in cell else h(cell)}</td>")
            out.append("</tr>")
        out.append("</tbody></table></section>")

    out.extend([
        "<section class='plate'>",
        "<h2>Missing Detail Report</h2><div class='ar'><h2>تقرير التفاصيل الناقصة</h2></div>",
        "<p>Complete parts extraction is not yet available for this model source.</p>",
        f"<p class='ar'>{ar('Complete parts extraction is not yet available for this model source.')}</p>",
        "<table><thead><tr>",
        "".join(f"<th>{h(x)}<br><span class='ar'>{h(ar(x))}</span></th>" for x in ["Market", "Model", "Body Style", "Engine", "Grade", "Production From", "Production To", "Notes", "Source"]),
        "</tr></thead><tbody>",
    ])
    for r in missing:
        out.append("<tr>")
        for key in ["market", "filter_model", "body_style", "engine", "grade_or_frame", "production_from", "production_to"]:
            out.append(f"<td>{h(r.get(key, ''))}</td>")
        out.append("<td>Verification Required - full EPC plates, diagrams, supersessions, and replacements not extracted yet.<br><span class='ar'>يتطلب التحقق - لم يتم استخراج لوحات EPC الكاملة والمخططات وأرقام الاستبدال لهذا المصدر بعد.</span></td>")
        out.append(f"<td><a href='{h(r.get('vehicle_url', ''))}'>PartSouq vehicle</a></td>")
        out.append("</tr>")
    out.append("</tbody></table></section></body></html>")
    return "".join(out)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    categories = load_categories()
    wgy = load_wgy()
    manifest = []
    for year in YEARS:
        html_text = build_year_html(year, categories, wgy)
        html_path = OUT / f"Y60 {year}.html"
        html_path.write_text(html_text, encoding="utf-8")
        manifest.append({"year": year, "html": str(html_path), "pdf": str(OUT / f"Y60 {year}.pdf")})
    (OUT / "yearly_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps({"generated_html": len(manifest), "out": str(OUT)}, indent=2))


if __name__ == "__main__":
    main()
