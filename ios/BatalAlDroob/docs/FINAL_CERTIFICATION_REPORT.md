# تقرير الشهادة الهندسية النهائية - بطل الدروب

التاريخ: 21 يوليو 2026  
الحالة: `READY_WITH_EXTERNAL_REQUIREMENTS`  
الجذر الرسمي: `ios/BatalAlDroob/`

## الملخص

تمت مراجعة التطبيق كمشروع طرف ثالث من الصفر وفق `PROJECT_STANDARDS.md`، ومعايير Apple الرسمية للمراجعة، وStoreKit، وإتاحة الوصول، ومتطلبات App Store Connect. التطبيق Native SwiftUI ولا يحتوي على Flutter أو Dart runtime داخل هدف بطل الدروب.

## النتيجة الرقمية

| المجال | الدرجة |
|---|---:|
| الهندسة العامة | 91/100 |
| UX | 89/100 |
| UI | 88/100 |
| الأداء | 90/100 |
| الأمان | 93/100 |
| Accessibility | 86/100 |
| Localization | 90/100 |
| App Store Readiness | 82/100 |

## Finding تم إصلاحه أثناء مراجعة الشهادة

### Medium - حفظ طلب قطعة فارغ ظاهريًا

- الملف: `BatalAlDroob/WorkflowViews.swift`
- الملفات المرتبطة: `BatalAlDroob/CatalogViewModel.swift`, `BatalAlDroob/Utilities.swift`, `BatalAlDroobTests/BatalCatalogResourceTests.swift`
- السبب الجذري: شرط تعطيل زر حفظ طلب القطعة كان يفحص `isEmpty` فقط، ما يسمح بقيم تحتوي مسافات أو أسطر فارغة.
- أثر المستخدم: يمكن أن يظهر للمستخدم أن الطلب حفظ بنجاح رغم عدم وجود رقم أو اسم قطعة فعلي.
- الأثر الهندسي: ضعف في validation لأن الحماية كانت واجهية وغير موحدة.
- الحل المنفذ: إضافة `partRequestHasRequiredInput(_:)` واستخدامها داخل الزر وداخل `saveRequestPlan`، مع اختبار `testBlankPartRequestCannotBeSaved`.
- التحقق: اختبارات الوحدة نجحت `14/14`.

## مراجعة النطاق

- كل الشاشات الأساسية تمت مراجعتها: الرئيسية، الكتالوج، طلب قطعة، المزيد، تفاصيل القطعة، الصيانة، القطع المشتركة.
- كل أزرار المسارات الحرجة تمت تغطيتها يدويًا بالكود أو عبر UI smoke tests.
- StoreKit يستخدم `batal.catalog.single.unlock` للفتح الجزئي، و`batal.catalog.permanent.unlock` للفتح الكامل، مع إبقاء `batal.catalog.full.unlock` كاستحقاق كامل قديم عند وجوده في App Store Connect.
- لا توجد خريطة أو بوصلة أو تتبع موقع في التطبيق، ولا توجد صلاحية موقع مطلوبة.
- OCR يتم محليًا عبر Vision ولا يرسل الصورة لخادم.
- الروابط الخارجية لا تفتح إلا عبر HTTPS وضمن نطاق المتجر الموثق.
- لا توجد صلاحيات غير مستخدمة في `Info.plist`.
- لا توجد Entitlements أو Capabilities إضافية غير مبررة.
- لا توجد تبعيات خارجية.

## التحقق المنفذ

| الأمر | النتيجة |
|---|---|
| `xcodebuild -list -project BatalAlDroob.xcodeproj` | PASS |
| `plutil -lint ...` | PASS |
| `swiftformat --lint .` | PASS |
| `swiftlint lint --strict --cache-path /tmp/batal-swiftlint-cache` | PASS |
| `python3 scripts/validate_release.py` | PASS |
| `python3 scripts/validate_partnership_data.py` | PASS |
| `xcodebuild ... Release ... CODE_SIGNING_ALLOWED=NO build` | PASS |
| `xcodebuild ... analyze` | PASS |
| Unit tests | PASS، عددها 14/14 |
| UI smoke tests | PASS، عددها 2/2 |
| `git diff --check` | PASS |

## المخاطر المتبقية

### High - عناصر App Store Connect خارج الكود

- منتجات StoreKit الجديدة `batal.catalog.single.unlock` و`batal.catalog.full.unlock`، وأي استحقاق قديم نشط `batal.catalog.permanent.unlock`، يجب أن تكون مكتملة البيانات، السعر، التوفر، صور App Review، والملاحظات.
- يجب إرفاق أول IAP جديد مع إصدار التطبيق نفسه عند الإرسال.
- يجب أن تكون صور 6.5-inch iPhone و13-inch iPad من التطبيق الحالي في الاستخدام الفعلي.
- يجب تشغيل Xcode Cloud ببناء `111` أو أعلى من commit المصحح وبـ Xcode إنتاجي مقبول.

### Medium - فحوصات يدوية لا يمكن إثباتها من البيئة الحالية

- StoreKit Sandbox على جهاز فعلي.
- Accessibility Inspector وVoiceOver الفعلي.
- Instruments Leaks/Time Profiler/Energy.
- لا يوجد مسار موقع/بوصلة مطلوب اختباره بعد الإزالة.

## التوصية النهائية

التوصية: `Ready for TestFlight`

ليس `Ready for App Store Submission` حتى تكتمل عناصر App Store Connect المذكورة أعلاه ويتم اختيار Build سحابي موقع من Xcode Cloud من commit الصحيح.
