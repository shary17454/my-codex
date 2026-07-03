from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "sources" / "partsouq" / "wgy60348567_unit_details.json"
OUT = ROOT / "output" / "pdf"


GLOSSARY = {
    "ENGINE": "المحرك",
    "ASSEMBLY": "مجموعة",
    "ASSY": "مجموعة",
    "CYLINDER": "أسطوانة",
    "BLOCK": "كتلة المحرك",
    "OIL": "زيت",
    "PAN": "حوض الزيت",
    "HEAD": "رأس",
    "ROCKER": "غطاء الصمامات",
    "COVER": "غطاء",
    "GASKET": "وجه/جلدة",
    "KIT": "طقم",
    "MOUNTING": "تثبيت",
    "TRANSMISSION": "ناقل الحركة",
    "FAN": "مروحة",
    "COMPRESSOR": "كمبروسر",
    "POWER": "باور",
    "STEERING": "دركسون",
    "BELT": "سير",
    "CRANKCASE": "علبة المرفق",
    "VENTILATION": "تهوية",
    "PISTON": "بستم",
    "CRANKSHAFT": "عمود كرنك",
    "FLYWHEEL": "حدافة",
    "CAMSHAFT": "عمود كامات",
    "VALVE": "صمام",
    "MECHANISM": "آلية",
    "FRONT": "أمامي",
    "VACUUM": "فاكيوم",
    "PUMP": "طرمبة",
    "FITTING": "توصيلات",
    "MANIFOLD": "منفولد",
    "INTAKE": "سحب",
    "EXHAUST": "عادم",
    "PARTS": "قطع",
    "EGR": "EGR",
    "AIR": "هواء",
    "POLLUTION": "انبعاثات",
    "CONTROL": "تحكم",
    "LUBRICATING": "تزييت",
    "SYSTEM": "نظام",
    "BODY": "هيكل",
    "BRAKE": "فرامل",
    "AXLE": "محور",
    "SUSPENSION": "تعليق",
    "SEAT": "مقعد",
    "BELT": "حزام",
    "DOOR": "باب",
    "ROOF": "سقف",
    "FLOOR": "أرضية",
    "REAR": "خلفي",
    "SIDE": "جانبي",
}


def e(value: object) -> str:
    return html.escape(str(value or ""))


def translate_name(name: str) -> str:
    clean = (name or "").replace("&", " & ").replace(",", " , ").replace(";", " ; ")
    words = []
    for token in clean.split():
        key = token.strip(" ,;:-()").upper()
        words.append(GLOSSARY.get(key, token))
    translated = " ".join(words).replace(" ,", "،").replace(" ;", "؛")
    return translated if translated != name else "ترجمة فنية مطلوبة"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    data = json.loads(SRC.read_text(encoding="utf-8"))
    vehicle = data["vehicle"]
    units = data["units"]
    part_count = sum(len(unit["part_rows"]) for unit in units)

    unit_rows = []
    for unit in units:
        unit_rows.append(
            "<tr>"
            f"<td>{e(unit['group_text'])}</td>"
            f"<td>{e(unit['plate_code'])}</td>"
            f"<td>{e(unit['plate_title_en'])}<div class='ar'>{e(translate_name(unit['plate_title_en']))}</div></td>"
            f"<td>{len(unit['part_rows'])}</td>"
            f"<td><a href='{e(unit['diagram_image_url'])}'>Diagram source</a></td>"
            f"<td><a href='{e(unit['unit_url'])}'>PartSouq plate</a></td>"
            "</tr>"
        )

    sections = []
    for unit in units:
        rows = []
        for part in unit["part_rows"]:
            rows.append(
                "<tr>"
                f"<td>{e(part.get('reference_code'))}</td>"
                f"<td>{e(part.get('part_number'))}</td>"
                f"<td>{e(part.get('part_name_en'))}<div class='ar'>{e(translate_name(part.get('part_name_en', '')))}</div></td>"
                f"<td>{e(part.get('quantity'))}</td>"
                f"<td>{e(part.get('applicable_models'))}</td>"
                f"<td>{e(part.get('specifications'))}</td>"
                f"<td>{e(part.get('date_range'))}</td>"
                "</tr>"
            )
        sections.append(
            f"""
            <section class="plate">
              <h2>{e(unit['plate_code'])}: {e(unit['plate_title_en'])}</h2>
              <h2 class="ar">{e(translate_name(unit['plate_title_en']))}</h2>
              <p class="small">Group: {e(unit['group_text'])} | Parts rows: {len(unit['part_rows'])}</p>
              <p class="small">Diagram source: <a href="{e(unit['diagram_image_url'])}">{e(unit['diagram_image_url'])}</a></p>
              <table>
                <thead><tr><th>Ref</th><th>Part Number</th><th>Name / Arabic</th><th>Qty</th><th>Applicable Models</th><th>Spec</th><th>Date Range</th></tr></thead>
                <tbody>{''.join(rows)}</tbody>
              </table>
            </section>
            """
        )

    vehicle_rows = "".join(f"<tr><th>{e(k)}</th><td>{e(v)}</td></tr>" for k, v in vehicle.items())
    html_text = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Nissan Safari Y60 WGY60348567 Parts Catalog</title>
  <style>
    @page {{ size: A4 landscape; margin: 10mm; }}
    body {{ font-family: Arial, Tahoma, sans-serif; color: #111827; line-height: 1.32; }}
    h1 {{ color: #173f5f; font-size: 24px; margin: 0 0 8px; }}
    h2 {{ color: #173f5f; font-size: 15px; border-bottom: 1px solid #9fb3c8; padding-bottom: 3px; }}
    .ar {{ direction: rtl; text-align: right; font-family: Tahoma, Arial, sans-serif; margin-top: 3px; }}
    .note {{ border-left: 4px solid #b91c1c; background: #fff7ed; padding: 8px 10px; margin: 12px 0; font-size: 11px; }}
    .small {{ font-size: 9px; color: #374151; overflow-wrap: anywhere; }}
    table {{ width: 100%; border-collapse: collapse; table-layout: fixed; margin-top: 8px; }}
    th {{ background: #173f5f; color: #fff; text-align: left; font-size: 8px; padding: 4px; }}
    td {{ border: 1px solid #c7d0dc; vertical-align: top; font-size: 7.6px; padding: 3px; overflow-wrap: anywhere; }}
    .toc-table td, .toc-table th {{ font-size: 7.5px; }}
    .plate {{ page-break-before: always; }}
    a {{ color: #0f4c81; text-decoration: none; }}
  </style>
</head>
<body>
  <h1>Nissan Safari / Patrol Y60 Parts Catalog - WGY60348567</h1>
  <h1 class="ar">كتالوج قطع نيسان سفاري / باترول Y60 - WGY60348567</h1>
  <div class="note">
    Source: user-provided PartSouq genuine catalog URL. This PDF includes extracted part tables and source links to original diagrams. Official diagram images are not embedded in this edition.
    <div class="ar">المصدر: رابط PartSouq الأصلي المقدم من المستخدم. يتضمن هذا الملف جداول القطع المستخرجة وروابط مصادر المخططات الأصلية. لم يتم تضمين صور المخططات الرسمية داخل هذا الإصدار.</div>
  </div>
  <h2>Vehicle / بيانات المركبة</h2>
  <table>{vehicle_rows}</table>
  <h2>Coverage / التغطية</h2>
  <p>Catalog groups: 14 | Plates: {len(units)} | Extracted part rows: {part_count}</p>
  <p class="ar">عدد المجموعات: 14 | عدد اللوحات: {len(units)} | صفوف القطع المستخرجة: {part_count}</p>
  <h2>Plate Index / فهرس اللوحات</h2>
  <table class="toc-table">
    <thead><tr><th>Group</th><th>Plate</th><th>Title / Arabic</th><th>Rows</th><th>Diagram</th><th>Source Page</th></tr></thead>
    <tbody>{''.join(unit_rows)}</tbody>
  </table>
  {''.join(sections)}
</body>
</html>
"""
    (OUT / "wgy60348567_partsouq_catalog.html").write_text(html_text, encoding="utf-8")
    print(OUT / "wgy60348567_partsouq_catalog.html")


if __name__ == "__main__":
    main()
