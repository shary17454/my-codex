# سجل إصدار الدرب

## 1.9.1 (76) - 2026-07-15

### العربية - What's New

- تثبيت اسم التطبيق المعروض داخل النظام والمتجر إلى "الدرب".
- إصلاح إنشاء الرحلات الجديدة وحفظها وتعديل المشاركين والوجهة.
- تحسين البوصلة واتجاه الشمال وربطها بطلب الموقع عند الحاجة.
- إصلاح أزرار الطقس وجودة الهواء ولوحة القيادة وإضافة الموقع لتظهر حالة واضحة عند الاستخدام.
- توسيع البحث المحلي عن المواقع المعتمدة وإضافة اقتراحات وجهات برية أكثر.
- تحسين خرائط بلا إنترنت بإظهار خيارات مناطق متعددة بدل تكرار موقع واحد.
- تحسين الخريطة وإعادة تمركزها عند تغيير الطبقة أو الوجهة.
- تحسين وضوح النصوص والبطاقات على الشاشات الصغيرة.
- توحيد إعدادات الإصدار والبناء وتجهيز حماية Xcode Cloud لمنع استخدام Xcode beta أو SDK غير مدعوم في أرشيف App Store.

### English - What's New

- Set the displayed app name consistently to "Al Darb".
- Fixed trip creation, saved trip editing, participants, and destination selection.
- Improved compass heading behavior and location permission flow.
- Fixed weather, air quality, driving dashboard, and add-place actions with clearer status feedback.
- Expanded local destination search with more approved desert locations.
- Improved offline maps with multiple region choices instead of repeated saved entries.
- Improved map recentering when changing layers or destinations.
- Improved text and card readability on smaller screens.
- Unified release/build settings and added an Xcode Cloud guard to prevent App Store archives from using beta Xcode or unsupported SDKs.

## 1.9.0 (67) - 2026-07-15

### العربية - What's New

- تحسين وضوح أزرار الخريطة والطبقات حتى تظهر النصوص كاملة داخل الإطارات على الشاشات الصغيرة.
- تحسين أزرار وضع القيادة والبوصلة لتكون أوضح وأسهل ضغطًا مع تسميات وصول مناسبة.
- تحسين محدد اللغة في شريط التطبيق لتقليل الازدحام مع إبقاء العربية والإنجليزية والفرنسية والإسبانية والصينية.
- تحسين إعادة رسم طبقات الخرائط عند تغيير شفافية طبقة Tiles.
- رفع رقم الإصدار والبناء وتجهيز التطبيق لبناء إصدار جديد.

### English - What's New

- Improved map and layer controls so labels fit better on small screens.
- Improved driving and compass controls with clearer tap targets and accessibility labels.
- Reduced toolbar crowding in the language selector while keeping Arabic, English, French, Spanish, and Chinese.
- Improved map tile overlay refresh when changing layer opacity.
- Bumped version and build number for the next release build.

## 1.6 (56) - 2026-07-11

- تغيير اسم التطبيق المعروض إلى "الدرب".
- رفع رقم البناء إلى 56 لتجهيز بناء جديد في App Store Connect.

## 1.6 (55) - 2026-07-11

- إضافة شاشة ملاحة بالإحداثيات للاستخدام الميداني: حفظ الموقع الحالي، حفظ نقطة يدوية، حساب المسافة والاتجاه، وعرض دقة GPS.
- إضافة تخزين محلي للنقاط دون حساب أو إعلانات أو تتبع.
- إضافة استيراد GPX وتصدير النقاط المحفوظة كملف GPX قابل للمشاركة.
- إضافة مشاركة الإحداثيات كنص وروابط Apple Maps و Google Maps.
- إصلاح تداخل أزرار الخريطة وتحويلها إلى شبكة أكثر وضوحاً على الشاشات الصغيرة.
- تحسين أزرار مصادر الخرائط البرية لتكون قابلة للضغط وبنصوص أصغر داخل الإطار.
- تحسين تشغيل البوصلة وطلب صلاحية الموقع عند فتحها أو تشغيل أدوات الملاحة.
- رفع رقم البناء إلى 55 ورقم الإصدار إلى 1.6 لتجهيز تحديث جديد عبر Xcode Cloud.

## 1.5 (54) - 2026-07-11

- تغيير اسم التطبيق المعروض إلى "الدروب".
- إصلاح ربط `CFBundleVersion` برقم البناء الفعلي في إعدادات Xcode بدلاً من رقم ثابت قديم، حتى يظهر البناء الجديد بشكل صحيح في App Store Connect.
- رفع رقم الإصدار إلى `1.5` ورقم البناء إلى `54` لتجاوز آخر محاولات Xcode Cloud الفاشلة.
- إعادة تجهيز المشروع للأرشفة عبر Xcode Cloud و App Store Connect.

## 1.4 (45) - 2026-07-11

- تجهيز إصدار تحديث جديد في App Store Connect لأن إصدار `1.0` منشور/مقفل ولا يقبل استبدال البناء داخله، ورفع رقم البناء فوق Build 43 المرفوض.
- رفع رقم النسخة إلى `1.4` ورقم البناء إلى `45` حتى يتوافق مع متطلبات Apple لنسخة أعلى من الإصدار المنشور.
- تغيير اسم التطبيق المعروض إلى "الدرب".
- تحسين دليل الحياة الفطرية بعرض معلومات أوضح عن الكائنات، درجة الخطورة، السمية، البيئة، الانتشار، وماذا يفعل المستخدم عند المشاهدة.
- ضبط النصوص الطويلة داخل بطاقات الأدوات ودليل الحياة الفطرية لتبقى داخل الإطار على الشاشات الصغيرة.
- تحسين شاشة البوصلة لتطلب صلاحية الموقع عند تشغيل أدوات الملاحة وتعرض حالة الصلاحية للمستخدم.
- إضافة تنبيهات قرب أولية للمناطق البرية المهمة أثناء الرحلة، مع طلب صلاحيات الموقع والإشعارات عند الحاجة.
- إضافة دعم لغات إضافية في محدد اللغة: الفرنسية، الإسبانية، والصينية، مع إبقاء العربية والإنجليزية.
- تحديث بيانات الإصدار استعداداً للرفع عبر Xcode Cloud إلى App Store Connect.
