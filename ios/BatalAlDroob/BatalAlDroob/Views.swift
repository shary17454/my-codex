import SwiftUI

// MARK: - Views

struct RootView: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        ZStack {
            TabView {
                DashboardView(viewModel: viewModel)
                    .tabItem { Label(
                        viewModel.text(ar: "الرئيسية", en: "Home"),
                        systemImage: "gauge.with.dots.needle.bottom.50percent"
                    ) }
                CatalogView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "الكتالوج", en: "Catalog"), systemImage: "magnifyingglass") }
                RequestView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "طلب قطعة", en: "Request"), systemImage: "cart.badge.plus") }
                MoreView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "الأدوات", en: "Tools"), systemImage: "wrench.and.screwdriver")
                    }
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
    @State private var fitmentQuery = "21082-4W000"
    @State private var fitmentResult = ""
    @State private var fitmentMatches: [Part] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BatalHeroCard(
                        eyebrow: viewModel.text(ar: "كتالوج Y60 محلي", en: "Local Y60 catalog"),
                        title: viewModel.text(ar: "بطل الدروب", en: "Batal Al-Droob"),
                        message: viewModel.text(
                            ar: "ابدأ من رقم القطعة، الوصف، أو التوافق ثم جهز طلبًا واضحًا للمورد.",
                            en: "Start from a part number, description, or fitment check, " +
                                "then prepare a clear supplier request."
                        ),
                        symbol: "shippingbox.and.arrow.backward"
                    )
                }

                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "حالة الكتالوج", en: "Catalog status"),
                        subtitle: viewModel.text(
                            ar: "قاعدة محلية مدمجة، بدون تسجيل دخول أو اتصال بخادم تابع لنا.",
                            en: "Bundled local database, with no sign-in or developer-operated server."
                        )
                    )
                    StatsHeader(viewModel: viewModel)
                }

                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "ابدأ بسرعة", en: "Start quickly"),
                        subtitle: viewModel.text(
                            ar: "الأكثر استخدامًا في التطبيق في مكان واحد.",
                            en: "The most-used workflows in one place."
                        )
                    )
                    HomeWorkflowRow(
                        symbol: "magnifyingglass",
                        title: viewModel.text(ar: "ابحث في الكتالوج", en: "Search the catalog"),
                        detail: viewModel.text(
                            ar: "استخدم تبويب الكتالوج للبحث برقم القطعة أو الاسم أو القسم.",
                            en: "Use the Catalog tab to search by part number, name, or category."
                        )
                    )
                    HomeWorkflowRow(
                        symbol: "cart.badge.plus",
                        title: viewModel.text(ar: "جهز طلب قطعة", en: "Prepare a part request"),
                        detail: viewModel.text(
                            ar: "احفظ طلبًا منظمًا قابلًا للمشاركة مع المورد.",
                            en: "Save a structured request that can be shared with a supplier."
                        )
                    )
                    HomeWorkflowRow(
                        symbol: "wrench.adjustable",
                        title: viewModel.text(ar: "سجل الصيانة", en: "Log maintenance"),
                        detail: viewModel.text(
                            ar: "احفظ أعمال الصيانة محليًا داخل الجهاز.",
                            en: "Keep maintenance entries locally on the device."
                        )
                    )
                }

                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "تحقق سريع من التوافق", en: "Quick fitment check"),
                        subtitle: viewModel.text(
                            ar: "يعطيك أفضل مطابقة من قاعدة الكتالوج قبل فتح التفاصيل.",
                            en: "Shows the best catalog match before opening details."
                        )
                    )
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

                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "قطع مدققة", en: "Verified records"),
                        subtitle: viewModel.text(
                            ar: "عينات جاهزة للمراجعة من بيانات الكتالوج.",
                            en: "Review-ready samples from the catalog data."
                        )
                    )
                    ForEach(viewModel.reviewReadyParts) { part in
                        NavigationLink(value: part) {
                            PartRow(part: part, viewModel: viewModel)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
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

struct BatalHeroCard: View {
    let eyebrow: String
    let title: String
    let message: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.tint, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
                VStack(alignment: .leading, spacing: 4) {
                    Text(eyebrow)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.largeTitle.bold())
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

struct BatalSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct HomeWorkflowRow: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.tint, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
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
                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "بحث القطع", en: "Parts search"),
                        subtitle: viewModel.text(
                            ar: "اكتب رقم القطعة أو اسمها ثم حدد القسم عند الحاجة.",
                            en: "Enter a part number or name, then narrow by category if needed."
                        )
                    )
                    Picker(viewModel.text(ar: "القسم", en: "Category"), selection: $viewModel.selectedCategory) {
                        ForEach(CatalogCategory.allCases) { category in
                            Label(category.title(viewModel.language), systemImage: category.symbol).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "النتائج", en: "Results"),
                        subtitle: viewModel.text(
                            ar: "\(viewModel.filteredParts.count.formatted()) نتيجة معروضة من الكتالوج.",
                            en: "\(viewModel.filteredParts.count.formatted()) displayed catalog results."
                        )
                    )
                    .accessibilityIdentifier("catalog.results")
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
            .listStyle(.insetGrouped)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            StatCard(
                title: viewModel.text(ar: "قطع مفهرسة", en: "Indexed parts"),
                value: viewModel.partCount.formatted(),
                symbol: "shippingbox"
            )
            StatCard(
                title: viewModel.text(ar: "سجلات", en: "Records"),
                value: viewModel.recordCount.formatted(),
                symbol: "doc.text.magnifyingglass"
            )
            StatCard(
                title: viewModel.text(ar: "مصادر", en: "Sources"),
                value: viewModel.sourceCount.formatted(),
                symbol: "books.vertical"
            )
            StatCard(
                title: viewModel.text(ar: "مفضلة", en: "Wishlist"),
                value: viewModel.wishlist.count.formatted(),
                symbol: "heart"
            )
        }
        .padding(.vertical, 6)
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
