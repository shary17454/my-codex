from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "work" / "partsouq_full" / "units_structured.json"
DIAGRAMS = ROOT / "work" / "partsouq_full" / "diagrams_colored"
OUT_DIR = ROOT / "outputs" / "extracted_parts"
OUT_HTML = OUT_DIR / "patrol_y60_interior_trim_seats_complete_card.html"


GROUPS = {
    "الطبلون والديكورات الأمامية": [117, 142, 143, 144],
    "السقف والفرش والعوازل": [147, 148, 149, 150, 154, 212],
    "الأرضية والجوانب والشنطة": [151, 152, 153, 162, 177, 204, 207],
    "ديكورات الأبواب": [170, 174],
    "الكراسي وأحزمة المقاعد": [179, 180, 181, 182, 185, 187, 188, 189, 195, 196, 198, 199],
    "الكونسول والتكاية الوسطية": [213, 214],
    "الثلاجة الخلفية والمكيف الخلفي المرتبط بالديكور": [41, 43, 44, 45, 46, 53, 54],
}

AR_TITLES = {
    "STEERING COLUMN SHELL COVER": "غطاء عامود الدركسون",
    "DASH TRIMMING & FITTING": "ديكورات الداش وتثبيتها",
    "INSTRUMENT PANEL,PAD & CLUSTER LID": "قشرة الطبلون وغطاء العدادات",
    "VENTILATOR": "الهوايات الداخلية",
    "ROOF TRIMMING; K": "فرش السقف - K",
    "ROOF TRIMMING; W": "فرش السقف - W",
    "ROOF TRIMMING; STANDARD ROOF": "فرش السقف - سقف عادي",
    "ROOF TRIMMING; SUNROOF": "فرش السقف - فتحة سقف",
    "FLOOR PANEL": "صاج الأرضية",
    "FLOOR PANEL (REAR)": "صاج الأرضية الخلفي",
    "FLOOR FITTING": "قطع تثبيت الأرضية",
    "FLOOR TRIMMING": "فرش الأرضية والعوازل",
    "BODY SIDE TRIMMING": "ديكورات الجوانب الداخلية",
    "FRONT DOOR TRIMMING": "ديكورات الأبواب الأمامية",
    "REAR DOOR TRIMMING": "ديكورات الأبواب الخلفية",
    "TRUNK & LUGGAGE ROOM TRIMMING": "ديكورات الشنطة وحجرة الأمتعة",
    "BACK DOOR TRIMMING": "ديكور الباب الخلفي",
    "REAR BODY FLOOR & FITTING": "أرضية الخلفية وتثبيتها",
    "SUNVISOR": "الشماسات",
    "FRONT SEAT BELT; W +HW +T": "أحزمة المقاعد الأمامية",
    "REAR SEAT BELT": "أحزمة المقاعد الخلفية",
    "FRONT SEAT; RH SEAT (SEPARATE TYPE)": "كرسي أمامي يمين منفصل",
    "FRONT SEAT; LH SEAT (SEPARATE TYPE)": "كرسي أمامي يسار منفصل",
    "FRONT SEAT; RH ONE PERSON": "كرسي أمامي يمين شخص واحد",
    "FRONT SEAT; LH": "كرسي أمامي يسار",
    "REAR SEAT; RH SEAT (SPLIT SEAT)": "كرسي خلفي يمين منفصل",
    "REAR SEAT; LH SEAT (SPLIT SEAT)": "كرسي خلفي يسار منفصل",
    "REAR SEAT; WAGON SPLIT TYPE RH": "كرسي خلفي واجن منفصل يمين",
    "REAR SEAT; WAGON SPLIT TYPE LH": "كرسي خلفي واجن منفصل يسار",
    "3RD SEAT; BENCH TYPE": "كرسي الصف الثالث",
    "3RD SEAT; (BENCH TYPE)(SIDE FASING)": "كرسي الصف الثالث جانبي",
    "CONSOLE BOX; NO.1": "ديكور الكونسول / التكاية الوسطية - رقم 1",
    "CONSOLE BOX; NO.2": "ديكور الكونسول / التكاية الوسطية - رقم 2",
    "HEATER & BLOWER UNIT; HEATER & BLOWER UNIT(REAR)": "دبة السخان والبلور الخلفية",
    "COOLING UNIT; COOLING UNIT": "وحدة التبريد / الثلاجة الخلفية",
    "COOLING UNIT; FITTING PARTS": "قطع تثبيت وحدة التبريد الخلفية",
    "COOLING UNIT; COOLING UNIT(OVER HEAD TYPE)": "وحدة المكيف الخلفي العلوي",
    "COOLING UNIT; FITTING PARTS(OVER HEAD TYPE)": "قطع تثبيت المكيف الخلفي العلوي",
    "PIPING; REAR COOLER": "مواسير المكيف الخلفي",
    "PIPING; REAR OVER HEAD COOLER": "مواسير المكيف الخلفي العلوي",
}


def esc(value: object) -> str:
    return html.escape("" if value is None else str(value))


def rows_for(unit: dict) -> list[list[str]]:
    table = unit.get("table") or []
    return table[1:] if len(table) > 1 else []


def diagram_path(index: int, uid: str) -> str:
    path = DIAGRAMS / f"{index + 1:03d}_uid_{uid}.png"
    return path.resolve().as_posix() if path.exists() else ""


def row_html(row: list[str]) -> str:
    part = row[0] if len(row) > 0 else ""
    name = row[1] if len(row) > 1 else ""
    code = row[2] if len(row) > 2 else ""
    qty = row[3] if len(row) > 3 else ""
    app = row[4] if len(row) > 4 else ""
    spec = row[5] if len(row) > 5 else ""
    date = row[6] if len(row) > 6 else ""
    note = " ".join(x for x in [app, spec, date] if x)
    return f"""
      <tr>
        <td class="en code">{esc(code)}</td>
        <td class="en part">{esc(part)}</td>
        <td class="en name">{esc(name)}</td>
        <td class="en qty">{esc(qty)}</td>
        <td class="en note-cell">{esc(note)}</td>
      </tr>
    """


def section_html(index: int, unit: dict) -> str:
    title = unit.get("title", "")
    uid = unit.get("uid", "")
    ar_title = AR_TITLES.get(title, title)
    rows = rows_for(unit)
    img = diagram_path(index, uid)
    img_html = f'<img src="file:///{img}" alt="{esc(title)}">' if img else ""
    return f"""
    <section class="unit">
      <div class="unit-head">
        <div>
          <h2>{esc(ar_title)}</h2>
          <div class="unit-sub en">{esc(title)} - UID {esc(uid)}</div>
        </div>
        <div class="count">{len(rows)} صف</div>
      </div>
      <div class="diagram">{img_html}</div>
      <table>
        <thead>
          <tr>
            <th>رقم المخطط</th>
            <th>رقم القطعة</th>
            <th>الاسم في الكتالوج</th>
            <th>الكمية</th>
            <th>التطبيق / الملاحظة / التاريخ</th>
          </tr>
        </thead>
        <tbody>
          {''.join(row_html(r) for r in rows)}
        </tbody>
      </table>
    </section>
    """


def build() -> None:
    data = json.loads(DATA.read_text(encoding="utf-8"))
    selected = [idx for indexes in GROUPS.values() for idx in indexes]
    total_rows = sum(len(rows_for(data[idx])) for idx in selected)

    toc = []
    for group, indexes in GROUPS.items():
        toc.append(f"<h3>{esc(group)}</h3><ul>")
        for idx in indexes:
            unit = data[idx]
            toc.append(
                f"<li><span>{esc(AR_TITLES.get(unit.get('title',''), unit.get('title','')))}</span>"
                f"<b class='en'>{len(rows_for(unit))} rows</b></li>"
            )
        toc.append("</ul>")

    sections = []
    for group, indexes in GROUPS.items():
        sections.append(f'<div class="group-break"><h1>{esc(group)}</h1></div>')
        for idx in indexes:
            sections.append(section_html(idx, data[idx]))

    html_text = f"""<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>Patrol Y60 Interior Trim Seats Complete Card</title>
  <style>
    @page {{ size: A4 portrait; margin: 10mm; }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      background: #eee8dc;
      color: #201b18;
      font-family: Arial, "Segoe UI", Tahoma, sans-serif;
      font-size: 13px;
    }}
    .page {{
      background: #fffdf8;
      border: 3px solid #906532;
      padding: 22px;
      min-height: 100vh;
    }}
    .cover {{
      page-break-after: always;
      text-align: center;
    }}
    .cover h1 {{
      margin: 24px 0 8px;
      color: #7a1e2e;
      font-size: 30px;
      line-height: 1.35;
    }}
    .cover .en-title {{
      direction: ltr;
      color: #14598d;
      font-weight: 900;
      font-size: 18px;
      margin-bottom: 22px;
    }}
    .vehicle {{
      margin: 18px auto;
      max-width: 720px;
      border-collapse: collapse;
      font-size: 15px;
      text-align: right;
    }}
    .vehicle td {{
      border: 1px solid #d6c6b1;
      padding: 9px 11px;
      background: #fff8ee;
      font-weight: 700;
    }}
    .vehicle td:first-child {{
      width: 34%;
      background: #7a1e2e;
      color: white;
    }}
    .badge {{
      display: inline-block;
      padding: 10px 16px;
      margin: 8px;
      background: #eef7fa;
      border: 2px solid #c8dbe6;
      color: #14598d;
      font-weight: 900;
      font-size: 16px;
    }}
    .summary {{
      margin: 18px auto;
      max-width: 760px;
      text-align: right;
    }}
    .summary h3 {{
      margin: 16px 0 7px;
      color: #7a1e2e;
      font-size: 18px;
    }}
    .summary ul {{
      list-style: none;
      padding: 0;
      margin: 0;
      border: 1px solid #d6c6b1;
    }}
    .summary li {{
      display: flex;
      justify-content: space-between;
      gap: 10px;
      padding: 7px 10px;
      background: #fff8ee;
      border-bottom: 1px solid #e1d3c1;
      font-weight: 700;
    }}
    .summary li:nth-child(even) {{ background: #f2e4d4; }}
    .group-break {{
      page-break-before: always;
      background: #7a1e2e;
      color: white;
      text-align: center;
      padding: 14px;
      margin: 0 0 12px;
    }}
    .group-break h1 {{
      margin: 0;
      font-size: 24px;
    }}
    .unit {{
      background: #fffdf8;
      border: 2px solid #b89062;
      padding: 12px;
      margin: 0 0 14px;
      page-break-inside: avoid;
    }}
    .unit-head {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      border-bottom: 2px solid #e4d3bf;
      padding-bottom: 8px;
      margin-bottom: 10px;
    }}
    h2 {{
      margin: 0;
      color: #7a1e2e;
      font-size: 20px;
      line-height: 1.35;
    }}
    .unit-sub {{
      margin-top: 3px;
      font-size: 12px;
    }}
    .count {{
      background: #14598d;
      color: white;
      border-radius: 4px;
      padding: 6px 10px;
      font-weight: 900;
      white-space: nowrap;
    }}
    .diagram {{
      background: white;
      border: 1px solid #d6c6b1;
      text-align: center;
      padding: 7px;
      margin-bottom: 10px;
    }}
    .diagram img {{
      max-width: 100%;
      max-height: 250px;
      object-fit: contain;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
      direction: rtl;
      font-size: 10.5px;
    }}
    th {{
      background: #7a1e2e;
      color: white;
      border: 1px solid #d6c6b1;
      padding: 6px 5px;
      font-size: 10.5px;
    }}
    td {{
      border: 1px solid #d6c6b1;
      padding: 5px 5px;
      vertical-align: top;
      background: #fff8ee;
      font-weight: 650;
    }}
    tr:nth-child(even) td {{ background: #f2e4d4; }}
    th:nth-child(1), td:nth-child(1) {{ width: 12%; }}
    th:nth-child(2), td:nth-child(2) {{ width: 18%; }}
    th:nth-child(3), td:nth-child(3) {{ width: 31%; }}
    th:nth-child(4), td:nth-child(4) {{ width: 8%; }}
    th:nth-child(5), td:nth-child(5) {{ width: 31%; }}
    .en {{
      direction: ltr;
      unicode-bidi: embed;
      color: #14598d;
      font-weight: 900;
      overflow-wrap: anywhere;
    }}
    .part {{ color: #7a1e2e; }}
    .name {{ color: #14598d; }}
    .note-cell {{ color: #3a342f; font-weight: 650; }}
  </style>
</head>
<body>
  <div class="page cover">
    <h1>بطاقة شاملة للديكورات الداخلية والفرش والكراسي</h1>
    <div class="en-title">Nissan Patrol Safari Y60 - WGY60-348567 - Interior Trim / Seats / Roof / Floor / Console / Rear Cooler Trim</div>
    <table class="vehicle">
      <tr><td>السيارة</td><td>نيسان باترول سفاري SGL Y60</td></tr>
      <tr><td>رقم الهيكل</td><td class="en">WGY60-348567</td></tr>
      <tr><td>الموديل</td><td class="en">WLGY60JFRC5</td></tr>
      <tr><td>الإنتاج</td><td class="en">10 / 1991</td></tr>
      <tr><td>اللون الداخلي</td><td class="en">AH3 / Burgundy</td></tr>
      <tr><td>منهجية الحصر</td><td>تم إدراج وحدات الديكور الداخلي والفرش والكراسي والأرضية والسقف والأبواب والكونسول والثلاجة/المكيف الخلفي المرتبط بالديكور.</td></tr>
    </table>
    <div class="badge">عدد المخططات: {len(selected)}</div>
    <div class="badge">عدد صفوف القطع: {total_rows}</div>
    <div class="summary">{''.join(toc)}</div>
  </div>
  {''.join(sections)}
</body>
</html>
"""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_HTML.write_text(html_text, encoding="utf-8")
    print(OUT_HTML)
    print("units", len(selected), "rows", total_rows)


if __name__ == "__main__":
    build()
