# مقترح ميزات وتطوير تطبيق وش الرأي

تاريخ الإعداد: 2026-07-30

## 1. Executive Summary

تطبيق **وش الرأي** هو تطبيق iOS/iPadOS عربي أصلي مبني بـSwiftUI يساعد المستخدم على إنشاء مقارنات، جمع التصويتات والأسباب، وتحويلها إلى ملخص قرار واضح. التطبيق تجاوز مرحلة “استطلاع بسيط” محليًا؛ لديه SwiftData، تصميم عربي فاخر، مقارنة موزونة، مكتبة معرفة، مساعد ذكي محلي، كاميرا قرار محلية، QR، مشاركة، تذكيرات، وتدفق إنشاء جيد.

أكبر فرصة الآن ليست إضافة زخارف أو مزايا سطحية، بل تحويل الأساس المحلي إلى منصة قرار اجتماعية موثوقة: Backend إنتاجي، مصادقة خادمية، منع تلاعب، إشراف، مزامنة، إشعارات، وروابط مشاركة عامة. بدون ذلك ستبقى أقوى ميزات التطبيق محلية أو تجريبية، ولن تعطي قيمة جماعية حقيقية على نطاق App Store.

أعلى أولوية مقترحة: **بوابة منصة القرار الإنتاجية**: ربط التطبيق بBackend إنتاجي حقيقي مع Sign in with Apple server-side، PostgreSQL، صلاحيات، منع تكرار التصويت، وإشراف أولي.

## 2. App Understanding

### ما تم فحصه

- `StudyVaultApp/AGENTS.md`
- `StudyVaultApp/README.md`
- `StudyVaultApp/IMPLEMENTATION_PLAN.md`
- `StudyVaultApp/PRODUCT_ROADMAP_AR.md`
- `StudyVaultApp/docs/BACKEND_API.md`
- `StudyVaultApp/docs/DECISION_PLATFORM_GATES.md`
- `StudyVaultApp/docs/RELEASE_CHECKLIST.md`
- `StudyVaultApp/docs/XCODE_CLOUD_RELEASE.md`
- `StudyVaultApp/backend/README.md`
- `StudyVaultApp/backend/package.json`
- `StudyVaultApp/backend/server.mjs`
- `StudyVaultApp/backend/tests/smoke.mjs`
- `StudyVaultApp/StudyVault/StudyVaultApp.swift`
- `StudyVaultApp/StudyVault/ContentView.swift`
- `StudyVaultApp/StudyVault/DesignSystem.swift`
- `StudyVaultApp/StudyVault/AskModels.swift`
- `StudyVaultApp/StudyVault/ViewModels.swift`
- `StudyVaultApp/StudyVault/PersistenceModels.swift`
- `StudyVaultApp/StudyVault/DecisionEngines.swift`
- `StudyVaultApp/StudyVault/CreateComparisonView.swift`
- `StudyVaultApp/StudyVault/QuestionDetailView.swift`
- `StudyVaultApp/StudyVault/SmartComparisonView.swift`
- `StudyVaultApp/StudyVault/AccountView.swift`
- `StudyVaultApp/StudyVault/AIDecisionAssistant.swift`
- `StudyVaultApp/StudyVault/PermissionsOnboardingView.swift`
- `StudyVaultApp/StudyVault/UserSession.swift`
- `StudyVaultApp/StudyVault/Info.plist`
- `StudyVaultApp/StudyVault/PrivacyInfo.xcprivacy`
- `StudyVaultApp/StudyVaultTests/StudyVaultCoreTests.swift`
- `StudyVaultApp/StudyVaultUITests/StudyVaultUITests.swift`
- `StudyVaultApp/AppStore/metadata_ar.md`
- `StudyVaultApp/ci_scripts/ci_post_clone.sh`

### التقنية الحالية

- النوع: تطبيق iOS/iPadOS Native.
- اللغة: Swift 6.
- الواجهة: SwiftUI.
- التخزين المحلي: SwiftData مع بقايا UserDefaults للإعدادات الخفيفة.
- الباكند: Node.js 20، بدون dependencies، تخزين JSON للتطوير فقط.
- المصادقة: Sign in with Apple داخل التطبيق، لكن بدون تحقق إنتاجي خادمي كامل.
- الإصدار الحالي في المشروع: `MARKETING_VERSION = 2.0` و`CURRENT_PROJECT_VERSION = 79`.
- App Store release path: Xcode Cloud فقط.

### المستخدمون المستهدفون

- مستخدم محتار بين منتجين أو خدمات أو قرارات شخصية.
- مستخدم يريد رأي الناس مع أسباب، وليس نسبة تصويت فقط.
- صانع قرار عائلي أو جماعي يحتاج تصويتًا خاصًا.
- مستخدم عربي/Saudi-first يريد تجربة عربية RTL طبيعية.

## 3. Current Feature Inventory

- Splash وOnboarding وPermissions onboarding.
- تبويبات: الرئيسية، اكتشف، قارن، المكتبة، الحساب.
- إنشاء مقارنة من خيارين إلى 10 خيارات.
- حفظ المسودات والمقارنات والتصويتات محليًا.
- تصويت مع سبب، تصنيف سبب، وتجربة موثقة ذاتيًا.
- منع التصويت المحلي المكرر.
- ملخص قرار، ثقة، جودة أدلة، نقاط قوة/ملاحظات.
- تحليل أسباب عربي محلي قائم على قواعد.
- مقارنة شخصية حسب معايير وأوزان.
- متابعة القرار بعد التجربة.
- مشاركة نصية، QR، بطاقة PNG، وتذكير محلي.
- بحث وتصنيف وفرز ومكتبة معرفة محلية.
- مساعد قرار ذكي محلي لا يرسل البيانات للخارج.
- كاميرا قرار محلية تستخدم Vision لتحويل صورة إلى مسودة مقارنة.
- Backend تطوير يدعم المقارنات، الغرف الخاصة، التصويت، التعليقات، البلاغات، وAI endpoints محلية.
- اختبارات Unit جيدة لمسارات القرار والتخزين، وUI smoke محدود.

## 4. Current Technical State

القوة التقنية الحالية:

- بنية SwiftUI/MVVM عملية وواضحة.
- Design System موحد (`WeshTheme`, أزرار، بطاقات، Empty/Status states).
- SwiftData يغطي البيانات الأساسية.
- Keychain مستخدم لمعرف Apple والبريد.
- Privacy Manifest موجود.
- اختبارات وحدة واسعة نسبيًا.
- Xcode Cloud مضبوط كمسار إصدار مع preflight.

الفجوات التقنية:

- Backend الحالي مصمم للتطوير فقط، JSON وليس PostgreSQL فعليًا.
- مصادقة الخادم غير مكتملة؛ `X-Client-ID` لا يكفي لإنتاج اجتماعي.
- الإبلاغ والإشراف غير مكتملين كعملية إنتاجية.
- لا توجد Universal Links أو صفحة ويب عامة للمقارنات.
- لا توجد Push Notifications إنتاجية.
- أذونات الموقع وATT موصوفة كاستخدام مستقبلي؛ هذا خطر خصوصية ومراجعة إذا بقي بلا حاجة حالية واضحة.
- Release docs تحتوي بعض أرقام قديمة مقابل المشروع الحالي؛ تحتاج توحيدًا قبل أي رفع رسمي.
- Live Activities وStoreKit وCloudKit موثقة كبوابات مستقبلية وليست مفعلة.

## 5. Gaps and Opportunities

أكبر فجوات المنتج:

1. القيمة الجماعية لا تكتمل دون Backend إنتاجي ومصادقة موثوقة.
2. المشاركة تحتاج روابط عامة/Universal Links حتى تنتشر المقارنات خارج التطبيق.
3. الثقة تحتاج إشرافًا، إبلاغًا فعليًا، وحماية من التلاعب.
4. الأذونات يجب أن تكون عند الحاجة لا دفعة واحدة، خصوصًا الموقع والتتبع.
5. AI الحالي مفيد محليًا، لكن يمكن تطويره لاحقًا عبر Backend بحدود خصوصية واضحة.

أكبر فرص النمو:

- غرف قرار خاصة للعائلة والأصدقاء والفرق.
- صفحة نتيجة قابلة للمشاركة كرابط وصورة.
- تنبيهات عند تغير المتصدر أو وصول عدد أصوات محدد.
- سجل قرارات ورضا بعد التجربة.
- تصفية آراء أصحاب التجربة.
- صفحة ويب عامة للمقارنات لزيادة المشاركة والاكتشاف.

## 6. Prioritized Feature List

| الأولوية | الميزة | الأثر | الصعوبة | السبب |
|---|---|---:|---:|---|
| P0 | Backend إنتاجي ومصادقة خادمية | High | High | أساس التصويت الحقيقي ومنع التلاعب |
| P0 | سياسة أذونات تدريجية وخصوصية أدق | High | Medium | يقلل رفض App Store ويرفع ثقة المستخدم |
| P0 | Universal Links وصفحات مشاركة عامة | High | Medium | يزيد انتشار المقارنات |
| P1 | إشعارات ذكية لتغير النتيجة والانتهاء | High | Medium | يعيد المستخدم للتطبيق في لحظة مهمة |
| P1 | إشراف وبلاغات إنتاجية | High | Medium | ضروري لمحتوى المستخدمين |
| P1 | فلترة آراء أصحاب التجربة | Medium | Medium | يزيد جودة القرار |
| P1 | تحسين Assistant بBackend AI اختياري | Medium | Medium | يرفع جودة التلخيص مع حماية الخصوصية |
| P2 | Live Activities | Medium | High | مناسبة للمقارنات النشطة لكنها تتطلب Extension/Capabilities |
| P2 | وش الرأي بلس | Medium | High | جيد بعد إثبات الاستخدام لا قبله |
| Later | سوق عروض وأسعار Affiliate | Medium | High | يحتاج شراكات وسياسات إفصاح |

## 7. Detailed Feature Proposals

### 7.1 Backend إنتاجي ومصادقة خادمية

- لماذا يناسب التطبيق: وش الرأي يعتمد على رأي المجتمع، وهذا لا يكتمل محليًا.
- المشكلة: Backend التطوير لا يمنع التلاعب إنتاجيًا ولا يثبت هوية المستخدم.
- فائدة المستخدم: أصوات موثوقة، غرف تعمل بين الأجهزة، نتائج لا تضيع.
- فائدة المنتج: أساس النمو والمشاركة والإشراف والتحليلات.
- مكان الظهور: كل المقارنات العامة والخاصة والتصويت والتعليقات.
- طريقة العمل: PostgreSQL، تحقق Sign in with Apple على الخادم، جلسات قصيرة العمر، قيود تصويت فريدة، rate limits.
- UI/UX: حالات اتصال أوضح، شارة “متصل/محلي”، رسائل فشل مزامنة قابلة للمحاولة.
- Backend/data: تطبيق `001_initial_schema.sql` و`002_decision_rooms.sql` فعليًا، إضافة جداول جلسات/تدقيق/بلاغات.
- الأذونات: لا أذونات جهاز جديدة.
- الخصوصية/الأمن: لا تقبل `userID` من العميل، لا تخزن PII غير لازم، تشفير HTTPS، سجلات دون أسرار.
- الصعوبة: High.
- الأثر: High.
- الأولوية: P0.
- معايير القبول: تصويت واحد لكل مستخدم موثق، غرف خاصة لا تظهر في البحث، rollback آمن، اختبارات API.
- الاختبارات: auth invalid/expired، duplicate vote، private room leak، rate limit، DB transaction rollback.

### 7.2 سياسة أذونات تدريجية

- لماذا تناسب التطبيق: التطبيق يحتاج الثقة أكثر من طلب صلاحيات مبكرًا.
- المشكلة: طلب الإشعارات/الموقع/الكاميرا/ATT من أول تشغيل قد يبدو زائدًا، وبعض الاستخدامات “مستقبلية”.
- فائدة المستخدم: تحكم أوضح ورفض أقل للأذونات.
- فائدة المنتج: تقليل مخاطر App Review ورفع التحويل.
- مكان الظهور: Onboarding، الكاميرا عند فتحها، الإشعارات عند تفعيل تذكير، الموقع عند ميزة محلية فعلية.
- طريقة العمل: شاشة تعريف عامة بدون طلب مباشر لكل الأذونات، ثم طلب كل إذن عند أول حاجة حقيقية.
- UI/UX: microcopy يشرح القيمة اللحظية فقط.
- Backend/data: لا يوجد.
- الأذونات: Camera/Notifications عند الحاجة؛ تأجيل Location/ATT حتى وجود ميزة حقيقية.
- الخصوصية/الأمن: تقليل جمع البيانات؛ تحديث Privacy Labels حسب الواقع.
- الصعوبة: Medium.
- الأثر: High.
- الأولوية: P0.
- معايير القبول: لا يظهر طلب موقع أو ATT دون مسار يستخدمه فعليًا، كل إذن له شاشة سبب.
- الاختبارات: أول تشغيل، فتح الكاميرا، تفعيل تذكير، رفض الإذن، إعادة المحاولة.

### 7.3 Universal Links وصفحة مقارنة عامة

- لماذا تناسب التطبيق: المشاركة هي محرك نمو التطبيق.
- المشكلة: URL Scheme وحده لا يكفي لمن لا يملك التطبيق ولا يعطي معاينة ويب.
- فائدة المستخدم: يشارك المقارنة مع أي شخص، ويفتحها من واتساب أو المتصفح.
- فائدة المنتج: نمو عضوي وفهرسة مستقبلية.
- مكان الظهور: مشاركة المقارنة، QR، بطاقة النتيجة.
- طريقة العمل: نطاق HTTPS، `apple-app-site-association`، صفحة ويب خفيفة تعرض عنوان/نتيجة/زر فتح التطبيق.
- UI/UX: زر “مشاركة الرابط العام”، fallback “افتح في التطبيق”.
- Backend/data: public comparison read endpoint، short IDs/slug، metadata OpenGraph.
- الأذونات: لا يوجد.
- الخصوصية/الأمن: لا تعرض المقارنات الخاصة، تحقق invite code للخاص.
- الصعوبة: Medium.
- الأثر: High.
- الأولوية: P0.
- معايير القبول: الرابط العام يفتح التطبيق إذا مثبتًا والويب إذا غير مثبت، الخاص لا يتسرب.
- الاختبارات: Universal Link، private link، no app fallback، OpenGraph preview.

### 7.4 إشعارات ذكية للمقارنات

- لماذا تناسب التطبيق: القرار يتغير بمرور الوقت.
- المشكلة: المستخدم لا يعرف متى تغيّر المتصدر أو انتهى التصويت.
- فائدة المستخدم: يرجع وقت الحدث المهم فقط.
- فائدة المنتج: retention أعلى.
- مكان الظهور: شاشة التفاصيل، التذكيرات، الإعدادات.
- طريقة العمل: APNs عبر Backend للإشعارات البعيدة، وإشعارات محلية للتذكير الفردي.
- UI/UX: خيارات “عند تغير المتصدر”، “قبل الانتهاء”، “عند 50 صوت”.
- Backend/data: جدول subscriptions، push tokens، event rules.
- الأذونات: Notifications عند أول تفعيل تذكير/متابعة.
- الخصوصية/الأمن: tokens مرتبطة بمستخدم موثق، حذف token عند sign-out.
- الصعوبة: Medium.
- الأثر: High.
- الأولوية: P1.
- معايير القبول: لا spam، يمكن إلغاء المتابعة، لا إشعارات لمقارنات خاصة دون صلاحية.
- الاختبارات: token registration، event trigger، opt-out، expired comparison.

### 7.5 إشراف وبلاغات إنتاجية

- لماذا تناسب التطبيق: المحتوى منشأ من المستخدمين.
- المشكلة: البلاغات الحالية محلية/تطويرية ولا توجد دورة مراجعة.
- فائدة المستخدم: مجتمع أنظف وأكثر ثقة.
- فائدة المنتج: امتثال App Store ومخاطر أقل.
- مكان الظهور: قائمة المزيد في التفاصيل، التعليقات، الأسباب.
- طريقة العمل: بلاغات في الخادم، حالات مراجعة، إخفاء مؤقت عند تكرار البلاغ، لوحة مراجعة داخلية لاحقًا.
- UI/UX: رسائل “استلمنا البلاغ”، خيارات سبب واضحة.
- Backend/data: reports, moderation_actions, audit_log.
- الأذونات: لا يوجد.
- الخصوصية/الأمن: حماية هوية المبلّغ، audit لكل مشرف.
- الصعوبة: Medium.
- الأثر: High.
- الأولوية: P1.
- معايير القبول: البلاغ يصل للخادم، لا يكرر بشكل مزعج، المحتوى الخاص لا يطلع لغير المصرح.
- الاختبارات: invalid report، duplicate report، moderator action, audit log.

### 7.6 فلترة آراء أصحاب التجربة

- لماذا تناسب التطبيق: قيمة التطبيق في “سبب الاختيار”، لا شعبية الخيار فقط.
- المشكلة: شارة “مجرّب” ذاتية حاليًا ولا توجد فلاتر متقدمة.
- فائدة المستخدم: يرى آراء أقرب للواقع.
- فائدة المنتج: تمايز عن تطبيقات التصويت.
- مكان الظهور: تفاصيل المقارنة، ملخص القرار، تبويب الأسباب.
- طريقة العمل: فلتر “من جرّب”، “أسباب مفيدة”، “أسباب معاكسة للمتصدر”.
- UI/UX: segmented controls خفيفة، شرح أن التحقق ذاتي حتى اعتماد تحقق أقوى.
- Backend/data: حقول experience_type, helpful_votes.
- الأذونات: لا يوجد حاليًا؛ إثبات بالصور لاحقًا يحتاج كاميرا/صور مع سياسة خصوصية.
- الخصوصية/الأمن: لا تجمع فواتير/صور إثبات قبل سياسة تخزين ومراجعة واضحة.
- الصعوبة: Medium.
- الأثر: Medium.
- الأولوية: P1.
- معايير القبول: الفلاتر لا تخفي الرأي المخالف، وتوضح معنى الشارة.
- الاختبارات: filter logic، accessibility labels، empty filtered state.

### 7.7 AI Assistant إنتاجي اختياري عبر Backend

- لماذا يناسب التطبيق: المستخدم يريد تلخيصًا وأسبابًا وصياغة مقارنة بسرعة.
- المشكلة: المحرك الحالي محلي rule-based ومحدود.
- فائدة المستخدم: أسئلة طبيعية وتلخيص أفضل دون قراءة كل التعليقات.
- فائدة المنتج: تمييز قوي بشرط ضبط التكلفة والخصوصية.
- مكان الظهور: زر المساعد، شاشة التفاصيل، إنشاء المقارنة.
- طريقة العمل: AI provider عبر Backend فقط، سياق محدود، redaction، no conversation storage افتراضيًا.
- UI/UX: إفصاح “إجابة إرشادية”، مصادر مختصرة، زر إعادة المحاولة، لا تنفيذ حساس دون تأكيد.
- Backend/data: provider adapter، usage limits، prompt templates، safety logs دون محتوى حساس.
- الأذونات: لا يوجد.
- الخصوصية/الأمن: لا مفاتيح داخل app، لا إرسال بيانات خاصة دون صلاحية، حماية prompt injection.
- الصعوبة: Medium.
- الأثر: Medium.
- الأولوية: P1.
- معايير القبول: fallback محلي عند فشل المزود، لا تسريب private rooms، timeout.
- الاختبارات: provider failure، timeout، prompt injection، private access.

### 7.8 Live Activities للمقارنات النشطة

- لماذا تناسب التطبيق: بعض المقارنات زمنية وتحتاج متابعة سريعة.
- المشكلة: لا يوجد Widget Extension أو ActivityKit target.
- فائدة المستخدم: يرى المتصدر والوقت المتبقي من شاشة القفل.
- فائدة المنتج: تفاعل أعلى لكن بعد اكتمال Backend/APNs.
- مكان الظهور: زر “تابع على شاشة القفل”.
- طريقة العمل: Widget Extension، ActivityKit، تحديث محلي/remote push.
- UI/UX: عرض المتصدر، النسبة، عدد الأصوات، الوقت المتبقي.
- Backend/data: push token وactivity updates.
- الأذونات: Live Activities/APNs.
- الخصوصية/الأمن: لا تعرض مقارنة خاصة على شاشة القفل إلا بموافقة واضحة.
- الصعوبة: High.
- الأثر: Medium.
- الأولوية: P2.
- معايير القبول: يعمل على جهاز فعلي، ينتهي عند إغلاق المقارنة، لا يعرض بيانات حساسة.
- الاختبارات: physical device, Dynamic Island, lock screen, remote update.

### 7.9 وش الرأي بلس

- لماذا يناسب التطبيق: ميزات الفرق والغرف الخاصة والتقارير قابلة للدفع.
- المشكلة: الدفع قبل بناء المجتمع قد يضر النمو.
- فائدة المستخدم: غرف خاصة غير محدودة، تقارير موسعة، أرشيف، تصدير.
- فائدة المنتج: دخل مستدام.
- مكان الظهور: الحساب، حدود الاستخدام، التصدير.
- طريقة العمل: StoreKit 2 بعد اعتماد Product IDs من App Store Connect.
- UI/UX: لا تمنع التصويت الأساسي أو قراءة النتائج.
- Backend/data: entitlements cache وربط المستخدم.
- الأذونات: لا يوجد.
- الخصوصية/الأمن: تحقق معاملات، استعادة مشتريات، لا hardcoded fake IDs.
- الصعوبة: High.
- الأثر: Medium.
- الأولوية: Later/P2 بعد نمو الاستخدام.
- معايير القبول: Sandbox/TestFlight، restore، manage subscription.
- الاختبارات: StoreKit config، purchase pending/cancelled/verified.

## 8. Development Improvement Proposal

### المعمارية

- نقل Backend من JSON إلى PostgreSQL بطبقة Repository واضحة.
- فصل AI provider adapter عن endpoints.
- إضافة shared API contract tests بين Swift والباكند عند استقرار العقود.
- تقليل تضخم `AskModels.swift` تدريجيًا بتقسيم domain models/services دون تغيير السلوك.

### جودة الكود

- الحفاظ على Design System وعدم إدخال styles محلية عشوائية.
- إضافة SwiftLint/SwiftFormat فقط إذا استقر الفريق على قواعده.
- توثيق نماذج البيانات التي لها أثر ترحيل.

### UI/UX

- إبقاء الصفحة الرئيسية موجهة للقرار لا للتفاعل الاجتماعي العام.
- تقليل طلب الأذونات المبكر.
- إضافة حالات Offline Sync واضحة: “محلي”، “بانتظار المزامنة”، “تمت المزامنة”.

### Accessibility وRTL

- توسيع UI tests لمسارات RTL والنص الطويل.
- فحص Dynamic Type بأكبر حجم على جهاز فعلي.
- التأكد أن الرسوم والنسب مقروءة نصيًا ولا تعتمد على اللون فقط.

### الأداء

- مراقبة قوائم المكتبة والمقارنات عند نمو البيانات فوق آلاف العناصر.
- نقل البحث الثقيل مستقبلًا إلى index محلي أو Backend.
- منع work على MainActor عند sync أو parsing كبير.

### الأمن والخصوصية

- إزالة/تأجيل ATT والموقع حتى وجود استخدام فعلي مثبت.
- عدم استخدام API token مشترك في نسخة App Store.
- اعتماد جلسات خادمية قصيرة العمر.
- إضافة سياسة حذف بيانات المستخدم والتصدير عند وجود Backend إنتاجي.

### الاختبارات

- زيادة smoke tests للباكند مع PostgreSQL.
- اختبارات Authorization للغرف الخاصة.
- UI test لمسار نشر مقارنة وتصويت وفتح ملخص.
- Snapshot أو screenshot validation للتصميم الأساسي إن أمكن.

### CI/CD والإصدار

- توحيد أرقام الإصدار في وثائق release checklist مع المشروع الحالي `2.0 (79)`.
- جعل Xcode Cloud يشغل Unit/UI tests قبل Archive حسب الوثيقة.
- منع أي رفع إذا تغيرت Privacy Manifest/Info.plist دون مراجعة App Privacy.

## 9. Roadmap by Phases

### Phase 1: Fast Improvements and Essential Fixes

- الهدف: تثبيت جاهزية المنتج قبل توسيع الميزات.
- الميزات: سياسة أذونات تدريجية، حالات مزامنة واضحة، تنظيف وثائق الإصدار، تحسين مشاركة الرابط الحالية، تعزيز اختبارات UI الأساسية.
- التحسينات التقنية: توحيد الوثائق، إضافة اختبارات permissions/onboarding، مراجعة Privacy Manifest.
- النتيجة: نسخة App Store أوضح وأقل مخاطرة.
- التعقيد: Medium.
- المخاطر: تغيير onboarding قد يؤثر على أول تجربة.
- القبول: لا طلب إذن غير مستخدم فعليًا، docs متوافقة مع version الحالي، build/tests تمر.
- التحقق: xcodebuild Debug/Release، Unit/UI tests، plutil، validation scripts.

### Phase 2: Main Feature Expansion and Technical Cleanup

- الهدف: تحويل التطبيق من محلي قوي إلى منصة مشاركة حقيقية.
- الميزات: Backend إنتاجي، Sign in with Apple server-side، Universal Links، صفحات ويب عامة، إشراف وبلاغات.
- التحسينات التقنية: PostgreSQL، معاملات، auth sessions، rate limits، monitoring.
- النتيجة: تصويت جماعي موثوق وقابل للنمو.
- التعقيد: High.
- المخاطر: الخصوصية، الهجرة، التكاليف التشغيلية.
- القبول: private/public access صحيح، منع التكرار، smoke/integration tests.
- التحقق: API integration tests، staging environment، TestFlight.

### Phase 3: Advanced Capabilities

- الهدف: زيادة التمايز والنمو والدخل بعد ثبات المنصة.
- الميزات: Push Notifications، AI provider عبر Backend، Live Activities، StoreKit Plus، تحليلات قرار متقدمة.
- التحسينات التقنية: APNs، provider adapter، usage metering، observability، admin moderation.
- النتيجة: منتج قرار عربي متقدم.
- التعقيد: High.
- المخاطر: تكلفة AI، مراجعة App Store، إدارة الاشتراكات.
- القبول: limits، fallback، privacy labels، sandbox purchases.
- التحقق: device testing، TestFlight cohorts، production monitoring.

## 10. Security and Privacy Considerations

- لا تطلب الموقع أو ATT قبل وجود ميزة فعلية تستخدمهما.
- لا تخزن صور الكاميرا أو ترفعها دون موافقة وسياسة واضحة.
- لا تعتمد على `X-Client-ID` كهوية إنتاجية.
- لا ترسل مقارنات خاصة إلى AI provider.
- لا تعرض نتائج غرفة خاصة عبر صفحة ويب عامة.
- اجعل الإبلاغ والإشراف قابلين للتدقيق.
- وثق Retention وحذف البيانات عند إضافة Backend.

## 11. UI/UX Considerations

- حافظ على الهوية: فحم/زمرد/ذهبي، قرار موثوق، لغة عربية قصيرة.
- اجعل “ملخص القرار” مركز التجربة لا مجرد بطاقة.
- لا تحول التطبيق إلى شبكة اجتماعية صاخبة؛ التفاعل يخدم القرار.
- اجعل إنشاء المقارنة سريعًا لكن مع مسار “قرار عميق” اختياري.
- أظهر دائمًا الفرق بين “رأي المجتمع” و“الأنسب لك”.
- اجعل حالات الفشل مفهومة: offline، sync pending، backend unavailable.

## 12. Testing Recommendations

- Unit: decision engines, validation, Arabic normalization, AI local fallback.
- Integration: backend auth, rooms, votes, reports, AI endpoints.
- UI: onboarding, permissions, create comparison, vote, summary, assistant, share.
- Accessibility: Dynamic Type, VoiceOver labels, contrast.
- Release: plutil, privacy manifest, version/build checks, xcodebuild Debug/Release.
- Backend: smoke with isolated data, PostgreSQL transaction tests عند الانتقال للإنتاج.

## 13. Release Readiness Recommendations

- لا ترسل نسخة تستخدم Backend JSON كإنتاج اجتماعي عام.
- راجع App Privacy Labels بعد أي تغيير في الأذونات أو AI أو Backend.
- وحّد وثائق الإصدار التي ما زالت تذكر `1.10.0/52` مع المشروع الحالي `2.0/79`.
- شغل UI tests في Xcode Cloud قبل Archive.
- حدّث Screenshots بعد أي تغيير في onboarding/permissions.
- لا تضف StoreKit أو Live Activity حتى توفر بيانات Apple Developer الحقيقية.

## 14. Risks and Tradeoffs

- إضافة Backend إنتاجي قبل ضبط الحوكمة قد تفتح مخاطر محتوى وتلاعب.
- طلب الأذونات دفعة واحدة قد يرفع الرفض ويضعف الثقة.
- AI خارجي يعطي قيمة أعلى لكنه يزيد التكلفة ومسؤولية الخصوصية.
- الاشتراكات المبكرة قد تكسر نمو المجتمع.
- Universal Links مفيدة جدًا لكنها تحتاج نطاقًا واستضافة وصيانة.

## 15. Recommended Next Implementation Command for Codex

```text
ROLE
أنت Senior iOS Engineer, Privacy Engineer, QA Lead, وRelease Readiness Engineer لتطبيق وش الرأي.

TASK
نفّذ Phase 1 فقط من FEATURE_AND_DEVELOPMENT_PROPOSAL.md: تحسين سياسة الأذونات والخصوصية، توحيد وثائق الإصدار مع الإصدار الحالي، إضافة/تحديث اختبارات مناسبة، والتحقق الكامل محليًا. لا تنفذ Backend إنتاجي، لا تضف Universal Links، لا تضف StoreKit، ولا تضف Live Activities.

SCOPE
اعمل داخل StudyVaultApp فقط. ركز على:
- StudyVault/PermissionsOnboardingView.swift
- StudyVault/StudyVaultApp.swift
- StudyVault/Info.plist
- StudyVault/PrivacyInfo.xcprivacy
- StudyVaultTests/StudyVaultCoreTests.swift
- StudyVaultUITests/StudyVaultUITests.swift
- README.md
- docs/RELEASE_CHECKLIST.md
- docs/XCODE_CLOUD_RELEASE.md
- AppStore/metadata_ar.md عند الحاجة

REQUIREMENTS
1. لا تطلب إذن الموقع أو ATT في أول تشغيل ما لم توجد ميزة فعلية تستخدمهما الآن.
2. أبقِ طلب الكاميرا عند فتح ميزة كاميرا القرار فقط.
3. أبقِ طلب الإشعارات عند تفعيل تذكير أو متابعة فقط.
4. حدّث النصوص لتوضح أن الأذونات اختيارية وتُطلب عند الحاجة.
5. راجع Info.plist وPrivacyInfo.xcprivacy حتى تعكس التدفق الفعلي.
6. وحّد وثائق الإصدار مع MARKETING_VERSION وCURRENT_PROJECT_VERSION الحاليين.
7. أضف اختبارات أو عدّل UI smoke بما يثبت أن أول تشغيل لا يطلب أذونات غير لازمة.
8. لا تغيّر Bundle ID أو Team أو Signing أو Entitlements.

DO NOT CHANGE
- لا تغيّر اسم التطبيق.
- لا تغيّر Bundle ID.
- لا تغيّر Development Team.
- لا تضف Capabilities.
- لا تضف dependencies.
- لا تنفذ Backend إنتاجي.
- لا ترفع إلى App Store.
- لا تحذف ملفات غير مؤكدة.

ACCEPTANCE CRITERIA
- أول تجربة تعرض شرحًا واضحًا ولا تستدعي Location/ATT مبكرًا.
- الكاميرا تُطلب فقط عند استخدام كاميرا القرار.
- الإشعارات تُطلب فقط عند تفعيل تذكير/متابعة.
- Privacy strings لا تعد بميزات غير منفذة.
- وثائق الإصدار متوافقة مع version/build الحاليين.
- الاختبارات المناسبة محدثة.
- لا يوجد regression في إنشاء مقارنة أو فتح التفاصيل.

VALIDATION COMMANDS
StudyVaultApp/scripts/validate_wesh_alray_scope.sh
python3 StudyVaultApp/scripts/validate_wesh_alray_data.py
cd StudyVaultApp/backend && npm run check
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/StudyVaultPhase1Debug build
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/StudyVaultPhase1Release build
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /tmp/StudyVaultPhase1Tests test
plutil -lint StudyVaultApp/StudyVault/Info.plist StudyVaultApp/StudyVault/PrivacyInfo.xcprivacy
git diff --check -- StudyVaultApp

FINAL REPORT REQUIREMENTS
اكتب بالعربية:
1. ما تغير في الأذونات والخصوصية.
2. الملفات المعدلة.
3. الاختبارات المضافة أو المعدلة.
4. أوامر التحقق ونتائجها.
5. ما لم يتم التحقق منه.
6. المخاطر المتبقية.
7. هل أصبح Phase 1 مكتملًا أم لا.
```
