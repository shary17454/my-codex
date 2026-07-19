# تقرير إصلاح إعدادات App Store وXcode Cloud

تاريخ التقرير: 2026-07-19
نطاق التقرير: تطبيق `وش الرأي` فقط داخل `StudyVaultApp`.

## 1. بيانات التطبيق

| البند | القيمة |
|---|---|
| اسم التطبيق | وش الرأي |
| Apple App ID | 6786065206 |
| Bundle Identifier | `com.shary17454.esal` |
| Xcode project | `StudyVault.xcodeproj` |
| Scheme | `StudyVault` |
| Target | `StudyVault` |
| عدد Targets داخل المشروع | 1 |
| Extensions / Widgets | غير موجودة داخل هذا المشروع |

## 2. سياق App Store Connect من الدردشة

| البند | القيمة |
|---|---|
| آخر إصدار منشور في App Store Connect | 1.9.0 بحالة Ready for Distribution |
| أحدث Version تمت محاولة رفعه | 1.10.0 |
| أحدث Build تمت محاولة رفعه | 51 |
| أعلى Build Upload ظاهر | 1.10.0 (51) بحالة Complete وReady to Submit |
| الإصدار الجديد المختار | 1.10.0 |
| Build الجديد المختار | 52 |

الإصدار `1.10.0` أعلى من آخر إصدار منشور `1.9.0`، ومساره ظاهر في Build Uploads. تم اختيار Build `52` لأنه أعلى من كل Builds الظاهرة حتى `51`، كما تأكد أن Xcode Cloud يعرض Next Build Number بقيمة `52`.

## 3. رموز ITMS والسبب الجذري

| الرمز | السبب العملي | الإجراء |
|---|---|---|
| ITMS-90111 | بناء بإصدار Xcode/SDK غير مدعوم للإرسال الإنتاجي | إضافة `ci_post_clone.sh` لإيقاف Xcode Cloud إذا لم يستخدم Xcode 26.6 `17F113` وSDK مناسب |
| ITMS-90478 | Version غير صالح أو غير مطابق لحالة App Store Connect | رفع Marketing Version إلى `1.10.0` |
| ITMS-90186 | Pre-Release Train مغلق للإرسال الجديد | عدم إعادة استخدام `1.4` أو `1.5` أو `1.9.0`، واستخدام `1.10.0` |
| ITMS-90062 | `CFBundleShortVersionString` يجب أن يكون أعلى من الإصدار المعتمد | ضبط `MARKETING_VERSION = 1.10.0` |
| تعارض Build Number | Build مستخدم سابقًا أو أقل من Build ظاهر | ضبط `CURRENT_PROJECT_VERSION = 52` وNext Build Number على `52` |
| اختلاف القيم بين المشروع والأرشيف | المشروع كان `1.9.0 (30)` بينما App Store Connect أظهر `1.9.0 (35)` | توحيد مصدر القيم من Build Settings وفحص المنتج المبني |

## 4. الملفات المعدلة

| الملف | سبب التعديل |
|---|---|
| `StudyVault.xcodeproj/project.pbxproj` | توحيد `MARKETING_VERSION` على `1.10.0` و`CURRENT_PROJECT_VERSION` على `52` في Debug وRelease |
| `ci_scripts/ci_post_clone.sh` | توجيه Workflow وش الرأي إلى حارس الإصدار الخاص به دون تغيير حارس التطبيقات الأخرى |
| `StudyVaultApp/ci_scripts/ci_post_clone.sh` | منع Xcode Beta أو SDK غير مناسب والتحقق من `1.10.0` وBuild لا يقل عن `52` |
| `AppStore/release_notes.md` | إضافة ملاحظات إصدار `1.10.0` بالعربية والإنجليزية |
| `docs/RELEASE_CHECKLIST.md` | تحديث Checklist للإصدار الجديد وخطوات Xcode Cloud اليدوية |
| `scripts/submit_app_store_version.mjs` | تحديث القيم الافتراضية اليدوية إلى `1.10.0 (52)` بدل قيم قديمة |

## 5. القيم الفعلية بعد البناء المحلي

تم فحص التطبيق الفعلي داخل الأرشيف المحلي الجديد:

`/tmp/StudyVault-1.10.0-52-final-20260719.xcarchive/Products/Applications/StudyVault.app/Info.plist`

| المفتاح | القيمة |
|---|---|
| CFBundleIdentifier | `com.shary17454.esal` |
| CFBundleDisplayName | وش الرأي |
| CFBundleShortVersionString | `1.10.0` |
| CFBundleVersion | `52` |
| DTPlatformName | `iphoneos` |
| DTPlatformVersion | `26.4` |
| DTSDKName | `iphoneos26.4` |
| DTSDKBuild | `23E252` |
| DTXcode | `2641` |
| DTXcodeBuild | `17E202` |
| MinimumOSVersion | `17.0` |

ملاحظة: هذه قيم بناء محلي فقط. لا يجوز اعتبارها Archive إنتاجيًا لأن Xcode المحلي هو 26.4.1 وليس Xcode Cloud 26.6 المطلوب.

## 6. إعداد Xcode Cloud الذي تم التحقق منه

1. التطبيق المحدد: `وش الرأي`، Apple App ID `6786065206`.
2. Workflow: `Default`.
3. المشروع: `StudyVaultApp/StudyVault.xcodeproj`.
4. Scheme: `StudyVault`.
5. Trigger: تغييرات الفرع `main`.
6. Xcode Version: Latest Release، ويعرض حاليًا Xcode 26.6 (`17F113`).
7. الإجراءات: Build iOS وArchive iOS مع التحضير لـApp Store Connect.
8. Next Build Number: `52`.
9. المتبقي: تشغيل Workflow من Commit النهائي ثم فحص Artifact السحابي الجديد.

## 7. جدول PASS / FAIL

| الشرط | النتيجة | الدليل |
|---|---|---|
| Bundle ID لم يتغير | PASS | بقي `com.shary17454.esal` |
| Development Team لم يتغير | PASS | بقي `4HM66AD594` في إعدادات المشروع |
| Signing/Entitlements لم تتغير | PASS | لم يتم تعديل `CODE_SIGN_STYLE` أو entitlements |
| Marketing Version أعلى من آخر إصدار منشور | PASS | `1.10.0` أعلى من `1.9.0` |
| Build Number أعلى من آخر Build ظاهر | PASS | `52` أعلى من `51` |
| `CFBundleShortVersionString` يأخذ من `$(MARKETING_VERSION)` | PASS | `Info.plist` يستخدم المتغير |
| `CFBundleVersion` يأخذ من `$(CURRENT_PROJECT_VERSION)` | PASS | `Info.plist` يستخدم المتغير |
| Target الرئيسي يحمل القيم الجديدة | PASS | الأرشيف المحلي أظهر `1.10.0 (52)` |
| Extensions/Widgets متوافقة | PASS | لا توجد Extensions أو Widgets داخل هذا المشروع |
| Release Build بدون توقيع | PASS | `xcodebuild ... -configuration Release ... build` نجح |
| Resolve Package Dependencies | PASS | لا توجد حزم خارجية، والأمر نجح |
| Unit Tests | PASS | 9/9 |
| UI Smoke Test | PASS | 1/1 على iPhone 17 Simulator |
| Xcode المحلي مطابق للإنتاج المطلوب | FAIL | المحلي `26.4.1 (17E202)`، المطلوب لـXcode Cloud `26.6 (17F113)` |
| Archive محلي جديد بعد آخر تعديل برمجي | PASS | `/tmp/StudyVault-1.10.0-52-final-20260719.xcarchive` |
| Archive سحابي موقّع بـXcode 26.6 | PENDING | يبدأ بعد Push إلى `main` |
| Build Uploads لا يحتوي Build 52 قبل التشغيل | PASS | أعلى Build ظاهر هو `51` وNext Build Number هو `52` |

## 8. قرار النشر

الحالة قبل تشغيل Xcode Cloud: `READY_WITH_EXTERNAL_REQUIREMENTS`.

لا ترفع ولا ترسل للمراجعة قبل:

- دفع Commit النهائي إلى `main` لتشغيل Workflow الموثق.
- انتظار Archive السحابي الموقّع وفحص أنه مبني بـXcode 26.6 (`17F113`) ويحمل `1.10.0 (52)`.
- اختبار Sign in with Apple والإشعارات وVoiceOver على جهاز فعلي.
- مراجعة App Privacy Labels وExport Compliance والبيانات القانونية داخل App Store Connect قبل الإرسال للمراجعة.
