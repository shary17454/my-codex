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
- `nissan-patrol/`

هذه الملفات تستخدم كمرجع لمتابعة العمل لاحقاً بدون فقدان سياق المشروع.
