# جاهزية تطبيق اسأل

جهزت التطبيق للرفع قدر الإمكان من داخل المشروع.

## الموجود الآن

- اسم التطبيق للمستخدم: `اسأل`
- Bundle ID: `com.shary17454.esal`
- مشروع Xcode: `StudyVault.xcodeproj`
- الأيقونة مضافة داخل Assets.
- التطبيق يعرض فكرة "اسأل الناس": أمثلة مقارنة تبدأ من صفر، مع تصويت وتعليقات محلية من المستخدم.
- بيانات App Store موجودة في مجلد `AppStore`.
- Privacy Manifest موجود.
- Scheme مشترك مضاف حتى يظهر في Xcode والأرشفة.

## المتبقي فقط

لا أستطيع تنفيذ هذه النقطة بدلًا عنك لأنها تحتاج حساب Apple Developer الخاص بك:

1. افتح `StudyVault.xcodeproj` في Xcode.
2. سجّل الدخول بحساب Apple Developer.
3. اختر Team الخاص بك في Signing.
4. اختر `Any iOS Device`.
5. من القائمة اختر `Product > Archive`.
6. بعد انتهاء الأرشفة اختر `Distribute App` ثم ارفع إلى App Store Connect.

إذا رفضت Apple المعرف `com.shary17454.esal`، استخدم معرفًا آخر تملكه مثل:

```text
com.shary17454.esalapp
```

## ملاحظة عن هذا الجهاز

Xcode في هذه البيئة لا يحتوي iOS platform المطلوب، لذلك لا يمكن تنفيذ Archive فعليًا هنا. الرسالة كانت:

```text
iOS 26.5 is not installed. Please download and install the platform from Xcode > Settings > Components.
```

على جهازك افتح Xcode ثم نزّل iOS platform من `Xcode > Settings > Components` إذا ظهر نفس التنبيه.
