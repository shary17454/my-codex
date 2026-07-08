import MapKit
import SwiftUI

struct OfflineMapsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = OfflineMapStore()
    @State private var isSaving = false
    @State private var errorMessage: String?

    let region: MKCoordinateRegion

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task { await saveCurrentRegion() }
                    } label: {
                        Label(isSaving ? "Saving..." : appState.text(.offline), systemImage: "icloud.and.arrow.down")
                    }
                    .disabled(isSaving)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section(store.maps.isEmpty ? "No Saved Maps" : "Saved Maps") {
                    ForEach(store.maps) { map in
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
                                Text(map.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.4f, %.4f", map.centerLatitude, map.centerLongitude))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
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

    private func saveCurrentRegion() async {
        isSaving = true
        errorMessage = nil
        do {
            try await store.saveSnapshot(title: appState.selectedTrip.title, region: region)
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
