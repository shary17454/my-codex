# دليل رفع بطل الدروب إلى App Store

## 1. بعد موافقة Apple Developer

افتح Xcode ثم افتح المشروع:

`ios/BatalAlDroob/BatalAlDroob.xcodeproj`

## 2. ضبط التوقيع

من Xcode:

1. اختر مشروع `BatalAlDroob`.
2. اختر Target باسم `BatalAlDroob`.
3. افتح تبويب `Signing & Capabilities`.
4. اختر حساب Apple Developer في خانة `Team`.
5. تأكد من Bundle ID:

`com.batalaldroob.parts`

يمكن تغييره إذا كان محجوزًا.

## 3. تجربة التطبيق

شغل التطبيق على iPhone أو Simulator. النسخة الحالية تفتح ملفات الويب المضمنة داخل التطبيق، ولا تعتمد على `localhost`.

## 4. إنشاء التطبيق في App Store Connect

القيم المقترحة:

- Name: `Batal Al-Droob` أو `بطل الدروب`
- Bundle ID: `com.batalaldroob.parts`
- SKU: `batal-droob-y60`
- Category: `Reference` أو `Utilities`

## 5. الخصوصية والدعم

ارفع الملفات التالية على رابط HTTPS عام:

- `privacy.html`
- `support.html`

ثم ضع روابطها في App Store Connect.

## 6. الأيقونة والصور

الأيقونة:

`app-store/icons/app-icon-1024.png`

لقطات الشاشة:

- `app-store/screenshots/iphone-67-ar-catalog.png`
- `app-store/screenshots/iphone-67-en-catalog.png`

## 7. الأرشفة والرفع

من Xcode:

1. اختر جهاز `Any iOS Device`.
2. من القائمة اختر `Product > Archive`.
3. بعد انتهاء الأرشفة، اضغط `Distribute App`.
4. اختر `App Store Connect`.
5. ارفع النسخة.

## 8. ملاحظات المراجعة

انسخ محتوى:

`app-store/review_notes.md`

في خانة Review Notes.

## ملاحظة فنية

تم التحقق أن مشروع Xcode يظهر في `xcodebuild -list`. البناء داخل بيئة Codex لم يكتمل بسبب تعطل خدمات Simulator/actool في البيئة، وليس بسبب ملفات المشروع. يجب تجربة الأرشفة من Xcode محليًا بعد تسجيل الدخول بحساب Apple Developer.
