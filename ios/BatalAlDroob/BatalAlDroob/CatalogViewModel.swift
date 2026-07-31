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
    private let aiService: AIAssistantServicing
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
    var aiMessages: [AIAssistantMessage] = []
    var aiQuestion = ""
    var aiSuggestions: [AISuggestion] = []
    var isAIResponding = false
    var aiErrorMessage: String?
    var selectedPhoto: PhotosPickerItem?
    var selectedPhotoName: String?
    var isAnalyzingPhoto = false
    var isLoadingPurchases = false
    var availableProductIDs = Set<String>()
    var isVehicleFilterEnabled = UserDefaults.standard.object(forKey: "batalVehicleFilterEnabled") as? Bool ?? false {
        didSet { UserDefaults.standard.set(isVehicleFilterEnabled, forKey: "batalVehicleFilterEnabled") }
    }

    private(set) var parts: [Part] = []
    private(set) var sources: [CatalogSource] = []
    private(set) var stores: [VerifiedStore] = []
    private(set) var generatedAt = ""
    private(set) var recordCount = 0
    private(set) var sourceCount = 0
    private(set) var partCount = 0
    var partSearchIndex: [String: String] = [:]

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

    var customerProfile = UserDefaults.standard.codable(CustomerProfile.self, forKey: "batalCustomerProfile") ?? CustomerProfile() {
        didSet { UserDefaults.standard.setCodable(customerProfile, forKey: "batalCustomerProfile") }
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
        StoreProductID.allCatalogProducts
    }

    init(
        repository: CatalogRepository,
        store: PurchaseService,
        photoTextRecognizer: any PhotoTextRecognizing = VisionPhotoTextRecognizer(),
        aiService: AIAssistantServicing = CompositeAIAssistantService(remote: BatalRemoteAIService())
    ) {
        self.repository = repository
        self.store = store
        self.photoTextRecognizer = photoTextRecognizer
        self.aiService = aiService
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
        let exactResults = Array(parts.lazy.filter { part in
            let categoryMatch = self.selectedCategory == .all || part.categoryValue == self.selectedCategory
            let numberMatch = self.partNumberMatches(
                part,
                normalizedQuery: query,
                allowingCloseMatches: false
            )
            guard categoryMatch || (isPartNumberLookup && numberMatch) else { return false }
            guard !query.isEmpty else { return true }
            let indexedText = self.partSearchIndex[part.partNumber] ?? self.searchableText(for: part)
            return numberMatch || self.searchTextMatches(indexedText, rawQuery: rawQuery, normalizedQuery: query)
        }.prefix(250))

        guard exactResults.isEmpty, isPartNumberLookup else { return applyVehicleFilter(to: exactResults) }
        return applyVehicleFilter(to: Array(fitmentMatches(for: rawQuery).prefix(25)))
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

    func generationRecordCount(for generationID: String) -> Int {
        let target = normalized(generationID)
        return parts.filter { part in
            normalized(part.model ?? "").contains(target)
                || part.years.contains { normalized($0).contains(target) }
                || part.evidence.contains { normalized($0.sourceID ?? "").contains(target) }
        }.count
    }

    func focusCatalog(onGeneration generationID: String) {
        searchText = generationID
        selectedCategory = .all
        selectedPart = filteredParts.first
    }

    var vehicleFilterSummary: String {
        let profile = vehicleProfile
        let values = [
            nonEmpty(profile.generation),
            nonEmpty(profile.year),
            nonEmpty(profile.engine),
            nonEmpty(profile.transmission)
        ].compactMap(\.self)
        return values.isEmpty ? text(ar: "لم يتم تحديد سيارة بعد.", en: "No vehicle selected yet.") : values.joined(separator: " · ")
    }

    var isRemoteAIConfigured: Bool {
        aiService.isRemoteAIConfigured
    }

    func vehicleMatchSummary(for part: Part) -> String {
        guard isVehicleProfileMeaningful else {
            return text(ar: "أضف بيانات سيارتك لتقييم التوافق.", en: "Add your vehicle to evaluate fitment.")
        }
        if matchesVehicleProfile(part) {
            return text(ar: "متوافق مع ملف سيارتك", en: "Matches your vehicle profile")
        }
        return text(ar: "لا يطابق ملف سيارتك الحالي", en: "Does not match your current vehicle profile")
    }

    func photoCandidateSummary(for part: Part) -> String {
        let confidenceText = (part.confidence ?? 0) > 0 ? "\((part.confidence ?? 0).formatted())%" : text(ar: "غير محددة", en: "Unknown")
        return text(
            ar: "سبب الترشيح: قراءة رقم/نص من الصورة · الثقة: \(confidenceText) · \(vehicleMatchSummary(for: part))",
            en: "Reason: number/text read from image · Confidence: \(confidenceText) · \(vehicleMatchSummary(for: part))"
        )
    }

    private var isVehicleProfileMeaningful: Bool {
        [vehicleProfile.generation, vehicleProfile.year, vehicleProfile.engine, vehicleProfile.transmission]
            .contains { !normalized($0).isEmpty }
    }

    private func applyVehicleFilter(to candidates: [Part]) -> [Part] {
        guard isVehicleFilterEnabled, isVehicleProfileMeaningful else { return candidates }
        return candidates.filter(matchesVehicleProfile)
    }

    private func matchesVehicleProfile(_ part: Part) -> Bool {
        let generation = normalized(vehicleProfile.generation)
        let year = normalized(vehicleProfile.year)
        let engine = normalized(vehicleProfile.engine)
        let transmission = normalized(vehicleProfile.transmission)

        let modelText = searchableText(for: part)
        let generationMatches = generation.isEmpty
            || normalized(part.model ?? "").contains(generation)
            || modelText.contains(generation)
        let yearMatches = year.isEmpty
            || part.years.contains { normalized($0).contains(year) }
            || part.dateRanges.contains { normalized($0).contains(year) }
            || modelText.contains(year)
        let engineMatches = engine.isEmpty
            || part.engines.contains { normalized($0).contains(engine) || engine.contains(normalized($0)) }
            || modelText.contains(engine)
        let transmissionMatches = transmission.isEmpty || modelText.contains(transmission)

        return generationMatches && yearMatches && engineMatches && transmissionMatches
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

    func isFullCatalogUnlocked() -> Bool {
        paidUnlocks.contains(catalogUnlockToken)
    }

    func isProductAvailable(_ productID: String) -> Bool {
        availableProductIDs.contains(productID)
    }

    func isPurchaseActionDisabled(for _: CatalogAccessLevel) -> Bool {
        isLoadingPurchases
    }

    var customerAccessTitle: String {
        switch customerProfile.accessMode {
        case .guest:
            return text(ar: "ضيف", en: "Guest")
        case .localEmail:
            return customerProfile.displayName.isEmpty ? customerProfile.email : customerProfile.displayName
        }
    }

    var customerAccessSummary: String {
        switch customerProfile.accessMode {
        case .guest:
            return text(ar: "تستخدم التطبيق كضيف. لا يلزم تسجيل دخول للبحث والطلبات.", en: "Using the app as a guest. No sign-in is required for search and requests.")
        case .localEmail:
            return text(
                ar: "البريد محفوظ على هذا الجهاز فقط ولا يفتح مشتريات الكتالوج.",
                en: "Email is saved on this device only and does not unlock catalog purchases."
            )
        }
    }

    func continueAsGuest() {
        customerProfile = CustomerProfile(accessMode: .guest, displayName: "", email: "", hasCompletedSignInChoice: true)
    }

    func saveLocalCustomer(name: String, email: String) -> Bool {
        let normalizedEmail = normalizedCustomerEmail(email)
        guard isValidCustomerEmail(normalizedEmail) else { return false }
        customerProfile = CustomerProfile(
            accessMode: .localEmail,
            displayName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: normalizedEmail,
            hasCompletedSignInChoice: true
        )
        return true
    }

    func isValidCustomerEmail(_ email: String) -> Bool {
        let normalizedEmail = normalizedCustomerEmail(email)
        let parts = normalizedEmail.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].count >= 1 else { return false }
        return parts[1].contains(".") && !parts[1].hasSuffix(".")
    }

    func normalizedCustomerEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
        isUnlocked(part) ? part.partNumber : masked(part.partNumber)
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

    func unlock(_ part: Part, level: CatalogAccessLevel = .fullCatalog) async {
        let productID = level.productID
        if !isProductAvailable(productID) {
            await refreshPurchaseProducts()
            guard isProductAvailable(productID) else {
                paymentMessage = purchaseSetupMessage
                return
            }
        }
        paymentMessage = text(
            ar: "جاري طلب الدفع: \(level.title(language))...",
            en: "Requesting purchase: \(level.title(language))..."
        )
        do {
            let outcome = try await store.purchase(productID: productID)
            switch outcome {
            case .success:
                applySuccessfulPurchase(productID: productID, part: part)
                paymentMessage = text(ar: "تم الدفع وفتح المحتوى.", en: "Payment complete. Content unlocked.")
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
        guard partRequestHasRequiredInput(request) else { return }
        var saved = request
        saved.planID = plan.id
        saved.draft = buildDraft(for: saved, plan: plan)
        savedRequests = Array(([saved] + savedRequests).prefix(50))
        paymentMessage = text(ar: "تم تجهيز طلب القطعة وحفظه.", en: "Part request was prepared and saved.")
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
            if containsFullCatalogEntitlement(restored) {
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

    func redeemOfferCode() async {
        paymentMessage = text(ar: "افتح ورقة استرداد كود Apple وأدخل الكود.", en: "Open Apple's offer code sheet and enter the code.")
        do {
            try await store.presentOfferCodeRedemption()
            await synchronizeCurrentEntitlements()
            if isFullCatalogUnlocked() {
                paymentMessage = text(ar: "تم استرداد الكود وفتح الكتالوج.", en: "Offer code redeemed. Catalog unlocked.")
            } else {
                paymentMessage = text(
                    ar: "إذا أكملت الاسترداد، استخدم استعادة المشتريات أو أعد فتح القطعة بعد لحظات.",
                    en: "If redemption completed, use Restore Purchases or reopen the part shortly."
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
        if containsFullCatalogEntitlement(productIDs) {
            paidUnlocks.insert(catalogUnlockToken)
        } else {
            paidUnlocks.remove(catalogUnlockToken)
        }
    }

    private func applySuccessfulPurchase(productID: String, part: Part) {
        switch productID {
        case StoreProductID.singleCatalogUnlock:
            paidUnlocks.insert(part.partNumber)
        case StoreProductID.catalogFullUnlock, StoreProductID.legacyCatalogFullUnlock:
            applyEntitlements([productID])
        default:
            break
        }
    }

    private func containsFullCatalogEntitlement(_ productIDs: Set<String>) -> Bool {
        productIDs.contains(StoreProductID.catalogFullUnlock)
            || productIDs.contains(StoreProductID.legacyCatalogFullUnlock)
    }

    private func purchaseErrorMessage(_ error: Error) -> String {
        if case AppError.productUnavailable = error {
            return purchaseSetupMessage
        }
        if case AppError.invalidProductType = error {
            return text(
                ar: "منتج الشراء مضبوط بنوع غير صحيح في App Store Connect. لا تستخدم الدفع حتى يتم تصحيح إعداد المنتج.",
                en: "The App Store product has the wrong type. Do not purchase until the product setup is corrected."
            )
        }
        if case AppError.unverifiedTransaction = error {
            return text(
                ar: "لم تتمكن Apple من توثيق عملية الشراء. حاول مرة أخرى بعد قليل.",
                en: "Apple could not verify the purchase. Try again shortly."
            )
        }
        if case AppError.offerCodeRedemptionUnavailable = error {
            return text(
                ar: "تعذر فتح ورقة استرداد الكود الآن. جرّب من جهاز فعلي أو افتح App Store لاسترداد الكود.",
                en: "The offer code sheet could not open now. Try on a physical device or redeem the code in the App Store."
            )
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

    func askAssistant(_ question: String? = nil) async {
        let rawQuestion = question ?? aiQuestion
        let trimmed = rawQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 800 else {
            aiErrorMessage = text(
                ar: "اكتب سؤالًا واضحًا لا يتجاوز 800 حرف.",
                en: "Enter a clear question under 800 characters."
            )
            return
        }
        guard !isAIResponding else { return }

        aiQuestion = ""
        aiErrorMessage = nil
        aiMessages.append(.init(role: .user, text: trimmed, generatedByAI: false, createdAt: Date()))
        isAIResponding = true
        defer { isAIResponding = false }

        do {
            let response = try await aiService.answer(assistantContextRequest(message: trimmed))
            aiSuggestions = response.suggestions
            let responseText = response.answer + "\n\n" + response.privacyNote
            aiMessages.append(.init(
                role: .assistant,
                text: responseText,
                generatedByAI: response.generatedByAI,
                createdAt: Date()
            ))
        } catch {
            BatalLog.ai.error("Assistant failed: \(String(describing: error), privacy: .public)")
            aiErrorMessage = text(
                ar: "تعذر تشغيل المساعد الآن. حاول مرة أخرى، أو استخدم البحث المحلي.",
                en: "The assistant is unavailable right now. Try again, or use local search."
            )
        }
    }

    func retryLastAssistantQuestion() async {
        guard let lastQuestion = aiMessages.last(where: { $0.role == .user })?.text else { return }
        await askAssistant(lastQuestion)
    }

    func assistantContextRequest(message: String) -> AIAssistantRequest {
        let contextParts = filteredParts.prefix(8).map { part in
            AIContextPart(
                partNumber: isUnlocked(part) ? part.partNumber : "",
                protectedNumber: protectedNumber(part),
                title: title(for: part),
                category: part.categoryValue.title(language),
                model: part.model ?? "",
                years: Array(part.years.prefix(8)),
                engines: Array(part.engines.prefix(6)),
                confidence: part.confidence,
                evidenceCount: part.evidence.count,
                unlocked: isUnlocked(part)
            )
        }
        let safeMaintenance = maintenanceItems.prefix(5).map { item in
            AISafeMaintenanceItem(
                title: safePreview(item.title, limit: 80),
                odometer: safePreview(item.odometer, limit: 32),
                notesPreview: safePreview(item.notes, limit: 120)
            )
        }
        return AIAssistantRequest(
            message: safeAIPreview(message, limit: 800),
            language: language.rawValue,
            currentSearch: safeAIPreview(searchText, limit: 160),
            selectedCategory: selectedCategory.title(language),
            vehicleSummary: safeVehicleSummary(),
            parts: contextParts,
            maintenance: Array(safeMaintenance),
            savedRequestCount: savedRequests.count
        )
    }

    private func safeVehicleSummary() -> String {
        let values = [
            nonEmpty(vehicleProfile.generation),
            nonEmpty(vehicleProfile.year),
            nonEmpty(vehicleProfile.engine),
            nonEmpty(vehicleProfile.transmission)
        ].compactMap(\.self)
        return values.isEmpty
            ? text(ar: "لم يتم تحديد سيارة بعد.", en: "No vehicle selected yet.")
            : values.joined(separator: " · ")
    }

    private func safePreview(_ value: String, limit: Int) -> String {
        let trimmed = value
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)) + "..."
    }

    private func safeAIPreview(_ value: String, limit: Int) -> String {
        let protected = parts.reduce(value) { partial, part in
            guard !isUnlocked(part) else { return partial }
            return part.allNumbers.reduce(partial) { text, number in
                text.replacingOccurrences(of: number, with: protectedNumber(part), options: [.caseInsensitive])
            }
        }
        return safePreview(protected, limit: limit)
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
            try await analyzePhotoData(data)
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

    func analyzeCapturedPartImage(_ image: UIImage) async {
        isAnalyzingPhoto = true
        selectedPhotoName = text(
            ar: "جاري تحليل صورة الكاميرا محليًا...",
            en: "Analyzing the camera image on device..."
        )
        defer { isAnalyzingPhoto = false }

        do {
            guard let data = image.jpegData(compressionQuality: 0.9), !data.isEmpty else {
                throw AppError.unreadablePhoto
            }
            try await analyzePhotoData(data)
        } catch is CancellationError {
            return
        } catch {
            selectedPhotoName = nil
            errorMessage = text(
                ar: "تعذر قراءة رقم قطعة واضح من صورة الكاميرا. صوّر الملصق أو النقش بوضوح أكبر.",
                en: "No clear part number could be read from the camera image. Capture the label or stamping more clearly."
            )
        }
    }

    private func analyzePhotoData(_ data: Data) async throws {
        try Task.checkCancellation()
        let recognizedLines = try await photoTextRecognizer.recognizeText(in: data)
        try Task.checkCancellation()
        applyRecognizedPhotoText(recognizedLines)
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
        if let matchingNumber {
            selectedPart = fitmentMatches(for: matchingNumber).first ?? filteredParts.first
        } else {
            selectedPart = filteredParts.first
        }
        if let selectedPart {
            selectedPhotoName = text(
                ar: "تم العثور على مرشح: \(protectedNumber(selectedPart)). \(photoCandidateSummary(for: selectedPart)). افتح صفحة الكتالوج بـ 4 ر.س لعرض الرقم الكامل وصورة القطعة.",
                en: "Candidate found: \(protectedNumber(selectedPart)). \(photoCandidateSummary(for: selectedPart)). Unlock this catalog page for SAR 4 to show the full number and part image."
            )
        } else {
            selectedPhotoName = text(
                ar: "تمت قراءة الصورة. افتح نتيجة مطابقة، ثم افتح القطعة لعرض الرقم الكامل وصورة القطعة.",
                en: "Photo analyzed. Open a matching result, then unlock the part to reveal the full number and part image."
            )
        }
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
}
