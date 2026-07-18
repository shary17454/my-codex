# Backend وش الرأي

Backend تطوير محلي لتطبيق وش الرأي بدون تبعيات خارجية. يستخدم Node.js المدمج وملف JSON محلي للتخزين.

## التشغيل

```sh
cd StudyVaultApp/backend
npm run check
PORT=8787 npm run dev
```

## الفحص

```sh
curl http://localhost:8787/health
```

## المتغيرات

| الاسم | الوصف | القيمة الافتراضية |
|---|---|---|
| `PORT` | منفذ الخادم المحلي | `8787` |
| `WESH_ALRAY_DATA_FILE` | ملف تخزين JSON المحلي | `backend/data/store.json` |
| `CORS_ORIGIN` | النطاق المسموح للطلبات | `*` |
| `RATE_LIMIT_WINDOW_MS` | نافذة تحديد المعدل | `60000` |
| `RATE_LIMIT_MAX` | أعلى عدد طلبات في النافذة | `120` |
| `WESH_ALRAY_API_TOKEN` | توكن اختياري لحماية عمليات الكتابة | فارغ |

## Smoke Test

بعد تشغيل الخادم:

```sh
BASE_URL=http://localhost:8787 npm run smoke
```

إذا تم ضبط `WESH_ALRAY_API_TOKEN` على الخادم، مرر الرمز نفسه للاختبار:

```sh
BASE_URL=http://localhost:8787 WESH_ALRAY_API_TOKEN=change-this npm run smoke
```

## الربط من تطبيق iOS

من تبويب الحساب داخل التطبيق:

1. فعّل "المزامنة مع الخادم".
2. أدخل رابط الخادم، مثل `http://localhost:8787`.
3. أدخل `API token` فقط إذا كان الخادم يعمل بمتغير `WESH_ALRAY_API_TOKEN`. يحفظ التطبيق هذا الرمز في Keychain.
4. اضغط "حفظ الإعداد"، ثم "مزامنة".

## Docker

```sh
cd StudyVaultApp/backend
docker build -t wesh-alray-backend .
docker run --rm -p 8787:8787 -e WESH_ALRAY_API_TOKEN=change-this wesh-alray-backend
```

## ملاحظات إنتاج

- هذا الخادم مناسب للتطوير والاختبار فقط.
- الإنتاج يحتاج قاعدة بيانات حقيقية مثل PostgreSQL أو Firestore. تم توفير مخطط PostgreSQL في `sql/001_initial_schema.sql`.
- منع التلاعب الحقيقي يحتاج مصادقة خادم وسياسة تصويت وربط كل صوت بمستخدم أو جهاز موثوق.
- لا تستخدم `WESH_ALRAY_API_TOKEN` كسر إنتاج داخل نسخة App Store؛ الرمز الثابت مناسب للتطوير أو اختبار داخلي فقط.
- الإنتاج يحتاج مصادقة مستخدمين حقيقية وجلسات آمنة بدل رمز كتابة مشترك داخل التطبيق.
