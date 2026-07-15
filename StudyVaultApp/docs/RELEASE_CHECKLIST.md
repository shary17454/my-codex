# قائمة تحقق إصدار وش الرأي

## معلومات الإصدار

- App name: وش الرأي.
- Bundle ID: `com.shary17454.esal`.
- Marketing version: `1.10.0`.
- Build number: `36`.
- Release action: `PREPARE_ONLY`، بدون رفع وبدون إرسال للمراجعة من هذه المهمة.
- Scheme: `StudyVault`.
- Target: `StudyVault`.
- Xcode Cloud required: Xcode 26.6 `17F113` أو أحدث إصدار إنتاجي تسمح به Apple.
- Local Xcode observed: 26.4.1 `17E202`، صالح للبناء المحلي فقط ولا يعتمد كبيئة رفع لهذا الإصدار.
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

- [ ] التأكد من أن الإصدار `1.10.0` أعلى من آخر إصدار مقبول ومن آخر محاولة `1.9.0`.
- [ ] التأكد من أن Build `36` أعلى من كل Build ظاهر في TestFlight / Build Uploads، خصوصًا Build `35`.
- [ ] التأكد أن Xcode Cloud workflow يحتوي `Archive - iOS` مع Distribution Preparation = App Store Connect.
- [ ] ضبط Xcode Cloud > Workflow > Environment > Xcode Version على Xcode 26.6 `17F113` أو إصدار إنتاجي أحدث مسموح.
- [ ] ضبط Xcode Cloud > Next Build Number على `36` أو رقم أعلى إن ظهر Build أحدث في Build Uploads.
- [ ] عدم اختيار Latest Beta أو Xcode 27 beta.
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
