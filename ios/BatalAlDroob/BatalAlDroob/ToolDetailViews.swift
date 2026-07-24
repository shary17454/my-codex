import PhotosUI
import SwiftUI

struct DescriptionSearchToolView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var descriptionQuery = ""
    @State private var hasSearched = false

    var body: some View {
        let choosePhotoTitle = viewModel.text(ar: "اختيار صورة كمرجع", en: "Choose reference photo")

        Form {
            Section(viewModel.text(ar: "بحث بالوصف", en: "Description search")) {
                TextField(
                    viewModel.text(
                        ar: "اكتب رقم القطعة أو وصف العطل",
                        en: "Enter a part number or fault description"
                    ),
                    text: $descriptionQuery,
                    axis: .vertical
                )
                .lineLimit(2 ... 4)
                Button {
                    hasSearched = true
                    viewModel.applyDescriptionSearch(descriptionQuery)
                } label: {
                    Label(
                        viewModel.text(ar: "بحث", en: "Search"),
                        systemImage: "text.magnifyingglass"
                    )
                }
                PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                    Label(choosePhotoTitle, systemImage: "photo")
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
            Section(viewModel.text(ar: "النتائج", en: "Results")) {
                if !hasSearched {
                    EmptyStateView(
                        symbol: "text.magnifyingglass",
                        title: viewModel.text(ar: "ابدأ البحث", en: "Start searching"),
                        message: viewModel.text(
                            ar: "اكتب رقم قطعة أو وصفًا مختصرًا ثم اضغط بحث.",
                            en: "Enter a part number or short description, then tap Search."
                        )
                    )
                } else if viewModel.filteredParts.isEmpty {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: viewModel.text(ar: "لا توجد نتائج", en: "No results"),
                        message: viewModel.text(
                            ar: "جرّب رقم قطعة مباشر أو وصفًا أوضح.",
                            en: "Try a direct part number or a clearer description."
                        )
                    )
                } else {
                    ForEach(viewModel.filteredParts.prefix(20)) { part in
                        NavigationLink(value: part) {
                            PartRow(part: part, viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.text(ar: "بحث ذكي", en: "Smart search"))
    }
}

struct TireCalculatorToolView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var oldTireSize = "265/70R16"
    @State private var newTireSize = "285/75R16"
    @State private var tireResult = ""

    var body: some View {
        Form {
            Section(viewModel.text(ar: "حاسبة الكفرات", en: "Tire calculator")) {
                TextField(viewModel.text(ar: "المقاس القديم", en: "Old size"), text: $oldTireSize)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                TextField(viewModel.text(ar: "المقاس الجديد", en: "New size"), text: $newTireSize)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
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
        }
        .navigationTitle(viewModel.text(ar: "حاسبة الكفرات", en: "Tire calculator"))
    }
}

struct FitmentCheckToolView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var query = "21082-4W000"
    @State private var summary = ""
    @State private var matches: [Part] = []
    @State private var didCheck = false

    var body: some View {
        Form {
            Section(viewModel.text(ar: "تحقق التوافق", en: "Fitment check")) {
                TextField(
                    viewModel.text(ar: "رقم القطعة أو وصف مختصر", en: "Part number or short description"),
                    text: $query
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                Button {
                    didCheck = true
                    summary = viewModel.fitmentSummary(for: query)
                    matches = viewModel.fitmentMatches(for: query)
                } label: {
                    Label(viewModel.text(ar: "تحقق", en: "Check"), systemImage: "checkmark.seal")
                }
            }
            if !summary.isEmpty {
                Section(viewModel.text(ar: "الملخص", en: "Summary")) {
                    Text(summary)
                        .font(.callout.monospacedDigit())
                        .textSelection(.enabled)
                }
            }
            Section(viewModel.text(ar: "أفضل المطابقات", en: "Best matches")) {
                if !didCheck {
                    EmptyStateView(
                        symbol: "checkmark.seal",
                        title: viewModel.text(ar: "لم يبدأ التحقق", en: "No check yet"),
                        message: viewModel.text(
                            ar: "أدخل رقم قطعة ثم اضغط تحقق لعرض المطابقات.",
                            en: "Enter a part number and tap Check to see matches."
                        )
                    )
                } else if matches.isEmpty {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: viewModel.text(ar: "لا توجد مطابقة مباشرة", en: "No direct match"),
                        message: viewModel.text(
                            ar: "راجع الملخص أو جرّب رقمًا أقرب للقطعة المطلوبة.",
                            en: "Review the summary or try a closer part number."
                        )
                    )
                } else {
                    ForEach(matches) { part in
                        NavigationLink(value: part) {
                            PartRow(part: part, viewModel: viewModel)
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.text(ar: "تحقق التوافق", en: "Fitment check"))
    }
}

struct MaintenanceToolView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: CatalogViewModel
    var returnToTools: (() -> Void)?
    @State private var title = ""
    @State private var odometer = ""
    @State private var notes = ""

    var body: some View {
        MaintenanceContent(viewModel: viewModel, title: $title, odometer: $odometer, notes: $notes)
            .navigationTitle(viewModel.text(ar: "الصيانة", en: "Maintenance"))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let returnToTools {
                            returnToTools()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Label(viewModel.text(ar: "الأدوات", en: "Tools"), systemImage: "chevron.backward")
                    }
                    .accessibilityIdentifier("tools.back")
                }
            }
    }
}
