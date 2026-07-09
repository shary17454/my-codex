# Rafiq Al Khala API

واجهة API أولية لتطبيق **رفيق الدروب**. الهدف منها توفير طبقة Backend مستقلة يمكن ربط تطبيق iOS بها لاحقاً لخدمات الرحلات، المجتمع، الطقس، السلامة، وطلبات SOS.

## التشغيل المحلي

```sh
cd RafiqAlKhalaAPI
npm run dev
```

الخدمة تعمل افتراضياً على:

```text
http://127.0.0.1:8787
```

## الاختبار

```sh
npm test
```

## Endpoints

### OpenAPI

```http
GET /openapi.json
```

### Health

```http
GET /health
```

### الطقس

```http
GET /v1/weather?lat=24.7136&lon=46.6753
```

يعتمد على Open-Meteo حالياً، ويمكن لاحقاً استبداله بمزود مدفوع أو Apple WeatherKit.

### الأماكن

```http
GET /v1/places
GET /v1/places?region=الرياض
POST /v1/places
```

مثال إنشاء موقع جديد:

```json
{
  "name": "موقع تخييم",
  "region": "حائل",
  "coordinate": {
    "latitude": 27.5,
    "longitude": 41.7
  },
  "difficulty": "متوسط",
  "terrain": ["جبال", "حصى"],
  "familyFriendly": true,
  "requires4x4": true,
  "tags": ["تخييم", "تصوير"]
}
```

المواقع الجديدة تدخل بحالة `pending_review` حتى لا تظهر للمستخدمين قبل المراجعة.

### مخطط الرحلة الذكي

```http
POST /v1/trips/plans
```

مثال:

```json
{
  "peopleCount": 4,
  "durationHours": 10,
  "vehicleType": "دفع رباعي",
  "budgetSar": 600,
  "preferences": {
    "tags": ["تطعيس", "غروب"]
  },
  "temperature": 44,
  "windSpeed": 50,
  "networkGapKm": 60
}
```

يرجع خطة مبدئية تشمل الوجهة، التوقفات، كمية الماء، الوقود التقديري، والتنبيهات.

### تسجيل الرحلات

```http
POST /v1/trips/records
```

### تنبيهات السلامة

```http
GET /v1/safety/alerts?temperature=44&windSpeed=50&airQualityIndex=160&rainRisk=true&networkGapKm=60
```

### SOS

```http
POST /v1/sos
```

مثال:

```json
{
  "coordinate": {
    "latitude": 24.7136,
    "longitude": 46.6753
  },
  "batteryPercent": 37,
  "heading": 280,
  "message": "أحتاج مساعدة",
  "contactIds": ["family-1"]
}
```

حالياً يتم حفظ الطلب في queue داخل الذاكرة. في الإنتاج يجب ربطه بقاعدة بيانات وخدمة رسائل مسموحة.

### دليل الحياة الفطرية

```http
GET /v1/nature/wildlife
```

### مناطق الخرائط بدون اتصال

```http
GET /v1/offline-map-regions
```

## ملاحظات الإنتاج

- التخزين الحالي داخل الذاكرة فقط للتطوير. الإنتاج يحتاج PostgreSQL أو CloudKit Server أو Firebase/Supabase.
- يمكن تفعيل حماية أولية للكتابة بوضع `RAFIQ_API_TOKEN`، ثم إرسال `Authorization: Bearer <token>` مع طلبات `POST`.
- إرسال SOS عبر SMS تلقائياً مقيّد في iOS. الأفضل تجهيز الرسالة وفتح واجهة الإرسال للمستخدم أو استخدام إشعارات/رسائل عبر Backend بموافقة مسبقة.
- الذكاء الاصطناعي الحالي Rule-Based. يمكن لاحقاً ربطه بخدمة AI وتحليل صور.
- الخرائط التجارية تحتاج ترخيصاً واضحاً قبل التخزين أو إعادة النشر.
