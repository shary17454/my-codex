from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "work" / "partsouq_full" / "units_structured.json"
DIAGRAMS = ROOT / "work" / "partsouq_full" / "diagrams_colored"
OUT_DIR = ROOT / "outputs" / "extracted_parts"
OUT_HTML = OUT_DIR / "patrol_y60_hvac_coolers_vents_complete_card.html"


SELECTED = [
    39,  # heater front
    40,  # blower front
    41,  # rear heater/blower
    42,  # front air con, includes ice box applications
    43,  # cooling unit
    44,  # cooling fitting parts
    45,  # overhead cooler
    46,  # overhead cooler fitting
    47,  # manual control unit
    48,  # nozzle and duct
    51,  # condenser, liquid tank, piping
    53,  # rear cooler piping
    54,  # rear overhead cooler piping
    55,  # heater piping front
    56,  # heater piping front+rear
    144, # ventilator
]

AR_TITLES = {
    "HEATER UNIT; HEATER UNIT(FRONT)": "دبة السخان الأمامية",
    "HEATER UNIT; BLOWER UNIT(FRONT)": "وحدة البلور الأمامية",
    "HEATER & BLOWER UNIT; HEATER & BLOWER UNIT(REAR)": "دبة السخان والبلور الخلفية",
    "COOLING UNIT; FRONT AIR CON": "وحدة المكيف الأمامي والثلاجة الأمامية",
    "COOLING UNIT; COOLING UNIT": "وحدة التبريد / الثلاجة",
    "COOLING UNIT; FITTING PARTS": "قطع تثبيت وحدة التبريد",
    "COOLING UNIT; COOLING UNIT(OVER HEAD TYPE)": "وحدة المكيف الخلفي العلوي",
    "COOLING UNIT; FITTING PARTS(OVER HEAD TYPE)": "قطع تثبيت المكيف الخلفي العلوي",
    "CONTROL UNIT; MANUAL TYPE": "مفاتيح المكيف اليدوية والوايرات",
    "NOZZLE & DUCT": "الهوايات ومجاري الهواء",
    "CONDENSER,LIQUID TANK & PIPING": "الكوندنسر وعلبة الفريون ومواسير المكيف",
    "PIPING; REAR COOLER": "مواسير المكيف الخلفي",
    "PIPING; REAR OVER HEAD COOLER": "مواسير المكيف الخلفي العلوي",
    "HEATER PIPING; FRONT": "ليات السخان الأمامي",
    "HEATER PIPING; FRONT+REAR": "ليات السخان الأمامي والخلفي",
    "VENTILATOR": "الهوايات الداخلية",
}

GROUPS = {
    "المنظومة الأمامية": [39, 40, 42, 47, 48, 51, 55],
    "الثلاجة والمكيف الخلفي": [41, 43, 44, 45, 46, 53, 54, 56],
    "الهوايات والديكورات المرتبطة": [144],
}


def esc(value: object) -> str:
    return html.escape("" if value is None else str(value))


def diagram_path(index: int, uid: str) -> str:
    path = DIAGRAMS / f"{index + 1:03d}_uid_{uid}.png"
    if not path.exists():
        return ""
    return path.resolve().as_posix()


def rows_for(unit: dict) -> list[list[str]]:
    table = unit.get("table") or []
    return table[1:] if len(table) > 1 else []


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
        <div class="count">{len(rows)} قطعة</div>
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
    units = {i: data[i] for i in SELECTED}
    total_rows = sum(len(rows_for(u)) for u in units.values())

    toc = []
    for group, indexes in GROUPS.items():
        toc.append(f"<h3>{esc(group)}</h3><ul>")
        for idx in indexes:
            unit = units[idx]
            toc.append(
                f"<li><span>{esc(AR_TITLES.get(unit.get('title',''), unit.get('title','')))}</span>"
                f"<b class='en'>{len(rows_for(unit))} parts</b></li>"
            )
        toc.append("</ul>")

    sections = []
    for group, indexes in GROUPS.items():
        sections.append(f'<div class="group-break"><h1>{esc(group)}</h1></div>')
        for idx in indexes:
            sections.append(section_html(idx, units[idx]))

    html_text = f"""<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>Patrol Y60 HVAC Complete Card</title>
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
    .summary {{
      margin: 22px auto;
      max-width: 720px;
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
      padding: 8px 10px;
      background: #fff8ee;
      border-bottom: 1px solid #e1d3c1;
      font-weight: 700;
    }}
    .summary li:nth-child(even) {{ background: #f2e4d4; }}
    .badge {{
      display: inline-block;
      padding: 10px 16px;
      margin-top: 12px;
      background: #eef7fa;
      border: 2px solid #c8dbe6;
      color: #14598d;
      font-weight: 900;
      font-size: 17px;
    }}
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
      max-height: 245px;
      object-fit: contain;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
      direction: rtl;
      font-size: 11px;
    }}
    th {{
      background: #7a1e2e;
      color: white;
      border: 1px solid #d6c6b1;
      padding: 6px 5px;
      font-size: 11px;
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
    th:nth-child(3), td:nth-child(3) {{ width: 30%; }}
    th:nth-child(4), td:nth-child(4) {{ width: 8%; }}
    th:nth-child(5), td:nth-child(5) {{ width: 32%; }}
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
    <h1>بطاقة شاملة لكل ما يخص المكيف والثلاجات والهوايات</h1>
    <div class="en-title">Nissan Patrol Safari Y60 - WGY60-348567 - HVAC / Coolers / Ice Box / Ventilation</div>
    <table class="vehicle">
      <tr><td>السيارة</td><td>نيسان باترول سفاري SGL Y60</td></tr>
      <tr><td>رقم الهيكل</td><td class="en">WGY60-348567</td></tr>
      <tr><td>الموديل</td><td class="en">WLGY60JFRC5</td></tr>
      <tr><td>الإنتاج</td><td class="en">10 / 1991</td></tr>
      <tr><td>المحرك</td><td class="en">TB42S</td></tr>
      <tr><td>المحتوى</td><td>جميع مخططات وصفوف القطع المرتبطة بالمكيف الأمامي والخلفي، الثلاجات/الآيس بوكس، الهوايات، الدكتات، المواسير، بلف السخان، والوايرات.</td></tr>
    </table>
    <div class="badge">عدد المخططات: {len(SELECTED)} - عدد صفوف القطع: {total_rows}</div>
    <div class="summary">
      {''.join(toc)}
    </div>
  </div>
  {''.join(sections)}
</body>
</html>
"""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_HTML.write_text(html_text, encoding="utf-8")
    print(OUT_HTML)


if __name__ == "__main__":
    build()
