# Wesh Alray Backend API

Base URL للتطوير:

```text
http://localhost:8787
```

## Health

```http
GET /health
```

## المقارنات

```http
GET /api/v1/comparisons?category=phones&q=iphone
```

```http
GET /api/v1/comparisons/{comparisonID}
```

```http
POST /api/v1/comparisons
Content-Type: application/json

{
  "title": "آيفون أم سامسونج؟",
  "details": "أهم شيء الكاميرا والبطارية",
  "category": "phones",
  "author": "ضيف",
  "isAnonymous": false,
  "allowsComments": true,
  "allowsVoteReasons": true,
  "tags": ["جوالات"],
  "options": [
    { "title": "آيفون" },
    { "title": "سامسونج" }
  ]
}
```

## التصويت

```http
POST /api/v1/comparisons/{comparisonID}/votes
Content-Type: application/json
X-Client-ID: local-device-id

{
  "optionID": "option-uuid",
  "author": "ضيف",
  "reason": "الكاميرا أفضل",
  "reasonCategory": "الكاميرا أفضل",
  "isVerifiedExperience": true,
  "isAnonymous": false
}
```

## التعليقات

```http
POST /api/v1/comparisons/{comparisonID}/comments
Content-Type: application/json

{
  "author": "ضيف",
  "text": "أحتاج تجارب أكثر عن الضمان"
}
```

## البلاغات

```http
POST /api/v1/reports
Content-Type: application/json

{
  "contentID": "uuid",
  "contentType": "comparison",
  "reason": "misleading",
  "details": "المعلومة غير دقيقة"
}
```

## متطلبات الإنتاج

- مصادقة Apple Sign In على الخادم.
- قاعدة بيانات دائمة.
- قيود Rate Limiting.
- سياسة منع تكرار التصويت.
- مراجعة وإشراف البلاغات.
- Push Notifications عبر APNs.
- Universal Links بملف `apple-app-site-association`.
