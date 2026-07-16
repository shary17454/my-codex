import MapKit
import SwiftUI

struct OfflineMapsView: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = OfflineMapStore()
    @State private var savingPresetID: UUID?
    @State private var errorMessage: String?
    @State private var searchText = ""

    let region: MKCoordinateRegion

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task { await save(title: "موقعي الحالي", region: region, presetID: nil) }
                    } label: {
                        Label("حفظ الخريطة الحالية", systemImage: "location.viewfinder")
                    }
                    .disabled(savingPresetID != nil)

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("يتم حفظ صورة خرائط Apple محليًا لاستخدامها كمرجع سريع عند ضعف الاتصال. لا يتم تنزيل بيانات ملاحة كاملة من Apple.")
                }

                Section("اختر منطقة للتحميل") {
                    TextField("ابحث عن منطقة مثل: طويق، العلا، الربع الخالي", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    ForEach(filteredPresets) { preset in
                        Button {
                            Task { await save(title: preset.title, region: preset.region, presetID: preset.id) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "map.fill")
                                    .foregroundStyle(Color.desertCopper)
                                    .frame(width: 32, height: 32)
                                    .background(Color.desertCopper.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.title)
                                        .font(.headline)
                                    Text(preset.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.4f, %.4f", preset.region.center.latitude, preset.region.center.longitude))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if savingPresetID == preset.id {
                                    ProgressView()
                                } else {
                                    Image(systemName: "icloud.and.arrow.down")
                                        .foregroundStyle(Color.oasisTeal)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(savingPresetID != nil)
                    }
                }

                Section(store.maps.isEmpty ? "لا توجد خرائط محفوظة" : "الخرائط المحفوظة") {
                    ForEach(store.maps) { map in
                        SavedOfflineMapRow(map: map)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.delete(store.maps[index])
                        }
                    }
                }
            }
            .navigationTitle(appState.text(.offline))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(appState.text(.done)) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var filteredPresets: [OfflineMapPreset] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return OfflineMapPreset.samples }
        return OfflineMapPreset.samples.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    private func save(title: String, region: MKCoordinateRegion, presetID: UUID?) async {
        savingPresetID = presetID ?? UUID()
        errorMessage = nil
        do {
            try await store.saveSnapshot(title: title, region: region)
            appState.statusMessage = "تم حفظ خريطة \(title)"
        } catch {
            errorMessage = "تعذر حفظ الخريطة: \(error.localizedDescription)"
        }
        savingPresetID = nil
    }
}

private struct SavedOfflineMapRow: View {
    let map: OfflineMap

    var body: some View {
        HStack(spacing: 12) {
            if let image = UIImage(contentsOfFile: map.fileURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "map")
                    .frame(width: 72, height: 72)
                    .background(Color.desertSand.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(map.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(map.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.4f, %.4f", map.centerLatitude, map.centerLongitude))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
