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
                .id(viewModel.language.rawValue)
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
    static let roomySpacing: CGFloat = 16
    static let screenPadding: CGFloat = 16
    static let controlHeight: CGFloat = 52

    static let brand = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.33, green: 0.75, blue: 0.66, alpha: 1.0)
            : UIColor(red: 0.02, green: 0.34, blue: 0.29, alpha: 1.0)
    })
    static let accent = Color(red: 0.83, green: 0.56, blue: 0.18)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let border = Color.primary.opacity(0.08)
}

enum BatalLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.batalaldroob.parts"

    static let catalog = Logger(subsystem: subsystem, category: "Catalog")
    static let purchases = Logger(subsystem: subsystem, category: "Purchases")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
}
