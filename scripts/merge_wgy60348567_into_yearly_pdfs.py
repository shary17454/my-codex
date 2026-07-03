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
YEARLY_DIR = ROOT / "output" / "pdf" / "yearly"
WGY_PDF = ROOT / "output" / "pdf" / "full_y60" / "WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.reportlab.pdf"
OUT_DIR = ROOT / "output" / "pdf" / "yearly_with_wgy60348567"
TMP_DIR = ROOT / "tmp" / "pdfs" / "yearly_wgy_dividers"

ARABIC_RE = re.compile(r"[\u0600-\u06ff]")


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
    if not ARABIC_RE.search(text):
        return text
    return get_display(arabic_reshaper.reshape(text))


def esc(value: object) -> str:
    text = "" if value is None else str(value)
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def para(text: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(text), style)


def para_ar(text: object, style: ParagraphStyle) -> Paragraph:
    return Paragraph(esc(rtl(text)), style)


def build_divider(year: int, path: Path) -> None:
    styles = {
        "title": ParagraphStyle("title", fontName=BOLD, fontSize=24, leading=30, alignment=TA_CENTER, textColor=colors.HexColor("#173f36")),
        "body": ParagraphStyle("body", fontName=FONT, fontSize=12, leading=16, alignment=TA_CENTER),
        "body_ar": ParagraphStyle("body_ar", fontName=FONT, fontSize=12, leading=16, alignment=TA_CENTER),
        "warn": ParagraphStyle("warn", fontName=BOLD, fontSize=11, leading=15, alignment=TA_CENTER, textColor=colors.HexColor("#8a5a00")),
    }
    doc = SimpleDocTemplate(
        str(path),
        pagesize=landscape(A4),
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=18 * mm,
        bottomMargin=18 * mm,
        title=f"Y60 {year} WGY60348567 verified supplement divider",
    )
    story = [
        Spacer(1, 42 * mm),
        para(f"Verified EPC Supplement - Y60 {year}", styles["title"]),
        para_ar(f"ملحق EPC موثق - Y60 {year}", styles["title"]),
        Spacer(1, 10 * mm),
        para("Source reference: WGY60348567 - General/Asia LHD WAGON TB42S SGL", styles["body"]),
        para_ar("مرجع المصدر: WGY60348567 - سوق عام/آسيا، مقود يسار، واجن، TB42S، فئة SGL", styles["body_ar"]),
        Spacer(1, 8 * mm),
        para("This supplement contains the detailed catalog plates, diagrams, and part rows extracted for this specific verified reference.", styles["body"]),
        para_ar("هذا الملحق يحتوي على لوحات الكتالوج والمخططات وصفوف القطع المستخرجة لهذا المرجع المحدد فقط.", styles["body_ar"]),
        Spacer(1, 8 * mm),
        para("Verification Required: do not treat this supplement as complete coverage for every Y60 body, market, trim, or engine.", styles["warn"]),
        para_ar("يتطلب التحقق: لا يُعامل هذا الملحق كتغطية كاملة لكل هياكل وأسواق وفئات ومحركات Y60.", styles["warn"]),
    ]
    doc.build(story)


def append_pdf(writer: PdfWriter, reader: PdfReader) -> None:
    for page in reader.pages:
        writer.add_page(page)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    TMP_DIR.mkdir(parents=True, exist_ok=True)

    if not WGY_PDF.exists():
        raise FileNotFoundError(WGY_PDF)

    wgy_reader = PdfReader(str(WGY_PDF))
    manifest = []
    for year in range(1988, 1998):
        src = YEARLY_DIR / f"Y60 {year}.pdf"
        if not src.exists():
            manifest.append({"year": year, "status": "missing source", "source": str(src)})
            continue

        divider = TMP_DIR / f"divider_{year}.pdf"
        build_divider(year, divider)

        yearly_reader = PdfReader(str(src))
        divider_reader = PdfReader(str(divider))
        writer = PdfWriter()
        append_pdf(writer, yearly_reader)
        append_pdf(writer, divider_reader)
        append_pdf(writer, wgy_reader)
        writer.add_metadata({
            "/Title": f"Nissan Patrol Y60 {year} with WGY60348567 verified supplement",
            "/Subject": "Bilingual Y60 yearly catalog with verified WGY60348567 EPC supplement",
        })

        out = OUT_DIR / f"Y60 {year}.pdf"
        with out.open("wb") as f:
            writer.write(f)

        manifest.append({
            "year": year,
            "source_pdf": str(src),
            "output_pdf": str(out),
            "yearly_pages": len(yearly_reader.pages),
            "supplement_pages": len(wgy_reader.pages),
            "divider_pages": len(divider_reader.pages),
            "total_pages": len(PdfReader(str(out)).pages),
            "bytes": out.stat().st_size,
            "note": "WGY60348567 supplement is verified only for the extracted reference, not every Y60 variant.",
        })

    manifest_path = OUT_DIR / "merge_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"merged": len([m for m in manifest if m.get("output_pdf")]), "out": str(OUT_DIR), "manifest": str(manifest_path)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
