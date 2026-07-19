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
- `UserSession.swift`: جلسة المستخدم وتخزين المعرفات الحساسة في Keychain.

لا توجد تبعيات Flutter أو Dart، ولا توجد CocoaPods أو حزم خارجية داخل Target التطبيق.

## الوظائف الحالية

- صفحة رئيسية بمؤشرات واختصارات ومقارنات حديثة.
- بحث وتصنيف وفرز للمقارنات.
- مقارنة ذكية بين عنصرين أو أكثر حسب معايير واضحة.
- إنشاء مقارنة من خيارين إلى 10 خيارات.
- منع العنوان الفارغ والخيارات الناقصة أو المكررة.
- حفظ واستعادة المسودة محليًا.
- تصويت مع سبب اختياري وتصنيف السبب.
- عدم زيادة عداد التصويت عند استخدام Backend قبل تأكيد الخادم.
- نسب تصويت، خيار متصدر، فارق النتيجة، ودرجة ثقة.
- نقاط قوة وضعف ومواصفات مقارنة.
- تعليقات منفصلة عن أسباب التصويت.
- حفظ ومشاركة وQR وتذكير محلي وإبلاغ.
- مكتبة معرفة محلية تضم 180 عنصرًا.
- 16 مقارنة أولية تبدأ دون أصوات أو تعليقات مصطنعة.
- دعم RTL والوضعين الفاتح والداكن وDynamic Type وVoiceOver.
- تخطيط متكيف مع iPhone وiPad.

## البيانات والـBackend

البيانات الأولية داخل:

- `StudyVault/SeedQuestions.json`
- `StudyVault/ProductKnowledge.json`

يوجد Backend تطوير محلي في `StudyVaultApp/backend/`. يدعم المقارنات والتصويت والتعليقات مع تحديد معدل الطلبات وتخزين JSON معزول للتطوير. هذا الخادم ليس بديلًا عن Backend إنتاجي دائم ومصادقة مستخدمين حقيقية.

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

- 9 اختبارات وحدة للتحقق، الحسابات، البحث، المسودات، ومنع التصويت المكرر.
- UI Smoke Test لفتح التطبيق والتنقل إلى الاكتشاف والوصول إلى البحث.

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

لا تغيّر Bundle ID أو Team أو Signing أو Entitlements من تعليمات التشغيل. الرفع إلى App Store Connect يحتاج Archive موقّع وبيئة Xcode Cloud إنتاجية مسموحة ومراجعة بيانات الخصوصية يدويًا.

راجع:

- `docs/FINAL_EXECUTION_REPORT.md`
- `docs/IOS_MODERNIZATION_REPORT.md`
- `docs/RELEASE_CHECKLIST.md`
