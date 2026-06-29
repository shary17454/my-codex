from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "outputs" / "extracted_parts"
OUT_HTML = OUT_DIR / "patrol_y60_vehicle_profile_card.html"

EXTERIOR_IMG = Path(
    r"C:\Users\safwa\.codex\codex-remote-attachments\019ee069-f5a1-7541-9599-811490c5a275\F2CF9B0E-9D28-4D35-80B8-B38BCC60F873\4-صورة-مُلصقة-1.jpg"
)
INTERIOR_IMG = Path(
    r"C:\Users\safwa\.codex\codex-remote-attachments\019ee069-f5a1-7541-9599-811490c5a275\F2CF9B0E-9D28-4D35-80B8-B38BCC60F873\5-صورة-مُلصقة-1.jpg"
)
PLATE_IMG = Path(
    r"C:\Users\safwa\.codex\codex-remote-attachments\019ee069-f5a1-7541-9599-811490c5a275\ACB79E13-1187-4F68-A17C-3243DF852AE0\1-صورة-مُلصقة-1.jpg"
)


def uri(path: Path) -> str:
    return path.resolve().as_posix()


def build() -> None:
    html_text = f"""<!doctype html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <title>Patrol Y60 Vehicle Profile Card</title>
  <style>
    @page {{ size: A4 portrait; margin: 10mm; }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      background: #efe9de;
      color: #201b18;
      font-family: Arial, "Segoe UI", Tahoma, sans-serif;
      font-size: 13px;
    }}
    .page {{
      background: #fffdf8;
      border: 3px solid #8b6438;
      padding: 14px;
      min-height: 100vh;
    }}
    .hero {{
      width: 100%;
      border: 1px solid #d7c7b3;
      overflow: hidden;
      margin-bottom: 10px;
    }}
    .hero img {{
      width: 100%;
      display: block;
      max-height: 240px;
      object-fit: cover;
    }}
    h1 {{
      margin: 0 0 6px;
      color: #7a1e2e;
      font-size: 27px;
      line-height: 1.35;
      text-align: center;
    }}
    .subtitle {{
      direction: ltr;
      text-align: center;
      color: #14598d;
      font-size: 16px;
      font-weight: 900;
      margin-bottom: 10px;
    }}
    .grid {{
      display: grid;
      grid-template-columns: 1.1fr 0.9fr;
      gap: 10px;
    }}
    .panel {{
      border: 2px solid #b89162;
      background: #fffaf2;
      padding: 10px;
      margin-bottom: 10px;
    }}
    .panel h2 {{
      margin: 0 0 8px;
      color: #7a1e2e;
      font-size: 17px;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
    }}
    td {{
      border: 1px solid #d7c7b3;
      padding: 6px 7px;
      vertical-align: top;
      background: #fff8ee;
      font-weight: 700;
    }}
    td:first-child {{
      width: 36%;
      background: #7a1e2e;
      color: white;
    }}
    ul {{
      list-style: none;
      padding: 0;
      margin: 0;
    }}
    li {{
      padding: 5px 7px;
      border-bottom: 1px solid #e6d7c4;
      background: #fff8ee;
      font-weight: 700;
      line-height: 1.45;
    }}
    li:nth-child(even) {{ background: #f3e6d6; }}
    .en {{
      direction: ltr;
      unicode-bidi: embed;
      color: #14598d;
      font-weight: 900;
    }}
    .note {{
      margin-top: 8px;
      border: 1px solid #d6b56d;
      background: #fff4d8;
      padding: 8px 10px;
      font-weight: 800;
      line-height: 1.55;
    }}
    .proof-grid {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 14px;
      margin-top: 12px;
    }}
    .photo-card {{
      border: 2px solid #b89162;
      background: #fffaf2;
      padding: 10px;
      page-break-inside: avoid;
    }}
    .photo-card img {{
      width: 100%;
      display: block;
      max-height: 300px;
      object-fit: contain;
      background: white;
      border: 1px solid #d7c7b3;
    }}
    .caption {{
      margin-top: 8px;
      color: #7a1e2e;
      font-weight: 900;
      text-align: center;
    }}
    .page-break {{
      page-break-before: always;
    }}
  </style>
</head>
<body>
  <div class="page">
    <div class="hero"><img src="file:///{uri(EXTERIOR_IMG)}" alt="Patrol Y60 exterior"></div>
    <h1>بطاقة تعريف السيارة</h1>
    <div class="subtitle">Nissan Patrol Safari Y60 SGL - TB42 - Manual 5 Speed - Long Wheel Base - Japan Spec</div>
    <div class="grid">
      <div>
        <div class="panel">
          <h2>البيانات الأساسية</h2>
          <table>
            <tr><td>الاسم</td><td>نيسان سفاري SGL (Y60)</td></tr>
            <tr><td>رقم الهيكل / الشاصي</td><td class="en">WGY60-348567</td></tr>
            <tr><td>رقم الموديل</td><td class="en">WLGY60JFRC5</td></tr>
            <tr><td>تاريخ الإنتاج</td><td class="en">10 / 1991</td></tr>
            <tr><td>موديل الاستمارة</td><td class="en">1992</td></tr>
            <tr><td>بلد الصنع</td><td>اليابان</td></tr>
            <tr><td>السوق</td><td>الخليج / السعودية</td></tr>
            <tr><td>المقود</td><td class="en">LHD</td></tr>
            <tr><td>الهيكل</td><td>Wagon طويل - خمسة أبواب</td></tr>
          </table>
        </div>
        <div class="panel">
          <h2>المحرك ونقل الحركة</h2>
          <ul>
            <li><span class="en">TB42S</span> - ستة سلندر مستقيم - 4.2 لتر - بنزين - كربريتر</li>
            <li>قير عادي <span class="en">FS5R50A</span> - خمس سرعات</li>
            <li>دفرنس <span class="en">HG41</span></li>
            <li>رقم سعة المحرك على اللوحة: <span class="en">4169 cc</span></li>
          </ul>
        </div>
      </div>
      <div>
        <div class="panel">
          <h2>الألوان والتجهيزات</h2>
          <ul>
            <li>اللون الخارجي: <span class="en">2L3</span> - أحمر ذهبي</li>
            <li>اللون الداخلي: <span class="en">AH3</span> - عنابي</li>
            <li>قزاز كهربائي كامل</li>
            <li>ثلاجة أمامية داخلية</li>
            <li>ثلاجة خلفية أصلية</li>
            <li>مكيف خلفي مستقل</li>
            <li>لوحة تحكم للمكيف الخلفي</li>
            <li>غطاء <span class="en">COOL BOX</span> أصلي</li>
            <li>ساعة رقمية علوية</li>
            <li>عداد <span class="en">RPM</span> وحرارة وضغط زيت وشحن بطارية ووقود</li>
            <li>فرش وديكورات داخلية عنابية</li>
          </ul>
        </div>
      </div>
    </div>
  </div>

  <div class="page page-break">
    <h1>صور توثيقية</h1>
    <div class="subtitle">Vehicle reference photos and manufacturer plate</div>
    <div class="panel">
      <h2>معلومات مؤكدة من الكتالوج</h2>
      <ul>
        <li>المحرك <span class="en">TB42S</span></li>
        <li>الهيكل <span class="en">WGY60</span></li>
        <li>الإنتاج <span class="en">10/1991</span></li>
        <li>وجود <span class="en">Rear Cooler</span></li>
        <li>وجود <span class="en">Ice Box</span></li>
        <li>فئة السيارة <span class="en">SGL</span></li>
      </ul>
      <div class="note">هذه البطاقة مبنية على بيانات لوحة المصنع، الصور المرفقة، واستخراج كتالوج القطع الخاص بالهيكل <span class="en">WGY60-348567</span>.</div>
    </div>
    <div class="proof-grid">
      <div class="photo-card">
        <img src="file:///{uri(INTERIOR_IMG)}" alt="Patrol Y60 interior">
        <div class="caption">صورة داخلية مرجعية</div>
      </div>
      <div class="photo-card">
        <img src="file:///{uri(PLATE_IMG)}" alt="Manufacturer plate">
        <div class="caption">لوحة بيانات المصنع</div>
      </div>
    </div>
  </div>
</body>
</html>
"""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    OUT_HTML.write_text(html_text, encoding="utf-8")
    print(OUT_HTML)


if __name__ == "__main__":
    build()
