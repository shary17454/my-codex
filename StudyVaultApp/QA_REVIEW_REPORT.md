# تقرير مراجعة الجودة والأداء لتطبيق وش الرأي

تاريخ المراجعة: 2026-07-14

## نطاق المراجعة

تمت مراجعة مشروع iOS داخل `StudyVaultApp` فقط، وهو تطبيق SwiftUI باسم `StudyVault` ويظهر للمستخدم باسم `وش الرأي`. المشروع يستخدم Swift 6 ويدعم iPhone وiPad عبر Target واحد.

## المعمارية الحالية

- الواجهة مبنية بـ SwiftUI.
- التنقل يعتمد على `TabView` و`NavigationStack`.
- إدارة الحالة الأساسية موجودة في `HomeViewModel` و`CreateComparisonViewModel`.
- التطبيق يعتمد حاليًا على بيانات محلية وملفات JSON و`UserDefaults`.
- لا يوجد Backend فعلي للتصويت الجماعي أو مزامنة الحسابات أو رفع الصور.

## ما تم فحصه

- ملفات Swift الأساسية:
  - `StudyVault/ContentView.swift`
  - `StudyVault/AskModels.swift`
  - `StudyVault/ViewModels.swift`
  - `StudyVault/StudyVaultApp.swift`
- ملفات الإعداد:
  - `StudyVault/Info.plist`
  - `StudyVault/PrivacyInfo.xcprivacy`
  - `StudyVault.xcodeproj/project.pbxproj`
- ملفات الموارد:
  - `SeedQuestions.json`
  - `ProductKnowledge.json`
  - `Assets.xcassets`

## التحسين المنفذ

تم إصلاح تحذير Xcode الخاص بمرحلة البناء:

`Run script build phase 'Clean App Metadata' will be run during every build`

السبب كان أن مرحلة السكربت لا تحتوي على مخرجات معلنة وكانت مضبوطة كمرحلة تعمل دائمًا. تم تعديلها لتنتج ملف:

`$(DERIVED_FILE_DIR)/CleanAppMetadata.stamp`

هذا يقلل العمل غير الضروري أثناء البناء ويحافظ على وظيفة تنظيف metadata بدون تعطيلها.

## نتائج التحقق

تم تشغيل البناء:

```bash
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -destination generic/platform=iOS -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

النتيجة:

```text
** BUILD SUCCEEDED **
```

تم تشغيل التحليل:

```bash
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -destination generic/platform=iOS -configuration Debug CODE_SIGNING_ALLOWED=NO analyze
```

النتيجة:

```text
** ANALYZE SUCCEEDED **
```

## ملاحظات الأداء

- لا توجد عمليات شبكة فعلية ثقيلة داخل المسار الحالي للتطبيق.
- البحث المحلي يستخدم فلترة مباشرة على مصفوفات محلية، وهو مناسب لحجم البيانات الحالي.
- الواجهات تستخدم SwiftUI وقوائم Lazy في أجزاء من التطبيق، وهذا مناسب للتصفح.
- أي تحليل عميق لاستهلاك الذاكرة أو البطارية يحتاج تشغيل التطبيق على جهاز فعلي عبر Instruments.

## ملاحظات الواجهة وتجربة المستخدم

- التطبيق مضبوط على اتجاه عربي RTL.
- الواجهات الأساسية تستخدم SwiftUI وعناصر Apple الأصلية.
- لا يمكن الجزم بعدم وجود تداخل نصوص على كل الأجهزة بدون اختبار بصري فعلي على iPhone وiPad، لكن البناء لا يظهر مشاكل تخطيط تمنع التشغيل.

## ملاحظات مهمة على المستودع

توجد ملفات مكررة غير متتبعة داخل `StudyVaultApp` بأسماء تنتهي بـ ` 2`، ويبدو أنها ناتجة من مزامنة أو نسخ سابقة. هذه الملفات ليست ظاهرة كجزء من Target الرئيسي حسب فحص `project.pbxproj`، ولم يتم حذفها حتى لا نفقد أي نسخة قد تحتاجها لاحقًا.

توجد أيضًا مخرجات بناء داخل `StudyVaultApp/build/`. ملف `.gitignore` داخل المشروع يستثني `build/` وملفات `.ipa` و`DerivedData/`، لذلك يجب عدم إضافتها إلى Git مستقبلًا.

## القيود المتبقية

- لا يوجد Test Target حاليًا، لذلك لم يتم تشغيل XCTest.
- اختبار أجهزة فعلية وInstruments يحتاج جلسة Xcode GUI وجهاز فعلي.
- التصويت والحفظ محليان ولا يمثلان منصة جماعية حقيقية دون Backend.

## التوصية التالية

1. إضافة Test Target بسيط لتغطية حساب نسب التصويت والتحقق من إنشاء المقارنة.
2. اختبار التطبيق يدويًا على iPhone وiPad.
3. تشغيل Instruments على جهاز فعلي لمسارات: فتح التطبيق، البحث، فتح تفاصيل مقارنة، التصويت، إنشاء مقارنة.
4. تنظيف ملفات `* 2.*` بعد تأكيد أنها نسخ مكررة غير مطلوبة.
