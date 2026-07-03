from __future__ import annotations

import json
import re
from pathlib import Path

import arabic_reshaper
from bidi.algorithm import get_display
from pypdf import PdfReader, PdfWriter
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer


ROOT = Path(__file__).resolve().parents[1]
BASE_DIR = ROOT / "output" / "pdf" / "yearly_with_wgy60348567"
SUP_DIR = ROOT / "output" / "pdf" / "available_missing_y60"
SRC_DIR = ROOT / "sources" / "partsouq" / "full_y60"
OUT_DIR = ROOT / "output" / "pdf" / "yearly_with_available_missing"
TMP_DIR = ROOT / "tmp" / "pdfs" / "available_missing_dividers"

TARGET_IDS = {"b3d7b114a89a", "d074a6710cf6"}
AR_RE = re.compile(r"[\u0600-\u06ff]")


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
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def para(value: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(value), style)


def para_ar(value: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(rtl(value)), style)


def parse_years(category: dict[str, object]) -> list[int]:
    text = f"{category.get('production_from','')} {category.get('production_to','')}"
    years = [int(y) for y in re.findall(r"(?:0[1-9]|1[0-2])\.(19\d{2}|20\d{2})", text)]
    start = years[0] if years else 1988
    end = years[1] if len(years) > 1 else 1997
    return [year for year in range(start, end + 1) if 1988 <= year <= 1997]


def build_divider(path: Path, year: int, title: str, units: int, parts: int, failures: int) -> None:
    styles = {
        "title": ParagraphStyle("title", fontName=BOLD, fontSize=23, leading=29, alignment=TA_CENTER, textColor=colors.HexColor("#173f36")),
        "body": ParagraphStyle("body", fontName=FONT, fontSize=12, leading=16, alignment=TA_CENTER),
        "warn": ParagraphStyle("warn", fontName=BOLD, fontSize=10, leading=14, alignment=TA_CENTER, textColor=colors.HexColor("#8a5a00")),
    }
    doc = SimpleDocTemplate(str(path), pagesize=landscape(A4), rightMargin=18 * mm, leftMargin=18 * mm, topMargin=18 * mm, bottomMargin=18 * mm)
    story = [
        Spacer(1, 38 * mm),
        para(f"Available Missing EPC Supplement - Y60 {year}", styles["title"]),
        para_ar(f"ملحق النواقص المستخرجة المتاحة - Y60 {year}", styles["title"]),
        Spacer(1, 9 * mm),
        para(title, styles["body"]),
        para_ar("هذا الملحق يحتوي فقط على النواقص التي تم استخراجها فعليًا من PartSouq حتى الآن.", styles["body"]),
        Spacer(1, 7 * mm),
        para(f"Catalog plates: {units} | Part rows: {parts} | Verification Required: {failures}", styles["body"]),
        para_ar(f"لوحات الكتالوج: {units} | صفوف القطع: {parts} | يتطلب التحقق: {failures}", styles["body"]),
        Spacer(1, 7 * mm),
        para("Remaining non-extracted references are not fabricated and remain in the missing coverage report.", styles["warn"]),
        para_ar("المراجع غير المستخرجة لم يتم اختلاقها وتبقى موجودة في تقرير النواقص.", styles["warn"]),
    ]
    doc.build(story)


def append_pdf(writer: PdfWriter, reader: PdfReader) -> None:
    for page in reader.pages:
        writer.add_page(page)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)
    supplements = []
    for source in sorted(SRC_DIR.glob("*.json")):
        if source.name.endswith(".units_index.json") or source.name.endswith(".units_plan.json"):
            continue
        extract_id = source.stem.split("_", 1)[0]
        if extract_id not in TARGET_IDS:
            continue
        data = json.loads(source.read_text(encoding="utf-8"))
        category = data.get("category", {})
        pdf = SUP_DIR / f"{source.stem}.pdf"
        if not pdf.exists():
            continue
        supplements.append({
            "extract_id": extract_id,
            "source": source,
            "pdf": pdf,
            "years": parse_years(category),
            "title": f"{category.get('market','')} / {category.get('body_style','')} / {category.get('engine','')} / {category.get('grade_or_frame','')}",
            "units": len(data.get("units", [])),
            "parts": sum(len(u.get("part_rows", [])) for u in data.get("units", [])),
            "failures": len(data.get("failures", [])) + len(data.get("group_failures", [])),
        })

    manifest = []
    for year in range(1988, 1998):
        base = BASE_DIR / f"Y60 {year}.pdf"
        out = OUT_DIR / f"Y60 {year}.pdf"
        writer = PdfWriter()
        append_pdf(writer, PdfReader(str(base)))
        included = []
        for sup in supplements:
            if year not in sup["years"]:
                continue
            divider = TMP_DIR / f"{year}_{sup['extract_id']}.pdf"
            build_divider(divider, year, sup["title"], sup["units"], sup["parts"], sup["failures"])
            append_pdf(writer, PdfReader(str(divider)))
            append_pdf(writer, PdfReader(str(sup["pdf"])))
            included.append({k: str(v) if isinstance(v, Path) else v for k, v in sup.items() if k != "source"})
        with out.open("wb") as f:
            writer.write(f)
        manifest.append({
            "year": year,
            "base": str(base),
            "output": str(out),
            "included_supplements": included,
            "pages": len(PdfReader(str(out)).pages),
            "bytes": out.stat().st_size,
        })

    manifest_path = OUT_DIR / "merge_available_missing_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"out": str(OUT_DIR), "years": len(manifest), "manifest": str(manifest_path)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
