import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

// MARK: - ViewModel

@MainActor
@Observable
final class CatalogViewModel {
    private let repository: CatalogRepository
    private let store: PurchaseService
    private let photoTextRecognizer: any PhotoTextRecognizing
    private let catalogUnlockToken = "__catalog_unlock__"
    private var hasLoadedCatalog = false
    private var hasLoadedStores = false

    var language: AppLanguage = .init(rawValue: UserDefaults.standard.string(forKey: "batalLang") ?? "ar") ?? .arabic {
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

    var vehicleProfile: VehicleProfile = UserDefaults.standard.codable(
        VehicleProfile.self,
        forKey: "batalVehicleProfile"
    ) ?? VehicleProfile() {
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
        .init(
            id: "basic",
            titleAr: "طلب عادي",
            titleEn: "Basic request",
            descriptionAr: "صياغة طلب القطعة وحفظه داخل التطبيق.",
            descriptionEn: "Prepare and save the part request inside the app."
        ),
        .init(
            id: "urgent",
            titleAr: "طلب مستعجل",
            titleEn: "Urgent request",
            descriptionAr: "صياغة طلب مختصر وجاهز للمشاركة السريعة.",
            descriptionEn: "Prepare a concise request ready for quick sharing."
        ),
        .init(
            id: "rare",
            titleAr: "طلب قطعة نادرة / NOS",
            titleEn: "Rare / NOS request",
            descriptionAr: "صياغة طلب مفصل للقطع النادرة أو المستعملة الأصلية.",
            descriptionEn: "Prepare a detailed request for rare, original used, or NOS parts."
        )
    ]
    var purchaseProductIDs: [String] {
        [StoreProductID.catalogPermanentUnlock]
    }

    init(
        repository: CatalogRepository,
        store: PurchaseService,
        photoTextRecognizer: any PhotoTextRecognizing = VisionPhotoTextRecognizer()
    ) {
        self.repository = repository
        self.store = store
        self.photoTextRecognizer = photoTextRecognizer
    }
}

extension CatalogViewModel {
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        loadingMessage = text(ar: "جاري تحميل قاعدة القطع...", en: "Loading catalog database...")
        defer { isLoading = false }

        var loadErrors: [String] = []
        if !hasLoadedCatalog {
            do {
                let catalog = try await repository.loadCatalog()
                parts = catalog.parts.filter { !$0.partNumber.isEmpty }
                partSearchIndex = parts.reduce(into: [:]) { index, part in
                    index[part.partNumber] = searchableText(for: part)
                }
                sources = catalog.sources
                generatedAt = catalog.generatedAt ?? ""
                recordCount = catalog.recordCount ?? parts.count
                sourceCount = catalog.sourceCount ?? catalog.sources.count
                partCount = catalog.partCount ?? parts.count
                selectedPart = filteredParts.first
                hasLoadedCatalog = true
            } catch {
                BatalLog.catalog.error("Catalog load failed: \(String(describing: error), privacy: .public)")
                loadErrors.append(text(ar: "تعذر تحميل كتالوج القطع.", en: "The parts catalog could not be loaded."))
            }
        }

        if !hasLoadedStores {
            do {
                stores = try await repository.loadStores()
                hasLoadedStores = true
            } catch {
                BatalLog.catalog.error("Store directory load failed: \(String(describing: error), privacy: .public)")
                loadErrors.append(text(ar: "تعذر تحميل دليل المتاجر.", en: "The store directory could not be loaded."))
            }
        }

        await refreshPurchaseProducts()
        await synchronizeCurrentEntitlements()
        errorMessage = loadErrors.isEmpty ? nil : loadErrors.joined(separator: "\n")
    }

    var filteredParts: [Part] {
        let rawQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = normalized(searchText)
        let isPartNumberLookup = isLikelyPartNumberLookup(rawQuery, normalizedQuery: query)
        return parts.lazy.filter { part in
            let categoryMatch = self.selectedCategory == .all || part.categoryValue == self.selectedCategory
            let numberMatch = self.partNumberMatches(part, normalizedQuery: query)
            guard categoryMatch || (isPartNumberLookup && numberMatch) else { return false }
            guard !query.isEmpty else { return true }
            return numberMatch || (self.partSearchIndex[part.partNumber] ?? self.searchableText(for: part)).contains(query)
        }.prefix(250).map(\.self)
    }

    var sharedParts: [Part] {
        parts.filter(\.isSharedCandidate).prefix(80).map(\.self)
    }

    var wishlistParts: [Part] {
        parts.filter { wishlist.contains($0.partNumber) }
    }

    var reviewReadyParts: [Part] {
        parts
            .filter { !$0.evidence.isEmpty && !$0.years.isEmpty && !$0.engines.isEmpty }
            .sorted { ($0.confidence ?? 0) > ($1.confidence ?? 0) }
            .prefix(8)
            .map(\.self)
    }
}

extension CatalogViewModel {
    func text(ar arabic: String, en english: String) -> String {
        language == .arabic ? arabic : english
    }

    func title(for part: Part) -> String {
        part.title(language: language)
    }

    func isUnlocked(_ part: Part) -> Bool {
        paidUnlocks.contains(catalogUnlockToken) || paidUnlocks.contains(part.partNumber)
    }

    func isProductAvailable(_ productID: String) -> Bool {
        availableProductIDs.contains(productID)
    }

    var purchaseSetupMessage: String {
        if isLoadingPurchases {
            return text(ar: "جاري التحقق من منتجات الشراء داخل التطبيق...", en: "Checking in-app purchase products...")
        }
        if availableProductIDs.isEmpty {
            return text(
                ar: "الدفع داخل التطبيق غير جاهز حاليًا. يمكنك استخدام البحث والكتالوج والأدوات المجانية، "
                    + "وسيتم تفعيل الشراء عند اعتماد منتجات App Store.",
                en: "In-app purchase is not ready yet. Free catalog search and tools remain available, "
                    + "and purchases will activate when App Store products are approved."
            )
        }
        return text(ar: "الدفع داخل التطبيق جاهز عبر Apple.", en: "In-app purchase is ready through Apple.")
    }

    func protectedNumber(_ part: Part) -> String {
        part.partNumber
    }

    func premiumNumber(_ number: String, for part: Part) -> String {
        number == part.partNumber || isUnlocked(part) ? number : masked(number)
    }

    func toggleWishlist(_ part: Part) {
        if wishlist.contains(part.partNumber) {
            wishlist.remove(part.partNumber)
        } else {
            wishlist.insert(part.partNumber)
        }
    }

    func unlock(_: Part) async {
        guard isProductAvailable(StoreProductID.catalogPermanentUnlock) else {
            paymentMessage = purchaseSetupMessage
            return
        }
        paymentMessage = text(ar: "جاري طلب الدفع...", en: "Requesting purchase...")
        do {
            let outcome = try await store.purchase(productID: StoreProductID.catalogPermanentUnlock)
            switch outcome {
            case .success:
                applyEntitlements([StoreProductID.catalogPermanentUnlock])
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

    @discardableResult
    func saveRequestPlan(_ plan: PartRequestPlan, request: SavedPartRequest) -> Bool {
        guard partRequestHasRequiredInput(request) else {
            paymentMessage = text(
                ar: "أدخل رقم القطعة أو اسمها قبل تجهيز الطلب.",
                en: "Enter a part number or part name before preparing the request."
            )
            return false
        }
        var saved = request.normalizedForStorage()
        saved.planID = plan.id
        saved.draft = buildDraft(for: saved, plan: plan)
        savedRequests = Array(([saved] + savedRequests).prefix(50))
        paymentMessage = text(ar: "تم تجهيز طلب القطعة وحفظه.", en: "Part request was prepared and saved.")
        return true
    }

    func refreshPurchaseProducts() async {
        isLoadingPurchases = true
        defer { isLoadingPurchases = false }
        do {
            availableProductIDs = try await store.availableProductIDs(for: purchaseProductIDs)
        } catch {
            BatalLog.purchases.error("StoreKit product lookup failed: \(String(describing: error), privacy: .public)")
            availableProductIDs = []
        }
    }

    func synchronizeCurrentEntitlements() async {
        await applyEntitlements(store.currentEntitledProductIDs())
    }

    func restorePurchases() async {
        paymentMessage = text(ar: "جاري استعادة المشتريات...", en: "Restoring purchases...")
        do {
            let restored = try await store.restorePurchasedProductIDs()
            applyEntitlements(restored)
            if restored.contains(StoreProductID.catalogPermanentUnlock) {
                paymentMessage = text(ar: "تمت استعادة فتح الكتالوج.", en: "Catalog unlock was restored.")
            } else {
                paymentMessage = text(
                    ar: "لا توجد مشتريات مؤهلة للاستعادة.",
                    en: "No eligible purchases were found to restore."
                )
            }
        } catch {
            paymentMessage = purchaseErrorMessage(error)
        }
    }

    func observePurchaseUpdates() async {
        for await entitlements in store.entitlementUpdates() {
            guard !Task.isCancelled else { break }
            applyEntitlements(entitlements)
        }
    }

    private func applyEntitlements(_ productIDs: Set<String>) {
        if productIDs.contains(StoreProductID.catalogPermanentUnlock) {
            paidUnlocks.insert(catalogUnlockToken)
        } else {
            paidUnlocks.remove(catalogUnlockToken)
            paidUnlocks.subtract(parts.map(\.partNumber))
        }
    }

    private func purchaseErrorMessage(_ error: Error) -> String {
        if case AppError.productUnavailable = error {
            return purchaseSetupMessage
        }
        return text(
            ar: "تعذر إكمال عملية الشراء. حاول مرة أخرى أو استخدم الاستعادة إذا كنت اشتريت سابقًا.",
            en: "The purchase could not be completed. Try again, or use Restore Purchases if you purchased before."
        )
    }
}

extension CatalogViewModel {
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

    @discardableResult
    func applyDescriptionSearch(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = self.text(
                ar: "اكتب وصف العطل أو رقم القطعة قبل البحث.",
                en: "Enter a fault description or part number before searching."
            )
            return false
        }
        let mappedKeywords = diagnosticKeywords(trimmed)
        searchText = mappedKeywords.isEmpty ? trimmed : mappedKeywords.joined(separator: " ")
        selectedCategory = .all
        selectedPart = rankedFitmentMatches(for: searchText, limit: 1).first ?? filteredParts.first
        if selectedPart == nil {
            paymentMessage = self.text(
                ar: "لم أجد تطابقًا مباشرًا. جرّب رقم القطعة أو كلمة أوضح مثل radiator أو brake.",
                en: "No direct match was found. Try a part number or a clearer word such as radiator or brake."
            )
        }
        return selectedPart != nil
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
            errorMessage = text(
                ar: "لم يظهر نص قابل للبحث في الصورة.",
                en: "No searchable text was found in the photo."
            )
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
}

extension CatalogViewModel {
    func tireDifference(oldSize: String, newSize: String) -> String {
        guard let old = tireDiameter(oldSize), let new = tireDiameter(newSize), old > 0 else {
            return text(ar: "أدخل المقاس بصيغة 265/70R16", en: "Enter size as 265/70R16")
        }
        let diff = ((new - old) / old) * 100
        return String(
            format: text(ar: "الفرق %.1f%%", en: "Difference %.1f%%"),
            locale: language.locale,
            diff
        )
    }

    func fitmentSummary(for query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return text(ar: "أدخل رقم قطعة أو وصفًا مختصرًا.", en: "Enter a part number or short description.")
        }
        let match = rankedFitmentMatches(for: trimmed, limit: 1).first
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
            text(
                ar: "مصادر الكتالوج: \((match.sourceCount ?? match.evidence.count).formatted())",
                en: "Catalog sources: \((match.sourceCount ?? match.evidence.count).formatted())"
            )
        ].joined(separator: "\n")
    }

    func fitmentMatches(for query: String) -> [Part] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return rankedFitmentMatches(for: trimmed, limit: 8)
    }

    private func rankedFitmentMatches(for query: String, limit: Int) -> [Part] {
        let normalizedQuery = normalized(query)
        return parts.compactMap { part -> (Part, Int)? in
            let normalizedPrimary = normalized(part.partNumber)
            let normalizedNumbers = part.allNumbers.map(normalized)
            let searchText = self.partSearchIndex[part.partNumber] ?? self.searchableText(for: part)
            let score: Int
            if normalizedPrimary == normalizedQuery {
                score = 400
            } else if normalizedNumbers.contains(normalizedQuery) {
                score = 350
            } else if normalizedPrimary.contains(normalizedQuery) {
                score = 300
            } else if normalizedNumbers.contains(where: { $0.contains(normalizedQuery) }) {
                score = 250
            } else if searchText.contains(normalizedQuery) {
                score = 100 + (part.confidence ?? 0)
            } else {
                return nil
            }
            return (part, score)
        }
        .sorted { lhs, rhs in
            if lhs.1 == rhs.1 { return (lhs.0.confidence ?? 0) > (rhs.0.confidence ?? 0) }
            return lhs.1 > rhs.1
        }
        .prefix(limit)
        .map(\.0)
    }

    private func searchableText(for part: Part) -> String {
        normalized(([
            part.partNumber,
            part.primaryOEMNumber,
            part.nameAr,
            part.nameEn,
            part.category,
            part.categoryAr,
            part.model
        ] + part.partNumbers + part.years + part.engines).compactMap(\.self).joined(separator: " "))
    }

    private func isLikelyPartNumberLookup(_ rawQuery: String, normalizedQuery: String) -> Bool {
        guard normalizedQuery.count >= 5 else { return false }
        if !partNumberCandidates(in: rawQuery).isEmpty { return true }
        return normalizedQuery.contains(where: \.isNumber)
            && normalizedQuery.contains(where: \.isLetter)
    }

    private func partNumberMatches(_ part: Part, normalizedQuery query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return part.allNumbers.map(normalized).contains { number in
            number == query || number.contains(query)
        }
    }
}
