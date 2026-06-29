from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "work" / "partsouq_full" / "units_structured.json"
DIAGRAMS = ROOT / "work" / "partsouq_full" / "diagrams_colored"
OUT_DIR = ROOT / "outputs" / "extracted_parts"
OUT_HTML = OUT_DIR / "patrol_y60_mechanical_complete_card.html"


GROUPS = {
    "المحرك والوقود والهواء والتحكم": list(range(0, 12)) + [17, 18, 19, 20, 21, 22],
    "العادم وتبريد المحرك": [12, 13, 14, 15, 16],
    "الكلتش والقير العادي والدبل": [62, 63, 64, 65, 66, 67, 68, 81, 82, 83, 84, 86, 87, 88, 89],
    "وحدات القير الأوتوماتيك الموجودة في الكتالوج": [69, 70, 71, 73, 75, 77, 78, 79, 80, 91],
    "الدفرنسات والمحاور والدبل لوك": [92, 93, 94, 95, 96, 97, 98],
    "الفرامل والدواسات والسيرفو": [99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114],
    "الدركسون والباور": [115, 116, 118, 119, 120, 121, 122, 123, 124, 125],
    "ملحق ميكانيكي": [90, 126],
}


AR_TITLES = {
    "CARBURETOR; ASSEMBLY": "الكربريتر - مجموعة كاملة",
    "CARBURETOR; COMPONENT PARTS (PART 1)": "قطع الكربريتر الداخلية - الجزء الأول",
    "CARBURETOR; COMPONENT PARTS (PART 2)": "قطع الكربريتر الداخلية - الجزء الثاني",
    "CARBURETOR REPAIR KIT": "طقم إصلاح الكربريتر",
    "FUEL STRAINER & FUEL HOSE": "فلتر وخراطيم الوقود",
    "AIR CLEANER": "علبة فلتر الهواء",
    "FUEL PUMP": "طرمبة الوقود",
    "FUEL TANK": "خزان الوقود",
    "FUEL PIPING; PIPING": "مواسير الوقود",
    "FUEL PIPING; CLIP": "مشابك ومثبتات مواسير الوقود",
    "ACCELERATOR LINKAGE": "روابط ودواسة الدعسة",
    "EXHAUST TUBE & MUFFLER": "الشكمان والدبة",
    "WATER PUMP, COOLING FAN & THERMOSTAT": "طرمبة الماء والمروحة والثرموستات",
    "OIL COOLER": "مبرد الزيت",
    "RADIATOR,SHROUD & INVERTER COOLING; RADIATOR ASSY": "الرديتر - مجموعة كاملة",
    "RADIATOR,SHROUD & INVERTER COOLING; RADIATOR FITTING PARTS": "تركيبات الرديتر والهواء",
    "IGNITION SYSTEM": "نظام الإشعال",
    "DISTRIBUTOR & IGNITION TIMING SENSOR; MITSUBISHI": "الديلكو وحساس توقيت الإشعال",
    "ENGINE CONTROL VACUUM PIPING": "ليات فاكيوم تحكم المحرك",
    "ALTERNATOR FITTING": "تثبيت الدينمو",
    "ALTERNATOR; HITACHI": "الدينمو - هيتاشي",
    "STARTER MOTOR; HITACHI": "السلف - هيتاشي",
    "CLUTCH COVER,DISC & RELEASE PARTS": "صحن ودسك وفحمة الكلتش",
    "CLUTCH MASTER CYLINDER; WITHOUT CLUTCH BOOSTER": "ماستر الكلتش بدون بوستر",
    "CLUTCH MASTER CYLINDER; WITH CLUTCH BOOSTER": "ماستر الكلتش مع بوستر",
    "CLUTCH OPERATING CYLINDER": "سلندر تشغيل الكلتش",
    "CLUTCH PIPING": "مواسير وليّات الكلتش",
    "AUTO TRANSMISSION,TRANSAXLE & FITTING; TRANSMISSION ASSEMBLY": "القير الأوتوماتيك - مجموعة كاملة",
    "AUTO TRANSMISSION,TRANSAXLE & FITTING; T/M TO ENG. FITTING": "تثبيت القير الأوتوماتيك بالمحرك",
    "TORQUE CONVERTER,HOUSING & CASE": "محول العزم وبيت القير الأوتوماتيك",
    "OIL PUMP": "طرمبة زيت القير الأوتوماتيك",
    "CLUTCH & BAND SERVO; SERVO & REVERSE CLUTCH": "سيرفو وباندات القير الأوتوماتيك",
    "CLUTCH & BAND SERVO; ACCUMULATER PARTS": "أجزاء الأكيوميوليتر للقير الأوتوماتيك",
    "CONTROL VALVE (ATM); UPPER": "بلوف تحكم القير الأوتوماتيك - علوي",
    "CONTROL VALVE (ATM); LOWER": "بلوف تحكم القير الأوتوماتيك - سفلي",
    "CONTROL SWITCH & SYSTEM": "مفاتيح ونظام تحكم القير الأوتوماتيك",
    "AUTO TRANSMISSION CONTROL DEVICE": "جهاز تحكم القير الأوتوماتيك",
    "MANUAL TRANSMISSION, TRANSAXLE & FITTING": "القير العادي FS5R50A والتثبيت",
    "TRANSMISSION CASE & CLUTCH RELEASE": "بيت القير وفحمة الكلتش",
    "TRANSMISSION GEAR; MAIN GEAR": "تروس القير العادي",
    "TRANSMISSION SHIFT CONTROL": "تحكم وتعشيق القير العادي",
    "TRANSFER ASSEMBLY & FITTING": "الدبل - مجموعة كاملة وتثبيت",
    "TRANSFER CASE": "بيت الدبل",
    "TRANSFER GEAR": "تروس وسلسلة الدبل",
    "TRANSFER SHIFT LEVER,FORK & CONTROL": "عصا وشوك وتحكم الدبل",
    "WINCH; WINCH COMPL (MACHANICAL)": "الونش الميكانيكي",
    "REAR FINAL DRIVE; 4 PINION (HG)(H233B 4PI)": "الدفرنس الخلفي HG H233B - أربع تروس",
    "REAR FINAL DRIVE; L.S.D (HG)(H233B LSD)": "الدفرنس الخلفي LSD",
    "REAR FINAL DRIVE; DIFF LOCK (HG)(H233B DIFF LOCK)": "الدفرنس الخلفي دفرنس لوك",
    "REAR FINAL DRIVE; (HH)(H260 4PI)": "الدفرنس الخلفي H260",
    "FRONT FINAL DRIVE; (HG)(H23B 2PI)": "الدفرنس الأمامي",
    "DIFF LOCK CONTROL": "تحكم الدفرنس لوك",
    "FRONT AXLE; NO.1": "الأكسل الأمامي",
    "FRONT BRAKE; STD": "فرامل أمامية قياسية",
    "FRONT BRAKE; BRAKE DISC W/LARGE ROTOR": "فرامل أمامية دسك كبير",
    "REAR BRAKE; DRUM BRAKE": "فرامل خلفية هوبات",
    "REAR BRAKE; DISC BRAKE": "فرامل خلفية دسك",
    "CENTER BRAKE": "فرامل الوسط / الدبل",
    "PARKING BRAKE CONTROL": "تحكم فرامل اليد",
    "BRAKE MASTER CYLINDER": "ماستر الفرامل",
    "BRAKE & CLUTCH PEDAL": "دواسات الفرامل والكلتش",
    "BRAKE SERVO & SERVO CONTROL; WITHOUT CLUTCH BOOSTER": "بوستر الفرامل بدون بوستر كلتش",
    "BRAKE SERVO & SERVO CONTROL; WITH CLUTCH BOOSTER": "بوستر الفرامل مع بوستر كلتش",
    "BRAKE SERVO & SERVO CONTROL; W/OUT CLUTCH SERVO +W/OUT RR DIFF LOCK": "بوستر الفرامل بدون سيرفو كلتش وبدون دفرنس لوك خلفي",
    "BRAKE SERVO & SERVO CONTROL; F/CLUTCH SERVO": "بوستر الفرامل مع سيرفو الكلتش",
    "BRAKE SERVO & SERVO CONTROL; F/CLUTCH SERVO +F/RR DIFF LOCK": "بوستر الفرامل مع سيرفو الكلتش ودفرنس لوك",
    "BRAKE SERVO & SERVO CONTROL; F/RR DIFF LOCK": "بوستر الفرامل مع دفرنس لوك",
    "STEERING WHEEL; 2SPOKE,3SPOKE": "طارة الدركسون",
    "STEERING LINKAGE": "روابط الدركسون",
    "STEERING COLUMN; WITHOUT TILT": "عامود الدركسون بدون إمالة",
    "POWER STEERING PUMP": "طرمبة الباور",
    "POWER STEERING GEAR": "علبة الدركسون الباور",
    "POWER STEERING PUMP MOUNTING": "تثبيت طرمبة الباور",
    "POWER STEERING PIPING": "مواسير وليّات الباور",
    "POWER STEERING PIPING; F/POWER STEERING": "مواسير وليّات الدركسون الباور",
    "SPARE TIRE HANGER": "حامل الاستبنة",
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
    uid = str(unit.get("uid", ""))
    ar_title = AR_TITLES.get(title, title)
    rows = rows_for(unit)
    img = diagram_path(index, uid)
    img_html = f'<img src="file:///{img}" alt="{esc(title)}">' if img else "<div class='missing'>لا توجد صورة مخطط محفوظة لهذه الوحدة</div>"
    return f"""
    <section class="unit">
      <div class="intro">
        <div class="unit-head">
          <div>
            <h2>{esc(ar_title)}</h2>
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
    selected = [idx for indexes in GROUPS.values() for idx in indexes]
    total_rows = sum(len(rows_for(data[idx])) for idx in selected)

    toc = []
    for group, indexes in GROUPS.items():
        toc.append(f"<h3>{esc(group)}</h3><ul>")
        for idx in indexes:
            unit = data[idx]
            title = unit.get("title", "")
            toc.append(
                f"<li><span>{esc(AR_TITLES.get(title, title))}</span>"
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
  <title>Nissan Patrol Y60 Mechanical Complete Catalog</title>
  <style>
    @page {{ size: A4 portrait; margin: 9mm; }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      background: #f0eadf;
      color: #211b16;
      font-family: Arial, "Segoe UI", Tahoma, sans-serif;
      font-size: 13px;
    }}
    .page {{
      background: #fffdf8;
      border: 3px solid #81603a;
      padding: 22px;
      min-height: 100vh;
    }}
    .cover {{ page-break-after: always; text-align: center; }}
    .cover h1 {{
      margin: 18px 0 8px;
      color: #7a1e2e;
      font-size: 30px;
      line-height: 1.35;
    }}
    .en-title {{
      direction: ltr;
      color: #14598d;
      font-weight: 900;
      font-size: 18px;
      margin-bottom: 18px;
    }}
    .vehicle {{
      margin: 14px auto;
      max-width: 760px;
      border-collapse: collapse;
      font-size: 15px;
      text-align: right;
    }}
    .vehicle td {{
      border: 1px solid #d4c2ad;
      padding: 8px 10px;
      background: #fff8ee;
      font-weight: 700;
    }}
    .vehicle td:first-child {{
      width: 35%;
      background: #7a1e2e;
      color: white;
    }}
    .badge {{
      display: inline-block;
      padding: 9px 15px;
      margin: 7px;
      background: #edf7fb;
      border: 2px solid #c5d9e7;
      color: #14598d;
      font-weight: 900;
      font-size: 16px;
    }}
    .summary {{
      margin: 14px auto;
      max-width: 790px;
      text-align: right;
    }}
    .summary h3 {{
      margin: 13px 0 6px;
      color: #7a1e2e;
      font-size: 17px;
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
      padding: 6px 9px;
      background: #fff8ee;
      border-bottom: 1px solid #e1d3c1;
      font-weight: 700;
    }}
    .summary li:nth-child(even) {{ background: #f3e7d8; }}
    .note {{
      margin: 14px auto;
      max-width: 760px;
      background: #fff4d8;
      border: 1px solid #d6b56d;
      padding: 10px 12px;
      font-weight: 800;
      line-height: 1.7;
    }}
    .group-break {{
      page-break-before: always;
      background: #7a1e2e;
      color: white;
      text-align: center;
      padding: 13px;
      margin: 0 0 12px;
    }}
    .group-break h1 {{ margin: 0; font-size: 23px; }}
    .unit {{
      background: #fffdf8;
      border: 2px solid #b89062;
      padding: 11px;
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
      margin-bottom: 9px;
    }}
    h2 {{
      margin: 0;
      color: #7a1e2e;
      font-size: 19px;
      line-height: 1.35;
    }}
    .unit-sub {{ margin-top: 3px; font-size: 12px; }}
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
      margin-bottom: 9px;
    }}
    .diagram img {{
      max-width: 100%;
      max-height: 265px;
      object-fit: contain;
      image-rendering: auto;
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
      font-size: 10.3px;
      page-break-inside: auto;
    }}
    thead {{ display: table-header-group; }}
    tr {{ page-break-inside: avoid; break-inside: avoid; }}
    th {{
      background: #7a1e2e;
      color: white;
      border: 1px solid #d6c6b1;
      padding: 6px 5px;
      font-size: 10.3px;
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
    <h1>بطاقة شاملة لكل القطع الميكانيكية</h1>
    <div class="en-title">Nissan Patrol Safari Y60 - WGY60-348567 - Complete Mechanical Parts</div>
    <table class="vehicle">
      <tr><td>السيارة</td><td>نيسان باترول سفاري SGL Y60</td></tr>
      <tr><td>رقم الهيكل</td><td class="en">WGY60-348567</td></tr>
      <tr><td>الموديل</td><td class="en">WLGY60JFRC5</td></tr>
      <tr><td>الإنتاج</td><td class="en">10 / 1991</td></tr>
      <tr><td>المحرك</td><td class="en">TB42S - 4.2L Carburetor</td></tr>
      <tr><td>القير الأساسي للسيارة</td><td class="en">Manual FS5R50A</td></tr>
      <tr><td>الدفرنس</td><td class="en">HG41</td></tr>
      <tr><td>منهجية الحصر</td><td>تم إدراج وحدات المحرك والوقود والتبريد والعادم والكلتش والقير والدبل والدفرنسات والمحاور والفرامل والدركسون من ملف الكتالوج المستخرج للسيارة.</td></tr>
    </table>
    <div class="note">تنبيه: السيارة حسب بيانات الهيكل قير عادي، وتم فصل وحدات القير الأوتوماتيك في قسم مستقل لأنها ظاهرة داخل بيانات الكتالوج، وليست الأساس لسيارتك.</div>
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
