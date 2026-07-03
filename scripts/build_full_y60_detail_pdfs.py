from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "sources" / "partsouq" / "full_y60"
OUT = ROOT / "output" / "pdf" / "full_y60"


AR = {
    "Nissan Patrol / Safari Y60 Detailed EPC Extract": "استخراج تفصيلي من كتالوج Nissan Patrol / Safari Y60",
    "Vehicle": "المركبة",
    "Market": "السوق",
    "Body Style": "نوع الهيكل",
    "Engine": "المحرك",
    "Grade": "الفئة",
    "Production": "الإنتاج",
    "Catalog Plates": "لوحات الكتالوج",
    "Exploded Diagram": "المخطط التفجيري",
    "Parts Table": "جدول القطع",
    "Part Number": "رقم القطعة",
    "English Name": "الاسم الإنجليزي",
    "Arabic Name": "الاسم العربي",
    "Reference": "رقم الإشارة",
    "Quantity": "الكمية",
    "Applicable Models": "الموديلات المطابقة",
    "Specifications": "المواصفات",
    "Verification Required": "يتطلب التحقق",
    "Source URL": "رابط المصدر",
    "Unit Failures": "اللوحات التي تحتاج مراجعة",
}


GLOSSARY = {
    "ENGINE": "محرك",
    "ASSY": "مجموعة",
    "ASSEMBLY": "مجموعة",
    "FUEL": "وقود",
    "HOSE": "لي",
    "PIPE": "ماسورة",
    "PIPING": "مواسير",
    "FILTER": "فلتر",
    "AIR": "هواء",
    "CLEANER": "منظف",
    "TANK": "خزان",
    "PUMP": "طرمبة",
    "INJECTION": "حقن",
    "EXHAUST": "عادم",
    "TUBE": "ماسورة",
    "MUFFLER": "شكمان",
    "WATER": "ماء",
    "COOLING": "تبريد",
    "FAN": "مروحة",
    "THERMOSTAT": "ثرموستات",
    "OIL": "زيت",
    "COOLER": "مبرد",
    "RADIATOR": "رديتر",
    "IGNITION": "إشعال",
    "ALTERNATOR": "دينمو",
    "STARTER": "سلف",
    "MOTOR": "موتور",
    "WIRING": "ظفيرة",
    "BODY": "هيكل",
    "ELECTRICAL": "كهرباء",
    "CLUTCH": "كلتش",
    "TRANSMISSION": "قير",
    "TRANSFER": "دبل",
    "GEAR": "ترس",
    "PROPELLER": "عمود",
    "SHAFT": "عمود",
    "FINAL": "نهائي",
    "DRIVE": "دفرنس",
    "BRAKE": "فرامل",
    "STEERING": "دركسون",
    "SUSPENSION": "تعليق",
    "AXLE": "محور",
    "DOOR": "باب",
    "ROOF": "سقف",
    "FLOOR": "أرضية",
    "SEAT": "مقعد",
    "BELT": "حزام",
    "LAMP": "لمبة",
    "SWITCH": "مفتاح",
    "COVER": "غطاء",
    "BRACKET": "حامل",
    "BOLT": "مسمار",
    "NUT": "صامولة",
    "GASKET": "وجه/جلدة",
    "SEAL": "صوفة/مانع تسرب",
    "KIT": "طقم",
    "FRONT": "أمامي",
    "REAR": "خلفي",
    "SIDE": "جانبي",
    "UPPER": "علوي",
    "LOWER": "سفلي",
    "RIGHT": "يمين",
    "LEFT": "يسار",
}


def esc(value: object) -> str:
    return html.escape(str(value or ""))


def translate_name(name: str) -> str:
    out: list[str] = []
    changed = False
    for raw in str(name or "").replace(",", " , ").replace("-", " - ").replace("/", " / ").split():
        key = "".join(ch for ch in raw.upper() if ch.isalnum())
        if key in GLOSSARY:
            out.append(GLOSSARY[key])
            changed = True
        else:
            out.append(raw)
    return " ".join(out) if changed else "يتطلب التحقق"


def filename_for(data: dict, source: Path) -> str:
    c = data.get("category", {})
    bits = [
        data.get("extract_id", source.stem.split("_", 1)[0]),
        c.get("market", ""),
        c.get("body_style", ""),
        c.get("engine", ""),
        c.get("grade_or_frame", ""),
    ]
    safe = "_".join(str(x) for x in bits if x)
    safe = "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in safe)
    while "__" in safe:
        safe = safe.replace("__", "_")
    return safe[:150] or source.stem


def build_html(data: dict, source: Path) -> str:
    c = data.get("category", {})
    units = data.get("units", [])
    failures = data.get("failures", []) + data.get("group_failures", [])
    part_count = sum(len(u.get("part_rows", [])) for u in units)
    title = f"{c.get('market','')} {c.get('body_style','')} {c.get('engine','')} {c.get('grade_or_frame','')}".strip()

    css = """
    @page { size: A4 landscape; margin: 10mm; }
    * { box-sizing: border-box; }
    body { font-family: Arial, "Segoe UI", Tahoma, sans-serif; color: #172026; margin: 0; }
    .ar { direction: rtl; text-align: right; font-family: "Segoe UI", Tahoma, Arial, sans-serif; color: #35434b; }
    h1 { font-size: 30px; margin: 0 0 8px; }
    h2 { font-size: 20px; margin: 18px 0 8px; color: #174b3d; break-after: avoid; }
    h3 { font-size: 16px; margin: 12px 0 6px; break-after: avoid; }
    .cover { min-height: 120mm; display: flex; flex-direction: column; justify-content: center; border-bottom: 3px solid #174b3d; margin-bottom: 8mm; }
    .summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin-top: 14px; }
    .box { border: 1px solid #c6d3ce; padding: 9px; min-height: 44px; }
    .box strong { display: block; font-size: 20px; }
    table { width: 100%; border-collapse: collapse; table-layout: fixed; font-size: 9px; margin: 8px 0 14px; }
    th { background: #1f3f36; color: white; text-align: left; padding: 5px; }
    td { border: 1px solid #ccd6d2; padding: 4px; vertical-align: top; overflow-wrap: anywhere; }
    tr:nth-child(even) td { background: #f8faf9; }
    .plate { break-before: page; }
    .diagram { max-width: 100%; max-height: 90mm; object-fit: contain; border: 1px solid #ccd6d2; }
    .muted { color: #62707a; font-size: 10px; }
    .warn { background: #fff8e5; border-left: 5px solid #986b00; padding: 8px 10px; margin: 10px 0; }
    """
    parts = [
        "<!doctype html><html><head><meta charset='utf-8'>",
        f"<title>{esc(title)}</title><style>{css}</style></head><body>",
        "<section class='cover'>",
        f"<h1>{esc(AR['Nissan Patrol / Safari Y60 Detailed EPC Extract'])}</h1>",
        f"<h1>{esc(title)}</h1>",
        f"<div class='ar'><h1>{esc(AR['Nissan Patrol / Safari Y60 Detailed EPC Extract'])}</h1></div>",
        "<div class='summary'>",
        f"<div class='box'><span>Catalog Plates</span><strong>{len(units)}</strong><div class='ar'>{AR['Catalog Plates']}</div></div>",
        f"<div class='box'><span>Part Rows</span><strong>{part_count}</strong><div class='ar'>صفوف القطع</div></div>",
        f"<div class='box'><span>Unit Failures</span><strong>{len(failures)}</strong><div class='ar'>{AR['Unit Failures']}</div></div>",
        f"<div class='box'><span>Extract ID</span><strong>{esc(data.get('extract_id',''))}</strong><div class='ar'>معرف الاستخراج</div></div>",
        "</div></section>",
        f"<h2>Vehicle</h2><div class='ar'><h2>{AR['Vehicle']}</h2></div>",
        "<table><tbody>",
    ]
    for label, key in [
        ("Market", "market"),
        ("Body Style", "body_style"),
        ("Engine", "engine"),
        ("Grade", "grade_or_frame"),
        ("Production", "production_from"),
        ("Source URL", "vehicle_url"),
    ]:
        value = c.get(key, "")
        if key == "production_from":
            value = f"{c.get('production_from','')} - {c.get('production_to','')}"
        parts.append(f"<tr><th>{esc(label)}<br><span class='ar'>{esc(AR.get(label,''))}</span></th><td>{esc(value)}</td></tr>")
    parts.append("</tbody></table>")

    if failures:
        parts.append(f"<div class='warn'><strong>{AR['Verification Required']}</strong><br>{len(failures)} units/groups need review. They are preserved in the JSON source and not discarded.<div class='ar'>توجد لوحات/مجموعات تحتاج مراجعة، وتم حفظها في ملف المصدر ولم يتم حذفها.</div></div>")

    for unit in units:
        rows = unit.get("part_rows", [])
        parts.extend([
            "<section class='plate'>",
            f"<h2>{esc(unit.get('plate_code',''))} - {esc(unit.get('plate_title_en',''))}</h2>",
            f"<div class='ar'><h2>{AR['Catalog Plates']} - {esc(translate_name(unit.get('plate_title_en','')))}</h2></div>",
            f"<p class='muted'>Group: {esc(unit.get('group_text',''))} | Source: <a href='{esc(unit.get('unit_url',''))}'>{esc(unit.get('unit_url',''))}</a></p>",
        ])
        if unit.get("diagram_image_url"):
            parts.append(f"<h3>Exploded Diagram</h3><div class='ar'><h3>{AR['Exploded Diagram']}</h3></div><img class='diagram' src='{esc(unit.get('diagram_image_url'))}' alt='{esc(unit.get('diagram_alt',''))}'><p class='muted'>{esc(unit.get('diagram_image_url'))}</p>")
        if not rows:
            parts.append(f"<div class='warn'><strong>{AR['Verification Required']}</strong><br>No part rows were visible/extracted for this plate. Diagram/title preserved.<div class='ar'>لم تظهر أو لم تُستخرج صفوف قطع لهذه اللوحة. تم حفظ عنوان اللوحة والمخطط للمراجعة.</div></div>")
        else:
            parts.append("<h3>Parts Table</h3><div class='ar'><h3>جدول القطع</h3></div>")
            parts.append("<table><thead><tr>")
            for col in ["Reference", "Part Number", "English Name", "Arabic Name", "Quantity", "Applicable Models", "Specifications"]:
                parts.append(f"<th>{esc(col)}<br><span class='ar'>{esc(AR.get(col,''))}</span></th>")
            parts.append("</tr></thead><tbody>")
            for row in rows:
                name = row.get("part_name_en", "")
                vals = [
                    row.get("reference_code", ""),
                    row.get("part_number", ""),
                    name,
                    translate_name(name),
                    row.get("quantity", ""),
                    row.get("applicable_models", ""),
                    row.get("specifications", ""),
                ]
                parts.append("<tr>" + "".join(f"<td>{esc(v)}</td>" for v in vals) + "</tr>")
            parts.append("</tbody></table>")
        parts.append("</section>")

    parts.append("</body></html>")
    return "".join(parts)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    for source in sorted(SRC.glob("*.json")):
        data = json.loads(source.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            continue
        if not data.get("units"):
            continue
        name = filename_for(data, source)
        html_path = OUT / f"{name}.html"
        pdf_path = OUT / f"{name}.pdf"
        html_path.write_text(build_html(data, source), encoding="utf-8")
        manifest.append({"source": str(source), "html": str(html_path), "pdf": str(pdf_path), "units": len(data.get("units", [])), "parts": sum(len(u.get("part_rows", [])) for u in data.get("units", []))})
    (OUT / "full_y60_pdf_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"html_files": len(manifest), "out": str(OUT)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
