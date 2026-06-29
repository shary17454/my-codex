from __future__ import annotations

import html
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "work" / "partsouq_full" / "units_structured.json"
DIAGRAMS = ROOT / "work" / "partsouq_full" / "diagrams_colored"
OUT_DIR = ROOT / "outputs" / "extracted_parts"
OUT_HTML = OUT_DIR / "patrol_y60_special_accessories_complete_card.html"


PRIMARY_UNITS = [
    34,  # room lamp
    35,  # map lamp
    39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 53, 54, 55, 56,  # HVAC and coolers
    57, 58,  # audio
    59, 60, 61,  # wipers and washer
    210, 211, 212,  # mirrors and sunvisors
]

KEYWORDS = re.compile(
    r"(AIR CON|COOLING|COOLER|HEATER|DUCT|NOZZLE|VENTILATOR|COMPRESSOR|CONDENSER|"
    r"LIQUID TANK|PIPING|AUDIO|RADIO|CASSETTE|CD|MIRROR|MAP LAMP|ROOM LAMP|CLOCK|"
    r"WIPER|WASHER|SUNVISOR|CONTROL UNIT)",
    re.I,
)

AR_TITLES = {
    "ROOM LAMP; ROOM LAMP": "إنارة السقف",
    "ROOM LAMP; MAP LAMP": "إنارة القراءة / الخريطة",
    "HEATER UNIT; HEATER UNIT(FRONT)": "دبة السخان الأمامية",
    "HEATER UNIT; BLOWER UNIT(FRONT)": "وحدة البلور الأمامية",
    "HEATER & BLOWER UNIT; HEATER & BLOWER UNIT(REAR)": "السخان والبلور الخلفي",
    "COOLING UNIT; FRONT AIR CON": "المكيف الأمامي والثلاجة الأمامية",
    "COOLING UNIT; COOLING UNIT": "الثلاجة / وحدة التبريد",
    "COOLING UNIT; FITTING PARTS": "تثبيتات الثلاجة / وحدة التبريد",
    "COOLING UNIT; COOLING UNIT(OVER HEAD TYPE)": "المكيف الخلفي العلوي",
    "COOLING UNIT; FITTING PARTS(OVER HEAD TYPE)": "تثبيتات المكيف الخلفي العلوي",
    "CONTROL UNIT; MANUAL TYPE": "مفاتيح المكيف والوايرات",
    "NOZZLE & DUCT": "الهوايات ومجاري الهواء",
    "COMPRESSOR": "الكمبروسر",
    "COMPRESSOR MOUNTING & FITTING": "تثبيتات الكمبروسر",
    "CONDENSER,LIQUID TANK & PIPING": "الكوندنسر وعلبة الفريون والمواسير",
    "PIPING; REAR COOLER": "مواسير المكيف الخلفي",
    "PIPING; REAR OVER HEAD COOLER": "مواسير المكيف الخلفي العلوي",
    "HEATER PIPING; FRONT": "ليات السخان الأمامي",
    "HEATER PIPING; FRONT+REAR": "ليات السخان الأمامي والخلفي",
    "AUDIO & VISUAL; RADIO UNIT": "المسجل والراديو",
    "CASSETTE STEREO; CASSETTE & CD DECK": "المسجل / الكاسيت / الـ CD",
    "REAR WINDOW WIPER": "مساحة الزجاج الخلفي",
    "WINDSHIELD WIPER": "مساحات الزجاج الأمامي",
    "WINDSHIELD WASHER": "رشاشات الزجاج",
    "REAR VIEW MIRROR; OUTSIDE MIRROR": "المرايات الخارجية",
    "REAR VIEW MIRROR; INSIDE MIRROR": "المرآة الداخلية",
    "SUNVISOR": "الشماسات",
    "INSTRUMENT METER & GAUGE; METER UNIT": "العدادات والساعة الرقمية",
    "SWITCH": "المفاتيح",
}


def esc(value: object) -> str:
    return html.escape("" if value is None else str(value))


def diagram_path(index: int, uid: str) -> str:
    path = DIAGRAMS / f"{index + 1:03d}_uid_{uid}.png"
    return path.resolve().as_posix() if path.exists() else ""


def rows_for(unit: dict, filtered: bool = False) -> list[list[str]]:
    rows = (unit.get("table") or [])[1:]
    if not filtered:
        return rows
    return [r for r in rows if KEYWORDS.search(" ".join(r))]


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


def section_html(index: int, unit: dict, rows: list[list[str]], prefix: str = "") -> str:
    title = unit.get("title", "")
    uid = str(unit.get("uid", ""))
    ar_title = AR_TITLES.get(title, title)
    img = diagram_path(index, uid)
    img_html = f'<img src="file:///{img}" alt="{esc(title)}">' if img else "<div class='missing'>لا توجد صورة مخطط محفوظة لهذه الوحدة</div>"
    return f"""
    <section class="unit">
      <div class="intro">
        <div class="unit-head">
          <div>
            <h2>{esc(prefix + ar_title)}</h2>
            <div class="unit-sub en">{esc(title)} - UID {esc(uid)}</div>
          </div>
          <div class="count">{len(rows)} صف</div>
        </div>
        <div class="diagram">{img_html}</div>
      </div>
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
    primary = [(i, data[i], rows_for(data[i], False)) for i in PRIMARY_UNITS]
    primary_set = set(PRIMARY_UNITS)

    filtered_units: list[tuple[int, dict, list[list[str]]]] = []
    for i, unit in enumerate(data):
        rows = rows_for(unit, True)
        if rows:
            filtered_units.append((i, unit, rows))

    primary_rows = sum(len(rows) for _, _, rows in primary)
    filtered_rows = sum(len(rows) for _, _, rows in filtered_units)

    toc_primary = "".join(
        f"<li><span>{esc(AR_TITLES.get(u.get('title', ''), u.get('title', '')))}</span>"
        f"<b class='en'>{len(rows)} rows</b></li>"
        for _, u, rows in primary
    )
    toc_filtered = "".join(
        f"<li><span>{esc(AR_TITLES.get(u.get('title', ''), u.get('title', '')))}</span>"
        f"<b class='en'>{len(rows)} matching rows</b></li>"
        for _, u, rows in filtered_units
    )

    primary_sections = "".join(section_html(i, u, rows) for i, u, rows in primary)
    filtered_sections = "".join(
        section_html(i, u, rows, prefix="فهرس مرتبط - ")
        for i, u, rows in filtered_units
        if i not in primary_set
    )

    html_text = f"""<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>Patrol Y60 Special Accessories Complete Card</title>
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
      max-height: 620px;
      overflow: hidden;
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
      page-break-inside: auto;
    }}
    .intro {{ page-break-inside: avoid; break-inside: avoid; }}
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
    .missing {{
      color: #7a1e2e;
      font-weight: 900;
      padding: 18px;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
      direction: rtl;
      font-size: 10.5px;
      page-break-inside: auto;
    }}
    thead {{ display: table-header-group; }}
    tr {{ page-break-inside: avoid; break-inside: avoid; }}
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
    <h1>بطاقة شاملة للملحقات الخاصة والمكيف والثلاجات</h1>
    <div class="en-title">Nissan Patrol Safari Y60 - WGY60-348567 - Special Accessories / HVAC / Coolers / Audio / Mirrors</div>
    <table class="vehicle">
      <tr><td>السيارة</td><td>نيسان باترول سفاري SGL Y60</td></tr>
      <tr><td>رقم الهيكل</td><td class="en">WGY60-348567</td></tr>
      <tr><td>الموديل</td><td class="en">WLGY60JFRC5</td></tr>
      <tr><td>الإنتاج</td><td class="en">10 / 1991</td></tr>
      <tr><td>المحتوى</td><td>يشمل المكيف الأمامي والخلفي، الثلاجات، وحدات التحكم، المواسير، البلور، الهوايات، المسجل، الإضاءة العلوية، المرآة، الشماسات، والمساحات والرشاشات، مع فهرس إضافي لكل الصفوف المرتبطة بهذه الملحقات عبر الكتالوج.</td></tr>
    </table>
    <div class="badge">المخططات الأساسية: {len(primary)} - صفوفها: {primary_rows}</div>
    <div class="badge">صفوف الفهرس المطابقة عبر الكتالوج: {filtered_rows}</div>
    <div class="summary">
      <h3>المخططات الأساسية المدرجة كاملة</h3>
      <ul>{toc_primary}</ul>
    </div>
  </div>
  <div class="group-break"><h1>المخططات الأساسية للملحقات والتكييف</h1></div>
  {primary_sections}
  <div class="group-break"><h1>فهرس إضافي لكل القطع المرتبطة بالملحقات الخاصة</h1></div>
  <div class="page cover">
    <h1>فهرس القطع المطابقة</h1>
    <div class="en-title">Rows matching: COOLER / HEATER / MIRROR / AUDIO / CLOCK / LAMP / WIPER / WASHER / DUCT</div>
    <div class="summary">
      <ul>{toc_filtered}</ul>
    </div>
  </div>
  {filtered_sections}
</body>
</html>
"""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_HTML.write_text(html_text, encoding="utf-8")
    print(OUT_HTML)
    print("primary_rows", primary_rows, "filtered_rows", filtered_rows, "filtered_units", len(filtered_units))


if __name__ == "__main__":
    build()
