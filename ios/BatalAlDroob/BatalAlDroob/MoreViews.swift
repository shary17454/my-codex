import PhotosUI
import SwiftUI

struct MoreView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var descriptionQuery = ""
    @State private var oldTireSize = "265/70R16"
    @State private var newTireSize = "285/75R16"
    @State private var tireResult = ""
    @State private var maintenanceTitle = ""
    @State private var maintenanceOdometer = ""
    @State private var maintenanceNotes = ""

    var body: some View {
        let photoPickerTitle = viewModel.text(ar: "اختيار صورة كمرجع", en: "Choose reference photo")
        return NavigationStack {
            List {
                Section {
                    ToolsHeroView(viewModel: viewModel)
                }
                Section(viewModel.text(ar: "مركز العمل", en: "Action center")) {
                    ToolsActionGrid(viewModel: viewModel)
                }
                Section(viewModel.text(ar: "بحث بالوصف والصورة", en: "Description and photo search")) {
                    TextField(
                        viewModel.text(ar: "اكتب وصف العطل أو القطعة", en: "Describe the fault or part"),
                        text: $descriptionQuery,
                        axis: .vertical
                    )
                    .lineLimit(2 ... 4)
                    Button { viewModel.applyDescriptionSearch(descriptionQuery) } label: {
                        Label(
                            viewModel.text(ar: "بحث بالوصف", en: "Search by description"),
                            systemImage: "text.magnifyingglass"
                        )
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
                        Button { viewModel.openStore(store, part: nil) } label: { Label(
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
            .navigationTitle(viewModel.text(ar: "المزيد", en: "More"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { part in
                PartDetailView(part: part, viewModel: viewModel)
            }
        }
    }
}

struct ToolsHeroView: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(viewModel.text(ar: "أدوات بطل الدروب", en: "Batal Al-Droob tools"), systemImage: "sparkles")
                .font(.title3.bold())
                .foregroundStyle(.primary)
            Text(viewModel.text(
                ar: "كل ما تحتاجه لتحويل رقم القطعة أو الوصف إلى طلب واضح ورابط متجر موثق.",
                en: "Turn a part number or description into a clear request and verified store handoff."
            ))
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

struct ToolsActionGrid: View {
    @Bindable var viewModel: CatalogViewModel

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
                ToolsActionCard(
                    symbol: "text.magnifyingglass",
                    title: viewModel.text(ar: "بحث ذكي", en: "Smart search"),
                    detail: viewModel.text(ar: "وصف العطل أو رقم القطعة.", en: "Fault description or part number.")
                )
                ToolsActionCard(
                    symbol: "checkmark.seal",
                    title: viewModel.text(ar: "تحقق التوافق", en: "Fitment check"),
                    detail: viewModel.text(
                        ar: "مطابقة القطعة مع السنوات والمحركات.",
                        en: "Match parts with years and engines."
                    )
                )
                ToolsActionCard(
                    symbol: "cart.badge.plus",
                    title: viewModel.text(ar: "تجهيز طلب", en: "Prepare request"),
                    detail: viewModel.text(ar: "نص منظم لإرساله للمورد.", en: "Structured text to send to suppliers.")
                )
                ToolsActionCard(
                    symbol: "wrench.and.screwdriver",
                    title: viewModel.text(ar: "سجل الصيانة", en: "Maintenance log"),
                    detail: viewModel.text(ar: "حفظ الأعمال والملاحظات محليًا.", en: "Save work and notes locally.")
                )
            }
        }
        .padding(.vertical, 6)
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous))
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

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash.fill").font(.largeTitle)
            Text(language == .arabic ? "المحتوى محمي" : "Content protected").font(.title.bold())
            Text(language == .arabic ? "تم حجب الكتالوج عندما لا يكون التطبيق نشطًا." :
                "The catalog is hidden while the app is inactive.")
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
