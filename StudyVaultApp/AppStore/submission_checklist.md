# قائمة تجهيز App Store

## مكتمل

- مشروع Xcode لتطبيق SwiftUI.
- واجهة عربية RTL.
- واجهة أسئلة مقارنة عربية.
- تصويت وأسباب وتعليقات محلية.
- إنشاء سؤال جديد بخيارين وحتى 10 خيارات.
- بحث وتصفية حسب المجال.
- AppIcon داخل `Assets.xcassets`.
- Privacy Manifest.
- سياسة خصوصية.
- بيانات App Store عربية.
- ملاحظات مراجعة.
- بناء Debug وRelease وStatic Analyzer ناجح.
- اختبارات الوحدة 9/9 واختبار الواجهة 1/1 ناجحة.
- Archive جديد يجب أن يحمل `1.11.0 (70)` أو رقم Build أعلى إذا تولى Xcode Cloud زيادته.
- Screenshots فعلية حديثة لـiPhone 6.9 بوصة وiPad 13 بوصة.
- Bundle ID مضبوط حاليًا على `com.shary17454.esal`.
- Scheme مشترك للأرشفة داخل Xcode.
- Xcode Cloud مضبوط على Latest Release، حاليًا Xcode 26.6 (`17F113`).
- Xcode Cloud Next Build Number مضبوط على `52`، وأعلى Build ظاهر سابقًا هو `51`.

## مطلوب قبل الإرسال للمراجعة

- دفع Commit النهائي إلى `main` وتشغيل Workflow وش الرأي فقط.
- انتظار نجاح الاختبارات وArchive وPrepare for App Store Connect في Xcode Cloud.
- التأكد من أن Build `52` ظهر بحالة Complete/Ready to Submit ولم يكن مستخدمًا قبل تشغيل Workflow.
- فحص بيانات Artifact السحابي والتأكد من `1.11.0 (70+)` وXcode 26.6 (`17F113`) أو إصدار إنتاجي أحدث تسمح به Apple.
- رفع اللقطات الحديثة وإدخال وصف الإصدار وسياسة الخصوصية في App Store Connect.
- مراجعة App Privacy Labels وExport Compliance وPricing and Availability يدويًا.
- اختبار Sign in with Apple والإشعارات والروابط العميقة وVoiceOver على جهاز فعلي.
- لا تغيّر Bundle ID أو Team أو Signing أو Entitlements.
