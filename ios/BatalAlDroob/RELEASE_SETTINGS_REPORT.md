# تقرير إعدادات إصدار بطل الدروب

> ملاحظة تحديث: هذا التقرير يوثق خط الأساس التاريخي للبناء 105. الحالة
> التشغيلية الأحدث موثقة في `docs/CURRENT_RELEASE_STATUS.md`: نجح Xcode
> Cloud Build 110 من commit `5a80728` باستخدام Xcode 26.6 وSDK 26.5، لكنه
> يسبق إصلاح منتج الشراء الدائم؛ البناء المصحح التالي يجب أن يكون 111 أو أعلى.

تاريخ الفحص: 2026-07-18

## الخلاصة

- التطبيق المقصود فقط: **بطل الدروب**.
- App Store Connect Apple ID: `6786117376`.
- Bundle Identifier: `com.batalaldroob.parts`.
- الإصدار المحضّر في المشروع: `1.1.0`.
- رقم البناء المحضّر: `105`.
- أعلى بناء ظاهر في سياق الدردشة: `104`، وكان مرتبطًا بالإصدار `1.1.0` وحالته الظاهرة `Waiting for Review`.
- آخر إصدار Approved أو Ready for Distribution: **غير ظاهر في الأدلة المتاحة، لذلك لم يتم تخمينه**.
- لم يتم الرفع إلى App Store Connect ولم يتم الإرسال للمراجعة في هذه المهمة.
- حالة المصدر: جاهز لبناء Xcode Cloud بعد الخطوات اليدوية أدناه.
- حالة إصدار App Store: **غير جاهز للرفع بعد**؛ يلزم إنشاء أرشيف جديد في Xcode Cloud باستخدام الأداة المطلوبة ثم نجاح فحص بيانات الأرشيف الفعلي.

## الحالة قبل الإصلاح

- كان `CURRENT_PROJECT_VERSION` في المشروع `96` بينما البناء `104` مستخدم بالفعل في App Store Connect.
- لم يكن هناك فحص بعد الأرشفة يقرأ القيم الفعلية من `xcarchive`.
- كان فحص Xcode Cloud يطبق بعض الشروط قبل التأكد من أن البناء يخص بطل الدروب، ما قد يؤثر في مشاريع أخرى داخل المستودع.
- لم يكن الفحص يتحقق من الحد الأدنى `SDK 26.5` أو من `CI_BUILD_NUMBER >= 105`.
- Xcode المحلي هو `26.4.1 (17E202)` وSDK المحلي `26.4`، وهما لا يطابقان سياسة هذا الإصدار المطلوبة: Xcode `26.6 (17F113)` وSDK `26.5`.

## سياق App Store Connect

| البند | الدليل المتاح |
|---|---|
| أحدث إصدار ظاهر | `1.1.0` |
| أعلى Build ظاهر | `104` |
| حالة أحدث لقطة | `Waiting for Review` |
| محاولة مراجعة سابقة واضحة | `1.0 (91)` |
| آخر إصدار منشور/معتمد | غير معلوم من الصور والسجل المحلي |
| الإصدار الجديد في المشروع | `1.1.0`، بشرط أن يظل train مفتوحًا |
| Build المرشح | `105` كحد أدنى، مع تحقق يدوي قبل تشغيل Cloud |

إذا أصبح إصدار `1.1.0` منشورًا أو مغلقًا، فلا يجوز استعماله لبناء جديد. يجب إنشاء إصدار أعلى في App Store Connect وتحديث `MARKETING_VERSION` في المشروع ليطابقه قبل الأرشفة.

## رموز ITMS المستهدفة

هذه الرموز مطلوبة في نطاق المهمة كحماية وقائية. أحدث رفض بشري ظاهر لبطل الدروب كان متعلقًا بالبيانات الوصفية، وليس دليلًا على أن الرموز الأربعة ظهرت كلها في آخر محاولة.

| الرمز | السبب | الحماية المطبقة |
|---|---|---|
| `ITMS-90111` | Xcode أو SDK غير مدعوم | فشل مبكر لأي Xcode Beta أو غير `26.6 (17F113)`، وفحص SDK `26.5+`، ثم فحص `DTXcode` و`DTXcodeBuild` و`DTSDKName` داخل الأرشيف. |
| `ITMS-90478` | Marketing Version غير صالح أو غير متوافق مع الإصدار المنشور | توحيد `MARKETING_VERSION = 1.1.0` مع اشتراط التحقق اليدوي من أن train ما يزال مفتوحًا. |
| `ITMS-90186` | Pre-Release Train مغلق أو غير صالح | منع إعادة استخدام بناء أقل من `105`، مع خطوة إلزامية للتحقق من حالة train في App Store Connect. |
| `ITMS-90062` | `CFBundleShortVersionString` غير صالح أو أقل من الإصدار المقبول | ربط `CFBundleShortVersionString` بـ`$(MARKETING_VERSION)` والتحقق من القيمة الناتجة داخل الأرشيف. |

## المشروع والمكونات

- Project: `ios/BatalAlDroob/BatalAlDroob.xcodeproj`
- Scheme: `BatalAlDroob`
- Targets: `BatalAlDroob`, `BatalAlDroobTests`
- App extensions / widgets / watch / app clips: لا يوجد.
- Package dependencies: لا يوجد.
- Project generator (Tuist/XcodeGen): لا يوجد.
- Deployment Target: iOS `17.0`، ولم يتغير.
- Swift: `6.0`.
- SDKROOT في إعداد المصدر: `iphoneos`.
- Development Team: `4HM66AD594`، لم يتغير.
- Bundle IDs:
  - App: `com.batalaldroob.parts`
  - Tests: `com.batalaldroob.parts.tests`

## مصادر الإصدار والبناء

- `MARKETING_VERSION` و`CURRENT_PROJECT_VERSION` في `project.pbxproj` هما مصدر إعداد المشروع.
- `Info.plist` يشتق القيم ولا يحتوي أرقامًا ثابتة:
  - `CFBundleShortVersionString = $(MARKETING_VERSION)`
  - `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`
  - `CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)`
- لا يوجد `agvtool` أو `PlistBuddy Set` أو `defaults write` يغيّر الإصدار أو البناء في CI.
- عند تشغيل Xcode Cloud، `CI_BUILD_NUMBER` هو مصدر رقم البناء الفعلي داخل الأرشيف، ويجب أن يكون `105` أو أعلى.

## التعديلات

- `ios/BatalAlDroob/BatalAlDroob.xcodeproj/project.pbxproj`
  - توحيد `CURRENT_PROJECT_VERSION = 105` في Debug وRelease للتطبيق والاختبارات.
  - الإبقاء على `MARKETING_VERSION = 1.1.0`.
- `ci_scripts/ci_post_clone.sh`
  - تقييد الحماية ببناء بطل الدروب فقط عبر bundle/product/project variables.
  - طباعة Xcode وSDK ومتغيرات Cloud والـcommit.
  - رفض Beta أو Xcode غير `26.6 (17F113)`.
  - رفض SDK أقل من `26.5`.
  - رفض اختلاف نسخ targets أو Build غير رقمي/أقل من `105`.
  - لا يغيّر الإصدار أو رقم البناء.
- `ci_scripts/ci_post_xcodebuild.sh`
  - فحص `xcarchive` الجديد بعد Archive ناجح.
  - التحقق من bundle/version/build/platform/Xcode/SDK/minimum OS.
  - التحقق من أي app/appex مضمن إن أضيف مستقبلًا.
- `ios/BatalAlDroob/scripts/validate_release.py`
  - فحص منظم لـInfo.plist وإعدادات المشروع وSDKROOT وDeployment Target وBundle IDs.
  - منع آليات CI المتعارضة التي تغيّر version/build.
- `ios/BatalAlDroob/README.md` و`AGENTS.md`
  - توثيق المشروع الصحيح وأوامر الفحص والحماية والقيود.

## الأداة الفعلية محليًا

| الفحص | القيمة |
|---|---|
| Xcode | `26.4.1` |
| Xcode Build | `17E202` |
| xcode-select | `/Applications/Xcode.app/Contents/Developer` |
| iPhoneOS SDK | `26.4` |
| SDK Path | `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.4.sdk` |

Apple تشترط حاليًا على نحو عام Xcode 26 أو أحدث وSDK 26 أو أحدث للرفع. سياسة هذا الإصدار أضيق بطلب المستخدم: Xcode `26.6 (17F113)` وiPhoneOS SDK `26.5`. لذلك نجح البناء المحلي تشخيصيًا لكنه لا يُعتمد كأرشيف إنتاجي لهذه المهمة.

## نتائج التنفيذ

| العملية | النتيجة |
|---|---|
| `xcodebuild -list` | PASS: targetان وscheme واحد كما هو موضح أعلاه. |
| Resolve Package Dependencies | PASS: لا توجد حزم خارجية. |
| Release simulator build | PASS، exit `0`. |
| Unit tests | PASS: `3/3`. |
| Local diagnostic device archive | PASS، أرشيف جديد داخل `/tmp` دون توقيع أو رفع. |
| Local archive structural metadata | PASS عند توقع الأداة المحلية. |
| Production archive guard against local archive | PASS كاختبار رفض: أوقفه بسبب `DTPlatformVersion 26.4` بدل `26.5`. |
| Production Xcode Cloud archive | BLOCKED/NOT RUN: يتطلب Workflow على Xcode 26.6 ثم تشغيله من commit الإصلاحات. |
| Upload / Review submission | NOT RUN حسب طلب المهمة. |

### الاختبارات الناجحة

- `BatalCatalogResourceTests.testBundledCatalogJSONHasUsableRecords`
- `BatalCatalogResourceTests.testBundledStoreDirectoryHasVerifiedStores`
- `BatalCatalogResourceTests.testBundledSupportDataExists`

## قيم الأرشيف التشخيصي الفعلية

الأرشيف الجديد: `/tmp/BatalAlDroob-1.1.0-105-local-20260718T0824.xcarchive`

| المفتاح | القيمة |
|---|---|
| `CFBundleIdentifier` | `com.batalaldroob.parts` |
| `CFBundleDisplayName` | `بطل الدروب` |
| `CFBundleShortVersionString` | `1.1.0` |
| `CFBundleVersion` | `105` |
| `DTPlatformName` | `iphoneos` |
| `DTPlatformVersion` | `26.4` |
| `DTSDKName` | `iphoneos26.4` |
| `DTSDKBuild` | `23E252` |
| `DTXcode` | `2641` |
| `DTXcodeBuild` | `17E202` |
| `MinimumOSVersion` | `17.0` |

الحزم الموجودة داخل الأرشيف: `BatalAlDroob.app` فقط. لا توجد `appex` أو frameworks مضمنة تسبب تعارضًا.

## الخطوات اليدوية الإلزامية في Xcode Cloud

1. افتح App Store Connect > بطل الدروب > Xcode Cloud > Workflows > Edit Workflow.
2. من Environment اختر **Xcode 26.6 (17F113)**، ولا تختَر Latest Beta.
3. اجعل Next Build Number `105` أو رقمًا أعلى من كل builds الظاهرة في TestFlight > Build Uploads.
4. تأكد أن workflow يبني project `ios/BatalAlDroob/BatalAlDroob.xcodeproj` وscheme `BatalAlDroob`.
5. شغّل workflow من commit يحتوي `ci_post_clone.sh` و`ci_post_xcodebuild.sh` والإعدادات الحالية.
6. لا ترفع artifact إذا فشل أي guard؛ اقرأ الخطأ وعالج السبب بدل زيادة الرقم فقط.
7. بعد نجاح Archive، تأكد في logs من سطر `PASS: xcarchive metadata matches Batal Al-Droob release settings.`

## الخطوات اليدوية الإلزامية في App Store Connect

1. افتح TestFlight > Build Uploads وتأكد أن `105` لم يُستخدم؛ إن كان مستخدمًا اختر الرقم التالي واضبط Next Build Number.
2. تحقق أن إصدار `1.1.0` ما يزال مفتوحًا ويمكن ربط Build جديد به.
3. إذا كان `1.1.0` منشورًا أو مغلقًا، أنشئ إصدارًا أعلى ثم حدّث `MARKETING_VERSION` في المشروع قبل أي build.
4. لا تربط الأرشيف بإصدار مغلق ولا تعِد استعمال Build سابق.
5. لا تُرسل للمراجعة قبل معالجة بيانات المتجر المنفصلة المذكورة أدناه.

## رسائل المراجعة البشرية المنفصلة

- Guideline `2.3.3`: صور iPhone 6.5-inch وiPad 13-inch يجب أن تعرض النسخة الحالية من التطبيق أثناء الاستخدام.
- Guideline `2.3.2`: صورة الترويج لعملية الشراء داخل التطبيق لا يجوز أن تكون لقطة شاشة من التطبيق؛ يجب أن تكون صورة ترويجية فريدة ودقيقة.
- ظهرت تاريخيًا رسائل `4.2.2 Minimum Functionality` و`2.1 Information Needed`. هذه ليست أخطاء Xcode/SDK/version ولا تُحل بتغيير Build Number.

## جدول القبول

| الشرط | الحالة |
|---|---|
| التطبيق الصحيح فقط | PASS |
| Bundle ID لم يتغير | PASS |
| Development Team لم يتغير | PASS |
| Signing/Entitlements/Capabilities لم تتغير | PASS |
| Deployment Target بقي 17.0 | PASS |
| Info.plist يشتق version/build | PASS |
| Version موحد في كل targets | PASS |
| Build موحد في كل targets | PASS |
| Build أعلى من 104 | PASS: 105 |
| لا توجد آلية CI ثانية تغيّر build/version | PASS |
| Xcode Cloud guard scoped لبطل الدروب | PASS |
| Beta Xcode مرفوض | PASS |
| SDK أقدم من 26.5 مرفوض | PASS |
| Release build | PASS |
| الاختبارات الأساسية | PASS: 3/3 |
| أرشيف جديد تشخيصي | PASS |
| فحص بنية الأرشيف والحزم | PASS |
| Xcode المحلي يطابق 26.6 (17F113) | FAIL |
| SDK المحلي يطابق 26.5 | FAIL |
| أرشيف إنتاجي جديد من Xcode Cloud | BLOCKED |
| التحقق من أن Build 105 غير مستخدم | MANUAL REQUIRED |
| التحقق من أن train 1.1.0 مفتوح | MANUAL REQUIRED |
| رفع أو إرسال للمراجعة | NOT RUN |

## مراجع Apple الرسمية

- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/support/xcode
- https://developer.apple.com/documentation/xcode-release-notes/xcode-26_6-release-notes
- https://developer.apple.com/documentation/xcode/environment-variable-reference
- https://developer.apple.com/documentation/Xcode/Writing-Custom-Build-Scripts

## الحكم النهائي

إعدادات المصدر والحمايات **جاهزة**، لكن إصدار App Store **ليس جاهزًا للرفع بعد** لأن الأرشيف الإنتاجي المطلوب لم يُنشأ على Xcode Cloud بـXcode `26.6 (17F113)` وSDK `26.5`، ولأن عدم استخدام Build `105` وحالة train `1.1.0` يحتاجان تحققًا مباشرًا داخل App Store Connect.
