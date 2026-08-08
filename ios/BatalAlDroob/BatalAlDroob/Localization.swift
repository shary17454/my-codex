import Foundation

/// Interface translations for the languages beyond Arabic and English.
///
/// Design note: the app states every user-facing string inline as an Arabic/English
/// pair via `CatalogViewModel.text(ar:en:)`. Rather than rewrite ~340 call sites into
/// key lookups, this table is keyed by the **English** string already present at each
/// call site, so adding a language never touches the views.
///
/// Coverage: every static (non-interpolated) interface string the app can show is
/// translated here. Strings that build their text with interpolation — counters such as
/// "1,204 linked records" — are not table keys, because the key would have to be the
/// already-formatted result; those fall back to English, which is the working second
/// language across Gulf workshops and the parts trade.
///
/// Catalog part names are **not** translated: the source catalogs publish them in
/// Arabic and English only, and OEM part numbers are language-neutral by definition.
/// The product name "Batal Al-Droob" is a brand and is deliberately left untranslated.
enum BatalLocalization {
    /// Returns the localized interface string for `language`, or nil when the app
    /// should fall back to the English text supplied at the call site.
    static func translate(_ englishKey: String, to language: AppLanguage) -> String? {
        table[englishKey]?[language]
    }

    /// Resolves an inline Arabic/English pair for `language`.
    ///
    /// Every type that renders interface text calls this. Writing
    /// `language == .arabic ? ar : en` at a call site instead silently opts that string
    /// out of the table, which is how the search-reason badges, the category names, and
    /// the request-validation messages stayed English in the eight non-Arabic languages
    /// even though the table already carried their translations.
    ///
    /// Do **not** use this for catalog data — part names, store names, and OEM numbers
    /// come from the source catalogs in Arabic/English only and are not interface text.
    static func resolve(_ language: AppLanguage, ar arabic: String, en english: String) -> String {
        switch language {
        case .arabic: arabic
        case .english: english
        default: translate(english, to: language) ?? english
        }
    }

    /// Number of interface strings translated for each non-default language.
    static var translatedStringCount: Int { table.count }

    /// Languages this table carries entries for: everything except the two languages
    /// whose text is written inline at the call site.
    static var coveredLanguages: [AppLanguage] {
        AppLanguage.allCases.filter { $0 != .arabic && $0 != .english }
    }

    /// The full table, assembled from four section tables. It is split because a single
    /// literal this size is both a lint violation and slow for the type checker; the
    /// sections have no overlapping keys, so the merge order does not matter.
    private static let table: [String: [AppLanguage: String]] = BatalNavigationStrings.entries
        .merging(BatalLabelAndSearchStrings.entries) { current, _ in current }
        .merging(BatalStateStrings.entries) { current, _ in current }
        .merging(BatalWorkflowStrings.entries) { current, _ in current }
}

// MARK: - Tabs, navigation, and common actions

private enum BatalNavigationStrings {
    static let entries: [String: [AppLanguage: String]] = [
        "Home": [
            .spanish: "Inicio", .french: "Accueil", .german: "Startseite", .russian: "Главная", .portuguese: "Início", .chinese: "首页", .turkish: "Ana Sayfa", .hindi: "होम"
        ],
        "Catalog": [
            .spanish: "Catálogo", .french: "Catalogue", .german: "Katalog", .russian: "Каталог", .portuguese: "Catálogo", .chinese: "目录", .turkish: "Katalog", .hindi: "कैटलॉग"
        ],
        "Assistant": [
            .spanish: "Asistente", .french: "Assistant", .german: "Assistent", .russian: "Помощник",
            .portuguese: "Assistente", .chinese: "助手", .turkish: "Asistan", .hindi: "सहायक"
        ],
        "Request": [
            .spanish: "Solicitud", .french: "Demande", .german: "Anfrage", .russian: "Запрос", .portuguese: "Solicitação", .chinese: "请求", .turkish: "Talep", .hindi: "अनुरोध"
        ],
        "Tools": [
            .spanish: "Herramientas", .french: "Outils", .german: "Werkzeuge", .russian: "Инструменты",
            .portuguese: "Ferramentas", .chinese: "工具", .turkish: "Araçlar", .hindi: "उपकरण"
        ],
        "More": [
            .spanish: "Más", .french: "Plus", .german: "Mehr", .russian: "Ещё", .portuguese: "Mais", .chinese: "更多", .turkish: "Daha Fazla", .hindi: "और"
        ],
        "Maintenance": [
            .spanish: "Mantenimiento", .french: "Entretien", .german: "Wartung", .russian: "Обслуживание",
            .portuguese: "Manutenção", .chinese: "保养", .turkish: "Bakım", .hindi: "रखरखाव"
        ],
        "Maintenance log": [
            .spanish: "Registro de mantenimiento", .french: "Journal d'entretien", .german: "Wartungsprotokoll",
            .russian: "Журнал обслуживания", .portuguese: "Registro de manutenção", .chinese: "保养记录", .turkish: "Bakım kaydı", .hindi: "रखरखाव लॉग"
        ],
        "Catalog library": [
            .spanish: "Biblioteca de catálogos", .french: "Bibliothèque du catalogue", .german: "Katalogbibliothek",
            .russian: "Библиотека каталогов", .portuguese: "Biblioteca de catálogos", .chinese: "目录库", .turkish: "Katalog kitaplığı", .hindi: "कैटलॉग लाइब्रेरी"
        ],
        "Original catalogs": [
            .spanish: "Catálogos originales", .french: "Catalogues d'origine", .german: "Originalkataloge",
            .russian: "Оригинальные каталоги", .portuguese: "Catálogos originais", .chinese: "原版目录", .turkish: "Orijinal kataloglar", .hindi: "मूल कैटलॉग"
        ],
        "Original catalog library": [
            .spanish: "Biblioteca de catálogos originales", .french: "Bibliothèque des catalogues d'origine",
            .german: "Bibliothek der Originalkataloge", .russian: "Библиотека оригинальных каталогов", .portuguese: "Biblioteca de catálogos originais", .chinese: "原版目录库",
            .turkish: "Orijinal katalog kitaplığı", .hindi: "मूल कैटलॉग लाइब्रेरी"
        ],
        "Shared fitment": [
            .spanish: "Compatibilidad compartida", .french: "Compatibilité partagée", .german: "Gemeinsame Passform",
            .russian: "Общая совместимость", .portuguese: "Compatibilidade compartilhada", .chinese: "通用适配", .turkish: "Ortak uyum", .hindi: "साझा फिटमेंट"
        ],
        "Fitment check": [
            .spanish: "Verificación de compatibilidad", .french: "Vérification de compatibilité", .german: "Passform prüfen", .russian: "Проверка совместимости",
            .portuguese: "Verificação de compatibilidade", .chinese: "适配检查", .turkish: "Uyum kontrolü", .hindi: "फिटमेंट जांच"
        ],
        "Smart search": [
            .spanish: "Búsqueda inteligente", .french: "Recherche intelligente", .german: "Intelligente Suche",
            .russian: "Умный поиск", .portuguese: "Busca inteligente", .chinese: "智能搜索", .turkish: "Akıllı arama", .hindi: "स्मार्ट खोज"
        ],
        "Part request": [
            .spanish: "Solicitud de pieza", .french: "Demande de pièce", .german: "Teileanfrage",
            .russian: "Запрос детали", .portuguese: "Solicitação de peça", .chinese: "配件请求", .turkish: "Parça talebi", .hindi: "पुर्जे का अनुरोध"
        ],
        "Back to Home": [
            .spanish: "Volver al inicio", .french: "Retour à l'accueil", .german: "Zurück zur Startseite",
            .russian: "Назад на главную", .portuguese: "Voltar ao início", .chinese: "返回首页", .turkish: "Ana sayfaya dön", .hindi: "होम पर वापस"
        ],
        "Quick paths": [
            .spanish: "Accesos rápidos", .french: "Accès rapides", .german: "Schnellzugriffe", .russian: "Быстрые переходы", .portuguese: "Atalhos", .chinese: "快捷入口",
            .turkish: "Hızlı yollar", .hindi: "त्वरित रास्ते"
        ],
        "Action center": [
            .spanish: "Centro de acciones", .french: "Centre d'actions", .german: "Aktionszentrum",
            .russian: "Центр действий", .portuguese: "Central de ações", .chinese: "操作中心", .turkish: "İşlem merkezi", .hindi: "एक्शन सेंटर"
        ],
        "Start quickly": [
            .spanish: "Empieza rápido", .french: "Démarrer rapidement", .german: "Schnell starten", .russian: "Быстрый старт", .portuguese: "Comece rápido", .chinese: "快速开始",
            .turkish: "Hızlı başla", .hindi: "जल्दी शुरू करें"
        ],

        // MARK: - Common actions

        "OK": [
            .spanish: "Aceptar", .french: "OK", .german: "OK", .russian: "ОК", .portuguese: "OK", .chinese: "确定", .turkish: "Tamam", .hindi: "ठीक है"
        ],
        "Done": [
            .spanish: "Listo", .french: "Terminé", .german: "Fertig", .russian: "Готово", .portuguese: "Concluído", .chinese: "完成", .turkish: "Bitti", .hindi: "पूर्ण"
        ],
        "Save": [
            .spanish: "Guardar", .french: "Enregistrer", .german: "Sichern", .russian: "Сохранить", .portuguese: "Salvar", .chinese: "保存", .turkish: "Kaydet", .hindi: "सहेजें"
        ],
        "Dismiss": [
            .spanish: "Cerrar", .french: "Fermer", .german: "Schließen", .russian: "Закрыть", .portuguese: "Fechar", .chinese: "关闭", .turkish: "Kapat", .hindi: "बंद करें"
        ],
        "Retry": [
            .spanish: "Reintentar", .french: "Réessayer", .german: "Erneut versuchen", .russian: "Повторить",
            .portuguese: "Tentar novamente", .chinese: "重试", .turkish: "Tekrar Dene", .hindi: "पुनः प्रयास करें"
        ],
        "Notice": [
            .spanish: "Aviso", .french: "Avis", .german: "Hinweis", .russian: "Уведомление", .portuguese: "Aviso", .chinese: "提示", .turkish: "Bildirim", .hindi: "सूचना"
        ],
        "Open catalog": [
            .spanish: "Abrir catálogo", .french: "Ouvrir le catalogue", .german: "Katalog öffnen",
            .russian: "Открыть каталог", .portuguese: "Abrir catálogo", .chinese: "打开目录", .turkish: "Kataloğu aç", .hindi: "कैटलॉग खोलें"
        ],
        "Open tools": [
            .spanish: "Abrir herramientas", .french: "Ouvrir les outils", .german: "Werkzeuge öffnen",
            .russian: "Открыть инструменты", .portuguese: "Abrir ferramentas", .chinese: "打开工具", .turkish: "Araçları aç", .hindi: "उपकरण खोलें"
        ],
        "Check now": [
            .spanish: "Comprobar ahora", .french: "Vérifier maintenant", .german: "Jetzt prüfen",
            .russian: "Проверить сейчас", .portuguese: "Verificar agora", .chinese: "立即检查", .turkish: "Şimdi kontrol et", .hindi: "अभी जांचें"
        ],
        "Search the catalog": [
            .spanish: "Buscar en el catálogo", .french: "Rechercher dans le catalogue", .german: "Katalog durchsuchen", .russian: "Поиск в каталоге",
            .portuguese: "Pesquisar no catálogo", .chinese: "搜索目录", .turkish: "Katalogda ara", .hindi: "कैटलॉग में खोजें"
        ],
        "Search by description": [
            .spanish: "Buscar por descripción", .french: "Rechercher par description", .german: "Nach Beschreibung suchen", .russian: "Поиск по описанию",
            .portuguese: "Buscar por descrição", .chinese: "按描述搜索", .turkish: "Açıklamaya göre ara", .hindi: "विवरण से खोजें"
        ],
        "Change language": [
            .spanish: "Cambiar idioma", .french: "Changer de langue", .german: "Sprache ändern", .russian: "Сменить язык", .portuguese: "Alterar idioma", .chinese: "更改语言",
            .turkish: "Dili değiştir", .hindi: "भाषा बदलें"
        ],
        "Language": [
            .spanish: "Idioma", .french: "Langue", .german: "Sprache", .russian: "Язык", .portuguese: "Idioma", .chinese: "语言", .turkish: "Dil", .hindi: "भाषा"
        ],
        "Calculate difference": [
            .spanish: "Calcular diferencia", .french: "Calculer la différence", .german: "Differenz berechnen",
            .russian: "Рассчитать разницу", .portuguese: "Calcular diferença", .chinese: "计算差值", .turkish: "Farkı hesapla", .hindi: "अंतर की गणना करें"
        ],
        "Share file": [
            .spanish: "Compartir archivo", .french: "Partager le fichier", .german: "Datei teilen",
            .russian: "Поделиться файлом", .portuguese: "Compartilhar arquivo", .chinese: "共享文件", .turkish: "Dosyayı paylaş", .hindi: "फ़ाइल साझा करें"
        ],
        "Share part request": [
            .spanish: "Compartir solicitud de pieza", .french: "Partager la demande de pièce", .german: "Teileanfrage teilen", .russian: "Поделиться запросом детали",
            .portuguese: "Compartilhar solicitação de peça", .chinese: "分享配件请求", .turkish: "Parça talebini paylaş", .hindi: "पुर्जा अनुरोध साझा करें"
        ],
        "Send question": [
            .spanish: "Enviar pregunta", .french: "Envoyer la question", .german: "Frage senden",
            .russian: "Отправить вопрос", .portuguese: "Enviar pergunta", .chinese: "发送问题", .turkish: "Soruyu gönder", .hindi: "प्रश्न भेजें"
        ],
        "Capture part or number": [
            .spanish: "Fotografiar la pieza o el número", .french: "Photographier la pièce ou le numéro",
            .german: "Teil oder Nummer aufnehmen", .russian: "Снять деталь или номер", .portuguese: "Fotografar peça ou número", .chinese: "拍摄配件或编号",
            .turkish: "Parçayı veya numarayı çek", .hindi: "पुर्जा या नंबर कैप्चर करें"
        ],
        "Choose reference photo": [
            .spanish: "Elegir foto de referencia", .french: "Choisir une photo de référence", .german: "Referenzfoto wählen", .russian: "Выбрать образец фото",
            .portuguese: "Escolher foto de referência", .chinese: "选择参考照片", .turkish: "Referans fotoğraf seç", .hindi: "संदर्भ फ़ोटो चुनें"
        ]
    ]
}

// MARK: - Counters, fields, search, and fitment

private enum BatalLabelAndSearchStrings {
    static let entries: [String: [AppLanguage: String]] = [
        "Parts": [
            .spanish: "Piezas", .french: "Pièces", .german: "Teile", .russian: "Детали", .portuguese: "Peças", .chinese: "配件", .turkish: "Parçalar", .hindi: "पुर्जे"
        ],
        "Indexed parts": [
            .spanish: "Piezas indexadas", .french: "Pièces indexées", .german: "Indizierte Teile",
            .russian: "Проиндексированные детали", .portuguese: "Peças indexadas", .chinese: "已索引配件",
            .turkish: "Dizinlenen parçalar", .hindi: "अनुक्रमित पुर्जे"
        ],
        "Sources": [
            .spanish: "Fuentes", .french: "Sources", .german: "Quellen", .russian: "Источники",
            .portuguese: "Fontes", .chinese: "来源", .turkish: "Kaynaklar", .hindi: "स्रोत"
        ],
        "Records": [
            .spanish: "Registros", .french: "Enregistrements", .german: "Datensätze", .russian: "Записи",
            .portuguese: "Registros", .chinese: "记录", .turkish: "Kayıtlar", .hindi: "रिकॉर्ड"
        ],
        "Stores": [
            .spanish: "Tiendas", .french: "Magasins", .german: "Geschäfte", .russian: "Магазины",
            .portuguese: "Lojas", .chinese: "商店", .turkish: "Mağazalar", .hindi: "स्टोर"
        ],
        "Verified stores": [
            .spanish: "Tiendas verificadas", .french: "Magasins vérifiés", .german: "Geprüfte Geschäfte",
            .russian: "Проверенные магазины", .portuguese: "Lojas verificadas", .chinese: "认证商店",
            .turkish: "Doğrulanmış mağazalar", .hindi: "सत्यापित स्टोर"
        ],
        "Files": [
            .spanish: "Archivos", .french: "Fichiers", .german: "Dateien", .russian: "Файлы",
            .portuguese: "Arquivos", .chinese: "文件", .turkish: "Dosyalar", .hindi: "फ़ाइलें"
        ],
        "Results": [
            .spanish: "Resultados", .french: "Résultats", .german: "Ergebnisse", .russian: "Результаты",
            .portuguese: "Resultados", .chinese: "结果", .turkish: "Sonuçlar", .hindi: "परिणाम"
        ],
        "Wishlist": [
            .spanish: "Favoritos", .french: "Favoris", .german: "Merkliste", .russian: "Избранное",
            .portuguese: "Favoritos", .chinese: "收藏", .turkish: "İstek listesi", .hindi: "इच्छा-सूची"
        ],
        "Newest": [
            .spanish: "Más reciente", .french: "Plus récent", .german: "Neueste", .russian: "Новейшие",
            .portuguese: "Mais recente", .chinese: "最新", .turkish: "En yeni", .hindi: "नवीनतम"
        ],
        "Patrol generations": [
            .spanish: "Generaciones Patrol", .french: "Générations Patrol", .german: "Patrol-Generationen",
            .russian: "Поколения Patrol", .portuguese: "Gerações Patrol", .chinese: "Patrol 世代",
            .turkish: "Patrol nesilleri", .hindi: "पेट्रोल जेनरेशन"
        ],
        "Generation": [
            .spanish: "Generación", .french: "Génération", .german: "Generation", .russian: "Поколение",
            .portuguese: "Geração", .chinese: "世代", .turkish: "Nesil", .hindi: "जेनरेशन"
        ],
        "All": [
            .spanish: "Todo", .french: "Tout", .german: "Alle", .russian: "Все",
            .portuguese: "Tudo", .chinese: "全部", .turkish: "Tümü", .hindi: "सभी"
        ],
        "General": [
            .spanish: "General", .french: "Général", .german: "Allgemein", .russian: "Общее",
            .portuguese: "Geral", .chinese: "通用", .turkish: "Genel", .hindi: "सामान्य"
        ],
        "Cooling": [
            .spanish: "Refrigeración", .french: "Refroidissement", .german: "Kühlung", .russian: "Охлаждение",
            .portuguese: "Arrefecimento", .chinese: "冷却", .turkish: "Soğutma", .hindi: "कूलिंग"
        ],
        "Electrical": [
            .spanish: "Eléctrico", .french: "Électricité", .german: "Elektrik", .russian: "Электрика",
            .portuguese: "Elétrica", .chinese: "电气", .turkish: "Elektrik", .hindi: "इलेक्ट्रिकल"
        ],
        "Body": [
            .spanish: "Carrocería", .french: "Carrosserie", .german: "Karosserie", .russian: "Кузов",
            .portuguese: "Carroceria", .chinese: "车身", .turkish: "Kaporta", .hindi: "बॉडी"
        ],
        "Brake": [
            .spanish: "Frenos", .french: "Freins", .german: "Bremsen", .russian: "Тормоза",
            .portuguese: "Freios", .chinese: "制动", .turkish: "Fren", .hindi: "ब्रेक"
        ],
        "Suspension": [
            .spanish: "Suspensión", .french: "Suspension", .german: "Fahrwerk", .russian: "Подвеска",
            .portuguese: "Suspensão", .chinese: "悬挂", .turkish: "Süspansiyon", .hindi: "सस्पेंशन"
        ],
        "Drivetrain": [
            .spanish: "Transmisión", .french: "Transmission", .german: "Antriebsstrang",
            .russian: "Трансмиссия", .portuguese: "Transmissão", .chinese: "传动",
            .turkish: "Aktarma organları", .hindi: "ड्राइवट्रेन"
        ],
        "Interior": [
            .spanish: "Interior", .french: "Intérieur", .german: "Innenraum", .russian: "Салон",
            .portuguese: "Interior", .chinese: "内饰", .turkish: "İç donanım", .hindi: "इंटीरियर"
        ],
        "Fuel": [
            .spanish: "Combustible", .french: "Carburant", .german: "Kraftstoff", .russian: "Топливо",
            .portuguese: "Combustível", .chinese: "燃油", .turkish: "Yakıt", .hindi: "ईंधन"
        ],
        "Price score": [
            .spanish: "Puntuación de precio", .french: "Évaluation du prix", .german: "Preisbewertung",
            .russian: "Оценка цены", .portuguese: "Pontuação de preço", .chinese: "价格评分",
            .turkish: "Fiyat puanı", .hindi: "मूल्य स्कोर"
        ],
        "Price fairness": [
            .spanish: "Equidad del precio", .french: "Équité du prix", .german: "Preisfairness",
            .russian: "Справедливость цены", .portuguese: "Justiça do preço", .chinese: "价格合理性",
            .turkish: "Fiyat adaleti", .hindi: "मूल्य निष्पक्षता"
        ],
        "Fitment match": [
            .spanish: "Compatibilidad", .french: "Compatibilité", .german: "Passform",
            .russian: "Совместимость", .portuguese: "Compatibilidade", .chinese: "适配度",
            .turkish: "Uyum", .hindi: "फिटमेंट"
        ],
        "Confidence": [
            .spanish: "Confianza", .french: "Confiance", .german: "Verlässlichkeit", .russian: "Достоверность",
            .portuguese: "Confiança", .chinese: "可信度", .turkish: "Güven", .hindi: "विश्वसनीयता"
        ],
        "Unlock one catalog page": [
            .spanish: "Desbloquear una página del catálogo", .french: "Débloquer une page du catalogue",
            .german: "Eine Katalogseite freischalten", .russian: "Открыть одну страницу каталога",
            .portuguese: "Desbloquear uma página do catálogo", .chinese: "解锁一页目录",
            .turkish: "Bir katalog sayfasını aç", .hindi: "एक कैटलॉग पृष्ठ अनलॉक करें"
        ],
        "Unlock full catalog": [
            .spanish: "Desbloquear el catálogo completo", .french: "Débloquer tout le catalogue",
            .german: "Vollständigen Katalog freischalten", .russian: "Открыть весь каталог",
            .portuguese: "Desbloquear o catálogo completo", .chinese: "解锁完整目录",
            .turkish: "Tüm kataloğu aç", .hindi: "पूरा कैटलॉग अनलॉक करें"
        ],
        "Category": [
            .spanish: "Categoría", .french: "Catégorie", .german: "Kategorie", .russian: "Категория",
            .portuguese: "Categoria", .chinese: "类别", .turkish: "Kategori", .hindi: "श्रेणी"
        ],
        "Information": [
            .spanish: "Información", .french: "Informations", .german: "Informationen", .russian: "Информация",
            .portuguese: "Informações", .chinese: "信息", .turkish: "Bilgi", .hindi: "जानकारी"
        ],
        "Model": [
            .spanish: "Modelo", .french: "Modèle", .german: "Modell", .russian: "Модель",
            .portuguese: "Modelo", .chinese: "型号", .turkish: "Model", .hindi: "मॉडल"
        ],
        "Years": [
            .spanish: "Años", .french: "Années", .german: "Jahre", .russian: "Годы",
            .portuguese: "Anos", .chinese: "年份", .turkish: "Yıllar", .hindi: "वर्ष"
        ],
        "Year": [
            .spanish: "Año", .french: "Année", .german: "Jahr", .russian: "Год",
            .portuguese: "Ano", .chinese: "年份", .turkish: "Yıl", .hindi: "वर्ष"
        ],
        "Engine": [
            .spanish: "Motor", .french: "Moteur", .german: "Motor", .russian: "Двигатель",
            .portuguese: "Motor", .chinese: "发动机", .turkish: "Motor", .hindi: "इंजन"
        ],
        "Engines": [
            .spanish: "Motores", .french: "Moteurs", .german: "Motoren", .russian: "Двигатели",
            .portuguese: "Motores", .chinese: "发动机", .turkish: "Motorlar", .hindi: "इंजन"
        ],
        "Transmission": [
            .spanish: "Transmisión", .french: "Boîte de vitesses", .german: "Getriebe", .russian: "Коробка передач",
            .portuguese: "Transmissão", .chinese: "变速箱", .turkish: "Şanzıman", .hindi: "ट्रांसमिशन"
        ],
        "Audit": [
            .spanish: "Auditoría", .french: "Audit", .german: "Prüfung", .russian: "Проверка",
            .portuguese: "Auditoria", .chinese: "审核", .turkish: "Denetim", .hindi: "ऑडिट"
        ],
        "Rarity": [
            .spanish: "Rareza", .french: "Rareté", .german: "Seltenheit", .russian: "Редкость",
            .portuguese: "Raridade", .chinese: "稀有度", .turkish: "Nadirlik", .hindi: "दुर्लभता"
        ],
        "Evidence": [
            .spanish: "Evidencia", .french: "Preuves", .german: "Belege", .russian: "Доказательства",
            .portuguese: "Evidências", .chinese: "依据", .turkish: "Kanıt", .hindi: "प्रमाण"
        ],
        "Part": [
            .spanish: "Pieza", .french: "Pièce", .german: "Teil", .russian: "Деталь",
            .portuguese: "Peça", .chinese: "配件", .turkish: "Parça", .hindi: "पुर्जा"
        ],
        "Part number": [
            .spanish: "Número de pieza", .french: "Numéro de pièce", .german: "Teilenummer",
            .russian: "Номер детали", .portuguese: "Número da peça", .chinese: "配件号",
            .turkish: "Parça numarası", .hindi: "पुर्जा नंबर"
        ],
        "Part numbers": [
            .spanish: "Números de pieza", .french: "Numéros de pièce", .german: "Teilenummern",
            .russian: "Номера деталей", .portuguese: "Números da peça", .chinese: "配件号",
            .turkish: "Parça numaraları", .hindi: "पुर्जा नंबर"
        ],
        "Part name": [
            .spanish: "Nombre de la pieza", .french: "Nom de la pièce", .german: "Teilename",
            .russian: "Название детали", .portuguese: "Nome da peça", .chinese: "配件名称",
            .turkish: "Parça adı", .hindi: "पुर्जे का नाम"
        ],
        "Notes": [
            .spanish: "Notas", .french: "Remarques", .german: "Notizen", .russian: "Заметки",
            .portuguese: "Observações", .chinese: "备注", .turkish: "Notlar", .hindi: "टिप्पणियाँ"
        ],
        "Title": [
            .spanish: "Título", .french: "Titre", .german: "Titel", .russian: "Название",
            .portuguese: "Título", .chinese: "标题", .turkish: "Başlık", .hindi: "शीर्षक"
        ],
        "Odometer": [
            .spanish: "Odómetro", .french: "Compteur kilométrique", .german: "Kilometerstand",
            .russian: "Пробег", .portuguese: "Odômetro", .chinese: "里程表",
            .turkish: "Kilometre", .hindi: "ओडोमीटर"
        ],
        "Log": [
            .spanish: "Registro", .french: "Journal", .german: "Protokoll", .russian: "Журнал",
            .portuguese: "Registro", .chinese: "记录", .turkish: "Kayıt", .hindi: "लॉग"
        ],
        "Vehicle": [
            .spanish: "Vehículo", .french: "Véhicule", .german: "Fahrzeug", .russian: "Автомобиль",
            .portuguese: "Veículo", .chinese: "车辆", .turkish: "Araç", .hindi: "वाहन"
        ],
        "Vehicle profile": [
            .spanish: "Perfil del vehículo", .french: "Profil du véhicule", .german: "Fahrzeugprofil",
            .russian: "Профиль автомобиля", .portuguese: "Perfil do veículo", .chinese: "车辆资料",
            .turkish: "Araç profili", .hindi: "वाहन प्रोफ़ाइल"
        ],
        "My vehicle": [
            .spanish: "Mi vehículo", .french: "Mon véhicule", .german: "Mein Fahrzeug", .russian: "Мой автомобиль",
            .portuguese: "Meu veículo", .chinese: "我的车辆", .turkish: "Aracım", .hindi: "मेरा वाहन"
        ],
        "Account": [
            .spanish: "Cuenta", .french: "Compte", .german: "Konto", .russian: "Аккаунт",
            .portuguese: "Conta", .chinese: "账户", .turkish: "Hesap", .hindi: "खाता"
        ],
        "Email": [
            .spanish: "Correo electrónico", .french: "E-mail", .german: "E-Mail", .russian: "Эл. почта",
            .portuguese: "E-mail", .chinese: "电子邮件", .turkish: "E-posta", .hindi: "ईमेल"
        ],
        "Email address": [
            .spanish: "Dirección de correo", .french: "Adresse e-mail", .german: "E-Mail-Adresse",
            .russian: "Адрес эл. почты", .portuguese: "Endereço de e-mail", .chinese: "电子邮件地址",
            .turkish: "E-posta adresi", .hindi: "ईमेल पता"
        ],
        "Name optional": [
            .spanish: "Nombre (opcional)", .french: "Nom (facultatif)", .german: "Name (optional)",
            .russian: "Имя (необязательно)", .portuguese: "Nome (opcional)", .chinese: "姓名（可选）",
            .turkish: "Ad (isteğe bağlı)", .hindi: "नाम (वैकल्पिक)"
        ],
        "Plan": [
            .spanish: "Plan", .french: "Formule", .german: "Variante", .russian: "Тип",
            .portuguese: "Plano", .chinese: "方案", .turkish: "Plan", .hindi: "योजना"
        ],
        "Request type": [
            .spanish: "Tipo de solicitud", .french: "Type de demande", .german: "Anfrageart",
            .russian: "Тип запроса", .portuguese: "Tipo de solicitação", .chinese: "请求类型",
            .turkish: "Talep türü", .hindi: "अनुरोध का प्रकार"
        ],
        "Request preview": [
            .spanish: "Vista previa de la solicitud", .french: "Aperçu de la demande", .german: "Anfragevorschau",
            .russian: "Предпросмотр запроса", .portuguese: "Prévia da solicitação", .chinese: "请求预览",
            .turkish: "Talep önizlemesi", .hindi: "अनुरोध पूर्वावलोकन"
        ],
        "Saved requests": [
            .spanish: "Solicitudes guardadas", .french: "Demandes enregistrées", .german: "Gespeicherte Anfragen",
            .russian: "Сохранённые запросы", .portuguese: "Solicitações salvas", .chinese: "已保存的请求",
            .turkish: "Kaydedilen talepler", .hindi: "सहेजे गए अनुरोध"
        ],
        "Owner": [
            .spanish: "Propietario", .french: "Propriétaire", .german: "Inhaber", .russian: "Владелец",
            .portuguese: "Proprietário", .chinese: "所有者", .turkish: "Sahip", .hindi: "स्वामी"
        ],
        "Data policy": [
            .spanish: "Política de datos", .french: "Politique de données", .german: "Datenrichtlinie",
            .russian: "Политика данных", .portuguese: "Política de dados", .chinese: "数据政策",
            .turkish: "Veri politikası", .hindi: "डेटा नीति"
        ],
        "Tire calculator": [
            .spanish: "Calculadora de neumáticos", .french: "Calculateur de pneus", .german: "Reifenrechner",
            .russian: "Калькулятор шин", .portuguese: "Calculadora de pneus", .chinese: "轮胎计算器",
            .turkish: "Lastik hesaplayıcı", .hindi: "टायर कैलकुलेटर"
        ],
        "Old size": [
            .spanish: "Medida anterior", .french: "Ancienne taille", .german: "Alte Größe", .russian: "Старый размер",
            .portuguese: "Medida antiga", .chinese: "原尺寸", .turkish: "Eski ölçü", .hindi: "पुराना आकार"
        ],
        "New size": [
            .spanish: "Medida nueva", .french: "Nouvelle taille", .german: "Neue Größe", .russian: "Новый размер",
            .portuguese: "Medida nova", .chinese: "新尺寸", .turkish: "Yeni ölçü", .hindi: "नया आकार"
        ],
        "Enter size as 265/70R16": [
            .spanish: "Introduce la medida como 265/70R16", .french: "Saisissez la taille au format 265/70R16",
            .german: "Größe im Format 265/70R16 eingeben", .russian: "Укажите размер в виде 265/70R16",
            .portuguese: "Informe a medida como 265/70R16", .chinese: "请按 265/70R16 格式输入尺寸",
            .turkish: "Ölçüyü 265/70R16 biçiminde girin", .hindi: "आकार 265/70R16 के रूप में दर्ज करें"
        ],
        "Difference %.1f%%": [
            .spanish: "Diferencia %.1f%%", .french: "Différence %.1f%%", .german: "Differenz %.1f%%",
            .russian: "Разница %.1f%%", .portuguese: "Diferença %.1f%%", .chinese: "差值 %.1f%%",
            .turkish: "Fark %.1f%%", .hindi: "अंतर %.1f%%"
        ],

        // MARK: - Search, catalog, and fitment

        "Part number or description": [
            .spanish: "Número o descripción de la pieza", .french: "Numéro ou description de pièce",
            .german: "Teilenummer oder Beschreibung", .russian: "Номер детали или описание",
            .portuguese: "Número ou descrição da peça", .chinese: "配件号或描述",
            .turkish: "Parça numarası veya açıklama", .hindi: "पुर्जा नंबर या विवरण"
        ],
        "Part number, name, category, or VIN": [
            .spanish: "Número, nombre, categoría o VIN", .french: "Numéro, nom, catégorie ou VIN",
            .german: "Nummer, Name, Kategorie oder VIN", .russian: "Номер, название, категория или VIN",
            .portuguese: "Número, nome, categoria ou VIN", .chinese: "配件号、名称、类别或 VIN",
            .turkish: "Numara, ad, kategori veya VIN", .hindi: "नंबर, नाम, श्रेणी या VIN"
        ],
        "Part number, description, year, or engine": [
            .spanish: "Número, descripción, año o motor", .french: "Numéro, description, année ou moteur",
            .german: "Nummer, Beschreibung, Jahr oder Motor", .russian: "Номер, описание, год или двигатель",
            .portuguese: "Número, descrição, ano ou motor", .chinese: "配件号、描述、年份或发动机",
            .turkish: "Numara, açıklama, yıl veya motor", .hindi: "नंबर, विवरण, वर्ष या इंजन"
        ],
        "Year, engine, model, or filename": [
            .spanish: "Año, motor, modelo o nombre de archivo", .french: "Année, moteur, modèle ou nom de fichier",
            .german: "Jahr, Motor, Modell oder Dateiname", .russian: "Год, двигатель, модель или имя файла",
            .portuguese: "Ano, motor, modelo ou nome do arquivo", .chinese: "年份、发动机、型号或文件名",
            .turkish: "Yıl, motor, model veya dosya adı", .hindi: "वर्ष, इंजन, मॉडल या फ़ाइल नाम"
        ],
        "Describe the fault or part": [
            .spanish: "Describe la avería o la pieza", .french: "Décrivez la panne ou la pièce",
            .german: "Fehler oder Teil beschreiben", .russian: "Опишите неисправность или деталь",
            .portuguese: "Descreva o problema ou a peça", .chinese: "描述故障或配件",
            .turkish: "Arızayı veya parçayı tanımlayın", .hindi: "खराबी या पुर्जे का वर्णन करें"
        ],
        "Description and photo search": [
            .spanish: "Búsqueda por descripción y foto", .french: "Recherche par description et photo",
            .german: "Suche per Beschreibung und Foto", .russian: "Поиск по описанию и фото",
            .portuguese: "Busca por descrição e foto", .chinese: "按描述和照片搜索",
            .turkish: "Açıklama ve fotoğrafla arama", .hindi: "विवरण और फ़ोटो से खोज"
        ],
        "Fast local catalog": [
            .spanish: "Catálogo local rápido", .french: "Catalogue local rapide", .german: "Schneller lokaler Katalog",
            .russian: "Быстрый локальный каталог", .portuguese: "Catálogo local rápido", .chinese: "快速本地目录",
            .turkish: "Hızlı yerel katalog", .hindi: "तेज़ स्थानीय कैटलॉग"
        ],
        "Native catalog dashboard": [
            .spanish: "Panel del catálogo nativo", .french: "Tableau de bord du catalogue natif",
            .german: "Übersicht des nativen Katalogs", .russian: "Панель локального каталога",
            .portuguese: "Painel do catálogo nativo", .chinese: "本地目录面板",
            .turkish: "Yerel katalog panosu", .hindi: "नेटिव कैटलॉग डैशबोर्ड"
        ],
        "Verified native records": [
            .spanish: "Registros verificados", .french: "Enregistrements vérifiés", .german: "Geprüfte Datensätze",
            .russian: "Проверенные записи", .portuguese: "Registros verificados", .chinese: "已验证记录",
            .turkish: "Doğrulanmış kayıtlar", .hindi: "सत्यापित रिकॉर्ड"
        ],
        "Quick fitment check": [
            .spanish: "Verificación rápida de compatibilidad", .french: "Vérification rapide de compatibilité",
            .german: "Schnelle Passformprüfung", .russian: "Быстрая проверка совместимости",
            .portuguese: "Verificação rápida de compatibilidade", .chinese: "快速适配检查",
            .turkish: "Hızlı uyum kontrolü", .hindi: "त्वरित फिटमेंट जांच"
        ],
        "Filter results by my vehicle": [
            .spanish: "Filtrar resultados por mi vehículo", .french: "Filtrer les résultats par mon véhicule",
            .german: "Ergebnisse nach meinem Fahrzeug filtern", .russian: "Фильтровать по моему автомобилю",
            .portuguese: "Filtrar resultados pelo meu veículo", .chinese: "按我的车辆筛选结果",
            .turkish: "Sonuçları aracıma göre filtrele", .hindi: "मेरे वाहन के अनुसार परिणाम फ़िल्टर करें"
        ],
        "Edit vehicle details": [
            .spanish: "Editar datos del vehículo", .french: "Modifier les détails du véhicule",
            .german: "Fahrzeugdaten bearbeiten", .russian: "Изменить данные автомобиля",
            .portuguese: "Editar dados do veículo", .chinese: "编辑车辆信息",
            .turkish: "Araç bilgilerini düzenle", .hindi: "वाहन विवरण संपादित करें"
        ],
        "Smart indicators": [
            .spanish: "Indicadores inteligentes", .french: "Indicateurs intelligents",
            .german: "Intelligente Indikatoren", .russian: "Умные показатели",
            .portuguese: "Indicadores inteligentes", .chinese: "智能指标",
            .turkish: "Akıllı göstergeler", .hindi: "स्मार्ट संकेतक"
        ],
        "Illustrative part locator": [
            .spanish: "Localizador ilustrativo de la pieza", .french: "Repère illustratif de la pièce",
            .german: "Illustrative Teileposition", .russian: "Иллюстративное указание детали",
            .portuguese: "Localizador ilustrativo da peça", .chinese: "示意配件定位",
            .turkish: "Örnek parça konumu", .hindi: "उदाहरणात्मक पुर्जा लोकेटर"
        ],
        "Parts with more than one verified fitment": [
            .spanish: "Piezas con más de una compatibilidad verificada",
            .french: "Pièces avec plusieurs compatibilités vérifiées",
            .german: "Teile mit mehr als einer geprüften Passform",
            .russian: "Детали с несколькими проверенными применениями",
            .portuguese: "Peças com mais de uma compatibilidade verificada",
            .chinese: "具有多个已验证适配的配件",
            .turkish: "Birden fazla doğrulanmış uyuma sahip parçalar",
            .hindi: "एक से अधिक सत्यापित फिटमेंट वाले पुर्जे"
        ],
        "Match parts with years and engines.": [
            .spanish: "Compara piezas con años y motores.", .french: "Associez les pièces aux années et moteurs.",
            .german: "Teile mit Jahren und Motoren abgleichen.", .russian: "Сопоставьте детали с годами и двигателями.",
            .portuguese: "Combine peças com anos e motores.", .chinese: "将配件与年份和发动机匹配。",
            .turkish: "Parçaları yıl ve motorlarla eşleştirin.", .hindi: "पुर्जों को वर्ष और इंजन से मिलाएँ।"
        ],
        "Fault description or part number.": [
            .spanish: "Descripción de la avería o número de pieza.",
            .french: "Description de la panne ou numéro de pièce.",
            .german: "Fehlerbeschreibung oder Teilenummer.", .russian: "Описание неисправности или номер детали.",
            .portuguese: "Descrição do problema ou número da peça.", .chinese: "故障描述或配件号。",
            .turkish: "Arıza açıklaması veya parça numarası.", .hindi: "खराबी का विवरण या पुर्जा नंबर।"
        ],
        "Jump into the most-used workflows.": [
            .spanish: "Accede a los flujos más usados.", .french: "Accédez aux parcours les plus utilisés.",
            .german: "Direkt zu den meistgenutzten Abläufen.", .russian: "Перейдите к самым частым сценариям.",
            .portuguese: "Acesse os fluxos mais usados.", .chinese: "直达最常用的流程。",
            .turkish: "En çok kullanılan akışlara geçin.", .hindi: "सबसे अधिक उपयोग किए जाने वाले फ़्लो पर जाएँ।"
        ],
        "Fast signals from the bundled database.": [
            .spanish: "Datos rápidos de la base incorporada.", .french: "Indicateurs rapides de la base intégrée.",
            .german: "Schnelle Kennzahlen aus der integrierten Datenbank.",
            .russian: "Быстрые показатели из встроенной базы.",
            .portuguese: "Sinais rápidos do banco de dados incluído.", .chinese: "来自内置数据库的快速数据。",
            .turkish: "Yerleşik veritabanından hızlı veriler.", .hindi: "अंतर्निहित डेटाबेस से त्वरित संकेत।"
        ],
        "Review-ready records for quick inspection.": [
            .spanish: "Registros listos para revisar rápidamente.", .french: "Enregistrements prêts à être examinés.",
            .german: "Prüfbereite Datensätze für einen schnellen Blick.",
            .russian: "Записи, готовые к быстрой проверке.",
            .portuguese: "Registros prontos para inspeção rápida.", .chinese: "可快速查看的记录。",
            .turkish: "Hızlı inceleme için hazır kayıtlar.", .hindi: "त्वरित जांच के लिए तैयार रिकॉर्ड।"
        ],
        "Check a part number before preparing a request.": [
            .spanish: "Comprueba un número de pieza antes de preparar la solicitud.",
            .french: "Vérifiez un numéro de pièce avant de préparer la demande.",
            .german: "Teilenummer vor der Anfrage prüfen.",
            .russian: "Проверьте номер детали перед созданием запроса.",
            .portuguese: "Verifique um número de peça antes de preparar a solicitação.",
            .chinese: "在准备请求前先核对配件号。",
            .turkish: "Talep hazırlamadan önce parça numarasını kontrol edin.",
            .hindi: "अनुरोध तैयार करने से पहले पुर्जा नंबर जांचें।"
        ],
        "Change the generation or search query.": [
            .spanish: "Cambia la generación o la búsqueda.", .french: "Changez la génération ou la recherche.",
            .german: "Generation oder Suchbegriff ändern.", .russian: "Измените поколение или запрос.",
            .portuguese: "Altere a geração ou a busca.", .chinese: "更换世代或搜索词。",
            .turkish: "Nesli veya arama sorgusunu değiştirin.", .hindi: "जेनरेशन या खोज बदलें।"
        ]
    ]
}

// MARK: - Match reasons, empty states, errors, and progress

private enum BatalStateStrings {
    static let entries: [String: [AppLanguage: String]] = [
        "Number match": [
            .spanish: "Coincidencia de número", .french: "Correspondance de numéro",
            .german: "Nummernübereinstimmung", .russian: "Совпадение по номеру",
            .portuguese: "Correspondência de número", .chinese: "编号匹配",
            .turkish: "Numara eşleşmesi", .hindi: "नंबर मिलान"
        ],
        "Alternate number": [
            .spanish: "Número alternativo", .french: "Numéro alternatif", .german: "Alternative Nummer",
            .russian: "Альтернативный номер", .portuguese: "Número alternativo", .chinese: "替代编号",
            .turkish: "Alternatif numara", .hindi: "वैकल्पिक नंबर"
        ],
        "Partial number": [
            .spanish: "Número parcial", .french: "Numéro partiel", .german: "Teilnummer",
            .russian: "Частичный номер", .portuguese: "Número parcial", .chinese: "部分编号",
            .turkish: "Kısmi numara", .hindi: "आंशिक नंबर"
        ],
        "Close number": [
            .spanish: "Número aproximado", .french: "Numéro proche", .german: "Ähnliche Nummer",
            .russian: "Близкий номер", .portuguese: "Número próximo", .chinese: "相近编号",
            .turkish: "Yakın numara", .hindi: "निकट नंबर"
        ],
        "Description match": [
            .spanish: "Coincidencia de descripción", .french: "Correspondance de description",
            .german: "Beschreibungsübereinstimmung", .russian: "Совпадение по описанию",
            .portuguese: "Correspondência de descrição", .chinese: "描述匹配",
            .turkish: "Açıklama eşleşmesi", .hindi: "विवरण मिलान"
        ],
        "Synonym match": [
            .spanish: "Coincidencia por sinónimo", .french: "Correspondance par synonyme",
            .german: "Synonymübereinstimmung", .russian: "Совпадение по синониму",
            .portuguese: "Correspondência por sinônimo", .chinese: "同义词匹配",
            .turkish: "Eş anlamlı eşleşme", .hindi: "पर्यायवाची मिलान"
        ],
        "Browse": [
            .spanish: "Explorar", .french: "Parcourir", .german: "Durchsuchen", .russian: "Обзор",
            .portuguese: "Navegar", .chinese: "浏览", .turkish: "Gözat", .hindi: "ब्राउज़"
        ],
        "Fits your vehicle": [
            .spanish: "Compatible con tu vehículo", .french: "Compatible avec votre véhicule",
            .german: "Passt zu Ihrem Fahrzeug", .russian: "Подходит вашему автомобилю",
            .portuguese: "Compatível com seu veículo", .chinese: "适合您的车辆",
            .turkish: "Aracınıza uygun", .hindi: "आपके वाहन के लिए उपयुक्त"
        ],
        "Matches your vehicle profile": [
            .spanish: "Coincide con el perfil de tu vehículo", .french: "Correspond au profil de votre véhicule",
            .german: "Passt zu Ihrem Fahrzeugprofil", .russian: "Соответствует профилю вашего автомобиля",
            .portuguese: "Corresponde ao perfil do seu veículo", .chinese: "与您的车辆资料匹配",
            .turkish: "Araç profilinize uyuyor", .hindi: "आपकी वाहन प्रोफ़ाइल से मेल खाता है"
        ],
        "Does not match your current vehicle profile": [
            .spanish: "No coincide con tu perfil de vehículo actual",
            .french: "Ne correspond pas à votre profil de véhicule actuel",
            .german: "Passt nicht zu Ihrem aktuellen Fahrzeugprofil",
            .russian: "Не соответствует текущему профилю автомобиля",
            .portuguese: "Não corresponde ao seu perfil de veículo atual",
            .chinese: "与您当前的车辆资料不匹配",
            .turkish: "Mevcut araç profilinizle eşleşmiyor",
            .hindi: "आपकी मौजूदा वाहन प्रोफ़ाइल से मेल नहीं खाता"
        ],
        "Add your vehicle to evaluate fitment.": [
            .spanish: "Añade tu vehículo para evaluar la compatibilidad.",
            .french: "Ajoutez votre véhicule pour évaluer la compatibilité.",
            .german: "Fügen Sie Ihr Fahrzeug hinzu, um die Passform zu bewerten.",
            .russian: "Добавьте автомобиль, чтобы оценить совместимость.",
            .portuguese: "Adicione seu veículo para avaliar a compatibilidade.",
            .chinese: "添加您的车辆以评估适配性。",
            .turkish: "Uyumu değerlendirmek için aracınızı ekleyin.",
            .hindi: "फिटमेंट का मूल्यांकन करने के लिए अपना वाहन जोड़ें।"
        ],
        "No vehicle selected yet.": [
            .spanish: "Aún no se ha seleccionado un vehículo.", .french: "Aucun véhicule sélectionné pour l'instant.",
            .german: "Noch kein Fahrzeug ausgewählt.", .russian: "Автомобиль ещё не выбран.",
            .portuguese: "Nenhum veículo selecionado ainda.", .chinese: "尚未选择车辆。",
            .turkish: "Henüz araç seçilmedi.", .hindi: "अभी तक कोई वाहन चयनित नहीं है।"
        ],
        "Good match": [
            .spanish: "Buena coincidencia", .french: "Bonne correspondance", .german: "Gute Übereinstimmung",
            .russian: "Хорошее совпадение", .portuguese: "Boa correspondência", .chinese: "匹配良好",
            .turkish: "İyi eşleşme", .hindi: "अच्छा मिलान"
        ],
        "Review fitment": [
            .spanish: "Revisar compatibilidad", .french: "Vérifier la compatibilité", .german: "Passform prüfen",
            .russian: "Проверьте совместимость", .portuguese: "Revisar compatibilidade", .chinese: "请核对适配",
            .turkish: "Uyumu gözden geçirin", .hindi: "फिटमेंट की समीक्षा करें"
        ],
        "Insufficient match": [
            .spanish: "Coincidencia insuficiente", .french: "Correspondance insuffisante",
            .german: "Unzureichende Übereinstimmung", .russian: "Недостаточное совпадение",
            .portuguese: "Correspondência insuficiente", .chinese: "匹配不足",
            .turkish: "Yetersiz eşleşme", .hindi: "अपर्याप्त मिलान"
        ],
        "Insufficient data": [
            .spanish: "Datos insuficientes", .french: "Données insuffisantes", .german: "Unzureichende Daten",
            .russian: "Недостаточно данных", .portuguese: "Dados insuficientes", .chinese: "数据不足",
            .turkish: "Yetersiz veri", .hindi: "अपर्याप्त डेटा"
        ],
        "Needs sources": [
            .spanish: "Faltan fuentes", .french: "Sources manquantes", .german: "Quellen erforderlich",
            .russian: "Нужны источники", .portuguese: "Faltam fontes", .chinese: "缺少来源",
            .turkish: "Kaynak gerekiyor", .hindi: "स्रोत आवश्यक"
        ],
        "Unknown": [
            .spanish: "Desconocido", .french: "Inconnu", .german: "Unbekannt", .russian: "Неизвестно",
            .portuguese: "Desconhecido", .chinese: "未知", .turkish: "Bilinmiyor", .hindi: "अज्ञात"
        ],
        "Why this result appears": [
            .spanish: "Por qué aparece este resultado", .french: "Pourquoi ce résultat apparaît",
            .german: "Warum dieses Ergebnis erscheint", .russian: "Почему показан этот результат",
            .portuguese: "Por que este resultado aparece", .chinese: "该结果出现的原因",
            .turkish: "Bu sonuç neden görünüyor", .hindi: "यह परिणाम क्यों दिख रहा है"
        ],
        "Recommended next step": [
            .spanish: "Siguiente paso recomendado", .french: "Étape suivante recommandée",
            .german: "Empfohlener nächster Schritt", .russian: "Рекомендуемый следующий шаг",
            .portuguese: "Próximo passo recomendado", .chinese: "建议的下一步",
            .turkish: "Önerilen sonraki adım", .hindi: "अनुशंसित अगला कदम"
        ],
        "Opens details for this indicator.": [
            .spanish: "Abre los detalles de este indicador.", .french: "Ouvre les détails de cet indicateur.",
            .german: "Öffnet die Details dieses Indikators.", .russian: "Открывает детали этого показателя.",
            .portuguese: "Abre os detalhes deste indicador.", .chinese: "打开该指标的详情。",
            .turkish: "Bu göstergenin ayrıntılarını açar.", .hindi: "इस संकेतक का विवरण खोलता है।"
        ],
        "Opens the related section.": [
            .spanish: "Abre la sección relacionada.", .french: "Ouvre la section correspondante.",
            .german: "Öffnet den zugehörigen Bereich.", .russian: "Открывает связанный раздел.",
            .portuguese: "Abre a seção relacionada.", .chinese: "打开相关部分。",
            .turkish: "İlgili bölümü açar.", .hindi: "संबंधित अनुभाग खोलता है।"
        ],
        "Opens the requested section.": [
            .spanish: "Abre la sección solicitada.", .french: "Ouvre la section demandée.",
            .german: "Öffnet den gewünschten Bereich.", .russian: "Открывает запрошенный раздел.",
            .portuguese: "Abre a seção solicitada.", .chinese: "打开所选部分。",
            .turkish: "İstenen bölümü açar.", .hindi: "अनुरोधित अनुभाग खोलता है।"
        ],

        // MARK: - Empty and error states

        "No results": [
            .spanish: "Sin resultados", .french: "Aucun résultat", .german: "Keine Ergebnisse",
            .russian: "Нет результатов", .portuguese: "Sem resultados", .chinese: "无结果",
            .turkish: "Sonuç yok", .hindi: "कोई परिणाम नहीं"
        ],
        "No matching files": [
            .spanish: "Sin archivos coincidentes", .french: "Aucun fichier correspondant",
            .german: "Keine passenden Dateien", .russian: "Нет подходящих файлов",
            .portuguese: "Nenhum arquivo correspondente", .chinese: "无匹配文件",
            .turkish: "Eşleşen dosya yok", .hindi: "कोई मेल खाती फ़ाइल नहीं"
        ],
        "No detailed evidence": [
            .spanish: "Sin evidencia detallada", .french: "Aucune preuve détaillée",
            .german: "Keine detaillierten Belege", .russian: "Нет подробных данных",
            .portuguese: "Sem evidências detalhadas", .chinese: "无详细依据",
            .turkish: "Ayrıntılı kanıt yok", .hindi: "कोई विस्तृत प्रमाण नहीं"
        ],
        "No stores loaded": [
            .spanish: "No se cargaron tiendas", .french: "Aucun magasin chargé", .german: "Keine Geschäfte geladen",
            .russian: "Магазины не загружены", .portuguese: "Nenhuma loja carregada", .chinese: "未加载商店",
            .turkish: "Mağaza yüklenmedi", .hindi: "कोई स्टोर लोड नहीं हुआ"
        ],
        "No shared-fitment parts": [
            .spanish: "Sin piezas de compatibilidad compartida", .french: "Aucune pièce à compatibilité partagée",
            .german: "Keine Teile mit gemeinsamer Passform", .russian: "Нет деталей с общей совместимостью",
            .portuguese: "Sem peças de compatibilidade compartilhada", .chinese: "无通用适配配件",
            .turkish: "Ortak uyumlu parça yok", .hindi: "कोई साझा-फिटमेंट पुर्जा नहीं"
        ],
        "No saved requests": [
            .spanish: "Sin solicitudes guardadas", .french: "Aucune demande enregistrée",
            .german: "Keine gespeicherten Anfragen", .russian: "Нет сохранённых запросов",
            .portuguese: "Sem solicitações salvas", .chinese: "无已保存的请求",
            .turkish: "Kaydedilen talep yok", .hindi: "कोई सहेजा गया अनुरोध नहीं"
        ],
        "No maintenance yet": [
            .spanish: "Aún sin mantenimiento", .french: "Aucun entretien pour l'instant",
            .german: "Noch keine Wartung", .russian: "Записей об обслуживании пока нет",
            .portuguese: "Ainda sem manutenção", .chinese: "尚无保养记录",
            .turkish: "Henüz bakım yok", .hindi: "अभी तक कोई रखरखाव नहीं"
        ],
        "Wishlist is empty": [
            .spanish: "Los favoritos están vacíos", .french: "Les favoris sont vides", .german: "Merkliste ist leer",
            .russian: "Избранное пусто", .portuguese: "Os favoritos estão vazios", .chinese: "收藏为空",
            .turkish: "İstek listesi boş", .hindi: "इच्छा-सूची खाली है"
        ],
        "Prepared part requests will appear here.": [
            .spanish: "Las solicitudes preparadas aparecerán aquí.",
            .french: "Les demandes préparées apparaîtront ici.",
            .german: "Vorbereitete Anfragen erscheinen hier.", .russian: "Подготовленные запросы появятся здесь.",
            .portuguese: "As solicitações preparadas aparecerão aqui.", .chinese: "已准备的请求将显示在这里。",
            .turkish: "Hazırlanan talepler burada görünür.", .hindi: "तैयार अनुरोध यहाँ दिखाई देंगे।"
        ],
        "Add the first service entry to keep a local vehicle log.": [
            .spanish: "Añade el primer servicio para llevar un registro local del vehículo.",
            .french: "Ajoutez la première intervention pour tenir un journal local du véhicule.",
            .german: "Fügen Sie den ersten Serviceeintrag hinzu, um ein lokales Fahrzeugprotokoll zu führen.",
            .russian: "Добавьте первую запись, чтобы вести локальный журнал автомобиля.",
            .portuguese: "Adicione o primeiro serviço para manter um registro local do veículo.",
            .chinese: "添加第一条保养记录以建立本地车辆日志。",
            .turkish: "Yerel araç kaydı tutmak için ilk servis girişini ekleyin.",
            .hindi: "स्थानीय वाहन लॉग रखने के लिए पहली सर्विस प्रविष्टि जोड़ें।"
        ],
        "No searchable text was found in the photo.": [
            .spanish: "No se encontró texto buscable en la foto.",
            .french: "Aucun texte exploitable n'a été trouvé sur la photo.",
            .german: "Im Foto wurde kein durchsuchbarer Text gefunden.",
            .russian: "На фото не найден текст для поиска.",
            .portuguese: "Nenhum texto pesquisável foi encontrado na foto.",
            .chinese: "照片中未找到可搜索的文字。",
            .turkish: "Fotoğrafta aranabilir metin bulunamadı.",
            .hindi: "फ़ोटो में कोई खोजने योग्य टेक्स्ट नहीं मिला।"
        ],
        "The parts catalog could not be loaded.": [
            .spanish: "No se pudo cargar el catálogo de piezas.",
            .french: "Le catalogue de pièces n'a pas pu être chargé.",
            .german: "Der Teilekatalog konnte nicht geladen werden.",
            .russian: "Не удалось загрузить каталог деталей.",
            .portuguese: "Não foi possível carregar o catálogo de peças.",
            .chinese: "无法加载配件目录。",
            .turkish: "Parça kataloğu yüklenemedi.",
            .hindi: "पुर्जा कैटलॉग लोड नहीं हो सका।"
        ],
        "The store directory could not be loaded.": [
            .spanish: "No se pudo cargar el directorio de tiendas.",
            .french: "L'annuaire des magasins n'a pas pu être chargé.",
            .german: "Das Geschäftsverzeichnis konnte nicht geladen werden.",
            .russian: "Не удалось загрузить каталог магазинов.",
            .portuguese: "Não foi possível carregar o diretório de lojas.",
            .chinese: "无法加载商店目录。",
            .turkish: "Mağaza dizini yüklenemedi.",
            .hindi: "स्टोर निर्देशिका लोड नहीं हो सकी।"
        ],
        "The store link is invalid.": [
            .spanish: "El enlace de la tienda no es válido.", .french: "Le lien du magasin n'est pas valide.",
            .german: "Der Geschäftslink ist ungültig.", .russian: "Ссылка магазина недействительна.",
            .portuguese: "O link da loja é inválido.", .chinese: "商店链接无效。",
            .turkish: "Mağaza bağlantısı geçersiz.", .hindi: "स्टोर लिंक अमान्य है।"
        ],
        "The store link could not be opened.": [
            .spanish: "No se pudo abrir el enlace de la tienda.",
            .french: "Le lien du magasin n'a pas pu être ouvert.",
            .german: "Der Geschäftslink konnte nicht geöffnet werden.",
            .russian: "Не удалось открыть ссылку магазина.",
            .portuguese: "Não foi possível abrir o link da loja.",
            .chinese: "无法打开商店链接。",
            .turkish: "Mağaza bağlantısı açılamadı.",
            .hindi: "स्टोर लिंक नहीं खोला जा सका।"
        ],
        "This file could not be opened": [
            .spanish: "No se pudo abrir este archivo", .french: "Ce fichier n'a pas pu être ouvert",
            .german: "Diese Datei konnte nicht geöffnet werden", .russian: "Не удалось открыть этот файл",
            .portuguese: "Não foi possível abrir este arquivo", .chinese: "无法打开此文件",
            .turkish: "Bu dosya açılamadı", .hindi: "यह फ़ाइल नहीं खोली जा सकी"
        ],
        "Camera is not available on this device or simulator.": [
            .spanish: "La cámara no está disponible en este dispositivo o simulador.",
            .french: "L'appareil photo n'est pas disponible sur cet appareil ou simulateur.",
            .german: "Die Kamera ist auf diesem Gerät oder Simulator nicht verfügbar.",
            .russian: "Камера недоступна на этом устройстве или симуляторе.",
            .portuguese: "A câmera não está disponível neste dispositivo ou simulador.",
            .chinese: "此设备或模拟器上没有可用的相机。",
            .turkish: "Bu cihazda veya simülatörde kamera kullanılamıyor.",
            .hindi: "इस डिवाइस या सिम्युलेटर पर कैमरा उपलब्ध नहीं है।"
        ],

        // MARK: - Progress and status

        "Loading catalog database...": [
            .spanish: "Cargando la base de piezas...", .french: "Chargement de la base du catalogue...",
            .german: "Katalogdatenbank wird geladen...", .russian: "Загрузка базы каталога...",
            .portuguese: "Carregando a base do catálogo...", .chinese: "正在加载目录数据库…",
            .turkish: "Katalog veritabanı yükleniyor...", .hindi: "कैटलॉग डेटाबेस लोड हो रहा है..."
        ],
        "Opening the catalog...": [
            .spanish: "Abriendo el catálogo...", .french: "Ouverture du catalogue...",
            .german: "Katalog wird geöffnet...", .russian: "Открытие каталога...",
            .portuguese: "Abrindo o catálogo...", .chinese: "正在打开目录…",
            .turkish: "Katalog açılıyor...", .hindi: "कैटलॉग खुल रहा है..."
        ],
        "Analyzing on device": [
            .spanish: "Analizando en el dispositivo", .french: "Analyse sur l'appareil",
            .german: "Analyse auf dem Gerät", .russian: "Анализ на устройстве",
            .portuguese: "Analisando no dispositivo", .chinese: "正在设备上分析",
            .turkish: "Cihazda analiz ediliyor", .hindi: "डिवाइस पर विश्लेषण हो रहा है"
        ],
        "Analyzing the photo on device...": [
            .spanish: "Analizando la foto en el dispositivo...", .french: "Analyse de la photo sur l'appareil...",
            .german: "Foto wird auf dem Gerät analysiert...", .russian: "Фото анализируется на устройстве...",
            .portuguese: "Analisando a foto no dispositivo...", .chinese: "正在设备上分析照片…",
            .turkish: "Fotoğraf cihazda analiz ediliyor...", .hindi: "डिवाइस पर फ़ोटो का विश्लेषण हो रहा है..."
        ],
        "Analyzing the camera image on device...": [
            .spanish: "Analizando la imagen de la cámara en el dispositivo...",
            .french: "Analyse de l'image de l'appareil photo sur l'appareil...",
            .german: "Kamerabild wird auf dem Gerät analysiert...",
            .russian: "Изображение с камеры анализируется на устройстве...",
            .portuguese: "Analisando a imagem da câmera no dispositivo...",
            .chinese: "正在设备上分析相机图像…",
            .turkish: "Kamera görüntüsü cihazda analiz ediliyor...",
            .hindi: "डिवाइस पर कैमरा छवि का विश्लेषण हो रहा है..."
        ],
        "Analyzing catalog context...": [
            .spanish: "Analizando el contexto del catálogo...", .french: "Analyse du contexte du catalogue...",
            .german: "Katalogkontext wird analysiert...", .russian: "Анализ контекста каталога...",
            .portuguese: "Analisando o contexto do catálogo...", .chinese: "正在分析目录上下文…",
            .turkish: "Katalog bağlamı analiz ediliyor...", .hindi: "कैटलॉग संदर्भ का विश्लेषण हो रहा है..."
        ],
        "Checking in-app purchase products...": [
            .spanish: "Comprobando los productos de compra integrada...",
            .french: "Vérification des achats intégrés...",
            .german: "In-App-Käufe werden geprüft...", .russian: "Проверка встроенных покупок...",
            .portuguese: "Verificando as compras no app...", .chinese: "正在检查应用内购买项目…",
            .turkish: "Uygulama içi satın alma ürünleri kontrol ediliyor...",
            .hindi: "इन-ऐप खरीदारी उत्पादों की जांच हो रही है..."
        ],
        "Restoring purchases...": [
            .spanish: "Restaurando compras...", .french: "Restauration des achats...",
            .german: "Käufe werden wiederhergestellt...", .russian: "Восстановление покупок...",
            .portuguese: "Restaurando compras...", .chinese: "正在恢复购买…",
            .turkish: "Satın alımlar geri yükleniyor...", .hindi: "खरीदारी बहाल हो रही है..."
        ],
        "Awaiting indexing": [
            .spanish: "Pendiente de indexación", .french: "En attente d'indexation",
            .german: "Wartet auf Indizierung", .russian: "Ожидает индексации",
            .portuguese: "Aguardando indexação", .chinese: "等待索引",
            .turkish: "Dizinleme bekleniyor", .hindi: "अनुक्रमण प्रतीक्षित"
        ],
        "Content protected": [
            .spanish: "Contenido protegido", .french: "Contenu protégé", .german: "Inhalt geschützt",
            .russian: "Содержимое защищено", .portuguese: "Conteúdo protegido", .chinese: "内容已保护",
            .turkish: "İçerik korunuyor", .hindi: "सामग्री सुरक्षित"
        ],
        "This shield appears only when you leave the app or open the app switcher to protect catalog data.": [
            .spanish: "Esta pantalla aparece solo al salir de la app o abrir el selector de apps, "
                + "para proteger los datos del catálogo.",
            .french: "Cet écran n'apparaît que lorsque vous quittez l'app ou ouvrez le sélecteur d'apps, "
                + "afin de protéger les données du catalogue.",
            .german: "Diese Abdeckung erscheint nur, wenn Sie die App verlassen oder den App-Umschalter öffnen, "
                + "um Katalogdaten zu schützen.",
            .russian: "Эта заставка появляется только при выходе из приложения или открытии переключателя приложений, "
                + "чтобы защитить данные каталога.",
            .portuguese: "Esta tela aparece apenas ao sair do app ou abrir o alternador de apps, "
                + "para proteger os dados do catálogo.",
            .chinese: "此遮罩仅在您离开 App 或打开 App 切换器时出现，用于保护目录数据。",
            .turkish: "Bu perde yalnızca uygulamadan çıktığınızda veya uygulama değiştiriciyi açtığınızda görünür "
                + "ve katalog verilerini korur.",
            .hindi: "यह पर्दा केवल तब दिखता है जब आप ऐप छोड़ते हैं या ऐप स्विचर खोलते हैं, "
                + "ताकि कैटलॉग डेटा सुरक्षित रहे।"
        ]
    ]
}

// MARK: - Purchases, assistant, requests, and onboarding

private enum BatalWorkflowStrings {
    static let entries: [String: [AppLanguage: String]] = [
        "Restore Purchases": [
            .spanish: "Restaurar compras", .french: "Restaurer les achats", .german: "Käufe wiederherstellen",
            .russian: "Восстановить покупки", .portuguese: "Restaurar compras", .chinese: "恢复购买",
            .turkish: "Satın alımları geri yükle", .hindi: "खरीदारी बहाल करें"
        ],
        "Redeem offer or owner code": [
            .spanish: "Canjear código de oferta o de propietario",
            .french: "Utiliser un code d'offre ou de propriétaire",
            .german: "Angebots- oder Inhabercode einlösen", .russian: "Активировать код предложения или владельца",
            .portuguese: "Resgatar código de oferta ou de proprietário", .chinese: "兑换优惠码或所有者代码",
            .turkish: "Teklif veya sahip kodunu kullan", .hindi: "ऑफ़र या स्वामी कोड रिडीम करें"
        ],
        "Unlock the full library for SAR 100": [
            .spanish: "Desbloquear la biblioteca completa por 100 SAR",
            .french: "Débloquer la bibliothèque complète pour 100 SAR",
            .german: "Vollständige Bibliothek für 100 SAR freischalten",
            .russian: "Открыть всю библиотеку за 100 SAR",
            .portuguese: "Desbloquear a biblioteca completa por SAR 100",
            .chinese: "以 100 沙特里亚尔解锁完整目录库",
            .turkish: "Tüm kitaplığı 100 SAR karşılığında açın",
            .hindi: "पूरी लाइब्रेरी 100 SAR में अनलॉक करें"
        ],
        "Part image and full number are locked": [
            .spanish: "La imagen de la pieza y el número completo están bloqueados",
            .french: "L'image de la pièce et le numéro complet sont verrouillés",
            .german: "Teilebild und vollständige Nummer sind gesperrt",
            .russian: "Изображение детали и полный номер заблокированы",
            .portuguese: "A imagem da peça e o número completo estão bloqueados",
            .chinese: "配件图片和完整编号已锁定",
            .turkish: "Parça görseli ve tam numara kilitli",
            .hindi: "पुर्जे की छवि और पूरा नंबर लॉक हैं"
        ],
        "Payment complete. Content unlocked.": [
            .spanish: "Pago completado. Contenido desbloqueado.", .french: "Paiement effectué. Contenu débloqué.",
            .german: "Zahlung abgeschlossen. Inhalt freigeschaltet.", .russian: "Оплата завершена. Контент открыт.",
            .portuguese: "Pagamento concluído. Conteúdo liberado.", .chinese: "支付完成，内容已解锁。",
            .turkish: "Ödeme tamamlandı. İçerik açıldı.", .hindi: "भुगतान पूर्ण। सामग्री अनलॉक हो गई।"
        ],
        "Purchase was cancelled.": [
            .spanish: "Se canceló la compra.", .french: "L'achat a été annulé.", .german: "Der Kauf wurde abgebrochen.",
            .russian: "Покупка отменена.", .portuguese: "A compra foi cancelada.", .chinese: "购买已取消。",
            .turkish: "Satın alma iptal edildi.", .hindi: "खरीदारी रद्द कर दी गई।"
        ],
        "Purchase is pending.": [
            .spanish: "La compra está pendiente.", .french: "L'achat est en attente.",
            .german: "Der Kauf steht noch aus.", .russian: "Покупка ожидает подтверждения.",
            .portuguese: "A compra está pendente.", .chinese: "购买待处理。",
            .turkish: "Satın alma beklemede.", .hindi: "खरीदारी लंबित है।"
        ],
        "Catalog unlock was restored.": [
            .spanish: "Se restauró el desbloqueo del catálogo.", .french: "Le déblocage du catalogue a été restauré.",
            .german: "Die Katalogfreischaltung wurde wiederhergestellt.",
            .russian: "Доступ к каталогу восстановлен.",
            .portuguese: "O desbloqueio do catálogo foi restaurado.", .chinese: "目录解锁已恢复。",
            .turkish: "Katalog kilidi geri yüklendi.", .hindi: "कैटलॉग अनलॉक बहाल कर दिया गया।"
        ],
        "No eligible purchases were found to restore.": [
            .spanish: "No se encontraron compras que restaurar.",
            .french: "Aucun achat éligible à restaurer n'a été trouvé.",
            .german: "Es wurden keine wiederherstellbaren Käufe gefunden.",
            .russian: "Покупок для восстановления не найдено.",
            .portuguese: "Nenhuma compra elegível foi encontrada para restaurar.",
            .chinese: "未找到可恢复的购买。",
            .turkish: "Geri yüklenecek uygun satın alma bulunamadı.",
            .hindi: "बहाल करने योग्य कोई खरीदारी नहीं मिली।"
        ],
        "Offer code redeemed. Catalog unlocked.": [
            .spanish: "Código canjeado. Catálogo desbloqueado.", .french: "Code utilisé. Catalogue débloqué.",
            .german: "Code eingelöst. Katalog freigeschaltet.", .russian: "Код активирован. Каталог открыт.",
            .portuguese: "Código resgatado. Catálogo liberado.", .chinese: "优惠码已兑换，目录已解锁。",
            .turkish: "Kod kullanıldı. Katalog açıldı.", .hindi: "ऑफ़र कोड रिडीम हुआ। कैटलॉग अनलॉक।"
        ],
        "In-app purchase is ready through Apple.": [
            .spanish: "La compra integrada está disponible mediante Apple.",
            .french: "L'achat intégré est disponible via Apple.",
            .german: "Der In-App-Kauf ist über Apple verfügbar.",
            .russian: "Встроенная покупка доступна через Apple.",
            .portuguese: "A compra no app está disponível pela Apple.",
            .chinese: "应用内购买已通过 Apple 就绪。",
            .turkish: "Uygulama içi satın alma Apple üzerinden hazır.",
            .hindi: "इन-ऐप खरीदारी Apple के माध्यम से तैयार है।"
        ],
        "Apple could not verify the purchase. Try again shortly.": [
            .spanish: "Apple no pudo verificar la compra. Inténtalo de nuevo en breve.",
            .french: "Apple n'a pas pu vérifier l'achat. Réessayez dans un instant.",
            .german: "Apple konnte den Kauf nicht überprüfen. Versuchen Sie es gleich erneut.",
            .russian: "Apple не смогла подтвердить покупку. Повторите попытку позже.",
            .portuguese: "A Apple não conseguiu verificar a compra. Tente novamente em instantes.",
            .chinese: "Apple 无法验证此次购买，请稍后重试。",
            .turkish: "Apple satın almayı doğrulayamadı. Kısa süre sonra tekrar deneyin.",
            .hindi: "Apple खरीदारी सत्यापित नहीं कर सका। कुछ देर बाद पुनः प्रयास करें।"
        ],

        // MARK: - Assistant

        "Batal Assistant": [
            .spanish: "Asistente Batal", .french: "Assistant Batal", .german: "Batal-Assistent",
            .russian: "Ассистент Batal", .portuguese: "Assistente Batal", .chinese: "Batal 助手",
            .turkish: "Batal Asistanı", .hindi: "बटल असिस्टेंट"
        ],
        "Ask Batal Assistant": [
            .spanish: "Pregunta al Asistente Batal", .french: "Interroger l'Assistant Batal",
            .german: "Batal-Assistent fragen", .russian: "Спросить ассистента Batal",
            .portuguese: "Pergunte ao Assistente Batal", .chinese: "询问 Batal 助手",
            .turkish: "Batal Asistanı'na sor", .hindi: "बटल असिस्टेंट से पूछें"
        ],
        "Ask about parts and fitment": [
            .spanish: "Pregunta sobre piezas y compatibilidad",
            .french: "Posez une question sur les pièces et la compatibilité",
            .german: "Fragen zu Teilen und Passform stellen", .russian: "Спросите о деталях и совместимости",
            .portuguese: "Pergunte sobre peças e compatibilidade", .chinese: "咨询配件与适配问题",
            .turkish: "Parçalar ve uyum hakkında sorun", .hindi: "पुर्जों और फिटमेंट के बारे में पूछें"
        ],
        "Ask about a part, fitment, or request...": [
            .spanish: "Pregunta por una pieza, compatibilidad o solicitud...",
            .french: "Posez une question sur une pièce, la compatibilité ou une demande...",
            .german: "Nach Teil, Passform oder Anfrage fragen...",
            .russian: "Спросите о детали, совместимости или запросе...",
            .portuguese: "Pergunte sobre uma peça, compatibilidade ou solicitação...",
            .chinese: "询问配件、适配或请求…",
            .turkish: "Parça, uyum veya talep hakkında sorun...",
            .hindi: "किसी पुर्जे, फिटमेंट या अनुरोध के बारे में पूछें..."
        ],
        "Quick prompts": [
            .spanish: "Preguntas rápidas", .french: "Suggestions rapides", .german: "Schnellfragen",
            .russian: "Быстрые вопросы", .portuguese: "Perguntas rápidas", .chinese: "快捷提问",
            .turkish: "Hızlı sorular", .hindi: "त्वरित प्रश्न"
        ],
        "Suggested next steps": [
            .spanish: "Próximos pasos sugeridos", .french: "Prochaines étapes suggérées",
            .german: "Vorgeschlagene nächste Schritte", .russian: "Предлагаемые следующие шаги",
            .portuguese: "Próximos passos sugeridos", .chinese: "建议的后续步骤",
            .turkish: "Önerilen sonraki adımlar", .hindi: "सुझाए गए अगले कदम"
        ],
        "Does this part fit my vehicle?": [
            .spanish: "¿Esta pieza sirve para mi vehículo?", .french: "Cette pièce convient-elle à mon véhicule ?",
            .german: "Passt dieses Teil zu meinem Fahrzeug?", .russian: "Подходит ли эта деталь моему автомобилю?",
            .portuguese: "Esta peça serve no meu veículo?", .chinese: "这个配件适合我的车吗？",
            .turkish: "Bu parça aracıma uyar mı?", .hindi: "क्या यह पुर्जा मेरे वाहन में फिट होगा?"
        ],
        "What should I do before requesting this part?": [
            .spanish: "¿Qué debo hacer antes de solicitar esta pieza?",
            .french: "Que dois-je faire avant de demander cette pièce ?",
            .german: "Was sollte ich vor der Anfrage zu diesem Teil tun?",
            .russian: "Что сделать перед запросом этой детали?",
            .portuguese: "O que devo fazer antes de solicitar esta peça?",
            .chinese: "在请求此配件前我该做什么？",
            .turkish: "Bu parçayı talep etmeden önce ne yapmalıyım?",
            .hindi: "इस पुर्जे का अनुरोध करने से पहले मुझे क्या करना चाहिए?"
        ],
        "AI-generated answer": [
            .spanish: "Respuesta generada por IA", .french: "Réponse générée par IA",
            .german: "KI-generierte Antwort", .russian: "Ответ создан ИИ",
            .portuguese: "Resposta gerada por IA", .chinese: "AI 生成的回答",
            .turkish: "Yapay zekâ yanıtı", .hindi: "AI-जनित उत्तर"
        ],
        "Local answer": [
            .spanish: "Respuesta local", .french: "Réponse locale", .german: "Lokale Antwort",
            .russian: "Локальный ответ", .portuguese: "Resposta local", .chinese: "本地回答",
            .turkish: "Yerel yanıt", .hindi: "स्थानीय उत्तर"
        ],
        "Safe local mode": [
            .spanish: "Modo local seguro", .french: "Mode local sécurisé", .german: "Sicherer lokaler Modus",
            .russian: "Безопасный локальный режим", .portuguese: "Modo local seguro", .chinese: "安全本地模式",
            .turkish: "Güvenli yerel mod", .hindi: "सुरक्षित स्थानीय मोड"
        ],
        "AI connected through secure backend": [
            .spanish: "IA conectada mediante un backend seguro",
            .french: "IA connectée via un backend sécurisé",
            .german: "KI über sicheres Backend verbunden", .russian: "ИИ подключён через защищённый сервер",
            .portuguese: "IA conectada por um backend seguro", .chinese: "AI 已通过安全后端连接",
            .turkish: "Yapay zekâ güvenli sunucuya bağlı", .hindi: "AI सुरक्षित बैकएंड से जुड़ा है"
        ],
        "Enter a clear question under 800 characters.": [
            .spanish: "Escribe una pregunta clara de menos de 800 caracteres.",
            .french: "Saisissez une question claire de moins de 800 caractères.",
            .german: "Stellen Sie eine klare Frage mit weniger als 800 Zeichen.",
            .russian: "Задайте понятный вопрос длиной до 800 символов.",
            .portuguese: "Escreva uma pergunta clara com menos de 800 caracteres.",
            .chinese: "请输入不超过 800 个字符的清晰问题。",
            .turkish: "800 karakterden kısa, net bir soru yazın.",
            .hindi: "800 अक्षरों से कम का स्पष्ट प्रश्न लिखें।"
        ],
        "Enter a part number or short description.": [
            .spanish: "Introduce un número de pieza o una descripción breve.",
            .french: "Saisissez un numéro de pièce ou une courte description.",
            .german: "Teilenummer oder kurze Beschreibung eingeben.",
            .russian: "Введите номер детали или краткое описание.",
            .portuguese: "Informe um número de peça ou uma breve descrição.",
            .chinese: "请输入配件号或简短描述。",
            .turkish: "Bir parça numarası veya kısa açıklama girin.",
            .hindi: "पुर्जा नंबर या संक्षिप्त विवरण दर्ज करें।"
        ],

        // MARK: - Requests

        "Supplier-ready request": [
            .spanish: "Solicitud lista para el proveedor", .french: "Demande prête pour le fournisseur",
            .german: "Lieferantenfertige Anfrage", .russian: "Запрос, готовый для поставщика",
            .portuguese: "Solicitação pronta para o fornecedor", .chinese: "可直接发给供应商的请求",
            .turkish: "Tedarikçiye hazır talep", .hindi: "आपूर्तिकर्ता-तैयार अनुरोध"
        ],
        "Open the closest result": [
            .spanish: "Abrir el resultado más cercano", .french: "Ouvrir le résultat le plus proche",
            .german: "Nächstliegendes Ergebnis öffnen", .russian: "Открыть ближайший результат",
            .portuguese: "Abrir o resultado mais próximo", .chinese: "打开最接近的结果",
            .turkish: "En yakın sonucu aç", .hindi: "निकटतम परिणाम खोलें"
        ],
        "The first result is the strongest current search candidate.": [
            .spanish: "El primer resultado es el mejor candidato de la búsqueda actual.",
            .french: "Le premier résultat est le meilleur candidat de la recherche actuelle.",
            .german: "Das erste Ergebnis ist der beste Kandidat der aktuellen Suche.",
            .russian: "Первый результат — лучший кандидат текущего поиска.",
            .portuguese: "O primeiro resultado é o melhor candidato da busca atual.",
            .chinese: "第一个结果是当前搜索中最合适的候选。",
            .turkish: "İlk sonuç, mevcut aramanın en güçlü adayıdır.",
            .hindi: "पहला परिणाम मौजूदा खोज का सबसे उपयुक्त उम्मीदवार है।"
        ],
        "Complete My Vehicle": [
            .spanish: "Completa Mi vehículo", .french: "Compléter Mon véhicule",
            .german: "Mein Fahrzeug vervollständigen", .russian: "Заполните «Мой автомобиль»",
            .portuguese: "Complete Meu veículo", .chinese: "完善“我的车辆”",
            .turkish: "Aracım bilgilerini tamamla", .hindi: "मेरा वाहन पूरा करें"
        ],
        "Vehicle details improve fitment ranking.": [
            .spanish: "Los datos del vehículo mejoran el orden por compatibilidad.",
            .french: "Les détails du véhicule améliorent le classement par compatibilité.",
            .german: "Fahrzeugdaten verbessern die Sortierung nach Passform.",
            .russian: "Данные автомобиля улучшают ранжирование по совместимости.",
            .portuguese: "Os dados do veículo melhoram a ordenação por compatibilidade.",
            .chinese: "车辆信息可改进适配排序。",
            .turkish: "Araç bilgileri uyum sıralamasını iyileştirir.",
            .hindi: "वाहन विवरण फिटमेंट रैंकिंग को बेहतर बनाते हैं।"
        ],
        "A saved request is easier to send after verification.": [
            .spanish: "Una solicitud guardada es más fácil de enviar tras verificarla.",
            .french: "Une demande enregistrée est plus simple à envoyer après vérification.",
            .german: "Eine gespeicherte Anfrage lässt sich nach der Prüfung leichter senden.",
            .russian: "Сохранённый запрос проще отправить после проверки.",
            .portuguese: "Uma solicitação salva é mais fácil de enviar após a verificação.",
            .chinese: "保存后的请求在核对后更易于发送。",
            .turkish: "Kaydedilmiş bir talebi doğrulamadan sonra göndermek daha kolaydır.",
            .hindi: "सहेजा गया अनुरोध सत्यापन के बाद भेजना आसान होता है।"
        ],
        "Prepare a part request": [
            .spanish: "Preparar una solicitud de pieza", .french: "Préparer une demande de pièce",
            .german: "Teileanfrage vorbereiten", .russian: "Подготовить запрос детали",
            .portuguese: "Preparar uma solicitação de peça", .chinese: "准备配件请求",
            .turkish: "Parça talebi hazırla", .hindi: "पुर्जा अनुरोध तैयार करें"
        ],
        "Prepare request": [
            .spanish: "Preparar solicitud", .french: "Préparer la demande", .german: "Anfrage vorbereiten",
            .russian: "Подготовить запрос", .portuguese: "Preparar solicitação", .chinese: "准备请求",
            .turkish: "Talep hazırla", .hindi: "अनुरोध तैयार करें"
        ],
        "Prepare and save request": [
            .spanish: "Preparar y guardar la solicitud", .french: "Préparer et enregistrer la demande",
            .german: "Anfrage vorbereiten und sichern", .russian: "Подготовить и сохранить запрос",
            .portuguese: "Preparar e salvar a solicitação", .chinese: "准备并保存请求",
            .turkish: "Talebi hazırla ve kaydet", .hindi: "अनुरोध तैयार करें और सहेजें"
        ],
        "Save part request": [
            .spanish: "Guardar solicitud de pieza", .french: "Enregistrer la demande de pièce",
            .german: "Teileanfrage sichern", .russian: "Сохранить запрос детали",
            .portuguese: "Salvar solicitação de peça", .chinese: "保存配件请求",
            .turkish: "Parça talebini kaydet", .hindi: "पुर्जा अनुरोध सहेजें"
        ],
        "Part request was prepared and saved.": [
            .spanish: "La solicitud de pieza se preparó y se guardó.",
            .french: "La demande de pièce a été préparée et enregistrée.",
            .german: "Die Teileanfrage wurde vorbereitet und gesichert.",
            .russian: "Запрос детали подготовлен и сохранён.",
            .portuguese: "A solicitação de peça foi preparada e salva.",
            .chinese: "配件请求已准备并保存。",
            .turkish: "Parça talebi hazırlandı ve kaydedildi.",
            .hindi: "पुर्जा अनुरोध तैयार कर सहेजा गया।"
        ],
        "Complete these to avoid an ambiguous request:": [
            .spanish: "Completa estos campos para evitar una solicitud ambigua:",
            .french: "Complétez ces champs pour éviter une demande ambiguë :",
            .german: "Füllen Sie diese Felder aus, um eine unklare Anfrage zu vermeiden:",
            .russian: "Заполните эти поля, чтобы запрос не был неоднозначным:",
            .portuguese: "Preencha estes campos para evitar uma solicitação ambígua:",
            .chinese: "请补全以下内容，避免请求含糊：",
            .turkish: "Belirsiz bir talebi önlemek için şunları tamamlayın:",
            .hindi: "अस्पष्ट अनुरोध से बचने के लिए ये पूरे करें:"
        ],
        "Add a part number or a part name.": [
            .spanish: "Añade un número o un nombre de pieza.", .french: "Ajoutez un numéro ou un nom de pièce.",
            .german: "Teilenummer oder Teilenamen hinzufügen.", .russian: "Добавьте номер или название детали.",
            .portuguese: "Adicione um número ou nome de peça.", .chinese: "请添加配件号或配件名称。",
            .turkish: "Bir parça numarası veya adı ekleyin.", .hindi: "पुर्जा नंबर या पुर्जे का नाम जोड़ें।"
        ],
        "Add the vehicle generation or model year.": [
            .spanish: "Añade la generación o el año del vehículo.",
            .french: "Ajoutez la génération ou l'année du véhicule.",
            .german: "Fahrzeuggeneration oder Modelljahr hinzufügen.",
            .russian: "Добавьте поколение или год выпуска автомобиля.",
            .portuguese: "Adicione a geração ou o ano do veículo.",
            .chinese: "请添加车辆世代或车型年份。",
            .turkish: "Araç neslini veya model yılını ekleyin.",
            .hindi: "वाहन की जेनरेशन या मॉडल वर्ष जोड़ें।"
        ],
        "Structured text to send to suppliers.": [
            .spanish: "Texto estructurado para enviar a los proveedores.",
            .french: "Texte structuré à envoyer aux fournisseurs.",
            .german: "Strukturierter Text zum Senden an Lieferanten.",
            .russian: "Структурированный текст для отправки поставщикам.",
            .portuguese: "Texto estruturado para enviar aos fornecedores.",
            .chinese: "可发送给供应商的结构化文本。",
            .turkish: "Tedarikçilere gönderilecek düzenli metin.",
            .hindi: "आपूर्तिकर्ताओं को भेजने के लिए संरचित पाठ।"
        ],
        "Save work and notes locally.": [
            .spanish: "Guarda trabajos y notas localmente.",
            .french: "Enregistrez les interventions et notes localement.",
            .german: "Arbeiten und Notizen lokal sichern.", .russian: "Сохраняйте работы и заметки локально.",
            .portuguese: "Salve serviços e anotações localmente.", .chinese: "在本地保存作业与备注。",
            .turkish: "Çalışmaları ve notları yerel olarak kaydedin.", .hindi: "कार्य और टिप्पणियाँ स्थानीय रूप से सहेजें।"
        ],
        "Add maintenance": [
            .spanish: "Añadir mantenimiento", .french: "Ajouter un entretien", .german: "Wartung hinzufügen",
            .russian: "Добавить обслуживание", .portuguese: "Adicionar manutenção", .chinese: "添加保养",
            .turkish: "Bakım ekle", .hindi: "रखरखाव जोड़ें"
        ],
        "Local vehicle log": [
            .spanish: "Registro local del vehículo", .french: "Journal local du véhicule",
            .german: "Lokales Fahrzeugprotokoll", .russian: "Локальный журнал автомобиля",
            .portuguese: "Registro local do veículo", .chinese: "本地车辆日志",
            .turkish: "Yerel araç kaydı", .hindi: "स्थानीय वाहन लॉग"
        ],

        // MARK: - Onboarding, account, and permissions

        "Welcome": [
            .spanish: "Bienvenido", .french: "Bienvenue", .german: "Willkommen", .russian: "Добро пожаловать",
            .portuguese: "Bem-vindo", .chinese: "欢迎", .turkish: "Hoş geldiniz", .hindi: "स्वागत है"
        ],
        "Welcome to Batal Al-Droob": [
            .spanish: "Bienvenido a Batal Al-Droob", .french: "Bienvenue dans Batal Al-Droob",
            .german: "Willkommen bei Batal Al-Droob", .russian: "Добро пожаловать в Batal Al-Droob",
            .portuguese: "Bem-vindo ao Batal Al-Droob", .chinese: "欢迎使用 Batal Al-Droob",
            .turkish: "Batal Al-Droob'a hoş geldiniz", .hindi: "बटल अल-द्रूब में आपका स्वागत है"
        ],
        "Sign in": [
            .spanish: "Iniciar sesión", .french: "Se connecter", .german: "Anmelden", .russian: "Войти",
            .portuguese: "Entrar", .chinese: "登录", .turkish: "Giriş yap", .hindi: "साइन इन"
        ],
        "Register": [
            .spanish: "Registrarse", .french: "S'inscrire", .german: "Registrieren", .russian: "Зарегистрироваться",
            .portuguese: "Cadastrar", .chinese: "注册", .turkish: "Kayıt ol", .hindi: "पंजीकरण"
        ],
        "Sign-in options": [
            .spanish: "Opciones de inicio de sesión", .french: "Options de connexion", .german: "Anmeldeoptionen",
            .russian: "Варианты входа", .portuguese: "Opções de entrada", .chinese: "登录选项",
            .turkish: "Giriş seçenekleri", .hindi: "साइन-इन विकल्प"
        ],
        "Sign-in required": [
            .spanish: "Se requiere iniciar sesión", .french: "Connexion requise", .german: "Anmeldung erforderlich",
            .russian: "Требуется вход", .portuguese: "Entrada obrigatória", .chinese: "需要登录",
            .turkish: "Giriş gerekli", .hindi: "साइन-इन आवश्यक"
        ],
        "Sign in and enable alerts": [
            .spanish: "Iniciar sesión y activar avisos", .french: "Se connecter et activer les alertes",
            .german: "Anmelden und Hinweise aktivieren", .russian: "Войти и включить уведомления",
            .portuguese: "Entrar e ativar alertas", .chinese: "登录并启用提醒",
            .turkish: "Giriş yap ve bildirimleri aç", .hindi: "साइन इन करें और अलर्ट चालू करें"
        ],
        "Sign in without alerts": [
            .spanish: "Iniciar sesión sin avisos", .french: "Se connecter sans alertes",
            .german: "Ohne Hinweise anmelden", .russian: "Войти без уведомлений",
            .portuguese: "Entrar sem alertas", .chinese: "不启用提醒直接登录",
            .turkish: "Bildirimsiz giriş yap", .hindi: "बिना अलर्ट साइन इन करें"
        ],
        "Signed in locally.": [
            .spanish: "Sesión iniciada localmente.", .french: "Connecté localement.", .german: "Lokal angemeldet.",
            .russian: "Вход выполнен локально.", .portuguese: "Sessão iniciada localmente.", .chinese: "已在本地登录。",
            .turkish: "Yerel olarak giriş yapıldı.", .hindi: "स्थानीय रूप से साइन इन किया गया।"
        ],
        "Local account created.": [
            .spanish: "Cuenta local creada.", .french: "Compte local créé.", .german: "Lokales Konto erstellt.",
            .russian: "Локальный аккаунт создан.", .portuguese: "Conta local criada.", .chinese: "已创建本地账户。",
            .turkish: "Yerel hesap oluşturuldu.", .hindi: "स्थानीय खाता बनाया गया।"
        ],
        "Local account saved.": [
            .spanish: "Cuenta local guardada.", .french: "Compte local enregistré.",
            .german: "Lokales Konto gesichert.", .russian: "Локальный аккаунт сохранён.",
            .portuguese: "Conta local salva.", .chinese: "已保存本地账户。",
            .turkish: "Yerel hesap kaydedildi.", .hindi: "स्थानीय खाता सहेजा गया।"
        ],
        "Save email on device": [
            .spanish: "Guardar el correo en el dispositivo", .french: "Enregistrer l'e-mail sur l'appareil",
            .german: "E-Mail auf dem Gerät sichern", .russian: "Сохранить эл. почту на устройстве",
            .portuguese: "Salvar o e-mail no dispositivo", .chinese: "将电子邮件保存在设备上",
            .turkish: "E-postayı cihaza kaydet", .hindi: "ईमेल डिवाइस पर सहेजें"
        ],
        "Enter a valid email.": [
            .spanish: "Introduce un correo válido.", .french: "Saisissez une adresse e-mail valide.",
            .german: "Gültige E-Mail-Adresse eingeben.", .russian: "Введите действительный адрес эл. почты.",
            .portuguese: "Informe um e-mail válido.", .chinese: "请输入有效的电子邮件。",
            .turkish: "Geçerli bir e-posta girin.", .hindi: "मान्य ईमेल दर्ज करें।"
        ],
        "Enter a valid email to continue.": [
            .spanish: "Introduce un correo válido para continuar.",
            .french: "Saisissez une adresse e-mail valide pour continuer.",
            .german: "Gültige E-Mail-Adresse eingeben, um fortzufahren.",
            .russian: "Введите действительный адрес эл. почты, чтобы продолжить.",
            .portuguese: "Informe um e-mail válido para continuar.",
            .chinese: "请输入有效的电子邮件以继续。",
            .turkish: "Devam etmek için geçerli bir e-posta girin.",
            .hindi: "जारी रखने के लिए मान्य ईमेल दर्ज करें।"
        ],
        "A valid email is required before using the app.": [
            .spanish: "Se requiere un correo válido antes de usar la app.",
            .french: "Une adresse e-mail valide est requise avant d'utiliser l'app.",
            .german: "Vor der Nutzung der App ist eine gültige E-Mail-Adresse erforderlich.",
            .russian: "Перед использованием приложения нужен действительный адрес эл. почты.",
            .portuguese: "É necessário um e-mail válido antes de usar o app.",
            .chinese: "使用本 App 前需要有效的电子邮件。",
            .turkish: "Uygulamayı kullanmadan önce geçerli bir e-posta gerekir.",
            .hindi: "ऐप उपयोग करने से पहले एक मान्य ईमेल आवश्यक है।"
        ],
        "Notifications": [
            .spanish: "Notificaciones", .french: "Notifications", .german: "Mitteilungen", .russian: "Уведомления",
            .portuguese: "Notificações", .chinese: "通知", .turkish: "Bildirimler", .hindi: "सूचनाएँ"
        ],
        "Location": [
            .spanish: "Ubicación", .french: "Localisation", .german: "Standort", .russian: "Геопозиция",
            .portuguese: "Localização", .chinese: "位置", .turkish: "Konum", .hindi: "स्थान"
        ],
        "Tracking": [
            .spanish: "Seguimiento", .french: "Suivi", .german: "Tracking", .russian: "Отслеживание",
            .portuguese: "Rastreamento", .chinese: "跟踪", .turkish: "İzleme", .hindi: "ट्रैकिंग"
        ],
        "Not requested": [
            .spanish: "No solicitado", .french: "Non demandé", .german: "Nicht angefordert",
            .russian: "Не запрошено", .portuguese: "Não solicitado", .chinese: "未请求",
            .turkish: "İstenmedi", .hindi: "अनुरोध नहीं किया गया"
        ],
        "Denied": [
            .spanish: "Denegado", .french: "Refusé", .german: "Abgelehnt", .russian: "Отклонено",
            .portuguese: "Negado", .chinese: "已拒绝", .turkish: "Reddedildi", .hindi: "अस्वीकृत"
        ],
        "Enabled": [
            .spanish: "Activado", .french: "Activé", .german: "Aktiviert", .russian: "Включено",
            .portuguese: "Ativado", .chinese: "已启用", .turkish: "Etkin", .hindi: "सक्षम"
        ],
        "Not used": [
            .spanish: "No se usa", .french: "Non utilisé", .german: "Nicht verwendet",
            .russian: "Не используется", .portuguese: "Não utilizado", .chinese: "未使用",
            .turkish: "Kullanılmıyor", .hindi: "उपयोग नहीं"
        ],
        "Not currently needed": [
            .spanish: "No es necesario por ahora", .french: "Pas nécessaire pour l'instant",
            .german: "Derzeit nicht erforderlich", .russian: "Сейчас не требуется",
            .portuguese: "Não é necessário no momento", .chinese: "目前不需要",
            .turkish: "Şu anda gerekli değil", .hindi: "फ़िलहाल आवश्यक नहीं"
        ]
    ]
}
