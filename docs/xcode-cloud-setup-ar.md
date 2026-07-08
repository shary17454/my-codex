# إعداد Xcode Cloud لتطبيق بطل الدروب

## الحالة الحالية

- المشروع: `ios/BatalAlDroob/BatalAlDroob.xcodeproj`
- الـ Scheme: `BatalAlDroob`
- Bundle ID: `com.batalaldroob.parts`
- Version: `1.0`
- Build: `30`
- Signing: `Automatic`
- Team ID: `4HM66AD594`
- Deployment Target: `iOS 15.0`

## إعداد Workflow المقترح

استخدم هذه القيم عند إنشاء Workflow في Xcode Cloud:

- Repository: `shary17454/my-codex`
- Branch: `main`
- Project: `ios/BatalAlDroob/BatalAlDroob.xcodeproj`
- Scheme: `BatalAlDroob`
- Action: `Archive`
- Destination: `Any iOS Device`
- Xcode Version: `Latest Release` أو `Latest Stable`
- Start Condition: `Manual Start` لأول تشغيل
- Signing: `Automatic`
- Distribution: `TestFlight / App Store Connect`

## ملاحظات مهمة

- تم إنشاء Shared Scheme حتى يستطيع Xcode Cloud رؤية `BatalAlDroob`.
- تم ربط `CFBundleShortVersionString` و `CFBundleVersion` بقيم Build Settings.
- تم توسيع `.gitignore` لمنع أرشيفات Xcode وملفات IPA و dSYM من الدخول لاحقًا في Git.
- لا تستخدم Xcode Beta في Xcode Cloud إلا إذا كان التطبيق يحتاج SDK غير متوفر في Xcode stable.
