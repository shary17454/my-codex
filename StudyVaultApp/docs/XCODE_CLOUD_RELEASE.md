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

`ci_post_xcodebuild.sh` يفحص الأرشيف الناتج فعليًا ويتحقق من:

- نجاح `xcodebuild`.
- Bundle ID `com.shary17454.esal`.
- Marketing Version المتوقع.
- تطابق Build Number داخل الأرشيف مع `CI_BUILD_NUMBER`.
- Xcode Build `17F113` وSDK `iphoneos26.5`.
- تطابق الإصدارات بين التطبيق وأي Extension مضمّن.

## آخر تحقق

نجح Xcode Cloud Build `58` في 20 يوليو 2026 من commit `dda2ea7` باستخدام Xcode `26.6 (17F113)` وmacOS Tahoe `26.5.1`. نجحت عمليتا Build وArchive، وظهر `1.10.0 (58)` في App Store Connect بحالة `Complete`.

## خطوات الإصدار

1. ادمج تغييرات وش الرأي في `main` وادفعها إلى GitHub.
2. راقب Workflow `Default` حتى نجاح Build وArchive.
3. افتح TestFlight > Build Uploads وتأكد من أن البناء الجديد `Complete`.
4. تحقق من أن الإصدار أعلى من آخر إصدار منشور وأن رقم البناء غير مستخدم.
5. اربط البناء بإصدار App Store المفتوح بعد مراجعة الخصوصية والبيانات الوصفية.
6. لا ترسل إلى App Review إلا بتصريح صريح وبعد اكتمال الخطوات اليدوية.
