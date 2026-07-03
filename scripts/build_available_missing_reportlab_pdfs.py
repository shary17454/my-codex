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
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / "sources" / "partsouq" / "full_y60"
OUT_DIR = ROOT / "output" / "pdf" / "available_missing_y60"
CACHE = ROOT / "sources" / "partsouq" / "image_cache"

TARGET_IDS = {"b3d7b114a89a", "d074a6710cf6"}
AR_RE = re.compile(r"[\u0600-\u06ff]")

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
    "TRANSFER CASE": "علبة الدبل",
    "TRANSMISSION CASE & CLUTCH RELEASE": "علبة القير وفصل الكلتش",
}

WORDS = {
    "ENGINE": "محرك", "ASSY": "مجموعة", "ASSEMBLY": "مجموعة", "GASKET": "وجه",
    "KIT": "طقم", "CYLINDER": "أسطوانة", "BLOCK": "بلوك", "OIL": "زيت",
    "PAN": "كرتير", "CAMSHAFT": "عمود كامات", "VALVE": "صمام", "MECHANISM": "آلية",
    "PISTON": "بستم", "CRANKSHAFT": "عمود كرنك", "FLYWHEEL": "حدافة", "FUEL": "وقود",
    "PUMP": "طرمبة", "TANK": "خزان", "EXHAUST": "عادم", "TUBE": "ماسورة",
    "MUFFLER": "شكمان", "TRANSFER": "دبل", "CASE": "علبة", "TRANSMISSION": "قير",
    "CLUTCH": "كلتش", "RELEASE": "فصل", "FRONT": "أمامي", "REAR": "خلفي",
    "BODY": "بودي", "DOOR": "باب", "LAMP": "لمبة", "SWITCH": "مفتاح",
    "WIRING": "ضفيرة", "SEAT": "مرتبة", "BELT": "حزام", "BRAKE": "فرامل",
    "STEERING": "دركسون", "PIPE": "ماسورة", "HOSE": "لي", "COVER": "غطاء",
    "BRACKET": "حامل", "BOLT": "مسمار", "NUT": "صامولة", "SEAL": "صوفة",
}


def register_fonts() -> tuple[str, str]:
    for regular, bold in [
        (Path("C:/Windows/Fonts/arial.ttf"), Path("C:/Windows/Fonts/arialbd.ttf")),
        (Path("C:/Windows/Fonts/tahoma.ttf"), Path("C:/Windows/Fonts/tahomabd.ttf")),
    ]:
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


def para(value: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(value), style)


def para_ar(value: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(rtl(value)), style)


def bilingual(en: str, ar: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(f"{esc(en)}<br/>{esc(rtl(ar))}", style)


def translate_name(name: object) -> str:
    text = "" if name is None else str(name).strip()
    if not text:
        return "يتطلب التحقق"
    key = re.sub(r"\s+", " ", text.upper()).strip()
    if key in PHRASES:
        return PHRASES[key]
    parts = re.split(r"([,;/()\-\s&]+)", text)
    changed = False
    out = []
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
    ext = Path(url.split("?", 1)[0]).suffix.lower() or ".img"
    path = CACHE / (hashlib.sha1(url.encode("utf-8")).hexdigest() + ext)
    if path.exists() and path.stat().st_size > 0:
        return path
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=20) as response:
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


def build_pdf(source: Path) -> dict[str, object]:
    data = json.loads(source.read_text(encoding="utf-8"))
    category = data.get("category", {})
    out = OUT_DIR / f"{source.stem}.pdf"
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    doc = SimpleDocTemplate(str(out), pagesize=landscape(A4), rightMargin=8 * mm, leftMargin=8 * mm, topMargin=8 * mm, bottomMargin=8 * mm)
    styles = getSampleStyleSheet()
    styles.add(ParagraphStyle(name="Cover", fontName=BOLD, fontSize=21, leading=27, alignment=TA_CENTER))
    styles.add(ParagraphStyle(name="H", fontName=BOLD, fontSize=13, leading=16, spaceAfter=4))
    styles.add(ParagraphStyle(name="Small", fontName=FONT, fontSize=7, leading=8))
    styles.add(ParagraphStyle(name="SmallR", fontName=FONT, fontSize=7, leading=8, alignment=TA_RIGHT))
    styles.add(ParagraphStyle(name="Tiny", fontName=FONT, fontSize=5.3, leading=6.1))
    styles.add(ParagraphStyle(name="TinyR", fontName=FONT, fontSize=5.3, leading=6.1, alignment=TA_RIGHT))
    styles.add(ParagraphStyle(name="Warn", fontName=BOLD, fontSize=8, leading=10, textColor=colors.HexColor("#8a5a00")))

    story = [
        Spacer(1, 22 * mm),
        para("Available Extracted Missing Y60 EPC Supplement", styles["Cover"]),
        para_ar("ملحق نواقص Y60 المستخرجة والمتاحة", styles["Cover"]),
        para(f"{category.get('market','')} / {category.get('body_style','')} / {category.get('engine','')} / {category.get('grade_or_frame','')}", styles["Cover"]),
        Spacer(1, 8 * mm),
    ]
    summary_rows = [
        ["Market", category.get("market", ""), "السوق"],
        ["Model", category.get("model_code", ""), "الموديل"],
        ["Body", category.get("body_style", ""), "الهيكل"],
        ["Engine", category.get("engine", ""), "المحرك"],
        ["Grade", category.get("grade_or_frame", ""), "الفئة"],
        ["Production", f"{category.get('production_from','')} - {category.get('production_to','')}", "الإنتاج"],
        ["Catalog Plates", str(len(data.get("units", []))), "لوحات الكتالوج"],
        ["Part Rows", str(sum(len(u.get("part_rows", [])) for u in data.get("units", []))), "صفوف القطع"],
        ["Verification Required", str(len(data.get("failures", [])) + len(data.get("group_failures", []))), "يتطلب التحقق"],
    ]
    table = Table([[para(a, styles["Small"]), para(b, styles["Small"]), para_ar(c, styles["SmallR"])] for a, b, c in summary_rows], colWidths=[42 * mm, 145 * mm, 60 * mm])
    table.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#b8c7c1")), ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f3f36")), ("TEXTCOLOR", (0, 0), (-1, 0), colors.white)]))
    story.append(table)
    story.append(PageBreak())

    headers = [
        ("Reference", "رقم الإشارة"), ("Part Number", "رقم القطعة"), ("English Name", "الاسم الإنجليزي"),
        ("Arabic Name", "الاسم العربي"), ("Qty", "الكمية"), ("Applicable Models", "الموديلات المطابقة"), ("Specifications", "المواصفات"),
    ]
    for idx, unit in enumerate(data.get("units", []), start=1):
        story.append(para(f"{idx}. {unit.get('plate_code','')} - {unit.get('plate_title_en','')}", styles["H"]))
        story.append(para_ar(translate_name(unit.get("plate_title_en", "")), styles["SmallR"]))
        img_path = cache_image(unit.get("diagram_image_url", ""))
        img = fit_image(img_path, 145 * mm, 80 * mm) if img_path else None
        if img:
            story.append(img)
        else:
            story.append(bilingual("Diagram unavailable - Verification Required", "المخطط غير متاح - يتطلب التحقق", styles["Warn"]))
        rows = [[bilingual(en, ar, styles["Tiny"]) for en, ar in headers]]
        for row in unit.get("part_rows", []):
            name_en = row.get("part_name_en", "")
            rows.append([
                para(row.get("reference_code", ""), styles["Tiny"]),
                para(row.get("part_number", ""), styles["Tiny"]),
                para(short(name_en, 70), styles["Tiny"]),
                para_ar(short(translate_name(name_en), 70), styles["TinyR"]),
                para(row.get("quantity", ""), styles["Tiny"]),
                para(short(row.get("applicable_models", ""), 85), styles["Tiny"]),
                para(short(row.get("specifications", ""), 85), styles["Tiny"]),
            ])
        if len(rows) == 1:
            rows.append([bilingual("VERIFICATION REQUIRED", "يتطلب التحقق", styles["Tiny"]), "", "", "", "", "", ""])
        parts_table = Table(rows, colWidths=[20 * mm, 28 * mm, 50 * mm, 45 * mm, 16 * mm, 56 * mm, 50 * mm], repeatRows=1)
        parts_table.setStyle(TableStyle([
            ("GRID", (0, 0), (-1, -1), 0.2, colors.HexColor("#c7d1cc")),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f3f36")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f7faf9")]),
        ]))
        story.append(parts_table)
        story.append(PageBreak())

    if data.get("failures") or data.get("group_failures"):
        story.append(bilingual("Missing EPC Plates Report", "تقرير لوحات EPC غير المكتملة", styles["H"]))
        for failure in data.get("failures", []) + data.get("group_failures", []):
            story.append(para(short(json.dumps(failure, ensure_ascii=False), 600), styles["Warn"]))

    doc.build(story)
    return {
        "source": str(source),
        "pdf": str(out),
        "units": len(data.get("units", [])),
        "parts": sum(len(u.get("part_rows", [])) for u in data.get("units", [])),
        "failures": len(data.get("failures", [])) + len(data.get("group_failures", [])),
        "bytes": out.stat().st_size,
    }


def main() -> None:
    built = []
    for source in sorted(SRC_DIR.glob("*.json")):
        if source.name.endswith(".units_index.json") or source.name.endswith(".units_plan.json"):
            continue
        if source.stem.split("_", 1)[0] in TARGET_IDS:
            built.append(build_pdf(source))
    manifest = OUT_DIR / "available_missing_manifest.json"
    manifest.write_text(json.dumps(built, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"built": built, "manifest": str(manifest)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
