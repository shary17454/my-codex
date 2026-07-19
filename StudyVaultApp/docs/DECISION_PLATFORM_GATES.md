# بوابات ميزات القرار والمنصة

## منفذ ومختبر داخل Target الحالي

- SwiftData للمقارنات والخيارات والمسودات والتصويتات والمحفوظات ونتائج التجربة.
- ترحيل بيانات UserDefaults القديمة بعد نجاح حفظ SwiftData.
- محرك أوزان ومعايير ونتيجة شخصية مقابل رأي المجتمع.
- حالة القرار والثقة وجودة الأدلة كمؤشرات منفصلة.
- تحليل أسباب عربي محلي قائم على قاموس وقواعد معلنة.
- متابعة القرار والرضا وإمكانية اختيار الخيار مجددًا.
- غرف عامة وخاصة ورموز دعوة في Backend التطوير.
- منع تكرار التصويت في SwiftData وعلى Backend التطوير.
- بطاقة نتيجة PNG وQR وCSV.
- مخطط زمني من أحداث تصويت فعلية.
- App Intent لإنشاء مسودة مقارنة وفتح التطبيق.
- TipKit لشرح ملخص القرار في موضعه.
- Privacy Manifest لسبب UserDefaults المعتمد `CA92.1`.

## Live Activity

غير مفعلة لأن المستودع لا يحتوي Widget Extension مصرحًا به، ولا Bundle ID للامتداد، ولا إعداد Push للأنشطة. تفعيلها الصحيح يتطلب:

1. إنشاء Widget Extension تحت حساب الفريق نفسه وتحديد Bundle ID فعلي من Apple Developer.
2. إضافة Live Activity UI و`NSSupportsLiveActivities` واختبار شاشة القفل وDynamic Island على جهاز فعلي.
3. عند التحديث البعيد: تخزين push token في Backend الإنتاج وإرسال تحديثات ActivityKit عبر APNs.
4. توحيد Marketing Version وBuild للامتداد والتطبيق والتحقق منهما داخل xcarchive.

لم تتم إضافة Target أوCapability أوEntitlement وهمي، التزامًا بعدم تغيير التوقيع دون تصريح وبيانات Apple الحقيقية.

## وش الرأي بلس / StoreKit 2

غير مفعّل لأن App Store Connect لا يوفر في المستودع Product IDs حقيقية أو أسعارًا أو مجموعة اشتراك أو نصوص شروط. الخطوات المطلوبة:

1. إنشاء Subscription Group ومنتجين شهري/سنوي في App Store Connect.
2. اعتماد Product IDs النهائية والترجمات والأسعار وفترات التجربة.
3. إضافة StoreKit 2 باستخدام تلك المعرّفات واختبارات StoreKit Configuration محلية.
4. إضافة استعادة المشتريات، إدارة الاشتراك، التحقق من Transaction، وسياسة مجانية واضحة.
5. اختبار Sandbox ثم TestFlight ومراجعة Agreements/Tax/Banking.

لا يجوز تصنيع Product IDs أو عرض Paywall قبل اكتمال هذه البيانات.

## Backend الإنتاج

المطلوب خارجيًا: نطاق HTTPS، PostgreSQL مُدار، Secrets Manager، معرفات Sign in with Apple الصحيحة، تحقق server-side من token وnonce، جلسات، APNs، مراقبة ونسخ احتياطية وسياسة احتفاظ وإشراف. ملفا SQL مرجعان للترحيل، لكن لم يتم نشر قاعدة أو خدمة خارجية.

## مزامنة CloudKit وUniversal Links

لم تُضف لأن كليهما يغير Capabilities أويتطلب نطاقًا وملف `apple-app-site-association`. التطبيق يستخدم SwiftData محليًا وURL Scheme حاليًا؛ تُنفذ هذه الخطوات فقط بعد اعتماد Container/Domain من حساب Apple.
