import SwiftUI
import Observation
import StoreKit
import PhotosUI
import CoreTransferable
import MapKit
import CoreLocation
import Vision

@main
struct BatalAlDroobApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = CatalogViewModel(repository: BundledCatalogRepository(), store: StoreKitPurchaseService())

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
                .environment(\.layoutDirection, viewModel.language == .arabic ? .rightToLeft : .leftToRight)
                .task { await viewModel.load() }
                .onChange(of: scenePhase) { _, phase in
                    viewModel.isPrivacyShieldVisible = phase != .active
                }
        }
    }
}

// MARK: - Design Tokens

enum BatalDesign {
    static let cardRadius: CGFloat = 8
    static let compactSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 12
}

// MARK: - Models

enum AppLanguage: String, CaseIterable, Identifiable {
    case arabic = "ar"
    case english = "en"
    var id: String { rawValue }
    var title: String { self == .arabic ? "العربية" : "English" }
}

enum CatalogCategory: String, CaseIterable, Identifiable {
    case all, engine, cooling, electrical, body, brake, suspension, interior, fuel, general
    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.all, .arabic): "الكل"
        case (.engine, .arabic): "محرك"
        case (.cooling, .arabic): "تبريد"
        case (.electrical, .arabic): "كهرباء"
        case (.body, .arabic): "هيكل"
        case (.brake, .arabic): "فرامل"
        case (.suspension, .arabic): "تعليق"
        case (.interior, .arabic): "داخلية"
        case (.fuel, .arabic): "وقود"
        case (.general, .arabic): "عام"
        case (.all, .english): "All"
        case (.engine, .english): "Engine"
        case (.cooling, .english): "Cooling"
        case (.electrical, .english): "Electrical"
        case (.body, .english): "Body"
        case (.brake, .english): "Brake"
        case (.suspension, .english): "Suspension"
        case (.interior, .english): "Interior"
        case (.fuel, .english): "Fuel"
        case (.general, .english): "General"
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

struct CatalogPayload: Decodable, Sendable {
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

struct CatalogSource: Decodable, Identifiable, Hashable, Sendable {
    let sourceID: String
    let filename: String?
    let year: String?
    let kind: String?
    let pageCount: Int?

    var id: String { sourceID }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id", filename, year, kind, pageCount = "page_count"
    }
}

struct Part: Decodable, Identifiable, Hashable, Sendable {
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

    var id: String { partNumber }

    enum CodingKeys: String, CodingKey {
        case partNumber = "part_number", nameAr = "name_ar", nameEn = "name_en", model, years, engines
        case dateRanges = "date_ranges", category, categoryAr = "category_ar", occurrenceCount = "occurrence_count"
        case sourceCount = "source_count", weightedSourceScore = "weighted_source_score", confidence
        case auditStatus = "audit_status", rarity, evidence, partNumbers = "part_numbers"
        case primaryOEMNumber = "primary_oem_number", diagramKey = "diagram_key"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        partNumber = try c.decodeIfPresent(String.self, forKey: .partNumber) ?? ""
        nameAr = try c.decodeIfPresent(String.self, forKey: .nameAr)
        nameEn = try c.decodeIfPresent(String.self, forKey: .nameEn)
        model = try c.decodeIfPresent(String.self, forKey: .model)
        years = try c.decodeFlexibleStringArray(forKey: .years)
        engines = try c.decodeFlexibleStringArray(forKey: .engines)
        dateRanges = try c.decodeFlexibleStringArray(forKey: .dateRanges)
        category = try c.decodeIfPresent(String.self, forKey: .category)
        categoryAr = try c.decodeIfPresent(String.self, forKey: .categoryAr)
        occurrenceCount = try c.decodeFlexibleInt(forKey: .occurrenceCount)
        sourceCount = try c.decodeFlexibleInt(forKey: .sourceCount)
        weightedSourceScore = try c.decodeFlexibleDouble(forKey: .weightedSourceScore)
        confidence = try c.decodeFlexibleInt(forKey: .confidence)
        auditStatus = try c.decodeIfPresent(String.self, forKey: .auditStatus)
        rarity = try c.decodeIfPresent(String.self, forKey: .rarity)
        evidence = try c.decodeIfPresent([Evidence].self, forKey: .evidence) ?? []
        partNumbers = try c.decodeFlexibleStringArray(forKey: .partNumbers)
        primaryOEMNumber = try c.decodeIfPresent(String.self, forKey: .primaryOEMNumber)
        diagramKey = try c.decodeIfPresent(String.self, forKey: .diagramKey)
    }

    func title(language: AppLanguage) -> String {
        if language == .arabic { return nonEmpty(nameAr) ?? nonEmpty(nameEn) ?? partNumber }
        return nonEmpty(nameEn) ?? nonEmpty(nameAr) ?? partNumber
    }

    var allNumbers: [String] {
        Array(([partNumber, primaryOEMNumber].compactMap(nonEmpty) + partNumbers).filter { !$0.isEmpty }.uniqued().prefix(8))
    }

    var categoryValue: CatalogCategory {
        guard let raw = category?.lowercased() else { return .general }
        return CatalogCategory(rawValue: raw) ?? .general
    }

    var isSharedCandidate: Bool {
        years.count >= 5 || engines.count >= 2 || (sourceCount ?? 0) >= 4
    }
}

struct Evidence: Decodable, Hashable, Sendable {
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

struct StoreDirectory: Decodable, Sendable {
    let verifiedStores: [VerifiedStore]
    enum CodingKeys: String, CodingKey { case verifiedStores = "verified_stores" }
}

struct VerifiedStore: Decodable, Identifiable, Hashable, Sendable {
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

    func name(language: AppLanguage) -> String { language == .arabic ? (nameAr ?? nameEn ?? id) : (nameEn ?? nameAr ?? id) }
    func searchURL(partNumber: String) -> URL? {
        let template = searchURLTemplate ?? website ?? ""
        let value = template.replacingOccurrences(of: "{part_number}", with: partNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? partNumber)
        return URL(string: value)
    }
}

struct PartRequestPlan: Identifiable, Hashable, Sendable {
    let id: String
    let titleAr: String
    let titleEn: String
    let descriptionAr: String
    let descriptionEn: String

    func title(_ language: AppLanguage) -> String { language == .arabic ? titleAr : titleEn }
    func description(_ language: AppLanguage) -> String { language == .arabic ? descriptionAr : descriptionEn }
}

struct SavedPartRequest: Identifiable, Codable, Hashable, Sendable {
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
}

struct MaintenanceItem: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var date = Date()
    var title = ""
    var odometer = ""
    var notes = ""
}

struct VehicleProfile: Codable, Hashable, Sendable {
    var generation = "Y60"
    var year = ""
    var vin = ""
    var engine = ""
    var transmission = ""
}

// MARK: - Services

protocol CatalogRepository: Sendable {
    func loadCatalog() async throws -> CatalogPayload
    func loadStores() async throws -> [VerifiedStore]
}

struct BundledCatalogRepository: CatalogRepository {
    func loadCatalog() async throws -> CatalogPayload {
        try await decodeBundledJSON(CatalogPayload.self, resource: "y60_app_catalog", subdirectories: ["data", "Web/data"])
    }

    func loadStores() async throws -> [VerifiedStore] {
        let directory = try await decodeBundledJSON(StoreDirectory.self, resource: "store_directory", subdirectories: ["data", "Web/data"])
        return directory.verifiedStores
    }

    private func decodeBundledJSON<T: Decodable & Sendable>(_ type: T.Type, resource: String, subdirectories: [String]) async throws -> T {
        let url = subdirectories.lazy.compactMap {
            Bundle.main.url(forResource: resource, withExtension: "json", subdirectory: $0)
        }.first
        guard let url else {
            throw AppError.missingResource(resource)
        }
        return try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        }.value
    }
}

protocol PhotoTextRecognizing: Sendable {
    func recognizeText(in data: Data) async throws -> [String]
}

struct VisionPhotoTextRecognizer: PhotoTextRecognizing {
    func recognizeText(in data: Data) async throws -> [String] {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(data: data, options: [:])
            try handler.perform([request])
            return (request.results ?? []).compactMap { observation in
                observation.topCandidates(1).first?.string
            }
        }.value
    }
}

protocol PurchaseService: Sendable {
    func availableProductIDs(for productIDs: [String]) async throws -> Set<String>
    func purchase(productID: String) async throws -> PurchaseOutcome
    func restorePurchasedProductIDs() async throws -> Set<String>
}

enum PurchaseOutcome: Equatable, Sendable { case success, cancelled, pending }

struct StoreKitPurchaseService: PurchaseService {
    func availableProductIDs(for productIDs: [String]) async throws -> Set<String> {
        let products = try await Product.products(for: productIDs)
        return Set(products.map(\.id))
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { throw AppError.productUnavailable }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw AppError.unverifiedTransaction }
            await transaction.finish()
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            throw AppError.unknownPurchaseResult
        }
    }

    func restorePurchasedProductIDs() async throws -> Set<String> {
        var restored = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            restored.insert(transaction.productID)
        }
        return restored
    }
}

enum AppError: LocalizedError, Sendable {
    case missingResource(String), productUnavailable, unverifiedTransaction, unknownPurchaseResult, unreadablePhoto
    var errorDescription: String? {
        switch self {
        case .missingResource(let name): "Missing bundled resource: \(name)"
        case .productUnavailable: "In-app purchase is not ready yet."
        case .unverifiedTransaction: "Transaction verification failed."
        case .unknownPurchaseResult: "Unknown purchase result."
        case .unreadablePhoto: "The selected photo could not be read."
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class CatalogViewModel {
    private let repository: CatalogRepository
    private let store: PurchaseService
    private let photoTextRecognizer: any PhotoTextRecognizing
    private let catalogUnlockToken = "__catalog_unlock__"

    var language: AppLanguage = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "batalLang") ?? "ar") ?? .arabic {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "batalLang") }
    }
    var searchText = ""
    var selectedCategory: CatalogCategory = .all
    var selectedPart: Part?
    var isLoading = false
    var loadingMessage = ""
    var errorMessage: String?
    var paymentMessage: String?
    var isPrivacyShieldVisible = false
    var selectedPhoto: PhotosPickerItem?
    var selectedPhotoName: String?
    var isAnalyzingPhoto = false
    var isLoadingPurchases = false
    var availableProductIDs = Set<String>()

    private(set) var parts: [Part] = []
    private(set) var sources: [CatalogSource] = []
    private(set) var stores: [VerifiedStore] = []
    private(set) var generatedAt = ""
    private(set) var recordCount = 0
    private(set) var sourceCount = 0
    private(set) var partCount = 0
    private var partSearchIndex: [String: String] = [:]

    var vehicleProfile = UserDefaults.standard.codable(VehicleProfile.self, forKey: "batalVehicleProfile") ?? VehicleProfile() {
        didSet { UserDefaults.standard.setCodable(vehicleProfile, forKey: "batalVehicleProfile") }
    }
    var maintenanceItems = UserDefaults.standard.codable([MaintenanceItem].self, forKey: "batalMaintenanceLog") ?? [] {
        didSet { UserDefaults.standard.setCodable(maintenanceItems, forKey: "batalMaintenanceLog") }
    }
    var savedRequests = UserDefaults.standard.codable([SavedPartRequest].self, forKey: "batalPartRequests") ?? [] {
        didSet { UserDefaults.standard.setCodable(Array(savedRequests.prefix(50)), forKey: "batalPartRequests") }
    }
    var wishlist = Set(UserDefaults.standard.stringArray(forKey: "batalWishlist") ?? []) {
        didSet { UserDefaults.standard.set(Array(wishlist), forKey: "batalWishlist") }
    }
    var paidUnlocks = Set(UserDefaults.standard.stringArray(forKey: "batalPaidUnlocks") ?? []) {
        didSet { UserDefaults.standard.set(Array(paidUnlocks), forKey: "batalPaidUnlocks") }
    }

    let plans: [PartRequestPlan] = [
        .init(id: "basic", titleAr: "طلب عادي", titleEn: "Basic request", descriptionAr: "صياغة طلب القطعة وحفظه داخل التطبيق.", descriptionEn: "Prepare and save the part request inside the app."),
        .init(id: "urgent", titleAr: "طلب مستعجل", titleEn: "Urgent request", descriptionAr: "صياغة طلب مختصر وجاهز للمشاركة السريعة.", descriptionEn: "Prepare a concise request ready for quick sharing."),
        .init(id: "rare", titleAr: "طلب قطعة نادرة / NOS", titleEn: "Rare / NOS request", descriptionAr: "صياغة طلب مفصل للقطع النادرة أو المستعملة الأصلية.", descriptionEn: "Prepare a detailed request for rare, original used, or NOS parts.")
    ]
    var purchaseProductIDs: [String] { ["batal.catalog.unlock"] }

    init(
        repository: CatalogRepository,
        store: PurchaseService,
        photoTextRecognizer: any PhotoTextRecognizing = VisionPhotoTextRecognizer()
    ) {
        self.repository = repository
        self.store = store
        self.photoTextRecognizer = photoTextRecognizer
    }

    func load() async {
        guard parts.isEmpty else { return }
        isLoading = true
        loadingMessage = text(ar: "جاري تحميل قاعدة القطع...", en: "Loading catalog database...")
        defer { isLoading = false }
        do {
            async let catalogTask = repository.loadCatalog()
            async let storesTask = repository.loadStores()
            let catalog = try await catalogTask
            parts = catalog.parts.filter { !$0.partNumber.isEmpty }
            partSearchIndex = parts.reduce(into: [:]) { index, part in
                index[part.partNumber] = searchableText(for: part)
            }
            sources = catalog.sources
            generatedAt = catalog.generatedAt ?? ""
            recordCount = catalog.recordCount ?? parts.count
            sourceCount = catalog.sourceCount ?? catalog.sources.count
            partCount = catalog.partCount ?? parts.count
            stores = try await storesTask
            selectedPart = filteredParts.first
            await refreshPurchaseProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var filteredParts: [Part] {
        let query = normalized(searchText)
        return parts.lazy.filter { part in
            let categoryMatch = self.selectedCategory == .all || part.categoryValue == self.selectedCategory
            guard categoryMatch else { return false }
            guard !query.isEmpty else { return true }
            return (self.partSearchIndex[part.partNumber] ?? self.searchableText(for: part)).contains(query)
        }.prefix(250).map { $0 }
    }

    var sharedParts: [Part] { parts.filter(\.isSharedCandidate).prefix(80).map { $0 } }
    var wishlistParts: [Part] { parts.filter { wishlist.contains($0.partNumber) } }
    var reviewReadyParts: [Part] {
        parts
            .filter { !$0.evidence.isEmpty && !$0.years.isEmpty && !$0.engines.isEmpty }
            .sorted { ($0.confidence ?? 0) > ($1.confidence ?? 0) }
            .prefix(8)
            .map { $0 }
    }

    func text(ar: String, en: String) -> String { language == .arabic ? ar : en }
    func title(for part: Part) -> String { part.title(language: language) }
    func isUnlocked(_ part: Part) -> Bool { paidUnlocks.contains(catalogUnlockToken) || paidUnlocks.contains(part.partNumber) }
    func isProductAvailable(_ productID: String) -> Bool { availableProductIDs.contains(productID) }
    var purchaseSetupMessage: String {
        if isLoadingPurchases {
            return text(ar: "جاري التحقق من منتجات الشراء داخل التطبيق...", en: "Checking in-app purchase products...")
        }
        if availableProductIDs.isEmpty {
            return text(
                ar: "الدفع داخل التطبيق غير جاهز حاليًا. يمكنك استخدام البحث والكتالوج والأدوات المجانية، وسيتم تفعيل الشراء عند اعتماد منتجات App Store.",
                en: "In-app purchase is not ready yet. Free catalog search and tools remain available, and purchases will activate when App Store products are approved."
            )
        }
        return text(ar: "الدفع داخل التطبيق جاهز عبر Apple.", en: "In-app purchase is ready through Apple.")
    }
    func protectedNumber(_ part: Part) -> String { part.partNumber }
    func premiumNumber(_ number: String, for part: Part) -> String {
        number == part.partNumber || isUnlocked(part) ? number : masked(number)
    }

    func toggleWishlist(_ part: Part) {
        if wishlist.contains(part.partNumber) { wishlist.remove(part.partNumber) } else { wishlist.insert(part.partNumber) }
    }

    func unlock(_ part: Part) async {
        guard isProductAvailable("batal.catalog.unlock") else {
            paymentMessage = purchaseSetupMessage
            return
        }
        paymentMessage = text(ar: "جاري طلب الدفع...", en: "Requesting purchase...")
        do {
            let outcome = try await store.purchase(productID: "batal.catalog.unlock")
            switch outcome {
            case .success:
                paidUnlocks.insert(catalogUnlockToken)
                paidUnlocks.insert(part.partNumber)
                paymentMessage = text(ar: "تم الدفع وفتح المحتوى", en: "Payment complete. Content unlocked.")
            case .cancelled:
                paymentMessage = text(ar: "تم إلغاء عملية الدفع.", en: "Purchase was cancelled.")
            case .pending:
                paymentMessage = text(ar: "عملية الدفع معلقة.", en: "Purchase is pending.")
            }
        } catch {
            paymentMessage = purchaseErrorMessage(error)
        }
    }

    func saveRequestPlan(_ plan: PartRequestPlan, request: SavedPartRequest) {
        var saved = request
        saved.planID = plan.id
        saved.draft = buildDraft(for: saved, plan: plan)
        savedRequests.insert(saved, at: 0)
        paymentMessage = text(ar: "تم تجهيز طلب القطعة وحفظه.", en: "Part request was prepared and saved.")
    }

    func refreshPurchaseProducts() async {
        isLoadingPurchases = true
        defer { isLoadingPurchases = false }
        do {
            availableProductIDs = try await store.availableProductIDs(for: purchaseProductIDs)
        } catch {
            availableProductIDs = []
        }
    }

    func restorePurchases() async {
        paymentMessage = text(ar: "جاري استعادة المشتريات...", en: "Restoring purchases...")
        do {
            let restored = try await store.restorePurchasedProductIDs()
            if restored.contains("batal.catalog.unlock") {
                paidUnlocks.insert(catalogUnlockToken)
                paymentMessage = text(ar: "تمت استعادة فتح الكتالوج.", en: "Catalog unlock was restored.")
            } else {
                paymentMessage = text(ar: "لا توجد مشتريات مؤهلة للاستعادة.", en: "No eligible purchases were found to restore.")
            }
        } catch {
            paymentMessage = purchaseErrorMessage(error)
        }
    }

    private func purchaseErrorMessage(_ error: Error) -> String {
        if case AppError.productUnavailable = error {
            return purchaseSetupMessage
        }
        return text(ar: "تعذر إكمال عملية الشراء. حاول مرة أخرى أو استخدم الاستعادة إذا كنت اشتريت سابقًا.", en: "The purchase could not be completed. Try again, or use Restore Purchases if you purchased before.")
    }

    func buildDraft(for request: SavedPartRequest, plan: PartRequestPlan) -> String {
        partRequestDraft(for: request, plan: plan, language: language)
    }

    func addMaintenance(title: String, odometer: String, notes: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        maintenanceItems.insert(.init(title: title, odometer: odometer, notes: notes), at: 0)
    }

    func deleteMaintenance(at offsets: IndexSet) {
        maintenanceItems.remove(atOffsets: offsets)
    }

    func deleteSavedRequests(at offsets: IndexSet) {
        savedRequests.remove(atOffsets: offsets)
    }


    func applyDescriptionSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searchText = diagnosticKeywords(trimmed).joined(separator: " ")
        selectedCategory = .all
        selectedPart = filteredParts.first
    }

    func analyzePhoto(_ item: PhotosPickerItem) async {
        isAnalyzingPhoto = true
        selectedPhotoName = text(ar: "جاري تحليل الصورة محليًا...", en: "Analyzing the photo on device...")
        defer { isAnalyzingPhoto = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self), !data.isEmpty else {
                throw AppError.unreadablePhoto
            }
            try Task.checkCancellation()
            let recognizedLines = try await photoTextRecognizer.recognizeText(in: data)
            try Task.checkCancellation()
            applyRecognizedPhotoText(recognizedLines)
        } catch is CancellationError {
            return
        } catch {
            selectedPhotoName = nil
            errorMessage = text(
                ar: "تعذر قراءة نص واضح من الصورة. جرّب صورة أوضح يظهر فيها رقم القطعة.",
                en: "No clear text could be read from the photo. Try a sharper image showing the part number."
            )
        }
    }

    func applyRecognizedPhotoText(_ lines: [String]) {
        let recognizedText = lines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !recognizedText.isEmpty else {
            errorMessage = text(ar: "لم يظهر نص قابل للبحث في الصورة.", en: "No searchable text was found in the photo.")
            selectedPhotoName = nil
            return
        }

        let candidates = partNumberCandidates(in: recognizedText)
        let matchingNumber = candidates.first { candidate in
            let query = normalized(candidate)
            return parts.contains { part in
                (partSearchIndex[part.partNumber] ?? searchableText(for: part)).contains(query)
            }
        }
        let fallback = diagnosticKeywords(recognizedText).joined(separator: " ")
        searchText = matchingNumber ?? fallback
        selectedCategory = .all
        selectedPart = filteredParts.first
        selectedPhotoName = text(
            ar: "تمت قراءة الصورة والبحث عن: \(searchText)",
            en: "Photo analyzed. Searching for: \(searchText)"
        )
    }

    func tireDifference(oldSize: String, newSize: String) -> String {
        guard let old = tireDiameter(oldSize), let new = tireDiameter(newSize), old > 0 else {
            return text(ar: "أدخل المقاس بصيغة 265/70R16", en: "Enter size as 265/70R16")
        }
        let diff = ((new - old) / old) * 100
        return String(format: text(ar: "الفرق %.1f%%", en: "Difference %.1f%%"), diff)
    }

    func fitmentSummary(for query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return text(ar: "أدخل رقم قطعة أو وصفًا مختصرًا.", en: "Enter a part number or short description.")
        }
        let normalizedQuery = normalized(trimmed)
        let match = parts.first { part in
            part.partNumber.localizedCaseInsensitiveContains(trimmed)
                || part.allNumbers.contains { $0.localizedCaseInsensitiveContains(trimmed) }
                || self.searchableText(for: part).contains(normalizedQuery)
        }
        guard let match else {
            return text(
                ar: "لم أجد تطابقًا مباشرًا. جرّب رقم قطعة مثل 21082-4W000 أو اسم القسم.",
                en: "No direct match found. Try a part number such as 21082-4W000 or a category name."
            )
        }
        return [
            text(ar: "القطعة: \(title(for: match))", en: "Part: \(title(for: match))"),
            text(ar: "الرقم الأساسي: \(match.partNumber)", en: "Primary number: \(match.partNumber)"),
            text(ar: "السنوات: \(short(match.years))", en: "Years: \(short(match.years))"),
            text(ar: "المحركات: \(short(match.engines))", en: "Engines: \(short(match.engines))"),
            text(ar: "مصادر الكتالوج: \((match.sourceCount ?? match.evidence.count).formatted())", en: "Catalog sources: \((match.sourceCount ?? match.evidence.count).formatted())")
        ].joined(separator: "\n")
    }

    func fitmentMatches(for query: String) -> [Part] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let normalizedQuery = normalized(trimmed)
        return parts.lazy.filter { part in
            part.partNumber.localizedCaseInsensitiveContains(trimmed)
                || part.allNumbers.contains { $0.localizedCaseInsensitiveContains(trimmed) }
                || self.searchableText(for: part).contains(normalizedQuery)
        }
        .prefix(8)
        .map { $0 }
    }

    func categoryCount(_ category: CatalogCategory) -> Int {
        guard category != .all else { return parts.count }
        return parts.lazy.filter { $0.categoryValue == category }.count
    }

    func openStore(_ store: VerifiedStore, part: Part?) {
        let url = store.searchURL(partNumber: part?.partNumber ?? "") ?? URL(string: store.website ?? "")
        guard let url, isAllowedExternalURL(url) else {
            errorMessage = text(ar: "رابط المتجر غير صالح.", en: "The store link is invalid.")
            return
        }
        #if os(iOS)
        Task {
            let opened = await UIApplication.shared.open(url)
            if !opened {
                errorMessage = text(ar: "تعذر فتح رابط المتجر.", en: "The store link could not be opened.")
            }
        }
        #endif
    }

    private func searchableText(for part: Part) -> String {
        normalized(([part.partNumber, part.primaryOEMNumber, part.nameAr, part.nameEn, part.category, part.categoryAr, part.model] + part.partNumbers + part.years + part.engines).compactMap { $0 }.joined(separator: " "))
    }
}


@MainActor
@Observable
final class LocationWeatherViewModel: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pendingStartLanguage: AppLanguage?
    private var lastWeatherLocation: CLLocation?
    private var lastWeatherUpdate: Date?
    private var currentLanguage: AppLanguage = .arabic
    private var weatherTask: Task<Void, Never>?

    var authorization: CLAuthorizationStatus = .notDetermined
    var coordinate: CLLocationCoordinate2D?
    var altitude: CLLocationDistance?
    var horizontalAccuracy: CLLocationAccuracy?
    var headingDegrees: CLLocationDirection?
    var isTracking = false
    var locationMessage = ""
    var weatherSummary = ""
    var weatherError: String?
    var isLoadingWeather = false
    var cameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753), span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)))

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
        manager.headingFilter = 3
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = true
        authorization = manager.authorizationStatus
    }

    func requestAndStart(language: AppLanguage) {
        authorization = manager.authorizationStatus
        if authorization == .notDetermined {
            pendingStartLanguage = language
            locationMessage = language == .arabic ? "بانتظار موافقة الموقع..." : "Waiting for location permission..."
            manager.requestWhenInUseAuthorization()
            return
        }
        start(language: language)
    }

    func start(language: AppLanguage) {
        currentLanguage = language
        authorization = manager.authorizationStatus
        guard authorization == .authorizedAlways || authorization == .authorizedWhenInUse else {
            locationMessage = language == .arabic ? "فعّل صلاحية الموقع لاستخدام التتبع والبوصلة." : "Enable location permission to use tracking and compass."
            return
        }
        isTracking = true
        locationMessage = language == .arabic ? "التتبع يعمل" : "Tracking active"
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        } else {
            headingDegrees = nil
            locationMessage = language == .arabic ? "التتبع يعمل. البوصلة غير متاحة على هذا الجهاز." : "Tracking active. Compass is not available on this device."
        }
    }

    func stop(language: AppLanguage) {
        pauseTracking()
        locationMessage = language == .arabic ? "تم إيقاف التتبع" : "Tracking stopped"
    }

    func pauseTracking() {
        isTracking = false
        weatherTask?.cancel()
        weatherTask = nil
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        isLoadingWeather = false
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if let language = self.pendingStartLanguage {
                self.pendingStartLanguage = nil
                if status == .authorizedAlways || status == .authorizedWhenInUse {
                    self.start(language: language)
                } else {
                    self.locationMessage = language == .arabic ? "لم يتم منح صلاحية الموقع." : "Location permission was not granted."
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let altitude = location.altitude
        let horizontalAccuracy = location.horizontalAccuracy
        Task { @MainActor in
            guard self.isTracking else { return }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.coordinate = coordinate
            self.altitude = altitude
            self.horizontalAccuracy = horizontalAccuracy
            self.cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
            self.scheduleWeatherLoad(for: CLLocation(latitude: latitude, longitude: longitude))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.headingDegrees = value
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.pauseTracking()
            self.locationMessage = self.currentLanguage == .arabic
                ? "تعذر تحديث الموقع. تحقق من الصلاحية وحاول مرة أخرى."
                : "Location could not be updated. Check permission and try again."
        }
    }

    private func scheduleWeatherLoad(for location: CLLocation) {
        if let lastWeatherLocation, let lastWeatherUpdate {
            let recentlyUpdated = Date().timeIntervalSince(lastWeatherUpdate) < 600
            let nearby = location.distance(from: lastWeatherLocation) < 1_000
            if recentlyUpdated && nearby { return }
        }
        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled else { return }
            await self?.loadWeather(for: location)
        }
    }

    func loadWeather(for location: CLLocation) async {
        if let lastWeatherLocation, let lastWeatherUpdate {
            let recentlyUpdated = Date().timeIntervalSince(lastWeatherUpdate) < 600
            let nearby = location.distance(from: lastWeatherLocation) < 1_000
            if recentlyUpdated && nearby { return }
        }
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        do {
            let weather = try await OpenMeteoWeatherService.fetch(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let temp = Measurement(value: weather.current.temperature2m, unit: UnitTemperature.celsius)
                .formatted(.measurement(width: .abbreviated, usage: .weather))
            weatherSummary = "\(temp) · \(weather.current.condition(language: currentLanguage))"
            weatherError = nil
            lastWeatherLocation = location
            lastWeatherUpdate = Date()
        } catch is CancellationError {
            return
        } catch {
            weatherError = currentLanguage == .arabic ? "تعذر تحديث الطقس. تحقق من الاتصال ثم حاول مرة أخرى." : "Weather could not be updated. Check your connection and try again."
        }
    }
}

enum WeatherServiceError: Error, Sendable {
    case invalidCoordinates
    case httpStatus(Int)
}

struct OpenMeteoWeatherService {
    static func fetch(latitude: Double, longitude: Double) async throws -> OpenMeteoWeather {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw WeatherServiceError.invalidCoordinates
        }
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code")
        ]
        guard let url = components?.url else { throw URLError(.badURL) }
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)

        for attempt in 0..<2 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                guard (200..<300).contains(http.statusCode) else { throw WeatherServiceError.httpStatus(http.statusCode) }
                return try JSONDecoder().decode(OpenMeteoWeather.self, from: data)
            } catch {
                guard attempt == 0, shouldRetryWeatherRequest(after: error) else { throw error }
                try await Task.sleep(for: .milliseconds(400))
            }
        }
        throw URLError(.unknown)
    }
}

struct OpenMeteoWeather: Decodable, Sendable {
    let current: Current

    struct Current: Decodable, Sendable {
        let temperature2m: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }

        func condition(language: AppLanguage) -> String {
            switch weatherCode {
            case 0: language == .arabic ? "صحو" : "Clear"
            case 1, 2: language == .arabic ? "غائم جزئياً" : "Partly cloudy"
            case 3: language == .arabic ? "غائم" : "Cloudy"
            case 45, 48: language == .arabic ? "ضباب" : "Fog"
            case 51, 53, 55, 61, 63, 65, 80, 81, 82: language == .arabic ? "أمطار" : "Rain"
            case 95, 96, 99: language == .arabic ? "عواصف" : "Thunderstorm"
            default: language == .arabic ? "طقس محلي" : "Local weather"
            }
        }
    }
}

// MARK: - Views

struct RootView: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        ZStack {
            TabView {
                DashboardView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "الرئيسية", en: "Home"), systemImage: "gauge.with.dots.needle.bottom.50percent") }
                CatalogView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "الكتالوج", en: "Catalog"), systemImage: "magnifyingglass") }
                SharedFitmentView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "المشتركة", en: "Fitment"), systemImage: "point.3.connected.trianglepath.dotted") }
                RequestView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "طلب قطعة", en: "Request"), systemImage: "cart.badge.plus") }
                MaintenanceView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "الصيانة", en: "Maintenance"), systemImage: "wrench.adjustable") }
                MoreView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "الأدوات", en: "Tools"), systemImage: "wrench.and.screwdriver") }
            }
            .overlay(alignment: .top) {
                PaymentBanner(
                    message: viewModel.paymentMessage,
                    dismissLabel: viewModel.text(ar: "إغلاق", en: "Dismiss")
                ) {
                    viewModel.paymentMessage = nil
                }
            }

            if viewModel.isLoading { LoadingOverlay(message: viewModel.loadingMessage) }
            if viewModel.isPrivacyShieldVisible { PrivacyShieldView(language: viewModel.language) }
        }
        .alert(viewModel.text(ar: "تنبيه", en: "Notice"), isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button(viewModel.text(ar: "حسنًا", en: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct DashboardView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var fitmentQuery = "21082-4W000"
    @State private var fitmentResult = ""
    @State private var fitmentMatches: [Part] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("بطل الدروب")
                            .font(.largeTitle.bold())
                        Text(viewModel.text(
                            ar: "تطبيق أصلي للبحث في قطع نيسان باترول، التحقق من التوافق، حفظ الصيانة، وتجهيز طلبات القطع.",
                            en: "A native app for Nissan Patrol parts search, fitment checks, maintenance logging, and part request preparation."
                        ))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section(viewModel.text(ar: "لوحة الكتالوج المحلي", en: "Native catalog dashboard")) {
                    StatsHeader(viewModel: viewModel)
                    ForEach(CatalogCategory.allCases.filter { $0 != .all }.prefix(6)) { category in
                        LabeledContent(category.title(viewModel.language), value: viewModel.categoryCount(category).formatted())
                    }
                }

                Section(viewModel.text(ar: "عينات مدققة قابلة للفتح", en: "Verified native records")) {
                    ForEach(viewModel.reviewReadyParts) { part in
                        NavigationLink(value: part) {
                            PartRow(part: part, viewModel: viewModel)
                        }
                    }
                }

                Section(viewModel.text(ar: "وظائف تعمل بدون شراء", en: "Included functionality")) {
                    FeatureRow(symbol: "number.square", title: viewModel.text(ar: "إظهار رقم القطعة الأساسي", en: "Primary part number"), detail: viewModel.text(ar: "الرقم الأساسي وبيانات السنوات والمحركات ظاهرة مباشرة.", en: "The primary number, years, and engine data are visible immediately."))
                    FeatureRow(symbol: "doc.text.magnifyingglass", title: viewModel.text(ar: "بحث كتالوج محلي", en: "Local catalog search"), detail: viewModel.text(ar: "يبحث داخل قاعدة مدمجة ولا يحتاج تسجيل دخول.", en: "Searches a bundled database without sign-in."))
                    FeatureRow(symbol: "wrench.and.screwdriver", title: viewModel.text(ar: "سجل صيانة وأدوات", en: "Maintenance and tools"), detail: viewModel.text(ar: "حفظ صيانة السيارة، حساب الكفرات، تتبع الموقع، البوصلة، والطقس.", en: "Save maintenance, calculate tire changes, and use location, compass, and weather tools."))
                }

                Section(viewModel.text(ar: "تحقق سريع من التوافق", en: "Quick fitment check")) {
                    TextField(viewModel.text(ar: "رقم القطعة أو الوصف", en: "Part number or description"), text: $fitmentQuery)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button {
                        fitmentResult = viewModel.fitmentSummary(for: fitmentQuery)
                        fitmentMatches = viewModel.fitmentMatches(for: fitmentQuery)
                    } label: {
                        Label(viewModel.text(ar: "تحقق الآن", en: "Check now"), systemImage: "checkmark.seal")
                    }
                    if !fitmentResult.isEmpty {
                        Text(fitmentResult)
                            .font(.callout.monospaced())
                            .textSelection(.enabled)
                    }
                    ForEach(fitmentMatches) { part in
                        NavigationLink(value: part) {
                            PartRow(part: part, viewModel: viewModel)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.text(ar: "الرئيسية", en: "Home"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { PartDetailView(part: $0, viewModel: viewModel) }
            .onAppear {
                if fitmentResult.isEmpty {
                    fitmentResult = viewModel.fitmentSummary(for: fitmentQuery)
                    fitmentMatches = viewModel.fitmentMatches(for: fitmentQuery)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CatalogView: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        NavigationStack {
            List {
                Section { StatsHeader(viewModel: viewModel) }
                Section {
                    Picker(viewModel.text(ar: "القسم", en: "Category"), selection: $viewModel.selectedCategory) {
                        ForEach(CatalogCategory.allCases) { category in
                            Label(category.title(viewModel.language), systemImage: category.symbol).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(viewModel.text(ar: "النتائج", en: "Results")) {
                    if viewModel.filteredParts.isEmpty {
                        EmptyStateView(
                            symbol: "magnifyingglass",
                            title: viewModel.text(ar: "لا توجد نتائج", en: "No results"),
                            message: viewModel.text(ar: "جرّب رقم قطعة، اسم قسم، سنة، أو محرك مختلف.", en: "Try another part number, category, year, or engine.")
                        )
                    } else {
                        ForEach(viewModel.filteredParts) { part in
                            NavigationLink(value: part) { PartRow(part: part, viewModel: viewModel) }
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: viewModel.text(ar: "رقم القطعة، الاسم، القسم، أو VIN", en: "Part number, name, category, or VIN"))
            .navigationTitle("بطل الدروب")
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { part in PartDetailView(part: part, viewModel: viewModel) }
        }
    }
}

struct StatsHeader: View {
    @Bindable var viewModel: CatalogViewModel
    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                StatCard(title: viewModel.text(ar: "قطع مفهرسة", en: "Indexed parts"), value: viewModel.partCount.formatted(), symbol: "shippingbox")
                StatCard(title: viewModel.text(ar: "سجلات", en: "Records"), value: viewModel.recordCount.formatted(), symbol: "doc.text.magnifyingglass")
            }
            GridRow {
                StatCard(title: viewModel.text(ar: "مصادر", en: "Sources"), value: viewModel.sourceCount.formatted(), symbol: "books.vertical")
                StatCard(title: viewModel.text(ar: "مفضلة", en: "Wishlist"), value: viewModel.wishlist.count.formatted(), symbol: "heart")
            }
        }
        .padding(.vertical, 6)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.tint)
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
    }
}

struct PartRow: View {
    let part: Part
    @Bindable var viewModel: CatalogViewModel
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: part.categoryValue.symbol)
                .frame(width: 34, height: 34)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title(for: part)).font(.headline).lineLimit(1)
                Text(viewModel.protectedNumber(part)).font(.subheadline.monospaced()).foregroundStyle(.secondary)
                Text([part.model, part.categoryAr ?? part.category, part.years.prefix(3).joined(separator: ", ")].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if part.confidence != nil { ConfidenceBadge(value: part.confidence ?? 0) }
        }
        .contentShape(Rectangle())
    }
}

struct ConfidenceBadge: View {
    let value: Int
    var body: some View {
        Text("\(value)%")
            .font(.caption.bold()).monospacedDigit()
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(value >= 80 ? .green.opacity(0.18) : .orange.opacity(0.18), in: Capsule())
            .foregroundStyle(value >= 80 ? .green : .orange)
    }
}

struct PartDetailView: View {
    let part: Part
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.title(for: part)).font(.title2.bold())
                    Text(viewModel.protectedNumber(part)).font(.title3.monospaced()).foregroundStyle(.tint)
                    if !viewModel.isUnlocked(part) {
                        Text(viewModel.purchaseSetupMessage)
                            .font(.caption)
                            .foregroundStyle(viewModel.availableProductIDs.isEmpty ? .orange : .secondary)
                        Button { Task { await viewModel.unlock(part) } } label: {
                            Label(viewModel.text(ar: "فتح الأرقام البديلة والأدلة المتقدمة", en: "Unlock alternate numbers and advanced evidence"), systemImage: "lock.open")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.isProductAvailable("batal.catalog.unlock") || viewModel.isLoadingPurchases)
                        Button { Task { await viewModel.restorePurchases() } } label: {
                            Label(viewModel.text(ar: "استعادة المشتريات", en: "Restore Purchases"), systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            Section(viewModel.text(ar: "معلومات", en: "Information")) {
                LabeledContent(viewModel.text(ar: "الموديل", en: "Model"), value: part.model ?? "Y60")
                LabeledContent(viewModel.text(ar: "القسم", en: "Category"), value: part.categoryAr ?? part.categoryValue.title(viewModel.language))
                LabeledContent(viewModel.text(ar: "السنوات", en: "Years"), value: short(part.years))
                LabeledContent(viewModel.text(ar: "المحركات", en: "Engines"), value: short(part.engines))
                LabeledContent(viewModel.text(ar: "حالة التدقيق", en: "Audit"), value: part.auditStatus ?? "-")
                LabeledContent(viewModel.text(ar: "الندرة", en: "Rarity"), value: part.rarity ?? "-")
            }
            Section(viewModel.text(ar: "أرقام القطعة", en: "Part numbers")) {
                ForEach(part.allNumbers, id: \.self) { number in
                    Text(viewModel.premiumNumber(number, for: part)).font(.body.monospaced())
                }
            }
            Section(viewModel.text(ar: "رسم كتالوج تقريبي", en: "Catalog diagram")) {
                NativeDiagramView(part: part)
                    .frame(height: 220)
                    .accessibilityLabel(viewModel.text(ar: "رسم يوضح رقم النداء التقريبي للقطعة", en: "Diagram showing the approximate part callout"))
            }
            Section(viewModel.text(ar: "الأدلة", en: "Evidence")) {
                if part.evidence.isEmpty {
                    EmptyStateView(
                        symbol: "doc.text.magnifyingglass",
                        title: viewModel.text(ar: "لا توجد أدلة مفصلة", en: "No detailed evidence"),
                        message: viewModel.text(ar: "يعرض التطبيق البيانات الأساسية المتاحة لهذه القطعة.", en: "The app shows the available basic data for this part.")
                    )
                } else {
                    ForEach(Array(part.evidence.prefix(8).enumerated()), id: \.offset) { _, evidence in
                        VStack(alignment: .leading, spacing: 4) {
                            Text([evidence.sourceID, evidence.year, evidence.page.map { "p.\($0)" }, evidence.reference].compactMap { $0 }.joined(separator: " · "))
                                .font(.subheadline.bold())
                            if let context = evidence.context { Text(context).font(.caption).foregroundStyle(.secondary).lineLimit(4) }
                        }
                    }
                }
            }
            Section(viewModel.text(ar: "متاجر موثقة", en: "Verified stores")) {
                ForEach(viewModel.stores.prefix(8)) { store in
                    Button { viewModel.openStore(store, part: part) } label: {
                        Label(store.name(language: viewModel.language), systemImage: "safari")
                    }
                }
            }
        }
        .navigationTitle(part.partNumber)
        .toolbar {
            Button { viewModel.toggleWishlist(part) } label: {
                Image(systemName: viewModel.wishlist.contains(part.partNumber) ? "heart.fill" : "heart")
            }
            .accessibilityLabel(viewModel.text(
                ar: viewModel.wishlist.contains(part.partNumber) ? "إزالة من قائمة الرغبات" : "إضافة إلى قائمة الرغبات",
                en: viewModel.wishlist.contains(part.partNumber) ? "Remove from wishlist" : "Add to wishlist"
            ))
        }
    }
}

struct NativeDiagramView: View {
    let part: Part
    var body: some View {
        Canvas { context, size in
            let box = CGRect(x: 30, y: 42, width: size.width - 60, height: 104)
            context.stroke(Path(roundedRect: box, cornerRadius: 14), with: .color(.secondary), lineWidth: 2)
            let callout = CGRect(x: size.width * 0.52, y: 82, width: 82, height: 42)
            context.fill(Path(roundedRect: callout, cornerRadius: 10), with: .color(.red.opacity(0.22)))
            context.stroke(Path(roundedRect: callout, cornerRadius: 10), with: .color(.red), lineWidth: 3)
            let text = Text(part.partNumber).font(.caption.monospaced().bold()).foregroundStyle(.primary)
            context.draw(text, at: CGPoint(x: callout.midX, y: callout.midY), anchor: .center)
        }
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
    }
}

struct SharedFitmentView: View {
    @Bindable var viewModel: CatalogViewModel
    var body: some View {
        NavigationStack {
            List(viewModel.sharedParts) { part in
                NavigationLink(value: part) { PartRow(part: part, viewModel: viewModel) }
            }
            .navigationTitle(viewModel.text(ar: "القطع المشتركة", en: "Shared fitment"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { PartDetailView(part: $0, viewModel: viewModel) }
        }
    }
}

struct RequestView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var request = SavedPartRequest()
    @State private var selectedPlanID = "basic"

    var selectedPlan: PartRequestPlan { viewModel.plans.first { $0.id == selectedPlanID } ?? viewModel.plans[0] }

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.text(ar: "نوع الطلب", en: "Request type")) {
                    Picker(viewModel.text(ar: "الخطة", en: "Plan"), selection: $selectedPlanID) {
                        ForEach(viewModel.plans) { plan in Text(plan.title(viewModel.language)).tag(plan.id) }
                    }
                    Text(selectedPlan.description(viewModel.language)).font(.caption).foregroundStyle(.secondary)
                    Text(viewModel.text(ar: "طلب القطعة هنا لا يتطلب دفعًا. الشراء داخل التطبيق مخصص فقط لفتح الكتالوج المحمي عند توفره.", en: "Part requests do not require payment. In-app purchase is used only for protected catalog unlock when available."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section(viewModel.text(ar: "بيانات السيارة", en: "Vehicle")) {
                    TextField("Y60", text: $request.generation)
                    TextField(viewModel.text(ar: "سنة الصنع", en: "Year"), text: $request.year)
                        .keyboardType(.numberPad)
                    TextField("VIN", text: $request.vin)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField(viewModel.text(ar: "المحرك", en: "Engine"), text: $request.engine)
                    TextField(viewModel.text(ar: "القير", en: "Transmission"), text: $request.transmission)
                }
                Section(viewModel.text(ar: "بيانات القطعة", en: "Part")) {
                    TextField(viewModel.text(ar: "رقم القطعة", en: "Part number"), text: $request.partNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField(viewModel.text(ar: "اسم القطعة", en: "Part name"), text: $request.partName)
                    TextField(viewModel.text(ar: "ملاحظات", en: "Notes"), text: $request.notes, axis: .vertical)
                    Button { viewModel.saveRequestPlan(selectedPlan, request: request) } label: {
                        Label(viewModel.text(ar: "تجهيز الطلب وحفظه", en: "Prepare and save request"), systemImage: "square.and.pencil")
                    }
                    .disabled(request.partNumber.isEmpty && request.partName.isEmpty)
                }
                Section(viewModel.text(ar: "طلبات محفوظة", en: "Saved requests")) {
                    if viewModel.savedRequests.isEmpty {
                        EmptyStateView(
                            symbol: "tray",
                            title: viewModel.text(ar: "لا توجد طلبات محفوظة", en: "No saved requests"),
                            message: viewModel.text(ar: "بعد تجهيز الطلب سيظهر هنا نص الطلب المحفوظ.", en: "Prepared part requests will appear here.")
                        )
                    } else {
                        ForEach(viewModel.savedRequests) { saved in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(saved.partNumber.isEmpty ? saved.partName : saved.partNumber).font(.headline)
                                    Spacer()
                                    ShareLink(item: saved.draft) {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                    .accessibilityLabel(viewModel.text(ar: "مشاركة طلب القطعة", en: "Share part request"))
                                }
                                Text(saved.draft).font(.caption).foregroundStyle(.secondary).lineLimit(4)
                            }
                        }
                        .onDelete(perform: viewModel.deleteSavedRequests)
                    }
                }
            }
            .navigationTitle(viewModel.text(ar: "طلب قطعة", en: "Part request"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
        }
    }
}

struct MaintenanceView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var title = ""
    @State private var odometer = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.text(ar: "ملف السيارة", en: "Vehicle profile")) {
                    TextField("Y60", text: $viewModel.vehicleProfile.generation)
                    TextField(viewModel.text(ar: "السنة", en: "Year"), text: $viewModel.vehicleProfile.year)
                        .keyboardType(.numberPad)
                    TextField("VIN", text: $viewModel.vehicleProfile.vin)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField(viewModel.text(ar: "المحرك", en: "Engine"), text: $viewModel.vehicleProfile.engine)
                    TextField(viewModel.text(ar: "القير", en: "Transmission"), text: $viewModel.vehicleProfile.transmission)
                }
                Section(viewModel.text(ar: "إضافة صيانة", en: "Add maintenance")) {
                    TextField(viewModel.text(ar: "العنوان", en: "Title"), text: $title)
                    TextField(viewModel.text(ar: "العداد", en: "Odometer"), text: $odometer)
                        .keyboardType(.numberPad)
                    TextField(viewModel.text(ar: "ملاحظات", en: "Notes"), text: $notes, axis: .vertical)
                    Button(viewModel.text(ar: "حفظ", en: "Save")) {
                        viewModel.addMaintenance(title: title, odometer: odometer, notes: notes)
                        title = ""; odometer = ""; notes = ""
                    }
                }
                Section(viewModel.text(ar: "السجل", en: "Log")) {
                    if viewModel.maintenanceItems.isEmpty {
                        EmptyStateView(
                            symbol: "wrench.adjustable",
                            title: viewModel.text(ar: "لا توجد صيانة محفوظة", en: "No maintenance yet"),
                            message: viewModel.text(ar: "أضف أول عملية صيانة لحفظ سجل السيارة محليًا.", en: "Add the first service entry to keep a local vehicle log.")
                        )
                    } else {
                        ForEach(viewModel.maintenanceItems) { item in
                            VStack(alignment: .leading) {
                                Text(item.title).font(.headline)
                                Text([item.odometer, item.notes].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: viewModel.deleteMaintenance)
                    }
                }
            }
            .navigationTitle(viewModel.text(ar: "الصيانة", en: "Maintenance"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
        }
    }
}

struct MoreView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var locationWeather = LocationWeatherViewModel()
    @State private var descriptionQuery = ""
    @State private var oldTireSize = "265/70R16"
    @State private var newTireSize = "285/75R16"
    @State private var tireResult = ""

    var body: some View {
        let photoPickerTitle = viewModel.text(ar: "اختيار صورة كمرجع", en: "Choose reference photo")
        return NavigationStack {
            List {
                Section(viewModel.text(ar: "اللغة", en: "Language")) { LanguageMenu(viewModel: viewModel) }
                Section(viewModel.text(ar: "بحث بالوصف والصورة", en: "Description and photo search")) {
                    TextField(viewModel.text(ar: "اكتب وصف العطل أو القطعة", en: "Describe the fault or part"), text: $descriptionQuery, axis: .vertical)
                    Button { viewModel.applyDescriptionSearch(descriptionQuery) } label: {
                        Label(viewModel.text(ar: "بحث بالوصف", en: "Search by description"), systemImage: "text.magnifyingglass")
                    }
                    PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                        Label(photoPickerTitle, systemImage: "photo")
                    }
                    .task(id: viewModel.selectedPhoto) {
                        guard let item = viewModel.selectedPhoto else { return }
                        await viewModel.analyzePhoto(item)
                    }
                    if viewModel.isAnalyzingPhoto {
                        ProgressView(viewModel.text(ar: "تحليل الصورة على الجهاز", en: "Analyzing on device"))
                    }
                    if let selectedPhotoName = viewModel.selectedPhotoName {
                        Text(selectedPhotoName).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section(viewModel.text(ar: "حاسبة الكفرات", en: "Tire calculator")) {
                    TextField(viewModel.text(ar: "المقاس القديم", en: "Old size"), text: $oldTireSize)
                    TextField(viewModel.text(ar: "المقاس الجديد", en: "New size"), text: $newTireSize)
                    Button(viewModel.text(ar: "احسب الفرق", en: "Calculate difference")) {
                        tireResult = viewModel.tireDifference(oldSize: oldTireSize, newSize: newTireSize)
                    }
                    if !tireResult.isEmpty { Text(tireResult).font(.headline) }
                }
                Section(viewModel.text(ar: "قائمة الرغبات", en: "Wishlist")) {
                    if viewModel.wishlistParts.isEmpty {
                        EmptyStateView(
                            symbol: "heart",
                            title: viewModel.text(ar: "قائمة الرغبات فارغة", en: "Wishlist is empty"),
                            message: viewModel.text(ar: "افتح أي قطعة واضغط القلب لحفظها هنا.", en: "Open a part and tap the heart to save it here.")
                        )
                    } else {
                        ForEach(viewModel.wishlistParts) { part in
                            NavigationLink(value: part) {
                                PartRow(part: part, viewModel: viewModel)
                            }
                        }
                    }
                }
                Section(viewModel.text(ar: "المتاجر الموثقة", en: "Verified stores")) {
                    ForEach(viewModel.stores) { store in
                        Button { viewModel.openStore(store, part: nil) } label: { Label(store.name(language: viewModel.language), systemImage: "link") }
                    }
                }
                Section(viewModel.text(ar: "التتبع والبوصلة والطقس", en: "Tracking, compass, and weather")) {
                    Map(position: $locationWeather.cameraPosition) {
                        if let coordinate = locationWeather.coordinate {
                            Marker(viewModel.text(ar: "موقعي", en: "My location"), coordinate: coordinate)
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: BatalDesign.cardRadius))

                    HStack {
                        Button { locationWeather.requestAndStart(language: viewModel.language) } label: {
                            Label(viewModel.text(ar: "تشغيل التتبع", en: "Start tracking"), systemImage: "location.fill")
                        }
                        Button { locationWeather.stop(language: viewModel.language) } label: {
                            Label(viewModel.text(ar: "إيقاف", en: "Stop"), systemImage: "pause.circle")
                        }
                    }
                    if let coordinate = locationWeather.coordinate {
                        LabeledContent(viewModel.text(ar: "الإحداثيات", en: "Coordinates"), value: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude))
                    }
                    if let heading = locationWeather.headingDegrees {
                        LabeledContent(viewModel.text(ar: "البوصلة", en: "Compass"), value: String(format: "%.0f°", heading))
                        CompassDial(degrees: heading)
                            .frame(height: 120)
                            .accessibilityLabel(viewModel.text(ar: "اتجاه البوصلة", en: "Compass heading"))
                    }
                    if !locationWeather.weatherSummary.isEmpty {
                        LabeledContent(viewModel.text(ar: "الطقس", en: "Weather"), value: locationWeather.weatherSummary)
                    }
                    if locationWeather.isLoadingWeather {
                        HStack {
                            ProgressView()
                            Text(viewModel.text(ar: "جاري تحديث الطقس...", en: "Updating weather..."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let weatherError = locationWeather.weatherError {
                        Text(viewModel.text(ar: "تعذر تحميل الطقس: ", en: "Weather unavailable: ") + weatherError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                        if let coordinate = locationWeather.coordinate {
                            Button {
                                Task {
                                    await locationWeather.loadWeather(
                                        for: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                    )
                                }
                            } label: {
                                Label(viewModel.text(ar: "إعادة المحاولة", en: "Retry"), systemImage: "arrow.clockwise")
                            }
                        }
                    }
                    if !locationWeather.locationMessage.isEmpty {
                        Text(locationWeather.locationMessage).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section(viewModel.text(ar: "سياسة البيانات", en: "Data policy")) {
                    Text(viewModel.text(
                        ar: "التطبيق مستقل ولا يتبع نيسان، ولا ينسخ أسعار المتاجر أو مخزونها. تُفتح روابط المتاجر الموثقة لإكمال البحث أو الشراء خارج التطبيق.",
                        en: "This app is independent from Nissan and does not copy store prices or inventory. Verified store links open externally to continue searching or purchasing."
                    ))
                }
            }
            .navigationTitle(viewModel.text(ar: "المزيد", en: "More"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { part in
                PartDetailView(part: part, viewModel: viewModel)
            }
            .onDisappear { locationWeather.pauseTracking() }
        }
    }
}


struct CompassDial: View {
    let degrees: CLLocationDirection
    var body: some View {
        ZStack {
            Circle().stroke(.secondary.opacity(0.35), lineWidth: 2)
            ForEach(0..<12) { tick in
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 2, height: tick % 3 == 0 ? 14 : 8)
                    .offset(y: -48)
                    .rotationEffect(.degrees(Double(tick) * 30))
            }
            Image(systemName: "location.north.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.red)
                .rotationEffect(.degrees(degrees))
            Text(String(format: "%.0f°", degrees))
                .font(.caption.monospacedDigit().bold())
                .offset(y: 44)
        }
        .padding(8)
    }
}

struct LanguageMenu: View {
    @Bindable var viewModel: CatalogViewModel
    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    viewModel.language = language
                } label: {
                    if viewModel.language == language {
                        Label(language.title, systemImage: "checkmark")
                    } else {
                        Text(language.title)
                    }
                }
            }
        } label: { Label(viewModel.language.title, systemImage: "globe") }
        .accessibilityLabel(viewModel.text(ar: "تغيير اللغة", en: "Change language"))
    }
}

struct LoadingOverlay: View {
    let message: String
    var body: some View {
        ZStack {
            Rectangle().fill(.black.opacity(0.25)).ignoresSafeArea()
            VStack(spacing: 14) { ProgressView(); Text(message).font(.headline) }
                .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
        }
    }
}

struct PrivacyShieldView: View {
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash.fill").font(.largeTitle)
            Text(language == .arabic ? "المحتوى محمي" : "Content protected").font(.title.bold())
            Text(language == .arabic ? "تم حجب الكتالوج عندما لا يكون التطبيق نشطًا." : "The catalog is hidden while the app is inactive.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .center, spacing: BatalDesign.compactSpacing) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BatalDesign.sectionSpacing)
        .accessibilityElement(children: .combine)
    }
}

struct PaymentBanner: View {
    let message: String?
    let dismissLabel: String
    let dismiss: () -> Void

    var body: some View {
        if let message, !message.isEmpty {
            HStack(spacing: 10) {
                Text(message)
                    .font(.footnote.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dismissLabel)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: 560)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
    }
}

// MARK: - Helpers


func partRequestDraft(for request: SavedPartRequest, plan: PartRequestPlan, language: AppLanguage) -> String {
    let header = language == .arabic ? "بطل الدروب - \(plan.titleAr)" : "Batal Al-Droob - \(plan.titleEn)"
    let fields: [(String, String)] = language == .arabic ? [
        ("الجيل", request.generation), ("السنة", request.year), ("VIN", request.vin),
        ("المحرك", request.engine), ("القير", request.transmission),
        ("رقم القطعة", request.partNumber), ("اسم القطعة", request.partName), ("ملاحظات", request.notes)
    ] : [
        ("Generation", request.generation), ("Year", request.year), ("VIN", request.vin),
        ("Engine", request.engine), ("Transmission", request.transmission),
        ("Part number", request.partNumber), ("Part name", request.partName), ("Notes", request.notes)
    ]
    let lines = fields.compactMap { label, value -> String? in
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : "\(label): \(trimmed)"
    }
    return ([header] + lines).joined(separator: "\n")
}

func partNumberCandidates(in text: String) -> [String] {
    let uppercased = text.uppercased()
    var candidates: [String] = []
    let fullRange = NSRange(uppercased.startIndex..<uppercased.endIndex, in: uppercased)

    if let separated = try? NSRegularExpression(
        pattern: #"(?<![A-Z0-9])([A-Z0-9]{4,8})\s*[-–—_/]\s*([A-Z0-9]{3,8})(?![A-Z0-9])"#
    ) {
        for match in separated.matches(in: uppercased, range: fullRange) where match.numberOfRanges == 3 {
            guard let firstRange = Range(match.range(at: 1), in: uppercased),
                  let secondRange = Range(match.range(at: 2), in: uppercased) else { continue }
            candidates.append("\(uppercased[firstRange])-\(uppercased[secondRange])")
        }
    }

    if let compact = try? NSRegularExpression(pattern: #"(?<![A-Z0-9])[A-Z0-9]{8,14}(?![A-Z0-9])"#) {
        for match in compact.matches(in: uppercased, range: fullRange) {
            guard let range = Range(match.range, in: uppercased) else { continue }
            let candidate = String(uppercased[range])
            if candidate.contains(where: { $0.isNumber }) {
                candidates.append(candidate)
            }
        }
    }

    return candidates.uniqued()
}

func isAllowedExternalURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased(),
          scheme == "https" || scheme == "http",
          url.host != nil else { return false }
    return true
}

func diagnosticKeywords(_ text: String) -> [String] {
    let normalizedText = text.lowercased()
    var words: [String] = []
    if normalizedText.contains("حر") || normalizedText.contains("heat") || normalizedText.contains("cool") || normalizedText.contains("radiator") { words += ["cooling", "fan", "radiator"] }
    if normalizedText.contains("كهرب") || normalizedText.contains("electric") || normalizedText.contains("light") || normalizedText.contains("sensor") { words += ["electrical", "sensor", "lamp"] }
    if normalizedText.contains("فرامل") || normalizedText.contains("brake") { words += ["brake"] }
    if normalizedText.contains("تعليق") || normalizedText.contains("suspension") || normalizedText.contains("shock") { words += ["suspension"] }
    if normalizedText.contains("وقود") || normalizedText.contains("fuel") || normalizedText.contains("pump") { words += ["fuel", "pump"] }
    return words.isEmpty ? normalizedText.split(separator: " ").prefix(6).map(String.init) : words.uniqued()
}

func tireDiameter(_ size: String) -> Double? {
    let cleaned = size.uppercased().replacingOccurrences(of: " ", with: "")
    let parts = cleaned.replacingOccurrences(of: "R", with: "/").split(separator: "/")
    guard parts.count >= 3,
          let width = Double(parts[0]),
          let aspect = Double(parts[1]),
          let wheel = Double(parts[2]) else { return nil }
    return (width * (aspect / 100) * 2 / 25.4) + wheel
}

private func shouldRetryWeatherRequest(after error: Error) -> Bool {
    if case WeatherServiceError.httpStatus(let status) = error {
        return status == 429 || (500...599).contains(status)
    }
    guard let urlError = error as? URLError else { return false }
    return [
        .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
        .dnsLookupFailed, .notConnectedToInternet, .resourceUnavailable
    ].contains(urlError.code)
}

private func nonEmpty(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
    return value
}

private func masked(_ value: String) -> String {
    guard value.count > 4 else { return "••••" }
    return String(value.prefix(2)) + "••••" + String(value.suffix(2))
}

private func short(_ values: [String], limit: Int = 6) -> String {
    guard !values.isEmpty else { return "-" }
    let head = values.prefix(limit).joined(separator: ", ")
    return values.count > limit ? head + " …" : head
}

private func normalized(_ value: String) -> String {
    value.lowercased()
        .replacingOccurrences(of: "-", with: "")
        .replacingOccurrences(of: " ", with: "")
        .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleStringArray(forKey key: Key) throws -> [String] {
        if let values = try? decodeIfPresent([String].self, forKey: key) { return values }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return value.isEmpty ? [] : [value] }
        if let values = try? decodeIfPresent([Int].self, forKey: key) { return values.map(String.init) }
        return []
    }

    func decodeFlexibleInt(forKey key: Key) throws -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return Int(value) }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return Int(value) }
        return nil
    }

    func decodeFlexibleDouble(forKey key: Key) throws -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) { return value }
        if let value = try? decodeIfPresent(Int.self, forKey: key) { return Double(value) }
        if let value = try? decodeIfPresent(String.self, forKey: key) { return Double(value) }
        return nil
    }
}

extension UserDefaults {
    func codable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func setCodable<T: Encodable>(_ value: T, forKey key: String) {
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: key)
    }
}
