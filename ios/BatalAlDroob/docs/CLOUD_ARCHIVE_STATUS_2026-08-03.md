# حالة إصدار وأرشفة بطل الدروب

التاريخ: 2026-08-03  
الإصدار الموثق: `2.6 (186)`  
المالك: شري العتيبي  
البريد: `sharyalhwaid@gmail.com`

## المصدر والإصدار

- الجذر الرسمي: `/Users/shrybnhshymbnmrzwqbnhwyd/Documents/Codex/2026-07-01/ios-gps-magellan-qr-1-mapkit/ios/BatalAlDroob`
- Bundle ID: `com.batalaldroob.parts`.
- الحد الأدنى: iOS/iPadOS 17.0.
- مصدر بناء TestFlight: commit `d63806a80851e28da54dac25ca831d023023e8bb`.
- وسم مصدر البناء: `v2.6.186`.
- لم يتغير Development Team أو Signing أو Entitlements أو Capabilities.

## التحقق الهندسي

| البوابة | النتيجة |
|---|---|
| Release validator | ناجح |
| Catalog validator | ناجح: 640/640 PDF، 12.51 GiB |
| Backend tests | ناجح: 9/9 |
| Unit tests | ناجح: 45/45 |
| UI tests | ناجح: 3/3 |
| إجمالي اختبارات iOS | ناجح: 48/48 |
| Local unsigned xcarchive | ناجح: 2.6 (186)، 109 MB تقريبًا |
| حارس xcarchive | ناجح للهوية والإصدار والبناء وXcode وSDK وiOS minimum |
| SwiftLint strict | متبقٍ 83 مخالفة نمطية/هيكلية معروفة |

## GitHub وXcode Cloud وTestFlight

- دُفع مصدر الإصدار إلى GitHub، ويشير الوسم `v2.6.186` إلى مصدر البناء المختبر.
- نجح Xcode Cloud build `186` في مرحلتي Build وArchive باستخدام Xcode 26.6 (`17F113`).
- نجحت Prepare Build for App Store Connect.
- ظهر build `186` تحت الإصدار `2.6` في TestFlight بحالة `Ready to Submit`.
- لم يُرسل build `186` إلى App Review.
- الإصدار المنشور الحالي هو `2.5 (180)` بحالة `Ready for Distribution`.

## موارد الكتالوج

| الجيل | الملفات |
|---|---:|
| Y60 | 297 |
| Y61 | 143 |
| Y62 | 140 |
| عام / غير مصنف | 60 |
| الإجمالي | 640 |

يوجد 612 محتوى فريدًا حسب SHA-256. المصدر الرسمي ونسخة الأرشفة المحلية يحتويان الموارد الكاملة. ملفات PDF الكبيرة مستثناة من Git، ولذلك يحتوي checkout الخاص بـGitHub وXcode Cloud على الفهارس وبيانات البحث فقط.

## الأرشيف الكامل

- الاسم الخارجي: `BatalAlDroob-Complete-Project/Source-Code-Archive.zip`.
- يحتوي 640 ملف PDF مع الكود والاختبارات والوثائق وموارد المشروع.
- استُبعد `.env.local` وأي سر تشغيل، وبقي `.env.example` بقيم إرشادية فقط.
- هذا التقرير موجود داخل ZIP نفسه؛ لذلك تُحفظ بصمة ZIP النهائية وحجمه ونتيجة سلامته في النسخة الخارجية من `Documentation/CLOUD_ARCHIVE_STATUS_2026-08-03.md` منعًا لمرجع بصمة دائري.

## PDF والبريد

- الملف: `Documentation/BatalAlDroob-Full-Documentation.pdf`.
- 43 صفحة A4 مضغوطة، تشمل التوثيق والكود الكامل لملفات Swift.
- بصمة PDF: `732a661690f69ecfe92fcf4c2596ab74beaa87eb9fb7afba2c13cbe28011f5a4`.
- تم فحص جميع الصفحات بصريًا ولم تظهر صفحات فارغة أو قص غير مقصود.
- تم إرسال PDF فعليًا إلى البريد المتصل بعنوان `كود بطل الدروب - التوثيق الكامل 2.6 (186)`.

## حدود التوزيع

- الحزمة المحلية التي تضم 640 ملف PDF تقارب 13 GB، وتتجاوز حد Apple البالغ 4 GB للتطبيق غير المضغوط.
- بناء Xcode Cloud رقم 186 حجمه قرابة 100 MB ويحتوي صفر PDF.
- لا يجوز إرسال build `186` للمراجعة على أنه النسخة الكاملة قبل نقل الموارد إلى Apple-hosted Background Assets أو خدمة تنزيل مصادق عليها، مع التحقق من الاستحقاق وSHA-256 والتخزين المؤقت والعمل دون شبكة.

## الذكاء الاصطناعي

عميل وخادم AI واختبارات الحماية موجودة، لكن لا يوجد backend مستضاف ومكوّن في build `186`. التطبيق يعمل بالمساعد المحلي فقط. يلزم نشر الخادم وتكوين `AIAssistantBaseURL` و`AIAssistantClientToken` بأمان قبل وصف المساعد بأنه متصل بخدمة AI خارجية.
