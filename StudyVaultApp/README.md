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
- مخطط زمني من أحداث تصويت فعلية دون توليد بيانات تاريخية.
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

إعدادات عنوان الخادم وAPI token متاحة داخل Debug فقط. يحفظ التطبيق الرمز في Keychain، ولا توجد أسرار مضمنة في المصدر.

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

- 21 اختبار وحدة للتحقق، SwiftData، الحسابات، تحليل العربية، البحث، المسودات، ومنع التصويت المكرر واستعادة المخزن بعد إعادة التشغيل.
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

## الإصدار

مصدر الإصدار هو `MARKETING_VERSION` و`CURRENT_PROJECT_VERSION` في إعدادات Target. تستمد قيم `CFBundleShortVersionString` و`CFBundleVersion` منهما.

لا تغيّر Bundle ID أو Team أو Signing أو Entitlements من تعليمات التشغيل. البناء المحلي مخصص للتطوير والتحقق فقط؛ مسار Release وArchive والرفع المعتمد هو Xcode Cloud حصريًا. يفحص `ci_post_clone.sh` بيئة Xcode وSDK قبل البناء، ثم يتحقق `ci_post_xcodebuild.sh` من القيم الفعلية داخل الأرشيف قبل قبول Build الإنتاجي.

إعداد Workflow المعتمد:

- الفرع: `main`.
- Scheme: `StudyVault`.
- Xcode: `26.6 (17F113)` الإنتاجي، وليس Latest Beta.
- Actions: Build ثم Archive مع App Store Connect distribution.
- Build Number: تديره Xcode Cloud؛ لا تستخدم `agvtool` أو `PlistBuddy` أو سكربتًا محليًا لزيادته.
- آخر رفض موثق من App Store Connect بتاريخ 31 يوليو 2026 كان للإصدار `2.0` والبناء `98` بسبب `ITMS-90186` و`ITMS-90062`: مسار `2.0` مغلق لأنه يساوي آخر إصدار معتمد. إصدار الإرسال التالي في المشروع هو `2.1` مع Build أساسه `99` أو أعلى من كل Builds الظاهرة في App Store Connect.

راجع [XCODE_CLOUD_RELEASE.md](docs/XCODE_CLOUD_RELEASE.md) قبل أي إصدار.

راجع:

- `docs/APPLE_ENGINEERING_STANDARD.md`
- `docs/FINAL_EXECUTION_REPORT.md`
- `docs/IOS_MODERNIZATION_REPORT.md`
- `docs/RELEASE_CHECKLIST.md`
- `docs/DECISION_PLATFORM_GATES.md`
