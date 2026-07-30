# سياسة إصدار وش الرأي عبر Xcode Cloud

## المصدر المعتمد

Xcode Cloud هو المصدر الوحيد لبناء Release وإنشاء Archive ورفع التطبيق إلى App Store Connect. نسخة Xcode المحلية، سواء كانت Beta أو إنتاجية، تستخدم للتطوير والمحاكاة فقط ولا يعتمد أي Artifact ناتج منها للإصدار.

## Workflow

- التطبيق: وش الرأي.
- المشروع: `StudyVault.xcodeproj`.
- Scheme: `StudyVault`.
- الفرع الإنتاجي: `main`.
- Xcode: `26.6 (17F113)` الإنتاجي.
- SDK: iPhoneOS `26.5`.
- Actions: Build - iOS ثم Archive - iOS.
- Distribution: App Store Connect.
- Build Number: Xcode Cloud Next Build Number فقط.

لا تختَر `Latest Beta`، ولا تستخدم Xcode Beta أو سكربتًا محليًا لتغيير رقم البناء.

## حواجز CI

`ci_post_clone.sh` يفشل مبكرًا عند:

- استخدام Xcode Beta أو إصدار غير معتمد.
- استخدام SDK أقدم من المطلوب.
- اختلاف Marketing Version أو Build Number بين إعدادات المشروع.
- انخفاض رقم Xcode Cloud عن الحد الأدنى.

`ci_post_xcodebuild.sh` يفحص الأرشيف الأساسي والـIPA الموقّع الناتج فعليًا ويتحقق من:

- نجاح `xcodebuild`.
- Bundle ID `com.shary17454.esal`.
- Marketing Version المتوقع.
- سلامة Build Number الأساسي داخل `.xcarchive`.
- تطابق Build Number النهائي داخل IPA الموقّع مع `CI_BUILD_NUMBER`؛ يطبق Xcode Cloud الرقم السحابي أثناء App Store export وليس داخل الأرشيف الأساسي.
- Xcode Build `17F113` وSDK `iphoneos26.5`.
- تطابق الإصدارات بين التطبيق وأي Extension مضمّن.

## آخر تحقق

آخر رسالة App Store Connect بتاريخ 23 يوليو 2026 رفضت `1.10.0 (69)` بسبب:

- `ITMS-90186`: مسار `1.10.0` مغلق للإرسالات الجديدة.
- `ITMS-90062`: `CFBundleShortVersionString` يجب أن يكون أعلى من آخر إصدار معتمد `1.10.0`.

الإصدار الحالي في المشروع هو `2.0`، ورقم البناء الأساسي `79`. يجب ضبط Xcode Cloud Next Build Number على `79` أو رقم أعلى من كل Builds الظاهرة في App Store Connect قبل أي Archive جديد.

## خطوات الإصدار

1. ادمج تغييرات وش الرأي في `main` وادفعها إلى GitHub.
2. راقب Workflow `Default` حتى نجاح Build وArchive.
3. افتح TestFlight > Build Uploads وتأكد من أن البناء الجديد `Complete` أو أن حالة المراجعة الحالية تسمح بالإجراء المطلوب.
4. تحقق من أن الإصدار أعلى من آخر إصدار منشور وأن رقم البناء غير مستخدم.
5. اربط البناء بإصدار App Store المفتوح بعد مراجعة الخصوصية والبيانات الوصفية.
6. لا ترسل إلى App Review إلا بتصريح صريح وبعد اكتمال الخطوات اليدوية.
