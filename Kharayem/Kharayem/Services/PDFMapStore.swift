import Foundation

enum PDFMapDocument: String, CaseIterable, Identifiable {
    case ajajiSaudi = "AjajiSaudi"
    case ajajiRiyadhRegion = "AjajiRiyadhRegion"
    case ajajiMarkedPlans = "AjajiMarkedPlans"

    var id: String { rawValue }

    var fileName: String {
        "\(rawValue).pdf"
    }
}

@MainActor
final class PDFMapStore: ObservableObject {
    @Published private(set) var importedDocuments: Set<PDFMapDocument> = []
    @Published private(set) var sourceMetadata: [PDFMapDocument: PDFSourceMetadata] = [:]

    init() {
        refreshImportedDocuments()
        loadMetadata()
    }

    func url(for document: PDFMapDocument) -> URL? {
        let imported = importedURL(for: document)
        if FileManager.default.fileExists(atPath: imported.path) {
            return imported
        }
        return Bundle.main.url(forResource: document.rawValue, withExtension: "pdf")
    }

    func importOfficialPDF(from sourceURL: URL, replacing document: PDFMapDocument) throws {
        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let destination = importedURL(for: document)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: destination.path)
        sourceMetadata[document] = PDFSourceMetadata(source: sourceURL.lastPathComponent, importedAt: .now)
        try persistMetadata()
        refreshImportedDocuments()
    }

    func downloadOfficialPDF(from remoteURL: URL, replacing document: PDFMapDocument) async throws {
        let (temporaryURL, response) = try await URLSession.shared.download(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        guard response.mimeType == "application/pdf" || remoteURL.pathExtension.lowercased() == "pdf" else {
            throw URLError(.cannotDecodeContentData)
        }

        let destination = importedURL(for: document)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: destination.path)
        sourceMetadata[document] = PDFSourceMetadata(source: remoteURL.absoluteString, importedAt: .now)
        try persistMetadata()
        refreshImportedDocuments()
    }

    func removeImportedPDF(for document: PDFMapDocument) {
        try? FileManager.default.removeItem(at: importedURL(for: document))
        sourceMetadata.removeValue(forKey: document)
        try? persistMetadata()
        refreshImportedDocuments()
    }

    func isImported(_ document: PDFMapDocument) -> Bool {
        importedDocuments.contains(document)
    }

    private func refreshImportedDocuments() {
        importedDocuments = Set(PDFMapDocument.allCases.filter { FileManager.default.fileExists(atPath: importedURL(for: $0).path) })
    }

    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataURL()),
              let decoded = try? JSONDecoder().decode([String: PDFSourceMetadata].self, from: data) else {
            sourceMetadata = [:]
            return
        }

        sourceMetadata = Dictionary(uniqueKeysWithValues: decoded.compactMap { key, value in
            guard let document = PDFMapDocument(rawValue: key) else { return nil }
            return (document, value)
        })
    }

    private func persistMetadata() throws {
        let encoded = Dictionary(uniqueKeysWithValues: sourceMetadata.map { ($0.key.rawValue, $0.value) })
        let data = try JSONEncoder().encode(encoded)
        try FileManager.default.createDirectory(at: metadataURL().deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: metadataURL(), options: [.atomic, .completeFileProtection])
    }

    private func importedURL(for document: PDFMapDocument) -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OfficialAjajiPDFs", isDirectory: true)
            .appendingPathComponent(document.fileName)
    }

    private func metadataURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OfficialAjajiPDFs", isDirectory: true)
            .appendingPathComponent("sources.json")
    }
}

struct PDFSourceMetadata: Codable, Hashable {
    let source: String
    let importedAt: Date
}
