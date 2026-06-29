from __future__ import annotations

import html
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "work" / "partsouq_full" / "units_structured.json"
DIAGRAMS = ROOT / "work" / "partsouq_full" / "diagrams_colored"
OUT_DIR = ROOT / "outputs" / "extracted_parts"
OUT_HTML = OUT_DIR / "patrol_y60_wiring_connectors_complete_card.html"


PRIMARY_UNITS = [
    17,  # ignition system
    18,  # distributor and ignition timing sensor
    20,  # alternator fitting
    21,  # alternator
    22,  # starter motor
    23,  # wiring body
    24,  # wiring body fitting parts
    25,  # battery
    26,  # meter and gauge
    27,  # switch
    28,  # relay part 1
    29,  # relay part 2
    30,  # electrical unit
    31,  # headlamp
    32,  # front combination lamp
    34,  # room lamp
    35,  # map lamp
    36,  # rear combination lamp
    37,  # license plate lamp
    38,  # other lamps
    47,  # manual A/C control switches
    57,  # radio unit
    58,  # cassette stereo
    59,  # rear wiper
    60,  # windshield wiper
    61,  # windshield washer
    80,  # control switch and system
    97,  # diff lock control
]

KEYWORDS = re.compile(
    r"\b(HARNESS|WIRING|WIRE|CONNECTOR|CORD|FUSE|FUSIBLE|RELAY|SWITCH|"
    r"SENSOR|SOLENOID|TERMINAL|SOCKET|LAMP|BULB|CONTROLLER|BUZZER|HORN|"
    r"FLASHER|RESISTOR|AMPLIFIER|ANTENNA|MOTOR|BATTERY|ALTERNATOR|"
    r"STARTER|DISTRIBUTOR|IGNITION|METER|GAUGE)\b|CONTROL UNIT",
    re.I,
)

AR_TITLES = {
    "IGNITION SYSTEM": "نظام الإشعال",
    "DISTRIBUTOR & IGNITION TIMING SENSOR; MITSUBISHI": "الديلكو وحساس توقيت الإشعال",
    "ALTERNATOR FITTING": "تثبيت الدينمو",
    "ALTERNATOR; HITACHI": "الدينمو / المولد",
    "STARTER MOTOR; HITACHI": "السلف / بادئ الحركة",
    "WIRING (BODY); WIRING": "الظفيرة الرئيسية للجسم",
    "WIRING (BODY); FITTING PARTS": "قطع تثبيت الظفيرة والأفياش",
    "BATTERY & BATTERY MOUNTING": "البطارية وقاعدة البطارية",
    "INSTRUMENT METER & GAUGE; METER UNIT": "العدادات والمؤشرات",
    "SWITCH": "المفاتيح",
    "RELAY; PART 1": "الريليهات - الجزء الأول",
    "RELAY; PART 2": "الريليهات - الجزء الثاني",
    "ELECTRICAL UNIT": "الوحدات الكهربائية",
    "HEADLAMP": "الأنوار الأمامية",
    "FRONT COMBINATION LAMP": "الأنوار الأمامية الجانبية / الإشارات",
    "ROOM LAMP; ROOM LAMP": "لمبات السقف",
    "ROOM LAMP; MAP LAMP": "لمبة القراءة / الخريطة",
    "REAR COMBINATION LAMP; F/GEN+ME": "الأنوار الخلفية",
    "LICENCE PLATE LAMP": "لمبة اللوحة",
    "LAMPS (OTHERS); FOG LAMP-ROUND,HALOGEN & INSPECTION LAMP": "لمبات أخرى / كشاف / لمبة فحص",
    "CONTROL UNIT; MANUAL TYPE": "مفاتيح المكيف اليدوية",
    "AUDIO & VISUAL; RADIO UNIT": "المسجل والراديو",
    "CASSETTE STEREO; CASSETTE & CD DECK": "المسجل / الكاسيت / الـ CD",
    "REAR WINDOW WIPER": "مساحة الزجاج الخلفي",
    "WINDSHIELD WIPER": "مساحات الزجاج الأمامي",
    "WINDSHIELD WASHER": "طرمبة وليات رشاشات الزجاج",
    "CONTROL SWITCH & SYSTEM": "مفاتيح وأنظمة التحكم",
    "DIFF LOCK CONTROL": "تحكم الدفرنس لوك",
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
  <title>Patrol Y60 Wiring and Connectors Complete Card</title>
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
    <h1>بطاقة شاملة للكهرباء والأفياش والظفيرة</h1>
    <div class="en-title">Nissan Patrol Safari Y60 - WGY60-348567 - Electrical / Harness / Connectors / Switches / Relays / Audio / Wipers</div>
    <table class="vehicle">
      <tr><td>السيارة</td><td>نيسان باترول سفاري SGL Y60</td></tr>
      <tr><td>رقم الهيكل</td><td class="en">WGY60-348567</td></tr>
      <tr><td>الموديل</td><td class="en">WLGY60JFRC5</td></tr>
      <tr><td>الإنتاج</td><td class="en">10 / 1991</td></tr>
      <tr><td>المحرك</td><td class="en">TB42S</td></tr>
      <tr><td>منهجية الحصر</td><td>تم إدراج مخططات الكهرباء الأساسية كاملة، ثم فهرسة كل صف في الكتالوج يحتوي على كلمات مرتبطة بالظفيرة أو الفيش أو المفتاح أو الريليه أو الحساس أو اللمبة أو السلك أو الأنظمة الكهربائية ذات الصلة.</td></tr>
    </table>
    <div class="badge">المخططات الأساسية: {len(primary)} - صفوفها: {primary_rows}</div>
    <div class="badge">صفوف الفهرس المطابقة عبر الكتالوج: {filtered_rows}</div>
    <div class="summary">
      <h3>المخططات الأساسية المدرجة كاملة</h3>
      <ul>{toc_primary}</ul>
    </div>
  </div>
  <div class="group-break"><h1>المخططات الكهربائية الأساسية كاملة</h1></div>
  {primary_sections}
  <div class="group-break"><h1>فهرس إضافي لكل القطع المرتبطة بالكهرباء عبر الكتالوج</h1></div>
  <div class="page cover">
    <h1>فهرس القطع المطابقة</h1>
    <div class="en-title">Rows matching: HARNESS / WIRE / CONNECTOR / SWITCH / RELAY / SENSOR / SOLENOID / LAMP / BULB / TERMINAL</div>
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
