# قائمة تحقق إصدار وش الرأي

## معلومات الإصدار

- App name: وش الرأي.
- Bundle ID: `com.shary17454.esal`.
- Marketing version: `1.9.0`.
- Build number: `30`.
- Release action: `PREPARE_ONLY`، بدون رفع وبدون إرسال للمراجعة من هذه المهمة.
- Scheme: `StudyVault`.
- Target: `StudyVault`.
- Xcode: 26.4.1.
- Swift: 6.0.
- Deployment target: iOS 17.0.

## البناء والتحقق

- [x] تشغيل Debug build بدون توقيع قبل التعديل.
- [x] تشغيل Release build بدون توقيع قبل التعديل.
- [x] تشغيل Debug build بدون توقيع بعد التعديل.
- [x] تشغيل Release build بدون توقيع بعد التعديل.
- [x] محاولة Archive بدون توقيع للتحقق البنيوي.
- [x] تشغيل `plutil -lint` لملفات plist الأساسية.
- [ ] تشغيل `git diff --check`.
- [ ] فحص conflict markers.

## الاختبارات

- [x] التحقق من حالة `xcodebuild test`.
- [ ] إنشاء Test target لاحقًا؛ الـScheme الحالي غير مهيأ للـTest action.
- [ ] اختبار يدوي لفتح الصفحة الرئيسية.
- [ ] اختبار يدوي لإنشاء مقارنة.
- [ ] اختبار يدوي للتصويت وإضافة السبب.
- [ ] اختبار يدوي للبحث والحفظ والمشاركة.

## App Store Connect

- [ ] التأكد من أن الإصدار `1.9.0` أعلى من آخر إصدار مقبول.
- [ ] التأكد من أن Build `30` أعلى من آخر Build مرفوض/مرفوع.
- [ ] التأكد أن Xcode Cloud workflow يحتوي `Archive - iOS` مع Distribution Preparation = App Store Connect.
- [ ] عدم اختيار Build مرفوض أو train مغلق.
- [ ] مراجعة What’s New بالعربية والإنجليزية.
- [ ] مراجعة Screenshots وApp Preview إن وجدت.
- [ ] مراجعة Pricing and Availability، خاصة السعودية إذا كانت مطلوبة.
- [ ] مراجعة Compliance والأسئلة القانونية.

## الخصوصية والأمان

- [ ] مراجعة `PrivacyInfo.xcprivacy`.
- [ ] مراجعة App Store Privacy Labels يدويًا.
- [ ] التأكد من عدم وجود مفاتيح API أو أسرار داخل الكود.
- [ ] مراجعة بيانات `UserDefaults` المحلية.
- [ ] التأكد من عدم تسجيل بيانات حساسة.
- [ ] مراجعة المتصفح الداخلي والروابط الخارجية.

## الجودة وتجربة المستخدم

- [ ] iPhone صغير.
- [ ] iPhone حديث كبير.
- [ ] iPad.
- [ ] Light Mode.
- [ ] Dark Mode.
- [ ] العربية RTL.
- [ ] الإنجليزية LTR إذا كانت مفعلة.
- [ ] Dynamic Type.
- [ ] VoiceOver عبر Accessibility Inspector.
- [ ] اختبار Safe Area وDynamic Island.

## قرار الإطلاق

لا ترسل للمراجعة قبل تحقق العناصر اليدوية أعلاه، خصوصًا Archive موقّع من Xcode Cloud، App Store Privacy Labels، وفحص التدفقات الحرجة على جهاز فعلي.
