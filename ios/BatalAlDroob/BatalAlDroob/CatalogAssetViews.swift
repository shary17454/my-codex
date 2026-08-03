import PDFKit
import SwiftUI

struct CatalogLibraryView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var query = ""
    @State private var generation = "ALL"

    private var documents: [CatalogDocument] {
        viewModel.catalogDocuments(search: query, generation: generation)
    }

    private var generations: [String] {
        ["ALL"] + Array(Set(viewModel.catalogDocuments.map(\.generation)))
            .filter { $0 != "UNKNOWN" }
            .sorted()
            + (viewModel.catalogDocuments.contains { $0.generation == "UNKNOWN" } ? ["UNKNOWN"] : [])
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .font(.title2)
                        .foregroundStyle(BatalDesign.brand)
                        .frame(width: 46, height: 46)
                        .background(BatalDesign.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.text(ar: "الكتالوجات الأصلية", en: "Original catalogs"))
                            .font(.headline)
                        Text(viewModel.text(
                            ar: "\(viewModel.catalogDocuments.count.formatted()) ملفًا مفهرسًا للتنزيل والقراءة.",
                            en: "\(viewModel.catalogDocuments.count.formatted()) indexed files ready to download."
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if !viewModel.isFullCatalogUnlocked() {
                Section {
                    Button {
                        AppHaptics.lightImpact()
                        Task { await viewModel.purchaseFullCatalogAccess() }
                    } label: {
                        Label(
                            viewModel.text(
                                ar: "فتح المكتبة الكاملة بـ 100 ر.س",
                                en: "Unlock the full library for SAR 100"
                            ),
                            systemImage: "lock.open.fill"
                        )
                    }
                    .buttonStyle(.batalPrimary)
                    .disabled(viewModel.isLoadingPurchases)
                    .accessibilityIdentifier("catalogLibrary.unlockFull")
                }
            }

            Section {
                Picker(viewModel.text(ar: "الجيل", en: "Generation"), selection: $generation) {
                    ForEach(generations, id: \.self) { value in
                        Text(generationTitle(value)).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("catalogLibrary.generationPicker")
            }

            Section(viewModel.text(ar: "الملفات", en: "Files")) {
                if documents.isEmpty {
                    EmptyStateView(
                        symbol: "doc.text.magnifyingglass",
                        title: viewModel.text(ar: "لا توجد ملفات مطابقة", en: "No matching files"),
                        message: viewModel.text(
                            ar: "غيّر الجيل أو عبارة البحث.",
                            en: "Change the generation or search query."
                        )
                    )
                } else {
                    ForEach(documents) { document in
                        CatalogDocumentButton(document: document, viewModel: viewModel)
                    }
                }
            }
        }
        .navigationTitle(viewModel.text(ar: "مكتبة الكتالوجات", en: "Catalog library"))
        .searchable(
            text: $query,
            prompt: viewModel.text(ar: "السنة، المحرك، الموديل أو اسم الملف", en: "Year, engine, model, or filename")
        )
        .scrollContentBackground(.hidden)
        .background(BatalDesign.canvas)
        .listStyle(.insetGrouped)
        .task {
            do {
                try await viewModel.loadCatalogDocumentsIfNeeded()
            } catch {
                viewModel.errorMessage = viewModel.text(
                    ar: "تعذر تحميل فهرس الكتالوجات الأصلية. أعد المحاولة بعد التحقق من تحديث التطبيق.",
                    en: "The original catalog index could not be loaded. Update the app and try again."
                )
            }
        }
        .sheet(item: $viewModel.catalogPDFPresentation) { presentation in
            CatalogPDFView(presentation: presentation, viewModel: viewModel)
        }
    }

    private func generationTitle(_ value: String) -> String {
        switch value {
        case "ALL": viewModel.text(ar: "الكل", en: "All")
        case "UNKNOWN": viewModel.text(ar: "عام", en: "General")
        default: value
        }
    }
}

private struct CatalogDocumentButton: View {
    let document: CatalogDocument
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        Button {
            AppHaptics.lightImpact()
            Task {
                if viewModel.isFullCatalogUnlocked() {
                    await viewModel.openCatalogDocument(document)
                } else {
                    await viewModel.purchaseFullCatalogAccess()
                }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Group {
                    if viewModel.catalogDownloadID == document.id {
                        ProgressView()
                    } else {
                        Image(systemName: viewModel.isFullCatalogUnlocked() ? "arrow.down.doc.fill" : "lock.doc.fill")
                    }
                }
                .frame(width: 34, height: 34)
                .foregroundStyle(BatalDesign.brand)
                .background(BatalDesign.brand.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 5) {
                    Text(document.title)
                        .font(.headline)
                    Text(document.fileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(metadata)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.catalogDownloadID != nil)
        .accessibilityIdentifier("catalogLibrary.document.\(document.id)")
        .accessibilityLabel("\(document.title), \(metadata)")
        .accessibilityHint(viewModel.text(
            ar: viewModel.isFullCatalogUnlocked() ? "ينزل الملف ثم يفتحه." : "يفتح شراء المكتبة الكاملة.",
            en: viewModel.isFullCatalogUnlocked() ? "Downloads and opens the file." : "Opens the full-library purchase."
        ))
    }

    private var metadata: String {
        let size = ByteCountFormatter.string(fromByteCount: document.sizeBytes, countStyle: .file)
        let pages = document.pageCount > 0
            ? viewModel.text(
                ar: "\(document.pageCount.formatted()) صفحة",
                en: "\(document.pageCount.formatted()) pages"
            )
            : nil
        return [size, pages].compactMap(\.self).joined(separator: " · ")
    }
}

struct CatalogEvidenceRow: View {
    let evidence: Evidence
    let part: Part
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        if let document = viewModel.catalogDocument(matching: evidence.sourceID) {
            Button {
                AppHaptics.lightImpact()
                Task { await viewModel.openCatalogDocument(document, page: evidence.page, for: part) }
            } label: {
                evidenceContent(downloadable: true)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.catalogDownloadID != nil)
            .accessibilityHint(viewModel.text(
                ar: "ينزل مرجع PDF الأصلي ويفتح الصفحة المرتبطة.",
                en: "Downloads the original PDF reference and opens the related page."
            ))
        } else {
            evidenceContent(downloadable: false)
        }
    }

    private func evidenceContent(downloadable: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text([evidence.sourceID, evidence.year, evidence.page.map { "p.\($0)" }, evidence.reference]
                    .compactMap(\.self).joined(separator: " · "))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                if let context = evidence.context {
                    Text(context)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            }
            Spacer(minLength: 4)
            if downloadable {
                if viewModel.catalogDownloadID != nil {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.down.doc")
                        .foregroundStyle(BatalDesign.brand)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

struct CatalogPDFView: View {
    let presentation: CatalogPDFPresentation
    @Bindable var viewModel: CatalogViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitRepresentable(url: presentation.url, page: presentation.page)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(presentation.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(viewModel.text(ar: "تم", en: "Done")) { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: presentation.url) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(viewModel.text(ar: "مشاركة الملف", en: "Share file"))
                    }
                }
        }
    }
}

private struct PDFKitRepresentable: UIViewRepresentable {
    let url: URL
    let page: Int?

    func makeUIView(context _: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.usePageViewController(false)
        view.document = PDFDocument(url: url)
        if
            let page,
            let document = view.document,
            let destination = document.page(at: max(0, min(page - 1, document.pageCount - 1)))
        {
            view.go(to: destination)
        }
        return view
    }

    func updateUIView(_: PDFView, context _: Context) {}
}
