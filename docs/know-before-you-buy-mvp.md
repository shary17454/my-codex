# اعرف قبل تشتري

هذا المستند يلخص محتوى مشروع Flutter MVP الذي تم نقله ودمجه في هذا المستودع.

## الهدف

تطبيق Flutter باسم "اعرف قبل تشتري" يساعد المستخدم على تصوير منتج ثم استخراج اسمه وتحليل قرار الشراء.

## ما تم بناؤه

- Clean Architecture مع Feature First Structure.
- Riverpod لإدارة الحالة.
- GoRouter للتنقل.
- Firebase Auth جاهز للربط عند إضافة ملفات Firebase.
- Camera لالتقاط صورة المنتج.
- Google ML Kit OCR لاستخراج النص من الصورة.
- Open Food Facts كمصدر بيانات عام وموثوق للمنتجات الغذائية.
- OpenAI data source قابل للاستبدال عبر `OPENAI_API_KEY`.
- Hive للتخزين المحلي.
- واجهات عربية/إنجليزية مع دعم الوضع الليلي.

## مكان المشروع

مشروع Flutter الجديد مدمج في جذر المستودع الحالي، وتشمل أهم الملفات:

- `lib/main.dart`
- `lib/app/`
- `lib/core/`
- `lib/features/`
- `pubspec.yaml`

## ملاحظات تشغيل

للتشغيل المحلي:

```powershell
C:\src\flutter\bin\flutter.bat run
```

لبناء نسخة Web:

```powershell
C:\src\flutter\bin\flutter.bat build web --release
```

لتفعيل OpenAI:

```powershell
C:\src\flutter\bin\flutter.bat run --dart-define=OPENAI_API_KEY=YOUR_KEY
```

## ملاحظات Firebase

تسجيل الدخول الحقيقي يحتاج إضافة ملفات Firebase:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

بدون هذه الملفات يعمل وضع `MVP Preview` للمعاينة.
