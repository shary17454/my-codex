import CoreLocation
import SwiftUI

struct CommunityView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var query = ""
    @State private var showingAddPlace = false
    @State private var selectedPlace: HiddenPlace?

    var filteredPlaces: [HiddenPlace] {
        if query.isEmpty { return appState.hiddenPlaces }
        return appState.hiddenPlaces.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.notes.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField(appState.text(.searchPlaceholder), text: $query)
                }
            }

            Section(appState.text(.communityPoints)) {
                ForEach(filteredPlaces.sorted(by: { $0.points > $1.points })) { place in
                    Button {
                        selectedPlace = place
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: place.imageSystemName)
                                .frame(width: 42, height: 42)
                                .background(Color.desertSand.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name)
                                    .font(.headline)
                                Text(place.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Label("\(place.rating)", systemImage: "star.fill")
                                    Label(place.contributor, systemImage: "person")
                                    Text(place.status == .pending ? appState.text(.reviewPending) : appState.text(.published))
                                        .foregroundStyle(place.status.tint)
                                }
                                .font(.caption2)
                                let facts = GeoFacts.forPlace(named: place.name)
                                if facts.hasSourcedData {
                                    Text(factsSummary(facts))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(Color.oasisTeal)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Text("\(place.points)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(Color.oasisTeal)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddPlace = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(appState.text(.addPlace))
            }
        }
        .sheet(isPresented: $showingAddPlace) {
            HiddenPlaceForm()
        }
        .sheet(item: $selectedPlace) { place in
            PlaceInfoSheet(place: place)
        }
    }

    /// One-line teaser of the verified figures, shown under the place row.
    private func factsSummary(_ facts: GeoFacts) -> String {
        facts.rows
            .filter(\.isVerified)
            .prefix(3)
            .map { "\($0.label): \($0.value)" }
            .joined(separator: " • ")
    }
}

/// Full reference card for a landmark: coordinates plus whatever verified
/// figures exist. Missing figures are stated as missing, never guessed.
struct PlaceInfoSheet: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let place: HiddenPlace

    private var facts: GeoFacts { GeoFacts.forPlace(named: place.name) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label(place.name, systemImage: place.imageSystemName)
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.desertCopper)

                    Text(place.notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let highlight = facts.highlight {
                        Text(highlight)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.oasisTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    }

                    infoCard(title: "الإحداثيات", icon: "location.north.line") {
                        factRow(GeoFacts.Row(label: "عشري", value: decimalText, isVerified: true))
                        factRow(GeoFacts.Row(label: "درجات ودقائق", value: dmsText, isVerified: true))
                    }

                    infoCard(title: "معلومات جغرافية", icon: "ruler") {
                        ForEach(facts.rows, id: \.label) { row in
                            factRow(row)
                        }
                        if facts.rows.contains(where: { !$0.isVerified }) {
                            Text("القيمة المعلّمة بـ«غير موثّق» رقم مبدئي (00) ولم يُوثّق من مصدر — لا تعتمد عليها ميدانيًا.")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let source = facts.source {
                        Label("مصدر الأرقام: \(source)", systemImage: "checkmark.seal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let deviceAltitude = appState.locationManager.altitudeMeters {
                        Label("ارتفاع جهازك الحالي: \(Int(deviceAltitude)) م (من GPS)", systemImage: "iphone.gen3")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.oasisTeal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("معلومات الموقع")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.text(.done)) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func infoCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline.weight(.bold))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func factRow(_ row: GeoFacts.Row) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(row.label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            if !row.isVerified {
                Text("غير موثّق")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15), in: Capsule())
            }
            Text(row.value)
                .font(.caption.weight(.bold))
                .foregroundStyle(row.isVerified ? Color.primary : Color.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var decimalText: String {
        String(format: "%.5f, %.5f", place.coordinate.latitude, place.coordinate.longitude)
    }

    private var dmsText: String {
        "\(dms(place.coordinate.latitude, positive: "N", negative: "S"))  \(dms(place.coordinate.longitude, positive: "E", negative: "W"))"
    }

    private func dms(_ value: Double, positive: String, negative: String) -> String {
        let hemisphere = value >= 0 ? positive : negative
        let absolute = abs(value)
        let degrees = Int(absolute)
        let minutesDecimal = (absolute - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let seconds = (minutesDecimal - Double(minutes)) * 60
        return String(format: "%d°%02d'%04.1f\"%@", degrees, minutes, seconds, hemisphere)
    }
}
