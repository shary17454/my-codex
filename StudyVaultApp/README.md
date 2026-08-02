# وش الرأي iOS

تطبيق iOS وiPadOS عربي أصلي يساعد المستخدم على مقارنة الخيارات واتخاذ قرار أوضح من خلال التصويت، أسباب الاختيار، ملخص القرار، المواصفات، والحفظ والمشاركة.

- الاسم الظاهر: `وش الرأي`
- Bundle ID: `com.shary17454.esal`
- Xcode project: `StudyVaultApp/StudyVault.xcodeproj`
- Scheme: `StudyVault`
- Swift: 6
- الواجهة: SwiftUI
- الحد الأدنى: iOS 17
- الأجهزة: iPhone وiPad

## المعمارية

يتبع التطبيق MVVM بصورة عملية:

- `ContentView.swift`: حاوية التطبيق والتنقل.
- `DashboardView.swift`: الصفحة الرئيسية.
- `DiscoverViews.swift`: البحث، التصنيفات، مكتبة المعرفة، والمتصفح.
- `SmartComparisonView.swift`: المقارنة حسب الاحتياج.
- `QuestionDetailView.swift`: التصويت، النتائج، أسباب التصويت، الملخص، المشاركة، والإبلاغ.
- `CreateComparisonView.swift`: إنشاء المقارنات والمسودات.
- `AccountView.swift`: الحساب والاهتمامات وإعدادات التطوير.
- `SharedComponents.swift` و`DesignSystem.swift`: مكونات وتصميم دلالي مشترك.
- `ViewModels.swift`: حالة الواجهة، البحث، النشر، التصويت، الحفظ، والاتصال بالخادم.
- `AskModels.swift`: نماذج المجال وخدمات القرار والتحقق.
- `PersistenceModels.swift`: نماذج SwiftData وترحيل المسودات والأصوات والمحفوظات القديمة.
- `DecisionEngines.swift`: الأوزان، حالة القرار، جودة الأدلة، تحليل العربية، النتائج اللاحقة، والترتيب.
- `DecisionFeaturesView.swift`: القرار الشخصي، متابعة التجربة، بطاقة المشاركة، ومخطط التصويت.
- `PlatformIntegrations.swift`: App Intents وTipKit وفتح مسودة المقارنة من Siri/Shortcuts.
- `UserSession.swift`: جلسة المستخدم وتخزين المعرفات الحساسة في Keychain.

لا توجد تبعيات Flutter أو Dart، ولا توجد CocoaPods أو حزم خارجية داخل Target التطبيق.

## الوظائف الحالية

- صفحة رئيسية بمؤشرات واختصارات ومقارنات حديثة.
- بحث وتصنيف وفرز للمقارنات.
- مقارنة ذكية بين عنصرين أو أكثر حسب معايير واضحة.
- إنشاء مقارنة من خيارين إلى 10 خيارات.
- منع العنوان الفارغ والخيارات الناقصة أو المكررة.
- حفظ المقارنات والمسودات والتصويتات والمحفوظات ونتائج التجربة باستخدام SwiftData.
- ترحيل البيانات المحلية القديمة من UserDefaults مرة واحدة دون حذفها قبل نجاح الحفظ.
- تصويت مع سبب اختياري وتصنيف السبب.
- منع التصويت المحلي المكرر وربط السبب بالخيار وسجل تغير النتيجة.
- عدم زيادة عداد التصويت عند استخدام Backend قبل تأكيد الخادم.
- نسب تصويت، خيار متصدر، فارق النتيجة، ودرجة ثقة متعددة العوامل.
- مؤشر مستقل لجودة الأدلة يعتمد على حجم المشاركة والأسباب والتجربة والحداثة.
- تحليل عربي محلي قائم على قواعد معلنة لا يدّعي استخدام الذكاء الاصطناعي.
- مقارنة شخصية حسب معايير وأوزان يحددها المستخدم، مع توضيح اختلافها عن رأي المجتمع.
- متابعة القرار بعد التجربة: الخيار الفعلي والرضا وإمكانية اختياره مجددًا.
- نقاط قوة وضعف ومواصفات مقارنة.
- تعليقات منفصلة عن أسباب التصويت.
- حفظ ومشاركة وQR وبطاقة نتيجة PNG وتذكير محلي وإبلاغ.
- روابط مشاركة عامة عند ضبط Backend عام، مع صفحة ويب لكل مقارنة على `/c/{comparisonID}` وQR يشير للرابط العام.
- دعم فتح روابط المقارنات من `weshalray://comparison/{id}` ومن مسارات Universal Links عند تفعيل Associated Domains للنطاق.
- مخطط زمني من أحداث تصويت فعلية دون توليد بيانات تاريخية.
- مساعد قرار ذكي داخل التطبيق يجيب من المقارنات والمكتبة الحالية، ويستخدم Backend آمنًا عند تفعيله مع fallback محلي دون تخزين المحادثة.
- كاميرا قرار تلتقط صورة حقيقية وتستخدم Apple Vision محليًا لقراءة النصوص. عند تفعيل Backend تُرسل النصوص المستخرجة فقط لاقتراح عنوان وخيارات ومعايير، ولا تُرسل الصورة نفسها.
- غرف عامة وخاصة بالرابط أو الرمز، وإخفاء النتائج حتى التصويت عند ربط Backend.
- الانضمام إلى غرفة خاصة بالرمز وتمرير الرمز في الرابط العميق.
- اختصار App Intent لإنشاء مسودة مقارنة وتلميحات TipKit سياقية.
- مكتبة معرفة محلية تضم 180 عنصرًا.
- 16 مقارنة أولية تبدأ دون أصوات أو تعليقات مصطنعة.
- دعم RTL والوضعين الفاتح والداكن وDynamic Type وVoiceOver.
- تخطيط متكيف مع iPhone وiPad.

## البيانات والـBackend

البيانات الأولية داخل:

- `StudyVault/SeedQuestions.json`
- `StudyVault/ProductKnowledge.json`

يوجد Backend تطوير محلي في `StudyVaultApp/backend/`. يدعم الغرف العامة والخاصة، رموز الدعوة، إخفاء النتائج، منع التصويت المكرر، سجل التصويت المجهّل، تحديد المعدل، والكتابة الذرية إلى JSON. هذا الخادم ليس بديلًا عن Backend إنتاجي دائم ومصادقة مستخدمين حقيقية.

في نسخة Release، لا تُنشر المقارنات العامة محليًا بوصفها عامة. إذا لم يكن `WeshAlrayBackendBaseURL` مضبوطًا على رابط HTTPS إنتاجي صالح، يعرض التطبيق رسالة واضحة للمستخدم بدل نشر مقارنة لا يراها الآخرون. عند ضبط Backend إنتاجي، تُرسل المقارنات العامة إلى `/api/v1/comparisons` وتظهر في «اكتشف» للمستخدمين بعد التحديث.

إعدادات عنوان الخادم وAPI token متاحة داخل Debug فقط. يحفظ التطبيق الرمز في Keychain، ولا توجد أسرار مضمنة في المصدر.

## المشاركة والنمو

يدعم التطبيق مشاركة المقارنات بعدة أشكال:

- نص مشاركة مختصر يحتوي عنوان المقارنة، الخيارات، ملخص القرار، ورابط الفتح.
- بطاقة نتيجة PNG قابلة للمشاركة عبر Share Sheet، مناسبة لـWhatsApp وX وInstagram عند توفر التطبيقات على الجهاز.
- QR لكل مقارنة يشير إلى الرابط العام عندما يكون Backend عام مضبوطًا، أو إلى الرابط العميق المحلي عند عدم وجود نطاق عام.
- أزرار مباشرة لـWhatsApp وX داخل نافذة المشاركة.
- صفحة ويب عامة في الباكند على `/c/{comparisonID}` تعرض العنوان والخيارات والنسب وزر فتح التطبيق.
- ملف Universal Links جاهز في الباكند على `/.well-known/apple-app-site-association`.

تفعيل Universal Links إنتاجيًا يحتاج:

1. نطاق HTTPS حقيقي يخدم الباكند أو طبقة الويب، مثل `https://example.com`.
2. ضبط `WESH_ALRAY_PUBLIC_WEB_BASE_URL` في بيئة الخادم.
3. ضبط `APPLE_APP_SITE_APP_ID` بصيغة `TEAMID.com.shary17454.esal`.
4. إضافة Associated Domain في Xcode بصيغة `applinks:example.com` بعد اعتماد النطاق النهائي.
5. اختبار فتح `https://example.com/c/{comparisonID}` على جهاز حقيقي.

## الإشعارات والمتابعة

يدعم التطبيق مرحلة الإشعارات كالتالي:

- طلب إذن الإشعارات من iOS في وقت الاستخدام.
- مركز إشعارات داخل التطبيق يعرض تنبيهات التصويت وتغير المتصدر وقرب الانتهاء وتذكير متابعة التجربة.
- تسجيل جهاز iOS في الباكند عبر `/api/v1/devices` عند توفر Backend.
- متابعة مقارنة محددة عبر `/api/v1/comparisons/{id}/follow`.
- صندوق إشعارات قابل للقراءة عبر `/api/v1/notifications`.
- جدولة تذكير محلي بعد التصويت ليسأل المستخدم لاحقًا: "وش اخترت؟ وهل أنت راضٍ؟"
- مسار APNs اختياري للإرسال الفعلي عبر `/api/v1/notifications/dispatch`.

إرسال Push خارج التطبيق يحتاج إعدادًا خارجيًا غير موجود في المستودع: تفعيل Push Notifications في Apple Developer، إضافة entitlement مناسب، إنشاء APNs Auth Key، وضبط `APNS_KEY_ID` و`APNS_TEAM_ID` و`APNS_BUNDLE_ID` و`APNS_PRIVATE_KEY_BASE64` في بيئة الخادم فقط.

## ميزات Apple وPlus والإدارة

- Siri Shortcuts/App Intents توسعت لتشمل: إنشاء مقارنة، فتح اكتشف، فتح مكتبتي، وفتح آخر نتيجة.
- التطبيق يعرض جاهزية Live Activities وWidgets بوضوح. التنفيذ الكامل يحتاج Widget Extension وBundle ID مستقلين من Apple Developer قبل الرفع.
- شاشة الحساب تعرض حالة Apple Features ووش الرأي Plus.
- حساب المالك يحصل على مزايا Plus داخليًا بدون اشتراك.
- StoreKit التجاري لم يُفعّل للمستخدمين بعد؛ يلزم إنشاء منتجات `com.shary17454.esal.plus.monthly` و`com.shary17454.esal.plus.yearly` في App Store Connect قبل فتح الشراء.
- CSV متاح، وتمت إضافة توليد PDF محلي لتقرير المقارنة.
- الباكند يوفر مسارات Admin محمية بالرمز للتقارير، الحظر، المقاييس، والنسخ الاحتياطية.

## الذكاء داخل التطبيق

النسخة الحالية تضيف AI MVP آمن ومحدود:

- `AIDecisionAssistantView`: مساعد قرار داخل التطبيق.
- `AIDecisionAssistantEngine`: محرك إجابات محلي يستند إلى المقارنات ومكتبة المعرفة الموجودة على الجهاز عند غياب Backend.
- `CameraDecisionAssistant`: استخراج نصوص الصورة باستخدام Apple Vision، ثم تحسين مسودة المقارنة عبر Backend عند تفعيله مع fallback محلي.
- Backend AI Provider: يمكن ضبط `AI_PROVIDER=openai` على الخادم لتفعيل OpenAI Responses API عبر `OPENAI_API_KEY`، مع رجوع تلقائي للتحليل المحلي عند فشل المزود.
- Backend endpoints اختيارية:
  - `POST /api/v1/ai/chat`
  - `POST /api/v1/ai/search`
  - `POST /api/v1/ai/summarize`
  - `POST /api/v1/ai/suggestions`
  - `POST /api/v1/ai/camera-draft`

لا توجد مفاتيح AI داخل Swift أو JavaScript. لا تُخزن محادثات المساعد. لا تُرفع صورة الكاميرا إلى الخادم؛ عند تفعيل Backend تُرسل النصوص المستخرجة فقط لتحسين اقتراح المسودة.

عند تفعيل OpenAI يجب أن يكون المفتاح Secret في بيئة الخادم فقط باسم `OPENAI_API_KEY`. يرسل الخادم سياقًا مختصرًا من المقارنات العامة أو النص المستخرج من الصورة، ولا يرسل الصورة نفسها أو محادثات محفوظة.

ملف إعدادات الباكند الآمن:

```sh
cp StudyVaultApp/backend/.env.example StudyVaultApp/backend/.env
```

لا تضع `.env` أو أي مفتاح حقيقي في Git.

## الأذونات والخصوصية

أول تشغيل يعرض شرحًا للأذونات فقط ولا يفتح نوافذ صلاحيات Apple دفعة واحدة. يطلب التطبيق الإذن في لحظة استخدام الميزة المرتبطة به:

- الكاميرا: عند فتح كاميرا القرار لاستخراج النصوص من الصورة وتحويلها إلى مسودة مقارنة. الصورة نفسها لا تُرفع للخادم.
- الإشعارات: عند جدولة تذكير أو متابعة نتيجة.

لا تطلب النسخة الحالية الموقع ولا إذن تتبع التطبيقات، ولا تحتوي `Info.plist` على مفاتيح استخدام لهما. إذا أضيفت ميزة مستقبلية تحتاج الموقع أو التتبع، يجب إضافة سبب استخدام واضح وتحديث App Store Privacy قبل الرفع.

## البناء

من جذر المستودع:

```sh
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj \
  -scheme StudyVault \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/StudyVaultReleaseDerivedData \
  build
```

## الاختبارات

```sh
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj \
  -scheme StudyVault \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -derivedDataPath /tmp/StudyVaultTestsDerived \
  test
```

تتضمن الاختبارات الحالية:

- اختبارات وحدة للتحقق، SwiftData، الحسابات، تحليل العربية، البحث، المسودات، مساعد القرار الذكي، الكاميرا، ومنع التصويت المكرر واستعادة المخزن بعد إعادة التشغيل.
- 3 اختبارات UI لمسارات الإقلاع والتنقل والبحث وبدء إنشاء مقارنة.

## فحوص المشروع

```sh
StudyVaultApp/scripts/validate_wesh_alray_scope.sh
python3 StudyVaultApp/scripts/validate_wesh_alray_data.py
cd StudyVaultApp/backend && npm run check
```

لتشغيل Smoke Test للـBackend:

```sh
cd StudyVaultApp/backend
PORT=8787 WESH_ALRAY_DATA_FILE=/tmp/wesh-alray-store.json npm run dev
BASE_URL=http://localhost:8787 npm run smoke
```

لتجربة مسار مزود OpenAI بدون مفتاح حقيقي، شغّل الخادم مع مزود وهمي محلي:

```sh
cd StudyVaultApp/backend
AI_PROVIDER=openai OPENAI_API_KEY=test-openai-key OPENAI_API_BASE_URL=http://localhost:8788/v1 PORT=8787 WESH_ALRAY_DATA_FILE=/tmp/wesh-alray-ai-provider-store.json npm run dev
BASE_URL=http://localhost:8787 npm run smoke:ai-provider
```

## الإصدار

مصدر الإصدار هو `MARKETING_VERSION` و`CURRENT_PROJECT_VERSION` في إعدادات Target. تستمد قيم `CFBundleShortVersionString` و`CFBundleVersion` منهما.

لا تغيّر Bundle ID أو Team أو Signing أو Entitlements من تعليمات التشغيل. البناء المحلي مخصص للتطوير والتحقق فقط؛ مسار Release وArchive والرفع المعتمد هو Xcode Cloud حصريًا. يفحص `ci_post_clone.sh` بيئة Xcode وSDK قبل البناء، ثم يتحقق `ci_post_xcodebuild.sh` من القيم الفعلية داخل الأرشيف قبل قبول Build الإنتاجي.

إعداد Workflow المعتمد:

- الفرع: `main`.
- Scheme: `StudyVault`.
- Xcode: `26.6 (17F113)` الإنتاجي، وليس Latest Beta.
- Actions: Build ثم Archive مع App Store Connect distribution.
- Build Number: تديره Xcode Cloud؛ لا تستخدم `agvtool` أو `PlistBuddy` أو سكربتًا محليًا لزيادته.
- آخر رفض موثق من App Store Connect بتاريخ 31 يوليو 2026 كان للإصدار `2.0` والبناء `98` بسبب `ITMS-90186` و`ITMS-90062`: مسار `2.0` مغلق لأنه يساوي آخر إصدار معتمد. إصدار الإرسال التالي في المشروع هو `2.1` مع Build أساسه `102` أو أعلى من كل Builds الظاهرة في App Store Connect.

راجع [XCODE_CLOUD_RELEASE.md](docs/XCODE_CLOUD_RELEASE.md) قبل أي إصدار.

راجع:

- `docs/APPLE_ENGINEERING_STANDARD.md`
- `docs/FINAL_EXECUTION_REPORT.md`
- `docs/IOS_MODERNIZATION_REPORT.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/DECISION_PLATFORM_GATES.md`
