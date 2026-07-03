# my-codex

مستودع شخصي لتجميع مشاريع وتجارب Codex وربطها مع GitHub.

## كتلوجات الباترول الاخيرة

اسم الحزمة المعتمد للبحث داخل GitHub:

```text
كتلوجات الباترول الاخيرة
```

موقع كتالوجات نيسان باترول المعتمدة:

```text
deliverables/final_patrol_catalogs
```

الخانات الأساسية:

- `Y60`
- `Y61`
- `Y62`
- `Y63`
- `Pre_Y60`
- `Pickup`
- `Reports`

ملف الاسم:

```text
PROJECT_NAME.txt
```

ملف الفهرسة السريع:

```text
كتلوجات الباترول الاخيرة.md
```

## Continue This Work From GitHub

Repository:

```text
https://github.com/shary17454/my-codex
```

Clone and pull the large PDF/ZIP files through Git LFS:

```powershell
git clone https://github.com/shary17454/my-codex.git
cd my-codex
git lfs install
git lfs pull
```

Check the saved catalogs:

```powershell
git status
git lfs ls-files
Get-ChildItem deliverables\final_patrol_catalogs -Recurse -Filter *.pdf
```

Resume Y61 extraction from saved data when source pages are available:

```powershell
C:\Users\safwa\AppData\Local\Programs\PowerShell\7\pwsh.exe -Command "& 'C:\Users\safwa\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 'scripts\download_y61_diagram_cache.py'"
```

## Patrol Hub / Safari Y60

المستودع يضم أيضًا ملفات مشروع **Nissan Patrol Safari Y60 / Patrol Hub**، تطبيق iPhone أولي، تطبيق Flutter للويب وويندوز، وملفات توثيق للدردشات والملاحظات.

### الملفات المهمة

- تطبيق Flutter: `flutter_y60_catalog/`
- تطبيق SwiftUI: `SafariY60Parts/`
- مشروع Xcode: `SafariY60Parts.xcodeproj`
- بيانات القطع لتطبيق iPhone: `SafariY60Parts/Resources/parts_seed.json`
- كتالوجات Y60: `flutter_y60_catalog/assets/catalog/pdfs/`
- فهارس البحث والأقسام: `flutter_y60_catalog/assets/catalog/search/`
- واجهة الويب البديلة: `patrol-hub-redesign/`
- أدوات توليد البيانات: `tools/`
- وثيقة المتطلبات: `PRODUCT_REQUIREMENTS_AR.md`

## Official EPC Source Intake

The final complete EPC catalog cannot be produced until official source material is added.

Place official Nissan EPC/FAST/microfiche/dealer files under:

```text
sources/official_epc/
```

Then register each source in:

```text
data/source_intake_manifest.csv
```

If an original EPC plate is unavailable, it must remain in the Missing EPC Plates Report. Do not generate, redraw, crop, simplify, or guess official diagrams or part numbers.
