import SwiftUI

struct RequestView: View {
    private enum Field: Hashable {
        case generation, year, vin, engine, transmission, partNumber, partName, notes
    }

    @Bindable var viewModel: CatalogViewModel
    @State private var request = SavedPartRequest()
    @State private var selectedPlanID = "basic"
    @FocusState private var focusedField: Field?

    var selectedPlan: PartRequestPlan {
        viewModel.plans.first { $0.id == selectedPlanID } ?? viewModel.plans[0]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.text(ar: "نوع الطلب", en: "Request type")) {
                    Picker(viewModel.text(ar: "الخطة", en: "Plan"), selection: $selectedPlanID) {
                        ForEach(viewModel.plans) { plan in Text(plan.title(viewModel.language)).tag(plan.id) }
                    }
                    Text(selectedPlan.description(viewModel.language)).font(.caption).foregroundStyle(.secondary)
                    Text(viewModel.text(
                        ar: "طلب القطعة هنا لا يتطلب دفعًا. الشراء داخل التطبيق مخصص فقط " +
                            "لفتح الكتالوج المحمي عند توفره.",
                        en: "Part requests do not require payment. In-app purchase is used only " +
                            "for protected catalog unlock when available."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Section(viewModel.text(ar: "بيانات السيارة", en: "Vehicle")) {
                    TextField("Y60", text: $request.generation)
                        .focused($focusedField, equals: .generation)
                    TextField(viewModel.text(ar: "سنة الصنع", en: "Year"), text: $request.year)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .year)
                    TextField("VIN", text: $request.vin)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .vin)
                    TextField(viewModel.text(ar: "المحرك", en: "Engine"), text: $request.engine)
                        .focused($focusedField, equals: .engine)
                    TextField(viewModel.text(ar: "القير", en: "Transmission"), text: $request.transmission)
                        .focused($focusedField, equals: .transmission)
                }
                Section(viewModel.text(ar: "بيانات القطعة", en: "Part")) {
                    TextField(viewModel.text(ar: "رقم القطعة", en: "Part number"), text: $request.partNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .partNumber)
                    TextField(viewModel.text(ar: "اسم القطعة", en: "Part name"), text: $request.partName)
                        .focused($focusedField, equals: .partName)
                    TextField(viewModel.text(ar: "ملاحظات", en: "Notes"), text: $request.notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                    Button {
                        focusedField = nil
                        viewModel.saveRequestPlan(selectedPlan, request: request)
                    } label: {
                        Label(
                            viewModel.text(ar: "تجهيز الطلب وحفظه", en: "Prepare and save request"),
                            systemImage: "square.and.pencil"
                        )
                    }
                    .disabled(!partRequestHasRequiredInput(request))
                }
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
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(saved.partNumber.isEmpty ? saved.partName : saved.partNumber).font(.headline)
                                    Spacer()
                                    ShareLink(item: saved.draft) {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                    .accessibilityLabel(viewModel.text(
                                        ar: "مشاركة طلب القطعة",
                                        en: "Share part request"
                                    ))
                                }
                                Text(saved.draft).font(.caption).foregroundStyle(.secondary).lineLimit(4)
                            }
                        }
                        .onDelete(perform: viewModel.deleteSavedRequests)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.text(ar: "طلب قطعة", en: "Part request"))
            .toolbar { LanguageMenu(viewModel: viewModel) }
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
                        VStack(alignment: .leading) {
                            Text(item.title).font(.headline)
                            Text([item.odometer, item.notes].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: viewModel.deleteMaintenance)
                }
            }
        }
    }
}
