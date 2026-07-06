# my-codex

مستودع شخصي لتجميع مشاريع وتجارب Codex وربطها مع GitHub. يحتوي على عدة مشاريع منفصلة، أهمها تطبيقات iOS وواجهات ويب ووثائق عمل مرتبطة بالمحادثات السابقة.

## المشاريع الرئيسية

- **وش الرأي / راح تفهم**: تطبيق iOS عربي للمقارنات والتصويت واتخاذ القرار، موجود داخل `StudyVaultApp/`.
- **اسأل الناس**: نسخة ويب MVP لفكرة المقارنات الجماعية، موجودة داخل `ask-people/`.
- **بطل الدروب**: تطبيق كتالوج قطع نيسان باترول Y60/Y61/Y62/Y63، وملفات الويب الخاصة به في جذر المستودع.
- **SafariY60Parts**: تطبيق SwiftUI أولي لإدارة قطع Nissan Patrol Safari Y60.
- **Patrol Hub / Safari Y60**: مشروع Flutter وبيانات كتالوجات وفهارس بحث لقطع باترول Y60.
- **دراسات ووثائق SAIP**: مستندات ومخرجات بحثية محفوظة داخل مجلدات `study-saip-*` و`output/saip`.

## وش الرأي

تطبيق iOS عربي يساعد المستخدم على اتخاذ قرار أوضح عند المقارنة بين منتجين أو خدمات أو خيارات متعددة، من خلال:

- إنشاء مقارنات بخيارين أو أكثر.
- التصويت وإضافة سبب التصويت.
- عرض نسب النتائج ونقاط القوة والضعف.
- حفظ المقارنات والبحث فيها.
- واجهة عربية RTL متوافقة مع iPhone وiPad.

المسارات المهمة:

- `StudyVaultApp/StudyVault.xcodeproj`
- `StudyVaultApp/StudyVault/ContentView.swift`
- `StudyVaultApp/StudyVault/AskModels.swift`
- `StudyVaultApp/StudyVault/ViewModels.swift`
- `StudyVaultApp/AppStore/`

تشغيل البناء:

```bash
xcodebuild -project StudyVaultApp/StudyVault.xcodeproj -scheme StudyVault -destination generic/platform=iOS -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## اسأل الناس

تطبيق ويب عربي لفكرة "اسأل الناس": منصة صغيرة تتيح للمستخدم إنشاء مقارنة بين شيئين محددين أو أكثر، ثم يحصل على تصويت وتعليقات من أشخاص مهتمين بنفس المجال.

المميزات الحالية:

- واجهة عربية كاملة باتجاه RTL.
- إنشاء مقارنة بعنوان وتفاصيل.
- عنصران أساسيان للمقارنة مع إمكانية إضافة عناصر إضافية.
- منع العناصر المكررة داخل المقارنة.
- تصويت مباشر على العناصر.
- تعليقات لكل مقارنة.
- حفظ المقارنات.
- فلترة وبحث وترتيب.
- حفظ البيانات محليًا عبر `localStorage`.

المسارات:

- `ask-people/index.html`
- `ask-people/styles.css`
- `ask-people/app.js`

التشغيل:

```bash
cd ask-people
python3 -m http.server 5173
```

ثم افتح:

```text
http://127.0.0.1:5173/
```

## بطل الدروب

**Batal Al-Droob** تطبيق عربي/إنجليزي لكتالوج قطع نيسان باترول، ويركز أولًا على Y60 مع تجهيز واجهة للأجيال Y61 وY62 وY63.

الملفات الرئيسية في الجذر:

- `index.html`
- `styles.css`
- `app.js`
- `server.py`
- `data/app_database.sqlite`
- `data/y60_app_catalog.json`
- `ios/BatalAlDroob/`

تشغيل محلي:

```bash
python3 server.py
```

ثم افتح:

```text
http://localhost:5005/?v=hierarchy-2
```

## Patrol Hub / Safari Y60

المشروع يضم:

- تطبيق Flutter قابل للتشغيل على الويب وويندوز ومجهز لاحقاً لأندرويد و iOS.
- تطبيق SwiftUI أولي لإدارة قطع `Nissan Patrol Safari Y60`.
- فهارس كتالوجات Y60 وملفات PDF الأصلية.
- بحث برقم القطعة أو الاسم العربي أو الاسم الإنجليزي.
- تصنيف حسب النظام: المحرك، القير والدبل، الكهرباء، التكييف، الداخلية، البدي، وغيرها.

المسارات:

- `flutter_y60_catalog/`
- `SafariY60Parts/`
- `SafariY60Parts.xcodeproj`
- `SafariY60Parts/Resources/parts_seed.json`
- `tools/`
- `PRODUCT_REQUIREMENTS_AR.md`

## توثيق الدردشات والمخرجات

توجد ملفات توثيق ومخرجات محادثات داخل:

- `docs/`
- `CHAT_CONTENT.md`
- `conversation_cloud_backup_ar.md`
- `study-saip-saher2030/`

## سياسة إدارة الملفات

ملف `.gitignore` يستثني ملفات البناء والكاش والأسرار، مثل:

- `build/`
- `DerivedData/`
- `.dart_tool/`
- `Pods/`
- `node_modules/`
- ملفات التوقيع والمفاتيح الخاصة.

يجب عدم رفع ملفات البناء أو الأرشيفات أو مفاتيح Apple الخاصة إلى GitHub.
