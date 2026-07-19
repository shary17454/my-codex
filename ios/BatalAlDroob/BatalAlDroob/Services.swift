import Foundation
import StoreKit
import Vision

// MARK: - Services

protocol CatalogRepository: Sendable {
    func loadCatalog() async throws -> CatalogPayload
    func loadStores() async throws -> [VerifiedStore]
}

struct BundledCatalogRepository: CatalogRepository {
    func loadCatalog() async throws -> CatalogPayload {
        try await decodeBundledJSON(
            CatalogPayload.self,
            resource: "y60_app_catalog",
            subdirectories: ["data", "Web/data"]
        )
    }

    func loadStores() async throws -> [VerifiedStore] {
        let directory = try await decodeBundledJSON(
            StoreDirectory.self,
            resource: "store_directory",
            subdirectories: ["data", "Web/data"]
        )
        return directory.verifiedStores
    }

    private func decodeBundledJSON<T: Decodable & Sendable>(
        _: T.Type,
        resource: String,
        subdirectories: [String]
    ) async throws -> T {
        let url = subdirectories.lazy.compactMap {
            Bundle.main.url(forResource: resource, withExtension: "json", subdirectory: $0)
        }.first
        guard let url else {
            throw AppError.missingResource(resource)
        }
        return try await Task.detached(priority: .userInitiated) {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        }.value
    }
}

protocol PhotoTextRecognizing: Sendable {
    func recognizeText(in data: Data) async throws -> [String]
}

struct VisionPhotoTextRecognizer: PhotoTextRecognizing {
    func recognizeText(in data: Data) async throws -> [String] {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(data: data, options: [:])
            try handler.perform([request])
            return (request.results ?? []).compactMap { observation in
                observation.topCandidates(1).first?.string
            }
        }.value
    }
}

protocol PurchaseService: Sendable {
    func availableProductIDs(for productIDs: [String]) async throws -> Set<String>
    func currentEntitledProductIDs() async -> Set<String>
    func entitlementUpdates() -> AsyncStream<Set<String>>
    func purchase(productID: String) async throws -> PurchaseOutcome
    func restorePurchasedProductIDs() async throws -> Set<String>
}

enum PurchaseOutcome: Equatable { case success, cancelled, pending }

struct StoreKitPurchaseService: PurchaseService {
    func availableProductIDs(for productIDs: [String]) async throws -> Set<String> {
        let products = try await Product.products(for: productIDs)
        return Set(products.map(\.id))
    }

    func purchase(productID: String) async throws -> PurchaseOutcome {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { throw AppError.productUnavailable }
        let result = try await product.purchase()
        switch result {
        case let .success(verification):
            guard case let .verified(transaction) = verification else { throw AppError.unverifiedTransaction }
            await transaction.finish()
            return .success
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            throw AppError.unknownPurchaseResult
        }
    }

    func currentEntitledProductIDs() async -> Set<String> {
        var entitled = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            entitled.insert(transaction.productID)
        }
        return entitled
    }

    func entitlementUpdates() -> AsyncStream<Set<String>> {
        AsyncStream { continuation in
            let task = Task {
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { break }
                    guard case let .verified(transaction) = result else {
                        BatalLog.purchases.error("Ignored an unverified StoreKit transaction update")
                        continue
                    }
                    await transaction.finish()
                    await continuation.yield(currentEntitledProductIDs())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func restorePurchasedProductIDs() async throws -> Set<String> {
        try await AppStore.sync()
        return await currentEntitledProductIDs()
    }
}

enum AppError: LocalizedError {
    case missingResource(String), productUnavailable, unverifiedTransaction, unknownPurchaseResult, unreadablePhoto
    var errorDescription: String? {
        switch self {
        case let .missingResource(name): "Missing bundled resource: \(name)"
        case .productUnavailable: "In-app purchase is not ready yet."
        case .unverifiedTransaction: "Transaction verification failed."
        case .unknownPurchaseResult: "Unknown purchase result."
        case .unreadablePhoto: "The selected photo could not be read."
        }
    }
}
