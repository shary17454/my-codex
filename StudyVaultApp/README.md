# وش الرأي؟ iOS

تطبيق iOS عربي باسم "وش الرأي؟" لطرح أسئلة المقارنة بين المنتجات والخدمات، ثم استقبال تصويت وتعليقات من أشخاص مهتمين بنفس المجال.

Bundle ID الحالي: `com.shary17454.esal`

## المحتوى

- مشروع Xcode: `StudyVault.xcodeproj`
- كود التطبيق: `StudyVault/`
- قاعدة بيانات الأسئلة الأولية: `StudyVault/SeedQuestions.json`
- بيانات App Store: `AppStore/`
- سكربت توليد الأيقونة: `Tools/GenerateIcon.swift`

## الوظائف

- طرح سؤال مقارنة جديد.
- دعم المقارنة بين خيارين وحتى 10 خيارات.
- تصويت مباشر على الخيارات.
- عرض نسب التصويت والاختيار الأعلى.
- تعليقات على كل سؤال.
- تصفية الأسئلة حسب المجال: جوالات، سيارات، مطاعم، لابتوبات، ألعاب، سفر، وغيرها.
- بحث باسم المنتج أو السؤال.
- دعم RTL عربي.
- نموذج أولي يعمل محليًا بدون تسجيل دخول أو خادم.

## قاعدة البيانات

التطبيق يقرأ أسئلة أولية من ملف JSON داخل التطبيق. البيانات تشمل أسماء منتجات وخدمات حقيقية في مجالات الجوالات والسيارات والمطاعم واللابتوبات والألعاب والسفر، لكنها تبدأ بدون أي تصويتات أو تعليقات مصطنعة. أرقام التصويت والتعليقات تُنشأ فقط من استخدام التطبيق.

## البناء محليًا

للبناء على Simulator:

```bash
xcodebuild -project StudyVault.xcodeproj -target StudyVault -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

للأرشفة والرفع إلى App Store:

1. افتح `StudyVault.xcodeproj` في Xcode.
2. سجّل دخولك بحساب Apple Developer من Xcode إذا لم تكن مسجلًا.
3. اختر Apple Developer Team عندما يطلب Xcode ذلك.
4. اختر `Any iOS Device`.
5. نفّذ `Product > Archive`.
6. ارفع من Organizer إلى App Store Connect.

إذا رفضت Apple المعرف `com.shary17454.esal` لأنه غير متاح، غيّره فقط إلى معرف آخر تملكه مثل `com.shary17454.esalapp`.

## ملاحظة عن بيئة البناء الحالية

تم التحقق من أن كود Swift يبني بنجاح. بعد إضافة AppIcon، فشل `actool` في هذه البيئة بسبب عدم توفر simulator runtime فعلي، برسالة:

```text
No available simulator runtimes for platform iphonesimulator
```

هذا متعلق بإعداد Xcode المحلي في البيئة، وليس بمنطق التطبيق. افتح المشروع في Xcode كامل يحتوي iOS Simulator runtime أو ابنِ Archive موقّعًا لحساب Apple Developer.

عند فحص إعدادات Release في هذه البيئة ظهر أيضًا أن iOS platform غير مثبت:

```text
iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components.
```
