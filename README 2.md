<<<<<<< HEAD
# my-codex

مستودع شخصي لتجميع مشاريع وتجارب Codex وربطها مع GitHub.

يضم حالياً ملفات مشروع **Nissan Patrol Safari Y60 / Patrol Hub**، تطبيق iPhone أولي، تطبيق Flutter للويب وويندوز، وملفات توثيق للدردشات والملاحظات.

## Patrol Hub / Safari Y60

المشروع الحالي يضم:

- تطبيق Flutter قابل للتشغيل على الويب وويندوز ومجهز لاحقاً لأندرويد و iOS.
- تطبيق SwiftUI أولي لإدارة قطع `Nissan Patrol Safari Y60`.
- فهارس كتالوجات Y60 وملفات PDF الأصلية.
- بحث برقم القطعة أو الاسم العربي أو الاسم الإنجليزي.
- تصنيف حسب النظام: المحرك، القير والدبل، الكهرباء، التكييف، الداخلية، البدي، وغيرها.
- صفحات تفاصيل للنتائج مرتبطة بصفحات PDF الأصلية.
- واجهة ويب ثابتة بديلة تحت `patrol-hub-redesign/`.

## الملفات المهمة

- تطبيق Flutter: `flutter_y60_catalog/`
- تطبيق SwiftUI: `SafariY60Parts/`
- مشروع Xcode: `SafariY60Parts.xcodeproj`
- بيانات القطع لتطبيق iPhone: `SafariY60Parts/Resources/parts_seed.json`
- كتالوجات Y60: `flutter_y60_catalog/assets/catalog/pdfs/`
- فهارس البحث والأقسام: `flutter_y60_catalog/assets/catalog/search/`
- واجهة الويب البديلة: `patrol-hub-redesign/`
- أدوات توليد البيانات: `tools/`
- وثيقة المتطلبات: `PRODUCT_REQUIREMENTS_AR.md`

## تشغيل Flutter

```powershell
cd flutter_y60_catalog
C:\src\flutter\bin\flutter.bat run -d windows
```

لبناء نسخة الويب:

```powershell
cd flutter_y60_catalog
C:\src\flutter\bin\flutter.bat build web --release
```

## تشغيل تطبيق iPhone

1. افتح `SafariY60Parts.xcodeproj` على جهاز macOS فيه Xcode.
2. اختر iPhone Simulator أو جهاز iPhone فعلي.
3. شغّل التطبيق.

## تحديث بيانات القطع

إذا تغيّر مصدر بيانات القطع، شغّل أداة التوليد المناسبة من مجلد `tools/` ثم أعد بناء التطبيق.

## توثيق الدردشات

تم حفظ ملفات توثيق ومخرجات محادثات داخل:

- `docs/chat-history.md`
- `docs/chat-transcript-2026-06-29.md`
- `docs/life-assistant-chat-handoff.md`
- `docs/patrol-hub-chat-handoff.md`
- `docs/patrol-hub-full-description-ar.md`
- `nissan-patrol/`

## كتيب مرزوق بن حويد العضياني

تم نقل ودمج محتوى محادثة مشروع **كتيب مرزوق بن حويد بن وازع العضياني رحمه الله** إلى:

- [docs/marzouq-book/README.md](docs/marzouq-book/README.md)
- [docs/marzouq-book/chat-log.md](docs/marzouq-book/chat-log.md)
- [docs/marzouq-book/artifacts.md](docs/marzouq-book/artifacts.md)
- [docs/marzouq-book/requirements.txt](docs/marzouq-book/requirements.txt)

هذه الملفات تستخدم كمرجع لمتابعة العمل لاحقاً بدون فقدان سياق المشروع.

## بطل الدروب

تم نقل ودمج محتوى دردشة مشروع **بطل الدروب** لتطبيق كتالوج قطع نيسان باترول إلى هذا المستودع.

**Batal Al-Droob** is a bilingual Arabic/English Nissan Patrol parts catalog app focused first on the Y60 generation, with the UI structure prepared for Y61, Y62, and Y63.

### Current Scope

- Browser app with Arabic-first UI and English toggle.
- Nissan Patrol generation selector: Y60, Y61, Y62, Y63.
- Internal parts sections: engine, cooling, electrical, body, brakes, suspension, and fuel.
- Y60 parts database extracted from supplied PDF catalogs and stored in SQLite and JSON.
- Saudi Riyal and US Dollar price display.
- iOS WebView wrapper prepared under `ios/BatalAlDroob`.
- App Store metadata and review notes prepared under `app-store`.

### Main Files

- [docs/CHAT_HANDOFF_AR.md](docs/CHAT_HANDOFF_AR.md)
- `index.html`, `styles.css`, `app.js`: web app UI and behavior.
- `server.py`: local web server and SQLite API.
- `data/app_database.sqlite`: app database.
- `data/y60_app_catalog.json`: browser fallback catalog data.
- `scripts/`: extraction, audit, build, and sync tools.
- `ios/BatalAlDroob/`: iOS wrapper project.

### Run Locally

```bash
python3 server.py
```

Open:

```text
http://localhost:5005/?v=hierarchy-2
```

On a phone connected to the same network, use the Mac IP address shown by `ifconfig`, for example:

```text
http://172.20.10.3:5005/?v=hierarchy-2
```

### Data Status

- Y60: integrated and searchable.
- Y61: UI slot and extraction script started, but full integration requires readable Y61 PDF/FAST/EPC source files.
- Y62/Y63: UI generation cards prepared with images; detailed parts databases are not integrated yet.
=======
# اسأل الناس

تطبيق ويب عربي لفكرة "اسأل الناس": منصة صغيرة تتيح للمستخدم إنشاء مقارنة بين شيئين محددين أو أكثر، ثم يحصل على تصويت وتعليقات من أشخاص مهتمين بنفس المجال.

## الفكرة

بدل أن يسأل المستخدم سؤالًا عامًا، ينشئ مقارنة واضحة مثل:

- أشتري السيارة A أم السيارة B؟
- أقارن بين آيفون 16 وجالكسي S25.
- أي مطعم أنسب لعشاء عائلي؟
- أختار لابتوب خفيف أم جهاز أقوى للبرمجة؟

المقارنة تبدأ دائمًا بعنصرين أساسيين، ويمكن إضافة عناصر أكثر عند الحاجة.

## المميزات الحالية

- واجهة عربية كاملة باتجاه RTL.
- إنشاء مقارنة بعنوان وتفاصيل.
- عنصران أساسيان للمقارنة مع إمكانية إضافة حتى 4 عناصر إضافية.
- منع العناصر المكررة داخل المقارنة.
- تصويت مباشر على العناصر.
- تعليقات لكل مقارنة.
- حفظ المقارنات.
- إغلاق وإعادة فتح التصويت.
- فلترة حسب المجال.
- بحث داخل المقارنات والعناصر والتعليقات.
- ترتيب حسب الأكثر تفاعلًا أو الأحدث أو المحفوظة.
- مؤشرات مباشرة لعدد المقارنات والأصوات والتعليقات.
- حفظ البيانات محليًا عبر `localStorage`.
- تصميم متجاوب للجوال وسطح المكتب.

## الملفات

- `index.html`: هيكل التطبيق.
- `styles.css`: تصميم الواجهة والتجاوب.
- `app.js`: منطق المقارنات، التصويت، البحث، الحفظ، والتعليقات.

## التشغيل

يمكن فتح التطبيق مباشرة من ملف:

```text
index.html
```

أو تشغيل خادم محلي من نفس المجلد:

```bash
python3 -m http.server 5173
```

ثم فتح:

```text
http://127.0.0.1:5173/
```

## ملاحظات

هذه نسخة MVP ثابتة بدون backend. الخطوة التالية الطبيعية هي ربطها بقاعدة بيانات ونظام حسابات واهتمامات، حتى تصل المقارنات لأشخاص مهتمين بالمجال نفسه.
>>>>>>> a8e0148 (Save Rah Tafham app project)
