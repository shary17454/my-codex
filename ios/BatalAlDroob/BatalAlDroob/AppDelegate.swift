import SwiftUI
import Observation
import StoreKit
import PhotosUI
import MapKit
import CoreLocation

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
    let productID: String
    let priceSAR: Int
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
        try await decodeBundledJSON(CatalogPayload.self, resource: "y60_app_catalog", subdirectory: "Web/data")
    }

    func loadStores() async throws -> [VerifiedStore] {
        let directory = try await decodeBundledJSON(StoreDirectory.self, resource: "store_directory", subdirectory: "Web/data")
        return directory.verifiedStores
    }

    private func decodeBundledJSON<T: Decodable & Sendable>(_ type: T.Type, resource: String, subdirectory: String) async throws -> T {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json", subdirectory: subdirectory) else {
            throw AppError.missingResource(resource)
        }
        return try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        }.value
    }
}

protocol PurchaseService: Sendable {
    func purchase(productID: String) async throws -> PurchaseOutcome
}

enum PurchaseOutcome: Equatable, Sendable { case success, cancelled, pending }

struct StoreKitPurchaseService: PurchaseService {
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
}

enum AppError: LocalizedError, Sendable {
    case missingResource(String), productUnavailable, unverifiedTransaction, unknownPurchaseResult
    var errorDescription: String? {
        switch self {
        case .missingResource(let name): "Missing bundled resource: \(name)"
        case .productUnavailable: "Product is not available in App Store Connect."
        case .unverifiedTransaction: "Transaction verification failed."
        case .unknownPurchaseResult: "Unknown purchase result."
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class CatalogViewModel {
    private let repository: CatalogRepository
    private let store: PurchaseService

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
        .init(id: "basic", productID: "batal.parts.request.basic", priceSAR: 10, titleAr: "طلب عادي", titleEn: "Basic request", descriptionAr: "تجهيز الطلب وإرساله للمتاجر المناسبة.", descriptionEn: "Prepare the request and route it to suitable stores."),
        .init(id: "urgent", productID: "batal.parts.request.urgent", priceSAR: 20, titleAr: "طلب مستعجل", titleEn: "Urgent request", descriptionAr: "أولوية أعلى وصياغة طلب جاهز للواتساب والبريد.", descriptionEn: "Higher priority with a ready message for WhatsApp and email."),
        .init(id: "rare", productID: "batal.parts.request.rare", priceSAR: 50, titleAr: "طلب قطعة نادرة / NOS", titleEn: "Rare / NOS request", descriptionAr: "بحث مركز للقطع النادرة أو المستعملة الأصلية.", descriptionEn: "Focused request for rare, used original, or NOS parts.")
    ]

    init(repository: CatalogRepository, store: PurchaseService) {
        self.repository = repository
        self.store = store
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

    func text(ar: String, en: String) -> String { language == .arabic ? ar : en }
    func title(for part: Part) -> String { part.title(language: language) }
    func isUnlocked(_ part: Part) -> Bool { paidUnlocks.contains(part.partNumber) }
    func protectedNumber(_ part: Part) -> String { part.partNumber }
    func premiumNumber(_ number: String, for part: Part) -> String {
        number == part.partNumber || isUnlocked(part) ? number : masked(number)
    }

    func toggleWishlist(_ part: Part) {
        if wishlist.contains(part.partNumber) { wishlist.remove(part.partNumber) } else { wishlist.insert(part.partNumber) }
    }

    func unlock(_ part: Part) async {
        paymentMessage = text(ar: "جاري طلب الدفع...", en: "Requesting purchase...")
        do {
            let outcome = try await store.purchase(productID: "batal.catalog.unlock")
            switch outcome {
            case .success:
                paidUnlocks.insert(part.partNumber)
                paymentMessage = text(ar: "تم الدفع وفتح المحتوى", en: "Payment complete. Content unlocked.")
            case .cancelled:
                paymentMessage = text(ar: "تم إلغاء عملية الدفع.", en: "Purchase was cancelled.")
            case .pending:
                paymentMessage = text(ar: "عملية الدفع معلقة.", en: "Purchase is pending.")
            }
        } catch {
            paymentMessage = error.localizedDescription
        }
    }

    func buyRequestPlan(_ plan: PartRequestPlan, request: SavedPartRequest) async {
        paymentMessage = text(ar: "جاري طلب الدفع...", en: "Requesting purchase...")
        do {
            let outcome = try await store.purchase(productID: plan.productID)
            guard outcome == .success else {
                paymentMessage = outcome == .cancelled ? text(ar: "تم إلغاء عملية الدفع.", en: "Purchase was cancelled.") : text(ar: "الدفع معلق.", en: "Payment is pending.")
                return
            }
            var saved = request
            saved.planID = plan.id
            saved.draft = buildDraft(for: saved, plan: plan)
            savedRequests.insert(saved, at: 0)
            paymentMessage = text(ar: "تم حفظ طلب القطعة بعد الدفع.", en: "Part request saved after payment.")
        } catch {
            paymentMessage = error.localizedDescription
        }
    }

    func buildDraft(for request: SavedPartRequest, plan: PartRequestPlan) -> String {
        let lines = [
            "بطل الدروب - \(plan.titleAr)",
            "الجيل: \(request.generation)",
            "السنة: \(request.year)",
            "VIN: \(request.vin)",
            "المحرك: \(request.engine)",
            "القير: \(request.transmission)",
            "رقم القطعة: \(request.partNumber)",
            "اسم القطعة: \(request.partName)",
            "ملاحظات: \(request.notes)"
        ]
        return lines.filter { !$0.hasSuffix(": ") }.joined(separator: "\n")
    }

    func addMaintenance(title: String, odometer: String, notes: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        maintenanceItems.insert(.init(title: title, odometer: odometer, notes: notes), at: 0)
    }


    func applyDescriptionSearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searchText = diagnosticKeywords(trimmed).joined(separator: " ")
        selectedCategory = .all
        selectedPart = filteredParts.first
    }

    func applyPhotoHint(_ name: String) {
        selectedPhotoName = name
        searchText = diagnosticKeywords(name).joined(separator: " ")
        selectedCategory = .all
        selectedPart = filteredParts.first
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
                || searchableText(for: part).contains(normalizedQuery)
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

    func openStore(_ store: VerifiedStore, part: Part?) {
        let url = store.searchURL(partNumber: part?.partNumber ?? "") ?? URL(string: store.website ?? "")
        guard let url else { return }
        #if os(iOS)
        Task { await UIApplication.shared.open(url) }
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
    var cameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753), span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)))

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        manager.headingFilter = 3
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
        isTracking = false
        weatherTask?.cancel()
        weatherTask = nil
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        locationMessage = language == .arabic ? "تم إيقاف التتبع" : "Tracking stopped"
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
        guard let location = locations.last else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let altitude = location.altitude
        let horizontalAccuracy = location.horizontalAccuracy
        Task { @MainActor in
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.coordinate = coordinate
            self.altitude = altitude
            self.horizontalAccuracy = horizontalAccuracy
            self.cameraPosition = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)))
            self.scheduleWeatherLoad(for: CLLocation(latitude: latitude, longitude: longitude))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            self.headingDegrees = value
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.locationMessage = error.localizedDescription }
    }

    private func scheduleWeatherLoad(for location: CLLocation) {
        if let lastWeatherLocation, let lastWeatherUpdate {
            let recentlyUpdated = Date().timeIntervalSince(lastWeatherUpdate) < 600
            let nearby = location.distance(from: lastWeatherLocation) < 1_000
            if recentlyUpdated && nearby { return }
        }
        weatherTask?.cancel()
        weatherTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 750_000_000)
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
        do {
            let weather = try await OpenMeteoWeatherService.fetch(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let temp = Measurement(value: weather.current.temperature2m, unit: UnitTemperature.celsius)
                .formatted(.measurement(width: .abbreviated, usage: .weather))
            weatherSummary = "\(temp) · \(weather.current.condition(language: currentLanguage))"
            weatherError = nil
            lastWeatherLocation = location
            lastWeatherUpdate = Date()
        } catch {
            weatherError = error.localizedDescription
        }
    }
}

struct OpenMeteoWeatherService {
    static func fetch(latitude: Double, longitude: Double) async throws -> OpenMeteoWeather {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code")
        ]
        guard let url = components?.url else { throw URLError(.badURL) }
        let request = URLRequest(url: url, timeoutInterval: 10)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(OpenMeteoWeather.self, from: data)
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
            .overlay(alignment: .top) { PaymentBanner(message: viewModel.paymentMessage) }

            if viewModel.isLoading { LoadingOverlay(message: viewModel.loadingMessage) }
            if viewModel.isPrivacyShieldVisible { PrivacyShieldView() }
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

                Section(viewModel.text(ar: "وظائف تعمل بدون شراء", en: "Included functionality")) {
                    FeatureRow(symbol: "number.square", title: viewModel.text(ar: "إظهار رقم القطعة الأساسي", en: "Primary part number"), detail: viewModel.text(ar: "الرقم الأساسي وبيانات السنوات والمحركات ظاهرة مباشرة.", en: "The primary number, years, and engine data are visible immediately."))
                    FeatureRow(symbol: "doc.text.magnifyingglass", title: viewModel.text(ar: "بحث كتالوج محلي", en: "Local catalog search"), detail: viewModel.text(ar: "يبحث داخل قاعدة مدمجة ولا يحتاج تسجيل دخول.", en: "Searches a bundled database without sign-in."))
                    FeatureRow(symbol: "wrench.and.screwdriver", title: viewModel.text(ar: "سجل صيانة وأدوات", en: "Maintenance and tools"), detail: viewModel.text(ar: "حفظ صيانة السيارة، حساب الكفرات، تتبع الموقع، البوصلة، والطقس.", en: "Save maintenance, calculate tire changes, and use location, compass, and weather tools."))
                }

                Section(viewModel.text(ar: "تحقق سريع من التوافق", en: "Quick fitment check")) {
                    TextField(viewModel.text(ar: "رقم القطعة أو الوصف", en: "Part number or description"), text: $fitmentQuery)
                        .textInputAutocapitalization(.characters)
                    Button { fitmentResult = viewModel.fitmentSummary(for: fitmentQuery) } label: {
                        Label(viewModel.text(ar: "تحقق الآن", en: "Check now"), systemImage: "checkmark.seal")
                    }
                    if !fitmentResult.isEmpty {
                        Text(fitmentResult)
                            .font(.callout.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle(viewModel.text(ar: "الرئيسية", en: "Home"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .onAppear {
                if fitmentResult.isEmpty {
                    fitmentResult = viewModel.fitmentSummary(for: fitmentQuery)
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
                    ForEach(viewModel.filteredParts) { part in
                        NavigationLink(value: part) { PartRow(part: part, viewModel: viewModel) }
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
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
                        Button { Task { await viewModel.unlock(part) } } label: {
                            Label(viewModel.text(ar: "فتح الأرقام البديلة والأدلة المتقدمة", en: "Unlock alternate numbers and advanced evidence"), systemImage: "lock.open")
                        }
                        .buttonStyle(.borderedProminent)
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
                NativeDiagramView(part: part, unlocked: viewModel.isUnlocked(part))
                    .frame(height: 220)
                    .accessibilityLabel(viewModel.text(ar: "رسم يوضح رقم النداء التقريبي للقطعة", en: "Diagram showing the approximate part callout"))
            }
            Section(viewModel.text(ar: "الأدلة", en: "Evidence")) {
                ForEach(Array(part.evidence.prefix(8).enumerated()), id: \.offset) { _, evidence in
                    VStack(alignment: .leading, spacing: 4) {
                        Text([evidence.sourceID, evidence.year, evidence.page.map { "p.\($0)" }, evidence.reference].compactMap { $0 }.joined(separator: " · "))
                            .font(.subheadline.bold())
                        if let context = evidence.context { Text(context).font(.caption).foregroundStyle(.secondary).lineLimit(4) }
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
        }
    }
}

struct NativeDiagramView: View {
    let part: Part
    let unlocked: Bool
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
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
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
                Section(viewModel.text(ar: "رسوم الطلب", en: "Request fee")) {
                    Picker(viewModel.text(ar: "الخطة", en: "Plan"), selection: $selectedPlanID) {
                        ForEach(viewModel.plans) { plan in Text("\(plan.title(viewModel.language)) · \(plan.priceSAR) SAR").tag(plan.id) }
                    }
                    Text(selectedPlan.description(viewModel.language)).font(.caption).foregroundStyle(.secondary)
                }
                Section(viewModel.text(ar: "بيانات السيارة", en: "Vehicle")) {
                    TextField("Y60", text: $request.generation)
                    TextField(viewModel.text(ar: "سنة الصنع", en: "Year"), text: $request.year)
                    TextField("VIN", text: $request.vin)
                    TextField(viewModel.text(ar: "المحرك", en: "Engine"), text: $request.engine)
                    TextField(viewModel.text(ar: "القير", en: "Transmission"), text: $request.transmission)
                }
                Section(viewModel.text(ar: "بيانات القطعة", en: "Part")) {
                    TextField(viewModel.text(ar: "رقم القطعة", en: "Part number"), text: $request.partNumber)
                    TextField(viewModel.text(ar: "اسم القطعة", en: "Part name"), text: $request.partName)
                    TextField(viewModel.text(ar: "ملاحظات", en: "Notes"), text: $request.notes, axis: .vertical)
                    Button { Task { await viewModel.buyRequestPlan(selectedPlan, request: request) } } label: {
                        Label(viewModel.text(ar: "دفع الرسوم وتجهيز الطلب", en: "Pay and prepare request"), systemImage: "creditcard")
                    }
                    .disabled(request.partNumber.isEmpty && request.partName.isEmpty)
                }
                Section(viewModel.text(ar: "طلبات محفوظة", en: "Saved requests")) {
                    ForEach(viewModel.savedRequests) { saved in
                        VStack(alignment: .leading) {
                            Text(saved.partNumber.isEmpty ? saved.partName : saved.partNumber).font(.headline)
                            Text(saved.draft).font(.caption).foregroundStyle(.secondary).lineLimit(4)
                        }
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
                    TextField("VIN", text: $viewModel.vehicleProfile.vin)
                    TextField(viewModel.text(ar: "المحرك", en: "Engine"), text: $viewModel.vehicleProfile.engine)
                    TextField(viewModel.text(ar: "القير", en: "Transmission"), text: $viewModel.vehicleProfile.transmission)
                }
                Section(viewModel.text(ar: "إضافة صيانة", en: "Add maintenance")) {
                    TextField(viewModel.text(ar: "العنوان", en: "Title"), text: $title)
                    TextField(viewModel.text(ar: "العداد", en: "Odometer"), text: $odometer)
                    TextField(viewModel.text(ar: "ملاحظات", en: "Notes"), text: $notes, axis: .vertical)
                    Button(viewModel.text(ar: "حفظ", en: "Save")) {
                        viewModel.addMaintenance(title: title, odometer: odometer, notes: notes)
                        title = ""; odometer = ""; notes = ""
                    }
                }
                Section(viewModel.text(ar: "السجل", en: "Log")) {
                    ForEach(viewModel.maintenanceItems) { item in
                        VStack(alignment: .leading) {
                            Text(item.title).font(.headline)
                            Text([item.odometer, item.notes].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                        }
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
                    .onChange(of: viewModel.selectedPhoto) { _, item in
                        guard let item else { return }
                        let hint = item.itemIdentifier ?? "part photo"
                        viewModel.applyPhotoHint(hint)
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
                    ForEach(viewModel.wishlistParts) { part in PartRow(part: part, viewModel: viewModel) }
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
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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
                    if let weatherError = locationWeather.weatherError {
                        Text(viewModel.text(ar: "تعذر تحميل الطقس: ", en: "Weather unavailable: ") + weatherError)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if !locationWeather.locationMessage.isEmpty {
                        Text(locationWeather.locationMessage).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section(viewModel.text(ar: "سياسة البيانات", en: "Data policy")) {
                    Text(viewModel.text(ar: "التطبيق مستقل ولا يتبع نيسان. بيانات الأسعار والتوفر لا تعرض إلا من مصادر متجر موثقة.", en: "This app is independent from Nissan. Prices and availability are shown only from verified store sources."))
                }
            }
            .navigationTitle(viewModel.text(ar: "المزيد", en: "More"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
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
                .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct PrivacyShieldView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash.fill").font(.largeTitle)
            Text("المحتوى محمي").font(.title.bold())
            Text("تم حجب الكتالوج عندما لا يكون التطبيق نشطًا.").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }
}

struct PaymentBanner: View {
    let message: String?
    var body: some View {
        if let message, !message.isEmpty {
            Text(message).font(.footnote.bold()).padding(.horizontal, 14).padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule()).padding(.top, 8)
        }
    }
}

// MARK: - Helpers


private func diagnosticKeywords(_ text: String) -> [String] {
    let normalizedText = text.lowercased()
    var words: [String] = []
    if normalizedText.contains("حر") || normalizedText.contains("heat") || normalizedText.contains("cool") || normalizedText.contains("radiator") { words += ["cooling", "fan", "radiator"] }
    if normalizedText.contains("كهرب") || normalizedText.contains("electric") || normalizedText.contains("light") || normalizedText.contains("sensor") { words += ["electrical", "sensor", "lamp"] }
    if normalizedText.contains("فرامل") || normalizedText.contains("brake") { words += ["brake"] }
    if normalizedText.contains("تعليق") || normalizedText.contains("suspension") || normalizedText.contains("shock") { words += ["suspension"] }
    if normalizedText.contains("وقود") || normalizedText.contains("fuel") || normalizedText.contains("pump") { words += ["fuel", "pump"] }
    return words.isEmpty ? normalizedText.split(separator: " ").prefix(6).map(String.init) : words.uniqued()
}

private func tireDiameter(_ size: String) -> Double? {
    let cleaned = size.uppercased().replacingOccurrences(of: " ", with: "")
    let parts = cleaned.replacingOccurrences(of: "R", with: "/").split(separator: "/")
    guard parts.count >= 3,
          let width = Double(parts[0]),
          let aspect = Double(parts[1]),
          let wheel = Double(parts[2]) else { return nil }
    return (width * (aspect / 100) * 2 / 25.4) + wheel
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
