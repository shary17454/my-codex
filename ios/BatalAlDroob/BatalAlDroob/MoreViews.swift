import SwiftUI

struct MoreView: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ToolsHeroView(viewModel: viewModel)
                }
                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "مركز العمل", en: "Action center"),
                        subtitle: viewModel.text(
                            ar: "كل أداة لها شاشة مستقلة ومسار واضح.",
                            en: "Each tool has a focused screen and a clear path."
                        )
                    )
                    ToolsActionGrid(viewModel: viewModel)
                }
                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "قائمة الرغبات", en: "Wishlist"),
                        subtitle: viewModel.text(
                            ar: "القطع التي حفظتها من شاشة التفاصيل.",
                            en: "Parts saved from detail screens."
                        )
                    )
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
                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "المتاجر الموثقة", en: "Verified stores"),
                        subtitle: viewModel.text(
                            ar: "روابط خارجية آمنة فقط، ولا ننسخ أسعارًا أو مخزونًا.",
                            en: "Safe external handoff links only; prices and inventory are not copied."
                        )
                    )
                    if viewModel.stores.isEmpty {
                        EmptyStateView(
                            symbol: "storefront",
                            title: viewModel.text(ar: "لا توجد متاجر محملة", en: "No stores loaded"),
                            message: viewModel.text(
                                ar: "تحقق من اتصال البيانات المضمنة ثم أعد فتح التطبيق.",
                                en: "Check the bundled data and reopen the app."
                            )
                        )
                    } else {
                        ForEach(viewModel.stores) { store in
                            Button { viewModel.openStore(store, part: nil) } label: { Label(
                                store.name(language: viewModel.language),
                                systemImage: "link"
                            ) }
                        }
                    }
                }
                Section {
                    BatalSectionHeader(
                        title: viewModel.text(ar: "إعدادات وخصوصية", en: "Settings and privacy"),
                        subtitle: viewModel.text(
                            ar: "اللغة وسياسة التعامل مع البيانات داخل التطبيق.",
                            en: "Language and app data handling policy."
                        )
                    )
                    LanguageMenu(viewModel: viewModel)
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
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(viewModel.text(ar: "الأدوات", en: "Tools"))
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
                NavigationLink {
                    DescriptionSearchToolView(viewModel: viewModel)
                } label: {
                    ToolsActionCard(
                        symbol: "text.magnifyingglass",
                        title: viewModel.text(ar: "بحث ذكي", en: "Smart search"),
                        detail: viewModel.text(ar: "وصف العطل أو رقم القطعة.", en: "Fault description or part number.")
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FitmentCheckToolView(viewModel: viewModel)
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

                NavigationLink {
                    TireCalculatorToolView(viewModel: viewModel)
                } label: {
                    ToolsActionCard(
                        symbol: "gauge.with.dots.needle.33percent",
                        title: viewModel.text(ar: "حاسبة الكفرات", en: "Tire calculator"),
                        detail: viewModel.text(ar: "قارن مقاسين بسرعة.", en: "Compare two tire sizes quickly.")
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SharedFitmentContent(viewModel: viewModel)
                        .navigationTitle(viewModel.text(ar: "القطع المشتركة", en: "Shared fitment"))
                } label: {
                    ToolsActionCard(
                        symbol: "point.3.connected.trianglepath.dotted",
                        title: viewModel.text(ar: "قطع مشتركة", en: "Shared parts"),
                        detail: viewModel.text(ar: "قطع تغطي أكثر من إعداد.", en: "Parts covering multiple setups.")
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PartRequestContent(viewModel: viewModel)
                        .navigationTitle(viewModel.text(ar: "طلب قطعة", en: "Part request"))
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

                NavigationLink {
                    MaintenanceToolView(viewModel: viewModel)
                } label: {
                    ToolsActionCard(
                        symbol: "wrench.and.screwdriver",
                        title: viewModel.text(ar: "سجل الصيانة", en: "Maintenance log"),
                        detail: viewModel.text(ar: "حفظ الأعمال والملاحظات محليًا.", en: "Save work and notes locally.")
                    )
                }
                .buttonStyle(.plain)
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
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
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
