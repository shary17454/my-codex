# Wesh Alray Development Backend API

Base URL الافتراضي: `http://localhost:8787`.

طلبات الكتابة تستخدم `Authorization: Bearer <token>` إذا ضُبط `WESH_ALRAY_API_TOKEN`. التصويت يتطلب `X-Client-ID`، لكن هذا معرّف تطوير وليس مصادقة إنتاجية.

## Health

```http
GET /health
```

## صفحات المشاركة العامة وUniversal Links

```http
GET /c/{comparisonID}
GET /comparisons/{comparisonID}
GET /.well-known/apple-app-site-association
```

صفحة `/c/{comparisonID}` تعرض صفحة HTML عامة للمقارنة وتحتوي:

- عنوان المقارنة ووصفها.
- الخيارات ونسب التصويت المسموح بعرضها.
- زر فتح التطبيق عبر `weshalray://comparison/{comparisonID}`.
- روابط مشاركة WhatsApp وX.
- وسوم Open Graph وTwitter Card أساسية.

الغرف الخاصة لا تظهر إلا مع رمز الدعوة:

```http
GET /c/{comparisonID}?invite=ABC123DEF4
```

إعدادات الإنتاج المطلوبة للروابط العامة:

```sh
WESH_ALRAY_PUBLIC_WEB_BASE_URL=https://example.com
APPLE_APP_SITE_APP_ID=TEAMID.com.shary17454.esal
```

لا يكتمل تفعيل Universal Links إلا بعد إضافة Associated Domain في Xcode/Apple Developer:

```text
applinks:example.com
```

ثم اختبار `https://example.com/c/{comparisonID}` على جهاز حقيقي.

## المقارنات العامة

```http
GET /api/v1/comparisons?category=phones&q=iphone
GET /api/v1/comparisons/{comparisonID}
```

القائمة لا تعيد الغرف الخاصة. البحث يشمل العنوان والوصف والخيارات والوسوم بعد تطبيع العربية.

```http
POST /api/v1/comparisons
Content-Type: application/json
X-Client-ID: local-device-id
Authorization: Bearer <token>

{
  "title": "آيفون أم سامسونج؟",
  "details": "أهم شيء الكاميرا والبطارية",
  "category": "phones",
  "author": "ضيف",
  "isAnonymous": false,
  "allowsComments": true,
  "allowsVoteReasons": true,
  "visibility": "inviteCode",
  "hideResultsUntilVote": true,
  "expiresAt": "2026-08-01T12:00:00Z",
  "tags": ["جوالات"],
  "options": [
    { "title": "آيفون" },
    { "title": "سامسونج" }
  ]
}
```

قيم `visibility`: `publicRoom` أو`linkOnly` أو`inviteCode`. الغرفة غير العامة تعيد `inviteCode`.

## فتح غرفة خاصة

```http
GET /api/v1/rooms/{inviteCode}
X-Client-ID: local-device-id
```

أو للوصول المباشر بالمعرف:

```http
GET /api/v1/comparisons/{comparisonID}
X-Invite-Code: ABC123DEF4
X-Client-ID: local-device-id
```

## التصويت

```http
POST /api/v1/comparisons/{comparisonID}/votes
Content-Type: application/json
X-Client-ID: local-device-id
X-Invite-Code: ABC123DEF4
Authorization: Bearer <token>

{
  "optionID": "option-uuid",
  "author": "ضيف",
  "reason": "الكاميرا أفضل",
  "reasonCategory": "الكاميرا",
  "isVerifiedExperience": true,
  "isAnonymous": false
}
```

يرد الخادم بـ`409` للصوت المكرر أو المقارنة المنتهية، و`400` إذا تجاوز السبب 300 حرف. `voteTrend` يحتوي وقت التصويت والخيار فقط ولا يحتوي هوية العميل.

## التعليقات والبلاغات

```http
POST /api/v1/comparisons/{comparisonID}/comments
Content-Type: application/json
X-Invite-Code: ABC123DEF4
Authorization: Bearer <token>

{ "author": "ضيف", "text": "أحتاج تجارب أكثر عن الضمان" }
```

```http
POST /api/v1/reports
Content-Type: application/json
Authorization: Bearer <token>

{
  "contentID": "uuid",
  "contentType": "comparison",
  "reason": "misleading",
  "details": "المعلومة غير دقيقة"
}
```

مراجعة البلاغات تستخدم نفس حماية `WESH_ALRAY_API_TOKEN` في بيئة الإنتاج:

```http
GET /api/v1/reports?status=open
Authorization: Bearer <token>
```

```http
PATCH /api/v1/reports/{reportID}
Content-Type: application/json
Authorization: Bearer <token>

{
  "status": "resolved",
  "reviewNote": "تمت مراجعة البلاغ"
}
```

الحالات المسموحة: `open`، `reviewing`، `resolved`، `dismissed`.

## AI MVP

المسارات التالية تستخدم سياق المقارنات المسموح للعميل رؤيتها، ولا تخزن المحادثات:

```http
POST /api/v1/ai/chat
Content-Type: application/json
X-Client-ID: local-device-id
Authorization: Bearer <token>

{ "prompt": "لخص مقارنة الكاميرا" }
```

```http
POST /api/v1/ai/search
Content-Type: application/json

{ "query": "السعر والكاميرا" }
```

```http
POST /api/v1/ai/summarize
Content-Type: application/json
X-Invite-Code: ABC123DEF4

{ "comparisonID": "uuid" }
```

```http
POST /api/v1/ai/suggestions
Content-Type: application/json

{}
```

```http
POST /api/v1/ai/camera-draft
Content-Type: application/json
Authorization: Bearer <token>

{
  "recognizedText": ["iPhone 15 Pro", "camera", "battery"],
  "fallbackTitle": "آيفون أم بديل؟",
  "fallbackCategory": "phones"
}
```

يرجع مسار الكاميرا عنوانًا وخيارات ومعايير مقترحة من النص المستخرج على الجهاز. لا يستقبل صورة خامًا ولا يحتاج رفع ملفات.

الاستجابات تحمل إجابات إرشادية ومصادر مختصرة. عند ضبط `AI_PROVIDER=openai` و`OPENAI_API_KEY` في بيئة الخادم يستخدم الباكند OpenAI Responses API لمسارات `chat` و`summarize` و`camera-draft`، وتعود الاستجابة بالحقل:

```json
{ "provider": "openai" }
```

إذا لم يتوفر المفتاح أو فشل المزود يعود الخادم تلقائيًا إلى التحليل المحلي:

```json
{ "provider": "local" }
```

مسار `summarize` يرجع دائمًا `summary` المنظم، وقد يرجع `aiSummary` كنص ذكي عند نجاح المزود الخارجي. لا يوجد مفتاح داخل التطبيق أو الكود، ولا تُرفع الصور الخام إلى الخادم.

## الإشعارات

يسجل التطبيق الجهاز لدى الباكند عند موافقة المستخدم على الإشعارات:

```http
POST /api/v1/devices
Content-Type: application/json
X-Client-ID: local-device-id
Authorization: Bearer <token>

{
  "platform": "ios",
  "pushToken": "apns-device-token-or-null",
  "notificationsEnabled": true
}
```

متابعة مقارنة لتنبيهات التصويت وتغير المتصدر وقرب الانتهاء:

```http
POST /api/v1/comparisons/{comparisonID}/follow
Content-Type: application/json
X-Client-ID: local-device-id
Authorization: Bearer <token>
```

قراءة صندوق الإشعارات:

```http
GET /api/v1/notifications
X-Client-ID: local-device-id
Authorization: Bearer <token>
```

للاختبارات أو لوحة التشغيل يمكن تضمين المجدول:

```http
GET /api/v1/notifications?includeScheduled=1
```

إرسال التنبيهات المستحقة عبر APNs من مهمة مجدولة أو worker:

```http
POST /api/v1/notifications/dispatch
Authorization: Bearer <token>
```

يتطلب الإرسال الفعلي عبر APNs ضبط الأسرار التالية في بيئة الخادم فقط:

- `APNS_ENV`: `sandbox` أو `production`.
- `APNS_KEY_ID`.
- `APNS_TEAM_ID`.
- `APNS_BUNDLE_ID`.
- `APNS_PRIVATE_KEY_BASE64`.

إذا لم تُضبط أسرار APNs، يرجع المسار `configured: false` ولا يحاول الاتصال بـApple. يجب كذلك تفعيل Push Notifications في Apple Developer وإضافة entitlement المناسب قبل اختبار Push على جهاز فعلي.

## الإدارة والتشغيل

تستخدم مسارات الإدارة `Authorization: Bearer <token>` ولا ترجع أسرارًا أو push tokens.

نظرة تشغيلية:

```http
GET /api/v1/admin/overview
Authorization: Bearer <token>
```

مقاييس مبسطة للأداء والنشاط:

```http
GET /api/v1/admin/metrics
Authorization: Bearer <token>
```

حظر عميل مسيء بمعرّف العميل الخام. يخزن الخادم hash فقط:

```http
POST /api/v1/admin/blocked-clients
Content-Type: application/json
Authorization: Bearer <token>

{
  "clientID": "client-id-from-abuse-investigation",
  "reason": "spam"
}
```

إنشاء نسخة احتياطية JSON في `WESH_ALRAY_BACKUP_DIR`:

```http
POST /api/v1/admin/backups
Authorization: Bearer <token>
```

هذه الإدارة مناسبة للتطوير وبيئة staging. الإنتاج الحقيقي يحتاج PostgreSQL، صلاحيات إدارية منفصلة، سجل تدقيق دائم، ونسخ احتياطية مدارة خارج الخادم.

## وش الرأي Plus

حساب المالك يفتح مزايا Plus داخل التطبيق دون اشتراك. تفعيل البيع للمستخدمين يتطلب إنشاء منتجات App Store Connect التالية وربط StoreKit 2 قبل الإرسال:

- `com.shary17454.esal.plus.monthly`
- `com.shary17454.esal.plus.yearly`

لا توجد مفاتيح شراء أو أسعار داخل الكود.

## حدود الإنتاج

هذا العقد مختبر محليًا، لكن هوية الإنتاج غير منفذة. قبل النشر العام يجب استخدام PostgreSQL ومعاملات، والتحقق الخادمي من Sign in with Apple، وجلسات آمنة، وAPNs، وإشراف ونسخ احتياطية. لا يوضع API token مشترك داخل نسخة App Store.
