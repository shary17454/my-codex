import CoreLocation
import MapKit
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
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var mapSearchResults: [PlaceSearchResult] = []
    @State private var isSearching = false
    @State private var searchMessage: String?

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
                    HStack {
                        TextField("ابحث باسم وادي، جبل، روضة، أو إحداثية", text: $query)
                            .submitLabel(.search)
                            .onSubmit { Task { await searchMap() } }
                        Button {
                            Task { await searchMap() }
                        } label: {
                            if isSearching {
                                ProgressView()
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                        }
                        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
                        .accessibilityLabel("بحث في خرائط Apple")
                    }

                    if let parsedCoordinate {
                        Button {
                            selectCoordinate(parsedCoordinate, title: "إحداثية مخصصة")
                        } label: {
                            Label(
                                String(format: "استخدام %.5f, %.5f", parsedCoordinate.latitude, parsedCoordinate.longitude),
                                systemImage: "scope"
                            )
                        }
                    }

                    if let searchMessage {
                        Text(searchMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(mapSearchResults) { result in
                        Button {
                            selectCoordinate(result.coordinate, title: result.name)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(result.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(result.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(suggestions.prefix(8)) { place in
                        Button {
                            name = place.name
                            notes = place.notes
                            rating = place.rating
                            includeCurrentLocation = false
                            selectedCoordinate = place.coordinate
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

                    Button {
                        save()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(appState.text(.submit))
                                .font(.headline.weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSubmit)
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
                        save()
                    }
                    .disabled(!canSubmit)
                }
            }
            .onAppear {
                if selectedCoordinate == nil {
                    selectedCoordinate = appState.selectedTrip.meetingPoint
                }
                if includeCurrentLocation {
                    appState.locationManager.startNavigation()
                }
            }
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && resolvedCoordinate != nil && !isSaving
    }

    private var coordinatePreview: String {
        guard let coordinate = resolvedCoordinate else {
            return "بانتظار إحداثية صالحة"
        }
        return String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    private var resolvedCoordinate: CLLocationCoordinate2D? {
        if includeCurrentLocation {
            return appState.locationManager.currentLocation?.coordinate ?? selectedCoordinate
        }
        return selectedCoordinate
    }

    private var parsedCoordinate: CLLocationCoordinate2D? {
        let normalized = query.replacingOccurrences(of: "،", with: ",")
        let parts = normalized.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 2,
              let latitude = Double(parts[0]),
              let longitude = Double(parts[1]),
              (-90...90).contains(latitude),
              (-180...180).contains(longitude) else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func selectCoordinate(_ coordinate: CLLocationCoordinate2D, title: String) {
        selectedCoordinate = coordinate
        includeCurrentLocation = false
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = title
        }
        searchMessage = "تم اختيار الموقع"
    }

    private func searchMap() async {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return }
        isSearching = true
        searchMessage = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = cleanQuery
        request.region = MKCoordinateRegion(
            center: appState.locationManager.currentLocation?.coordinate ?? appState.selectedTrip.meetingPoint,
            span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8)
        )
        do {
            let response = try await MKLocalSearch(request: request).start()
            let appleResults = response.mapItems.prefix(12).map { item in
                PlaceSearchResult(
                    name: item.name ?? cleanQuery,
                    subtitle: item.placemark.title ?? "نتيجة من خرائط Apple",
                    coordinate: item.placemark.coordinate
                )
            }
            let localResults = HiddenPlace.samples
                .filter {
                    $0.name.localizedCaseInsensitiveContains(cleanQuery) ||
                    $0.notes.localizedCaseInsensitiveContains(cleanQuery)
                }
                .map {
                    PlaceSearchResult(
                        name: $0.name,
                        subtitle: "موقع محفوظ داخل الدروب",
                        coordinate: $0.coordinate
                    )
                }
            let dirtRoadResults = dirtRoadSearchResults(for: cleanQuery)
            mapSearchResults = deduplicated(appleResults + localResults + dirtRoadResults)
            searchMessage = mapSearchResults.isEmpty ? "لم يتم العثور على نتائج" : "نتائج خرائط Apple والمواقع المحفوظة"
        } catch {
            mapSearchResults = HiddenPlace.samples
                .filter {
                    $0.name.localizedCaseInsensitiveContains(cleanQuery) ||
                    $0.notes.localizedCaseInsensitiveContains(cleanQuery)
                }
                .map {
                    PlaceSearchResult(
                        name: $0.name,
                        subtitle: "نتيجة محلية عند تعذر الاتصال",
                        coordinate: $0.coordinate
                    )
                }
                + dirtRoadSearchResults(for: cleanQuery)
            searchMessage = mapSearchResults.isEmpty ? "تعذر البحث الآن. يمكنك إدخال الإحداثية مباشرة." : "تم عرض نتائج محلية عند تعذر الاتصال"
        }
    }

    private func dirtRoadSearchResults(for query: String) -> [PlaceSearchResult] {
        DirtRoadRoute.samples
            .filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.summary.localizedCaseInsensitiveContains(query) ||
                $0.condition.localizedCaseInsensitiveContains(query) ||
                $0.surface.rawValue.localizedCaseInsensitiveContains(query) ||
                $0.difficulty.rawValue.localizedCaseInsensitiveContains(query)
            }
            .map {
                PlaceSearchResult(
                    name: $0.name,
                    subtitle: "طريق بري: \($0.subtitle)",
                    coordinate: $0.endCoordinate
                )
            }
    }

    private func save() {
        guard let coordinate = resolvedCoordinate else {
            searchMessage = "يلزم تحديد موقع صحيح قبل الإرسال"
            return
        }
        isSaving = true
        let cloudStore = appState.cloudStore
        let place = HiddenPlace(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            coordinate: coordinate,
            rating: rating,
            imageSystemName: "camera.macro",
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            status: .pending,
            contributor: "أنت",
            points: 10
        )
        appState.addHiddenPlace(place)
        isSaving = false
        dismiss()
        Task {
            try? await cloudStore.saveHiddenPlaceForReview(place)
        }
    }

    private func deduplicated(_ results: [PlaceSearchResult]) -> [PlaceSearchResult] {
        var seen = Set<String>()
        return results.filter { result in
            let key = "\(result.name.lowercased())|\(Int(result.coordinate.latitude * 10_000))|\(Int(result.coordinate.longitude * 10_000))"
            return seen.insert(key).inserted
        }
    }
}

private struct PlaceSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
}
