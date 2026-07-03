# متطلبات استلام مصادر كتالوج Nissan Patrol Y60 EPC

## الغرض

هذا الملف يحدد مصادر البيانات المطلوبة قبل إنتاج كتالوج EPC أصلي كامل لنيسان باترول Y60 من 1988 إلى 1997.

لا يتم إدخال أرقام قطع، أو لوحات EPC، أو مخططات تفجيرية، أو أرقام نداء، أو بدائل قطع، أو نطاقات VIN بدون مصدر رسمي قابل للتحقق.

## المصادر المقبولة

- تصدير رسمي من Nissan FAST أو Nissan EPC.
- صورة أو PDF أصلي للوحات EPC من وكيل أو مصدر رسمي.
- مسح ميكروفيش قطع غيار أصلي بجودة تسمح بقراءة أرقام القطع وأرقام النداء.
- مستندات بدائل أو Supersession صادرة من نيسان أو الوكيل.
- فهارس تطبيق حسب VIN أو تاريخ إنتاج أو كود موديل رسمية.

## المصادر غير الكافية وحدها

- صور من منتديات بدون مصدر رسمي.
- جداول غير موثقة من الإنترنت.
- أرقام قطع من متاجر إلكترونية بدون ربط بلوحة EPC الأصلية.
- مخططات معاد رسمها أو ناقصة أرقام النداء.
- ملفات لا توضح السوق أو سنة الإنتاج أو كود الموديل.

## المطلوب لكل مصدر

لكل ملف مصدر، يجب تسجيل البيانات التالية في:

`data/source_intake_manifest.csv`

الحقول المطلوبة:

- `source_id`: رقم تعريفي للمصدر.
- `source_type`: نوع المصدر، مثل FAST export أو EPC PDF أو Microfiche scan.
- `source_file_path`: مسار الملف داخل مساحة العمل.
- `year_from` و `year_to`: نطاق السنوات.
- `market`: السوق، مثل Japan أو GCC أو Saudi Arabia أو Australia أو Europe.
- `model_code`: كود الموديل إن وجد.
- `body`: نوع الهيكل.
- `engine`: كود المحرك.
- `transmission`: نوع أو كود ناقل الحركة.
- `language`: لغة المصدر.
- `contains_epc_plate_numbers`: هل يحتوي على أرقام لوحات EPC الأصلية.
- `contains_exploded_diagrams`: هل يحتوي على المخططات التفجيرية الأصلية.
- `contains_callouts`: هل يحتوي على أرقام النداء أو أرقام المرجع.
- `contains_part_numbers`: هل يحتوي على أرقام قطع نيسان.
- `contains_vin_applicability`: هل يحتوي على نطاقات VIN.
- `contains_production_dates`: هل يحتوي على تواريخ إنتاج.
- `contains_supersessions`: هل يحتوي على أرقام بديلة أو ملغاة.
- `source_owner`: مالك أو مصدر الملف.
- `verification_status`: حالة التحقق.
- `notes`: ملاحظات.

## هيكل مجلدات المصادر المقترح

ضع المصادر الرسمية تحت:

`sources/official_epc/`

التقسيم المقترح:

- `sources/official_epc/1988/`
- `sources/official_epc/1989/`
- `sources/official_epc/1990/`
- `sources/official_epc/1991/`
- `sources/official_epc/1992/`
- `sources/official_epc/1993/`
- `sources/official_epc/1994/`
- `sources/official_epc/1995/`
- `sources/official_epc/1996/`
- `sources/official_epc/1997/`

ويمكن إنشاء مجلدات فرعية حسب السوق:

- `GCC`
- `Saudi_Arabia`
- `Japan`
- `Australia`
- `Europe`
- `Africa`
- `Export`

## قاعدة العمل

إذا لم تكن لوحة EPC الأصلية متوفرة، يتم إدراجها في:

`output/markdown/missing_epc_plates_report.md`

ولا يتم توليد أو تخمين أي مخطط أو رقم قطعة.

