import Foundation

/// Interface translations for the languages beyond Arabic and English.
///
/// Design note: the app states every user-facing string inline as an Arabic/English
/// pair via `CatalogViewModel.text(ar:en:)`. Rather than rewrite ~240 call sites into
/// key lookups, this table is keyed by the **English** string already present at each
/// call site, so adding a language never touches the views.
///
/// Coverage is deliberate, not exhaustive: the navigation layer and primary actions
/// are translated, and anything without an entry falls back to English. A partial
/// translation with an English fallback is safe here — English is the working second
/// language across Gulf workshops and the parts trade.
///
/// Catalog part names are **not** translated: the source catalogs publish them in
/// Arabic and English only, and OEM part numbers are language-neutral by definition.
enum BatalLocalization {
    /// Returns the localized interface string for `language`, or nil when the app
    /// should fall back to the English text supplied at the call site.
    static func translate(_ englishKey: String, to language: AppLanguage) -> String? {
        table[englishKey]?[language]
    }

    /// Number of interface strings translated for each non-default language.
    static var translatedStringCount: Int { table.count }

    private static let table: [String: [AppLanguage: String]] = [
        // MARK: Tabs and navigation
        "Home": [
            .spanish: "Inicio", .french: "Accueil", .german: "Startseite", .russian: "Главная", .portuguese: "Início", .chinese: "首页", .turkish: "Ana Sayfa", .hindi: "होम"
        ],
        "Catalog": [
            .spanish: "Catálogo", .french: "Catalogue", .german: "Katalog", .russian: "Каталог", .portuguese: "Catálogo", .chinese: "目录", .turkish: "Katalog", .hindi: "कैटलॉग"
        ],
        "Assistant": [
            .spanish: "Asistente", .french: "Assistant", .german: "Assistent", .russian: "Помощник", .portuguese: "Assistente", .chinese: "助手", .turkish: "Asistan", .hindi: "सहायक"
        ],
        "Request": [
            .spanish: "Solicitud", .french: "Demande", .german: "Anfrage", .russian: "Запрос", .portuguese: "Solicitação", .chinese: "请求", .turkish: "Talep", .hindi: "अनुरोध"
        ],
        "Tools": [
            .spanish: "Herramientas", .french: "Outils", .german: "Werkzeuge", .russian: "Инструменты", .portuguese: "Ferramentas", .chinese: "工具", .turkish: "Araçlar", .hindi: "उपकरण"
        ],
        "More": [
            .spanish: "Más", .french: "Plus", .german: "Mehr", .russian: "Ещё", .portuguese: "Mais", .chinese: "更多", .turkish: "Daha Fazla", .hindi: "और"
        ],
        "Maintenance": [
            .spanish: "Mantenimiento", .french: "Entretien", .german: "Wartung", .russian: "Обслуживание", .portuguese: "Manutenção", .chinese: "保养", .turkish: "Bakım", .hindi: "रखरखाव"
        ],
        "Catalog library": [
            .spanish: "Biblioteca de catálogos", .french: "Bibliothèque du catalogue", .german: "Katalogbibliothek", .russian: "Библиотека каталогов", .portuguese: "Biblioteca de catálogos", .chinese: "目录库", .turkish: "Katalog kitaplığı", .hindi: "कैटलॉग लाइब्रेरी"
        ],
        "Shared fitment": [
            .spanish: "Compatibilidad compartida", .french: "Compatibilité partagée", .german: "Gemeinsame Passform", .russian: "Общая совместимость", .portuguese: "Compatibilidade compartilhada", .chinese: "通用适配", .turkish: "Ortak uyum", .hindi: "साझा फिटमेंट"
        ],
        "Fitment check": [
            .spanish: "Verificación de compatibilidad", .french: "Vérification de compatibilité", .german: "Passform prüfen", .russian: "Проверка совместимости", .portuguese: "Verificação de compatibilidade", .chinese: "适配检查", .turkish: "Uyum kontrolü", .hindi: "फिटमेंट जांच"
        ],
        "Smart search": [
            .spanish: "Búsqueda inteligente", .french: "Recherche intelligente", .german: "Intelligente Suche", .russian: "Умный поиск", .portuguese: "Busca inteligente", .chinese: "智能搜索", .turkish: "Akıllı arama", .hindi: "स्मार्ट खोज"
        ],
        "Part request": [
            .spanish: "Solicitud de pieza", .french: "Demande de pièce", .german: "Teileanfrage", .russian: "Запрос детали", .portuguese: "Solicitação de peça", .chinese: "配件请求", .turkish: "Parça talebi", .hindi: "पुर्जे का अनुरोध"
        ],

        // MARK: Common actions
        "OK": [
            .spanish: "Aceptar", .french: "OK", .german: "OK", .russian: "ОК", .portuguese: "OK", .chinese: "确定", .turkish: "Tamam", .hindi: "ठीक है"
        ],
        "Dismiss": [
            .spanish: "Cerrar", .french: "Fermer", .german: "Schließen", .russian: "Закрыть", .portuguese: "Fechar", .chinese: "关闭", .turkish: "Kapat", .hindi: "बंद करें"
        ],
        "Retry": [
            .spanish: "Reintentar", .french: "Réessayer", .german: "Erneut versuchen", .russian: "Повторить", .portuguese: "Tentar novamente", .chinese: "重试", .turkish: "Tekrar Dene", .hindi: "पुनः प्रयास करें"
        ],
        "Notice": [
            .spanish: "Aviso", .french: "Avis", .german: "Hinweis", .russian: "Уведомление", .portuguese: "Aviso", .chinese: "提示", .turkish: "Bildirim", .hindi: "सूचना"
        ],
        "Open catalog": [
            .spanish: "Abrir catálogo", .french: "Ouvrir le catalogue", .german: "Katalog öffnen", .russian: "Открыть каталог", .portuguese: "Abrir catálogo", .chinese: "打开目录", .turkish: "Kataloğu aç", .hindi: "कैटलॉग खोलें"
        ],
        "Check now": [
            .spanish: "Comprobar ahora", .french: "Vérifier maintenant", .german: "Jetzt prüfen", .russian: "Проверить сейчас", .portuguese: "Verificar agora", .chinese: "立即检查", .turkish: "Şimdi kontrol et", .hindi: "अभी जांचें"
        ],
        "Search the catalog": [
            .spanish: "Buscar en el catálogo", .french: "Rechercher dans le catalogue", .german: "Katalog durchsuchen", .russian: "Поиск в каталоге", .portuguese: "Pesquisar no catálogo", .chinese: "搜索目录", .turkish: "Katalogda ara", .hindi: "कैटलॉग में खोजें"
        ],
        "Part number or description": [
            .spanish: "Número o descripción de la pieza", .french: "Numéro ou description de pièce",
            .german: "Teilenummer oder Beschreibung", .russian: "Номер детали или описание",
            .portuguese: "Número ou descrição da peça", .chinese: "配件号或描述",
            .turkish: "Parça numarası veya açıklama", .hindi: "पुर्जा नंबर या विवरण"
        ],

        // MARK: Counters and labels
        "Parts": [
            .spanish: "Piezas", .french: "Pièces", .german: "Teile", .russian: "Детали", .portuguese: "Peças", .chinese: "配件", .turkish: "Parçalar", .hindi: "पुर्जे"
        ],
        "Sources": [
            .spanish: "Fuentes", .french: "Sources", .german: "Quellen", .russian: "Источники", .portuguese: "Fontes", .chinese: "来源", .turkish: "Kaynaklar", .hindi: "स्रोत"
        ],
        "Stores": [
            .spanish: "Tiendas", .french: "Magasins", .german: "Geschäfte", .russian: "Магазины", .portuguese: "Lojas", .chinese: "商店", .turkish: "Mağazalar", .hindi: "स्टोर"
        ],
        "Newest": [
            .spanish: "Más reciente", .french: "Plus récent", .german: "Neueste", .russian: "Новейшие", .portuguese: "Mais recente", .chinese: "最新", .turkish: "En yeni", .hindi: "नवीनतम"
        ],
        "Patrol generations": [
            .spanish: "Generaciones Patrol", .french: "Générations Patrol", .german: "Patrol-Generationen", .russian: "Поколения Patrol", .portuguese: "Gerações Patrol", .chinese: "Patrol 世代", .turkish: "Patrol nesilleri", .hindi: "पेट्रोल जेनरेशन"
        ],

        // MARK: Search result reasons (Phase 1 badges)
        "Number match": [
            .spanish: "Coincidencia de número", .french: "Correspondance de numéro", .german: "Nummernübereinstimmung", .russian: "Совпадение по номеру", .portuguese: "Correspondência de número", .chinese: "编号匹配", .turkish: "Numara eşleşmesi", .hindi: "नंबर मिलान"
        ],
        "Description match": [
            .spanish: "Coincidencia de descripción", .french: "Correspondance de description", .german: "Beschreibungsübereinstimmung", .russian: "Совпадение по описанию", .portuguese: "Correspondência de descrição", .chinese: "描述匹配", .turkish: "Açıklama eşleşmesi", .hindi: "विवरण मिलान"
        ],
        "Fits your vehicle": [
            .spanish: "Compatible con tu vehículo", .french: "Compatible avec votre véhicule", .german: "Passt zu Ihrem Fahrzeug", .russian: "Подходит вашему автомобилю", .portuguese: "Compatível com seu veículo", .chinese: "适合您的车辆", .turkish: "Aracınıza uygun", .hindi: "आपके वाहन के लिए उपयुक्त"
        ]
    ]
}
