import SwiftUI

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
                            Label(
                                viewModel
                                    .text(
                                        ar: "فتح الأرقام البديلة والأدلة المتقدمة",
                                        en: "Unlock alternate numbers and advanced evidence"
                                    ),
                                systemImage: "lock.open"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            !viewModel.isProductAvailable(StoreProductID.catalogPermanentUnlock)
                                || viewModel.isLoadingPurchases
                        )
                        Button { Task { await viewModel.restorePurchases() } } label: {
                            Label(
                                viewModel.text(ar: "استعادة المشتريات", en: "Restore Purchases"),
                                systemImage: "arrow.clockwise"
                            )
                        }
                    }
                }
            }
            Section(viewModel.text(ar: "معلومات", en: "Information")) {
                LabeledContent(viewModel.text(ar: "الموديل", en: "Model"), value: part.model ?? "Y60")
                LabeledContent(
                    viewModel.text(ar: "القسم", en: "Category"),
                    value: part.categoryAr ?? part.categoryValue.title(viewModel.language)
                )
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
            Section(viewModel.text(ar: "مؤشر موضع توضيحي", en: "Illustrative part locator")) {
                NativeDiagramView(part: part)
                    .frame(height: 220)
                    .accessibilityLabel(viewModel.text(
                        ar: "مؤشر توضيحي يعرض رقم القطعة وليس رسماً رسمياً من الكتالوج",
                        en: "Illustrative locator showing the part number, not an official catalog diagram"
                    ))
            }
            Section(viewModel.text(ar: "الأدلة", en: "Evidence")) {
                if part.evidence.isEmpty {
                    EmptyStateView(
                        symbol: "doc.text.magnifyingglass",
                        title: viewModel.text(ar: "لا توجد أدلة مفصلة", en: "No detailed evidence"),
                        message: viewModel.text(
                            ar: "يعرض التطبيق البيانات الأساسية المتاحة لهذه القطعة.",
                            en: "The app shows the available basic data for this part."
                        )
                    )
                } else {
                    ForEach(Array(part.evidence.prefix(8).enumerated()), id: \.offset) { _, evidence in
                        VStack(alignment: .leading, spacing: 4) {
                            Text([evidence.sourceID, evidence.year, evidence.page.map { "p.\($0)" }, evidence.reference]
                                .compactMap(\.self).joined(separator: " · "))
                                .font(.subheadline.bold())
                            if
                                let context = evidence
                                    .context { Text(context).font(.caption).foregroundStyle(.secondary).lineLimit(4) }
                        }
                    }
                }
            }
            Section(viewModel.text(ar: "متاجر موثقة", en: "Verified stores")) {
                if viewModel.stores.isEmpty {
                    EmptyStateView(
                        symbol: "storefront",
                        title: viewModel.text(ar: "لا توجد متاجر محملة", en: "No stores loaded"),
                        message: viewModel.text(
                            ar: "دليل المتاجر الموثقة غير متاح حاليًا داخل التطبيق.",
                            en: "The verified store directory is not currently available in the app."
                        )
                    )
                } else {
                    ForEach(viewModel.stores.prefix(8)) { store in
                        Button { viewModel.openStore(store, part: part) } label: {
                            Label(store.name(language: viewModel.language), systemImage: "safari")
                        }
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
            SharedFitmentContent(viewModel: viewModel)
                .navigationTitle(viewModel.text(ar: "القطع المشتركة", en: "Shared fitment"))
                .toolbar { LanguageMenu(viewModel: viewModel) }
        }
    }
}

struct SharedFitmentContent: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        List {
            if viewModel.sharedParts.isEmpty {
                EmptyStateView(
                    symbol: "point.3.connected.trianglepath.dotted",
                    title: viewModel.text(ar: "لا توجد قطع مشتركة", en: "No shared-fitment parts"),
                    message: viewModel.text(
                        ar: "ستظهر هنا القطع التي تعمل على أكثر من إعداد موثق.",
                        en: "Parts that fit more than one verified configuration will appear here."
                    )
                )
            } else {
                ForEach(viewModel.sharedParts) { part in
                    NavigationLink(value: part) { PartRow(part: part, viewModel: viewModel) }
                }
            }
        }
        .navigationDestination(for: Part.self) { PartDetailView(part: $0, viewModel: viewModel) }
    }
}
