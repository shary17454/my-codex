# قائمة تحقق إصدار وش الرأي

## معلومات ثابتة

- [x] الاسم: وش الرأي.
- [x] Bundle ID: `com.shary17454.esal`.
- [x] Scheme: `StudyVault`.
- [x] Swift: 6.0.
- [x] Deployment target: iOS 17.0.
- [x] الأجهزة: iPhone وiPad.
- [x] Marketing Version في المشروع: `2.1`.
- [x] Build Number في المشروع: `102`.
- [x] لم يتغير Team أو Signing أو Entitlements.

## البناء والاختبارات المحلية

- [x] Debug build.
- [x] Release simulator build.
- [x] Static Analyzer.
- [x] Unit Tests: 9/9.
- [x] UI Smoke Test: 1/1.
- [x] Backend syntax check.
- [x] Backend isolated smoke test.
- [x] فحص JSON وInfo.plist.
- [x] Archive محلي جديد دون توقيع للتحقق البنيوي.
- [x] فحص القيم الفعلية داخل xcarchive.
- [x] لا توجد Extensions مضمنة بأرقام مختلفة.
- [x] `git diff --check`.
- [x] فحص conflict markers.

## الواجهة

- [x] iPhone حديث.
- [x] iPad Portrait.
- [x] iPad Landscape.
- [x] Light Mode.
- [x] Dark Mode.
- [x] العربية RTL.
- [x] بحث واكتشاف.
- [x] إنشاء مقارنة.
- [x] تصويت محلي وعرض النتائج.
- [x] المكتبة والحساب.
- [ ] iPhone فعلي صغير.
- [ ] Dynamic Type بأكبر الأحجام على جهاز فعلي.
- [ ] VoiceOver وAccessibility Inspector.
- [ ] Reduce Motion وIncrease Contrast يدويًا.

## Xcode Cloud

- [x] توجيه `ci_scripts/ci_post_clone.sh` المشترك إلى حارس وش الرأي عند اكتشاف `StudyVault` فقط.
- [x] اعتماد Xcode Cloud وحده لبناء Release وArchive والرفع إلى App Store Connect.
- [x] تثبيت Workflow على Xcode 26.6 الإنتاجي `17F113` وSDK iPhoneOS 26.5.
- [x] إضافة `ci_post_xcodebuild.sh` للتحقق من Bundle ID والإصدار وXcode/SDK داخل الأرشيف، ومن رقم Cloud داخل IPA الموقّع النهائي.
- [ ] إنشاء Archive جديد من Commit النهائي لإصدار `2.1` عبر Xcode Cloud.
- [x] فحص Shell syntax ومسار الرفض المحلي عند استخدام Xcode أقدم من 26.6.
- [x] تأكيد أن Workflow يبني `StudyVaultApp/StudyVault.xcodeproj` والـScheme `StudyVault`.
- [x] اختيار Xcode Stable إنتاجي: Latest Release، حاليًا Xcode 26.6 (`17F113`).
- [ ] يجب ضبط Next Build Number على `102` أو أعلى، أعلى من Builds السابقة.
- [ ] تشغيل Unit وUI tests قبل Archive.
- [ ] إنشاء Archive من Commit النهائي.
- [ ] التأكد أن الإصدار والبناء داخل Artifact يطابقان App Store Connect.
- [ ] عدم استخدام Artifact أو Archive أقدم.
- [ ] عدم إعادة استخدام Build Number سبق رفعه.

## App Store Connect

- [x] التأكد أن `2.1` أعلى من الإصدار المغلق `2.0`.
- [x] التأكد أن Build `102` أعلى من آخر Build مرفوض `98`.
- [ ] مراجعة App Privacy Labels يدويًا.
- [ ] مراجعة Export Compliance.
- [x] تحديث What’s New بالعربية والإنجليزية بما يطابق الوظائف المنفذة.
- [x] تجهيز Screenshots فعلية لـiPhone 6.9 بوصة وiPad 13 بوصة.
- [ ] مراجعة Pricing and Availability.
- [ ] اختبار Apple Sign In على جهاز فعلي.
- [ ] اختبار الإشعارات والـDeep Links.
- [ ] عدم الإرسال للمراجعة قبل إغلاق جميع البنود اليدوية.

## Backend والإنتاج

- [ ] توفير خدمة HTTPS إنتاجية.
- [ ] استبدال تخزين JSON بقاعدة بيانات دائمة.
- [ ] تطبيق مصادقة مستخدمين وسياسة تصويت على الخادم.
- [ ] ضبط Rate Limiting وMonitoring وBackups.
- [ ] مراجعة تطابق Privacy Labels مع بيانات الخادم الفعلية.
- [ ] اختبار Rollback وتوافق API قبل الإطلاق.

## قرار الإصدار

الحالة الحالية: `READY_WITH_EXTERNAL_REQUIREMENTS`.

لا ترفع النسخة المحلية غير الموقعة. استخدم Xcode Cloud بعد إكمال فحوص Version/Build وPrivacy وBackend أعلاه.
