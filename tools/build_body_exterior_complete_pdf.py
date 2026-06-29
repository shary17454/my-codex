from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "work" / "partsouq_full" / "units_structured.json"
DIAGRAMS = ROOT / "work" / "partsouq_full" / "diagrams_colored"
OUT_DIR = ROOT / "outputs" / "extracted_parts"
OUT_HTML = OUT_DIR / "patrol_y60_body_exterior_complete_card.html"


GROUPS = {
    "الواجهة والهيكل الأمامي": [127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 145],
    "السقف والجوانب والهيكل الخارجي": [146, 151, 152, 153, 155, 156, 157, 158, 159, 160, 161, 163, 164, 166, 209, 210],
    "الأبواب والزجاج والأقفال": [167, 168, 169, 171, 172, 173, 175, 176, 202, 203, 206, 207, 208],
    "الخلفية والصدامات والحوامل": [126, 178],
    "الخطوط والشعارات والملحقات الخارجية": [216, 217, 218, 219, 220, 221, 222],
}

AR_TITLES = {
    "SPARE TIRE HANGER": "حامل الاستبنة",
    "FRONT BUMPER; GUARD FRONT": "الصدام الأمامي / الحماية الأمامية",
    "FRONT BUMPER; BUMPER STD": "الصدام الأمامي القياسي",
    "FRONT BUMPER; BUMPER F/FR WINCH": "الصدام الأمامي مع تجهيز الونش",
    "FRONT GRILLE": "شبك الواجهة",
    "FRONT APRON & RADIATOR CORE SUPPORT; NO.1": "دعامة الواجهة وحامل الرديتر - 1",
    "FRONT APRON & RADIATOR CORE SUPPORT": "دعامة الواجهة وحامل الرديتر",
    "FRONT FENDER & FITTING": "الرفرف الأمامي وتوابعه",
    "HOOD LEDGE & FITTING; HOODLEDGE PANEL & FITTING": "لوح حافة الكبوت وتثبيته",
    "HOOD LEDGE & FITTING; ENGINE ROOM PLUG": "سدادات حافة الكبوت وغرفة المحرك",
    "HOOD PANEL,HINGE & FITTING": "الكبوت والمفصلات والتثبيت",
    "HOOD LOCK CONTROL": "قفل الكبوت وتحكمه",
    "COWL TOP & FITTING": "غطاء أسفل الزجاج الأمامي",
    "DASH PANEL & FITTING": "لوح الداش المعدني وتثبيته",
    "FRONT WINDSHIELD": "الزجاج الأمامي",
    "ROOF PANEL & FITTING": "صاج السقف وتثبيته",
    "FLOOR PANEL": "صاج الأرضية الأمامي",
    "FLOOR PANEL (REAR)": "صاج الأرضية الخلفي",
    "FLOOR FITTING": "تثبيتات الأرضية",
    "BODY SIDE PANEL": "صاج الجنب",
    "BODY SIDE MOULDING; ROOF TOP": "ديكور سقف خارجي",
    "BODY SIDE MOULDING; BODY SIDE": "ديكور الجوانب الخارجي",
    "BODY SIDE FITTING; OVER FENDER & FITTING": "أوفر فندر وتثبيته",
    "BODY SIDE FITTING; SIDE STEP": "الخطوة الجانبية",
    "BODY SIDE FITTING; MAT GUARD & OTHER": "بطانات الرفارف والواقيات",
    "REAR FENDER & FITTING": "الرفرف الخلفي وتوابعه",
    "REAR WINDOW": "الزجاج الخلفي",
    "BODY MOUNTING": "جلد وقواعد تثبيت البدي",
    "REAR VIEW MIRROR; OUTSIDE MIRROR": "المرايات الخارجية",
    "FRONT DOOR PANEL & FITTING": "باب أمامي وصاجه",
    "FRONT DOOR WINDOW & REGULATOR": "زجاج الباب الأمامي ومنظمته",
    "FRONT DOOR LOCK & HANDLE": "قفل ومقبض الباب الأمامي",
    "REAR DOOR PANEL & FITTING": "باب خلفي جانبي وصاجه",
    "REAR DOOR WINDOW & REGULATOR": "زجاج الباب الخلفي ومنظمته",
    "REAR DOOR LOCK & HANDLE": "قفل ومقبض الباب الخلفي",
    "SIDE WINDOW": "زجاج جانبي",
    "BACK DOOR PANEL & FITTING": "باب الشنطة وصاجه",
    "BACK DOOR LOCK & HANDLE": "قفل ومقبض باب الشنطة",
    "REAR BODY SIDE GATE & FITTING": "بوابة جانبية خلفية وتثبيتها",
    "REAR BODY FLOOR & FITTING": "أرضية الخلفية وتثبيتها",
    "REAR BODY REAR GATE & FITTING": "البوابة الخلفية وتثبيتها",
    "REAR BUMPER": "الصدام الخلفي",
    "ACCENT STRIPE": "الخطوط الجانبية",
    "EMBLEM & NAME LABEL": "الشعارات واللواصق الاسمية",
    "CAUTION PLATE & LABEL": "لوحات وتحذيرات المصنع",
    "TOOL KIT & MAINTENANCE MANUAL": "عدة السيارة وكتالوج الصيانة",
    "KEY SET & BLANK KEY": "طقم المفتاح والبلانك",
    "TOUCH UP PAINT": "بخاخ / قلم رتوش اللون",
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
    selected = [idx for indexes in GROUPS.values() for idx in indexes if len(rows_for(data[idx]))]
    total_rows = sum(len(rows_for(data[idx])) for idx in selected)

    toc = []
    for group, indexes in GROUPS.items():
        toc.append(f"<h3>{esc(group)}</h3><ul>")
        for idx in indexes:
            rows = rows_for(data[idx])
            if not rows:
                continue
            title = data[idx].get("title", "")
            toc.append(
                f"<li><span>{esc(AR_TITLES.get(title, title))}</span>"
                f"<b class='en'>{len(rows)} rows</b></li>"
            )
        toc.append("</ul>")

    sections = []
    for group, indexes in GROUPS.items():
        sections.append(f'<div class="group-break"><h1>{esc(group)}</h1></div>')
        for idx in indexes:
            if rows_for(data[idx]):
                sections.append(section_html(idx, data[idx]))

    html_text = f"""<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>Nissan Patrol Y60 Body Exterior Complete Catalog</title>
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
    <h1>بطاقة شاملة للبدي والأجزاء الخارجية</h1>
    <div class="en-title">Nissan Patrol Safari Y60 - WGY60-348567 - Body / Exterior / Doors / Glass / Bumpers</div>
    <table class="vehicle">
      <tr><td>السيارة</td><td>نيسان باترول سفاري SGL Y60</td></tr>
      <tr><td>رقم الهيكل</td><td class="en">WGY60-348567</td></tr>
      <tr><td>الموديل</td><td class="en">WLGY60JFRC5</td></tr>
      <tr><td>الإنتاج</td><td class="en">10 / 1991</td></tr>
      <tr><td>اللون الخارجي</td><td class="en">2L3</td></tr>
      <tr><td>منهجية الحصر</td><td>تم إدراج وحدات البدي، الواجهة، الكبوت، الرفارف، الزجاج، الأبواب، الأقفال، الصدامات، الخطوط الخارجية، الشعارات، والمرايات الخارجية من ملف الكتالوج المستخرج للسيارة.</td></tr>
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
