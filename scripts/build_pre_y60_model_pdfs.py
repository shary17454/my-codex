from __future__ import annotations

import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "pdf" / "pre_y60" / "models"


MODELS = [
    {
        "slug": "4w60_4w_series",
        "title": "Nissan Patrol 4W60 / 4W Series",
        "ar_title": "نيسان باترول سلسلة 4W60 / 4W",
        "years": "1951-1960",
        "names": "Nissan Patrol, early Datsun/Nissan 4W Patrol",
        "ar_names": "نيسان باترول المبكر / داتسون باترول في بعض الأسواق",
        "codes": "4W60, 4W61, 4W65, 4W66",
        "y_code": "No Y generation code",
        "ar_y_code": "لا يوجد رمز جيل Y",
        "extraction_target": "Original printed Nissan/Datsun parts book or archive EPC scan required.",
        "ar_extraction_target": "يلزم كتاب قطع نيسان/داتسون الأصلي المطبوع أو مسح أرشيفي موثق.",
    },
    {
        "slug": "60_g60_series",
        "title": "Nissan Patrol 60 / G60 Series",
        "ar_title": "نيسان باترول سلسلة 60 / G60",
        "years": "1960-1980",
        "names": "Nissan Patrol 60, Datsun Patrol, Patrol G60",
        "ar_names": "نيسان باترول 60 / داتسون باترول / باترول G60",
        "codes": "60, G60, L60, H60, KG60",
        "y_code": "No Y generation code",
        "ar_y_code": "لا يوجد رمز جيل Y",
        "extraction_target": "Original parts catalog or verified EPC scan required.",
        "ar_extraction_target": "يلزم كتالوج قطع أصلي أو مسح EPC موثق.",
    },
    {
        "slug": "160_mq_mk_series",
        "title": "Nissan Patrol 160 Series / MQ / MK",
        "ar_title": "نيسان باترول سلسلة 160 / MQ / MK",
        "years": "1980-1987 before Y60; continued later in some markets",
        "names": "Nissan Patrol 160, Datsun/Nissan Patrol MQ, Patrol MK, Nissan Safari",
        "ar_names": "نيسان باترول 160 / داتسون أو نيسان باترول MQ / باترول MK / نيسان سفاري",
        "codes": "160, K160, V160, W160 and market variants",
        "y_code": "No generation-level Y code",
        "ar_y_code": "لا يوجد رمز Y كجيل؛ الرموز المستخدمة 160 ومشتقاتها",
        "extraction_target": "Best first candidate for PartSouq/FAST extraction when access is available.",
        "ar_extraction_target": "أفضل هدف أول للاستخراج من PartSouq/FAST عند توفر الوصول.",
    },
    {
        "slug": "260_series",
        "title": "Nissan Patrol 260 Series",
        "ar_title": "نيسان باترول سلسلة 260",
        "years": "1986-1990s depending on market",
        "names": "Nissan Patrol 260, Ebro Patrol in some Spanish/European contexts",
        "ar_names": "نيسان باترول 260 / إيبرو باترول في بعض الأسواق الإسبانية والأوروبية",
        "codes": "260 and market variants",
        "y_code": "No generation-level Y code",
        "ar_y_code": "لا يوجد رمز Y كجيل",
        "extraction_target": "European/Spanish EPC or verified parts catalog source required.",
        "ar_extraction_target": "يلزم مصدر EPC أوروبي/إسباني أو كتالوج قطع موثق.",
    },
]


def esc(value: object) -> str:
    return html.escape(str(value or ""))


def build_html(model: dict) -> str:
    rows = [
        ("English Name", "الاسم الإنجليزي", model["title"]),
        ("Arabic Name", "الاسم العربي", model["ar_title"]),
        ("Approximate Years", "السنوات التقريبية", model["years"]),
        ("Common Names", "الأسماء الشائعة", f"{model['names']}<br><span class='ar'>{model['ar_names']}</span>"),
        ("Known Codes", "الرموز المعروفة", model["codes"]),
        ("Y Code Status", "حالة رمز Y", f"{model['y_code']}<br><span class='ar'>{model['ar_y_code']}</span>"),
        ("Required Source", "المصدر المطلوب", f"{model['extraction_target']}<br><span class='ar'>{model['ar_extraction_target']}</span>"),
    ]
    table_rows = "".join(
        f"<tr><th>{esc(en)}<br><span class='ar'>{esc(ar)}</span></th><td>{value}</td></tr>"
        for en, ar, value in rows
    )
    missing_rows = "".join(
        f"<tr><td>{esc(item)}</td><td>Verification Required<br><span class='ar'>يتطلب التحقق</span></td></tr>"
        for item in [
            "Original EPC/parts catalog source",
            "Original catalog plate list",
            "Exploded diagrams",
            "Nissan part numbers",
            "VIN/date applicability",
            "Supersession and replacement numbers",
            "Market-specific differences",
        ]
    )
    return f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>{esc(model['title'])}</title>
<style>
@page {{ size: A4; margin: 12mm; }}
body {{ font-family: Arial, "Segoe UI", Tahoma, sans-serif; color: #172026; line-height: 1.35; }}
.ar {{ direction: rtl; text-align: right; font-family: "Segoe UI", Tahoma, Arial, sans-serif; }}
h1 {{ color: #173f35; margin-bottom: 4px; }}
h2 {{ color: #173f35; margin-top: 20px; }}
table {{ width: 100%; border-collapse: collapse; table-layout: fixed; margin: 10px 0 16px; font-size: 11px; }}
th {{ width: 30%; background: #1f3f36; color: white; padding: 7px; text-align: left; vertical-align: top; }}
td {{ border: 1px solid #ccd6d2; padding: 7px; vertical-align: top; overflow-wrap: anywhere; }}
.notice {{ background: #fff8e5; border-left: 5px solid #986b00; padding: 10px; margin: 12px 0; }}
.ok {{ background: #eaf6f1; border-left: 5px solid #1f6b50; padding: 10px; margin: 12px 0; }}
</style>
</head>
<body>
<h1>{esc(model['title'])}</h1>
<div class="ar"><h1>{esc(model['ar_title'])}</h1></div>
<div class="notice">
This is a verified-source placeholder catalog, not a fabricated parts catalog. No part numbers or diagrams are invented.
<div class="ar">هذا ملف كتالوج مبدئي يعتمد قاعدة التحقق من المصدر، وليس كتالوج قطع مخترع. لم يتم إنشاء أي رقم قطعة أو مخطط من غير مصدر.</div>
</div>
<h2>Model Identity</h2>
<div class="ar"><h2>تعريف الموديل</h2></div>
<table>{table_rows}</table>
<h2>EPC Extraction Status</h2>
<div class="ar"><h2>حالة استخراج EPC</h2></div>
<table>
<thead><tr><th>Item<br><span class="ar">البند</span></th><th>Status<br><span class="ar">الحالة</span></th></tr></thead>
<tbody>{missing_rows}</tbody>
</table>
<div class="ok">
Recommended next action: open a verified PartSouq/FAST/EPC page for this generation, then run a generation-specific extraction queue.
<div class="ar">الخطوة التالية الموصى بها: فتح صفحة PartSouq/FAST/EPC موثقة لهذا الجيل، ثم تشغيل طابور استخراج خاص به.</div>
</div>
</body>
</html>"""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    for model in MODELS:
        path = OUT / f"{model['slug']}.html"
        path.write_text(build_html(model), encoding="utf-8")
        manifest.append({"slug": model["slug"], "html": str(path), "pdf": str(path.with_suffix(".pdf"))})
    (OUT / "pre_y60_model_pdf_manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"count": len(manifest), "out": str(OUT)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
