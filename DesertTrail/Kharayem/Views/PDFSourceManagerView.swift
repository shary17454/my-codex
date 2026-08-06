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
        }
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
