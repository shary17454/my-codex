from __future__ import annotations

import csv
import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DB = ROOT / "output" / "database" / "pre_y60"
OUT_MD = ROOT / "output" / "markdown" / "pre_y60"
OUT_PDF = ROOT / "output" / "pdf" / "pre_y60"


GENERATIONS = [
    {
        "generation": "4W60 / 4W Series",
        "arabic_generation": "سلسلة 4W60 / 4W",
        "approx_years": "1951-1960",
        "common_names": "Nissan Patrol, early Datsun/Nissan 4W Patrol",
        "arabic_names": "نيسان باترول المبكر / داتسون باترول في بعض الأسواق",
        "known_codes": "4W60, 4W61, 4W65, 4W66",
        "y_code": "No",
        "catalog_status": "Verification Required - official EPC/parts book source not yet supplied",
        "priority": "Archive/manual source required",
    },
    {
        "generation": "60 Series",
        "arabic_generation": "سلسلة 60",
        "approx_years": "1960-1980",
        "common_names": "Nissan Patrol 60, Datsun Patrol, Patrol G60",
        "arabic_names": "نيسان باترول 60 / داتسون باترول / باترول G60",
        "known_codes": "60, G60, L60, H60, KG60",
        "y_code": "No",
        "catalog_status": "Verification Required - official EPC/parts book source not yet supplied",
        "priority": "Archive/manual source required",
    },
    {
        "generation": "160 Series / MQ / MK",
        "arabic_generation": "سلسلة 160 / MQ / MK",
        "approx_years": "1980-1987 before Y60; continued later in some markets",
        "common_names": "Nissan Patrol 160, Datsun/Nissan Patrol MQ, Patrol MK, Nissan Safari",
        "arabic_names": "نيسان باترول 160 / باترول MQ / باترول MK / نيسان سفاري",
        "known_codes": "160, K160, V160, W160 and market variants",
        "y_code": "No generation-level Y code",
        "catalog_status": "Candidate for PartSouq/EPC extraction once source access is available",
        "priority": "First extraction target",
    },
    {
        "generation": "260 Series",
        "arabic_generation": "سلسلة 260",
        "approx_years": "1986-1990s depending on market",
        "common_names": "Nissan Patrol 260, Ebro Patrol in some Spanish/European contexts",
        "arabic_names": "نيسان باترول 260 / إيبرو باترول في بعض الأسواق الأوروبية",
        "known_codes": "260 and market variants",
        "y_code": "No generation-level Y code",
        "catalog_status": "Candidate for European/Spanish EPC extraction once source access is available",
        "priority": "Second extraction target",
    },
]


def esc(value: object) -> str:
    return html.escape(str(value or ""))


def write_csv() -> Path:
    OUT_DB.mkdir(parents=True, exist_ok=True)
    path = OUT_DB / "nissan_patrol_pre_y60_catalog_index.csv"
    with path.open("w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=list(GENERATIONS[0].keys()))
        writer.writeheader()
        writer.writerows(GENERATIONS)
    return path


def write_json() -> Path:
    OUT_DB.mkdir(parents=True, exist_ok=True)
    path = OUT_DB / "nissan_patrol_pre_y60_catalog_index.json"
    path.write_text(json.dumps(GENERATIONS, ensure_ascii=False, indent=2), encoding="utf-8")
    return path


def build_markdown() -> str:
    lines = [
        "# Nissan Patrol قبل Y60 - فهرس كتالوجات أولي",
        "",
        "هذا المستند لا يحتوي أرقام قطع أو مخططات غير موثقة. أي كتالوج قطع لم يتم استخراج مصدره الرسمي يوضع تحت `Verification Required`.",
        "",
        "This document does not fabricate part numbers or diagrams. Any catalog not extracted from an official/source page remains marked `Verification Required`.",
        "",
        "## هل كان يوجد رمز Y قبل 1988؟",
        "",
        "لا يوجد رمز جيل Y لباترول قبل Y60. الرموز المستخدمة قبل ذلك كانت مثل 4W60 وG60 و160 و260، مع تسميات سوقية مثل MQ/MK وSafari.",
        "",
        "| الجيل | السنوات التقريبية | الأسماء | الرموز | حالة الكتالوج |",
        "|---|---:|---|---|---|",
    ]
    for g in GENERATIONS:
        lines.append(
            f"| {g['generation']}<br>{g['arabic_generation']} | {g['approx_years']} | {g['common_names']}<br>{g['arabic_names']} | {g['known_codes']} | {g['catalog_status']} |"
        )
    lines.extend(
        [
            "",
            "## Extraction Priority / أولوية الاستخراج",
            "",
            "1. 160 Series / MQ / MK: أقرب جيل قبل Y60 وغالبا الأكثر توفرًا في قواعد EPC الإلكترونية.",
            "2. 260 Series: مهم للأسواق الأوروبية/الإسبانية.",
            "3. 60/G60 و4W60: غالبًا تحتاج كتب قطع مصورة أو مصادر أرشيفية وليست صفحات EPC حديثة.",
            "",
            "## Missing Source Report / تقرير المصادر الناقصة",
            "",
            "- Official Nissan parts book for 4W60: Verification Required.",
            "- Official Nissan parts book for 60/G60: Verification Required.",
            "- Official EPC/PartSouq category list for 160/MQ/MK: Verification Required.",
            "- Official EPC/PartSouq category list for 260: Verification Required.",
            "",
            "## Next Step",
            "",
            "افتح صفحة PartSouq أو مصدر EPC للجيل 160/MQ/MK أو 260، ثم يمكن تشغيل نفس آلية استخراج Y60 مع Queue جديد خاص بما قبل Y60.",
        ]
    )
    return "\n".join(lines) + "\n"


def write_markdown() -> Path:
    OUT_MD.mkdir(parents=True, exist_ok=True)
    path = OUT_MD / "nissan_patrol_pre_y60_catalog_index.md"
    path.write_text(build_markdown(), encoding="utf-8")
    return path


def write_html() -> Path:
    OUT_PDF.mkdir(parents=True, exist_ok=True)
    rows = []
    for g in GENERATIONS:
        rows.append(
            "<tr>"
            f"<td><strong>{esc(g['generation'])}</strong><br><span class='ar'>{esc(g['arabic_generation'])}</span></td>"
            f"<td>{esc(g['approx_years'])}</td>"
            f"<td>{esc(g['common_names'])}<br><span class='ar'>{esc(g['arabic_names'])}</span></td>"
            f"<td>{esc(g['known_codes'])}</td>"
            f"<td>{esc(g['y_code'])}</td>"
            f"<td>{esc(g['catalog_status'])}</td>"
            "</tr>"
        )
    html_text = f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Nissan Patrol Pre-Y60 Catalog Index</title>
<style>
@page {{ size: A4 landscape; margin: 10mm; }}
body {{ font-family: Arial, "Segoe UI", Tahoma, sans-serif; color: #172026; }}
.ar {{ direction: rtl; text-align: right; font-family: "Segoe UI", Tahoma, Arial, sans-serif; }}
h1 {{ color: #173f35; }}
table {{ width: 100%; border-collapse: collapse; table-layout: fixed; font-size: 10px; }}
th {{ background: #1f3f36; color: white; padding: 6px; text-align: left; }}
td {{ border: 1px solid #ccd6d2; padding: 6px; vertical-align: top; overflow-wrap: anywhere; }}
.notice {{ background: #fff8e5; border-left: 5px solid #986b00; padding: 10px; margin: 12px 0; }}
</style>
</head>
<body>
<h1>Nissan Patrol Before Y60 - Catalog Index</h1>
<div class="ar"><h1>نيسان باترول قبل Y60 - فهرس الكتالوجات</h1></div>
<div class="notice">
No part numbers or diagrams are fabricated in this file. Missing catalogs remain marked Verification Required.
<div class="ar">لا يتم اختراع أرقام قطع أو مخططات في هذا الملف. أي كتالوج غير مستخرج من مصدر رسمي يبقى تحت يتطلب التحقق.</div>
</div>
<h2>Was there a Y code before 1988?</h2>
<p>No generation-level Y code is used for the earlier Patrol generations listed here. The Y-series Patrol starts with Y60.</p>
<div class="ar"><h2>هل كان يوجد رمز Y قبل 1988؟</h2><p>لا يوجد رمز جيل Y للأجيال السابقة هنا. يبدأ رمز Y في باترول مع Y60.</p></div>
<table>
<thead><tr><th>Generation</th><th>Years</th><th>Names</th><th>Known Codes</th><th>Y Code?</th><th>Catalog Status</th></tr></thead>
<tbody>{''.join(rows)}</tbody>
</table>
<h2>Extraction Priority</h2>
<ol>
<li>160 Series / MQ / MK</li>
<li>260 Series</li>
<li>60/G60 and 4W60 archive parts books</li>
</ol>
</body></html>"""
    path = OUT_PDF / "nissan_patrol_pre_y60_catalog_index.html"
    path.write_text(html_text, encoding="utf-8")
    return path


def main() -> None:
    paths = {
        "csv": str(write_csv()),
        "json": str(write_json()),
        "markdown": str(write_markdown()),
        "html": str(write_html()),
    }
    print(json.dumps(paths, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
