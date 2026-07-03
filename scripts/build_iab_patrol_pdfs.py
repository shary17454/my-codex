from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

import arabic_reshaper
from bidi.algorithm import get_display
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "sources" / "partsouq" / "full_patrol_all_iab"
IMG_CACHE = ROOT / "sources" / "partsouq" / "image_cache"
OUT_DIR = ROOT / "output" / "pdf" / "patrol_iab_merged"
REPORT_DIR = ROOT / "output" / "reports"
SCRIPT_MTIME = Path(__file__).stat().st_mtime

AR_RE = re.compile(r"[\u0600-\u06ff]")

LABEL_AR = {
    "Catalog": "الكتالوج",
    "Vehicle": "السيارة",
    "Market": "السوق",
    "Body Style": "نوع الهيكل",
    "Engine": "المحرك",
    "Grade": "الفئة",
    "Production": "فترة الإنتاج",
    "Source": "المصدر",
    "Extract ID": "معرف الاستخراج",
    "Summary": "الملخص",
    "Catalog Plates": "لوحات الكتالوج",
    "Extracted Plates": "اللوحات المستخرجة",
    "Parts Rows": "صفوف القطع",
    "Diagram Images": "صور المخططات",
    "Verification Required": "يتطلب التحقق",
    "Original EPC Plate": "لوحة EPC الأصلية",
    "Original Title": "العنوان الأصلي",
    "Arabic Title": "العنوان العربي",
    "Exploded Diagram": "المخطط التفجيري",
    "Parts Table": "جدول القطع",
    "Ref": "المرجع",
    "Part Number": "رقم القطعة",
    "English Name": "الاسم الإنجليزي",
    "Arabic Name": "الاسم العربي",
    "Qty": "الكمية",
    "Applicable Models": "الموديلات المطابقة",
    "Specification": "المواصفة",
    "Range": "الفترة",
    "Notes": "ملاحظات",
    "Missing EPC Plates Report": "تقرير لوحات EPC غير المتاحة",
    "No verified part rows were available for this plate.": "لم تتوفر صفوف قطع مؤكدة لهذه اللوحة.",
    "Diagram image was not available in the local cache.": "صورة المخطط غير متوفرة في الكاش المحلي.",
}

PHRASES = {
    "ENGINE ASSEMBLY": "مجموعة المحرك",
    "ENGINE ASSY": "مجموعة المحرك",
    "ENGINE GASKET KIT": "طقم وجيهات المحرك",
    "CYLINDER BLOCK & OIL PAN": "بلوك المحرك والكرتير",
    "CAMSHAFT & VALVE MECHANISM": "عمود الكامات وآلية الصمامات",
    "PISTON,CRANKSHAFT & FLYWHEEL": "البساتم وعمود الكرنك والحدافة",
    "LUBRICATING SYSTEM": "نظام التزييت",
    "FUEL PUMP": "طرمبة الوقود",
    "FUEL TANK": "خزان الوقود",
    "EXHAUST TUBE & MUFFLER": "ماسورة العادم والشكمان",
    "WATER PUMP": "طرمبة الماء",
    "RADIATOR": "الرديتر",
    "IGNITION SYSTEM": "نظام الإشعال",
    "ALTERNATOR": "الدينمو",
    "STARTER MOTOR": "السلف",
    "BODY ELECTRICAL": "كهرباء البودي",
    "ENGINE ELECTRICAL": "كهرباء المحرك",
    "TRANSFER CASE": "علبة الدبل",
    "TRANSMISSION CASE": "علبة القير",
    "CLUTCH CONTROL": "تحكم الكلتش",
    "PROPELLER SHAFT": "عمود الكردان",
    "FRONT AXLE": "الدفرنس الأمامي",
    "REAR AXLE": "الدفرنس الخلفي",
    "BRAKE PIPING": "مواسير الفرامل",
    "PARKING BRAKE": "فرامل التوقف",
    "STEERING COLUMN": "عمود الدركسون",
    "POWER STEERING": "باور الدركسون",
    "FRONT SUSPENSION": "التعليق الأمامي",
    "REAR SUSPENSION": "التعليق الخلفي",
    "INSTRUMENT PANEL": "الطبلون",
    "HEATER & BLOWER UNIT": "وحدة الدفاية والمروحة",
    "AIR CONDITIONER": "المكيف",
    "REAR COOLER": "المكيف الخلفي",
    "WINCH": "الونش",
}

WORDS = {
    "ENGINE": "محرك",
    "ASSY": "مجموعة",
    "ASSEMBLY": "مجموعة",
    "GASKET": "وجه",
    "KIT": "طقم",
    "CYLINDER": "أسطوانة",
    "BLOCK": "بلوك",
    "OIL": "زيت",
    "PAN": "كرتير",
    "CAMSHAFT": "عمود كامات",
    "VALVE": "صمام",
    "MECHANISM": "آلية",
    "PISTON": "بستم",
    "CRANKSHAFT": "عمود كرنك",
    "FLYWHEEL": "حدافة",
    "FUEL": "وقود",
    "PUMP": "طرمبة",
    "TANK": "خزان",
    "EXHAUST": "عادم",
    "TUBE": "ماسورة",
    "PIPE": "ماسورة",
    "PIPING": "مواسير",
    "HOSE": "لي",
    "MUFFLER": "شكمان",
    "WATER": "ماء",
    "COOLING": "تبريد",
    "FAN": "مروحة",
    "THERMOSTAT": "ثرموستات",
    "RADIATOR": "رديتر",
    "FILTER": "فلتر",
    "AIR": "هواء",
    "CLEANER": "منظف",
    "IGNITION": "إشعال",
    "ALTERNATOR": "دينمو",
    "STARTER": "سلف",
    "MOTOR": "موتور",
    "WIRING": "ضفيرة",
    "HARNESS": "ضفيرة",
    "BODY": "بودي",
    "ELECTRICAL": "كهرباء",
    "CLUTCH": "كلتش",
    "TRANSMISSION": "قير",
    "TRANSFER": "دبل",
    "CASE": "علبة",
    "GEAR": "ترس",
    "PROPELLER": "كردان",
    "SHAFT": "عمود",
    "AXLE": "محور",
    "DIFFERENTIAL": "دفرنس",
    "BRAKE": "فرامل",
    "STEERING": "دركسون",
    "SUSPENSION": "تعليق",
    "DOOR": "باب",
    "ROOF": "سقف",
    "FLOOR": "أرضية",
    "SEAT": "مقعد",
    "BELT": "حزام",
    "LAMP": "لمبة",
    "LIGHT": "نور",
    "SWITCH": "مفتاح",
    "COVER": "غطاء",
    "BRACKET": "حامل",
    "BOLT": "مسمار",
    "NUT": "صامولة",
    "SEAL": "صوفة",
    "FRONT": "أمامي",
    "REAR": "خلفي",
    "SIDE": "جانبي",
    "UPPER": "علوي",
    "LOWER": "سفلي",
    "RIGHT": "يمين",
    "LEFT": "يسار",
    "CONTROL": "تحكم",
    "CABLE": "سلك",
    "PANEL": "لوحة",
    "GLASS": "زجاج",
    "MIRROR": "مراية",
    "HANDLE": "يد",
    "LOCK": "قفل",
    "REGULATOR": "منظم",
}


def register_fonts() -> tuple[str, str]:
    choices = [
        (Path("C:/Windows/Fonts/arial.ttf"), Path("C:/Windows/Fonts/arialbd.ttf")),
        (Path("C:/Windows/Fonts/tahoma.ttf"), Path("C:/Windows/Fonts/tahomabd.ttf")),
    ]
    for regular, bold in choices:
        if regular.exists():
            pdfmetrics.registerFont(TTFont("CatalogFont", str(regular)))
            pdfmetrics.registerFont(TTFont("CatalogFont-Bold", str(bold if bold.exists() else regular)))
            return "CatalogFont", "CatalogFont-Bold"
    return "Helvetica", "Helvetica-Bold"


FONT, BOLD = register_fonts()


def rtl(text: Any) -> str:
    value = "" if text is None else str(text)
    if not AR_RE.search(value):
        return value
    return get_display(arabic_reshaper.reshape(value))


def clean_text(text: Any) -> str:
    return re.sub(r"\s+", " ", "" if text is None else str(text)).strip()


def translate(text: Any) -> str:
    value = clean_text(text)
    if not value:
        return rtl("يتطلب التحقق")
    upper = value.upper()
    for phrase, ar in sorted(PHRASES.items(), key=lambda item: len(item[0]), reverse=True):
        if phrase in upper:
            return rtl(ar)
    tokens = re.split(r"(\W+)", value)
    out: list[str] = []
    changed = False
    for token in tokens:
        key = re.sub(r"[^A-Z0-9]", "", token.upper())
        if key in WORDS:
            out.append(WORDS[key])
            changed = True
        else:
            out.append(token)
    return rtl("".join(out) if changed else "يتطلب التحقق")


def para(text: Any, style: ParagraphStyle) -> Paragraph:
    return Paragraph(clean_text(text).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"), style)


def ar_para(text: Any, style: ParagraphStyle) -> Paragraph:
    return Paragraph(rtl(text).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"), style)


def safe_name(value: str) -> str:
    out = "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in value)
    while "__" in out:
        out = out.replace("__", "_")
    return out.strip("._")[:170] or "catalog"


def image_cache_path(url: str) -> Path:
    ext = Path(url.split("?", 1)[0]).suffix.lower() or ".gif"
    return IMG_CACHE / f"{hashlib.sha1(url.encode('utf-8')).hexdigest()}{ext}"


def part_rows(unit: dict[str, Any]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for table in unit.get("tables", []):
        headers = [clean_text(h) for h in table.get("headers", [])]
        if not {"Number", "Name", "Code"}.issubset(set(headers)):
            continue
        idx = {header: pos for pos, header in enumerate(headers)}
        for raw in table.get("rows", [])[1:]:
            def cell(name: str) -> str:
                pos = idx.get(name)
                return clean_text(raw[pos]) if pos is not None and pos < len(raw) else ""

            number = cell("Number")
            name = cell("Name")
            if not number and not name:
                continue
            rows.append(
                {
                    "reference": cell("Code"),
                    "part_number": number,
                    "name": name,
                    "quantity": cell("Quantity"),
                    "applicable": cell("Applicable Models"),
                    "specification": cell("Specification"),
                    "range": cell("Range"),
                }
            )
    if rows:
        return rows
    for row in unit.get("part_rows", []):
        number = clean_text(row.get("part_number"))
        name = clean_text(row.get("part_name_en"))
        if number.lower() in {"brand", "number"} or name.lower() in {"name"}:
            continue
        rows.append(
            {
                "reference": clean_text(row.get("reference_code")),
                "part_number": number,
                "name": name,
                "quantity": clean_text(row.get("quantity")),
                "applicable": clean_text(row.get("applicable_models")),
                "specification": clean_text(row.get("specifications")),
                "range": clean_text(row.get("range")),
            }
        )
    return rows


def make_styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "title",
            parent=base["Title"],
            fontName=BOLD,
            fontSize=20,
            leading=24,
            alignment=TA_LEFT,
            spaceAfter=6,
        ),
        "title_ar": ParagraphStyle(
            "title_ar",
            parent=base["Title"],
            fontName=BOLD,
            fontSize=18,
            leading=23,
            alignment=TA_RIGHT,
            spaceAfter=8,
        ),
        "h2": ParagraphStyle("h2", parent=base["Heading2"], fontName=BOLD, fontSize=13, leading=16, spaceBefore=8),
        "h2_ar": ParagraphStyle(
            "h2_ar", parent=base["Heading2"], fontName=BOLD, fontSize=13, leading=16, alignment=TA_RIGHT, spaceBefore=4
        ),
        "cell": ParagraphStyle("cell", parent=base["BodyText"], fontName=FONT, fontSize=6.8, leading=8),
        "cell_ar": ParagraphStyle(
            "cell_ar", parent=base["BodyText"], fontName=FONT, fontSize=6.8, leading=8, alignment=TA_RIGHT
        ),
        "small": ParagraphStyle("small", parent=base["BodyText"], fontName=FONT, fontSize=7, leading=8.5),
        "small_ar": ParagraphStyle("small_ar", parent=base["BodyText"], fontName=FONT, fontSize=7, leading=8.5, alignment=TA_RIGHT),
        "cover": ParagraphStyle("cover", parent=base["BodyText"], fontName=FONT, fontSize=9, leading=12),
        "cover_ar": ParagraphStyle("cover_ar", parent=base["BodyText"], fontName=FONT, fontSize=9, leading=12, alignment=TA_RIGHT),
    }


STYLES = make_styles()


def table_style(header_bg: colors.Color = colors.HexColor("#1f3f36")) -> TableStyle:
    return TableStyle(
        [
            ("FONTNAME", (0, 0), (-1, -1), FONT),
            ("FONTNAME", (0, 0), (-1, 0), BOLD),
            ("BACKGROUND", (0, 0), (-1, 0), header_bg),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#b9c7c2")),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 3),
            ("RIGHTPADDING", (0, 0), (-1, -1), 3),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f7faf9")]),
        ]
    )


def header_footer(canvas, doc, title: str) -> None:  # type: ignore[no-untyped-def]
    canvas.saveState()
    canvas.setFont(FONT, 7)
    canvas.setFillColor(colors.HexColor("#5a666b"))
    canvas.drawString(10 * mm, 7 * mm, title[:110])
    canvas.drawRightString(287 * mm, 7 * mm, f"Page {doc.page}")
    canvas.restoreState()


def build_pdf(source: Path) -> dict[str, Any]:
    data = json.loads(source.read_text(encoding="utf-8-sig"))
    category = data.get("category", {})
    units = data.get("units", [])
    failures = data.get("failures", []) + data.get("group_failures", [])
    clean_units = [(unit, part_rows(unit)) for unit in units]
    discovered_count = len(data.get("discovered_units", []))
    part_count = sum(len(rows) for _, rows in clean_units)
    diagram_count = sum(1 for unit, _ in clean_units if unit.get("diagram_image_url"))
    cached_diagrams = sum(1 for unit, _ in clean_units if unit.get("diagram_image_url") and image_cache_path(unit["diagram_image_url"]).exists())

    vehicle_title = " | ".join(
        clean_text(x)
        for x in [
            category.get("year"),
            category.get("market"),
            category.get("body_style"),
            category.get("engine"),
            category.get("grade_or_frame"),
        ]
        if clean_text(x)
    )
    filename = safe_name(f"{data.get('extract_id', source.stem)}_{category.get('market','')}_{category.get('body_style','')}_{category.get('engine','')}_{category.get('grade_or_frame','')}.pdf")
    out = OUT_DIR / filename
    out.parent.mkdir(parents=True, exist_ok=True)
    result = {
        "source": str(source),
        "pdf": str(out),
        "extract_id": data.get("extract_id"),
        "vehicle": vehicle_title,
        "units": len(units),
        "parts": part_count,
        "diagrams": diagram_count,
        "cached_diagrams": cached_diagrams,
        "failures": len(failures),
        "complete": bool(data.get("complete")) or (discovered_count > 0 and len(units) + len(failures) >= discovered_count),
    }
    required_mtime = max(SCRIPT_MTIME, source.stat().st_mtime)
    if out.exists() and out.stat().st_size > 0 and out.stat().st_mtime >= required_mtime:
        return result | {"status": "existing"}

    doc = SimpleDocTemplate(
        str(out),
        pagesize=landscape(A4),
        rightMargin=8 * mm,
        leftMargin=8 * mm,
        topMargin=9 * mm,
        bottomMargin=11 * mm,
    )
    story: list[Any] = []
    story.append(para("Nissan Patrol / Safari EPC Extract", STYLES["title"]))
    story.append(ar_para("استخراج كتالوج قطع نيسان باترول / سفاري", STYLES["title_ar"]))
    story.append(para(vehicle_title, STYLES["cover"]))
    story.append(ar_para(vehicle_title, STYLES["cover_ar"]))
    story.append(Spacer(1, 5 * mm))

    summary_rows = [
        [para("Field", STYLES["cell"]), ar_para("الحقل", STYLES["cell_ar"]), para("Value", STYLES["cell"]), ar_para("القيمة", STYLES["cell_ar"])],
    ]
    summary_pairs = [
        ("Extract ID", data.get("extract_id", "")),
        ("Vehicle", clean_text(data.get("source_row", {}).get("raw_text", ""))),
        ("Market", category.get("market", "")),
        ("Body Style", category.get("body_style", "")),
        ("Engine", category.get("engine", "")),
        ("Grade", category.get("grade_or_frame", "")),
        ("Production", f"{category.get('production_from','')} - {category.get('production_to','')}"),
        ("Catalog Plates", len(units)),
        ("Parts Rows", part_count),
        ("Diagram Images", f"{diagram_count} ({cached_diagrams} cached)"),
        ("Verification Required", len(failures)),
        ("Source", data.get("source_vehicle_url", "")),
    ]
    for label, value in summary_pairs:
        summary_rows.append([para(label, STYLES["cell"]), ar_para(LABEL_AR.get(label, label), STYLES["cell_ar"]), para(value, STYLES["cell"]), ar_para(value, STYLES["cell_ar"])])
    t = Table(summary_rows, colWidths=[35 * mm, 35 * mm, 165 * mm, 35 * mm], repeatRows=1)
    t.setStyle(table_style())
    story.append(t)
    story.append(PageBreak())

    for index, (unit, rows) in enumerate(clean_units, start=1):
        title = clean_text(unit.get("plate_title_en") or unit.get("plate_code") or unit.get("diagram_alt") or f"Plate {index}")
        plate_code = clean_text(unit.get("plate_code") or unit.get("uid") or index)
        story.append(
            KeepTogether(
                [
                    para(f"{index}. Original EPC Plate", STYLES["h2"]),
                    ar_para("لوحة EPC الأصلية", STYLES["h2_ar"]),
                    para(plate_code, STYLES["small"]),
                ]
            )
        )
        story.append(para(title, STYLES["small"]))
        story.append(ar_para(translate(title), STYLES["small_ar"]))
        meta = [
            [para("UID", STYLES["cell"]), para(clean_text(unit.get("uid")), STYLES["cell"]), para("CID", STYLES["cell"]), para(clean_text(unit.get("cid")), STYLES["cell"]), para("Group", STYLES["cell"]), para(clean_text(unit.get("group_text")), STYLES["cell"])],
            [para("URL", STYLES["cell"]), para(clean_text(unit.get("unit_url")), STYLES["cell"]), para("Diagram URL", STYLES["cell"]), para(clean_text(unit.get("diagram_image_url")), STYLES["cell"]), para("Arabic Title", STYLES["cell"]), ar_para(translate(title), STYLES["cell_ar"])],
        ]
        mt = Table(meta, colWidths=[15 * mm, 88 * mm, 18 * mm, 88 * mm, 23 * mm, 38 * mm])
        mt.setStyle(table_style(colors.HexColor("#3b5550")))
        story.append(mt)

        url = clean_text(unit.get("diagram_image_url"))
        cache = image_cache_path(url) if url else None
        if cache and cache.exists() and cache.stat().st_size > 0:
            try:
                img = Image(str(cache))
                img._restrictSize(260 * mm, 72 * mm)
                story.append(Spacer(1, 2 * mm))
                story.append(img)
            except Exception:
                story.append(ar_para(LABEL_AR["Diagram image was not available in the local cache."], STYLES["small_ar"]))
        elif url:
            story.append(ar_para(LABEL_AR["Diagram image was not available in the local cache."], STYLES["small_ar"]))

        if rows:
            header = [
                para("Ref", STYLES["cell"]),
                para("Part Number", STYLES["cell"]),
                para("English Name", STYLES["cell"]),
                ar_para("الاسم العربي", STYLES["cell_ar"]),
                para("Qty", STYLES["cell"]),
                para("Applicable Models", STYLES["cell"]),
                para("Specification / Range", STYLES["cell"]),
            ]
            table_data = [header]
            for row in rows:
                spec = " | ".join(x for x in [row.get("specification", ""), row.get("range", "")] if x)
                table_data.append(
                    [
                        para(row.get("reference", ""), STYLES["cell"]),
                        para(row.get("part_number", ""), STYLES["cell"]),
                        para(row.get("name", ""), STYLES["cell"]),
                        ar_para(translate(row.get("name", "")), STYLES["cell_ar"]),
                        para(row.get("quantity", ""), STYLES["cell"]),
                        para(row.get("applicable", ""), STYLES["cell"]),
                        para(spec, STYLES["cell"]),
                    ]
                )
            pt = Table(table_data, colWidths=[19 * mm, 31 * mm, 50 * mm, 50 * mm, 13 * mm, 48 * mm, 59 * mm], repeatRows=1)
            pt.setStyle(table_style())
            story.append(Spacer(1, 2 * mm))
            story.append(pt)
        else:
            story.append(ar_para(LABEL_AR["No verified part rows were available for this plate."], STYLES["small_ar"]))
            story.append(para("Verification Required", STYLES["small"]))
        story.append(PageBreak())

    if failures:
        story.append(para("Missing EPC Plates Report", STYLES["title"]))
        story.append(ar_para(LABEL_AR["Missing EPC Plates Report"], STYLES["title_ar"]))
        rows = [[para("Group", STYLES["cell"]), para("Title", STYLES["cell"]), para("UID", STYLES["cell"]), para("Reason", STYLES["cell"])]]
        for failure in failures:
            unit = failure.get("unit", failure)
            rows.append(
                [
                    para(clean_text(unit.get("group_text", "")), STYLES["cell"]),
                    para(clean_text(unit.get("title", unit.get("plate_title_en", ""))), STYLES["cell"]),
                    para(clean_text(unit.get("uid", "")), STYLES["cell"]),
                    para("Verification Required", STYLES["cell"]),
                ]
            )
        ft = Table(rows, colWidths=[45 * mm, 115 * mm, 30 * mm, 80 * mm], repeatRows=1)
        ft.setStyle(table_style(colors.HexColor("#805f12")))
        story.append(ft)

    doc.build(story, onFirstPage=lambda c, d: header_footer(c, d, vehicle_title), onLaterPages=lambda c, d: header_footer(c, d, vehicle_title))
    return result | {"status": "built"}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    sources = sorted(SRC_DIR.glob("*.progressive.json"))
    results = []
    for source in sources:
        results.append(build_pdf(source))
        print(f"{results[-1].get('status', 'built')} {Path(results[-1]['pdf']).name}")
    summary = {
        "source_dir": str(SRC_DIR),
        "output_dir": str(OUT_DIR),
        "files": len(results),
        "complete_files": sum(1 for r in results if r["complete"]),
        "in_progress_files": sum(1 for r in results if not r["complete"]),
        "units": sum(int(r["units"]) for r in results),
        "parts": sum(int(r["parts"]) for r in results),
        "diagrams": sum(int(r["diagrams"]) for r in results),
        "cached_diagrams": sum(int(r["cached_diagrams"]) for r in results),
        "failures": sum(int(r["failures"]) for r in results),
        "results": results,
    }
    report = REPORT_DIR / "patrol_iab_pdf_build_summary.json"
    report.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in summary.items() if k != "results"} | {"report": str(report)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
