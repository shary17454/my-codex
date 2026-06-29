import Combine
import Foundation

@MainActor
final class PartsStore: ObservableObject {
    @Published private(set) var vehicle: VehicleProfile?
    @Published private(set) var systems: [PartSystem] = []
    @Published private(set) var parts: [PartRecord] = []
    @Published private(set) var userContent: [String: PartUserContent] = [:]

    private let fileManager = FileManager.default

    init() {
        loadSeed()
        loadUserContent()
    }

    func partContent(for partID: String) -> PartUserContent {
        userContent[partID] ?? PartUserContent()
    }

    func notes(for partID: String) -> [PartNote] {
        partContent(for: partID).notes.sorted { $0.createdAt > $1.createdAt }
    }

    func photos(for partID: String) -> [PartPhoto] {
        partContent(for: partID).photos.sorted { $0.createdAt > $1.createdAt }
    }

    func photoURL(for photo: PartPhoto) -> URL {
        photosDirectory.appendingPathComponent(photo.filename)
    }

    func addNote(_ text: String, to partID: String) {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        var content = partContent(for: partID)
        content.notes.insert(PartNote(text: clean), at: 0)
        userContent[partID] = content
        saveUserContent()
    }

    func deleteNote(_ note: PartNote, from partID: String) {
        var content = partContent(for: partID)
        content.notes.removeAll { $0.id == note.id }
        userContent[partID] = content
        saveUserContent()
    }

    func addPhoto(data: Data, to partID: String) throws {
        try ensureDirectories()
        let photo = PartPhoto(filename: "\(UUID().uuidString).jpg")
        try data.write(to: photoURL(for: photo), options: .atomic)
        var content = partContent(for: partID)
        content.photos.insert(photo, at: 0)
        userContent[partID] = content
        saveUserContent()
    }

    func deletePhoto(_ photo: PartPhoto, from partID: String) {
        try? fileManager.removeItem(at: photoURL(for: photo))
        var content = partContent(for: partID)
        content.photos.removeAll { $0.id == photo.id }
        userContent[partID] = content
        saveUserContent()
    }

    func parts(for system: PartSystem) -> [PartRecord] {
        parts.filter { $0.systemKey == system.key }
    }

    private func loadSeed() {
        guard
            let url = Bundle.main.url(forResource: "parts_seed", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let seed = try? JSONDecoder().decode(PartsSeed.self, from: data)
        else {
            return
        }
        vehicle = seed.vehicle
        systems = seed.systems.sorted { $0.nameAr < $1.nameAr }
        parts = seed.parts
    }

    private func loadUserContent() {
        try? ensureDirectories()
        guard
            let data = try? Data(contentsOf: metadataURL),
            let decoded = try? JSONDecoder().decode([String: PartUserContent].self, from: data)
        else {
            userContent = [:]
            return
        }
        userContent = decoded
    }

    private func saveUserContent() {
        try? ensureDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(userContent) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }

    private func ensureDirectories() throws {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }

    private var appSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    private var storageDirectory: URL {
        appSupportDirectory.appendingPathComponent("SafariY60Parts", isDirectory: true)
    }

    private var photosDirectory: URL {
        storageDirectory.appendingPathComponent("photos", isDirectory: true)
    }

    private var metadataURL: URL {
        storageDirectory.appendingPathComponent("part_user_content.json")
    }
}
