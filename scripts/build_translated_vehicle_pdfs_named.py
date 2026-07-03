from __future__ import annotations

import hashlib
import json
import re
import shutil
from pathlib import Path
from typing import Any

import arabic_reshaper
from bidi.algorithm import get_display
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT, TA_RIGHT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
IAB_SRC = ROOT / "sources" / "partsouq" / "full_patrol_all_iab"
Y61_IAB_SRC = ROOT / "sources" / "partsouq" / "full_y61_iab"
FULL_Y60_SRC = ROOT / "sources" / "partsouq" / "full_y60"
Y62_SRC = ROOT / "sources" / "partsouq" / "full_patrol_safari"
IMG_CACHE = ROOT / "sources" / "partsouq" / "image_cache"
OUT = ROOT / "deliverables" / "translated_vehicle_pdfs_named"
REPORT = ROOT / "deliverables" / "translated_vehicle_pdfs_named_manifest.json"

AR_RE = re.compile(r"[\u0600-\u06ff]")

LABEL_AR = {
    "Nissan Patrol / Safari EPC Parts Catalog": "كتالوج قطع نيسان باترول / سفاري EPC",
    "Vehicle": "السيارة",
    "Generation": "الجيل",
    "Market": "السوق",
    "Body Style": "نوع الهيكل",
    "Engine": "المحرك",
    "Grade": "الفئة",
    "Production": "فترة الإنتاج",
    "Source": "المصدر",
    "Extract ID": "معرف الاستخراج",
    "Catalog Plates": "لوحات الكتالوج",
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
    "Specification / Range": "المواصفة / النطاق",
    "Notes": "ملاحظات",
    "Diagram image was not available in the local cache.": "صورة المخطط غير متوفرة في الكاش المحلي.",
    "No verified part rows were available for this plate.": "لم تتوفر صفوف قطع مؤكدة لهذه اللوحة.",
    "No part numbers or diagrams were fabricated.": "لم يتم اختراع أي أرقام قطع أو مخططات.",
}

PHRASES = {
    "ENGINE ASSEMBLY": "مجموعة المحرك",
    "ENGINE ASSY": "مجموعة المحرك",
    "BARE & SHORT ENGINE": "المحرك المجرد والمحرك القصير",
    "ENGINE GASKET KIT": "طقم وجيهات المحرك",
    "CYLINDER BLOCK & OIL PAN": "بلوك المحرك والكرتير",
    "CAMSHAFT & VALVE MECHANISM": "عمود الكامات وآلية الصمامات",
    "PISTON,CRANKSHAFT & FLYWHEEL": "البساتم وعمود الكرنك والحدافة",
    "MANIFOLD": "مجمع السحب أو العادم",
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
    "FRONT AXLE": "المحور الأمامي",
    "REAR AXLE": "المحور الخلفي",
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
    "ROAD WHEEL & TIRE": "الجنوط والكفرات",
    "FRONT BUMPER": "الصدام الأمامي",
    "REAR BUMPER": "الصدام الخلفي",
    "BACK DOOR": "الباب الخلفي",
    "SIDE WINDOW": "زجاج جانبي",
}

WORDS = {
    "ABSORBER": "مساعد",
    "ACCELERATOR": "دعسة البنزين",
    "ACTUATOR": "مشغل",
    "ADJUSTER": "منظم",
    "AIR": "هواء",
    "ALTERNATOR": "دينمو",
    "ARM": "ذراع",
    "ASSY": "مجموعة",
    "ASSEMBLY": "مجموعة",
    "AXLE": "محور",
    "BACK": "خلفي",
    "BAR": "عمود",
    "BEARING": "رمان",
    "BELT": "حزام",
    "BODY": "بودي",
    "BOLT": "مسمار",
    "BOOSTER": "باكم",
    "BRACKET": "حامل",
    "BRAKE": "فرامل",
    "BUMPER": "صدام",
    "BUSH": "جلدة",
    "BUSHING": "جلدة",
    "CABLE": "سلك",
    "CAMSHAFT": "عمود كامات",
    "CAP": "غطاء",
    "CARBURETOR": "كربريتر",
    "CASE": "علبة",
    "CENTER": "وسطي",
    "CHASSIS": "شاص",
    "CLIP": "مشبك",
    "CLUTCH": "كلتش",
    "COIL": "كويل",
    "CONTROL": "تحكم",
    "COOLER": "مبرد",
    "COOLING": "تبريد",
    "COVER": "غطاء",
    "CRANKSHAFT": "عمود كرنك",
    "CYLINDER": "أسطوانة",
    "DIFFERENTIAL": "دفرنس",
    "DOOR": "باب",
    "DRIVE": "دفع",
    "DUCT": "مجرى",
    "ELECTRICAL": "كهرباء",
    "ENGINE": "محرك",
    "EXHAUST": "عادم",
    "FAN": "مروحة",
    "FILTER": "فلتر",
    "FLOOR": "أرضية",
    "FLYWHEEL": "حدافة",
    "FRAME": "هيكل",
    "FRONT": "أمامي",
    "FUEL": "وقود",
    "GASKET": "وجه",
    "GAUGE": "عداد",
    "GEAR": "ترس",
    "GLASS": "زجاج",
    "GRILLE": "شبك",
    "GUARD": "حماية",
    "HANDLE": "يد",
    "HARNESS": "ضفيرة",
    "HEAD": "رأس",
    "HEATER": "دفاية",
    "HOSE": "لي",
    "HOUSING": "بيت",
    "HUB": "صرة",
    "IGNITION": "إشعال",
    "INJECTOR": "بخاخ",
    "INSULATOR": "عازل",
    "JOINT": "وصلة",
    "KIT": "طقم",
    "LAMP": "لمبة",
    "LENS": "عدسة",
    "LEVER": "عصا",
    "LINK": "وصلة",
    "LOCK": "قفل",
    "LOWER": "سفلي",
    "MIRROR": "مراية",
    "MOTOR": "موتور",
    "MOUNTING": "قاعدة",
    "MUFFLER": "شكمان",
    "NUT": "صامولة",
    "OIL": "زيت",
    "OUTER": "خارجي",
    "PANEL": "لوحة",
    "PIPE": "ماسورة",
    "PISTON": "بستم",
    "PLATE": "صفيحة",
    "PROPELLER": "كردان",
    "PUMP": "طرمبة",
    "RADIATOR": "رديتر",
    "REAR": "خلفي",
    "REGULATOR": "منظم",
    "RELAY": "كتاوت",
    "RESERVOIR": "علبة",
    "ROD": "عمود",
    "ROOF": "سقف",
    "SEAL": "صوفة",
    "SEAT": "مقعد",
    "SENSOR": "حساس",
    "SHAFT": "عمود",
    "SHOCK": "مساعد",
    "SIDE": "جانبي",
    "SPRING": "ياي",
    "STARTER": "سلف",
    "STEERING": "دركسون",
    "STOPPER": "مصد",
    "STRIKER": "لسان قفل",
    "SUSPENSION": "تعليق",
    "SWITCH": "مفتاح",
    "TANK": "خزان",
    "THERMOSTAT": "ثرموستات",
    "TIRE": "كفر",
    "TRANSFER": "دبل",
    "TRANSMISSION": "قير",
    "TRIM": "تلبيس",
    "TUBE": "ماسورة",
    "UPPER": "علوي",
    "VALVE": "صمام",
    "WATER": "ماء",
    "WHEEL": "جنط",
    "WINDOW": "نافذة",
    "WIPER": "مساحة",
    "WIRING": "ضفيرة",
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


def clean(value: Any) -> str:
    return re.sub(r"\s+", " ", "" if value is None else str(value)).strip()


def rtl(value: Any) -> str:
    text = clean(value)
    if not AR_RE.search(text):
        return text
    return get_display(arabic_reshaper.reshape(text))


def xml(value: Any) -> str:
    return clean(value).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def p(value: Any, style: ParagraphStyle) -> Paragraph:
    return Paragraph(xml(value), style)


def ar(value: Any, style: ParagraphStyle) -> Paragraph:
    return Paragraph(xml(rtl(value)), style)


def bilingual(en: str, ar_text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(f"{xml(en)}<br/>{xml(rtl(ar_text))}", style)


def translate_name(value: Any) -> str:
    text = clean(value)
    if not text:
        return LABEL_AR["Verification Required"]
    upper = text.upper()
    for phrase, translation in sorted(PHRASES.items(), key=lambda item: len(item[0]), reverse=True):
        if phrase in upper:
            return translation
    parts = re.split(r"([,;/()&+\-\s]+)", text)
    translated: list[str] = []
    changed = False
    for part in parts:
        key = re.sub(r"[^A-Z0-9]", "", part.upper())
        if key in WORDS:
            translated.append(WORDS[key])
            changed = True
        else:
            translated.append(part)
    return re.sub(r"\s+", " ", "".join(translated)).strip() if changed else LABEL_AR["Verification Required"]


def safe_name(value: str) -> str:
    out = "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in value)
    while "__" in out:
        out = out.replace("__", "_")
    return out.strip("._")[:175] or "catalog"


def image_cache_path(url: str) -> Path:
    ext = Path(url.split("?", 1)[0]).suffix.lower() or ".gif"
    return IMG_CACHE / f"{hashlib.sha1(url.encode('utf-8')).hexdigest()}{ext}"


def styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle("title", parent=base["Title"], fontName=BOLD, fontSize=18, leading=22, alignment=TA_LEFT),
        "title_ar": ParagraphStyle("title_ar", parent=base["Title"], fontName=BOLD, fontSize=18, leading=22, alignment=TA_RIGHT),
        "h": ParagraphStyle("h", parent=base["Heading2"], fontName=BOLD, fontSize=11, leading=14, spaceBefore=4),
        "h_ar": ParagraphStyle("h_ar", parent=base["Heading2"], fontName=BOLD, fontSize=11, leading=14, alignment=TA_RIGHT),
        "cell": ParagraphStyle("cell", parent=base["BodyText"], fontName=FONT, fontSize=5.7, leading=6.7),
        "cell_ar": ParagraphStyle("cell_ar", parent=base["BodyText"], fontName=FONT, fontSize=5.7, leading=6.7, alignment=TA_RIGHT),
        "small": ParagraphStyle("small", parent=base["BodyText"], fontName=FONT, fontSize=7, leading=8.4),
        "small_ar": ParagraphStyle("small_ar", parent=base["BodyText"], fontName=FONT, fontSize=7, leading=8.4, alignment=TA_RIGHT),
    }


S = styles()


def table_style(header_bg: colors.Color = colors.HexColor("#1f3f36")) -> TableStyle:
    return TableStyle(
        [
            ("FONTNAME", (0, 0), (-1, -1), FONT),
            ("FONTNAME", (0, 0), (-1, 0), BOLD),
            ("BACKGROUND", (0, 0), (-1, 0), header_bg),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("GRID", (0, 0), (-1, -1), 0.2, colors.HexColor("#b9c7c2")),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 2),
            ("RIGHTPADDING", (0, 0), (-1, -1), 2),
            ("TOPPADDING", (0, 0), (-1, -1), 2),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f7faf9")]),
        ]
    )


def extract_rows(unit: dict[str, Any]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for table in unit.get("tables", []) or []:
        headers = [clean(h) for h in table.get("headers", [])]
        if not {"Number", "Name", "Code"}.issubset(set(headers)):
            continue
        idx = {header: pos for pos, header in enumerate(headers)}
        for raw in (table.get("rows", []) or [])[1:]:
            def cell(name: str) -> str:
                pos = idx.get(name)
                return clean(raw[pos]) if pos is not None and pos < len(raw) else ""

            if cell("Number").lower() in {"brand", "number"} or cell("Name").lower() == "name":
                continue
            if not cell("Number") and not cell("Name"):
                continue
            rows.append(
                {
                    "reference": cell("Code"),
                    "part_number": cell("Number"),
                    "name": cell("Name"),
                    "quantity": cell("Quantity"),
                    "applicable": cell("Applicable Models"),
                    "specification": cell("Specification"),
                    "range": cell("Range"),
                }
            )
    if rows:
        return rows
    for raw in unit.get("part_rows", []) or []:
        part_number = clean(raw.get("part_number"))
        name = clean(raw.get("part_name_en"))
        if part_number.lower() in {"brand", "number"} or name.lower() == "name":
            continue
        if not part_number and not name:
            continue
        rows.append(
            {
                "reference": clean(raw.get("reference_code")),
                "part_number": part_number,
                "name": name,
                "quantity": clean(raw.get("quantity")),
                "applicable": clean(raw.get("applicable_models")),
                "specification": clean(raw.get("specifications")),
                "range": clean(raw.get("range")),
            }
        )
    return rows


def category_from(data: dict[str, Any], source: Path) -> dict[str, str]:
    c = data.get("category") or {}
    row = data.get("source_row") or {}
    cells = row.get("cells") or []
    return {
        "extract_id": clean(data.get("extract_id") or c.get("extract_id") or source.stem),
        "generation": clean(data.get("detected_generation") or c.get("detected_generation") or c.get("model_code")),
        "year": clean(c.get("year") or c.get("year_filter") or ""),
        "market": clean(data.get("market") or c.get("market") or c.get("catalog_market") or ""),
        "body_style": clean(c.get("body_style") or (cells[1] if len(cells) > 1 else "")),
        "engine": clean(c.get("engine") or (cells[2] if len(cells) > 2 else "")),
        "grade": clean(c.get("grade_or_frame") or (cells[3] if len(cells) > 3 else "")),
        "production": clean(f"{c.get('production_from') or (cells[6] if len(cells) > 6 else '')} - {c.get('production_to') or (cells[7] if len(cells) > 7 else '')}"),
        "source": clean(data.get("source_vehicle_url") or c.get("vehicle_url") or ""),
    }


def fit_diagram(url: str) -> Image | None:
    if not url:
        return None
    cache = image_cache_path(url)
    if not cache.exists() or cache.stat().st_size <= 0:
        return None
    try:
        img = Image(str(cache))
        ratio = min((260 * mm) / img.imageWidth, (70 * mm) / img.imageHeight, 1)
        img.drawWidth = img.imageWidth * ratio
        img.drawHeight = img.imageHeight * ratio
        return img
    except Exception:
        return None


def build_vehicle_pdf(source: Path, out_name: str | None = None) -> dict[str, Any] | None:
    data = json.loads(source.read_text(encoding="utf-8-sig"))
    if not isinstance(data, dict):
        return None
    units = data.get("units") or []
    if not units:
        return None
    c = category_from(data, source)
    title = " | ".join(x for x in [c["year"], c["market"], c["body_style"], c["engine"], c["grade"]] if x)
    filename = out_name or safe_name("_".join(x for x in [c["generation"] or "Patrol", c["year"], c["extract_id"], c["market"], c["body_style"], c["engine"], c["grade"]] if x)) + ".pdf"
    out = OUT / filename
    if out.exists() and out.stat().st_size > 0:
        clean_units = [(unit, extract_rows(unit)) for unit in units]
        return {
            "source": str(source),
            "pdf": str(out),
            "plates": len(units),
            "parts": sum(len(rows) for _, rows in clean_units),
            "diagrams": sum(1 for unit, _ in clean_units if clean(unit.get("diagram_image_url"))),
            "verification_required": len((data.get("failures") or []) + (data.get("group_failures") or [])),
            "status": "existing",
        }
    doc = SimpleDocTemplate(str(out), pagesize=landscape(A4), rightMargin=8 * mm, leftMargin=8 * mm, topMargin=8 * mm, bottomMargin=9 * mm)
    clean_units = [(unit, extract_rows(unit)) for unit in units]
    failures = (data.get("failures") or []) + (data.get("group_failures") or [])
    story: list[Any] = [
        p("Nissan Patrol / Safari EPC Parts Catalog", S["title"]),
        ar(LABEL_AR["Nissan Patrol / Safari EPC Parts Catalog"], S["title_ar"]),
        p(title, S["small"]),
        ar(title, S["small_ar"]),
        Spacer(1, 4 * mm),
    ]
    summary_rows = [[bilingual("Field", "الحقل", S["cell"]), bilingual("Value", "القيمة", S["cell"])]]
    part_count = sum(len(rows) for _, rows in clean_units)
    diagram_count = sum(1 for u, _ in clean_units if clean(u.get("diagram_image_url")))
    for label, value in [
        ("Extract ID", c["extract_id"]),
        ("Generation", c["generation"]),
        ("Market", c["market"]),
        ("Body Style", c["body_style"]),
        ("Engine", c["engine"]),
        ("Grade", c["grade"]),
        ("Production", c["production"]),
        ("Catalog Plates", len(units)),
        ("Parts Rows", part_count),
        ("Diagram Images", diagram_count),
        ("Verification Required", len(failures)),
        ("Source", c["source"]),
    ]:
        summary_rows.append([bilingual(label, LABEL_AR.get(label, label), S["cell"]), p(value, S["cell"])])
    st = Table(summary_rows, colWidths=[55 * mm, 215 * mm], repeatRows=1)
    st.setStyle(table_style())
    story.append(st)
    story.append(ar(LABEL_AR["No part numbers or diagrams were fabricated."], S["small_ar"]))
    story.append(PageBreak())

    for idx, (unit, rows) in enumerate(clean_units, start=1):
        plate_title = clean(unit.get("plate_title_en") or unit.get("plate_code") or f"Plate {idx}")
        plate_code = clean(unit.get("plate_code") or unit.get("uid") or idx)
        story.append(p(f"{idx}. {plate_code} - {plate_title}", S["h"]))
        story.append(ar(translate_name(plate_title), S["h_ar"]))
        meta = Table(
            [
                [bilingual("Original EPC Plate", LABEL_AR["Original EPC Plate"], S["cell"]), p(plate_code, S["cell"]), bilingual("Arabic Title", LABEL_AR["Arabic Title"], S["cell"]), ar(translate_name(plate_title), S["cell_ar"])],
                [p("URL", S["cell"]), p(unit.get("unit_url", ""), S["cell"]), p("Diagram URL", S["cell"]), p(unit.get("diagram_image_url", ""), S["cell"])],
            ],
            colWidths=[35 * mm, 95 * mm, 35 * mm, 105 * mm],
        )
        meta.setStyle(table_style(colors.HexColor("#3b5550")))
        story.append(meta)
        img = fit_diagram(clean(unit.get("diagram_image_url")))
        story.append(Spacer(1, 2 * mm))
        if img:
            story.append(img)
        else:
            story.append(bilingual("Diagram image was not available in the local cache.", LABEL_AR["Diagram image was not available in the local cache."], S["small"]))
        story.append(Spacer(1, 2 * mm))
        if rows:
            table_data = [[
                bilingual("Ref", LABEL_AR["Ref"], S["cell"]),
                bilingual("Part Number", LABEL_AR["Part Number"], S["cell"]),
                bilingual("English Name", LABEL_AR["English Name"], S["cell"]),
                bilingual("Arabic Name", LABEL_AR["Arabic Name"], S["cell"]),
                bilingual("Qty", LABEL_AR["Qty"], S["cell"]),
                bilingual("Applicable Models", LABEL_AR["Applicable Models"], S["cell"]),
                bilingual("Specification / Range", LABEL_AR["Specification / Range"], S["cell"]),
            ]]
            for row in rows:
                spec = " | ".join(x for x in [row.get("specification", ""), row.get("range", "")] if x)
                table_data.append(
                    [
                        p(row.get("reference", ""), S["cell"]),
                        p(row.get("part_number", ""), S["cell"]),
                        p(row.get("name", ""), S["cell"]),
                        ar(translate_name(row.get("name", "")), S["cell_ar"]),
                        p(row.get("quantity", ""), S["cell"]),
                        p(row.get("applicable", ""), S["cell"]),
                        p(spec, S["cell"]),
                    ]
                )
            pt = Table(table_data, colWidths=[17 * mm, 28 * mm, 49 * mm, 49 * mm, 12 * mm, 55 * mm, 60 * mm], repeatRows=1)
            pt.setStyle(table_style())
            story.append(pt)
        else:
            story.append(bilingual("No verified part rows were available for this plate.", LABEL_AR["No verified part rows were available for this plate."], S["small"]))
            story.append(p("VERIFICATION REQUIRED", S["small"]))
        story.append(PageBreak())
    doc.build(story)
    return {"source": str(source), "pdf": str(out), "plates": len(units), "parts": part_count, "diagrams": diagram_count, "verification_required": len(failures)}


PRE_Y60 = [
    ("4w60_4w_series.pdf", "Nissan Patrol 4W60 / 4W Series", "نيسان باترول سلسلة 4W60 / 4W", "1951-1960", "4W60, 4W61, 4W65, 4W66"),
    ("60_g60_series.pdf", "Nissan Patrol 60 / G60 Series", "نيسان باترول سلسلة 60 / G60", "1960-1980", "60, G60, L60, H60, KG60"),
    ("160_mq_mk_series.pdf", "Nissan Patrol 160 Series / MQ / MK", "نيسان باترول سلسلة 160 / MQ / MK", "1980-1987 before Y60; continued later in some markets", "160, K160, V160, W160"),
    ("260_series.pdf", "Nissan Patrol 260 Series", "نيسان باترول سلسلة 260", "1986-1990s depending on market", "260 and market variants"),
]


def build_pre_y60_pdf(filename: str, title: str, ar_title: str, years: str, codes: str) -> dict[str, Any]:
    out = OUT / filename
    if out.exists() and out.stat().st_size > 0:
        return {"source": "pre_y60_verified_placeholder", "pdf": str(out), "plates": 0, "parts": 0, "diagrams": 0, "verification_required": 1, "status": "existing"}
    doc = SimpleDocTemplate(str(out), pagesize=A4, rightMargin=12 * mm, leftMargin=12 * mm, topMargin=12 * mm, bottomMargin=12 * mm)
    rows = [
        ("English Name", "الاسم الإنجليزي", title),
        ("Arabic Name", "الاسم العربي", ar_title),
        ("Approximate Years", "السنوات التقريبية", years),
        ("Known Codes", "الرموز المعروفة", codes),
        ("Original EPC status", "حالة EPC الأصلي", "Verification Required"),
        ("Policy", "السياسة", "No part numbers or diagrams were fabricated."),
    ]
    story = [p(title, S["title"]), ar(ar_title, S["title_ar"]), Spacer(1, 5 * mm)]
    table = Table([[bilingual(en, ar_label, S["cell"]), p(value, S["cell"])] for en, ar_label, value in rows], colWidths=[55 * mm, 120 * mm])
    table.setStyle(table_style())
    story.append(table)
    story.append(Spacer(1, 5 * mm))
    story.append(ar("هذا الملف يحافظ على المتوفر فقط. لم يتم اختراع أرقام قطع أو مخططات، وأي نقص موثق بعلامة يتطلب التحقق.", S["small_ar"]))
    doc.build(story)
    return {"source": "pre_y60_verified_placeholder", "pdf": str(out), "plates": 0, "parts": 0, "diagrams": 0, "verification_required": 1}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    results: list[dict[str, Any]] = []
    seen: set[str] = set()
    for source in sorted(IAB_SRC.glob("*.progressive.json")):
        result = build_vehicle_pdf(source)
        if result:
            results.append(result)
            seen.add(Path(result["pdf"]).name)
    for source in sorted(Y61_IAB_SRC.glob("*.progressive.json")):
        result = build_vehicle_pdf(source)
        if result:
            results.append(result)
            seen.add(Path(result["pdf"]).name)
    for source in sorted(FULL_Y60_SRC.glob("*.json")):
        result = build_vehicle_pdf(source)
        if result and Path(result["pdf"]).name not in seen:
            results.append(result)
            seen.add(Path(result["pdf"]).name)
    for source in sorted(Y62_SRC.glob("*.json")):
        result = build_vehicle_pdf(source)
        if result:
            results.append(result)
    for item in PRE_Y60:
        results.append(build_pre_y60_pdf(*item))
    REPORT.write_text(json.dumps({"output_dir": str(OUT), "files": len(results), "results": results}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"output_dir": str(OUT), "files": len(results), "report": str(REPORT)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
