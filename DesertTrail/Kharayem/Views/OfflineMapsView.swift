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
                        Task { await save(title: currentRegionTitle, region: region, presetID: nil) }
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

                    Label("\(filteredPresets.count) منطقة جاهزة للحفظ المحلي", systemImage: "square.grid.2x2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    if filteredLandmarks.isEmpty {
                        ContentUnavailableView {
                            Label("لا توجد نتائج", systemImage: "magnifyingglass")
                        } description: {
                            Text("جرّب البحث باسم وادٍ أو جبل أو منطقة مثل: حنيفة، طويق، الديسة، أجا.")
                        }
                    } else {
                        ForEach(filteredLandmarks.prefix(8)) { landmark in
                            landmarkRow(landmark)
                        }
                    }
                } header: {
                    Text("فهرس المعالم والأودية دون إنترنت")
                } footer: {
                    Text("الفهرس المحلي يعمل دون اتصال ويعرض أسماء الأودية والجبال والمعالم القريبة. حفظ الخريطة هنا يحفظ لقطة مرجعية من خرائط Apple، وليس بيانات ملاحة كاملة.")
                }

                ForEach(groupedFilteredPresets, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.presets) { preset in
                            presetRow(preset)
                        }
                    }
                }

                Section(store.maps.isEmpty ? "لا توجد خرائط محفوظة" : "الخرائط المحفوظة") {
                    ForEach(store.maps) { map in
                        NavigationLink {
                            SavedOfflineMapDetail(map: map)
                        } label: {
                            SavedOfflineMapRow(map: map)
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

    private var filteredPresets: [OfflineMapPreset] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return OfflineMapPreset.samples }
        return OfflineMapPreset.samples.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.subtitle.localizedCaseInsensitiveContains(query) ||
            landmarkSummary(for: $0.region).localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredLandmarks: [GeospatialSearchResult] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = GeospatialSearchResult.samples.filter { landmark in
            query.isEmpty ||
            landmark.name.localizedCaseInsensitiveContains(query) ||
            landmark.type.localizedCaseInsensitiveContains(query) ||
            landmark.source.localizedCaseInsensitiveContains(query)
        }
        return matches.sorted {
            distance(from: region.center, to: $0.coordinate) < distance(from: region.center, to: $1.coordinate)
        }
    }

    private var groupedFilteredPresets: [OfflineMapPresetGroup] {
        let presets = filteredPresets
        let groups = [
            OfflineMapPresetGroup(title: "الرياض ونجد", presets: presets.filter { containsAny($0, ["الرياض", "طويق", "حنيفة", "خريم", "الصمان", "الدهناء"]) }),
            OfflineMapPresetGroup(title: "الشمال والشمال الغربي", presets: presets.filter { containsAny($0, ["العلا", "اللوز", "جبة", "أجا", "سلمى", "خيبر", "الديسة", "حسمي"]) }),
            OfflineMapPresetGroup(title: "الغرب والحجاز", presets: presets.filter { containsAny($0, ["رهط", "ورقان", "الفرع", "وج", "كشب"]) }),
            OfflineMapPresetGroup(title: "الجنوب والمرتفعات", presets: presets.filter { containsAny($0, ["السودة", "فيفاء", "لجب", "شدا", "بيشة", "نجران", "القهر"]) }),
            OfflineMapPresetGroup(title: "الصحارى والمسارات الطويلة", presets: presets.filter { containsAny($0, ["الربع", "الدواسر", "يبرين", "نفود"]) })
        ]
        let groupedIDs = Set(groups.flatMap { $0.presets.map(\.id) })
        let uncategorized = presets.filter { !groupedIDs.contains($0.id) }
        return (groups + [OfflineMapPresetGroup(title: "مناطق أخرى", presets: uncategorized)])
            .filter { !$0.presets.isEmpty }
    }

    @ViewBuilder
    private func presetRow(_ preset: OfflineMapPreset) -> some View {
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
                    Text(landmarkSummary(for: preset.region))
                        .font(.caption2)
                        .foregroundStyle(Color.oasisTeal)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
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

    private func landmarkRow(_ landmark: GeospatialSearchResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: landmarkIcon(for: landmark.type))
                .foregroundStyle(Color.oasisTeal)
                .frame(width: 32, height: 32)
                .background(Color.oasisTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(landmark.name)
                        .font(.headline)
                    Text(landmark.type)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.desertCopper)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.desertCopper.opacity(0.12), in: Capsule())
                }

                Text("\(landmark.source) · \(String(format: "%.0f", distance(from: region.center, to: landmark.coordinate) / 1_000)) كم من مركز الخريطة")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(String(format: "%.4f, %.4f", landmark.coordinate.latitude, landmark.coordinate.longitude))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(landmark.name)، \(landmark.type)، \(landmark.source)")
    }

    private func landmarkSummary(for region: MKCoordinateRegion) -> String {
        let nearby = GeospatialSearchResult.samples
            .sorted { distance(from: region.center, to: $0.coordinate) < distance(from: region.center, to: $1.coordinate) }
            .prefix(3)
            .map(\.name)
        guard !nearby.isEmpty else { return "لا توجد معالم قريبة في الفهرس المحلي" }
        return "معالم قريبة: \(nearby.joined(separator: "، "))"
    }

    private func landmarkIcon(for type: String) -> String {
        if type.contains("وادي") || type.contains("شعيب") { return "water.waves" }
        if type.contains("جبل") || type.contains("مرتفع") || type.contains("هضبة") { return "mountain.2" }
        if type.contains("نفود") || type.contains("صحراء") { return "sun.max" }
        if type.contains("حرة") { return "flame" }
        if type.contains("روضة") { return "leaf" }
        return "mappin.and.ellipse"
    }

    private func containsAny(_ preset: OfflineMapPreset, _ words: [String]) -> Bool {
        words.contains { word in
            preset.title.localizedCaseInsensitiveContains(word) ||
            preset.subtitle.localizedCaseInsensitiveContains(word)
        }
    }

    private var currentRegionTitle: String {
        if let nearest = OfflineMapPreset.samples.min(by: {
            distance(from: region.center, to: $0.region.center) < distance(from: region.center, to: $1.region.center)
        }), distance(from: region.center, to: nearest.region.center) < 15_000 {
            return nearest.title
        }
        return String(format: "خريطة %.3f, %.3f", region.center.latitude, region.center.longitude)
    }

    private func distance(from first: CLLocationCoordinate2D, to second: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: first.latitude, longitude: first.longitude)
            .distance(from: CLLocation(latitude: second.latitude, longitude: second.longitude))
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

private struct OfflineMapPresetGroup {
    let title: String
    let presets: [OfflineMapPreset]
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

private struct SavedOfflineMapDetail: View {
    let map: OfflineMap

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let image = UIImage(contentsOfFile: map.fileURL.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("الخريطة المحفوظة لمنطقة \(map.title)")
                } else {
                    ContentUnavailableView("تعذر فتح الخريطة", systemImage: "map.fill")
                }

                Label(map.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                Label(
                    String(format: "%.5f, %.5f", map.centerLatitude, map.centerLongitude),
                    systemImage: "location"
                )
                .font(.body.monospacedDigit())

                ShareLink(item: map.fileURL) {
                    Label("مشاركة صورة الخريطة", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle(map.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
