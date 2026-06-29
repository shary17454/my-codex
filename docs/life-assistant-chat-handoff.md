# مساعد الحياة - Life Assistant MVP Handoff

هذا الملف ينقل محتوى هذه الدردشة إلى المستودع `shary17454/my-codex` كملخص تنفيذي وتقني قابل للمتابعة.

## الطلب الأصلي

إنشاء MVP لتطبيق Flutter باسم **مساعد الحياة** يجمع التذكيرات والالتزامات الشخصية في مكان واحد، ويستخدم الذكاء الاصطناعي لترتيب الأولويات وإرسال تنبيهات ذكية قبل المواعيد المهمة.

الهدف: أن يصبح التطبيق مساعداً شخصياً يومياً حتى لا ينسى المستخدم أي التزام أو موعد مهم.

## نطاق MVP المطلوب

- تسجيل الدخول بالبريد الإلكتروني.
- تسجيل الدخول عبر Google.
- تسجيل الدخول عبر Apple.
- صفحة رئيسية تعرض:
  - أهم مهمة اليوم.
  - أهم 5 تنبيهات قادمة.
  - نسبة إنجاز المهام.
  - التقويم المختصر.
- إضافة عنصر جديد من الأنواع التالية:
  - الهوية الوطنية.
  - الإقامة.
  - جواز السفر.
  - رخصة القيادة.
  - تأمين السيارة.
  - تأمين طبي.
  - استمارة السيارة.
  - صيانة السيارة.
  - تغيير الزيت.
  - الفواتير.
  - الاشتراكات.
  - الأدوية.
  - المواعيد الطبية.
  - المناسبات.
  - المهام الشخصية.
  - أخرى.
- كل عنصر يحتوي على:
  - الاسم.
  - الوصف.
  - تاريخ البداية.
  - تاريخ الانتهاء.
  - مستوى الأهمية.
  - ملاحظات.
  - مرفقات اختيارية.
  - صورة اختيارية.
- ذكاء اصطناعي يعرض:
  - ما يجب فعله اليوم.
  - ترتيب الأولويات.
  - التنبيه قبل الموعد حسب الأهمية.
  - اقتراح أفضل وقت لإنجاز المهمة.
  - تلخيص أسبوعي.
  - تلخيص شهري.
- تقويم يومي وأسبوعي وشهري مع تلوين الأحداث حسب الأولوية.
- إشعارات قبل الموعد بشهر، أسبوعين، أسبوع، ثلاثة أيام، يوم، ساعتين، ووقت مخصص.
- لوحة إحصائيات تعرض:
  - عدد المهام.
  - عدد الوثائق.
  - عدد الوثائق المنتهية.
  - عدد الوثائق التي ستنتهي قريباً.
  - نسبة الالتزام.
  - المهام المنجزة.
- تصميم حديث مستوحى من Apple وMaterial 3، مع Light/Dark Mode، العربية والإنجليزية، وResponsive UI.

## التقنيات المختارة

- Flutter.
- Dart.
- Riverpod.
- GoRouter.
- Dio.
- Freezed annotations.
- Firebase Authentication.
- Firebase Firestore.
- Firebase Cloud Messaging.
- Firebase Analytics.
- Firebase Crashlytics.
- Hive للتخزين المحلي في MVP.
- Local Notifications.
- OpenAI API كطبقة قابلة للاستبدال.

## المعمارية المتفق عليها

تم اعتماد:

- Clean Architecture.
- Feature First.
- SOLID.
- Repository Pattern.
- Dependency Injection عبر Riverpod.
- Error Handling موحد.
- Logging.

تقسيم الميزات:

```text
lib/
  app/
    router/
    theme/
    localization/
    di/
  core/
    constants/
    errors/
    firebase/
    logging/
    network/
    utils/
    widgets/
  features/
    auth/
    home/
    commitments/
    calendar/
    notifications/
    ai_assistant/
    statistics/
```

## مراحل التنفيذ التي تمت في الدردشة

### Milestone 1: إنشاء المشروع والمعمارية

تم إنشاء مشروع Flutter باسم `life_assistant` وإعداد:

- `main.dart`.
- `LifeAssistantApp`.
- GoRouter.
- Theme Light/Dark باستخدام Material 3.
- Localization عربي/إنجليزي مبدئي.
- Core widgets.
- Core errors.
- Core network.
- Core logging.
- Feature-first folders.
- صفحات skeleton للمنزل، تسجيل الدخول، إضافة عنصر، التقويم، والإحصائيات.

تم تشغيل:

```bash
flutter analyze
flutter test
```

وكانت النتيجة بدون أخطاء.

### Milestone 2: المصادقة

تم تنفيذ:

- `AuthRemoteDataSource` باستخدام Firebase Auth.
- `AuthRepositoryImpl`.
- Use cases:
  - `SignInWithEmail`.
  - `SignInWithGoogle`.
  - `SignInWithApple`.
  - `SignOut`.
- `AuthController` وRiverpod providers.
- شاشة تسجيل دخول فعلية مع loading/error state.
- Apple Sign-In مع nonce صحيح.
- Google Sign-In API v7 باستخدام `authenticate()` و`initialize()`.

### Milestone 3: إدارة المهام والوثائق

تم تنفيذ:

- Entity: `Commitment`.
- Enums:
  - `CommitmentType`.
  - `PriorityLevel`.
- `CommitmentModel` مع JSON serialization يدوي.
- Hive local datasource.
- Firestore remote datasource جاهز عند توفر Firebase user.
- Repository implementation.
- Use cases:
  - `CreateCommitment`.
  - `UpdateCommitment`.
  - `DeleteCommitment`.
  - `GetCommitments`.
- `CommitmentsController`.
- شاشة إضافة عنصر تحفظ فعلياً في Hive.

### Milestone 4: التقويم والإشعارات

تم تنفيذ:

- صفحة تقويم بثلاثة تبويبات:
  - يومي.
  - أسبوعي.
  - شهري.
- تلوين حسب الأولوية:
  - منخفض: أخضر.
  - متوسط: أزرق.
  - عال: برتقالي.
  - حرج: أحمر.
- Notification lead times:
  - شهر.
  - أسبوعين.
  - أسبوع.
  - ثلاثة أيام.
  - يوم.
  - ساعتين.
  - وقت مخصص.
- `CommitmentNotificationsService` لحساب الجداول.
- Local Notifications datasource.
- FCM datasource.

### Milestone 5: الذكاء الاصطناعي

تم تنفيذ abstraction قابل للاستبدال:

- `AiRepository`.
- `AiRemoteDataSource`.
- `LocalAiDataSource` كافتراضي للـ MVP.
- `OpenAiDataSource` اختياري عبر Dio وOpenAI Chat Completions.
- Use cases:
  - `AnalyzeCommitments`.
  - `GenerateWeeklySummary`.
  - `GenerateMonthlySummary`.
- Providers:
  - `todayAiInsightsProvider`.
  - `weeklyAiSummaryProvider`.
  - `monthlyAiSummaryProvider`.

### Milestone 6: الإحصائيات

تم تنفيذ:

- `StatisticsSummary`.
- `statisticsSummaryProvider`.
- صفحة إحصائيات حقيقية محسوبة من الالتزامات:
  - عدد المهام.
  - عدد الوثائق.
  - الوثائق المنتهية.
  - الوثائق التي ستنتهي قريباً خلال 30 يوماً.
  - نسبة الالتزام.
  - المهام المنجزة.

### Milestone 7: الاختبارات وتحسين الأداء

تم تنفيذ اختبارات:

- Widget test لتشغيل التطبيق.
- Test لتحويل `CommitmentModel` من وإلى JSON.
- Test لخدمة جدولة الإشعارات.

التحقق النهائي في الدردشة:

```bash
dart format lib test
flutter analyze
flutter test
```

النتيجة:

- `flutter analyze`: لا توجد أخطاء.
- `flutter test`: كل الاختبارات نجحت.

## إعداد Firebase

لم تكن ملفات Firebase موجودة محلياً:

- `google-services.json`.
- `GoogleService-Info.plist`.
- `firebase_options.dart`.

كما أن FlutterFire CLI لم يكن مثبتاً محلياً.

لذلك تم تنفيذ bootstrap آمن:

- `FirebaseBootstrap.initialize()` يحاول تشغيل Firebase.
- عند غياب الإعدادات لا ينهار التطبيق.
- `UnavailableAuthRepository` يعرض خطأ واضحاً عند محاولة تسجيل الدخول بدون Firebase.
- التخزين المحلي عبر Hive يبقى عاملاً حتى قبل ربط Firebase.

## الملفات والمكونات الرئيسية المنفذة محلياً

أهم الملفات التي تم إنشاؤها أو تعديلها في المشروع المحلي:

```text
lib/main.dart
lib/core/firebase/firebase_bootstrap.dart
lib/app/app.dart
lib/app/router/app_router.dart
lib/app/theme/app_theme.dart
lib/app/localization/app_localizations.dart
lib/features/auth/**
lib/features/commitments/**
lib/features/home/**
lib/features/calendar/**
lib/features/notifications/**
lib/features/ai_assistant/**
lib/features/statistics/**
test/commitment_model_test.dart
test/notifications_service_test.dart
test/widget_test.dart
```

## القيود الحالية

- لم يتم رفع مشروع Flutter الكامل عبر Git المحلي لأن:
  - `gh` غير مثبت على الجهاز.
  - المجلد المحلي لم يكن Git repository.
  - اتصال `git ls-remote` إلى GitHub من shell فشل/انتهى بمهلة.
- تم استخدام GitHub connector بدلاً من ذلك لنقل محتوى الدردشة كوثيقة داخل المستودع.
- رفع المشروع الكامل يحتاج إما:
  - تثبيت GitHub CLI وتسجيل الدخول.
  - أو إتاحة اتصال Git من shell.
  - أو رفع الملفات عبر connector على دفعات لاحقة.

## الخطوة التالية المقترحة

لدمج المشروع الكامل كمصدر Flutter داخل هذا المستودع:

1. تثبيت GitHub CLI:

```bash
gh auth login
```

2. داخل مجلد المشروع المحلي:

```bash
git init
git remote add origin https://github.com/shary17454/my-codex.git
git checkout -b codex/life-assistant-mvp
git add .
git commit -m "Add Life Assistant Flutter MVP"
git push -u origin codex/life-assistant-mvp
```

3. فتح Pull Request إلى `main`.

## حالة الفرع الحالي

تم إنشاء فرع:

```text
codex/life-assistant-mvp
```

الغرض منه: نقل ملخص الدردشة وخطة/تنفيذ MVP إلى المستودع للدمج والمراجعة.
