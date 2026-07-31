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
- آخر رفض موثق في البريد لتطبيق وش الراي كان `2.0 (97)` بتاريخ 31 يوليو 2026 لأن مسار `2.0` مغلق بعد اعتماده سابقًا. الإصدار الجاري للإرسال التالي هو `2.1 (98+)`.
- Screenshots فعلية حديثة لـiPhone 6.9 بوصة وiPad 13 بوصة.
- Bundle ID مضبوط حاليًا على `com.shary17454.esal`.
- Scheme مشترك للأرشفة داخل Xcode.
- Xcode Cloud مضبوط على إصدار إنتاجي مسموح، حاليًا Xcode 26.6 (`17F113`) في آخر Build موثق.
- آخر Build مرفوض موثق لهذا التطبيق هو `97` على مسار `2.0` المغلق. قبل أي Build جديد اضبط Xcode Cloud Next Build Number على `98` أو رقم أعلى من كل Builds الظاهرة في App Store Connect.

## مطلوب قبل الإرسال للمراجعة

- دفع Commit النهائي إلى `main` وتشغيل Workflow وش الرأي فقط عند وجود تغييرات جديدة.
- انتظار نجاح الاختبارات وArchive وPrepare for App Store Connect في Xcode Cloud عند إنشاء Build جديد.
- التأكد من أن أي Build جديد أعلى من `78` أو أعلى رقم ظاهر في Build Uploads، أيهما أكبر.
- فحص بيانات Artifact السحابي والتأكد من `2.1` ورقم البناء الجديد وXcode 26.6 (`17F113`) أو أحدث إصدار إنتاجي تسمح به Apple.
- رفع اللقطات الحديثة وإدخال وصف الإصدار وسياسة الخصوصية في App Store Connect.
- مراجعة App Privacy Labels وExport Compliance وPricing and Availability يدويًا.
- اختبار Sign in with Apple والإشعارات والروابط العميقة وVoiceOver على جهاز فعلي.
- لا تغيّر Bundle ID أو Team أو Signing أو Entitlements.
