import PhotosUI
import SwiftUI
import UIKit

enum MoreToolDestination: Hashable {
    case smartSearch
    case fitment
    case request
    case maintenance
}

struct MoreView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var toolPath: [MoreToolDestination] = []
    @State private var descriptionQuery = ""
    @State private var descriptionMatches: [Part] = []
    @State private var descriptionStatus = ""
    @State private var oldTireSize = "265/70R16"
    @State private var newTireSize = "285/75R16"
    @State private var tireResult = ""
    @State private var maintenanceTitle = ""
    @State private var maintenanceOdometer = ""
    @State private var maintenanceNotes = ""
    @State private var isCameraPresented = false

    var body: some View {
        let photoPickerTitle = viewModel.text(ar: "اختيار صورة كمرجع", en: "Choose reference photo")
        let cameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
        return NavigationStack(path: $toolPath) {
            List {
                Section {
                    ToolsHeroView(viewModel: viewModel)
                }
                CustomerAccountSection(viewModel: viewModel)
                Section(viewModel.text(ar: "مركز العمل", en: "Action center")) {
                    ToolsActionGrid(
                        viewModel: viewModel,
                        maintenanceTitle: $maintenanceTitle,
                        maintenanceOdometer: $maintenanceOdometer,
                        maintenanceNotes: $maintenanceNotes,
                        openTool: { toolPath.append($0) }
                    )
                }
                Section(viewModel.text(ar: "بحث بالوصف والصورة", en: "Description and photo search")) {
                    TextField(
                        viewModel.text(ar: "اكتب وصف العطل أو القطعة", en: "Describe the fault or part"),
                        text: $descriptionQuery,
                        axis: .vertical
                    )
                    .lineLimit(2 ... 4)
                    Button {
                        AppHaptics.lightImpact()
                        viewModel.applyDescriptionSearch(descriptionQuery)
                        descriptionMatches = viewModel.filteredParts
                        descriptionStatus = descriptionSearchStatus
                    } label: {
                        Label(
                            viewModel.text(ar: "بحث بالوصف", en: "Search by description"),
                            systemImage: "text.magnifyingglass"
                        )
                    }
                    .disabled(descriptionQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if !descriptionStatus.isEmpty {
                        Text(descriptionStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(descriptionMatches.prefix(6)) { part in
                        NavigationLink(value: part) {
                            PartRow(part: part, viewModel: viewModel)
                        }
                    }
                    Button {
                        AppHaptics.lightImpact()
                        isCameraPresented = true
                    } label: {
                        Label(
                            viewModel.text(ar: "تصوير القطعة أو رقمها", en: "Capture part or number"),
                            systemImage: "camera.viewfinder"
                        )
                    }
                    .disabled(!cameraAvailable)
                    if !cameraAvailable {
                        Text(viewModel.text(
                            ar: "الكاميرا غير متاحة على هذا الجهاز أو المحاكي.",
                            en: "Camera is not available on this device or simulator."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    Button {
                        AppHaptics.lightImpact()
                        tireResult = viewModel.tireDifference(oldSize: oldTireSize, newSize: newTireSize)
                    } label: {
                        Label(
                            viewModel.text(ar: "احسب الفرق", en: "Calculate difference"),
                            systemImage: "gauge.with.dots.needle.33percent"
                        )
                    }
                    if !tireResult.isEmpty {
                        Text(tireResult)
                            .font(.headline.monospacedDigit())
                            .textSelection(.enabled)
                    }
                }
                Section(viewModel.text(ar: "مسارات سريعة", en: "Quick paths")) {
                    NavigationLink {
                        SharedFitmentContent(viewModel: viewModel)
                            .navigationTitle(viewModel.text(ar: "القطع المشتركة", en: "Shared fitment"))
                    } label: {
                        Label(
                            viewModel.text(ar: "القطع المشتركة", en: "Shared fitment"),
                            systemImage: "point.3.connected.trianglepath.dotted"
                        )
                    }
                    NavigationLink {
                        MaintenanceContent(
                            viewModel: viewModel,
                            title: $maintenanceTitle,
                            odometer: $maintenanceOdometer,
                            notes: $maintenanceNotes
                        )
                        .navigationTitle(viewModel.text(ar: "الصيانة", en: "Maintenance"))
                    } label: {
                        Label(viewModel.text(ar: "الصيانة", en: "Maintenance"), systemImage: "wrench.adjustable")
                    }
                }
                Section(viewModel.text(ar: "قائمة الرغبات", en: "Wishlist")) {
                    if viewModel.wishlistParts.isEmpty {
                        EmptyStateView(
                            symbol: "heart",
                            title: viewModel.text(ar: "قائمة الرغبات فارغة", en: "Wishlist is empty"),
                            message: viewModel.text(
                                ar: "افتح أي قطعة واضغط القلب لحفظها هنا.",
                                en: "Open a part and tap the heart to save it here."
                            )
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
                        Button {
                            AppHaptics.lightImpact()
                            viewModel.openStore(store, part: nil)
                        } label: { Label(
                            store.name(language: viewModel.language),
                            systemImage: "link"
                        ) }
                    }
                }
                Section(viewModel.text(ar: "اللغة", en: "Language")) { LanguageMenu(viewModel: viewModel) }
                Section(viewModel.text(ar: "سياسة البيانات", en: "Data policy")) {
                    Text(viewModel.text(
                        ar: "التطبيق مستقل ولا يتبع نيسان، ولا ينسخ أسعار المتاجر أو مخزونها. " +
                            "تُفتح روابط المتاجر الموثقة لإكمال البحث أو الشراء خارج التطبيق. " +
                            "لا يرسل التطبيق صور البحث أو بيانات السيارة أو سجلات الصيانة " +
                            "إلى خادم تابع لنا.",
                        en: "This app is independent from Nissan and does not copy store prices or inventory. " +
                            "Verified store links open externally to continue searching or purchasing. " +
                            "The app does not send reference photos, vehicle details, or maintenance entries " +
                            "to a developer-operated server."
                    ))
                }
            }
            .fullScreenCover(isPresented: $isCameraPresented) {
                CameraCaptureView { image in
                    Task { await viewModel.analyzeCapturedPartImage(image) }
                }
                .ignoresSafeArea()
            }
            .navigationTitle(viewModel.text(ar: "المزيد", en: "More"))
            .scrollContentBackground(.hidden)
            .background(BatalDesign.canvas)
            .listStyle(.insetGrouped)
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { part in
                PartDetailView(part: part, viewModel: viewModel)
            }
            .navigationDestination(for: MoreToolDestination.self) { destination in
                switch destination {
                case .smartSearch:
                    SmartSearchContent(viewModel: viewModel)
                case .fitment:
                    SharedFitmentContent(viewModel: viewModel)
                        .navigationTitle(viewModel.text(ar: "تحقق التوافق", en: "Fitment check"))
                case .request:
                    RequestView(viewModel: viewModel)
                case .maintenance:
                    MaintenanceContent(
                        viewModel: viewModel,
                        title: $maintenanceTitle,
                        odometer: $maintenanceOdometer,
                        notes: $maintenanceNotes
                    )
                    .navigationTitle(viewModel.text(ar: "الصيانة", en: "Maintenance"))
                }
            }
        }
    }

    private var descriptionSearchStatus: String {
        let count = viewModel.filteredParts.count
        if count == 0 {
            return viewModel.text(
                ar: "لم أجد نتائج مطابقة. جرّب وصفًا أدق أو رقم قطعة.",
                en: "No matches found. Try a more specific description or part number."
            )
        }
        return viewModel.text(
            ar: "تم العثور على \(count) نتيجة. افتح أي قطعة للاطلاع على التفاصيل.",
            en: "Found \(count) results. Open any part to review details."
        )
    }
}

private struct CustomerAccountSection: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var statusMessage: String?

    var body: some View {
        Section(viewModel.text(ar: "الحساب", en: "Account")) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(BatalDesign.brand)
                    .frame(width: 40, height: 40)
                    .background(BatalDesign.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.control))
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.customerAccessTitle)
                        .font(.headline)
                    Text(viewModel.customerAccessSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            TextField(viewModel.text(ar: "الاسم اختياري", en: "Name optional"), text: $name)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("account.name")
            TextField(viewModel.text(ar: "البريد الإلكتروني", en: "Email"), text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("account.email")

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                AppHaptics.lightImpact()
                if viewModel.saveLocalCustomer(name: name, email: email) {
                    statusMessage = viewModel.text(ar: "تم حفظ الحساب المحلي.", en: "Local account saved.")
                } else {
                    statusMessage = viewModel.text(ar: "اكتب بريدًا صحيحًا.", en: "Enter a valid email.")
                }
            } label: {
                Label(viewModel.text(ar: "حفظ البريد على الجهاز", en: "Save email on device"), systemImage: "envelope.badge")
            }
            .accessibilityIdentifier("account.saveEmail")
        }
        .onAppear {
            name = viewModel.customerProfile.displayName
            email = viewModel.customerProfile.email
        }
    }
}

struct ToolsHeroView: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(BatalDesign.accent)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.text(ar: "أدوات بطل الدروب", en: "Batal Al-Droob tools"))
                        .font(.title3.bold())
                    Text(viewModel.text(ar: "مركز تشغيل سريع", en: "Fast operating center"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(viewModel.text(
                ar: "كل ما تحتاجه لتحويل رقم القطعة أو الوصف إلى طلب واضح ورابط متجر موثق.",
                en: "Turn a part number or description into a clear request and verified store handoff."
            ))
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [BatalDesign.brand.opacity(0.16), BatalDesign.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
                .stroke(BatalDesign.border)
        )
        .accessibilityElement(children: .combine)
    }
}

struct ToolsActionGrid: View {
    @Bindable var viewModel: CatalogViewModel
    @Binding var maintenanceTitle: String
    @Binding var maintenanceOdometer: String
    @Binding var maintenanceNotes: String
    let openTool: (MoreToolDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.text(
                ar: "أدوات مرتبطة مباشرة بقطع الباترول: بحث، توافق، طلب، صيانة، وروابط متاجر موثقة.",
                en: "Patrol parts tools focused on search, fitment, requests, maintenance, and verified stores."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("more.section.action-center")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                Button {
                    AppHaptics.lightImpact()
                    openTool(.smartSearch)
                } label: {
                    ToolsActionCard(
                        symbol: "text.magnifyingglass",
                        title: viewModel.text(ar: "بحث ذكي", en: "Smart search"),
                        detail: viewModel.text(ar: "وصف العطل أو رقم القطعة.", en: "Fault description or part number.")
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tools.action.smart-search")

                Button {
                    AppHaptics.lightImpact()
                    openTool(.fitment)
                } label: {
                    ToolsActionCard(
                        symbol: "checkmark.seal",
                        title: viewModel.text(ar: "تحقق التوافق", en: "Fitment check"),
                        detail: viewModel.text(
                            ar: "مطابقة القطعة مع السنوات والمحركات.",
                            en: "Match parts with years and engines."
                        )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tools.action.fitment")

                Button {
                    AppHaptics.lightImpact()
                    openTool(.request)
                } label: {
                    ToolsActionCard(
                        symbol: "cart.badge.plus",
                        title: viewModel.text(ar: "تجهيز طلب", en: "Prepare request"),
                        detail: viewModel.text(
                            ar: "نص منظم لإرساله للمورد.",
                            en: "Structured text to send to suppliers."
                        )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tools.action.request")

                Button {
                    AppHaptics.lightImpact()
                    openTool(.maintenance)
                } label: {
                    ToolsActionCard(
                        symbol: "wrench.and.screwdriver",
                        title: viewModel.text(ar: "سجل الصيانة", en: "Maintenance log"),
                        detail: viewModel.text(ar: "حفظ الأعمال والملاحظات محليًا.", en: "Save work and notes locally.")
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tools.action.maintenance")
            }
        }
        .padding(.vertical, 6)
    }
}

struct SmartSearchContent: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        List {
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
                        message: viewModel.text(
                            ar: "اكتب رقم قطعة أو وصفًا أدق من خانة البحث في الأعلى.",
                            en: "Enter a part number or more specific description in the search field above."
                        )
                    )
                } else {
                    ForEach(viewModel.filteredParts) { part in
                        NavigationLink(value: part) {
                            PartRow(part: part, viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: viewModel.text(
                ar: "رقم القطعة، الوصف، السنة، أو المحرك",
                en: "Part number, description, year, or engine"
            )
        )
        .navigationTitle(viewModel.text(ar: "بحث ذكي", en: "Smart search"))
    }
}

struct ToolsActionCard: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.tint)
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(14)
        .background(BatalDesign.surface, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
                .stroke(BatalDesign.border)
        )
        .contentShape(RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous))
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
                .accessibilityIdentifier("language.option.\(language.rawValue)")
            }
        } label: { Label(viewModel.language.title, systemImage: "globe") }
            .accessibilityIdentifier("language.menu")
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

    /// Same fallback chain as `CatalogViewModel.text(ar:en:)`. This view only receives the
    /// language (it is drawn above the tab bar without the view model), so it resolves the
    /// translation itself rather than hardcoding an Arabic/English pair.
    private func text(ar arabic: String, en english: String) -> String {
        switch language {
        case .arabic: arabic
        case .english: english
        default: BatalLocalization.translate(english, to: language) ?? english
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash.fill").font(.largeTitle)
            Text(text(ar: "المحتوى محمي", en: "Content protected")).font(.title.bold())
            Text(text(
                ar: "يظهر هذا الغطاء فقط عند مغادرة التطبيق أو فتح مبدل التطبيقات لحماية بيانات الكتالوج.",
                en: "This shield appears only when you leave the app or open the app switcher to protect catalog data."
            ))
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
