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

        let id = UUID()
        let directory = try mapsDirectory()
        let fileURL = directory.appendingPathComponent("\(id.uuidString).png")
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])

        let map = OfflineMap(
            id: id,
            title: title,
            fileURL: fileURL,
            createdAt: .now,
            centerLatitude: region.center.latitude,
            centerLongitude: region.center.longitude
        )
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

        maps = decoded.compactMap { entry in
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
