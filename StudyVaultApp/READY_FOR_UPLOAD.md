# جاهزية تطبيق وش الراي

جهزت التطبيق للرفع قدر الإمكان من داخل المشروع.

## الموجود الآن

- اسم التطبيق للمستخدم: `وش الراي`
- Bundle ID: `com.shary17454.esal`
- Version: `1.5`
- Build: `27`
- مشروع Xcode: `StudyVault.xcodeproj`
- الأيقونة مضافة داخل Assets.
- التطبيق يعرض فكرة "وش رأي الناس؟": أمثلة مقارنة تبدأ من صفر، مع تصويت وتعليقات محلية من المستخدم.
- بيانات App Store موجودة في مجلد `AppStore`.
- Privacy Manifest موجود.
- Scheme مشترك مضاف حتى يظهر في Xcode والأرشفة.

## المتبقي فقط

لا أستطيع تنفيذ خطوة الإرسال النهائية من App Store Connect بدلًا عنك إذا حظر المتصفح التحكم الآلي، لأنها تحتاج حساب Apple Developer الخاص بك:

1. افتح `StudyVault.xcodeproj` في Xcode.
2. سجّل الدخول بحساب Apple Developer.
3. اختر Team الخاص بك في Signing.
4. اختر `Any iOS Device`.
5. من القائمة اختر `Product > Archive`.
6. بعد انتهاء الأرشفة اختر `Distribute App` ثم ارفع إلى App Store Connect.
7. في App Store Connect أنشئ أو افتح نسخة `iOS 1.5` ثم اختر البناء `27` أو أي بناء أحدث يحمل `CFBundleShortVersionString = 1.5`.

إذا رفضت Apple المعرف `com.shary17454.esal`، استخدم معرفًا آخر تملكه مثل:

```text
com.shary17454.esalapp
```

## ملاحظة عن هذا الجهاز

تم التحقق من أن المشروع يبني بنجاح عبر `xcodebuild` عند استخدام وجهة `generic/platform=iOS`.
إذا ظهر على جهاز آخر تنبيه عن نقص iOS platform أو Simulator runtime، افتح Xcode ثم نزّل المكونات المطلوبة من:

```text
Xcode > Settings > Components
```
