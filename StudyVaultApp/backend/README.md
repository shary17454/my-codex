# Backend وش الرأي

Backend تطوير محلي لتطبيق وش الرأي بدون تبعيات خارجية. يستخدم Node.js المدمج وملف JSON محلي للتخزين.

## التشغيل

```sh
cd StudyVaultApp
PORT=8787 node backend/server.mjs
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
BASE_URL=http://localhost:8787 node backend/tests/smoke.mjs
```

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
- لا تضع مفاتيح أو أسرار داخل تطبيق iOS.
