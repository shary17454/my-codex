from __future__ import annotations

import html
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CARD_DIR = ROOT / "outputs" / "extracted_parts"

CARD_FILES = [
    "patrol_y60_wiring_connectors_complete_card.html",
    "patrol_y60_body_exterior_complete_card.html",
    "patrol_y60_interior_trim_seats_complete_card.html",
    "patrol_y60_mechanical_complete_card.html",
    "patrol_y60_special_accessories_complete_card.html",
    "patrol_y60_hvac_coolers_vents_complete_card.html",
]

EXACT = {
    "AIR CLEANER": "منقي الهواء",
    "AIR CLEANER ELEMENT": "فلتر الهواء",
    "AIR CLEANER HOUSING COVER": "غطاء علبة فلتر الهواء",
    "BATTERY": "البطارية",
    "CARBURETOR": "الكربريتر",
    "CLOCK ASSY": "مجموعة الساعة",
    "COOLER BOX": "صندوق الثلاجة",
    "FUEL PUMP": "طرمبة الوقود",
    "FUEL TANK": "خزان الوقود",
    "RADIATOR": "الرديتر",
    "STARTER MOTOR": "السلف",
    "WIPER SWITCH": "مفتاح المساحات",
}

PHRASES = {
    "AIR CONDITIONER": "المكيف",
    "AIR DUCT": "دكت الهواء",
    "AUTO DOOR LOCK": "قفل الباب الكهربائي",
    "BACK DOOR": "الباب الخلفي",
    "BAROMETRIC PRESSURE SENSOR": "حساس الضغط الجوي",
    "BLOWER ASSY": "مجموعة مروحة الهواء",
    "BLOWER UNIT ASSY": "مجموعة وحدة مروحة الهواء",
    "BODY ASSY": "مجموعة الهيكل",
    "BRAKE MASTER CYLINDER": "ماستر الفرامل",
    "CENTER BRAKE": "فرامل الوسط",
    "CLUTCH MASTER CYLINDER": "ماستر الكلتش",
    "COMBINATION LAMP": "إضاءة مشتركة",
    "COOLING UNIT": "وحدة التبريد",
    "DIFF LOCK": "قفل الدفرنس",
    "DOOR LOCK": "قفل الباب",
    "FINAL DRIVE": "الدفرنس",
    "FRONT DOOR": "الباب الأمامي",
    "FRONT SEAT": "الكرسي الأمامي",
    "FRONT WINDOW": "النافذة الأمامية",
    "FUEL STRAINER": "فلتر الوقود",
    "HEATER UNIT": "وحدة الدفاية",
    "HOODLEDGE": "حافة الكبوت",
    "IGNITION COIL": "كويل الإشعال",
    "IGNITION SYSTEM": "نظام الإشعال",
    "INSTRUMENT PANEL": "لوحة الطبلون",
    "POWER STEERING": "الدركسون الباور",
    "REAR BODY": "الهيكل الخلفي",
    "REAR COOLER": "المكيف الخلفي",
    "REAR DOOR": "الباب الخلفي الجانبي",
    "REAR SEAT": "الكرسي الخلفي",
    "REAR WINDOW": "الزجاج الخلفي",
    "SEAT BELT": "حزام الأمان",
    "SPARE TIRE": "الاستبنة",
    "TRANSFER CASE": "علبة الدبل",
    "WASHER TANK": "خزان ماء المساحات",
    "WINDSHIELD WIPER": "مساحات الزجاج الأمامي",
}

TOKENS = {
    "A": "A",
    "ABSORBER": "ممتص",
    "ACTUATOR": "مشغل",
    "ADAPTER": "محول",
    "ADJUST": "تعديل",
    "ADJUSTER": "معدل",
    "AIR": "هواء",
    "AMPLIFIER": "مضخم",
    "ARM": "ذراع",
    "ARMATURE": "عضو دوار",
    "ARMREST": "مسند يد",
    "ASHTRAY": "طفاية",
    "ASSIST": "مساعد",
    "ASSY": "مجموعة",
    "AUTO": "آلي",
    "BACK": "خلفي",
    "BAFFLE": "حاجز",
    "BAG": "حقيبة",
    "BALL": "كرة",
    "BAND": "رباط",
    "BAR": "عمود",
    "BASE": "قاعدة",
    "BEARING": "رمان",
    "BELL": "جرس",
    "BELT": "حزام",
    "BLADE": "ريشة",
    "BLIND": "غطاء",
    "BLOCK": "بلوك",
    "BODY": "هيكل",
    "BOLT": "برغي",
    "BOOT": "جلدة",
    "BOW": "قوس",
    "BOX": "صندوق",
    "BRACE": "دعامة",
    "BRACKET": "حامل",
    "BRAKE": "فرامل",
    "BULB": "لمبة",
    "BUMPER": "صدام",
    "BUSH": "جلدة",
    "BUSHING": "جلدة",
    "CABLE": "كيبل",
    "CALIPER": "كليبر",
    "CAP": "غطاء",
    "CARRIER": "حامل",
    "CASE": "بيت",
    "CENTER": "وسط",
    "CHAIN": "سلسلة",
    "CHAMBER": "حجرة",
    "CHECK": "فحص",
    "CHOKE": "تشوك",
    "CLAMP": "مشبك",
    "CLEANER": "منقي",
    "CLIP": "مشبك",
    "CLOCK": "ساعة",
    "CLUTCH": "كلتش",
    "COIL": "كويل",
    "COLLAR": "جلبة",
    "COMPL": "كامل",
    "COMPRESSOR": "كمبروسر",
    "CONDENSER": "رديتر المكيف",
    "CONNECTING": "توصيل",
    "CONNECTOR": "فيش",
    "CONTROL": "تحكم",
    "COOLER": "ثلاجة/مبرد",
    "COOLING": "تبريد",
    "CORD": "سلك",
    "COVER": "غطاء",
    "CRANK": "كرنك",
    "CROSS": "عرضي",
    "CUSHION": "قاعدة كرسي",
    "CYLINDER": "سلندر",
    "DASH": "طبلون",
    "DISC": "دسك",
    "DOOR": "باب",
    "DUCT": "دكت",
    "ELEMENT": "فلتر",
    "ENGINE": "محرك",
    "EVAPORATOR": "ثلاجة المكيف",
    "EXHAUST": "عادم",
    "EXTENSION": "وصلة",
    "FAN": "مروحة",
    "FENDER": "رفرف",
    "FILTER": "فلتر",
    "FINAL": "نهائي",
    "FITTING": "تثبيت",
    "FIX": "تثبيت",
    "FLOAT": "عوامة",
    "FLOOR": "أرضية",
    "FOG": "ضباب",
    "FRAME": "فريم",
    "FRONT": "أمامي",
    "FUEL": "وقود",
    "GASKET": "وجه",
    "GAUGE": "عداد",
    "GEAR": "ترس/قير",
    "GLASS": "زجاج",
    "GRILLE": "شبك",
    "GRIP": "مسكة",
    "GUARD": "حماية",
    "HANDLE": "مقبض",
    "HANGER": "حامل",
    "HARNESS": "ظفيرة",
    "HEAD": "رأس",
    "HEATER": "دفاية",
    "HINGE": "مفصل",
    "HOLDER": "ماسك",
    "HOOD": "كبوت",
    "HOOK": "خطاف",
    "HOSE": "لي",
    "HOUSING": "بيت",
    "IDLER": "شداد",
    "INNER": "داخلي",
    "INSIDE": "داخلي",
    "INSULATOR": "عازل",
    "INTAKE": "سحب",
    "JOINT": "وصلة",
    "KIT": "طقم",
    "LAMP": "لمبة",
    "LEVER": "ذراع",
    "LID": "غطاء",
    "LIQUID": "سائل",
    "LINK": "وصلة",
    "LINKAGE": "روابط",
    "LOCK": "قفل",
    "LOWER": "سفلي",
    "MIRROR": "مراية",
    "MOLDING": "حلية",
    "MOTOR": "موتور",
    "MOUNTING": "تثبيت",
    "MUFFLER": "دبة الشكمان",
    "NO": "رقم",
    "NUT": "صامولة",
    "OIL": "زيت",
    "OPENER": "فتاحة",
    "OUTER": "خارجي",
    "PAD": "لبادة",
    "PANEL": "لوح/ديكور",
    "PARKING": "توقف",
    "PEDAL": "دعسة",
    "PIPE": "ماسورة",
    "PISTON": "بستم",
    "PLATE": "صفيحة",
    "PLUG": "سدادة",
    "PROTECTOR": "حماية",
    "PULLEY": "بكرة",
    "PUMP": "طرمبة",
    "RADIATOR": "رديتر",
    "REAR": "خلفي",
    "RECEIVER": "مجفف",
    "RELAY": "ريليه",
    "RESERVOIR": "خزان",
    "RESISTOR": "مقاومة",
    "RETAINER": "مثبت",
    "RETURN": "راجع",
    "ROD": "عمود",
    "ROOF": "سقف",
    "RUBBER": "ربل",
    "SCREW": "مسمار",
    "SEAL": "صوفة/جلدة",
    "SEAT": "كرسي",
    "SENSOR": "حساس",
    "SERVO": "سيرفو",
    "SET": "طقم",
    "SHAFT": "عمود",
    "SHIELD": "حاجز",
    "SIDE": "جانبي",
    "SPACER": "مباعد",
    "SPRING": "ياي",
    "STAY": "دعامة",
    "STEERING": "دركسون",
    "STOPPER": "محدد",
    "STRAINER": "فلتر",
    "STRAP": "حزام",
    "SUNVISOR": "شماسة",
    "SUPPORT": "حامل",
    "SWITCH": "مفتاح",
    "TANK": "خزان",
    "THERMO": "حراري",
    "THERMOSTAT": "ثرموستات",
    "TIRE": "كفر",
    "TOOL": "عدة",
    "TO": "إلى",
    "TRIM": "ديكور",
    "TUBE": "ماسورة",
    "UNIT": "وحدة",
    "UPPER": "علوي",
    "VALVE": "بلف",
    "VENT": "هواية",
    "VENTILATOR": "هواية",
    "WASHER": "وردة",
    "WATER": "ماء",
    "WEATHERSTRIP": "ربل عازل",
    "WHEEL": "عجلة",
    "WINCH": "ونش",
    "WINDOW": "نافذة",
    "WIRE": "سلك",
    "WIPER": "مساحة",
}


def translate_name(name: str) -> str:
    clean = html.unescape(name).strip()
    if not clean:
        return "غير مذكور في الكتالوج"
    upper = re.sub(r"\s+", " ", clean.upper()).strip()
    if upper in EXACT:
        return EXACT[upper]

    text = upper
    used: list[str] = []
    for key, value in sorted(PHRASES.items(), key=lambda item: len(item[0]), reverse=True):
        if key in text:
            used.append(value)
            text = text.replace(key, " ")

    pieces = [p for p in re.split(r"[\s,\-;/()+]+", text) if p]
    for piece in pieces:
        if piece in {"RH", "R"}:
            used.append("يمين")
        elif piece in {"LH", "L"}:
            used.append("يسار")
        elif piece in TOKENS:
            used.append(TOKENS[piece])
        elif re.fullmatch(r"\d+(ST|ND|RD|TH)?", piece):
            used.append(piece)
        elif len(piece) <= 3:
            used.append(piece)
        else:
            used.append(piece.title())

    result = " ".join(dict.fromkeys(used))
    return result or clean


def patch_headers(text: str) -> str:
    header = """
        <thead>
          <tr>
            <th>رقم المخطط</th>
            <th>رقم القطعة</th>
            <th>اسم القطعة بالعربي / الاسم الأصلي</th>
            <th>الكمية</th>
            <th>التطبيق / الملاحظة / التاريخ</th>
          </tr>
        </thead>
    """
    pattern = re.compile(
        r"<thead>\s*<tr>\s*"
        r"<th>.*?</th>\s*<th>.*?</th>\s*<th>.*?</th>\s*<th>.*?</th>\s*<th>.*?</th>\s*"
        r"</tr>\s*</thead>",
        re.S,
    )
    return pattern.sub(header, text)


def patch_css(text: str) -> str:
    if ".ar-name" in text:
        return text
    css = """
    .name-cell { color: #211b16; }
    .ar-name {
      direction: rtl;
      unicode-bidi: embed;
      color: #211b16;
      font-weight: 900;
      font-size: 11.2px;
      line-height: 1.35;
    }
    .en-name {
      display: block;
      margin-top: 3px;
      color: #14598d;
      font-size: 9.4px;
      line-height: 1.25;
    }
"""
    return text.replace("  </style>", css + "  </style>")


def patch_names(text: str) -> tuple[str, int]:
    count = 0

    def cell_for(original: str) -> str:
        arabic = translate_name(original)
        return (
            '<td class="name-cell">'
            f'<div class="ar-name">{html.escape(arabic)}</div>'
            f'<span class="en en-name">{html.escape(original) if original else "-"}</span>'
            "</td>"
        )

    def repl_original(match: re.Match[str]) -> str:
        nonlocal count
        original = html.unescape(match.group(1).strip())
        count += 1
        return cell_for(original)

    def repl_existing(match: re.Match[str]) -> str:
        nonlocal count
        original = html.unescape(match.group(1).strip())
        if original == "-":
            original = ""
        count += 1
        return cell_for(original)

    patched = re.sub(
        r'<td class="name-cell">.*?<span class="en en-name">(.*?)</span></td>',
        repl_existing,
        text,
        flags=re.S,
    )
    patched = re.sub(r'<td class="en name">(.*?)</td>', repl_original, patched, flags=re.S)
    return patched, count


def patch_card(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    text = patch_css(text)
    text = patch_headers(text)
    text, count = patch_names(text)
    path.write_text(text, encoding="utf-8")
    return count


def main() -> None:
    total = 0
    for filename in CARD_FILES:
        path = CARD_DIR / filename
        count = patch_card(path)
        total += count
        print(f"{filename}: {count} names translated")
    print(f"total: {total}")


if __name__ == "__main__":
    main()
