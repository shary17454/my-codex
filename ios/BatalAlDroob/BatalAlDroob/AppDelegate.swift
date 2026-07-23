import Foundation
import OSLog
import SwiftUI

@main
struct BatalAlDroobApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = CatalogViewModel(
        repository: BundledCatalogRepository(),
        store: StoreKitPurchaseService()
    )

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: viewModel)
                .environment(\.layoutDirection, viewModel.language == .arabic ? .rightToLeft : .leftToRight)
                .environment(\.locale, viewModel.language.locale)
                .task { await viewModel.load() }
                .task { await viewModel.observePurchaseUpdates() }
                .onChange(of: scenePhase) { _, phase in
                    viewModel.isPrivacyShieldVisible = phase != .active
                }
        }
    }
}

// MARK: - Design Tokens

enum BatalDesign {
    static let cardRadius: CGFloat = 8
    static let compactSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 12
}

enum BatalLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.batalaldroob.parts"

    static let catalog = Logger(subsystem: subsystem, category: "Catalog")
    static let purchases = Logger(subsystem: subsystem, category: "Purchases")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
}
