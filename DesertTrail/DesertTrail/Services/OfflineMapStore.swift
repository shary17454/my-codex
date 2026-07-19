import Foundation
import MapKit
import UIKit

struct OfflineMap: Identifiable, Hashable {
    let id: UUID
    var title: String
    var fileURL: URL
    var createdAt: Date
    var centerLatitude: Double
    var centerLongitude: Double
}

struct OfflineMapPreset: Identifiable {
    let id = UUID()
    var title: String
    var subtitle: String
    var region: MKCoordinateRegion

    static let samples: [OfflineMapPreset] = [
        OfflineMapPreset(
            title: "وادي حنيفة",
            subtitle: "الرياض - أودية ومتنزهات",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730), span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        ),
        OfflineMapPreset(
            title: "حافة العالم",
            subtitle: "طويق - طرق برية وحواف صخرية",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 24.9530, longitude: 45.9960), span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12))
        ),
        OfflineMapPreset(
            title: "روضة خريم",
            subtitle: "ربيع ومناطق عائلية",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.3828, longitude: 47.2552), span: MKCoordinateSpan(latitudeDelta: 0.11, longitudeDelta: 0.11))
        ),
        OfflineMapPreset(
            title: "نفود الثويرات",
            subtitle: "كثبان رملية ومناطق تطعيس",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 26.0900, longitude: 44.1500), span: MKCoordinateSpan(latitudeDelta: 0.18, longitudeDelta: 0.18))
        ),
        OfflineMapPreset(
            title: "العلا",
            subtitle: "جبال وتكوينات صخرية",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 26.6085, longitude: 37.9232), span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16))
        ),
        OfflineMapPreset(
            title: "الربع الخالي",
            subtitle: "منطقة صحراوية واسعة",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 20.2000, longitude: 50.0000), span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45))
        ),
        OfflineMapPreset(
            title: "جبل اللوز",
            subtitle: "تبوك - جبال ومرتفعات باردة",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 28.6640, longitude: 35.2980), span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16))
        ),
        OfflineMapPreset(
            title: "جبة حائل",
            subtitle: "نفود وآثار ومواقع صحراوية",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 28.0030, longitude: 40.9390), span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15))
        ),
        OfflineMapPreset(
            title: "وادي الدواسر",
            subtitle: "طرق برية وأودية جنوب نجد",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 20.4607, longitude: 44.7879), span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22))
        ),
        OfflineMapPreset(
            title: "الصمان",
            subtitle: "دحول وكثبان ومسارات برية",
            region: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 26.6320, longitude: 47.2130), span: MKCoordinateSpan(latitudeDelta: 0.24, longitudeDelta: 0.24))
        )
    ]
}

@MainActor
final class OfflineMapStore: ObservableObject {
    @Published private(set) var maps: [OfflineMap] = []

    private let folderName = "OfflineMaps"

    init() {
        loadSavedMaps()
    }

    func saveSnapshot(title: String, region: MKCoordinateRegion) async throws {
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 900, height: 900)
        options.scale = UIScreen.main.scale
        options.mapType = .hybridFlyover
        options.showsBuildings = false

        let snapshot = try await MKMapSnapshotter(options: options).start()
        guard let data = snapshot.image.pngData() else { return }

        let directory = try mapsDirectory()
        let existingMap = matchingMap(title: title, region: region)
        let id = existingMap?.id ?? UUID()
        let fileURL = existingMap?.fileURL ?? directory.appendingPathComponent("\(id.uuidString).png")
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])

        let map = OfflineMap(
            id: id,
            title: title,
            fileURL: fileURL,
            createdAt: .now,
            centerLatitude: region.center.latitude,
            centerLongitude: region.center.longitude
        )
        maps.removeAll { $0.id == id }
        maps.insert(map, at: 0)
        try persistIndex()
    }

    func delete(_ map: OfflineMap) {
        try? FileManager.default.removeItem(at: map.fileURL)
        maps.removeAll { $0.id == map.id }
        try? persistIndex()
    }

    private func loadSavedMaps() {
        guard let data = try? Data(contentsOf: indexURL()),
              let decoded = try? JSONDecoder().decode([OfflineMapIndexEntry].self, from: data) else {
            maps = []
            return
        }

        let loadedMaps: [OfflineMap] = decoded.compactMap { entry -> OfflineMap? in
            let fileURL = mapsDirectoryIfExists().appendingPathComponent(entry.fileName)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            return OfflineMap(
                id: entry.id,
                title: entry.title,
                fileURL: fileURL,
                createdAt: entry.createdAt,
                centerLatitude: entry.centerLatitude,
                centerLongitude: entry.centerLongitude
            )
        }
        maps = removeDuplicateMaps(from: loadedMaps)
        if maps.count != loadedMaps.count {
            try? persistIndex()
        }
    }

    private func matchingMap(title: String, region: MKCoordinateRegion) -> OfflineMap? {
        let normalizedTitle = normalized(title)
        let target = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        return maps.first { map in
            guard normalized(map.title) == normalizedTitle else { return false }
            let saved = CLLocation(latitude: map.centerLatitude, longitude: map.centerLongitude)
            return target.distance(from: saved) < 1_000
        }
    }

    private func removeDuplicateMaps(from loadedMaps: [OfflineMap]) -> [OfflineMap] {
        var result: [OfflineMap] = []
        for map in loadedMaps.sorted(by: { $0.createdAt > $1.createdAt }) {
            let location = CLLocation(latitude: map.centerLatitude, longitude: map.centerLongitude)
            let duplicate = result.contains { existing in
                guard normalized(existing.title) == normalized(map.title) else { return false }
                let existingLocation = CLLocation(latitude: existing.centerLatitude, longitude: existing.centerLongitude)
                return location.distance(from: existingLocation) < 1_000
            }
            if duplicate {
                try? FileManager.default.removeItem(at: map.fileURL)
            } else {
                result.append(map)
            }
        }
        return result
    }

    private func normalized(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "ar"))
    }

    private func persistIndex() throws {
        let entries = maps.map {
            OfflineMapIndexEntry(
                id: $0.id,
                title: $0.title,
                fileName: $0.fileURL.lastPathComponent,
                createdAt: $0.createdAt,
                centerLatitude: $0.centerLatitude,
                centerLongitude: $0.centerLongitude
            )
        }
        let data = try JSONEncoder().encode(entries)
        try data.write(to: indexURL(), options: [.atomic, .completeFileProtection])
    }

    private func mapsDirectory() throws -> URL {
        let url = mapsDirectoryIfExists()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func mapsDirectoryIfExists() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(folderName, isDirectory: true)
    }

    private func indexURL() -> URL {
        mapsDirectoryIfExists().appendingPathComponent("index.json")
    }
}

private struct OfflineMapIndexEntry: Codable {
    let id: UUID
    let title: String
    let fileName: String
    let createdAt: Date
    let centerLatitude: Double
    let centerLongitude: Double
}
