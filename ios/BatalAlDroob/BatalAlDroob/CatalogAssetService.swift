import CryptoKit
import Foundation

#if canImport(BackgroundAssets)
    import BackgroundAssets
    import System
#endif

struct CatalogAssetDeliveryManifest: Decodable {
    let schemaVersion: Int
    let delivery: String
    let minimumManagedOS: String
    let totalFiles: Int
    let totalBytes: Int64
    let packCount: Int
    let documents: [CatalogDocument]
}

struct CatalogDocument: Decodable, Identifiable, Hashable {
    let id: String
    let fileName: String
    let generation: String
    let years: [String]
    let engines: [String]
    let modelCodes: [String]
    let markets: [String]
    let sourceKind: String
    let pageCount: Int
    let sizeBytes: Int64
    let sha256: String
    let assetPackID: String
    let assetPath: String
    let sourceRelativePath: String

    var title: String {
        let yearText = years.prefix(3).joined(separator: ", ")
        return yearText.isEmpty ? generation : "\(generation) · \(yearText)"
    }

    var searchText: String {
        normalized(
            ([fileName, generation, sourceKind, sourceRelativePath]
                + years + engines + modelCodes + markets)
                .joined(separator: " ")
        )
    }

    var sourceAliases: [String] {
        let stem = (fileName as NSString).deletingPathExtension
        let relativeStem = (sourceRelativePath as NSString).deletingPathExtension
        return [id, fileName, stem, sourceRelativePath, relativeStem].map(normalized)
    }
}

struct CatalogPDFPresentation: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
    let page: Int?
}

protocol CatalogAssetServing: Sendable {
    func loadDocuments() async throws -> [CatalogDocument]
    func isAvailableLocally(_ document: CatalogDocument) async -> Bool
    func localURL(for document: CatalogDocument) async throws -> URL
}

enum CatalogAssetError: LocalizedError {
    case invalidManifest
    case unsafePath
    case unsupportedSystem
    case invalidFileSize
    case invalidChecksum

    var errorDescription: String? {
        switch self {
        case .invalidManifest:
            "Catalog delivery manifest is missing or invalid."
        case .unsafePath:
            "Catalog asset path is invalid."
        case .unsupportedSystem:
            "Original catalog downloads require iOS 26 or later."
        case .invalidFileSize:
            "Downloaded catalog failed its file-size verification."
        case .invalidChecksum:
            "Downloaded catalog failed its integrity verification."
        }
    }
}

actor CatalogAssetService: CatalogAssetServing {
    private let manifestURL: URL?
    private let localArchiveRoot: URL?
    private var cachedDocuments: [CatalogDocument]?
    private var verifiedDocumentIDs = Set<String>()

    init(
        resourceURL: URL? = Bundle.main.resourceURL,
        localArchiveRoot: URL? = CatalogAssetService.debugArchiveRoot()
    ) {
        manifestURL = resourceURL?
            .appendingPathComponent("data", isDirectory: true)
            .appendingPathComponent("catalog_asset_delivery.json", isDirectory: false)
        self.localArchiveRoot = localArchiveRoot
    }

    func loadDocuments() async throws -> [CatalogDocument] {
        if let cachedDocuments { return cachedDocuments }
        guard let manifestURL else { throw CatalogAssetError.invalidManifest }
        let data = try Data(contentsOf: manifestURL, options: [.mappedIfSafe])
        let manifest = try JSONDecoder().decode(CatalogAssetDeliveryManifest.self, from: data)
        guard
            manifest.schemaVersion == 1,
            manifest.delivery == "apple_hosted_background_assets",
            manifest.totalFiles == 640,
            manifest.documents.count == manifest.totalFiles,
            manifest.packCount > 0,
            manifest.packCount <= 200,
            manifest.totalBytes == manifest.documents.reduce(Int64(0), { $0 + $1.sizeBytes })
        else {
            throw CatalogAssetError.invalidManifest
        }
        cachedDocuments = manifest.documents
        return manifest.documents
    }

    func isAvailableLocally(_ document: CatalogDocument) async -> Bool {
        if verifiedLocalURL(for: document) != nil { return true }
        #if canImport(BackgroundAssets)
            if #available(iOS 26.4, *) {
                return AssetPackManager.shared.assetPackIsAvailableLocally(withID: document.assetPackID)
            }
        #endif
        return false
    }

    func localURL(for document: CatalogDocument) async throws -> URL {
        guard isSafe(document) else { throw CatalogAssetError.unsafePath }
        if let localArchiveRoot {
            let localURL = localArchiveRoot.appendingPathComponent(document.assetPath, isDirectory: false)
            if FileManager.default.fileExists(atPath: localURL.path) {
                guard fileSize(at: localURL) == document.sizeBytes else {
                    throw CatalogAssetError.invalidFileSize
                }
                guard verifyChecksum(of: localURL, for: document) else {
                    throw CatalogAssetError.invalidChecksum
                }
                return localURL
            }
        }

        #if canImport(BackgroundAssets)
            if #available(iOS 26.0, *) {
                let manager = AssetPackManager.shared
                let assetPack = try await manager.assetPack(withID: document.assetPackID)
                if #available(iOS 26.4, *) {
                    try await manager.ensureLocalAvailability(of: assetPack, requireLatestVersion: false)
                } else {
                    try await manager.ensureLocalAvailability(of: assetPack)
                }
                let url = try manager.url(for: FilePath(document.assetPath))
                guard fileSize(at: url) == document.sizeBytes else {
                    throw CatalogAssetError.invalidFileSize
                }
                guard verifyChecksum(of: url, for: document) else {
                    throw CatalogAssetError.invalidChecksum
                }
                return url
            }
        #endif

        throw CatalogAssetError.unsupportedSystem
    }

    private func verifiedLocalURL(for document: CatalogDocument) -> URL? {
        guard isSafe(document), let localArchiveRoot else { return nil }
        let url = localArchiveRoot.appendingPathComponent(document.assetPath, isDirectory: false)
        guard fileSize(at: url) == document.sizeBytes else { return nil }
        return verifyChecksum(of: url, for: document) ? url : nil
    }

    private func isSafe(_ document: CatalogDocument) -> Bool {
        document.assetPath.hasPrefix("catalog/patrol_full_unique/")
            && !document.assetPath.split(separator: "/").contains("..")
            && document.sha256.range(of: "^[0-9a-f]{64}$", options: .regularExpression) != nil
            && document.sizeBytes > 0
    }

    private func fileSize(at url: URL) -> Int64? {
        guard
            let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
            values.isRegularFile == true,
            let size = values.fileSize
        else { return nil }
        return Int64(size)
    }

    private func verifyChecksum(of url: URL, for document: CatalogDocument) -> Bool {
        if verifiedDocumentIDs.contains(document.id) { return true }
        guard let checksum = try? sha256(of: url), checksum == document.sha256 else { return false }
        verifiedDocumentIDs.insert(document.id)
        return true
    }

    private func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while let data = try handle.read(upToCount: 1_048_576), !data.isEmpty {
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private nonisolated static func debugArchiveRoot() -> URL? {
        #if DEBUG
            guard
                let path = ProcessInfo.processInfo.environment["BATAL_CATALOG_LOCAL_ROOT"],
                !path.isEmpty
            else { return nil }
            return URL(fileURLWithPath: path, isDirectory: true)
        #else
            return nil
        #endif
    }
}
