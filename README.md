# Safari Y60 Parts iPhone App

تطبيق iPhone بسيط لإدارة قطع `Nissan Patrol Safari Y60` مبني بـ `SwiftUI`.

## الموجود حالياً

- بحث برقم القطعة أو الاسم أو رقم المخطط
- تصنيف حسب النظام
- عرض اسم عربي للقطعة مع الاسم الأصلي من الكتالوج
- فلترة حسب سنة التوافق، المحرك، وحالة القطعة
- صفحة تفاصيل لكل قطعة
- إضافة ملاحظات محلية لكل قطعة
- إضافة صور من مكتبة الصور لكل قطعة
- بيانات أولية مولدة من ملف الكتالوج الحالي في `work/partsouq_full/units_structured.json`

## الملفات المهمة

- المشروع: `SafariY60Parts.xcodeproj`
- ملفات التطبيق: `SafariY60Parts/`
- بيانات القطع: `SafariY60Parts/Resources/parts_seed.json`
- مولد البيانات: `tools/build_ios_parts_seed.py`
- وثيقة المتطلبات: `PRODUCT_REQUIREMENTS_AR.md`

## طريقة التشغيل

1. افتح `SafariY60Parts.xcodeproj` على جهاز ماك فيه Xcode.
2. اختر iPhone Simulator أو جهاز iPhone فعلي.
3. شغّل التطبيق.

## تحديث بيانات القطع

إذا تغيّر ملف المصدر `units_structured.json` شغّل:

```powershell
& 'C:\Users\safwa\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' 'tools\build_ios_parts_seed.py'
```

ثم افتح المشروع من جديد في Xcode.

## ملاحظات

- التخزين الحالي محلي على الجهاز داخل `Application Support`.
- الصور تضاف من مكتبة الصور. لم أضف التقاط مباشر بالكاميرا في هذه النسخة الأولى.
- لم يتم بناء التطبيق أو تشغيله هنا لأن البيئة الحالية لا تحتوي Xcode أو iOS Simulator.
