# مشروع كتيب مرزوق بن حويد بن وازع العضياني رحمه الله

هذا المجلد ينقل مخرجات محادثة Codex الخاصة بإنشاء كتيب عربي عن **مرزوق بن حويد بن وازع العضياني رحمه الله** إلى مستودع GitHub.

## ما تم إنجازه

- تأليف كتيب عربي بصيغة PDF على هيئة كتاب.
- إضافة غلاف، مقدمة، فهرس، وصورة المرحوم.
- تقسيم الكتيب إلى أبواب: إهداء، المقدمة، ما ثبت في المصادر، مولده ونشأته، أشعاره، مناقبه، قصص ومواقف، وفاته، الخاتمة، وصفحات للتوثيق.
- تحويل الكتيب إلى نسخة Word قابلة للتعديل.
- تحسين الصورة الأصلية محلياً مع الحفاظ على ملامحها ومحتواها.
- إضافة تصميم فخم: غلاف ذهبي/عاجي، إطارات زخرفية، وترويسات داخلية.
- إصلاح خطأ تداخل تذييل الصفحات مع الزخرفة السفلية.

## الملفات داخل هذا المجلد

- [chat-log.md](chat-log.md): سجل منظم لمحتوى المحادثة ومراحل العمل.
- [full-chat-transcript.md](full-chat-transcript.md): أرشيف أوسع للمحادثة وطلبات المستخدم والنتائج.
- [artifacts.md](artifacts.md): روابط ملفات PDF وWord والصورة النهائية.
- [requirements.txt](requirements.txt): حزم Python المطلوبة لإعادة التوليد.

## التحميل المباشر

- [نسخة PDF النهائية](../../artifacts/marzouq-book/marzouq_bin_huwaid_al_odhayani_book.pdf)
- [نسخة Word قابلة للتعديل](../../artifacts/marzouq-book/marzouq_bin_huwaid_al_odhayani_book_editable.docx)
- [الصورة المحسنة](../../artifacts/marzouq-book/marzouq_photo_enhanced.jpg)

## إعادة البناء

لإعادة توليد PDF وWord محلياً، يلزم Python والحزم الموجودة في [requirements.txt](requirements.txt)، كما يلزم خط Tahoma على Windows أو تعديل مسار الخطوط في السكربت.

```powershell
pip install -r docs/marzouq-book/requirements.txt
python create_marzouq_pdf.py
python create_marzouq_docx.py
```
