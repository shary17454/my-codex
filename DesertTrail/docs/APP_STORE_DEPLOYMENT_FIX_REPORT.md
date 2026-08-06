# تقرير إصلاح إعدادات النشر - الدرب

تاريخ التقرير: 2026-07-15

## الملخص

تم تنفيذ إصلاح محدود وآمن لإعدادات النشر الخاصة بتطبيق `الدرب` فقط، دون تغيير Bundle Identifier أو Team أو Signing أو Entitlements أو Capabilities أو وظائف التطبيق.

الهدف كان منع تكرار أخطاء App Store Connect المرتبطة بإصدار Xcode/SDK وأرقام الإصدار والبناء، وتجهيز المشروع ليبنى عبر Xcode Cloud باستخدام Xcode إنتاجي بدل Xcode beta.

## بيانات التطبيق

| البند | القيمة |
|---|---|
| اسم التطبيق من المشروع | الدرب |
| Apple ID من سياق App Store Connect | 6787725503 |
| Bundle Identifier | com.codex.Kharayem |
| Development Team | 4HM66AD594 |
| Xcode Project | Kharayem/Kharayem.xcodeproj |
| Scheme | Kharayem |
| Targets المكتشفة | Kharayem فقط |
| Extensions / Widgets | لا توجد في المشروع الحالي |

## رموز ITMS المستخرجة من السياق

| الرمز | السبب الجذري | الإجراء |
|---|---|---|
| ITMS-90111 | استخدام Xcode/SDK غير مدعوم للإرسال، خصوصًا Xcode 27 beta | إضافة حارس Xcode Cloud يرفض beta ويتطلب Xcode 26.6 (17F113) |
| ITMS-90186 | محاولة إرسال بناء على train تجريبي/إصدار مغلق | إبقاء الإصدار الحالي على train جديد أعلى من الإصدارات المغلقة: 1.9.1 |
| ITMS-90062 | CFBundleShortVersionString غير أعلى من إصدار سبق اعتماده أو غير مطابق | توحيد Marketing Version على 1.9.1 في المشروع وInfo.plist |
| ITMS-90478 | رقم/صيغة إصدار غير صالح أو غير مطابق لمسار App Store Connect | توحيد الإصدار والبناء وتوثيق خطوات إنشاء/اختيار الإصدار الصحيح في App Store Connect |

## الإصدار والبناء

| البند | قبل الإصلاح | بعد الإصلاح |
|---|---:|---:|
| MARKETING_VERSION | 1.9.1 | 1.9.1 |
| CURRENT_PROJECT_VERSION | 68 | 76 |
| CFBundleShortVersionString | $(MARKETING_VERSION) | $(MARKETING_VERSION) |
| CFBundleVersion | $(CURRENT_PROJECT_VERSION) | $(CURRENT_PROJECT_VERSION) |

سبب اختيار Build `76`: أعلى رقم ظاهر في سياق الدردشة كان ضمن محاولات Xcode Cloud الأخيرة، وتم اختيار رقم أعلى منه لتجنب إعادة استخدام أي Build سابق أو فاشل.

## إعداد Xcode Cloud المطلوب

يجب ضبط Workflow يدويًا في App Store Connect:

1. افتح App Store Connect.
2. اختر تطبيق `الدرب`.
3. افتح `Xcode Cloud`.
4. افتح `Manage Workflows`.
5. عدّل الـ Workflow المستخدم للفرع `main`.
6. في `Environment` اختر:
   - Xcode Version: `Xcode 26.6 (17F113)` أو أحدث إصدار إنتاجي تسمح Apple صراحة باستخدامه للإرسال.
   - لا تختَر `Latest Beta`.
   - لا تستخدم Xcode 27 beta.
7. تأكد أن Actions تحتوي:
   - `Build - iOS`
   - `Archive - iOS`
8. اجعل `Archive - iOS` يستخدم:
   - Platform: iOS
   - Scheme: Kharayem
   - Distribution Preparation: App Store Connect
9. اضبط `Next Build Number` على `76` أو أعلى، مع عدم الرجوع لأي رقم مستخدم سابقًا.
10. شغّل Build جديد من commit يحتوي هذا الإصلاح.

## الحارس المضاف لـ Xcode Cloud

تمت إضافة:

`ci_scripts/ci_post_clone.sh`

وظيفته:

- طباعة نسخة Xcode وBuild Version.
- طباعة مسار xcode-select.
- طباعة نسخة ومسار iPhoneOS SDK.
- طباعة بيانات Xcode Cloud المهمة إن وجدت.
- إيقاف البناء مبكرًا إذا كان Xcode beta.
- إيقاف البناء إذا لم يكن Xcode `26.6 (17F113)` وفق الإعداد الحالي.
- إيقاف البناء إذا كانت أرقام الإصدار أو البناء غير موحدة.
- إيقاف البناء إذا كان ملف المشروع المتوقع غير موجود.

الحارس لا يغيّر الإصدار أو رقم البناء، ولا يغيّر Signing.

## نتائج الفحص المحلي

| الفحص | النتيجة | ملاحظة |
|---|---|---|
| xcodebuild -list | نجح | Scheme: Kharayem |
| Release showBuildSettings | نجح | 1.9.1 / 76، Bundle ID لم يتغير |
| Release simulator build | نجح | BUILD SUCCEEDED |
| Unit/UI tests | لم تُشغّل | Scheme Kharayem غير مهيأ لـ test action |
| ci_post_clone.sh مع override محلي | نجح | تحقق من منطق الحارس والقيم |
| ci_post_clone.sh بدون override | فشل كما هو متوقع | الجهاز المحلي يستخدم Xcode 26.4.1 وليس 26.6 |
| git diff --check | نجح | لا توجد مشاكل whitespace |
| conflict markers | نجح | لا توجد علامات تعارض |

## قيم الأرشيف المحلي الفعلي

تم إنشاء أرشيف محلي غير مخصص للرفع إلى App Store لأن البيئة المحلية تستخدم Xcode 26.4.1. القيم داخل الأرشيف كانت:

| المفتاح | القيمة |
|---|---|
| CFBundleIdentifier | com.codex.Kharayem |
| CFBundleDisplayName | الدرب |
| CFBundleShortVersionString | 1.9.1 |
| CFBundleVersion | 76 |
| DTPlatformName | iphoneos |
| DTPlatformVersion | 26.4 |
| DTSDKName | iphoneos26.4 |
| DTSDKBuild | 23E252 |
| DTXcode | 2641 |
| DTXcodeBuild | 17E202 |
| MinimumOSVersion | 17.0 |

هذه القيم تثبت أن المشروع يوحّد الإصدار والبناء، لكنها لا تكفي للرفع لأن Xcode/SDK المحليين ليسا البيئة المطلوبة للإرسال.

## App Store Connect

الخطوات اليدوية قبل الإرسال:

1. إذا كان الإصدار `1.8` منشورًا أو مغلقًا، لا تستخدمه للبناء الجديد.
2. استخدم إصدار iOS في App Store Connect مطابقًا لـ `1.9.1`.
3. اختر Build `76` أو أعلى بعد أن ينتهي Xcode Cloud من `Processing`.
4. املأ حقل Arabic `What's New in This Version`.
5. راجع Screenshots وApp Privacy وCompliance قبل الضغط على Add for Review.

## جدول الشروط

| الشرط | الحالة |
|---|---|
| عدم تغيير Bundle ID | PASS |
| عدم تغيير Development Team | PASS |
| عدم تغيير Signing/Entitlements | PASS |
| توحيد MARKETING_VERSION | PASS |
| توحيد CURRENT_PROJECT_VERSION | PASS |
| Info.plist يستخدم متغيرات المشروع | PASS |
| عدم وجود Extensions بإصدارات مختلفة | PASS |
| حماية من Xcode beta | PASS |
| حماية من SDK غير مناسب | PASS |
| Build محلي simulator | PASS |
| Archive إنتاجي Xcode Cloud | MANUAL REQUIRED |
| إرسال إلى App Review | NOT DONE BY DESIGN |

## الحالة النهائية

الحالة: `READY_WITH_MANUAL_STEPS`

المشروع جاهز لأن يبنيه Xcode Cloud بعد ضبط Workflow على Xcode إنتاجي مسموح. لم يتم الرفع أو الإرسال للمراجعة تنفيذًا للتعليمات.
