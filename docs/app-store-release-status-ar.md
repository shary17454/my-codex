# حالة تجهيز بطل الدروب للآبستور

## تحديث 2026-07-10

- تم اعتماد رقم إصدار جديد: `1.0.1`
- تم رفع رقم البناء المحلي إلى: `47`
- تم تصحيح تخطيط الواجهة على `iPad` بعد ملاحظة App Review تحت البند `Guideline 4 - Design`
- سبب الإصلاح الرئيسي: كانت طبقات CSS النهائية تفرض عرض هاتف ضيق وتخفي أجزاء مهمة من الواجهة حتى على الشاشات اللوحية، مما يؤدي إلى تجربة مزدحمة وغير محسنة
- تم تنفيذ طبقة استجابة نهائية تفصل بين:
  - الهاتف: واجهة مضغوطة كما كانت
  - الآيباد: تخطيط كامل بعرض مريح وإظهار العناصر التشغيلية والمحتوى بشكل أوضح
  - الشاشات العريضة: تخطيط موسع مع عمود جانبي ومحتوى رئيسي
- تم تحديث واجهة التطبيق لإظهار `1.0.1` داخل بطاقة الإصدار المرئية
- يلزم بعد ذلك إنشاء بناء جديد من هذا المصدر ثم رفعه إلى App Store Connect بدل البناء المرفوض القديم `42`

تاريخ المراجعة: 2026-07-01

## الحالة الحالية

- اسم التطبيق داخل المشروع: بطل الدروب
- اسم سجل App Store Connect الصحيح: بطل الدروب
- Apple ID لسجل بطل الدروب: `6786117376`
- Bundle ID الصحيح لتطبيق بطل الدروب: `com.batalaldroob.parts`
- الإصدار: `1.0`
- رقم البناء: `2`
- أقل إصدار iOS: `15.0`
- نوع المشروع: iOS WebView محلي يحتوي نسخة الويب داخل التطبيق
- مسار مشروع Xcode: `ios/BatalAlDroob/BatalAlDroob.xcodeproj`
- مخطط البناء: `BatalAlDroob`
- Team ID الصحيح: `4HM66AD594`
- حالة الرفع: تم رفع البناء إلى App Store Connect بنجاح، والبناء قيد معالجة Apple.
- ملاحظة مهمة: تطبيق `راح تفهم` منفصل ولم يتم تعديله أو إرساله للمراجعة ضمن هذا المسار.

## ما تم إنجازه

1. مزامنة نسخة الويب النهائية داخل تطبيق iOS.
2. تحديث Service Worker إلى `batal-droob-v13`.
3. التأكد من وجود الأيقونات داخل `Assets.xcassets`.
4. بناء نسخة Release بدون توقيع للتحقق من سلامة الكود.
5. التأكد من أن التطبيق ينتج ملف `.app` بنجاح.
6. التحقق من حساب Apple Developer داخل Xcode.
7. تصحيح Team ID داخل مشروع Xcode إلى `4HM66AD594`.
8. إنشاء Archive ناجح للتطبيق.
9. محاولة الرفع إلى App Store Connect.
10. اكتشاف أن سجل App Store Connect المفتوح كان لتطبيق آخر باسم `راح تفهم` وليس لتطبيق `بطل الدروب`.
11. إرجاع Bundle ID في مشروع Xcode إلى `com.batalaldroob.parts`.
12. إنشاء App ID صحيح في Apple Developer باسم `Batal Al-Droob` ومعرف `com.batalaldroob.parts`.
13. إنشاء سجل App Store Connect منفصل باسم `بطل الدروب`.
14. دمج قواعد بيانات الكتالوج داخل نسخة iOS، بما يشمل فهرس البحث وملفات PDF.
15. رفع أرشيف `BatalAlDroob` الصحيح إلى سجل `بطل الدروب` في App Store Connect.

## نتيجة البناء

نجح بناء iOS بدون توقيع:

```text
xcodebuild ... CODE_SIGNING_ALLOWED=NO build
** BUILD SUCCEEDED **
```

مسار التطبيق الناتج:

```text
build/BatalAlDroobDerivedData/Build/Products/Release-iphoneos/BatalAlDroob.app
```

حجم التطبيق الناتج تقريباً:

```text
23 MB
```

## نتيجة الأرشفة

تم إنشاء الأرشيف بنجاح:

```text
** ARCHIVE SUCCEEDED **
```

مسار الأرشيف:

```text
build/BatalAlDroob.xcarchive
```

بيانات الأرشيف:

```text
Bundle ID: com.batalaldroob.parts
Version: 1.0
Build: 1
Team: 4HM66AD594
```

## نتيجة الرفع الحالية

محاولة الرفع الأولى فشلت لأن Xcode كان يبحث عن تطبيق بهذا الـ Bundle ID:

```text
com.batalaldroob.parts
```

وسجل App Store Connect لم يكن يحتوي هذا الـ Bundle ID. بعد فحص صفحة App Store Connect تبين أن الصفحة المفتوحة كانت لتطبيق آخر باسم `راح تفهم` مرتبط بهذا الـ Bundle ID:

```text
com.shary17454.esal
```

تمت إعادة مشروع Xcode إلى Bundle ID الصحيح لتطبيق بطل الدروب:

```text
com.batalaldroob.parts
```

بعد ذلك تم إنشاء App ID وسجل App Store Connect الصحيحين لتطبيق `بطل الدروب`، ثم تم رفع البناء بنجاح:

```text
Uploaded BatalAlDroob
** EXPORT SUCCEEDED **
```

سجل App Store Connect الصحيح:

```text
Name: بطل الدروب
Apple ID: 6786117376
Bundle ID: com.batalaldroob.parts
```

حالة البناء بعد الرفع: قيد معالجة Apple داخل App Store Connect. قد يحتاج عدة دقائق قبل ظهوره في خانة Build.

## المطلوب لإكمال الإرسال للمراجعة

1. انتظار انتهاء معالجة البناء داخل App Store Connect.
2. ربط البناء المرفوع بإصدار `1.0`.
3. تعبئة الوصف والكلمات المفتاحية ومعلومات الإصدار.
4. رفع لقطات الشاشة المطلوبة.
5. إكمال تصنيف العمر Age Ratings.
6. إكمال App Privacy.
7. تحديد السعر والتوفر.
8. تعبئة ملاحظات المراجعة.
9. إرسال التطبيق للمراجعة.

## أمر الأرشفة المستخدم

```bash
xcodebuild \
  -project ios/BatalAlDroob/BatalAlDroob.xcodeproj \
  -scheme BatalAlDroob \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/BatalAlDroob.xcarchive \
  -allowProvisioningUpdates \
  archive
```

## أمر الرفع المستخدم

```bash
xcodebuild \
  -exportArchive \
  -archivePath build/BatalAlDroob.xcarchive \
  -exportOptionsPlist ios/BatalAlDroob/exportOptions.app-store.plist \
  -exportPath build/AppStore \
  -allowProvisioningUpdates
```

## قرار النشر

التطبيق تم بناؤه وأرشفته ورفعه بنجاح إلى سجل App Store Connect الصحيح باسم `بطل الدروب` باستخدام Bundle ID `com.batalaldroob.parts`. المتبقي قبل الإرسال للمراجعة هو إكمال بيانات المتجر والخصوصية والتصنيف ولقطات الشاشة ثم ربط البناء بعد انتهاء معالجة Apple.

## تحديث تنفيذ 2026-07-01 17:55

تم تنفيذ فحص جديد بعد طلب إكمال المتبقي:

- تم تأكيد أن سجل App Store Connect الصحيح لتطبيق `بطل الدروب` هو:
  - Apple ID: `6786117376`
  - Bundle ID: `com.batalaldroob.parts`
- تم تأكيد أن سجل `راح تفهم` تطبيق منفصل ويجب عدم تعديله ضمن هذا المشروع:
  - Apple ID: `6786065206`
  - Bundle ID: `com.shary17454.esal`
- تم إغلاق نافذة تصنيف العمر التي ظهرت داخل التطبيق الخطأ بدون إكمالها أو إرسالها.
- تم تشغيل بناء iOS جديد بدون توقيع:

```text
xcodebuild ... CODE_SIGNING_ALLOWED=NO build
** BUILD SUCCEEDED **
```

- تم تأكيد بيانات تطبيق iOS الناتج:

```text
Bundle ID: com.batalaldroob.parts
Version: 1.0
Build: 2
```

تم تحديث أيقونة التطبيق الخارجية إلى صورة الباترول الدائرية، وتجهيز نسخة محلية جديدة برقم بناء `2` حتى لا تتعارض مع البناء `1` المرفوع سابقاً.

- تم تشغيل تدقيق قاعدة بيانات Y60:

```text
record_count: 100574
part_count: 5125
source_count: 12
skipped_duplicate_count: 1
```

- التكرار الوحيد الذي تمت إزالته:

```text
Y60 1988.pdf
kept_source_id: 03_year_catalog_1988
skipped_source_id: 04_year_catalog_1988
```

- تم تأكيد فهارس نسخة iOS:

```text
catalog_search_index.entries: 5271
catalog_section_index.sections: 10
PDF files bundled in iOS app: 11
```

- تم تأكيد جاهزية ملفات App Store:

```text
iphone-67-ar-catalog.png: 1290x2796
iphone-67-en-catalog.png: 1290x2796
app-icon-1024.png: 1024x1024
```

- تم تأكيد سلامة ملفات JSON:

```text
catalog_search_index.json: valid JSON
catalog_section_index.json: valid JSON
```

## حاجز الإرسال النهائي

تم فتح Chrome على رابط `بطل الدروب` الصحيح:

```text
https://appstoreconnect.apple.com/apps/6786117376/distribution/ios/version/inflight
```

لكن أداة التحكم الرسومية التي تقرأ الشاشة ما زالت ترى نافذة App Store Connect القديمة الخاصة بتطبيق `راح تفهم`. لذلك لا يجوز استخدام الأداة لتعبئة بيانات المتجر أو الضغط على Submit، لأن ذلك قد يغيّر التطبيق الخطأ.

المتبقي بعد هذا الفحص هو عمل داخل App Store Connect فقط:

1. اختيار تطبيق `بطل الدروب` يدوياً من قائمة التطبيقات.

## تحديث تنفيذ 2026-07-01 23:55

تم تنفيذ جولة تجهيز إضافية بعد ملاحظة أن App Store Connect يعرض البناء القديم والأيقونة القديمة:

- تم استبدال أيقونة التطبيق الخارجية بأيقونة مربعة ممتدة للحواف من صورة الباترول، بدون دائرة داخلية وبدون هوامش بيضاء.
- تم توليد كل مقاسات AppIcon داخل:

```text
ios/BatalAlDroob/BatalAlDroob/Assets.xcassets/AppIcon.appiconset/
```

- تم تحديث أيقونات الويب داخل:

```text
assets/icons/
ios/BatalAlDroob/BatalAlDroob/Web/assets/icons/
app-store/icons/app-icon-1024.png
```

- تم رفع رقم البناء إلى:

```text
Version: 1.0
Build: 5
```

- تم إنشاء أرشيف iOS جديد:

```text
build/BatalAlDroob-Build5.xcarchive
```

- تم تصدير IPA جديد:

```text
build/BatalAlDroob-Build5-IPA/BatalAlDroob.ipa
```

- تم التحقق من IPA لدى Apple:

```text
VERIFY SUCCEEDED with no errors
```

- تم رفع IPA إلى App Store Connect بنجاح:

```text
UPLOAD SUCCEEDED with no errors
Delivery UUID: 9e86afcc-38ae-4ca9-a492-0581fe432a73
```

- تم التأكد عبر App Store Connect API أن البناء الجديد وصل وأصبح صالحاً:

```text
Build: 5
processingState: VALID
usesNonExemptEncryption: false
```

- تم إنشاء منتج الشراء داخل التطبيق:

```text
Product ID: batal.catalog.unlock
Type: CONSUMABLE
Apple IAP ID: 6786440522
State: MISSING_METADATA
```

- سبب بقاء حالة الشراء `MISSING_METADATA`: مفتاح App Store Connect API الحالي يسمح بإنشاء المنتج، لكنه منع إضافة ترجمات/وصف المنتج برسالة:

```text
The API key in use does not allow this request
```

المتبقي داخل App Store Connect:

1. إضافة اسم ووصف منتج الشراء:
   - Arabic/Saudi Arabia: `فتح كتالوج أو رقم قطعة`
   - Description: `يفتح رقم قطعة أو صفحة كتالوج محمية داخل تطبيق بطل الدروب.`
   - English/US: `Catalog or Part Number Unlock`
   - Description: `Unlocks one protected part number or catalog page in Batal Al-Droob.`
2. تحديد السعر الرمزي. أقل نقطة سعر سعودية ظهرت من Apple:

```text
0.99 SAR
```

3. رفع لقطة شاشة مراجعة لمنتج الشراء إن طلبتها Apple.
4. ربط Build 5 بإصدار TestFlight/App Store.
5. إكمال App Privacy وAge Rating وبيانات الإصدار.
6. إرسال التطبيق للمراجعة بعد اكتمال بيانات الشراء.
2. ربط البناء المعالج بإصدار `1.0`.
3. رفع لقطات الشاشة.
4. لصق الوصف والكلمات المفتاحية والنص الترويجي.
5. إدخال روابط الخصوصية والدعم.
6. إكمال Age Rating بقيم `No/None` لأن التطبيق مرجع قطع بدون محتوى حساس.
7. إكمال App Privacy: لا يجمع بيانات ولا يتتبع المستخدم.
8. اختيار السعر والتوفر.
9. إرسال التطبيق للمراجعة بعد تأكيد المالك.

## تحديث الأيقونة ورفع Build 2 - 2026-07-01 18:12

تم اعتماد الصورة الجديدة كصورة التطبيق الخارجية وأيقونة التطبيق، وتم توليد المقاسات التالية منها:

- App Store icon: `app-store/icons/app-icon-1024.png` بحجم `1024x1024`.
- iOS AppIcon كامل داخل:
  - `ios/BatalAlDroob/BatalAlDroob/Assets.xcassets/AppIcon.appiconset/`
- Web/PWA icons:
  - `assets/icons/icon-192.png`
  - `assets/icons/icon-512.png`
  - `assets/icons/apple-touch-icon.png`
  - `flutter_y60_catalog/web/icons/`

تم رفع رقم البناء إلى:

```text
Version: 1.0
Build: 2
Bundle ID: com.batalaldroob.parts
```

تم بناء التطبيق بنجاح بعد تغيير الأيقونة:

```text
** BUILD SUCCEEDED **
```

تم إنشاء Archive جديد:

```text
build/BatalAlDroob-Build2.xcarchive
Bundle ID: com.batalaldroob.parts
Version: 1.0
Build: 2
```

تم رفع Build 2 إلى App Store Connect بنجاح:

```text
Uploaded BatalAlDroob
** EXPORT SUCCEEDED **
```

حالة Build 2 بعد الرفع: مرفوع وينتظر معالجة Apple داخل App Store Connect قبل اختياره في صفحة الإصدار.

## تحديث امتثال التشفير - 2026-07-01 18:48

ظهرت شاشة App Store Connect داخل TestFlight تطلب:

```text
Determine Compliance Requirements
```

تمت معالجة ذلك داخل التطبيق بإضافة مفتاح Apple الرسمي:

```text
ITSAppUsesNonExemptEncryption = false
```

ثم تم رفع رقم البناء إلى:

```text
Version: 1.0
Build: 3
Bundle ID: com.batalaldroob.parts
```

تم بناء Build 3 بنجاح:

```text
** BUILD SUCCEEDED **
```

وتم إنشاء الأرشيف بنجاح:

```text
build/BatalAlDroob-Build3.xcarchive
** ARCHIVE SUCCEEDED **
```

لكن رفع Build 3 توقف بسبب صلاحية حساب Xcode/App Store Connect:

```text
** EXPORT FAILED **
error: exportArchive Failed to Use Accounts
App Store Connect access for “شري بن حشيم العتيبي” is required.
Ensure that your Apple Account usernames and passwords are correct in Accounts settings.
```

المعنى: Build 3 جاهز محلياً، لكن يحتاج إعادة تسجيل دخول/اعتماد حساب Apple داخل Xcode حتى يتم رفعه. آخر Build مرفوع فعلياً إلى App Store Connect حتى الآن هو Build 2.
## تحديث 2026-07-01 - Build 4

تم تجهيز نسخة جديدة من تطبيق **بطل الدروب**:

- الاسم داخل التطبيق: بطل الدروب
- Bundle ID: `com.batalaldroob.parts`
- الإصدار: `1.0`
- رقم البناء: `4`
- التشفير: `ITSAppUsesNonExemptEncryption = false`
- الأرشيف: `build/BatalAlDroob-Build4.xcarchive`

### ما تم فحصه

- فحص JavaScript: ناجح.
- مزامنة ملفات الويب داخل حزمة iOS: ناجحة.
- بناء Release على iOS: ناجح.
- إنشاء أرشيف App Store: ناجح.
- التحقق من Info.plist داخل الأرشيف: مطابق للاسم والحزمة والبناء.

### حالة الدفع

تمت إضافة بوابة دفع داخل التطبيق عبر StoreKit للمنتج:

```text
batal.catalog.unlock
```

يجب إنشاء هذا المنتج في App Store Connect كشراء داخل التطبيق من نوع Consumable وربطه بالنسخة قبل اعتماد الدفع فعليًا في TestFlight/App Store.

### حالة حماية الشاشة

تمت إضافة حماية عملية داخل iOS:

- حجب المحتوى عند تسجيل الشاشة أو العرض الخارجي.
- غطاء خصوصية عند خروج التطبيق للخلفية.
- تنبيه عند التقاط Screenshot.

ملاحظة: iOS لا يسمح بمنع Screenshot بنسبة 100٪ داخل التطبيقات العادية، لكن تم تنفيذ أقصى حماية نظامية عملية.

### نتيجة الرفع

محاولة رفع Build 4 إلى App Store Connect فشلت بسبب حساب Xcode:

```text
Failed to Use Accounts
App Store Connect access for “شري بن حشيم العتيبي” is required.
```

محاولة تصدير IPA فشلت أيضًا بسبب عدم وجود شهادة توزيع:

```text
No Accounts
No signing certificate "iOS Distribution" found
```

### المطلوب لإكمال الرفع

1. فتح Xcode على الماك.
2. الدخول إلى Settings > Accounts.
3. تسجيل الدخول أو تحديث جلسة Apple ID المطور.
4. التأكد أن الحساب يظهر له App Store Connect access للفريق `شري بن حشيم العتيبي`.
5. التأكد أن Xcode يستطيع إنشاء شهادة `Apple Distribution / iOS Distribution`.
6. إنشاء منتج الشراء داخل التطبيق `batal.catalog.unlock` في App Store Connect.
7. إعادة تنفيذ رفع Build 4 أو بناء Build 5 إذا تم تعديل أي ملف بعدها.
