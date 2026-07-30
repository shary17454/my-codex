# Wesh Alray Development Backend API

Base URL الافتراضي: `http://localhost:8787`.

طلبات الكتابة تستخدم `Authorization: Bearer <token>` إذا ضُبط `WESH_ALRAY_API_TOKEN`. التصويت يتطلب `X-Client-ID`، لكن هذا معرّف تطوير وليس مصادقة إنتاجية.

## Health

```http
GET /health
```

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

الاستجابات تحمل إجابات إرشادية ومصادر مختصرة. لا يوجد مزود AI خارجي في النسخة الحالية، ولا يوجد مفتاح داخل التطبيق أو الكود. أي مزود خارجي مستقبلي يجب أن يمر عبر Backend فقط باستخدام Secret في بيئة التشغيل.

## حدود الإنتاج

هذا العقد مختبر محليًا، لكن هوية الإنتاج غير منفذة. قبل النشر العام يجب استخدام PostgreSQL ومعاملات، والتحقق الخادمي من Sign in with Apple، وجلسات آمنة، وAPNs، وإشراف ونسخ احتياطية. لا يوضع API token مشترك داخل نسخة App Store.
