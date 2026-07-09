import SwiftUI

struct CommunityView: View {
    @EnvironmentObject private var appState: AppState
    @State private var query = ""
    @State private var showingAddPlace = false

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
                        }
                        Spacer()
                        Text("\(place.points)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Color.oasisTeal)
                    }
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
    }
}
