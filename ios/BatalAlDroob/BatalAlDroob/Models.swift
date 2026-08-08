import Foundation

// MARK: - Models

/// Languages the interface can be shown in.
///
/// The set targets this app's real audience: Gulf Patrol owners plus the workshop
/// and parts-trade workforce, which is largely South Asian and Filipino. Catalog
/// part names themselves remain Arabic/English (that is how the source catalogs are
/// published); only the interface is localized, and any untranslated string falls
/// back to English.
enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic = "ar"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case russian = "ru"
    case portuguese = "pt"
    case chinese = "zh-Hans"
    case turkish = "tr"
    case hindi = "hi"

    var id: String {
        rawValue
    }

    /// Endonym, so each language is recognizable to its own speakers in the picker.
    var title: String {
        switch self {
        case .arabic: "العربية"
        case .english: "English"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .russian: "Русский"
        case .portuguese: "Português"
        case .chinese: "中文"
        case .turkish: "Türkçe"
        case .hindi: "हिन्दी"
        }
    }

    /// Right-to-left scripts. Drives the layout direction of the whole interface.
    var isRTL: Bool {
        switch self {
        case .arabic: true
        default: false
        }
    }

    var locale: Locale {
        switch self {
        case .arabic: Locale(identifier: "ar_SA")
        case .english: Locale(identifier: "en_US")
        case .spanish: Locale(identifier: "es_ES")
        case .french: Locale(identifier: "fr_FR")
        case .german: Locale(identifier: "de_DE")
        case .russian: Locale(identifier: "ru_RU")
        case .portuguese: Locale(identifier: "pt_BR")
        case .chinese: Locale(identifier: "zh_Hans")
        case .turkish: Locale(identifier: "tr_TR")
        case .hindi: Locale(identifier: "hi_IN")
        }
    }
}

enum CatalogCategory: String, CaseIterable, Identifiable {
    // Raw values must match the `category` field in the catalog data exactly.
    // `drivetrain` covers transfer case / differential / propeller-shaft parts that
    // previously fell through to `general` (see Part.categoryValue fallback).
    case all, engine, cooling, electrical, body, brake, suspension, drivetrain, interior, fuel, general
    var id: String {
        rawValue
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .all: BatalLocalization.resolve(language, ar: "الكل", en: "All")
        case .engine: BatalLocalization.resolve(language, ar: "محرك", en: "Engine")
        case .cooling: BatalLocalization.resolve(language, ar: "تبريد", en: "Cooling")
        case .electrical: BatalLocalization.resolve(language, ar: "كهرباء", en: "Electrical")
        case .body: BatalLocalization.resolve(language, ar: "هيكل", en: "Body")
        case .brake: BatalLocalization.resolve(language, ar: "فرامل", en: "Brake")
        case .suspension: BatalLocalization.resolve(language, ar: "تعليق", en: "Suspension")
        case .drivetrain: BatalLocalization.resolve(language, ar: "نقل الحركة", en: "Drivetrain")
        case .interior: BatalLocalization.resolve(language, ar: "داخلية", en: "Interior")
        case .fuel: BatalLocalization.resolve(language, ar: "وقود", en: "Fuel")
        case .general: BatalLocalization.resolve(language, ar: "عام", en: "General")
        }
    }

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .engine: "engine.combustion"
        case .cooling: "fan"
        case .electrical: "bolt"
        case .body: "car.side"
        case .brake: "record.circle"
        case .suspension: "waveform.path.ecg"
        case .drivetrain: "gearshape.2"
        case .interior: "seatbelt"
        case .fuel: "fuelpump"
        case .general: "wrench.and.screwdriver"
        }
    }
}

struct CatalogPayload: Decodable {
    let generatedAt: String?
    let appName: String?
    let model: String?
    let sourceCount: Int?
    let recordCount: Int?
    let partCount: Int?
    let sources: [CatalogSource]
    let parts: [Part]

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at", appName = "app_name", model
        case sourceCount = "source_count", recordCount = "record_count", partCount = "part_count"
        case sources, parts
    }
}

enum CatalogAccessLevel: String, Identifiable, CaseIterable {
    case singleUnlock
    case fullCatalog

    var id: String { rawValue }

    var productID: String {
        switch self {
        case .singleUnlock:
            StoreProductID.singleCatalogUnlock
        case .fullCatalog:
            StoreProductID.catalogFullUnlock
        }
    }

    var fallbackPriceAr: String {
        switch self {
        case .singleUnlock: "4 ر.س"
        case .fullCatalog: "100 ر.س"
        }
    }

    var fallbackPriceEn: String {
        switch self {
        case .singleUnlock: "SAR 4"
        case .fullCatalog: "SAR 100"
        }
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .singleUnlock:
            BatalLocalization.resolve(language, ar: "فتح صفحة كتالوج واحدة", en: "Unlock one catalog page")
        case .fullCatalog:
            BatalLocalization.resolve(language, ar: "فتح الكتالوج الكامل", en: "Unlock full catalog")
        }
    }

    func description(_ language: AppLanguage) -> String {
        switch self {
        case .singleUnlock:
            language == .arabic
                ? "يفتح رقم القطعة، الأرقام البديلة، وصورة/مؤشر صفحة الكتالوج للصفحة الحالية فقط."
                : "Unlocks the part number, alternates, and catalog page image/locator for the current page only."
        case .fullCatalog:
            language == .arabic
                ? "يفتح كل القطع المدفوعة في قاعدة الكتالوج الحالية بشكل دائم وقابل للاستعادة."
                : "Permanently unlocks all paid records in the current catalog and supports restore."
        }
    }

    func priceText(_ language: AppLanguage) -> String {
        language == .arabic ? fallbackPriceAr : fallbackPriceEn
    }
}

struct CatalogSource: Decodable, Identifiable, Hashable {
    let sourceID: String
    let filename: String?
    let year: String?
    let kind: String?
    let pageCount: Int?

    var id: String {
        sourceID
    }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id", filename, year, kind, pageCount = "page_count"
    }
}

struct Part: Decodable, Identifiable, Hashable {
    let partNumber: String
    let nameAr: String?
    let nameEn: String?
    let model: String?
    let years: [String]
    let engines: [String]
    let dateRanges: [String]
    let category: String?
    let categoryAr: String?
    let occurrenceCount: Int?
    let sourceCount: Int?
    let weightedSourceScore: Double?
    let confidence: Int?
    let auditStatus: String?
    let rarity: String?
    let evidence: [Evidence]
    let partNumbers: [String]
    let primaryOEMNumber: String?
    let diagramKey: String?

    var id: String {
        partNumber
    }

    enum CodingKeys: String, CodingKey {
        case partNumber = "part_number", nameAr = "name_ar", nameEn = "name_en", model, years, engines
        case dateRanges = "date_ranges", category, categoryAr = "category_ar", occurrenceCount = "occurrence_count"
        case sourceCount = "source_count", weightedSourceScore = "weighted_source_score", confidence
        case auditStatus = "audit_status", rarity, evidence, partNumbers = "part_numbers"
        case primaryOEMNumber = "primary_oem_number", diagramKey = "diagram_key"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        partNumber = try container.decodeIfPresent(String.self, forKey: .partNumber) ?? ""
        nameAr = try container.decodeIfPresent(String.self, forKey: .nameAr)
        nameEn = try container.decodeIfPresent(String.self, forKey: .nameEn)
        model = try container.decodeIfPresent(String.self, forKey: .model)
        years = try container.decodeFlexibleStringArray(forKey: .years)
        engines = try container.decodeFlexibleStringArray(forKey: .engines)
        dateRanges = try container.decodeFlexibleStringArray(forKey: .dateRanges)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        categoryAr = try container.decodeIfPresent(String.self, forKey: .categoryAr)
        occurrenceCount = try container.decodeFlexibleInt(forKey: .occurrenceCount)
        sourceCount = try container.decodeFlexibleInt(forKey: .sourceCount)
        weightedSourceScore = try container.decodeFlexibleDouble(forKey: .weightedSourceScore)
        confidence = try container.decodeFlexibleInt(forKey: .confidence)
        auditStatus = try container.decodeIfPresent(String.self, forKey: .auditStatus)
        rarity = try container.decodeIfPresent(String.self, forKey: .rarity)
        evidence = try container.decodeIfPresent([Evidence].self, forKey: .evidence) ?? []
        partNumbers = try container.decodeFlexibleStringArray(forKey: .partNumbers)
        primaryOEMNumber = try container.decodeIfPresent(String.self, forKey: .primaryOEMNumber)
        diagramKey = try container.decodeIfPresent(String.self, forKey: .diagramKey)
    }

    func title(language: AppLanguage) -> String {
        if language == .arabic { return nonEmpty(nameAr) ?? nonEmpty(nameEn) ?? partNumber }
        return nonEmpty(nameEn) ?? nonEmpty(nameAr) ?? partNumber
    }

    var allNumbers: [String] {
        Array(([partNumber, primaryOEMNumber].compactMap(nonEmpty) + partNumbers).filter { !$0.isEmpty }.uniqued()
            .prefix(8))
    }

    /// Maps the raw catalog `category` string to a known UI category.
    /// Documented fallback: an unknown or missing category resolves to `.general`
    /// rather than being dropped, so every part stays browsable.
    var categoryValue: CatalogCategory {
        guard let raw = category?.lowercased() else { return .general }
        return CatalogCategory(rawValue: raw) ?? .general
    }

    var isSharedCandidate: Bool {
        years.count >= 5 || engines.count >= 2 || (sourceCount ?? 0) >= 4
    }
}

/// Explains why a part appeared in the search results, so users can trust the ranking.
/// Ordered from strongest (exact number) to weakest (plain browse) signal.
enum PartMatchReason: String, CaseIterable, Identifiable {
    case exactNumber
    case alternateNumber
    case partialNumber
    case closeNumber
    case description
    case synonym
    case browse

    var id: String { rawValue }

    func label(_ language: AppLanguage) -> String {
        switch self {
        case .exactNumber: BatalLocalization.resolve(language, ar: "مطابقة رقم", en: "Number match")
        case .alternateNumber: BatalLocalization.resolve(language, ar: "رقم بديل", en: "Alternate number")
        case .partialNumber: BatalLocalization.resolve(language, ar: "رقم جزئي", en: "Partial number")
        case .closeNumber: BatalLocalization.resolve(language, ar: "رقم قريب", en: "Close number")
        case .description: BatalLocalization.resolve(language, ar: "مطابقة وصف", en: "Description match")
        case .synonym: BatalLocalization.resolve(language, ar: "مرادف", en: "Synonym match")
        case .browse: BatalLocalization.resolve(language, ar: "تصفح", en: "Browse")
        }
    }

    var symbol: String {
        switch self {
        case .exactNumber, .alternateNumber: "number"
        case .partialNumber, .closeNumber: "number.circle"
        case .description: "text.magnifyingglass"
        case .synonym: "textformat.abc"
        case .browse: "square.grid.2x2"
        }
    }

    var systemColorName: String {
        switch self {
        case .exactNumber: "green"
        case .alternateNumber, .partialNumber: "teal"
        case .closeNumber: "orange"
        case .description, .synonym: "blue"
        case .browse: "gray"
        }
    }
}

enum SmartPartIndicatorKind: String, CaseIterable, Identifiable {
    case priceScore
    case priceFairness
    case fitmentMatch
    case confidence

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .priceScore:
            BatalLocalization.resolve(language, ar: "تقييم السعر", en: "Price score")
        case .priceFairness:
            BatalLocalization.resolve(language, ar: "عدالة السعر", en: "Price fairness")
        case .fitmentMatch:
            BatalLocalization.resolve(language, ar: "المطابقة", en: "Fitment match")
        case .confidence:
            BatalLocalization.resolve(language, ar: "الثقة", en: "Confidence")
        }
    }

    var symbol: String {
        switch self {
        case .priceScore: "gauge.with.dots.needle.33percent"
        case .priceFairness: "questionmark.circle.fill"
        case .fitmentMatch: "scope"
        case .confidence: "checkmark.shield.fill"
        }
    }
}

struct SmartPartIndicator: Identifiable, Equatable {
    let kind: SmartPartIndicatorKind
    let value: String
    let summary: String
    let details: [String]
    let systemColorName: String

    var id: SmartPartIndicatorKind { kind }
}

struct Evidence: Decodable, Hashable {
    let sourceID: String?
    let year: String?
    let page: Int?
    let reference: String?
    let quantity: String?
    let context: String?

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id", year, page, reference, quantity, context
    }
}

struct StoreDirectory: Decodable {
    let verifiedStores: [VerifiedStore]
    enum CodingKeys: String, CodingKey { case verifiedStores = "verified_stores" }
}

struct VerifiedStore: Decodable, Identifiable, Hashable {
    let id: String
    let nameAr: String?
    let nameEn: String?
    let category: String?
    let website: String?
    let searchURLTemplate: String?

    enum CodingKeys: String, CodingKey {
        case id, category, website
        case nameAr = "name_ar", nameEn = "name_en", searchURLTemplate = "search_url_template"
    }

    func name(language: AppLanguage) -> String {
        language == .arabic ? (nameAr ?? nameEn ?? id) : (nameEn ?? nameAr ?? id)
    }

    func searchURL(partNumber: String) -> URL? {
        let template = searchURLTemplate ?? website ?? ""
        let value = template.replacingOccurrences(
            of: "{part_number}",
            with: partNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? partNumber
        )
        return URL(string: value)
    }
}

struct PartRequestPlan: Identifiable, Hashable {
    let id: String
    let titleAr: String
    let titleEn: String
    let descriptionAr: String
    let descriptionEn: String

    func title(_ language: AppLanguage) -> String {
        language == .arabic ? titleAr : titleEn
    }

    func description(_ language: AppLanguage) -> String {
        language == .arabic ? descriptionAr : descriptionEn
    }
}

struct SavedPartRequest: Identifiable, Codable, Hashable {
    var id = UUID()
    var createdAt = Date()
    var generation = "Y60"
    var year = ""
    var vin = ""
    var engine = ""
    var transmission = ""
    var partNumber = ""
    var partName = ""
    var notes = ""
    var planID = "basic"
    var draft = ""

    func normalizedForStorage() -> SavedPartRequest {
        var copy = self
        copy.generation = generation.trimmedForStorage(defaultValue: "Y60")
        copy.year = year.trimmedForStorage()
        copy.vin = vin.trimmedForStorage().uppercased()
        copy.engine = engine.trimmedForStorage()
        copy.transmission = transmission.trimmedForStorage()
        copy.partNumber = partNumber.trimmedForStorage().uppercased()
        copy.partName = partName.trimmedForStorage()
        copy.notes = notes.trimmedForStorage()
        copy.draft = draft.trimmedForStorage()
        return copy
    }
}

struct MaintenanceItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var date = Date()
    var title = ""
    var odometer = ""
    var notes = ""
}

struct VehicleProfile: Codable, Hashable {
    var generation = "Y60"
    var year = ""
    var vin = ""
    var engine = ""
    var transmission = ""
}

enum CustomerAccessMode: String, Codable, Hashable {
    case localEmail
}

struct CustomerProfile: Codable, Hashable {
    var accessMode: CustomerAccessMode = .localEmail
    var displayName = ""
    var email = ""
    var hasCompletedSignInChoice = false
}

private extension String {
    func trimmedForStorage(defaultValue: String = "") -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultValue : trimmed
    }
}
