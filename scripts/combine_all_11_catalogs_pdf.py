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
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
YEARLY = ROOT / "output" / "pdf" / "yearly_with_wgy60348567"
LAST = ROOT / "output" / "pdf" / "full_y60" / "WGY60348567_General_Asia_LHD_WAGON_TB42S_SGL.reportlab.pdf"
OUT = ROOT / "output" / "pdf" / "Y60_1988-1997_all_11_catalogs_combined.pdf"
TMP = ROOT / "tmp" / "pdfs" / "all_11_dividers"
MANIFEST = ROOT / "output" / "pdf" / "Y60_1988-1997_all_11_catalogs_combined_manifest.json"

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


def section_inputs() -> list[dict[str, object]]:
    sections: list[dict[str, object]] = []
    for year in range(1988, 1998):
        sections.append({
            "order": year - 1987,
            "title_en": f"Nissan Patrol / Safari Y60 - {year}",
            "title_ar": f"نيسان باترول / سفاري Y60 - {year}",
            "subtitle_en": "Year catalog with verified WGY60348567 supplement",
            "subtitle_ar": "كتالوج السنة مع ملحق WGY60348567 الموثق",
            "source": YEARLY / f"Y60 {year}.pdf",
        })
    sections.append({
        "order": 11,
        "title_en": "WGY60348567 Detailed EPC Catalog",
        "title_ar": "كتالوج EPC التفصيلي للمرجع WGY60348567",
        "subtitle_en": "Independent verified reference catalog - General/Asia LHD WAGON TB42S SGL",
        "subtitle_ar": "كتالوج مرجعي مستقل موثق - سوق عام/آسيا، مقود يسار، واجن، TB42S، فئة SGL",
        "source": LAST,
    })
    return sections


def build_divider(section: dict[str, object], path: Path, source_pages: int, start_page: int) -> None:
    styles = {
        "kicker": ParagraphStyle("kicker", fontName=BOLD, fontSize=15, leading=18, alignment=TA_CENTER, textColor=colors.HexColor("#8a5a00")),
        "title": ParagraphStyle("title", fontName=BOLD, fontSize=28, leading=34, alignment=TA_CENTER, textColor=colors.HexColor("#173f36")),
        "subtitle": ParagraphStyle("subtitle", fontName=FONT, fontSize=13, leading=18, alignment=TA_CENTER),
        "note": ParagraphStyle("note", fontName=FONT, fontSize=10, leading=13, alignment=TA_CENTER, textColor=colors.HexColor("#4f5d63")),
        "cell": ParagraphStyle("cell", fontName=FONT, fontSize=10, leading=13, alignment=TA_CENTER),
        "cell_bold": ParagraphStyle("cell_bold", fontName=BOLD, fontSize=11, leading=14, alignment=TA_CENTER),
    }
    doc = SimpleDocTemplate(
        str(path),
        pagesize=landscape(A4),
        rightMargin=18 * mm,
        leftMargin=18 * mm,
        topMargin=16 * mm,
        bottomMargin=16 * mm,
        title=str(section["title_en"]),
    )
    rows = [
        [para("Section", styles["cell_bold"]), para("Order", styles["cell_bold"]), para("Starts At Page", styles["cell_bold"]), para("Section Pages", styles["cell_bold"])],
        [
            para(str(section["title_en"]), styles["cell"]),
            para(str(section["order"]), styles["cell"]),
            para(str(start_page), styles["cell"]),
            para(str(source_pages), styles["cell"]),
        ],
        [para_ar("القسم", styles["cell_bold"]), para_ar("الترتيب", styles["cell_bold"]), para_ar("يبدأ من الصفحة", styles["cell_bold"]), para_ar("صفحات القسم", styles["cell_bold"])],
    ]
    table = Table(rows, colWidths=[112 * mm, 34 * mm, 48 * mm, 44 * mm])
    table.setStyle(TableStyle([
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#b8c7c1")),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f3f36")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("BACKGROUND", (0, 2), (-1, 2), colors.HexColor("#eef5f2")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
    ]))
    story = [
        Spacer(1, 30 * mm),
        para(f"SECTION {section['order']} / 11", styles["kicker"]),
        para_ar(f"القسم {section['order']} من 11", styles["kicker"]),
        Spacer(1, 7 * mm),
        para(section["title_en"], styles["title"]),
        para_ar(section["title_ar"], styles["title"]),
        Spacer(1, 6 * mm),
        para(section["subtitle_en"], styles["subtitle"]),
        para_ar(section["subtitle_ar"], styles["subtitle"]),
        Spacer(1, 11 * mm),
        table,
        Spacer(1, 8 * mm),
        para("The next pages are the complete source PDF for this section, preserved in order.", styles["note"]),
        para_ar("الصفحات التالية هي ملف PDF الكامل لهذا القسم، محفوظة بنفس ترتيبها.", styles["note"]),
    ]
    doc.build(story)


def append_reader(writer: PdfWriter, reader: PdfReader) -> None:
    for page in reader.pages:
        writer.add_page(page)


def main() -> None:
    TMP.mkdir(parents=True, exist_ok=True)
    OUT.parent.mkdir(parents=True, exist_ok=True)

    writer = PdfWriter()
    manifest: list[dict[str, object]] = []
    page_cursor = 1

    for section in section_inputs():
        source = Path(section["source"])
        if not source.exists():
            raise FileNotFoundError(source)
        source_reader = PdfReader(str(source))
        divider = TMP / f"section_{section['order']:02d}.pdf"
        build_divider(section, divider, len(source_reader.pages), page_cursor)
        divider_reader = PdfReader(str(divider))

        section_start = page_cursor
        append_reader(writer, divider_reader)
        page_cursor += len(divider_reader.pages)
        content_start = page_cursor
        append_reader(writer, source_reader)
        page_cursor += len(source_reader.pages)

        manifest.append({
            "order": section["order"],
            "title_en": section["title_en"],
            "title_ar": section["title_ar"],
            "source_pdf": str(source),
            "divider_pages": len(divider_reader.pages),
            "source_pages": len(source_reader.pages),
            "section_start_page": section_start,
            "content_start_page": content_start,
            "section_end_page": page_cursor - 1,
        })

    writer.add_metadata({
        "/Title": "Nissan Patrol Y60 1988-1997 - All 11 Catalog PDFs Combined",
        "/Subject": "Chronological combined bilingual catalog with section start pages",
        "/Author": "Codex",
    })

    with OUT.open("wb") as f:
        writer.write(f)

    result = {
        "output_pdf": str(OUT),
        "bytes": OUT.stat().st_size,
        "sections": len(manifest),
        "total_pages": len(PdfReader(str(OUT)).pages),
        "manifest": manifest,
    }
    MANIFEST.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
