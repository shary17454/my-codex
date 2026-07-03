from __future__ import annotations

import hashlib
import json
import re
import urllib.request
from pathlib import Path

import arabic_reshaper
from bidi.algorithm import get_display
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "sources" / "partsouq" / "full_y60" / "WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.json"
OUT = ROOT / "output" / "pdf" / "full_y60" / "WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.reportlab.pdf"
CACHE = ROOT / "sources" / "partsouq" / "image_cache"

ARABIC_RE = re.compile(r"[\u0600-\u06ff]")

PART_GLOSSARY = {
    "ABSORBER": "مساعد",
    "ACCELERATOR": "دعسة البنزين",
    "AIR": "هواء",
    "ALTERNATOR": "دينمو",
    "ASSY": "مجموعة",
    "ASSEMBLY": "مجموعة",
    "AUTOMATIC": "أوتوماتيك",
    "AXLE": "دفرنس",
    "BACK": "خلفي",
    "BAR": "عمود",
    "BEARING": "رمان",
    "BELT": "سير",
    "BODY": "بودي",
    "BOLT": "مسمار",
    "BRACKET": "حامل",
    "BRAKE": "فرامل",
    "BUSH": "جلدة",
    "BUSHING": "جلدة",
    "CABLE": "سلك",
    "CAMSHAFT": "عمود كامات",
    "CASE": "علبة",
    "CHAIN": "جنزير",
    "CLAMP": "مشبك",
    "CLUTCH": "كلتش",
    "COMPRESSOR": "كمبروسر",
    "CONDENSER": "رديتر مكيف",
    "CONTROL": "تحكم",
    "COOLER": "مبرد",
    "COVER": "غطاء",
    "CRANKCASE": "علبة المرفق",
    "CRANKSHAFT": "عمود كرنك",
    "CYLINDER": "أسطوانة",
    "DIFFERENTIAL": "دفرنس",
    "DOOR": "باب",
    "ENGINE": "محرك",
    "EVAPORATOR": "ثلاجة مكيف",
    "EXHAUST": "عادم",
    "FAN": "مروحة",
    "FILTER": "فلتر",
    "FITTING": "توصيلات",
    "FLYWHEEL": "حدافة",
    "FRONT": "أمامي",
    "FUEL": "وقود",
    "GASKET": "وجه",
    "GEAR": "ترس",
    "GLASS": "زجاج",
    "GRILLE": "شبك",
    "HEAD": "رأس",
    "HOSE": "لي",
    "IGNITION": "إشعال",
    "INSULATOR": "عازل",
    "INTAKE": "سحب",
    "JOINT": "وصلة",
    "KIT": "طقم",
    "LAMP": "لمبة",
    "LINK": "ذراع",
    "LOCK": "قفل",
    "MANIFOLD": "مجمع",
    "MANUAL": "عادي",
    "MECHANISM": "آلية",
    "METER": "عداد",
    "MOTOR": "موتور",
    "MOUNT": "قاعدة",
    "MOUNTING": "قاعدة",
    "NUT": "صامولة",
    "OIL": "زيت",
    "PAD": "فحمات",
    "PAN": "كرتير",
    "PARTS": "قطع",
    "PIPE": "ماسورة",
    "PISTON": "بستم",
    "POLLUTION": "انبعاثات",
    "POWER": "باور",
    "PUMP": "طرمبة",
    "RADIATOR": "رديتر",
    "REAR": "خلفي",
    "REGULATOR": "منظم",
    "RING": "حلقة",
    "ROCKER": "تاكيه",
    "ROD": "عمود",
    "SEAL": "صوفة",
    "SEAT": "مرتبة",
    "SENSOR": "حساس",
    "SHAFT": "عمود",
    "SHOCK": "مساعد",
    "SPRING": "ياي",
    "STARTER": "سلف",
    "STEERING": "دركسون",
    "STOPPER": "مصد",
    "SWITCH": "مفتاح",
    "TANK": "خزان",
    "THERMOSTAT": "بلف حرارة",
    "TRANSFER": "دبل",
    "TRANSMISSION": "قير",
    "VALVE": "صمام",
    "VENTILATION": "تهوية",
    "WASHER": "وردة",
    "WINDOW": "نافذة",
    "WIRE": "سلك",
    "WIRING": "ضفيرة",
}

PHRASE_GLOSSARY = {
    "ACCELERATOR LINKAGE": "وصلات دعسة البنزين",
    "AIR CLEANER": "فلتر الهواء",
    "AIR POLLUTION CONTROL": "نظام التحكم في الانبعاثات",
    "ALTERNATOR FITTING": "تثبيت الدينمو",
    "AUTO TRANSMISSION CONTROL DEVICE": "جهاز التحكم بالقير الأوتوماتيك",
    "BACK DOOR LOCK & HANDLE": "قفل ومقبض الباب الخلفي",
    "BACK DOOR PANEL & FITTING": "لوح الباب الخلفي وتركيباته",
    "BATTERY & BATTERY MOUNTING": "البطارية وقاعدة البطارية",
    "BODY MOUNTING": "قواعد الهيكل",
    "CAMSHAFT & VALVE MECHANISM": "عمود الكامات وآلية الصمامات",
    "CARBURETOR REPAIR KIT": "طقم إصلاح الكربريتر",
    "CARBURETOR; ASSEMBLY": "مجموعة الكربريتر",
    "CLUTCH COVER,DISC & RELEASE PARTS": "غطاء ودسك الكلتش وقطع الفصل",
    "CLUTCH MASTER CYLINDER; WITH CLUTCH BOOSTER": "ماستر كلتش مع باكم كلتش",
    "CLUTCH MASTER CYLINDER; WITHOUT CLUTCH BOOSTER": "ماستر كلتش بدون باكم كلتش",
    "CLUTCH OPERATING CYLINDER": "سلندر تشغيل الكلتش",
    "CLUTCH PIPING": "مواسير الكلتش",
    "COMPRESSOR": "كمبروسر المكيف",
    "COMPRESSOR MOUNTING & FITTING": "قاعدة الكمبروسر وتركيباته",
    "CONDENSER,LIQUID TANK & PIPING": "رديتر المكيف وقارورة الفريون والمواسير",
    "CONTROL SWITCH & SYSTEM": "مفتاح التحكم والنظام",
    "COOLING UNIT; FRONT AIR CON": "وحدة تبريد المكيف الأمامي",
    "CRANKCASE VENTILATION": "تهوية علبة المرفق",
    "CYLINDER BLOCK & OIL PAN": "بلوك المحرك والكرتير",
    "CYLINDER HEAD & ROCKER COVER": "رأس المكينة وغطاء التاكيهات",
    "DIFF LOCK CONTROL": "تحكم قفل الدفرنس",
    "EGR PARTS": "قطع نظام EGR",
    "ELECTRICAL UNIT": "الوحدة الكهربائية",
    "ENGINE & TRANSMISSION MOUNTING; EUR": "قواعد المحرك والقير - أوروبا",
    "ENGINE & TRANSMISSION MOUNTING; GEN": "قواعد المحرك والقير - عام",
    "ENGINE ASSEMBLY": "مجموعة المحرك",
    "ENGINE ASSY": "مجموعة المحرك",
    "ENGINE CONTROL VACUUM PIPING": "مواسير فاكيوم التحكم بالمحرك",
    "ENGINE GASKET KIT": "طقم وجيهات المحرك",
    "EXHAUST TUBE & MUFFLER": "ماسورة العادم والشكمان",
    "FAN,COMPRESSOR & POWER STEERING BELT": "سير المروحة والكمبروسر وباور الدركسون",
    "FRONT COMBINATION LAMP": "شمعة أمامية مدمجة",
    "FRONT COVER,VACUUM PUMP & FITTING": "غطاء أمامي وطرمبة فاكيوم وتركيبات",
    "FRONT DOOR LOCK & HANDLE": "قفل ومقبض الباب الأمامي",
    "FRONT DOOR PANEL & FITTING": "لوح الباب الأمامي وتركيباته",
    "FRONT DOOR WINDOW & REGULATOR": "زجاج الباب الأمامي والماكينة",
    "FUEL PIPING; PIPING": "مواسير الوقود",
    "FUEL PUMP": "طرمبة الوقود",
    "FUEL STRAINER & FUEL HOSE": "مصفاة الوقود ولي الوقود",
    "FUEL TANK": "خزان الوقود",
    "HEADLAMP": "شمعة أمامية",
    "HEATER PIPING; FRONT": "مواسير الدفاية الأمامية",
    "IGNITION SYSTEM": "نظام الإشعال",
    "LUBRICATING SYSTEM": "نظام التزييت",
    "MANIFOLD; EXHAUST PARTS": "قطع مجمع العادم",
    "MANIFOLD; INTAKE PARTS": "قطع مجمع السحب",
    "MANUAL TRANSMISSION, TRANSAXLE & FITTING": "القير العادي وتركيباته",
    "OIL COOLER": "مبرد الزيت",
    "OIL PUMP": "طرمبة الزيت",
    "PISTON,CRANKSHAFT & FLYWHEEL": "البساتم وعمود الكرنك والحدافة",
    "RADIATOR,SHROUD & INVERTER COOLING; RADIATOR ASSY": "مجموعة الرديتر وغطاء المروحة والتبريد",
    "RADIATOR,SHROUD & INVERTER COOLING; RADIATOR FITTING PARTS": "قطع تثبيت الرديتر وغطاء المروحة",
    "REAR BUMPER": "الصدام الخلفي",
    "REAR DOOR LOCK & HANDLE": "قفل ومقبض الباب الخلفي",
    "REAR DOOR PANEL & FITTING": "لوح الباب الخلفي وتركيباته",
    "REAR WINDOW": "الزجاج الخلفي",
    "RELAY; PART 1": "الريليهات - الجزء الأول",
    "RELAY; PART 2": "الريليهات - الجزء الثاني",
    "ROOM LAMP; MAP LAMP": "إنارة داخلية - لمبة الخريطة",
    "ROOM LAMP; ROOM LAMP": "إنارة داخلية - لمبة الصالون",
    "STARTER MOTOR; HITACHI": "سلف HITACHI",
    "SWITCH": "مفاتيح",
    "TRANSFER ASSEMBLY & FITTING": "مجموعة الدبل وتركيباتها",
    "TRANSFER CASE": "علبة الدبل",
    "TRANSFER GEAR": "تروس الدبل",
    "TRANSFER SHIFT LEVER,FORK & CONTROL": "عصا تعشيق الدبل والشوكة والتحكم",
    "TRANSMISSION CASE & CLUTCH RELEASE": "علبة القير وفصل الكلتش",
    "TRANSMISSION GEAR; MAIN GEAR": "تروس القير - الترس الرئيسي",
    "TRANSMISSION SHIFT CONTROL": "تحكم تعشيق القير",
    "WATER PUMP, COOLING FAN & THERMOSTAT": "طرمبة الماء ومروحة التبريد وبلف الحرارة",
    "WINDSHIELD WASHER": "رشاشات الزجاج الأمامي",
    "WINDSHIELD WIPER": "مساحات الزجاج الأمامي",
    "WIRING (BODY); FITTING PARTS": "قطع تثبيت ضفيرة البودي",
    "WIRING (BODY); WIRING": "ضفيرة البودي",
}


def register_fonts() -> tuple[str, str]:
    candidates = [
        (Path("C:/Windows/Fonts/arial.ttf"), Path("C:/Windows/Fonts/arialbd.ttf")),
        (Path("C:/Windows/Fonts/tahoma.ttf"), Path("C:/Windows/Fonts/tahomabd.ttf")),
    ]
    for regular, bold in candidates:
        if regular.exists():
            pdfmetrics.registerFont(TTFont("CatalogFont", str(regular)))
            if bold.exists():
                pdfmetrics.registerFont(TTFont("CatalogFont-Bold", str(bold)))
            else:
                pdfmetrics.registerFont(TTFont("CatalogFont-Bold", str(regular)))
            return "CatalogFont", "CatalogFont-Bold"
    return "Helvetica", "Helvetica-Bold"


FONT, BOLD = register_fonts()


def has_arabic(value: object) -> bool:
    return bool(ARABIC_RE.search("" if value is None else str(value)))


def rtl(value: object) -> str:
    text = "" if value is None else str(value)
    if not has_arabic(text):
        return text
    return get_display(arabic_reshaper.reshape(text))


def esc(value: object) -> str:
    text = "" if value is None else str(value)
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("\n", "<br/>")
    )


def para(text: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(text), style)


def para_ar(text: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(rtl(text)), style)


def bilingual_header(english: str, arabic: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(f"{esc(english)}<br/>{esc(rtl(arabic))}", style)


def short(text: object, limit: int = 55) -> str:
    value = "" if text is None else str(text)
    return value if len(value) <= limit else value[: limit - 1] + "..."


def translate_part_name(name: object) -> str:
    text = "" if name is None else str(name).strip()
    if not text:
        return "يتطلب التحقق"

    normalized = re.sub(r"\s+", " ", text.upper()).strip()
    if normalized in PHRASE_GLOSSARY:
        return PHRASE_GLOSSARY[normalized]

    pieces = re.split(r"([,;/()\-\s]+)", text)
    translated: list[str] = []
    changed = False
    for piece in pieces:
        key = re.sub(r"[^A-Za-z0-9]", "", piece).upper()
        if key in PART_GLOSSARY:
            translated.append(PART_GLOSSARY[key])
            changed = True
        else:
            translated.append(piece)

    result = re.sub(r"\s+", " ", "".join(translated)).strip()
    return result if changed else "يتطلب التحقق"


def cache_image(url: str) -> Path | None:
    if not url:
        return None
    CACHE.mkdir(parents=True, exist_ok=True)
    ext = Path(url.split("?", 1)[0]).suffix.lower() or ".img"
    path = CACHE / (hashlib.sha1(url.encode("utf-8")).hexdigest() + ext)
    if path.exists() and path.stat().st_size > 0:
        return path
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req, timeout=25) as response:
            path.write_bytes(response.read())
        return path if path.stat().st_size > 0 else None
    except Exception:
        return None


def fit_image(path: Path, max_width: float, max_height: float) -> Image | None:
    try:
        img = Image(str(path))
        ratio = min(max_width / img.imageWidth, max_height / img.imageHeight, 1)
        img.drawWidth = img.imageWidth * ratio
        img.drawHeight = img.imageHeight * ratio
        return img
    except Exception:
        return None


def main() -> None:
    data = json.loads(SRC.read_text(encoding="utf-8"))
    OUT.parent.mkdir(parents=True, exist_ok=True)

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=landscape(A4),
        rightMargin=8 * mm,
        leftMargin=8 * mm,
        topMargin=8 * mm,
        bottomMargin=8 * mm,
        title="WGY60348567 Nissan Patrol Safari Y60 Parts Catalog",
    )
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(name="CoverTitle", fontName=BOLD, fontSize=22, leading=28, alignment=TA_CENTER, spaceAfter=8))
    styles.add(ParagraphStyle(name="H2x", fontName=BOLD, fontSize=13, leading=16, spaceBefore=6, spaceAfter=5))
    styles.add(ParagraphStyle(name="Smallx", fontName=FONT, fontSize=7, leading=8))
    styles.add(ParagraphStyle(name="SmallRtl", fontName=FONT, fontSize=7, leading=8, alignment=TA_RIGHT))
    styles.add(ParagraphStyle(name="SmallHeader", fontName=BOLD, fontSize=7, leading=8, textColor=colors.white))
    styles.add(ParagraphStyle(name="SmallHeaderRtl", fontName=BOLD, fontSize=7, leading=8, alignment=TA_RIGHT, textColor=colors.white))
    styles.add(ParagraphStyle(name="Tinyx", fontName=FONT, fontSize=5.4, leading=6.2))
    styles.add(ParagraphStyle(name="TinyRtl", fontName=FONT, fontSize=5.4, leading=6.2, alignment=TA_RIGHT))
    styles.add(ParagraphStyle(name="TinyHeader", fontName=BOLD, fontSize=5.4, leading=6.2, textColor=colors.white))
    styles.add(ParagraphStyle(name="Warn", fontName=BOLD, fontSize=8, leading=10, textColor=colors.HexColor("#8a5a00")))

    c = data.get("category", {})
    story = [
        Spacer(1, 25 * mm),
        para("Nissan Patrol / Safari Y60 Parts Catalog", styles["CoverTitle"]),
        para_ar("كتالوج قطع نيسان باترول / سفاري Y60", styles["CoverTitle"]),
        para("VIN / Reference: WGY60348567", styles["CoverTitle"]),
        Spacer(1, 8 * mm),
    ]

    summary_rows = [
        ["Field", "Value", "الحقل", "القيمة"],
        ["Market", c.get("market", ""), "السوق", c.get("market", "")],
        ["Model", c.get("model_code", ""), "الموديل", c.get("model_code", "")],
        ["Body", c.get("body_style", ""), "الهيكل", c.get("body_style", "")],
        ["Engine", c.get("engine", ""), "المحرك", c.get("engine", "")],
        ["Grade", c.get("grade_or_frame", ""), "الفئة", c.get("grade_or_frame", "")],
        ["Color", c.get("options", ""), "اللون", c.get("options", "")],
        ["Production", c.get("production_from", ""), "الإنتاج", c.get("production_from", "")],
        ["Catalog Plates", str(len(data.get("units", []))), "لوحات الكتالوج", str(len(data.get("units", [])))],
        ["Part Rows", str(sum(len(u.get("part_rows", [])) for u in data.get("units", []))), "صفوف القطع", str(sum(len(u.get("part_rows", [])) for u in data.get("units", [])))],
        ["Failures", str(len(data.get("failures", []))), "تحتاج مراجعة", str(len(data.get("failures", [])))],
    ]
    table_rows = []
    for row_index, row in enumerate(summary_rows):
        left_style = styles["SmallHeader"] if row_index == 0 else styles["Smallx"]
        right_style = styles["SmallHeaderRtl"] if row_index == 0 else styles["SmallRtl"]
        table_rows.append([
            para(row[0], left_style),
            para(row[1], left_style),
            para_ar(row[2], right_style),
            para(row[3], left_style),
        ])
    summary_table = Table(table_rows, colWidths=[35 * mm, 95 * mm, 35 * mm, 95 * mm])
    summary_table.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#b8c7c1")),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f3f36")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), BOLD),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]))
    story.append(summary_table)
    story.append(PageBreak())

    if data.get("failures"):
        story.append(bilingual_header("Verification Required", "يتطلب التحقق", styles["H2x"]))
        for failure in data["failures"]:
            unit = failure.get("unit", {})
            story.append(para(f"{unit.get('title','')} - {failure.get('error','')}", styles["Warn"]))
        story.append(PageBreak())

    col_widths = [20 * mm, 28 * mm, 50 * mm, 45 * mm, 16 * mm, 56 * mm, 50 * mm]
    headers = [
        ("Reference", "رقم الإشارة"),
        ("Part Number", "رقم القطعة"),
        ("English Name", "الاسم الإنجليزي"),
        ("Arabic Name", "الاسم العربي"),
        ("Qty", "الكمية"),
        ("Applicable Models", "الموديلات المطابقة"),
        ("Specifications", "المواصفات"),
    ]

    for idx, unit in enumerate(data.get("units", []), start=1):
        title_en = unit.get("plate_title_en", "")
        title = f"{idx}. {unit.get('plate_code','')} - {title_en}"
        story.append(para(title, styles["H2x"]))
        story.append(para_ar(translate_part_name(title_en), styles["SmallRtl"]))
        story.append(para(f"Source: {unit.get('unit_url','')}", styles["Smallx"]))
        image_path = cache_image(unit.get("diagram_image_url", ""))
        image = fit_image(image_path, 145 * mm, 82 * mm) if image_path else None
        if image:
            story.append(image)
        else:
            story.append(bilingual_header(
                f"Diagram URL: {unit.get('diagram_image_url','VERIFICATION REQUIRED')}",
                "رابط المخطط: يتطلب التحقق",
                styles["Warn"],
            ))
        story.append(Spacer(1, 3 * mm))

        rows = [[bilingual_header(en, ar, styles["TinyHeader"]) for en, ar in headers]]
        for row in unit.get("part_rows", []):
            source_arabic = row.get("part_name_ar")
            arabic_name = source_arabic if source_arabic and has_arabic(source_arabic) else translate_part_name(row.get("part_name_en", ""))
            cells = [
                para(row.get("reference_code", ""), styles["Tinyx"]),
                para(row.get("part_number", ""), styles["Tinyx"]),
                para(short(row.get("part_name_en", ""), 70), styles["Tinyx"]),
                para_ar(short(arabic_name, 70), styles["TinyRtl"]),
                para(row.get("quantity", ""), styles["Tinyx"]),
                para(short(row.get("applicable_models", ""), 85), styles["Tinyx"]),
                para(short(row.get("specifications", ""), 85), styles["Tinyx"]),
            ]
            rows.append(cells)
        if len(rows) == 1:
            rows.append([
                bilingual_header("VERIFICATION REQUIRED", "يتطلب التحقق", styles["Tinyx"]),
                "",
                "",
                "",
                "",
                "",
                "",
            ])
        table = Table(rows, colWidths=col_widths, repeatRows=1)
        table.setStyle(TableStyle([
            ("GRID", (0, 0), (-1, -1), 0.2, colors.HexColor("#c7d1cc")),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f3f36")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), BOLD),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f7faf9")]),
        ]))
        story.append(table)
        story.append(PageBreak())

    doc.build(story)
    print(json.dumps({"pdf": str(OUT), "bytes": OUT.stat().st_size}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
