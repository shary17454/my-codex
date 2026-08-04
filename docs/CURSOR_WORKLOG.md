# سجل عمل Cursor على رواية

> هذا الملف مخصّص لتسليم العمل بين **Cursor** و **Codex (ChatGPT)**.
> الهدف: تكميل MVP دون حذف أو استبدال أي شيء أنشأه Codex.

## قواعد التعاون

1. **إضافة فقط** — لا حذف ملفات Codex، ولا إعادة كتابة وحدات كاملة.
2. **فرع منفصل** — عمل Cursor على فرع `cursor/continue-mvp`؛ `main` يبقى كما تركه Codex.
3. **Commits واضحة** — كل دفعة بعنوان يبدأ بـ `cursor:` لتمييزها في Git.
4. **لا تعديل على بيئة Codex** — المسار `Documents/Codex/2026-08-04/new-chat-2/` هو نفس المستودع؛ التغييرات هنا يراها Codex عند العودة.
5. **PlaceholderPage تبقى** — الشاشات غير المنجزة تظل تستخدم `placeholder_page.dart` حتى تُبنى بدائل حقيقية.

## حالة المشروع عند بدء Cursor (2026-08-04)

| الجزء | الحالة | ملاحظة |
|-------|--------|--------|
| `apps/api` | ✅ MVP جاهز | auth, content, search, RBAC, tests |
| `apps/web` | ✅ أساسي | صفحات متصلة بالـ API |
| `apps/admin` | ✅ أساسي | مراجعة ونشر القصائد |
| `apps/mobile` | 🟡 جزئي | home + search + poems + poets؛ باقي المسارات placeholder |
| `packages/*` | 🟡 stubs | placeholders |

**آخر commit من Codex:** `bd21346` — Set Rawaya iOS bundle identifier  
**Remote:** `origin/codex/rawaya-mvp-xcode-cloud` على `github.com/shary17454/my-codex.git`

## أولويات التكميل المقترحة (المرحلة 1)

- [x] Flutter: شاشات القصائد (`/poems`, `/poems/:id`)
- [x] Flutter: شاشة الشعراء (`/poets`)
- [ ] Flutter: تسجيل الدخول (`/auth`) — ربط بـ `POST /auth/login`
- [ ] Web: تحسين UI للصفحات الأساسية (بدون كسر API)
- [ ] Mobile: ربط باقي أقسام Home بالمسارات الصحيحة

## سجل التغييرات

| التاريخ | الفرع | الوصف | الملفات |
|---------|-------|-------|---------|
| 2026-08-04 | `cursor/continue-mvp` | إنشاء هذا السجل وإطار التعاون | `docs/CURSOR_WORKLOG.md` |
| 2026-08-04 | `cursor/continue-mvp` | شاشات Flutter للقصائد والشعراء | `apps/mobile/lib/features/poems/*`, `apps/mobile/lib/features/poets/poets_page.dart`, `apps/mobile/lib/main.dart`, `apps/mobile/lib/features/home/home_page.dart` |
| 2026-08-04 | `cursor/continue-mvp` | إصلاح علاقات Prisma + CI | `apps/api/prisma/schema.prisma`, `content.service.ts`, `suggestions.service.ts`, `ci_post_clone.sh` |

---

**لـ Codex عند العودة:** اقرأ هذا الملف أولاً، ثم `git log --oneline cursor/continue-mvp` لرؤية commits Cursor.
