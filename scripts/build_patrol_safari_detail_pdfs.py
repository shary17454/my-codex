from __future__ import annotations

import hashlib
import json
import os
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
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "sources" / "partsouq" / "full_patrol_safari"
OUT_DIR = ROOT / "output" / "pdf" / "patrol_safari_detailed"
CACHE = ROOT / "sources" / "partsouq" / "image_cache"
AR_RE = re.compile(r"[\u0600-\u06ff]")


WORDS = {
    "ENGINE": "محرك",
    "ASSY": "مجموعة",
    "ASSEMBLY": "مجموعة",
    "BARE": "مجرد",
    "SHORT": "قصير",
    "GASKET": "وجه",
    "KIT": "طقم",
    "CYLINDER": "أسطوانة",
    "BLOCK": "بلوك",
    "OIL": "زيت",
    "PAN": "كرتير",
    "PUMP": "طرمبة",
    "FUEL": "وقود",
    "TANK": "خزان",
    "PIPE": "ماسورة",
    "HOSE": "لي",
    "TUBE": "ماسورة",
    "MUFFLER": "شكمان",
    "EXHAUST": "عادم",
    "WATER": "ماء",
    "COOLING": "تبريد",
    "RADIATOR": "رديتر",
    "FAN": "مروحة",
    "BODY": "هيكل",
    "ELECTRICAL": "كهرباء",
    "WIRING": "ضفيرة",
    "HARNESS": "ضفيرة",
    "LAMP": "لمبة",
    "SWITCH": "مفتاح",
    "DOOR": "باب",
    "ROOF": "سقف",
    "SEAT": "مرتبة",
    "BELT": "حزام",
    "BRAKE": "فرامل",
    "STEERING": "دركسون",
    "SUSPENSION": "تعليق",
    "AXLE": "محور",
    "TRANSMISSION": "قير",
    "TRANSFER": "دبل",
    "CASE": "علبة",
    "GEAR": "ترس",
    "SHAFT": "عمود",
    "CLUTCH": "كلتش",
    "COVER": "غطاء",
    "BRACKET": "حامل",
    "BOLT": "مسمار",
    "NUT": "صامولة",
    "SEAL": "صوفة",
    "FRONT": "أمامي",
    "REAR": "خلفي",
    "UPPER": "علوي",
    "LOWER": "سفلي",
    "LEFT": "يسار",
    "RIGHT": "يمين",
}


PHRASES = {
    "BARE & SHORT ENGINE": "المحرك المجرد والمحرك القصير",
    "ENGINE GASKET KIT": "طقم وجيهات المحرك",
    "CYLINDER BLOCK & OIL PAN": "بلوك المحرك والكرتير",
    "BODY ELECTRICAL": "كهرباء الهيكل",
    "FRONT AXLE": "المحور الأمامي",
    "REAR AXLE": "المحور الخلفي",
    "TRANSFER CASE": "علبة الدبل",
    "FUEL TANK": "خزان الوقود",
    "EXHAUST TUBE & MUFFLER": "ماسورة العادم والشكمان",
}


def register_fonts() -> tuple[str, str]:
    candidates = [
        (Path("C:/Windows/Fonts/arial.ttf"), Path("C:/Windows/Fonts/arialbd.ttf")),
        (Path("C:/Windows/Fonts/tahoma.ttf"), Path("C:/Windows/Fonts/tahomabd.ttf")),
    ]
    for regular, bold in candidates:
        if regular.exists():
            pdfmetrics.registerFont(TTFont("CatalogFont", str(regular)))
            pdfmetrics.registerFont(TTFont("CatalogFont-Bold", str(bold if bold.exists() else regular)))
            return "CatalogFont", "CatalogFont-Bold"
    return "Helvetica", "Helvetica-Bold"


FONT, BOLD = register_fonts()


def rtl(value: object) -> str:
    text = "" if value is None else str(value)
    if not AR_RE.search(text):
        return text
    return get_display(arabic_reshaper.reshape(text))


def esc(value: object) -> str:
    text = "" if value is None else str(value)
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\n", "<br/>")


def paragraph(value: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(value), style)


def paragraph_ar(value: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(rtl(value)), style)


def bilingual(en: str, ar: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(f"{esc(en)}<br/>{esc(rtl(ar))}", style)


def translate_name(value: object) -> str:
    text = "" if value is None else str(value).strip()
    if not text:
        return "يتطلب التحقق"
    key = re.sub(r"\s+", " ", text.upper()).strip()
    if key in PHRASES:
        return PHRASES[key]
    parts = re.split(r"([,;/()\-\s&]+)", text)
    changed = False
    out: list[str] = []
    for part in parts:
        word = re.sub(r"[^A-Za-z0-9]", "", part).upper()
        if word in WORDS:
            out.append(WORDS[word])
            changed = True
        else:
            out.append(part)
    return re.sub(r"\s+", " ", "".join(out)).strip() if changed else "يتطلب التحقق"


def short(value: object, limit: int) -> str:
    text = "" if value is None else str(value)
    return text if len(text) <= limit else text[: limit - 1] + "..."


def cache_image(url: str) -> Path | None:
    if not url:
        return None
    CACHE.mkdir(parents=True, exist_ok=True)
    ext = Path(url.split("?", 1)[0]).suffix.lower() or ".gif"
    path = CACHE / (hashlib.sha1(url.encode("utf-8")).hexdigest() + ext)
    if path.exists() and path.stat().st_size > 0:
        return path
    if os.environ.get("PATROL_PDF_NO_DOWNLOAD") == "1":
        return None
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=25) as response:
            path.write_bytes(response.read())
        return path if path.exists() and path.stat().st_size > 0 else None
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


def start_year(data: dict) -> str:
    row = data.get("source_row") or {}
    text = " ".join(str(x) for x in row.get("cells", []))
    match = re.search(r"\b(19|20)\d{2}\b", text)
    return match.group(0) if match else "9999"


def output_name(data: dict, source: Path) -> str:
    row = data.get("source_row") or {}
    cells = row.get("cells") or []
    year = start_year(data)
    bits = [year, data.get("detected_generation", ""), data.get("market", ""), *cells[:4]]
    name = "_".join(str(x) for x in bits if x)
    name = re.sub(r"[^A-Za-z0-9._-]+", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")
    return f"{name[:150] or source.stem}.pdf"


def build_pdf(source: Path) -> dict[str, object]:
    data = json.loads(source.read_text(encoding="utf-8"))
    out = OUT_DIR / output_name(data, source)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    doc = SimpleDocTemplate(
        str(out),
        pagesize=landscape(A4),
        rightMargin=8 * mm,
        leftMargin=8 * mm,
        topMargin=8 * mm,
        bottomMargin=8 * mm,
    )
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(name="Cover", fontName=BOLD, fontSize=21, leading=26, alignment=TA_CENTER))
    styles.add(ParagraphStyle(name="H", fontName=BOLD, fontSize=12, leading=15, spaceAfter=4))
    styles.add(ParagraphStyle(name="Small", fontName=FONT, fontSize=7.2, leading=8.4))
    styles.add(ParagraphStyle(name="SmallR", fontName=FONT, fontSize=7.2, leading=8.4, alignment=TA_RIGHT))
    styles.add(ParagraphStyle(name="Tiny", fontName=FONT, fontSize=5.4, leading=6.2))
    styles.add(ParagraphStyle(name="TinyR", fontName=FONT, fontSize=5.4, leading=6.2, alignment=TA_RIGHT))
    styles.add(ParagraphStyle(name="Warn", fontName=BOLD, fontSize=8, leading=10, textColor=colors.HexColor("#8a5a00")))

    units = data.get("units", [])
    part_rows = sum(len(u.get("part_rows", [])) for u in units)
    row = data.get("source_row") or {}
    title = " / ".join(str(x) for x in row.get("cells", [])[:6] if x)

    story = [
        Spacer(1, 20 * mm),
        paragraph("Nissan Patrol / Safari Detailed EPC Extract", styles["Cover"]),
        paragraph_ar("استخراج تفصيلي من كتالوج قطع نيسان باترول / سفاري", styles["Cover"]),
        Spacer(1, 5 * mm),
        paragraph(title, styles["Cover"]),
        Spacer(1, 8 * mm),
    ]

    summary_rows = [
        ("Market", data.get("market", ""), "السوق"),
        ("Generation", data.get("detected_generation", ""), "الجيل"),
        ("Model Year From", start_year(data), "بداية سنة الموديل"),
        ("Catalog Plates", len(units), "لوحات الكتالوج"),
        ("Part Rows", part_rows, "صفوف القطع"),
        ("Diagrams", sum(1 for u in units if u.get("diagram_image_url")), "المخططات"),
        ("Verification Required", len([u for u in units if not u.get("diagram_image_url") or not u.get("part_rows")]), "يتطلب التحقق"),
        ("Source URL", data.get("source_vehicle_url", ""), "رابط المصدر"),
    ]
    summary = Table(
        [[paragraph(a, styles["Small"]), paragraph(b, styles["Small"]), paragraph_ar(c, styles["SmallR"])] for a, b, c in summary_rows],
        colWidths=[42 * mm, 145 * mm, 60 * mm],
    )
    summary.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#b8c7c1")),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f3f36")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ]
        )
    )
    story.append(summary)
    story.append(PageBreak())

    headers = [
        ("Ref", "الإشارة"),
        ("Part Number", "رقم القطعة"),
        ("English Name", "الاسم الإنجليزي"),
        ("Arabic Name", "الاسم العربي"),
        ("Qty", "الكمية"),
        ("Applicable", "التطبيق"),
        ("Range / Notes", "النطاق / ملاحظات"),
    ]

    for idx, unit in enumerate(units, start=1):
        story.append(paragraph(f"{idx}. {unit.get('plate_code', '')} - {unit.get('plate_title_en', '')}", styles["H"]))
        story.append(paragraph_ar(translate_name(unit.get("plate_title_en", "")), styles["SmallR"]))
        story.append(paragraph(short(unit.get("unit_url", ""), 260), styles["Tiny"]))

        img_path = cache_image(unit.get("diagram_image_url", ""))
        img = fit_image(img_path, 145 * mm, 78 * mm) if img_path else None
        if img:
            story.append(img)
            story.append(paragraph(short(unit.get("diagram_image_url", ""), 260), styles["Tiny"]))
        else:
            story.append(bilingual("Diagram unavailable - Verification Required", "المخطط غير متاح - يتطلب التحقق", styles["Warn"]))

        rows = [[bilingual(en, ar, styles["Tiny"]) for en, ar in headers]]
        for part in unit.get("part_rows", []):
            name = part.get("part_name_en", "")
            rows.append(
                [
                    paragraph(part.get("reference_code", ""), styles["Tiny"]),
                    paragraph(part.get("part_number", ""), styles["Tiny"]),
                    paragraph(short(name, 70), styles["Tiny"]),
                    paragraph_ar(short(translate_name(name), 70), styles["TinyR"]),
                    paragraph(part.get("quantity", ""), styles["Tiny"]),
                    paragraph(short(part.get("applicable_models", ""), 80), styles["Tiny"]),
                    paragraph(short(part.get("specifications", ""), 90), styles["Tiny"]),
                ]
            )
        if len(rows) == 1:
            rows.append([bilingual("VERIFICATION REQUIRED", "يتطلب التحقق", styles["Tiny"]), "", "", "", "", "", ""])

        table = Table(rows, colWidths=[18 * mm, 27 * mm, 50 * mm, 45 * mm, 14 * mm, 56 * mm, 55 * mm], repeatRows=1)
        table.setStyle(
            TableStyle(
                [
                    ("GRID", (0, 0), (-1, -1), 0.2, colors.HexColor("#c7d1cc")),
                    ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f3f36")),
                    ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ]
            )
        )
        story.append(table)
        story.append(PageBreak())

    doc.build(story)
    return {
        "source": str(source),
        "pdf": str(out),
        "year": start_year(data),
        "market": data.get("market", ""),
        "generation": data.get("detected_generation", ""),
        "plates": len(units),
        "part_rows": part_rows,
    }


def main() -> None:
    outputs = []
    for source in sorted(SRC_DIR.glob("*.json")):
        outputs.append(build_pdf(source))
    outputs.sort(key=lambda item: (item["year"], item["generation"], item["market"], item["pdf"]))
    manifest = OUT_DIR / "patrol_safari_detailed_pdf_manifest.json"
    manifest.write_text(json.dumps({"outputs": outputs}, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"manifest": str(manifest), "outputs": outputs}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
