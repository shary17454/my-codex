import SwiftUI

struct RequestView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var request = SavedPartRequest()
    @State private var selectedPlanID = "basic"

    var selectedPlan: PartRequestPlan {
        viewModel.plans.first { $0.id == selectedPlanID } ?? viewModel.plans[0]
    }

    private var canSaveRequest: Bool {
        partRequestHasRequiredInput(request)
    }

    private func saveRequest() {
        viewModel.saveRequestPlan(selectedPlan, request: request)
    }

    var body: some View {
        NavigationStack {
            FormContent(
                viewModel: viewModel,
                request: $request,
                selectedPlanID: $selectedPlanID,
                selectedPlan: selectedPlan,
                canSaveRequest: canSaveRequest,
                saveRequest: saveRequest
            )
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(BatalDesign.canvas)
            .navigationTitle(viewModel.text(ar: "طلب قطعة", en: "Part request"))
            .toolbar {
                LanguageMenu(viewModel: viewModel)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    AppHaptics.lightImpact()
                    saveRequest()
                } label: {
                    Label(viewModel.text(ar: "حفظ طلب القطعة", en: "Save part request"), systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.batalPrimary)
                .disabled(!canSaveRequest)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
                .accessibilityIdentifier("request.save")
            }
        }
    }
}

private struct FormContent: View {
    @Bindable var viewModel: CatalogViewModel
    @Binding var request: SavedPartRequest
    @Binding var selectedPlanID: String
    let selectedPlan: PartRequestPlan
    let canSaveRequest: Bool
    let saveRequest: () -> Void

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        viewModel.text(ar: "طلب جاهز للمورد", en: "Supplier-ready request"),
                        systemImage: "doc.text.magnifyingglass"
                    )
                    .font(.headline)
                    Text(viewModel.text(
                        ar: "اكتب الحد الأدنى من البيانات، واحفظ نصًا واضحًا يمكنك مشاركته خارج التطبيق.",
                        en: "Enter the minimum details and save a clear request you can share outside the app."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            RequestTypeSection(
                viewModel: viewModel,
                selectedPlanID: $selectedPlanID,
                selectedPlan: selectedPlan
            )
            PartDetailsSection(
                viewModel: viewModel,
                request: $request,
                canSaveRequest: canSaveRequest,
                saveRequest: saveRequest
            )
            VehicleDetailsSection(viewModel: viewModel, request: $request)
            RequestPreviewSection(
                viewModel: viewModel,
                request: $request,
                selectedPlan: selectedPlan
            )
            SavedRequestsSection(viewModel: viewModel)
        }
    }
}

private struct RequestTypeSection: View {
    @Bindable var viewModel: CatalogViewModel
    @Binding var selectedPlanID: String
    let selectedPlan: PartRequestPlan

    var body: some View {
        Section(viewModel.text(ar: "نوع الطلب", en: "Request type")) {
            Picker(viewModel.text(ar: "الخطة", en: "Plan"), selection: $selectedPlanID) {
                ForEach(viewModel.plans) { plan in
                    Text(plan.title(viewModel.language)).tag(plan.id)
                }
            }
            Text(selectedPlan.description(viewModel.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(viewModel.text(
                ar: "طلب القطعة هنا لا يتطلب دفعًا. الشراء داخل التطبيق مخصص فقط " +
                    "لفتح الكتالوج المحمي عند توفره.",
                en: "Part requests do not require payment. In-app purchase is used only " +
                    "for protected catalog unlock when available."
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct PartDetailsSection: View {
    @Bindable var viewModel: CatalogViewModel
    @Binding var request: SavedPartRequest
    let canSaveRequest: Bool
    let saveRequest: () -> Void

    var body: some View {
        Section(viewModel.text(ar: "بيانات القطعة", en: "Part")) {
            TextField(viewModel.text(ar: "رقم القطعة", en: "Part number"), text: $request.partNumber)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .accessibilityIdentifier("request.partNumber")
            TextField(viewModel.text(ar: "اسم القطعة", en: "Part name"), text: $request.partName)
                .accessibilityIdentifier("request.partName")
            TextField(viewModel.text(ar: "ملاحظات", en: "Notes"), text: $request.notes, axis: .vertical)
                .accessibilityIdentifier("request.notes")
            Button {
                AppHaptics.lightImpact()
                saveRequest()
            } label: {
                Label(
                    viewModel.text(ar: "تجهيز الطلب وحفظه", en: "Prepare and save request"),
                    systemImage: "square.and.pencil"
                )
            }
            .disabled(!canSaveRequest)
            .accessibilityIdentifier("request.save.inline")
        }
    }
}

private struct VehicleDetailsSection: View {
    @Bindable var viewModel: CatalogViewModel
    @Binding var request: SavedPartRequest

    var body: some View {
        Section(viewModel.text(ar: "بيانات السيارة", en: "Vehicle")) {
            TextField("Y60", text: $request.generation)
                .accessibilityIdentifier("request.generation")
            TextField(viewModel.text(ar: "سنة الصنع", en: "Year"), text: $request.year)
                .keyboardType(.numberPad)
                .accessibilityIdentifier("request.year")
            TextField("VIN", text: $request.vin)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .accessibilityIdentifier("request.vin")
            TextField(viewModel.text(ar: "المحرك", en: "Engine"), text: $request.engine)
                .accessibilityIdentifier("request.engine")
            TextField(viewModel.text(ar: "القير", en: "Transmission"), text: $request.transmission)
                .accessibilityIdentifier("request.transmission")
        }
    }
}

private struct RequestPreviewSection: View {
    @Bindable var viewModel: CatalogViewModel
    @Binding var request: SavedPartRequest
    let selectedPlan: PartRequestPlan

    private var missing: [PartRequestRequirement] {
        partRequestMissingRequirements(request)
    }

    var body: some View {
        Section(viewModel.text(ar: "معاينة الطلب", en: "Request preview")) {
            if missing.isEmpty {
                Text(viewModel.buildDraft(for: request, plan: selectedPlan))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("request.preview")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        viewModel.text(ar: "أكمل الحقول التالية لمنع طلب غامض:", en: "Complete these to avoid an ambiguous request:"),
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    ForEach(missing) { requirement in
                        Text("• \(requirement.message(viewModel.language))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
                .accessibilityIdentifier("request.preview.missing")
            }
        }
    }
}

private struct SavedRequestsSection: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        Section(viewModel.text(ar: "طلبات محفوظة", en: "Saved requests")) {
            if viewModel.savedRequests.isEmpty {
                EmptyStateView(
                    symbol: "tray",
                    title: viewModel.text(ar: "لا توجد طلبات محفوظة", en: "No saved requests"),
                    message: viewModel.text(
                        ar: "بعد تجهيز الطلب سيظهر هنا نص الطلب المحفوظ.",
                        en: "Prepared part requests will appear here."
                    )
                )
            } else {
                ForEach(viewModel.savedRequests) { saved in
                    SavedRequestRow(saved: saved, viewModel: viewModel)
                }
                .onDelete(perform: viewModel.deleteSavedRequests)
            }
        }
    }
}

private struct SavedRequestRow: View {
    let saved: SavedPartRequest
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(saved.partNumber.isEmpty ? saved.partName : saved.partNumber)
                        .font(.headline)
                    // Saved requests accumulate up to 50 entries; without the recorded
                    // date the user cannot tell an old quote request from today's.
                    Text(saved.createdAt.formatted(.dateTime.year().month().day()
                        .locale(viewModel.language.locale)))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ShareLink(item: saved.draft) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(viewModel.text(
                    ar: "مشاركة طلب القطعة",
                    en: "Share part request"
                ))
            }
            Text(saved.draft)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(4)
        }
    }
}

struct MaintenanceView: View {
    @Bindable var viewModel: CatalogViewModel
    @State private var title = ""
    @State private var odometer = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            MaintenanceContent(
                viewModel: viewModel,
                title: $title,
                odometer: $odometer,
                notes: $notes
            )
            .navigationTitle(viewModel.text(ar: "الصيانة", en: "Maintenance"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
        }
    }
}

struct MaintenanceContent: View {
    @Bindable var viewModel: CatalogViewModel
    @Binding var title: String
    @Binding var odometer: String
    @Binding var notes: String

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        viewModel.text(ar: "سجل محلي للسيارة", en: "Local vehicle log"),
                        systemImage: "wrench.and.screwdriver"
                    )
                    .font(.headline)
                    Text(viewModel.text(
                        ar: "احفظ بيانات السيارة وأعمال الصيانة على الجهاز لتسهيل الطلبات القادمة.",
                        en: "Keep vehicle details and service entries on device for faster future requests."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            Section(viewModel.text(ar: "ملف السيارة", en: "Vehicle profile")) {
                TextField("Y60", text: $viewModel.vehicleProfile.generation)
                TextField(viewModel.text(ar: "السنة", en: "Year"), text: $viewModel.vehicleProfile.year)
                    .keyboardType(.numberPad)
                TextField("VIN", text: $viewModel.vehicleProfile.vin)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                TextField(viewModel.text(ar: "المحرك", en: "Engine"), text: $viewModel.vehicleProfile.engine)
                TextField(
                    viewModel.text(ar: "القير", en: "Transmission"),
                    text: $viewModel.vehicleProfile.transmission
                )
            }
            Section(viewModel.text(ar: "إضافة صيانة", en: "Add maintenance")) {
                TextField(viewModel.text(ar: "العنوان", en: "Title"), text: $title)
                TextField(viewModel.text(ar: "العداد", en: "Odometer"), text: $odometer)
                    .keyboardType(.numberPad)
                TextField(viewModel.text(ar: "ملاحظات", en: "Notes"), text: $notes, axis: .vertical)
                Button(viewModel.text(ar: "حفظ", en: "Save")) {
                    AppHaptics.lightImpact()
                    viewModel.addMaintenance(title: title, odometer: odometer, notes: notes)
                    title = ""; odometer = ""; notes = ""
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section(viewModel.text(ar: "السجل", en: "Log")) {
                if viewModel.maintenanceItems.isEmpty {
                    EmptyStateView(
                        symbol: "wrench.adjustable",
                        title: viewModel.text(ar: "لا توجد صيانة محفوظة", en: "No maintenance yet"),
                        message: viewModel.text(
                            ar: "أضف أول عملية صيانة لحفظ سجل السيارة محليًا.",
                            en: "Add the first service entry to keep a local vehicle log."
                        )
                    )
                } else {
                    ForEach(viewModel.maintenanceItems) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(.headline)
                            // `MaintenanceItem.date` was recorded and persisted from the
                            // start but never displayed, so a service log could not answer
                            // the one question it exists for: when was this done.
                            Text(item.date.formatted(.dateTime.year().month().day()
                                .locale(viewModel.language.locale)))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(BatalDesign.brand)
                            Text([item.odometer, item.notes].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: viewModel.deleteMaintenance)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BatalDesign.canvas)
        .navigationTitle(viewModel.text(ar: "الصيانة", en: "Maintenance"))
    }
}
