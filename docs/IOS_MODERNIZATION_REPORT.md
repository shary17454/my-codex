# تقرير تحديث iOS لتطبيق بطل الدروب

## الحالة السابقة

- المشروع المحدد: `ios/BatalAlDroob`.
- نوع التطبيق: iOS Native باستخدام SwiftUI مع UIKit lifecycle سابق غير مستخدم.
- الهدف: `BatalAlDroob`.
- Scheme: `BatalAlDroob`.
- Bundle ID: `com.batalaldroob.parts`.
- الإصدار السابق في المشروع: `1.0.1`.
- رقم البناء السابق في المشروع: `81`.
- Swift: `6.0`.
- iOS Deployment Target: `17.0`.
- Xcode المستخدم للتحقق: `Xcode 26.6 (17F113)`.
- لا توجد تبعيات CocoaPods أو Swift Package Manager لهذا الهدف.
- لا توجد Test targets مهيأة في Scheme.

## Baseline قبل التعديل

- `Debug` simulator build: ناجح.
- `Release` simulator build: ناجح.
- `xcodebuild test`: غير مهيأ لأن Scheme لا يحتوي Test action.
- ملاحظة موجودة قبل التعديل: Run Script phase باسم `Clean Bundle Metadata` تعمل كل مرة لأن dependency analysis غير مفعّل.

## القرارات

- لم يتم تغيير Bundle ID أو Signing أو Development Team.
- لم يتم رفع الحد الأدنى لنظام iOS.
- لم تتم إضافة تبعيات خارجية.
- تم الحفاظ على مفاتيح UserDefaults الحالية:
  - `batalLang`
  - `batalVehicleProfile`
  - `batalMaintenanceLog`
  - `batalPartRequests`
  - `batalWishlist`
  - `batalPaidUnlocks`
- تم إبقاء ملفات الويب والكتالوجات المدمجة للحفاظ على السلوك الحالي وعدم حذف بيانات.

## التغييرات المنفذة

### Project configuration

- رفع `MARKETING_VERSION` إلى `1.1.0`.
- رفع `CURRENT_PROJECT_VERSION` إلى `84`.
- إضافة `PrivacyInfo.xcprivacy` إلى موارد التطبيق.

### UI/UX

- إضافة `BatalDesign` كطبقة design tokens بسيطة.
- إضافة `EmptyStateView` موحد لحالات عدم وجود نتائج أو سجلات.
- تحسين حالات:
  - نتائج البحث الفارغة.
  - أدلة القطعة الفارغة.
  - طلبات القطع المحفوظة الفارغة.
  - سجل الصيانة الفارغ.
  - قائمة الرغبات الفارغة.
- تحسين شاشة الحماية عند خروج التطبيق من الحالة النشطة لتدعم العربية والإنجليزية.

### Arabic / English / RTL

- دعم اتجاه الواجهة ما زال مرتبطًا باللغة داخل `RootView`.
- تم إزالة نص عربي ثابت من شاشة الحماية.
- تمت إضافة رسائل Empty State عربية وإنجليزية.

### Accessibility

- إضافة `accessibilityElement(children: .combine)` لعناصر Empty State وشاشة الحماية.
- الحفاظ على استخدام SwiftUI controls الأصلية مثل `List`, `Form`, `NavigationStack`, `TabView`, و`Label`.

### Forms

- تحسين حقول السنة والعداد لاستخدام `numberPad`.
- تعطيل التصحيح التلقائي ورفع الأحرف لحقول VIN وأرقام القطع.

### Location / Weather

- إضافة حالة تحميل للطقس.
- تحسين رسالة فشل الطقس لتكون مفهومة للمستخدم بدل عرض خطأ نظام خام فقط.
- لم يتم تغيير منطق صلاحيات الموقع.

### Privacy / Security

- إضافة Privacy Manifest.
- التصريح باستخدام UserDefaults ضمن Required Reason API.
- عدم إعلان جمع بيانات في manifest لأن الكود الحالي لا يرسل بيانات المستخدم إلى Backend خاص.
- ملاحظة: خدمة Open-Meteo تستخدم عند تشغيل الموقع لجلب الطقس بناءً على الإحداثيات، ويجب مطابقة ذلك يدويًا مع App Store Privacy Labels.

## التدفقات الحرجة

- تحميل قاعدة الكتالوج المدمجة: Verified by build only; يحتاج تشغيل يدوي للتأكد من البيانات على جهاز/Simulator.
- البحث عن قطعة: Partially verified by code review/build.
- تفاصيل القطعة والأدلة: Partially verified by code review/build.
- المشتريات داخل التطبيق: Not verified; تحتاج Sandbox/TestFlight.
- طلب قطعة بعد الدفع: Not verified; يحتاج Sandbox/TestFlight.
- سجل الصيانة المحلي: Partially verified by code review/build.
- قائمة الرغبات: Partially verified by code review/build.
- التتبع والبوصلة والطقس: Not verified على جهاز فعلي؛ البناء فقط نجح.

## الاختبارات والتحقق

- Debug build بعد التعديلات: ناجح.
- لا توجد Unit/UI tests مهيأة لهذا الهدف.
- Release build وArchive موثقان في `docs/RELEASE_CHECKLIST.md`.

## المخاطر المتبقية

- لا توجد اختبارات آلية تغطي منطق البحث أو الشراء.
- المشتريات تحتاج تحقق Sandbox/TestFlight.
- الموقع والبوصلة والطقس تحتاج جهاز فعلي لأن Simulator لا يثبت صلاحية الحساسات.
- App Store Privacy Labels تحتاج مراجعة بشرية قبل أي إرسال نهائي.
- التطبيق ما زال يحتوي `Web/` المدمج للحفاظ على الوظائف، رغم أن الواجهة الحالية SwiftUI أصلية.

## التوصيات

1. إضافة Test target منخفض المخاطر في دورة لاحقة لتغطية `tireDiameter`, decoding, search, and view model behavior.
2. اختبار Sandbox In-App Purchase قبل أي إرسال جديد.
3. اختبار الموقع والبوصلة والطقس على جهاز فعلي.
4. تشغيل Accessibility Inspector يدويًا على الشاشات الأساسية.
5. إبقاء الإرسال الحالي Build 83 قيد المراجعة وعدم سحبه إلا إذا قررت إرسال Build 84 بدلًا منه.
