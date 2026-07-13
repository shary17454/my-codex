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

    var body: some View {
        NavigationStack {
            Form {
                Section(appState.text(.hiddenPlace)) {
                    TextField(appState.text(.placeName), text: $name)
                    Stepper("\(appState.text(.rating)): \(rating)", value: $rating, in: 1...5)
                    TextField(appState.text(.safetyNotes), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle(appState.text(.useCurrentLocation), isOn: $includeCurrentLocation)
                }

                Section(appState.text(.review)) {
                    Label(appState.text(.reviewMessage), systemImage: "checkmark.seal")
                        .foregroundStyle(.secondary)
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
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
        appState.hiddenPlaces.append(place)
        try? await cloudStore.saveHiddenPlaceForReview(place)
        isSaving = false
        dismiss()
    }
}
