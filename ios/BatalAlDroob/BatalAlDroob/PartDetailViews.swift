import SwiftUI

struct PartDetailView: View {
    let part: Part
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: part.categoryValue.symbol)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(BatalDesign.brand)
                            .frame(width: 48, height: 48)
                            .background(BatalDesign.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(viewModel.title(for: part))
                                .font(.title2.bold())
                                .fixedSize(horizontal: false, vertical: true)
                            Text(viewModel.protectedNumber(part))
                                .font(.title3.monospaced())
                                .foregroundStyle(BatalDesign.brand)
                                .textSelection(.enabled)
                        }
                    }
                    if !viewModel.isUnlocked(part) {
                        Text(viewModel.purchaseSetupMessage)
                            .font(.caption)
                            .foregroundStyle(viewModel.availableProductIDs.isEmpty ? .orange : .secondary)
                        CatalogAccessOfferView(part: part, viewModel: viewModel)
                        Button {
                            AppHaptics.lightImpact()
                            Task { await viewModel.restorePurchases() }
                        } label: {
                            Label(
                                viewModel.text(ar: "استعادة المشتريات", en: "Restore Purchases"),
                                systemImage: "arrow.clockwise"
                            )
                        }
                        .buttonStyle(.batalSecondary)
                        Button {
                            AppHaptics.lightImpact()
                            Task { await viewModel.redeemOfferCode() }
                        } label: {
                            Label(
                                viewModel.text(ar: "استرداد كود العرض أو المالك", en: "Redeem offer or owner code"),
                                systemImage: "ticket"
                            )
                        }
                        .buttonStyle(.batalSecondary)
                        .accessibilityIdentifier("purchase.redeemOfferCode")
                    }
                }
                .padding(.vertical, 4)
            }
            Section(viewModel.text(ar: "معلومات", en: "Information")) {
                LabeledContent(viewModel.text(ar: "الموديل", en: "Model"), value: part.model ?? "Y60")
                LabeledContent(
                    viewModel.text(ar: "القسم", en: "Category"),
                    value: part.categoryAr ?? part.categoryValue.title(viewModel.language)
                )
                YearListDetailRow(
                    title: viewModel.text(ar: "السنوات", en: "Years"),
                    years: orderedModelYears(for: part.model, years: part.years)
                )
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
                if viewModel.isUnlocked(part) {
                    NativeDiagramView(part: part, displayNumber: viewModel.protectedNumber(part))
                        .frame(height: 220)
                        .accessibilityLabel(viewModel.text(
                            ar: "مؤشر توضيحي يعرض رقم القطعة وليس رسماً رسمياً من الكتالوج",
                            en: "Illustrative locator showing the part number, not an official catalog diagram"
                        ))
                } else {
                    LockedPartImagePlaceholder(viewModel: viewModel)
                        .frame(height: 220)
                }
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
                        Button {
                            AppHaptics.lightImpact()
                            viewModel.openStore(store, part: part)
                        } label: {
                            Label(store.name(language: viewModel.language), systemImage: "safari")
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.protectedNumber(part))
        .scrollContentBackground(.hidden)
        .background(BatalDesign.canvas)
        .listStyle(.insetGrouped)
        .toolbar {
            Button {
                AppHaptics.lightImpact()
                viewModel.toggleWishlist(part)
            } label: {
                Image(systemName: viewModel.wishlist.contains(part.partNumber) ? "heart.fill" : "heart")
            }
            .accessibilityLabel(viewModel.text(
                ar: viewModel.wishlist.contains(part.partNumber) ? "إزالة من قائمة الرغبات" : "إضافة إلى قائمة الرغبات",
                en: viewModel.wishlist.contains(part.partNumber) ? "Remove from wishlist" : "Add to wishlist"
            ))
        }
    }
}

private struct YearListDetailRow: View {
    let title: String
    let years: [String]

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
            if years.isEmpty {
                Text("-")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 8)], alignment: .trailing, spacing: 8) {
                    ForEach(years, id: \.self) { year in
                        Text(year)
                            .font(.callout.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(BatalDesign.brand.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(BatalDesign.brand.opacity(0.25), lineWidth: 1))
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(title): \(years.joined(separator: ", "))")
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LockedPartImagePlaceholder: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.lock")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(BatalDesign.accent)
            Text(viewModel.text(ar: "صورة القطعة والرقم الكامل مقفلة", en: "Part image and full number are locked"))
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(viewModel.text(
                ar: "افتح صفحة الكتالوج هذه بـ 4 ر.س لعرض الرقم الكامل ومؤشر صورة القطعة.",
                en: "Unlock this catalog page for SAR 4 to show the full number and part image locator."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
    }
}

private struct CatalogAccessOfferView: View {
    let part: Part
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        VStack(spacing: 8) {
            accessButton(level: .singleUnlock, style: .secondary)
            accessButton(level: .fullCatalog, style: .primary)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func accessButton(level: CatalogAccessLevel, style: AccessButtonStyle) -> some View {
        if style == .primary {
            accessButtonContent(level: level)
                .buttonStyle(.batalPrimary)
        } else {
            accessButtonContent(level: level)
                .buttonStyle(.batalSecondary)
        }
    }

    private func accessButtonContent(level: CatalogAccessLevel) -> some View {
        Button {
            AppHaptics.lightImpact()
            Task { await viewModel.unlock(part, level: level) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: level == .singleUnlock ? "doc.viewfinder" : "shippingbox.and.arrow.backward.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title(viewModel.language))
                        .font(.subheadline.weight(.semibold))
                    Text(level.description(viewModel.language))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Text(level.priceText(viewModel.language))
                    .font(.subheadline.monospacedDigit().bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .disabled(viewModel.isPurchaseActionDisabled(for: level))
    }

    private enum AccessButtonStyle {
        case primary, secondary
    }
}

struct NativeDiagramView: View {
    let part: Part
    let displayNumber: String

    var body: some View {
        Canvas { context, size in
            let box = CGRect(x: 30, y: 42, width: size.width - 60, height: 104)
            context.stroke(Path(roundedRect: box, cornerRadius: 14), with: .color(.secondary), lineWidth: 2)
            let callout = CGRect(x: size.width * 0.52, y: 82, width: 82, height: 42)
            context.fill(Path(roundedRect: callout, cornerRadius: 10), with: .color(.red.opacity(0.22)))
            context.stroke(Path(roundedRect: callout, cornerRadius: 10), with: .color(.red), lineWidth: 3)
            let text = Text(displayNumber).font(.caption.monospaced().bold()).foregroundStyle(.primary)
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
            Section {
                Label(
                    viewModel.text(ar: "قطع تعمل على أكثر من إعداد موثق", en: "Parts with more than one verified fitment"),
                    systemImage: "point.3.connected.trianglepath.dotted"
                )
                .font(.headline)
            }
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
        .scrollContentBackground(.hidden)
        .background(BatalDesign.canvas)
        .listStyle(.insetGrouped)
        .navigationDestination(for: Part.self) { PartDetailView(part: $0, viewModel: viewModel) }
    }
}
