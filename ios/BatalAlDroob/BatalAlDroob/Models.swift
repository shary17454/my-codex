import Foundation

// MARK: - Models

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic = "ar"
    case english = "en"
    var id: String {
        rawValue
    }

    var title: String {
        self == .arabic ? "العربية" : "English"
    }

    var locale: Locale {
        Locale(identifier: self == .arabic ? "ar_SA" : "en_US")
    }
}

enum CatalogCategory: String, CaseIterable, Identifiable {
    case all, engine, cooling, electrical, body, brake, suspension, interior, fuel, general
    var id: String {
        rawValue
    }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .all: language == .arabic ? "الكل" : "All"
        case .engine: language == .arabic ? "محرك" : "Engine"
        case .cooling: language == .arabic ? "تبريد" : "Cooling"
        case .electrical: language == .arabic ? "كهرباء" : "Electrical"
        case .body: language == .arabic ? "هيكل" : "Body"
        case .brake: language == .arabic ? "فرامل" : "Brake"
        case .suspension: language == .arabic ? "تعليق" : "Suspension"
        case .interior: language == .arabic ? "داخلية" : "Interior"
        case .fuel: language == .arabic ? "وقود" : "Fuel"
        case .general: language == .arabic ? "عام" : "General"
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
            language == .arabic ? "فتح صفحة كتالوج واحدة" : "Unlock one catalog page"
        case .fullCatalog:
            language == .arabic ? "فتح الكتالوج الكامل" : "Unlock full catalog"
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

    var categoryValue: CatalogCategory {
        guard let raw = category?.lowercased() else { return .general }
        return CatalogCategory(rawValue: raw) ?? .general
    }

    var isSharedCandidate: Bool {
        years.count >= 5 || engines.count >= 2 || (sourceCount ?? 0) >= 4
    }
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
    case guest
    case localEmail
}

struct CustomerProfile: Codable, Hashable {
    var accessMode: CustomerAccessMode = .guest
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
