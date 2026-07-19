# تقرير هجرة وجاهزية Native iOS لتطبيق وش الرأي

تاريخ التقرير: 2026-07-18

## 1. Discovery & Fixes

- تم تحديد نطاق وش الرأي في `StudyVaultApp/` فقط.
- تم التأكد أن مشروع وش الرأي الحالي Native iOS وليس Flutter:
  - المشروع: `StudyVault.xcodeproj`
  - Scheme: `StudyVault`
  - Swift version: `6.0`
  - UI: SwiftUI
  - Architecture: MVVM تدريجي عبر `HomeViewModel` و`CreateComparisonViewModel`
- لا توجد ملفات `.dart` أو `pubspec.yaml` أو مجلد Flutter runtime داخل نطاق التطبيق النشط، مع استثناء أرشيفات مستندات قديمة داخل `StudyVault/Resources/StudyFiles` لأنها ليست runtime ولا تدخل في مشروع Xcode.
- تم فصل تعليمات وش الرأي عن بطل الدروب بتحديث `AGENTS.md` وإضافة `StudyVaultApp/AGENTS.md`.
- تم إضافة سكربت Preflight باسم `StudyVaultApp/scripts/validate_wesh_alray_scope.sh` للتحقق من:
  - عدم وجود Flutter/Dart runtime داخل نطاق وش الرأي.
  - عدم وجود مرجع `BatalAlDroob` داخل مشروع Xcode الخاص بوش الرأي.
  - ثبات اسم العرض `وش الرأي`.
  - ثبات Bundle ID الحالي.
  - ضبط Swift 6.
- تم إضافة فحص بيانات باسم `StudyVaultApp/scripts/validate_wesh_alray_data.py` للتحقق من JSON، إعدادات Info.plist، وإعدادات Xcode الأساسية.
- تمت إزالة مفاتيح Live Activities من `Info.plist` لأنها لم تكن مدعومة بتنفيذ ActivityKit فعلي داخل وش الرأي.

## 2. File Manifest

ملفات Swift الأساسية الحالية:

- `StudyVault/StudyVaultApp.swift`: نقطة دخول التطبيق.
- `StudyVault/ContentView.swift`: الواجهة الرئيسية وتدفقات الصفحة الرئيسية، الإنشاء، التفاصيل، الحساب، المشاركة، QR، والبلاغات.
- `StudyVault/AskModels.swift`: نماذج المقارنات، التصنيفات، التصويت، التعليقات، الملخصات، التفضيلات، والبلاغات.
- `StudyVault/ViewModels.swift`: ViewModels، البحث، الحفظ المحلي، إعدادات Backend، عميل API، وKeychain token storage.

ملفات Backend التطوير:

- `backend/server.mjs`: REST API محلي للتطوير.
- `backend/tests/smoke.mjs`: smoke test للـAPI.
- `backend/sql/001_initial_schema.sql`: مخطط PostgreSQL مرجعي للإنتاج.

ملفات أضيفت/عدلت لهذا الفصل:

- `AGENTS.md`
- `StudyVaultApp/AGENTS.md`
- `StudyVaultApp/scripts/validate_wesh_alray_scope.sh`
- `StudyVaultApp/docs/NATIVE_IOS_MIGRATION_READINESS_REPORT.md`

## 3. Capabilities & Permissions Log

حسب `StudyVault/Info.plist` و`StudyVault/PrivacyInfo.xcprivacy`:

- URL Scheme:
  - `weshalray://comparison/{id}` للروابط العميقة المحلية.
- Live Activities:
  - غير مفعلة حاليًا في `Info.plist`.
  - يجب إعادة تفعيلها فقط عند إضافة تنفيذ ActivityKit وTarget/Capability مناسبين.
- Permissions:
  - لا توجد UsageDescriptions لكاميرا أو صور أو موقع أو ميكروفون في `Info.plist`.
- Privacy Manifest:
  - `NSPrivacyTracking = false`
  - لا توجد بيانات معلنة كمجمعة داخل `NSPrivacyCollectedDataTypes`.
  - لا توجد Required Reason APIs معلنة حاليًا.

## 4. Xcode & Scheme Configurations

- Xcode project: `StudyVault.xcodeproj`
- Scheme: `StudyVault`
- Target: `StudyVault`
- Bundle ID: `com.shary17454.esal`
- Marketing Version: `1.10.0`
- Build Number: `52`
- Deployment Target: iOS `17.0`
- Swift Version: `6.0`
- Signing: Automatic، دون تغيير ضمن هذا العمل.
- `Info.plist` يستخدم:
  - `CFBundleShortVersionString = $(MARKETING_VERSION)`
  - `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`

## 5. Services Configured

- لا توجد SDKs خارجية مطلوبة داخل تطبيق iOS الحالي.
- Backend التطوير موجود داخل `backend/` باستخدام Node.js بدون تبعيات خارجية.
- التطبيق يدعم ربط Backend اختياري من تبويب الحساب:
  - Base URL
  - API token اختياري محفوظ في Keychain
- الإنتاج يحتاج استبدال API token المشترك بمصادقة مستخدمين حقيقية على الخادم قبل الاعتماد العام.

## 6. Verification Gate

أوامر التحقق المطلوبة:

```sh
StudyVaultApp/scripts/validate_wesh_alray_scope.sh
python3 StudyVaultApp/scripts/validate_wesh_alray_data.py
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/StudyVaultDerivedData build
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/StudyVaultReleaseDerivedData build
cd StudyVaultApp/backend && npm run check
```

Smoke test للـBackend يتطلب تشغيل الخادم المحلي:

```sh
cd StudyVaultApp/backend
PORT=8787 npm run dev
BASE_URL=http://localhost:8787 npm run smoke
```

## 7. Manual Actions Required

قبل وصف التطبيق بأنه إنتاجي بالكامل:

1. استضافة Backend إنتاجي وربطه بقاعدة بيانات دائمة.
2. تنفيذ مصادقة مستخدمين حقيقية بدل رمز API مشترك.
3. التحقق اليدوي من App Store Privacy Labels داخل App Store Connect.
4. اختبار Push Notifications/Universal Links/Live Activities فقط إذا تم تفعيلها فعليًا.
5. اختبار VoiceOver وDynamic Type يدويًا على أجهزة فعلية أو Simulator مناسب.
6. إنشاء Archive موقّع من Xcode/Xcode Cloud عند طلب الرفع.

## 8. Release Assessment

الحالة الحالية بعد الفصل: `READY_WITH_EXTERNAL_REQUIREMENTS`

السبب:

- كود وش الرأي Native وقابل للبناء محليًا.
- تم فصل نطاقه عن بطل الدروب بسكربت وتعليمات واضحة.
- لا يوجد Flutter runtime داخل نطاق التطبيق النشط.
- لا تزال الجاهزية الإنتاجية الكاملة مرتبطة باستضافة Backend ومصادقة إنتاجية وفحوص App Store اليدوية.
