# بطل الدروب 2.8 — نصوص App Store Connect

`2.8 (214)` يتخطى `2.7`: كل ما في 2.7 موجود هنا، وفوقه تحسينات الأداء والترجمة. لا
تحتاج إطلاق 2.7 قبله.

> النصوص أدناه جاهزة للّصق كما هي. حد "وش الجديد" في App Store هو 4000 حرف، وكلا
> النصين تحته بكثير.

---

## What's New — العربية (`ar-SA`)

```
أسرع في البحث والتصفح

• البحث في الكتالوج صار أسرع بشكل ملموس: الكتابة لا تتقطع، والنتائج تظهر فورًا،
  والتمرير في القائمة سلس.
• الشاشة الرئيسية تفتح مباشرة بدون تعليق عند حساب أعداد الأقسام وبطاقات الأجيال.
• فتح الكتالوجات الأصلية لم يعد يجمّد الشاشة: يظهر مؤشر تحميل ويبقى بإمكانك الإغلاق
  في أي لحظة.

عشر لغات… مترجمة فعلًا

• شاشة الترحيب الأولى صارت تظهر بلغتك المختارة بدل الإنجليزية.
• أسماء الأقسام وشارات سبب النتيجة والمؤشرات الذكية ورسائل الطلب صارت مترجمة
  بالكامل للإسبانية والفرنسية والألمانية والروسية والبرتغالية والصينية والتركية
  والهندية.
• تصحيح اتجاه الأسهم في اللغات التي تُكتب من اليسار لليمين.

تفاصيل مفيدة

• سجل الصيانة صار يعرض تاريخ كل عملية، والطلبات المحفوظة تعرض تاريخها.

ملاحظة: أسماء القطع وأرقامها تبقى بالعربية والإنجليزية لأن الكتالوجات الأصلية
منشورة بهما، وأرقام OEM محايدة لغويًا.
```

---

## What's New — English (`en-US`)

```
Faster search and browsing

• Catalog search is noticeably faster: typing no longer stutters, results appear
  immediately, and the results list scrolls smoothly.
• The home screen opens straight away instead of pausing while it counts categories
  and generation records.
• Opening an original catalog no longer freezes the screen. A loading indicator
  appears and you can close the reader at any moment.

Ten languages, actually translated

• The first-run welcome screen now appears in the language you picked instead of
  English.
• Category names, search reason badges, smart indicators, and part-request messages
  are now fully translated into Spanish, French, German, Russian, Portuguese,
  Simplified Chinese, Turkish, and Hindi.
• Fixed chevrons that pointed the wrong way in left-to-right languages.

Useful details

• The maintenance log now shows the date of each entry, and saved part requests show
  when they were created.

Note: part names and numbers stay Arabic/English because the source catalogs are
published that way, and OEM numbers are language-neutral.
```

---

## ملاحظات للمراجع (App Review Notes)

اختياري — أضفها فقط إذا رجع سؤال من المراجعة.

```
This version contains no new feature surface, no new permission, and no new data
collection compared to 2.7. It is a performance, correctness, and localization pass:
search and dashboard work that was repeated many times per screen refresh is now
computed once, catalog PDFs are parsed off the main thread, and the eight non-Arabic
interface languages declared in CFBundleLocalizations are now translated across the
static interface, including the first-run screen.

Sign-in: the app requires a valid email on first run. This is a local, on-device
profile used to personalise request preparation. It is not backend authentication and
it never leaves the device.

Original catalog PDFs are delivered through Apple-hosted managed Background Assets and
require iOS 26 or later. Indexed catalog search works on iOS 17 and later.
```

---

## قائمة تحقق قبل التقديم

- [ ] اختر البناء `2.8 (214)` في صفحة الإصدار
- [ ] الصق "وش الجديد" بالعربية والإنجليزية أعلاه
- [ ] **Promotional Text فارغ** — ثغرة معروفة من 2.7، عبّئها أو اتركها بوعي
- [ ] **لقطات الشاشة** ما زالت لقطات 2.6 ولا تُظهر ميزات 2.7/2.8
- [ ] أرفق منتجات الشراء داخل التطبيق إن كانت تحتاج مراجعة
- [ ] راجع إجابات الخصوصية (التطبيق لا يجمع بيانات ولا يتتبع)
- [ ] إعداد الإطلاق: "Manually release" حاليًا — قرر إن كنت تبيه تلقائيًا
