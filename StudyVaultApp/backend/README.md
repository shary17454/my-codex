# Backend وش الرأي

خادم تطوير محلي بلا تبعيات خارجية. يستخدم Node.js وملف JSON لتجربة عقد الشبكة قبل توفير PostgreSQL ومصادقة الإنتاج.

## ما ينفذه

- مقارنات عامة وغرف خاصة بالرابط أو رمز الدعوة.
- إخفاء النتائج والأسباب حتى يصوّت العميل عند تفعيل السياسة.
- منع صوت ثانٍ للعميل نفسه داخل المقارنة.
- تجزئة `X-Client-ID` بـSHA-256 وعدم تخزين قيمته الأصلية.
- أسباب حتى 300 حرف وتعليقات حتى 800 حرف.
- أحداث تصويت زمنية مجهّلة للمخطط.
- Rate limiting وسجل تدقيق محلي محدود.
- كتابة JSON ذرية وتسلسل عمليات الكتابة لتجنب فقدان التحديثات المتزامنة.
- فشل مبكر عند فساد ملف البيانات بدل استبداله بمتجر فارغ.
- endpoints ذكية محلية للبحث والتلخيص والاقتراحات داخل المقارنات العامة دون تخزين محادثات AI أو استخدام مفاتيح خارجية.

`X-Client-ID` مناسب لمنع التكرار العرضي في التطوير فقط. لا يثبت هوية الشخص ويمكن تغييره؛ الإنتاج يجب أن يستخرج المستخدم من جلسة موثقة بعد التحقق من Sign in with Apple.

## التشغيل

يتطلب Node.js 20 أو أحدث، ولا يحتاج `npm install` لعدم وجود dependencies.

```sh
cd StudyVaultApp/backend
npm run check
PORT=8787 WESH_ALRAY_DATA_FILE=/tmp/wesh-alray-store.json npm run dev
```

في Terminal ثانٍ:

```sh
cd StudyVaultApp/backend
BASE_URL=http://localhost:8787 npm run smoke
```

Smoke Test يتحقق من الغرفة العامة والخاصة، منع تسرب الخاصة إلى البحث، إخفاء النتائج، كشفها بعد التصويت، منع التكرار، طول السبب، ومخطط الأصوات.

## المتغيرات

| الاسم | الغرض | الحساسية | الافتراضي |
|---|---|---:|---|
| `PORT` | منفذ HTTP | لا | `8787` |
| `WESH_ALRAY_DATA_FILE` | ملف JSON للتطوير | لا | `data/store.json` |
| `CORS_ORIGIN` | Origin مسموح | لا | `*` في التطوير فقط |
| `RATE_LIMIT_WINDOW_MS` | نافذة تحديد المعدل | لا | `60000` |
| `RATE_LIMIT_MAX` | الطلبات لكل عنوان/نافذة | لا | `120` |
| `WESH_ALRAY_API_TOKEN` | حماية مشتركة لكتابة التطوير | نعم | فارغ |
| `WESH_ALRAY_BLOCKED_CLIENT_HASHES` | SHA-256 hashes مفصولة بفواصل | لا | فارغ |
| `AI_PROVIDER` | مزود AI المستقبلي؛ النسخة الحالية تستخدم `local` فقط | لا | `local` |
| `AI_REQUEST_TIMEOUT_MS` | مهلة مزود AI عند ربط خدمة خارجية مستقبلًا | لا | `12000` |
| `AI_MAX_CONTEXT_ITEMS` | أقصى عدد عناصر سياق ترسل للتحليل | لا | `50` |
| `OPENAI_API_KEY` | مفتاح مزود خارجي مستقبلي إن تم تفعيله عبر Backend فقط | نعم | غير مستخدم حاليًا |

عند `NODE_ENV=production` يرفض الخادم البدء إذا غاب `WESH_ALRAY_API_TOKEN` أو بقي `CORS_ORIGIN=*`. هذا حاجز أمان فقط ولا يحول التخزين الملفي إلى Backend إنتاجي.

## AI MVP

المسارات الحالية:

```http
POST /api/v1/ai/chat
POST /api/v1/ai/search
POST /api/v1/ai/summarize
POST /api/v1/ai/suggestions
```

النسخة الحالية لا تستخدم مزود AI خارجي ولا تحتاج API key. تعتمد على سياق المقارنات العامة فقط، وتعيد إجابات إرشادية ومصادر مختصرة. لا تُخزن المحادثات. الغرف الخاصة لا تُلخص إلا مع صلاحية الوصول نفسها المستخدمة في باقي API.

عند ربط OpenAI أو أي مزود آخر لاحقًا:

1. ضع المفتاح في Secret/Environment فقط، مثل `OPENAI_API_KEY`.
2. لا ترسل `clientHash` أو رموز الدعوة أو أسرار التشغيل للمزود.
3. قلل السياق إلى العنوان والخيارات والأسباب العامة المطلوبة للإجابة.
4. أضف timeout، اختبارات فشل المزود، وتحديثًا لسياسة الخصوصية وApp Store Privacy.

## Docker

```sh
cd StudyVaultApp/backend
docker build -t wesh-alray-backend .
docker run --rm -p 8787:8787 \
  -e WESH_ALRAY_API_TOKEN=development-only \
  -e CORS_ORIGIN=https://example.invalid \
  wesh-alray-backend
```

## الانتقال إلى الإنتاج

1. طبّق `sql/001_initial_schema.sql` ثم `sql/002_decision_rooms.sql` على PostgreSQL مع نسخ احتياطية ومستخدم قاعدة محدود الصلاحية.
2. استبدل التخزين الملفي بطبقة معاملات PostgreSQL؛ لا تنشر `server.mjs` الحالي كخادم اجتماعي عام.
3. تحقق على الخادم من identity token الخاص بـSign in with Apple: التوقيع، issuer، audience، expiry، nonce، ثم أنشئ جلسة قصيرة العمر.
4. اربط الصوت بـ`user_id` المستخرج من الجلسة، وليس بمعرّف يرسله التطبيق.
5. وفر HTTPS، secrets manager، مراقبة، نسخًا احتياطية، وسياسات حذف/احتفاظ وإشراف.
6. اختبر الاستعادة، التزامن، الحظر، الإبلاغ، APNs، وسياسة الخصوصية في بيئة staging قبل ربط نسخة App Store.

راجع `../docs/BACKEND_API.md` للعقد الحالي و`../docs/DECISION_PLATFORM_GATES.md` للمتطلبات الخارجية.
