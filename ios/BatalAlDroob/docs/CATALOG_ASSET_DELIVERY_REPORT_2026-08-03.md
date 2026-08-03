# تقرير تسليم كتالوجات بطل الدروب

التاريخ: 2026-08-03
الإصدار: 2.6
البناء: 189
الحالة: التنفيذ والتعبئة المحلية مكتملان؛ رفع الحزم ومعالجتها في App Store Connect لم يُؤكدا بعد.

## النتيجة التنفيذية

أصبح مشروع بطل الدروب يدعم جميع ملفات كتالوجات الباترول الأصلية وعددها 640
ملف PDF من خلال Apple-Hosted Managed Background Assets. لا تُنسخ الملفات داخل
حزمة IPA لأن حجمها غير المضغوط 12.51 GiB ويتجاوز حد تطبيق iOS، بل تُفهرس داخل
التطبيق وتُنزل من Apple عند طلب المستخدم للملف المرتبط.

| البند | النتيجة |
|---|---:|
| ملفات PDF المصدر | 640 |
| الحجم المنطقي للمصدر | 13,433,611,217 بايت |
| Y60 | 297 ملفًا |
| Y61 | 143 ملفًا |
| Y62 | 140 ملفًا |
| عام/غير مصنف | 60 ملفًا |
| الحزم المُدارة | 40 |
| حجم أرشيفات AAR المعبأة | 10,454,944 KiB تقريبًا |
| بصمات SHA-256 | 640/640 مطابقة |

## بنية التسليم

1. يبقى فهرس البحث وقاعدة بيانات أرقام القطع داخل التطبيق ويعملان دون تنزيل PDF.
2. يربط `catalog_asset_delivery.json` كل ملف بمعرف حزمة ومسار وحجم وبصمة SHA-256.
3. يطلب التطبيق الحزمة المرتبطة فقط بعد تحقق صلاحية الوصول المدفوع أو صلاحية المالك.
4. ينفذ `AssetPackManager` التنزيل من استضافة Apple على iOS 26 فأحدث.
5. يرفض التطبيق فتح الملف إذا تغيّر المسار أو الحجم أو بصمة SHA-256.
6. يفتح الملف عبر PDFKit ويمكن الانتقال إلى صفحة الدليل المرتبطة بنتيجة القطعة.

## تغييرات المشروع

- إضافة `CatalogAssetService.swift` لخدمة الفهرس والتنزيل والتحقق.
- إضافة `CatalogAssetViews.swift` لمكتبة الكتالوجات وقارئ PDF.
- إضافة امتداد `BatalCatalogAssetsExtension` للتنزيل المُدار.
- إضافة App Group مشترك: `group.com.batalaldroob.parts`.
- إضافة مفاتيح `BAAppGroupID` و`BAHasManagedAssetPacks` و`BAUsesAppleHosting`.
- إبقاء Bundle ID للتطبيق دون تغيير: `com.batalaldroob.parts`.
- إضافة 40 manifest حتميًا تحت `CatalogAssetPacks/manifests`.
- استبعاد PDF من موارد IPA والإبقاء على `Web/catalog/search` فقط.
- رفع رقم البناء إلى 189 دون تغيير Marketing Version 2.6.

## التحقق المنفذ

- نجح `validate_catalog_archive.py --full-hash`: عدد الملفات والحجم وكل البصمات مطابقة.
- نجح إنشاء 40/40 أرشيف `.aar` باستخدام Xcode 26.6 (17F113) و`ba-package 1.2`.
- سُجلت بصمة SHA-256 لكل أرشيف AAR في
  `CATALOG_ASSET_PACKS_SHA256_2026-08-03.txt` لمطابقة الملف المحلي مع الملف
  المرفوع أو المعاد تنزيله من Apple دون الاعتماد على الاسم وحده.
- نجح `validate_release.py` بعد إضافة الامتداد ومفاتيح Background Assets.
- نجح بناء Debug لجهاز iOS عام دون توقيع.
- نجح بناء Release لجهاز iOS عام دون توقيع.
- نجحت 48/48 من اختبارات الوحدة و4/4 من اختبارات الواجهة، بإجمالي 52/52.
- نجح اختبار الواجهة المخصص في فتح مكتبة الكتالوجات والتحقق من ظهور فهرس 640
  ملفًا، محدد الجيل، وأول مستند مفهرس.
- تحقق أن Release يحتوي امتداد التنزيل داخل `Extensions` ولا يحتوي أي ملف PDF.

## حالة App Store Connect

لم تُرفع أرشيفات `.aar` إلى App Store Connect في وقت كتابة هذا التقرير. يجب عدم
وصف الحزم بأنها منشورة أو متاحة لعملاء App Store حتى تنجح الخطوات التالية ويظهر
وضع المعالجة في App Store Connect:

1. رفع الحزم الأربعين إلى سجل تطبيق بطل الدروب Apple ID `6786117376`.
2. انتظار معالجة Apple لكل حزمة والتحقق من عدم وجود `Failed`.
3. ربط الحزم بتجربة TestFlight واختبار تنزيل عينة من كل جيل على جهاز iOS 26 فأحدث.
4. إرسال الحزم للمراجعة. تسمح Apple بعشر حزم كحد أقصى في طلب مراجعة واحد، لذلك
   تحتاج الحزم الأربعون إلى أربع دفعات مراجعة ما لم تغيَّر استراتيجية التقسيم.
5. عدم إرسال إصدار التطبيق للمراجعة إلا بأمر صريح من المالك.

## القيود والتوافق

- التطبيق الأساسي يدعم iOS 17 فأحدث.
- تنزيل ملفات PDF الأصلية عبر Managed Background Assets يحتاج iOS 26 فأحدث.
- على iOS 17 إلى iOS 25 يبقى البحث والفهرس وبيانات القطع متاحة، لكن فتح PDF
  المُستضاف يعرض رسالة عدم دعم النظام بدل ادعاء نجاح التنزيل.
- أرشيفات `.aar` نواتج إصدار قابلة لإعادة التوليد ولا تُرفع إلى GitHub.
- لا تحتوي الشفرة على مفاتيح تخزين أو بيانات دخول لخادم ملفات.

## أوامر إعادة الإنتاج

```sh
python3 scripts/validate_catalog_archive.py --full-hash

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
python3 scripts/generate_catalog_asset_packs.py \
  --package-all \
  --output-directory CatalogAssetPacks/archives

python3 scripts/validate_release.py
```

## مراجع Apple

- [Downloading Apple-hosted asset packs](https://developer.apple.com/documentation/BackgroundAssets/downloading-apple-hosted-asset-packs)
- [Upload Apple-hosted asset packs](https://developer.apple.com/help/app-store-connect/manage-asset-packs/upload-apple-hosted-asset-packs/)
- [Apple-hosted asset pack size limits](https://developer.apple.com/help/app-store-connect/reference/app-uploads/apple-hosted-asset-pack-size-limits/)
- [Submit Apple-hosted asset packs](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-apple-hosted-asset-packs/)
