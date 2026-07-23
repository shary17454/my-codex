# تقرير إصلاح إعدادات App Store وXcode Cloud

تاريخ التقرير: 2026-07-23
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
| آخر إصدار منشور/مغلق في App Store Connect | 1.10.0 |
| أحدث Version تمت محاولة رفعه | 1.10.0 |
| أحدث Build تمت محاولة رفعه | 69 |
| أعلى Build مذكور في رسائل Apple | 69 |
| الإصدار الجديد المختار | 1.11.0 |
| Build الجديد المختار | 70 |

رسالة Apple الأخيرة أوضحت أن مسار الإصدار `1.10.0` مغلق ولا يقبل Builds جديدة، وأن `CFBundleShortVersionString` يجب أن يكون أعلى من الإصدار المعتمد `1.10.0`. لذلك تم اختيار الإصدار `1.11.0` وBuild `70` لأنه أعلى من Build المرفوض `69`.

## 3. رموز ITMS والسبب الجذري

| الرمز | السبب العملي | الإجراء |
|---|---|---|
| ITMS-90111 | بناء بإصدار Xcode/SDK غير مدعوم للإرسال الإنتاجي | إضافة `ci_post_clone.sh` لإيقاف Xcode Cloud إذا لم يستخدم Xcode 26.6 `17F113` وSDK مناسب |
| ITMS-90478 | Version غير صالح أو غير مطابق لحالة App Store Connect | استخدام إصدار أعلى من الإصدار المغلق |
| ITMS-90186 | Pre-Release Train `1.10.0` مغلق للإرسال الجديد | عدم إعادة استخدام `1.10.0` واستخدام `1.11.0` |
| ITMS-90062 | `CFBundleShortVersionString` يجب أن يكون أعلى من الإصدار المعتمد `1.10.0` | ضبط `MARKETING_VERSION = 1.11.0` |
| تعارض Build Number | Build مستخدم سابقًا أو أقل من Build ظاهر | ضبط `CURRENT_PROJECT_VERSION = 70` وNext Build Number على `70` أو أعلى |
| اختلاف القيم بين المشروع والأرشيف | المشروع كان `1.9.0 (30)` بينما App Store Connect أظهر `1.9.0 (35)` | توحيد مصدر القيم من Build Settings وفحص المنتج المبني |

## 4. الملفات المعدلة

| الملف | سبب التعديل |
|---|---|
| `StudyVault.xcodeproj/project.pbxproj` | توحيد `MARKETING_VERSION` على `1.11.0` و`CURRENT_PROJECT_VERSION` على `70` في Debug وRelease |
| `ci_scripts/ci_post_clone.sh` | توجيه Workflow وش الرأي إلى حارس الإصدار الخاص به دون تغيير حارس التطبيقات الأخرى |
| `StudyVaultApp/ci_scripts/ci_post_clone.sh` | منع Xcode Beta أو SDK غير مناسب والتحقق من `1.11.0` وBuild لا يقل عن `70`، وتشغيل السكربت بـbash لدعم `pipefail` |
| `AppStore/release_notes.md` | إضافة ملاحظات إصدار `1.11.0` بالعربية والإنجليزية |
| `docs/RELEASE_CHECKLIST.md` | تحديث Checklist للإصدار الجديد وخطوات Xcode Cloud اليدوية |
| `scripts/submit_app_store_version.mjs` | تحديث القيم الافتراضية اليدوية إلى `1.11.0 (70)` بدل قيم مغلقة |

## 5. القيم الفعلية بعد البناء المحلي

تم فحص التطبيق الفعلي داخل الأرشيف المحلي الجديد:

لم يتم إنشاء Archive محلي جديد في هذه الجولة إذا كانت بيئة CoreSimulator/Xcode المحلية غير مستقرة. مصدر الحقيقة الحالي هو إعدادات المشروع وفحص Xcode Cloud التالي.

| المفتاح | القيمة |
|---|---|
| CFBundleIdentifier | `com.shary17454.esal` |
| CFBundleDisplayName | وش الرأي |
| CFBundleShortVersionString | يجب أن يظهر `1.11.0` داخل Artifact السحابي الجديد |
| CFBundleVersion | يجب أن يظهر `70` أو رقمًا أعلى إذا غيّر Xcode Cloud الرقم |
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
8. Next Build Number: يجب ضبطه على `70` أو أعلى.
9. المتبقي: تشغيل Workflow من Commit النهائي ثم فحص Artifact السحابي الجديد.

## 7. جدول PASS / FAIL

| الشرط | النتيجة | الدليل |
|---|---|---|
| Bundle ID لم يتغير | PASS | بقي `com.shary17454.esal` |
| Development Team لم يتغير | PASS | بقي `4HM66AD594` في إعدادات المشروع |
| Signing/Entitlements لم تتغير | PASS | لم يتم تعديل `CODE_SIGN_STYLE` أو entitlements |
| Marketing Version أعلى من آخر إصدار منشور/مغلق | PASS | `1.11.0` أعلى من `1.10.0` |
| Build Number أعلى من آخر Build مرفوض | PASS | `70` أعلى من `69` |
| `CFBundleShortVersionString` يأخذ من `$(MARKETING_VERSION)` | PASS | `Info.plist` يستخدم المتغير |
| `CFBundleVersion` يأخذ من `$(CURRENT_PROJECT_VERSION)` | PASS | `Info.plist` يستخدم المتغير |
| Target الرئيسي يحمل القيم الجديدة | PASS | إعدادات المشروع موحدة على `1.11.0 (70)` |
| Extensions/Widgets متوافقة | PASS | لا توجد Extensions أو Widgets داخل هذا المشروع |
| Release Build بدون توقيع | PASS | `xcodebuild ... -configuration Release ... build` نجح |
| Resolve Package Dependencies | PASS | لا توجد حزم خارجية، والأمر نجح |
| Unit Tests | PASS | 9/9 |
| UI Smoke Test | PASS | 1/1 على iPhone 17 Simulator |
| Xcode المحلي مطابق للإنتاج المطلوب | FAIL | المحلي `26.4.1 (17E202)`، المطلوب لـXcode Cloud `26.6 (17F113)` |
| Archive محلي جديد بعد آخر تعديل برمجي | PENDING | يجب إنشاؤه بعد استقرار بيئة Xcode أو عبر Xcode Cloud |
| Archive سحابي موقّع بـXcode 26.6 | PENDING | يبدأ بعد Push إلى `main` |
| Build Uploads لا يحتوي Build 70 قبل التشغيل | PENDING | يحتاج تحققًا في App Store Connect قبل التشغيل |

## 8. قرار النشر

الحالة قبل تشغيل Xcode Cloud: `READY_WITH_EXTERNAL_REQUIREMENTS`.

لا ترفع ولا ترسل للمراجعة قبل:

- دفع Commit النهائي إلى `main` لتشغيل Workflow الموثق.
- انتظار Archive السحابي الموقّع وفحص أنه مبني بـXcode 26.6 (`17F113`) ويحمل `1.11.0 (70)` أو رقم Build أعلى إن كان Xcode Cloud يدير الرقم.
- اختبار Sign in with Apple والإشعارات وVoiceOver على جهاز فعلي.
- مراجعة App Privacy Labels وExport Compliance والبيانات القانونية داخل App Store Connect قبل الإرسال للمراجعة.
