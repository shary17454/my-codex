# تقرير تنظيف مستودع وش الرأي

تاريخ التنفيذ: 2026-07-22

## النطاق

- تم العمل داخل `StudyVaultApp/` فقط.
- لم يتم تعديل تطبيقات أو مشاريع شقيقة مثل `BatalAlDroob` أو `DesertTrail`.
- لم يتم تغيير Bundle ID أو التوقيع أو الصلاحيات أو إعدادات النشر.

## ما تم حذفه

تم حذف نسخ مكررة ومهملة أنشأها النظام أو iCloud/Finder بنمط الاسم ` 2` داخل نطاق التطبيق. هذه الملفات لم تكن مرجعية في:

- مشروع Xcode `StudyVault.xcodeproj`.
- سكربتات التحقق والبناء.
- مصادر Swift.
- بيانات التطبيق النشطة.
- إعدادات App Store النشطة.

الفئات التي أزيلت:

- نسخ مكررة من ملفات Swift الأساسية مثل `AskModels`, `ContentView`, و`StudyVaultApp`.
- نسخ مكررة من `Info.plist`, `PrivacyInfo.xcprivacy`, وملفات entitlements.
- نسخ مكررة من بيانات JSON النشطة.
- نسخ مكررة من سكربتات App Store والأيقونة.
- نسخ مكررة من لقطات الشاشة وملفات App Store metadata.
- نسخ مكررة من أرشيف `StudyFiles` القديم.
- مجلد `output/` غير المتتبع لأنه ناتج توليد محلي، وتمت إضافة `output/` إلى `.gitignore`.

## ملفات مشبوهة لم يتم حذفها

تم إبقاء العناصر التالية لأن الثقة في حذفها أقل من 100%:

- صور App Store المتطابقة بين مجلدات `iphone65`, `ipad13`, و`ipad13-jpg`.
  - السبب: قد تكون مطلوبة كأصول منفصلة لأحجام أجهزة مختلفة حتى لو كان محتواها متطابقًا.
- ملفات ExportOptions المتعددة:
  - `ExportOptions-AppStore.plist`
  - `ExportOptions-AppStore-Manual.plist`
  - `ExportOptions-AppStore-Export.plist`
  - `AppStore/ExportOptions-AppStore.plist`
  - `AppStore/export_options_app_store.plist`
  - `AppStore/export_options_app_store_upload.plist`
  - السبب: لكل ملف محتوى مختلف، وقد يستخدم بعضها في خطوات رفع يدوية أو سكربتات خارج المستودع.
- مجلد `StudyVault/Resources/StudyFiles` الأصلي.
  - السبب: موثق كأرشيف قديم غير داخل Xcode runtime، لكنه قد يكون مطلوبًا كمرجع تاريخي أو تسليمي.

## التحقق

تمت إعادة تشغيل فحوصات النطاق والبيانات والبناء بعد التنظيف:

- `StudyVaultApp/scripts/validate_wesh_alray_scope.sh`: نجح.
- `python3 StudyVaultApp/scripts/validate_wesh_alray_data.py`: نجح.
- `cd StudyVaultApp/backend && npm run check`: نجح.
- Debug build عبر `xcodebuild`: نجح.
- Release build عبر `xcodebuild`: نجح.
- `xcodebuild build-for-testing`: نجح.
- `git diff --check -- StudyVaultApp`: نجح.

اختبارات Simulator لم تكتمل بسبب خلل بيئي في CoreSimulatorService، وليس بسبب خطأ بناء في المشروع.

## النتيجة

تنظيف المستودع داخل `StudyVaultApp/` اكتمل بأصغر فرق آمن. تم حذف الملفات التي ثبت أنها نسخ مكررة غير مستخدمة، وتم الحفاظ على الملفات التي قد تدخل في النشر أو التوثيق أو أصول App Store.
