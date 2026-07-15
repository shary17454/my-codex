# تقرير إصلاح إعدادات App Store وXcode Cloud

تاريخ التقرير: 2026-07-15  
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
| آخر إصدار منشور معروف من السياق | 1.6 |
| أحدث Version تمت محاولة رفعه | 1.9.0 |
| أحدث Build تمت محاولة رفعه | 35 |
| Build Uploads المذكور | 1.9.0 (35) بحالة Complete |
| الإصدار الجديد المختار | 1.10.0 |
| Build الجديد المختار | 36 |

تم اختيار `1.10.0` لأن الأخطاء `ITMS-90186` و`ITMS-90062` و`ITMS-90478` تعني أن استخدام train سابق أو Version مساوي/أقل أو مغلق قد يعيد الرفض. تم اختيار Build `36` لأنه أعلى من Build `35` المذكور في App Store Connect.

## 3. رموز ITMS والسبب الجذري

| الرمز | السبب العملي | الإجراء |
|---|---|---|
| ITMS-90111 | بناء بإصدار Xcode/SDK غير مدعوم للإرسال الإنتاجي | إضافة `ci_post_clone.sh` لإيقاف Xcode Cloud إذا لم يستخدم Xcode 26.6 `17F113` وSDK مناسب |
| ITMS-90478 | Version غير صالح أو غير مطابق لحالة App Store Connect | رفع Marketing Version إلى `1.10.0` |
| ITMS-90186 | Pre-Release Train مغلق للإرسال الجديد | عدم إعادة استخدام `1.4` أو `1.5` أو `1.9.0`، واستخدام `1.10.0` |
| ITMS-90062 | `CFBundleShortVersionString` يجب أن يكون أعلى من الإصدار المعتمد | ضبط `MARKETING_VERSION = 1.10.0` |
| تعارض Build Number | Build مستخدم سابقًا أو أقل من Build ظاهر | ضبط `CURRENT_PROJECT_VERSION = 36` |
| اختلاف القيم بين المشروع والأرشيف | المشروع كان `1.9.0 (30)` بينما App Store Connect أظهر `1.9.0 (35)` | توحيد مصدر القيم من Build Settings وفحص المنتج المبني |

## 4. الملفات المعدلة

| الملف | سبب التعديل |
|---|---|
| `StudyVault.xcodeproj/project.pbxproj` | رفع `MARKETING_VERSION` إلى `1.10.0` و`CURRENT_PROJECT_VERSION` إلى `36` في Debug وRelease |
| `ci_scripts/ci_post_clone.sh` | إضافة فحص مبكر لبيئة Xcode Cloud يمنع Xcode Beta أو SDK غير مناسب |
| `AppStore/release_notes.md` | إضافة ملاحظات إصدار `1.10.0` بالعربية والإنجليزية |
| `docs/RELEASE_CHECKLIST.md` | تحديث Checklist للإصدار الجديد وخطوات Xcode Cloud اليدوية |
| `scripts/submit_app_store_version.mjs` | تحديث القيم الافتراضية اليدوية إلى `1.10.0 (36)` بدل قيم قديمة |

## 5. القيم الفعلية بعد البناء المحلي

تم فحص المنتج المبني من:

`/tmp/StudyVaultReleasePreflight/Build/Products/Release-iphoneos/StudyVault.app/Info.plist`

| المفتاح | القيمة |
|---|---|
| CFBundleIdentifier | `com.shary17454.esal` |
| CFBundleDisplayName | وش الرأي |
| CFBundleShortVersionString | `1.10.0` |
| CFBundleVersion | `36` |
| DTPlatformName | `iphoneos` |
| DTPlatformVersion | `26.4` |
| DTSDKName | `iphoneos26.4` |
| DTSDKBuild | `23E252` |
| DTXcode | `2641` |
| DTXcodeBuild | `17E202` |
| MinimumOSVersion | `17.0` |

ملاحظة: هذه قيم بناء محلي فقط. لا يجوز اعتبارها Archive إنتاجيًا لأن Xcode المحلي هو 26.4.1 وليس Xcode Cloud 26.6 المطلوب.

## 6. إعداد Xcode Cloud المطلوب يدويًا

1. افتح App Store Connect.
2. افتح تطبيق `وش الرأي`.
3. افتح Xcode Cloud > Workflows.
4. عدّل Workflow المستخدم للرفع.
5. Environment > Xcode Version:
   - اختر Xcode 26.6 `17F113` أو إصدارًا إنتاجيًا أحدث تسمح به Apple.
   - لا تختَر Latest Beta أو Xcode 27 beta.
6. تأكد من وجود Action:
   - `Build - iOS`
   - `Archive - iOS`
7. داخل `Archive - iOS`:
   - Platform: iOS
   - Scheme: StudyVault
   - Distribution Preparation: App Store Connect
8. اضبط Xcode Cloud > Next Build Number على `36` أو أعلى إذا ظهر Build أحدث في Build Uploads.
9. شغّل Build جديد من Commit يحتوي هذه التعديلات.
10. بعد اكتمال Archive، افحص `xcarchive` أو بيانات Artifact الفعلية وتأكد من `1.10.0 (36)`.

## 7. جدول PASS / FAIL

| الشرط | النتيجة | الدليل |
|---|---|---|
| Bundle ID لم يتغير | PASS | بقي `com.shary17454.esal` |
| Development Team لم يتغير | PASS | بقي `4HM66AD594` في إعدادات المشروع |
| Signing/Entitlements لم تتغير | PASS | لم يتم تعديل `CODE_SIGN_STYLE` أو entitlements |
| Marketing Version أعلى من آخر منشور معروف وآخر محاولة | PASS | `1.10.0` أعلى من `1.6` ومن `1.9.0` |
| Build Number أعلى من آخر Build ظاهر في السياق | PASS | `36` أعلى من `35` |
| `CFBundleShortVersionString` يأخذ من `$(MARKETING_VERSION)` | PASS | `Info.plist` يستخدم المتغير |
| `CFBundleVersion` يأخذ من `$(CURRENT_PROJECT_VERSION)` | PASS | `Info.plist` يستخدم المتغير |
| Target الرئيسي يحمل القيم الجديدة | PASS | المنتج المحلي المبني أظهر `1.10.0 (36)` |
| Extensions/Widgets متوافقة | PASS | لا توجد Extensions أو Widgets داخل هذا المشروع |
| Release Build بدون توقيع | PASS | `xcodebuild ... -configuration Release ... build` نجح |
| Resolve Package Dependencies | PASS | لا توجد حزم خارجية، والأمر نجح |
| Unit/UI Tests | FAIL | الـScheme غير مهيأ لـTest action |
| Xcode المحلي مطابق للإنتاج المطلوب | FAIL | المحلي `26.4.1 (17E202)`، المطلوب لـXcode Cloud `26.6 (17F113)` |
| فحص `xcarchive` النهائي | FAIL | لم يتم إنشاء Archive جديد عبر Xcode Cloud بعد |
| Build Uploads لا يحتوي Build 36 | MANUAL | يحتاج تحقق يدوي من TestFlight > Build Uploads قبل الرفع |

## 8. قرار النشر

الحالة الحالية: `READY_WITH_MANUAL_STEPS`.

لا ترفع ولا ترسل للمراجعة قبل:

- ضبط Xcode Cloud على Xcode 26.6 `17F113` أو أحدث إنتاجي مسموح.
- ضبط Next Build Number على `36` أو أعلى.
- إنشاء Archive جديد من Commit يحتوي هذه التعديلات.
- فحص قيم `xcarchive` النهائي والتأكد من `1.10.0 (36)`.
- التأكد يدويًا من أن Build `36` غير موجود مسبقًا في Build Uploads.
