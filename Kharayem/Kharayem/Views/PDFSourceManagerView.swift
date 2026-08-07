import SwiftUI

struct PDFSourceManagerView: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: PDFMapStore
    let document: PDFMapDocument

    @State private var showingFileImporter = false
    @State private var remoteURLText = ""
    @State private var isDownloading = false
    @State private var errorMessage: String?
    @State private var boundsNorth = ""
    @State private var boundsSouth = ""
    @State private var boundsEast = ""
    @State private var boundsWest = ""
    @State private var boundsMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(appState.text(.sourceURL)) {
                    Text(store.sourceMetadata[document]?.source ?? appState.text(.sourceUnknown))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let importedAt = store.sourceMetadata[document]?.importedAt {
                        Text(importedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(appState.text(.downloadOfficialPDF)) {
                    TextField("https://example.com/map.pdf", text: $remoteURLText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button {
                        Task { await downloadPDF() }
                    } label: {
                        Label(isDownloading ? "..." : appState.text(.download), systemImage: "arrow.down.doc")
                    }
                    .disabled(isDownloading || URL(string: remoteURLText) == nil)
                }

                Section {
                    Text("حدود الخريطة الجغرافية لعرضها كطبقة فوق القمر الصناعي. القيم الأولية تقريبية — عدّلها حتى تنطبق المعالم (مثل السواحل والمدن) على صور القمر.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    calibrationField("شمال (خط عرض)", value: $boundsNorth)
                    calibrationField("جنوب (خط عرض)", value: $boundsSouth)
                    calibrationField("شرق (خط طول)", value: $boundsEast)
                    calibrationField("غرب (خط طول)", value: $boundsWest)
                    Button {
                        saveBounds()
                    } label: {
                        Label("حفظ المعايرة", systemImage: "scope")
                    }
                    if let boundsMessage {
                        Text(boundsMessage)
                            .font(.caption)
                            .foregroundStyle(boundsMessage.contains("تم") ? Color.green : Color.red)
                    }
                } header: {
                    Text("معايرة الطبقة (تقريبية)")
                }

                Section {
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label(appState.text(.importOfficialPDF), systemImage: "folder")
                    }

                    if store.isImported(document) {
                        Button(role: .destructive) {
                            store.removeImportedPDF(for: document)
                        } label: {
                            Label(appState.text(.restoreBundledPDF), systemImage: "arrow.uturn.backward")
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(appState.text(.managePDFSource))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(appState.text(.done)) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFileImporter) {
                PDFImportPicker { url in
                    do {
                        try store.importOfficialPDF(from: url, replacing: document)
                        showingFileImporter = false
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .onAppear(perform: loadBounds)
        }
    }

    private func calibrationField(_ title: String, value: Binding<String>) -> some View {
        HStack {
            Text(title)
                .font(.caption)
            Spacer()
            TextField("0.0", text: value)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
                .font(.body.monospacedDigit())
        }
    }

    private func loadBounds() {
        let bounds = GeoImageBounds.stored(for: document)
        boundsNorth = String(format: "%.4f", bounds.north)
        boundsSouth = String(format: "%.4f", bounds.south)
        boundsEast = String(format: "%.4f", bounds.east)
        boundsWest = String(format: "%.4f", bounds.west)
    }

    private func saveBounds() {
        guard let n = Double(boundsNorth), let s = Double(boundsSouth),
              let e = Double(boundsEast), let w = Double(boundsWest) else {
            boundsMessage = "أدخل أرقامًا عشرية صحيحة (مثال: 24.7136)"
            return
        }
        let bounds = GeoImageBounds(north: n, south: s, east: e, west: w)
        guard bounds.isValid else {
            boundsMessage = "الحدود غير منطقية: الشمال يجب أن يزيد عن الجنوب والشرق عن الغرب"
            return
        }
        bounds.save(for: document)
        boundsMessage = "تم حفظ المعايرة — أعد فتح طبقة العجاجي لتطبيقها"
    }

    private func downloadPDF() async {
        guard let url = URL(string: remoteURLText) else { return }
        isDownloading = true
        errorMessage = nil
        do {
            try await store.downloadOfficialPDF(from: url, replacing: document)
            remoteURLText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isDownloading = false
    }
}
