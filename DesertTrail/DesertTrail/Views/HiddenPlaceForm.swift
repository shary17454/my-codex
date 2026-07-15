import CoreLocation
import SwiftUI

struct HiddenPlaceForm: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var notes = ""
    @State private var rating = 4
    @State private var includeCurrentLocation = true
    @State private var isSaving = false
    @State private var query = ""

    private var suggestions: [HiddenPlace] {
        let base = HiddenPlace.samples.filter { $0.status == .approved }
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(cleanQuery) ||
            $0.notes.localizedCaseInsensitiveContains(cleanQuery)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(appState.text(.hiddenPlace)) {
                    TextField(appState.text(.placeName), text: $name)
                        .textInputAutocapitalization(.words)
                    Stepper("\(appState.text(.rating)): \(rating)", value: $rating, in: 1...5)
                    TextField(appState.text(.safetyNotes), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle(appState.text(.useCurrentLocation), isOn: $includeCurrentLocation)
                        .onChange(of: includeCurrentLocation) { _, enabled in
                            if enabled {
                                appState.locationManager.startNavigation()
                            }
                        }
                    Text(coordinatePreview)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Section("اقتراحات سريعة") {
                    TextField("ابحث باسم وادي، جبل، روضة، أو إحداثية", text: $query)
                    ForEach(suggestions.prefix(8)) { place in
                        Button {
                            name = place.name
                            notes = place.notes
                            rating = place.rating
                            includeCurrentLocation = false
                            appState.setTripDestination(to: place)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: place.imageSystemName)
                                    .foregroundStyle(Color.desertCopper)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(place.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(place.notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section(appState.text(.review)) {
                    Label(appState.text(.reviewMessage), systemImage: "checkmark.seal")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .navigationTitle(appState.text(.addPlace))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.text(.cancel)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(appState.text(.submit)) {
                        Task { await save() }
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    private var coordinatePreview: String {
        let coordinate = includeCurrentLocation
            ? appState.locationManager.currentLocation?.coordinate ?? appState.selectedTrip.meetingPoint
            : appState.selectedTrip.meetingPoint
        return String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    private func save() async {
        isSaving = true
        let cloudStore = appState.cloudStore
        let coordinate = appState.locationManager.currentLocation?.coordinate ?? appState.selectedTrip.meetingPoint
        let place = HiddenPlace(
            id: UUID(),
            name: name,
            coordinate: includeCurrentLocation ? coordinate : appState.selectedTrip.meetingPoint,
            rating: rating,
            imageSystemName: "camera.macro",
            notes: notes,
            status: .pending,
            contributor: "أنت",
            points: 10
        )
        appState.addHiddenPlace(place)
        try? await cloudStore.saveHiddenPlaceForReview(place)
        isSaving = false
        dismiss()
    }
}
