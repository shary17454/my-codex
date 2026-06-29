# my-codex
مستودع تجريبي لاستخدام Codex من الجوال عبر السحابة وربطه مع GitHub
# my-codex

مستودع تجريبي لاستخدام Codex من الجوال عبر السحابة.

الهدف:
- تجربة GitHub و Codex.
- تشغيل المهام السحابية بدون لابتوب.
- حفظ الملفات والمشاريع لاستخدامها لاحقاً.

## مساعد الحياة

تم نقل ملخص دردشة مشروع **مساعد الحياة - Life Assistant MVP** إلى:

- [docs/life-assistant-chat-handoff.md](docs/life-assistant-chat-handoff.md)

## Patrol Hub

تم نقل ودمج محتوى دردشة إعادة تصميم **Patrol Hub** إلى:

- [docs/patrol-hub-chat-handoff.md](docs/patrol-hub-chat-handoff.md)
- [patrol-hub-redesign/index.html](patrol-hub-redesign/index.html)

## كتيب مرزوق بن حويد العضياني

تم نقل ودمج محتوى محادثة مشروع **كتيب مرزوق بن حويد بن وازع العضياني رحمه الله** إلى:

- [docs/marzouq-book/README.md](docs/marzouq-book/README.md)
- [docs/marzouq-book/chat-log.md](docs/marzouq-book/chat-log.md)

## بطل الدروب

تم نقل ودمج محتوى دردشة مشروع **بطل الدروب** لتطبيق كتالوج قطع نيسان باترول إلى هذا المستودع.

**Batal Al-Droob** is a bilingual Arabic/English Nissan Patrol parts catalog app focused first on the Y60 generation, with the UI structure prepared for Y61, Y62, and Y63.

### Current Scope

- Browser app with Arabic-first UI and English toggle.
- Nissan Patrol generation selector: Y60, Y61, Y62, Y63.
- Internal parts sections: engine, cooling, electrical, body, brakes, suspension, and fuel.
- Y60 parts database extracted from supplied PDF catalogs and stored in SQLite and JSON.
- Saudi Riyal and US Dollar price display.
- iOS WebView wrapper prepared under `ios/BatalAlDroob`.
- App Store metadata and review notes prepared under `app-store`.

### Main Files

- [docs/CHAT_HANDOFF_AR.md](docs/CHAT_HANDOFF_AR.md)
- `index.html`, `styles.css`, `app.js`: web app UI and behavior.
- `server.py`: local web server and SQLite API.
- `data/app_database.sqlite`: app database.
- `data/y60_app_catalog.json`: browser fallback catalog data.
- `scripts/`: extraction, audit, build, and sync tools.
- `ios/BatalAlDroob/`: iOS wrapper project.

### Run Locally

```bash
python3 server.py
```

Open:

```text
http://localhost:5005/?v=hierarchy-2
```

On a phone connected to the same network, use the Mac IP address shown by `ifconfig`, for example:

```text
http://172.20.10.3:5005/?v=hierarchy-2
```

### Data Status

- Y60: integrated and searchable.
- Y61: UI slot and extraction script started, but full integration requires readable Y61 PDF/FAST/EPC source files.
- Y62/Y63: UI generation cards prepared with images; detailed parts databases are not integrated yet.
