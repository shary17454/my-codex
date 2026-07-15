# تقرير تحديث iOS لتطبيق وش الرأي

## الحالة السابقة

تم فحص تطبيق `وش الرأي` داخل `StudyVaultApp`. المشروع يبني قبل التعديل بنجاح في Debug وRelease عند تعطيل التوقيع، ولا يحتوي على Test target مهيأ داخل Scheme الحالي.

## Architecture والتقنيات

- نوع المشروع: iOS Native.
- الواجهة: SwiftUI.
- اللغة: Swift 6.0.
- النمط: MVVM جزئي عبر `HomeViewModel` و`CreateComparisonViewModel`.
- إدارة الحالة: Observation و`@StateObject`/`@State`.
- التخزين: `UserDefaults` وملفات JSON محلية داخل التطبيق.
- الاعتماديات: لا توجد CocoaPods أو Swift Package Manager ظاهرة لهذا الهدف.
- الحد الأدنى لنظام iOS: 17.0.
- Bundle ID: `com.shary17454.esal`، ولم يتم تغييره.
- Team/Signing: Automatic signing مع Team الحالي، ولم يتم تغييره.

## المشكلات المهمة

- لا توجد اختبارات آلية مضافة إلى Scheme `StudyVault`; أمر `xcodebuild test` يفشل لأن الـScheme غير مهيأ للـTest action.
- توجد نسخ احتياطية غير مضافة إلى Target بأسماء مثل `ContentView 2.swift` و`Info 2.plist`. لم يتم حذفها لتجنب فقدان بيانات عمل سابقة، لكنها تحتاج تنظيف مستودع منفصل.
- التطبيق يعتمد على بيانات محلية ولا يحتوي Backend فعليًا للتصويت الجماعي أو مزامنة الحسابات.

## القرارات المعمارية

لم يتم تنفيذ إعادة كتابة أو تغيير Architecture لأن المشروع الحالي SwiftUI أصلي ويبني بنجاح. التغيير في هذه الجولة ركز على إعداد إصدار جديد آمن وتوثيق جاهزية الإصدار بدل تعديل سلوك مستخدم مستقر.

## تحديثات الاعتماديات

لا توجد اعتماديات خارجية مرصودة داخل `StudyVaultApp`، لذلك لم يتم تحديث Lockfiles أو إضافة مكتبات جديدة.

## UI/UX ودعم العربية وRTL

الواجهة الرئيسية تفرض RTL عبر `layoutDirection` وتستخدم مكونات SwiftUI وSF Symbols. لم يتم تنفيذ إعادة تصميم واسعة في هذه الجولة لأن بناء baseline ناجح وأي إعادة تصميم كبيرة تحتاج فحص بصري كامل على Simulator وأجهزة فعلية.

## Accessibility

يوجد استخدام لبعض `accessibilityLabel` في عناصر مهمة، لكن لم يتم تشغيل Accessibility Inspector. يلزم فحص يدوي لVoiceOver وDynamic Type قبل الإرسال النهائي.

## Security وPrivacy

- لم تتم إضافة أسرار أو مفاتيح API.
- لم يتم تغيير Entitlements أو Signing أو Bundle ID.
- `PrivacyInfo.xcprivacy` يعلن عدم التتبع وعدم جمع بيانات.
- يجب مراجعة App Store Privacy Labels يدويًا لأن الاستنتاج من الكود لا يكفي لتأكيد إجابات الخصوصية القانونية.

## Performance

تم الاعتماد على نجاح build ومراجعة كود سطحية فقط. لم يتم تشغيل Instruments، لذلك لا توجد ادعاءات بقياسات أداء فعلية.

## الاختبارات والتحقق

- Debug build قبل التعديل: ناجح.
- Release build قبل التعديل: ناجح.
- Test action قبل التعديل: غير مهيأ في Scheme.
- Debug build بعد التعديل: ناجح.
- Release build بعد التعديل: ناجح.
- Archive بدون توقيع بعد التعديل: ناجح.
- `plutil -lint` لملفات plist الأساسية: ناجح.

## إعداد الإصدار

- الإصدار السابق: `1.8.0`.
- رقم البناء السابق: `29`.
- الإصدار الجديد: `1.9.0`.
- رقم البناء الجديد: `30`.
- مصدر الحقيقة: `MARKETING_VERSION` و`CURRENT_PROJECT_VERSION` في `StudyVault.xcodeproj/project.pbxproj`.

## المشكلات المتبقية

- إضافة Unit/UI test targets للتدفقات الحرجة.
- تنظيف النسخ المكررة غير المستخدمة بعد التأكد من عدم الحاجة لها.
- فحص App Store Privacy Labels وبيانات التوفر والتسعير يدويًا في App Store Connect.
- تشغيل Archive موقّع أو Xcode Cloud Archive قبل الإرسال الرسمي.

## التوصية

الإصدار جاهز من ناحية كود البناء المحلي بعد اكتمال الفحوصات النهائية، لكن الإطلاق الرسمي يجب أن يمر عبر Xcode Cloud أو Archive موقّع مع مراجعة الخصوصية والاختبارات اليدوية.
