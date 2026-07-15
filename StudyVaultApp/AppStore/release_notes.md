# ملاحظات الإصدار 1.10.0

- تحديث إعدادات الإصدار والبناء لتفادي مسارات App Store Connect المغلقة أو أرقام البناء المستخدمة سابقًا.
- إضافة فحص مبكر في Xcode Cloud يمنع استخدام Xcode Beta أو SDK غير مناسب قبل مرحلة الأرشفة.
- توحيد مصدر أرقام الإصدار والبناء عبر `MARKETING_VERSION` و`CURRENT_PROJECT_VERSION`.
- تحسين وثائق التحقق قبل الرفع لضمان استخدام Archive جديد من Commit الصحيح.

## English Release Notes 1.10.0

- Updated release and build settings to avoid closed App Store Connect trains and previously used build numbers.
- Added an early Xcode Cloud preflight check that blocks Beta Xcode or unsupported SDKs before archiving.
- Unified version and build values through `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`.
- Improved release verification documentation to require a fresh archive from the correct commit.

# ملاحظات الإصدار 1.9.0

- تجهيز إصدار إنتاجي جديد برقم بناء أعلى لتفادي إعادة استخدام مسارات إصدارات أو Builds مغلقة في App Store Connect.
- مراجعة إعدادات المشروع، الخصوصية، وبيانات الإصدار مع الحفاظ على Bundle ID والتوقيع كما هي.
- التحقق من نجاح بناء Debug وRelease بدون توقيع داخل بيئة Xcode المحلية.
- تحديث وثائق الاستعداد للإصدار وقائمة التحقق قبل تشغيل Xcode Cloud أو الإرسال للمراجعة.

## English Release Notes 1.9.0

- Prepared a new production release with an increased build number to avoid reusing closed App Store Connect trains or builds.
- Reviewed project configuration, privacy metadata, and release settings while preserving the existing bundle identifier and signing setup.
- Verified local unsigned Debug and Release builds with Xcode.
- Updated release readiness documentation and the checklist for Xcode Cloud or review submission.

# ملاحظات الإصدار 1.8.0

- تحسين استقرار المتصفح الداخلي عند فتح روابط البحث أو إدخال عبارات بحث مخصصة.
- تجهيز رقم إصدار وبناء جديدين للاختبار والتحقق قبل أي رفع رسمي.
- إضافة توثيق مراجعة iOS وقائمة تحقق للإصدار تشمل البناء، الخصوصية، إمكانية الوصول، وبيانات App Store.

## English Release Notes 1.8.0

- Improved internal comparison browser stability when opening search links or custom search terms.
- Prepared a new version and build number for validation before any official upload.
- Added iOS modernization documentation and a release checklist covering build, privacy, accessibility, and App Store readiness.

# ملاحظات الإصدار 1.6

- رفع رقم الإصدار لمعالجة رفض App Store Connect المرتبط بإغلاق مسار الإصدار السابق.
- تغيير الاسم الظاهر داخل الواجهة إلى وش الرأي.
- إضافة ملخص قرار ذكي داخل صفحة المقارنة يوضح الخيار المتقدم ونسبة الثقة وأهم إشارات القرار.
- إضافة معايير تقييم حسب التصنيف مثل السعر، الجودة، البطارية، الاعتمادية، الخدمة، والقيمة مقابل السعر.
- إضافة أسباب تصويت جاهزة حسب نوع المقارنة لتقليل التعليقات العشوائية وتسهيل فهم النتائج.
- إضافة خيار "جرّبت هذا الخيار فعليًا" لإظهار شارة مجرّب فعليًا بجانب الرأي.
- إضافة فلترة للتعليقات حسب كل الآراء، آراء المجربين فعليًا، أو أسباب التصويت فقط.
- إضافة حفظ حالة القرار: أفكر أشتريه، قيد المقارنة، قررت، تم الشراء.
- إضافة مشاركة نص نتيجة المقارنة من داخل صفحة القرار.
- إضافة سبب التصويت: عند اختيار أي خيار يمكن للمستخدم كتابة سبب واضح يشرح لماذا صوّت له.
- عرض أسباب المصوتين تحت السؤال مع بطاقة توضح الخيار المرتبط بكل رد.
- تحسين نصوص صفحة السؤال لتفرق بين التعليق العام وسبب التصويت.
- تصميم أحدث بواجهة زجاجية أكثر وضوحًا وأناقة.
- قاعدة معرفة محلية موسعة تضم 180 عنصرًا مرجعيًا عبر الجوالات، السيارات، المطاعم، اللابتوبات، الألعاب، السفر، وخدمات أخرى.
- تحسين محرك البحث المحلي ليقرأ الاسم، المجال، المواصفات، نقاط القوة، الملاحظات، والاستخدام المناسب.
- إضافة بطاقات بيانات تفصيلية لكل عنصر مقارنة.
- تحديث أيقونة التطبيق إلى تصميم زجاجي ثلاثي الأبعاد بدون نص.
- تحسين شاشة المقارنة الذكية ووضوح عرض النتائج.
