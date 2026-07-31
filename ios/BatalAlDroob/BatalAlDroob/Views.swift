import SwiftUI

// MARK: - Views

enum AppTab: Hashable {
    case dashboard
    case catalog
    case assistant
    case request
    case tools
}

struct RootView: View {
    @Bindable var viewModel: CatalogViewModel
    @AppStorage("hasCompletedInitialPermissionOnboarding") private var hasCompletedInitialPermissionOnboarding = false
    @State private var selectedTab = AppTab.dashboard
    @State private var isPermissionOnboardingPresented = false

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
                AIAssistantView(viewModel: viewModel)
                    .tabItem { Label(viewModel.text(ar: "المساعد", en: "Assistant"), systemImage: "sparkles") }
                    .tag(AppTab.assistant)
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
        .tint(BatalDesign.brand)
        .background(BatalDesign.canvas)
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-skipPermissionOnboardingForUITests") {
                hasCompletedInitialPermissionOnboarding = true
            }
            guard !hasCompletedInitialPermissionOnboarding else { return }
            isPermissionOnboardingPresented = true
        }
        .fullScreenCover(isPresented: $isPermissionOnboardingPresented) {
            PermissionOnboardingView(viewModel: viewModel) {
                hasCompletedInitialPermissionOnboarding = true
                isPermissionOnboardingPresented = false
            }
            .environment(\.layoutDirection, viewModel.language == .arabic ? .rightToLeft : .leftToRight)
            .environment(\.locale, viewModel.language.locale)
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
            AppHaptics.lightImpact()
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
            ScrollView {
                LazyVStack(alignment: .leading, spacing: BatalDesign.roomySpacing) {
                    DashboardHero(viewModel: viewModel) { generationID in
                        viewModel.focusCatalog(onGeneration: generationID)
                        openTab(.catalog)
                    }

                    PatrolGenerationsSection(viewModel: viewModel) {
                        openTab(.catalog)
                    }

                    DashboardSectionTitle(
                        title: viewModel.text(ar: "ابدأ بسرعة", en: "Start quickly"),
                        subtitle: viewModel.text(ar: "اختصر أكثر المسارات استخدامًا.", en: "Jump into the most-used workflows.")
                    )
                    VStack(spacing: 10) {
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
                            tab: .assistant,
                            identifier: "home.quick.assistant",
                            symbol: "sparkles.square.filled.on.square",
                            title: viewModel.text(ar: "اسأل مساعد بطل الدروب", en: "Ask Batal Assistant"),
                            detail: viewModel.text(
                                ar: "احصل على ترشيحات وتفسير للتوافق من سياق الكتالوج الحالي.",
                                en: "Get suggestions and fitment explanations from the current catalog context."
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

                    DashboardSectionTitle(
                        title: viewModel.text(ar: "لوحة الكتالوج المحلي", en: "Native catalog dashboard"),
                        subtitle: viewModel.text(ar: "أرقام سريعة من قاعدة البيانات المدمجة.", en: "Fast signals from the bundled database.")
                    )
                    VStack(spacing: 12) {
                        StatsHeader(viewModel: viewModel, openTab: openTab)
                        CategorySummaryGrid(viewModel: viewModel)
                    }

                    DashboardSectionTitle(
                        title: viewModel.text(ar: "عينات مدققة قابلة للفتح", en: "Verified native records"),
                        subtitle: viewModel.text(ar: "نتائج جاهزة للفحص والتجربة.", en: "Review-ready records for quick inspection.")
                    )
                    VStack(spacing: 10) {
                        ForEach(viewModel.reviewReadyParts) { part in
                            NavigationLink(value: part) {
                                PremiumPartRow(part: part, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    DashboardSectionTitle(
                        title: viewModel.text(ar: "تحقق سريع من التوافق", en: "Quick fitment check"),
                        subtitle: viewModel.text(ar: "اختبر رقم قطعة قبل تجهيز الطلب.", en: "Check a part number before preparing a request.")
                    )
                    VStack(alignment: .leading, spacing: 12) {
                        TextField(
                            viewModel.text(ar: "رقم القطعة أو الوصف", en: "Part number or description"),
                            text: $fitmentQuery
                        )
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        Button {
                            AppHaptics.lightImpact()
                            fitmentResult = viewModel.fitmentSummary(for: fitmentQuery)
                            fitmentMatches = viewModel.fitmentMatches(for: fitmentQuery)
                        } label: {
                            Label(viewModel.text(ar: "تحقق الآن", en: "Check now"), systemImage: "checkmark.seal")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.batalPrimary)
                        if !fitmentResult.isEmpty {
                            Text(fitmentResult)
                                .font(.callout.monospaced())
                                .textSelection(.enabled)
                        }
                        ForEach(fitmentMatches) { part in
                            NavigationLink(value: part) {
                                PremiumPartRow(part: part, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .premiumPanel()
                }
                .padding(BatalDesign.screenPadding)
            }
            .background(BatalDesign.canvas)
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
        .frame(maxWidth: .infinity, minHeight: BatalDesign.controlHeight, alignment: .leading)
        .padding(14)
        .premiumPanel()
    }
}

struct DashboardHero: View {
    @Bindable var viewModel: CatalogViewModel
    let openGeneration: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                heroImage
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.72), .black.opacity(0.24), .black.opacity(0.04)],
                    startPoint: .bottom,
                    endPoint: .top
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.text(ar: "مرحبًا في بطل الدروب", en: "Welcome to Batal Al-Droob"))
                        .font(AppTypography.hero)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                    Text(viewModel.text(
                        ar: "كتالوج باترول عملي يجمع الصور، الأجيال، أرقام القطع، التوافق، والطلبات في مكان واحد.",
                        en: "A Patrol workbench for generation visuals, part numbers, fitment, requests, and catalog lookup."
                    ))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
            }
            .clipShape(RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
                    .stroke(.white.opacity(0.16))
            )

            HStack(spacing: 8) {
                HeroMetric(
                    value: viewModel.partCount.formatted(),
                    label: viewModel.text(ar: "قطعة", en: "Parts")
                )
                HeroMetric(
                    value: viewModel.sourceCount.formatted(),
                    label: viewModel.text(ar: "مصدر", en: "Sources")
                )
                HeroMetric(
                    value: viewModel.stores.count.formatted(),
                    label: viewModel.text(ar: "متجر", en: "Stores")
                )
            }

            HStack(spacing: 8) {
                HeroGenerationPill(title: "Y60", subtitle: "1988-1997", isActive: true) {
                    openGeneration("Y60")
                }
                HeroGenerationPill(title: "Y61", subtitle: "1997-2010", isActive: false) {
                    openGeneration("Y61")
                }
                HeroGenerationPill(title: "Y62", subtitle: "2010-2024", isActive: false) {
                    openGeneration("Y62")
                }
                HeroGenerationPill(
                    title: "Y63",
                    subtitle: viewModel.text(ar: "الأحدث", en: "Newest"),
                    isActive: false
                ) {
                    openGeneration("Y63")
                }
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [AppColors.brandDeep.opacity(0.22), BatalDesign.brand.opacity(0.16), BatalDesign.surface],
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

    @ViewBuilder
    private var heroImage: some View {
        if let image = GenerationImageLoader.image(named: "patrol-y60") {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [AppColors.brandDeep, AppColors.brand, AppColors.accent.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "car.side.fill")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
    }
}

struct HeroMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
    }
}

struct HeroGenerationPill: View {
    let title: String
    let subtitle: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button {
            AppHaptics.lightImpact()
            action()
        } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption.weight(.heavy))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(isActive ? BatalDesign.brand : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 6)
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .background(
            isActive ? BatalDesign.brand.opacity(0.14) : Color.secondary.opacity(0.10),
            in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(isActive ? BatalDesign.brand.opacity(0.24) : BatalDesign.border)
        )
        .accessibilityIdentifier("home.hero.generation.\(title)")
        .accessibilityLabel(title)
        .accessibilityHint("يفتح الكتالوج على جيل \(title)")
    }
}

private struct PatrolGeneration: Identifiable {
    let id: String
    let imageName: String
    let titleAr: String
    let titleEn: String
    let yearsAr: String
    let yearsEn: String
    let summaryAr: String
    let summaryEn: String
    let badgeAr: String
    let badgeEn: String
    let isActive: Bool
}

struct PatrolGenerationsSection: View {
    @Bindable var viewModel: CatalogViewModel
    let openCatalog: () -> Void

    private let generations = [
        PatrolGeneration(
            id: "Y60",
            imageName: "patrol-y60",
            titleAr: "الفئة الكلاسيكية",
            titleEn: "Classic generation",
            yearsAr: "1988-1997",
            yearsEn: "1988-1997",
            summaryAr: "الفئة الكلاسيكية التي طلبت إرجاع صورها، وهي مرتبطة الآن ببحث الكتالوج النشط.",
            summaryEn: "The restored classic generation visuals linked to the active catalog search.",
            badgeAr: "نشط",
            badgeEn: "Active",
            isActive: true
        ),
        PatrolGeneration(
            id: "Y61",
            imageName: "patrol-y61",
            titleAr: "جيل السفاري",
            titleEn: "Safari generation",
            yearsAr: "1997-2010",
            yearsEn: "1997-2010",
            summaryAr: "جيل السفاري ضمن بطاقات الأجيال، جاهز للتوسعة عند إدخال قاعدة بياناته.",
            summaryEn: "The Safari generation card, ready for expansion when its catalog is indexed.",
            badgeAr: "قادم",
            badgeEn: "Next",
            isActive: false
        ),
        PatrolGeneration(
            id: "Y62",
            imageName: "patrol-y62",
            titleAr: "الجيل الفاخر",
            titleEn: "Luxury generation",
            yearsAr: "2010-2024",
            yearsEn: "2010-2024",
            summaryAr: "جيل المنصة الحديثة مع صورة مستقلة وبطاقة واضحة داخل الرئيسية.",
            summaryEn: "A modern-platform generation with its own visual card on the home screen.",
            badgeAr: "قادم",
            badgeEn: "Next",
            isActive: false
        ),
        PatrolGeneration(
            id: "Y63",
            imageName: "patrol-y63",
            titleAr: "الجيل الجديد",
            titleEn: "New generation",
            yearsAr: "الجيل الأحدث",
            yearsEn: "Newest generation",
            summaryAr: "بطاقة الجيل الأحدث محفوظة ضمن هيكل الأجيال للتوافق المستقبلي.",
            summaryEn: "The newest generation card is kept in the generation framework for future support.",
            badgeAr: "مستقبلي",
            badgeEn: "Future",
            isActive: false
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DashboardSectionTitle(
                title: viewModel.text(ar: "أجيال الباترول", en: "Patrol generations"),
                subtitle: viewModel.text(
                    ar: "بطاقات الصور للأجيال الأربع؛ اضغط أي جيل لفتح الكتالوج على نطاقه.",
                    en: "Photo cards for the four generations. Tap a generation to focus the catalog."
                )
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(generations) { generation in
                        PatrolGenerationCard(generation: generation, viewModel: viewModel) {
                            viewModel.focusCatalog(onGeneration: generation.id)
                            openCatalog()
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .accessibilityIdentifier("home.generations.carousel")
        }
    }
}

private struct PatrolGenerationCard: View {
    let generation: PatrolGeneration
    @Bindable var viewModel: CatalogViewModel
    let openCatalog: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            AppHaptics.lightImpact()
            openCatalog()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                generationImage

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(generation.id)
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(generation.isActive ? BatalDesign.brand : .primary)
                        Spacer(minLength: 8)
                        Text(viewModel.text(ar: generation.badgeAr, en: generation.badgeEn))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                generation.isActive ? BatalDesign.brand.opacity(0.14) : Color.secondary.opacity(0.12),
                                in: Capsule()
                            )
                            .foregroundStyle(generation.isActive ? BatalDesign.brand : .secondary)
                    }

                    Text(viewModel.text(ar: generation.titleAr, en: generation.titleEn))
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(viewModel.text(ar: generation.yearsAr, en: generation.yearsEn))
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(BatalDesign.accent)

                    Text(viewModel.text(ar: generation.summaryAr, en: generation.summaryEn))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Label(
                        viewModel.text(
                            ar: "\(viewModel.generationRecordCount(for: generation.id).formatted()) سجل مرتبط",
                            en: "\(viewModel.generationRecordCount(for: generation.id).formatted()) linked records"
                        ),
                        systemImage: "externaldrive.badge.checkmark"
                    )
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BatalDesign.brand)

                    Label(
                        viewModel.text(ar: "فتح الكتالوج", en: "Open catalog"),
                        systemImage: "arrow.up.forward.app"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(generation.isActive ? BatalDesign.accent : .secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: 238, alignment: .topLeading)
        .padding(10)
        .background(BatalDesign.surface, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
                .stroke(generation.isActive ? BatalDesign.brand.opacity(colorScheme == .dark ? 0.45 : 0.30) : BatalDesign.border)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.generation.\(generation.id)")
    }

    @ViewBuilder
    private var generationImage: some View {
        if let image = GenerationImageLoader.image(named: generation.imageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 128)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [.black.opacity(0.55), .black.opacity(0.0)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
                }
        } else {
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .fill(.regularMaterial)
                .frame(height: 128)
                .overlay {
                    Image(systemName: "car.side")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(BatalDesign.accent)
                }
        }
    }
}

private enum GenerationImageLoader {
    static func image(named name: String) -> UIImage? {
        Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "models")
            .flatMap { UIImage(contentsOfFile: $0.path) }
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "models")
                .flatMap { UIImage(contentsOfFile: $0.path) }
    }
}

struct DashboardSectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(AppTypography.sectionTitle)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct CategorySummaryGrid: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
            ForEach(CatalogCategory.allCases.filter { $0 != .all }.prefix(6)) { category in
                HStack(spacing: 8) {
                    Image(systemName: category.symbol)
                        .foregroundStyle(BatalDesign.brand)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.title(viewModel.language))
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        Text(viewModel.categoryCount(category).formatted())
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(BatalDesign.surface, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
            }
        }
        .premiumPanel()
    }
}

struct PremiumPartRow: View {
    let part: Part
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        PartRow(part: part, viewModel: viewModel)
            .padding(12)
            .premiumPanel()
    }
}

struct CatalogView: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(
                            viewModel.text(ar: "كتالوج محلي سريع", en: "Fast local catalog"),
                            systemImage: "shippingbox.and.arrow.backward"
                        )
                        .font(.headline)
                        Text(viewModel.text(
                            ar: "ابحث في الأرقام والأوصاف والفئات بدون انتظار شبكة أو تسجيل دخول.",
                            en: "Search numbers, descriptions, and categories without network delay or sign-in."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                Section {
                    TextField(
                        viewModel.text(ar: "رقم القطعة، الاسم، القسم، أو VIN", en: "Part number, name, category, or VIN"),
                        text: $viewModel.searchText
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("catalog.search.inline")
                }
                if !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section {
                        HStack {
                            Text(viewModel.text(ar: "النتائج", en: "Results"))
                                .font(.headline)
                            Spacer()
                            Text(viewModel.filteredParts.count.formatted())
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("catalog.results.summary")
                    }
                }
                CatalogVehicleProfileSection(viewModel: viewModel)
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
                                .accessibilityIdentifier("catalog.part.\(part.partNumber)")
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
            .scrollContentBackground(.hidden)
            .background(BatalDesign.canvas)
            .listStyle(.insetGrouped)
            .toolbar { LanguageMenu(viewModel: viewModel) }
            .navigationDestination(for: Part.self) { part in PartDetailView(part: part, viewModel: viewModel) }
        }
    }
}

private struct CatalogVehicleProfileSection: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var isExpanded = false

    var body: some View {
        Section(viewModel.text(ar: "سيارتي", en: "My vehicle")) {
            Toggle(isOn: $viewModel.isVehicleFilterEnabled) {
                Label(
                    viewModel.text(ar: "فلترة النتائج حسب سيارتي", en: "Filter results by my vehicle"),
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }
            .accessibilityIdentifier("catalog.vehicle.filter.toggle")

            HStack(spacing: 10) {
                Image(systemName: "car.side.fill")
                    .foregroundStyle(BatalDesign.brand)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.vehicleFilterSummary)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Text(viewModel.text(
                        ar: "النتائج الحالية: \(viewModel.filteredParts.count.formatted()) من \(viewModel.parts.count.formatted())",
                        en: "Current results: \(viewModel.filteredParts.count.formatted()) of \(viewModel.parts.count.formatted())"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            DisclosureGroup(
                viewModel.text(ar: "تعديل بيانات السيارة", en: "Edit vehicle details"),
                isExpanded: $isExpanded
            ) {
                TextField("Y60", text: $viewModel.vehicleProfile.generation)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("catalog.vehicle.generation")
                TextField(viewModel.text(ar: "سنة الصنع", en: "Year"), text: $viewModel.vehicleProfile.year)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("catalog.vehicle.year")
                TextField(viewModel.text(ar: "المحرك", en: "Engine"), text: $viewModel.vehicleProfile.engine)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("catalog.vehicle.engine")
                TextField(viewModel.text(ar: "القير", en: "Transmission"), text: $viewModel.vehicleProfile.transmission)
                    .accessibilityIdentifier("catalog.vehicle.transmission")
            }
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
                AppHaptics.lightImpact()
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
        .background(BatalDesign.surface, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: BatalDesign.cardRadius)
                .stroke(BatalDesign.border)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
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
        .accessibilityIdentifier("catalog.part.\(part.partNumber)")
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

extension View {
    func premiumPanel() -> some View {
        self
            .background(BatalDesign.surface, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
                    .stroke(BatalDesign.border)
            )
    }
}
