import Foundation
import OSLog
import SwiftUI
import UIKit

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
    static let cardRadius = AppRadius.card
    static let compactSpacing = AppSpacing.compact
    static let sectionSpacing = AppSpacing.section
    static let roomySpacing = AppSpacing.roomy
    static let screenPadding = AppSpacing.screen
    static let controlHeight: CGFloat = 52

    static let brand = AppColors.brand
    static let accent = AppColors.accent
    static let surface = AppColors.surface
    static let canvas = AppColors.canvas
    static let border = AppColors.border
}

enum AppTheme {
    static let maximumContentWidth: CGFloat = 720
    static let minimumTouchTarget: CGFloat = 44
    static let animation = Animation.spring(response: 0.28, dampingFraction: 0.86)
}

enum AppColors {
    static let brand = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.33, green: 0.75, blue: 0.66, alpha: 1.0)
            : UIColor(red: 0.02, green: 0.34, blue: 0.29, alpha: 1.0)
    })
    static let brandDeep = Color(red: 0.01, green: 0.20, blue: 0.18)
    static let accent = Color(red: 0.83, green: 0.56, blue: 0.18)
    static let accentSoft = Color(red: 0.96, green: 0.78, blue: 0.42)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let border = Color.primary.opacity(0.08)
}

enum AppTypography {
    static let hero = Font.largeTitle.weight(.bold)
    static let sectionTitle = Font.title3.weight(.bold)
    static let cardTitle = Font.headline.weight(.semibold)
    static let body = Font.body
    static let metadata = Font.caption
}

enum AppSpacing {
    static let compact: CGFloat = 8
    static let section: CGFloat = 12
    static let roomy: CGFloat = 16
    static let screen: CGFloat = 16
}

enum AppRadius {
    static let card: CGFloat = 14
    static let control: CGFloat = 12
}

struct AppPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(minHeight: BatalDesign.controlHeight)
            .padding(.horizontal, 14)
            .background(
                LinearGradient(
                    colors: configuration.isPressed
                        ? [AppColors.brandDeep, AppColors.brand]
                        : [AppColors.brand, AppColors.accent.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : AppTheme.animation, value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(minHeight: BatalDesign.controlHeight)
            .padding(.horizontal, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    .stroke(BatalDesign.border)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : AppTheme.animation, value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

extension ButtonStyle where Self == AppPrimaryButtonStyle {
    static var batalPrimary: AppPrimaryButtonStyle { AppPrimaryButtonStyle() }
}

extension ButtonStyle where Self == AppSecondaryButtonStyle {
    static var batalSecondary: AppSecondaryButtonStyle { AppSecondaryButtonStyle() }
}

enum AppHaptics {
    @MainActor
    static func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

enum BatalLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.batalaldroob.parts"

    static let catalog = Logger(subsystem: subsystem, category: "Catalog")
    static let purchases = Logger(subsystem: subsystem, category: "Purchases")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let ai = Logger(subsystem: subsystem, category: "AI")
}
