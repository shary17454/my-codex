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
