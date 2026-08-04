# رواية (Rawaya)

منصة رقمية عربية لحفظ وصون التراث العربي والبدوي.

## المتطلبات
- Node.js 20+
- PostgreSQL
- Redis
- Flutter 3.4+

## التشغيل السريع
```bash
npm install
cp .env.example .env
npm run docker:dev
```

## تشغيل الخدمات
- API: `http://localhost:4000/api`
- واجهة الويب: `http://localhost:3001`
- لوحة الإدارة: `http://localhost:3002`
- Swagger: `http://localhost:4000/api/docs`

## المتغيرات
- `DATABASE_URL`
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `REDIS_URL`

## حسابات Seed
- admin@rawaya.test
- editor@rawaya.test
- user@rawaya.test

> ملاحظة: كلمات المرور في seed أولية placeholder، يجب استبدالها.

## أوامر مفيدة
- `npm run dev`
- `npm run build`
- `npm run test`
- `npm run docker:prod`
- `cd apps/mobile && flutter test`
- `cd apps/mobile && flutter build ios --release --no-codesign`

## GitHub و Xcode Cloud

المشروع مجهز للرفع داخل مستودع GitHub كمجلد مستقل باسم `rawayah/` حتى لا يتداخل مع مشاريع أخرى.

ملفات Xcode Cloud موجودة في:

- `apps/mobile/ios/ci_scripts/ci_post_clone.sh`
- `apps/mobile/ios/ci_scripts/ci_pre_xcodebuild.sh`

إعداد Xcode Cloud المقترح:

- Product: تطبيق Flutter iOS داخل `apps/mobile/ios/Runner.xcworkspace`
- Scheme: `Runner`
- Branch: `main`
- Workflow: تشغيل `ci_post_clone.sh` ثم بناء iOS Release
- Signing: عبر حساب Apple Developer في App Store Connect

## قواعد البيانات الأولية في MVP
- المستخدمون والصلاحيات
- الشعراء والقصائد
- القصص
- الكتب
- الخيل
- الإبل
- الصقور
- كلاب الصيد
- الأسئلة والتعليقات والمفضلة
- البحث والسجلات
