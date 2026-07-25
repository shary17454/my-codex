import SwiftUI

// MARK: - Views

enum AppTab: Hashable {
    case dashboard
    case catalog
    case request
    case tools
}

struct RootView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var selectedTab = AppTab.dashboard

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                DashboardView(viewModel: viewModel) { tab in
                    selectedTab = tab
                }
                    .tabItem { Label(
                        viewModel.text(ar: "الرئيسية", en: "Home"),
                        systemImage: "gauge.with.dots.needle.bottom.50percent"
                    ) }
                    .tag(AppTab.dashboard)
                CatalogView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "الكتالوج", en: "Catalog"), systemImage: "magnifyingglass") }
                    .tag(AppTab.catalog)
                RequestView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "طلب قطعة", en: "Request"), systemImage: "cart.badge.plus") }
                    .tag(AppTab.request)
                MoreView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "الأدوات", en: "Tools"), systemImage: "wrench.and.screwdriver")
                    }
                    .tag(AppTab.tools)
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
        .alert(
            viewModel.text(ar: "تنبيه", en: "Notice"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(viewModel.text(ar: "إعادة المحاولة", en: "Retry")) {
                viewModel.errorMessage = nil
                Task { await viewModel.load() }
            }
            Button(viewModel.text(ar: "حسنًا", en: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct DashboardView: View {
    @Bindable var viewModel: CatalogViewModel
    let openTab: (AppTab) -> Void
    @State private var fitmentQuery = "21082-4W000"
    @State private var fitmentResult = ""
    @State private var fitmentMatches: [Part] = []

    private func quickAction(
        tab: AppTab,
        identifier: String,
        symbol: String,
        title: String,
        detail: String
    ) -> some View {
        Button {
            openTab(tab)
        } label: {
            FeatureRow(symbol: symbol, title: title, detail: detail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityHint(viewModel.text(ar: "يفتح القسم المطلوب.", en: "Opens the requested section."))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(viewModel.text(ar: "بطل الدروب", en: "Batal Al-Droob"))
                            .font(.largeTitle.bold())
                        Text(viewModel.text(
                            ar: "تطبيق أصلي للبحث في قطع نيسان باترول، التحقق من التوافق، " +
                                "حفظ الصيانة، وتجهيز طلبات القطع.",
                            en: "A native app for Nissan Patrol parts search, fitment checks, " +
                                "maintenance logging, and part request preparation."
                        ))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section(viewModel.text(ar: "ابدأ بسرعة", en: "Start quickly")) {
                    quickAction(
                        tab: .catalog,
                        identifier: "home.quick.catalog",
                        symbol: "magnifyingglass.square.fill",
                        title: viewModel.text(ar: "ابحث في الكتالوج", en: "Search the catalog"),
                        detail: viewModel.text(
                            ar: "افتح البحث المحلي برقم القطعة أو الاسم أو القسم.",
                            en: "Open local search by part number, name, or category."
                        )
                    )
                    quickAction(
                        tab: .request,
                        identifier: "home.quick.request",
                        symbol: "cart.badge.plus",
                        title: viewModel.text(ar: "جهز طلب قطعة", en: "Prepare a part request"),
                        detail: viewModel.text(
                            ar: "اكتب بيانات السيارة والقطعة واحفظ نصًا جاهزًا للمورد.",
                            en: "Enter vehicle and part details, then save a supplier-ready request."
                        )
                    )
                    quickAction(
                        tab: .tools,
                        identifier: "home.quick.tools",
                        symbol: "wrench.and.screwdriver",
                        title: viewModel.text(ar: "افتح الأدوات", en: "Open tools"),
                        detail: viewModel.text(
                            ar: "انتقل إلى البحث الذكي، التوافق، الصيانة، وحاسبة الكفرات.",
                            en: "Go to smart search, fitment, maintenance, and the tire calculator."
                        )
                    )
                }

                Section(viewModel.text(ar: "لوحة الكتالوج المحلي", en: "Native catalog dashboard")) {
                    StatsHeader(viewModel: viewModel, openTab: openTab)
                    ForEach(CatalogCategory.allCases.filter { $0 != .all }.prefix(6)) { category in
                        LabeledContent(
                            category.title(viewModel.language),
                            value: viewModel.categoryCount(category).formatted()
                        )
                    }
                }

                Section(viewModel.text(ar: "عينات مدققة قابلة للفتح", en: "Verified native records")) {
                    ForEach(viewModel.reviewReadyParts) { part in
                        NavigationLink(value: part) {
                            PartRow(part: part, viewModel: viewModel)
                        }
                    }
                }

                Section(viewModel.text(ar: "تحقق سريع من التوافق", en: "Quick fitment check")) {
                    TextField(
                        viewModel.text(ar: "رقم القطعة أو الوصف", en: "Part number or description"),
                        text: $fitmentQuery
                    )
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
                            message: viewModel.text(
                                ar: "جرّب رقم قطعة، اسم قسم، سنة، أو محرك مختلف.",
                                en: "Try another part number, category, year, or engine."
                            )
                        )
                    } else {
                        ForEach(viewModel.filteredParts) { part in
                            NavigationLink(value: part) { PartRow(part: part, viewModel: viewModel) }
                        }
                    }
                }
            }
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: viewModel.text(
                    ar: "رقم القطعة، الاسم، القسم، أو VIN",
                    en: "Part number, name, category, or VIN"
                )
            )
            .navigationTitle(viewModel.text(ar: "بطل الدروب", en: "Batal Al-Droob"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { part in PartDetailView(part: part, viewModel: viewModel) }
        }
    }
}

struct StatsHeader: View {
    @Bindable var viewModel: CatalogViewModel
    var openTab: ((AppTab) -> Void)?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            statCard(
                title: viewModel.text(ar: "قطع مفهرسة", en: "Indexed parts"),
                value: viewModel.partCount.formatted(),
                symbol: "shippingbox",
                tab: .catalog,
                identifier: "home.stats.parts"
            )
            statCard(
                title: viewModel.text(ar: "سجلات", en: "Records"),
                value: viewModel.recordCount.formatted(),
                symbol: "doc.text.magnifyingglass",
                tab: .catalog,
                identifier: "home.stats.records"
            )
            statCard(
                title: viewModel.text(ar: "مصادر", en: "Sources"),
                value: viewModel.sourceCount.formatted(),
                symbol: "books.vertical",
                tab: .tools,
                identifier: "home.stats.sources"
            )
            statCard(
                title: viewModel.text(ar: "مفضلة", en: "Wishlist"),
                value: viewModel.wishlist.count.formatted(),
                symbol: "heart",
                tab: .tools,
                identifier: "home.stats.wishlist"
            )
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func statCard(
        title: String,
        value: String,
        symbol: String,
        tab: AppTab,
        identifier: String
    ) -> some View {
        if let openTab {
            Button {
                openTab(tab)
            } label: {
                StatCard(title: title, value: value, symbol: symbol)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(identifier)
            .accessibilityHint(viewModel.text(ar: "يفتح القسم المرتبط.", en: "Opens the related section."))
        } else {
            StatCard(title: title, value: value, symbol: symbol)
        }
    }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).font(.title2).foregroundStyle(.tint)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
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
                Text([part.model, part.categoryAr ?? part.category, part.years.prefix(3).joined(separator: ", ")]
                    .compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " · "))
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
