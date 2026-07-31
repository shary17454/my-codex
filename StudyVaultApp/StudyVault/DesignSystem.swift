import SwiftUI
import UIKit

enum WeshTheme {
    static let accent = adaptiveColor(light: 0x126F5B, dark: 0x27B58A)
    static let accentBright = adaptiveColor(light: 0x168F74, dark: 0x56D2AD)
    static let gold = adaptiveColor(light: 0xA8732C, dark: 0xD7AE63)
    static let goldBright = adaptiveColor(light: 0xC78F42, dark: 0xE8C988)
    static let warning = adaptiveColor(light: 0xB78738, dark: 0xE5B85C)
    static let highlight = warning
    static let destructive = adaptiveColor(light: 0xB95353, dark: 0xE27373)
    static let success = accent
    static let secondaryAccent = adaptiveColor(light: 0x416988, dark: 0x8FB4D4)

    static let canvas = adaptiveColor(light: 0xF6F3ED, dark: 0x070A0E)
    static let canvasBottom = adaptiveColor(light: 0xECE4D8, dark: 0x111822)
    static let surface = adaptiveColor(light: 0xFFFDF8, dark: 0x111820)
    static let elevatedSurface = adaptiveColor(light: 0xFFFFFF, dark: 0x19222D)
    static let premiumSurface = adaptiveColor(light: 0xFFFCF4, dark: 0x101A1D)
    static let primaryText = adaptiveColor(light: 0x171B21, dark: 0xF7F8FA)
    static let secondaryText = adaptiveColor(light: 0x66707B, dark: 0xA8B0BA)
    static let hairline = adaptiveColor(light: 0xE6E0D6, dark: 0x2B323D)

    static let cardRadius: CGFloat = 26
    static let controlRadius: CGFloat = 18
    static let compactRadius: CGFloat = 12
    static let cornerRadius = compactRadius
    static let contentMaxWidth: CGFloat = 1180
    static let horizontalPadding: CGFloat = 20
    static let touchTarget: CGFloat = 54

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                adaptiveColor(light: 0xF9F5EE, dark: 0x05070A),
                canvas,
                canvasBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                adaptiveColor(light: 0x0E3D35, dark: 0x071211),
                adaptiveColor(light: 0x126F5B, dark: 0x0D2A24),
                adaptiveColor(light: 0x8B642F, dark: 0x4C3315)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    static var decisionGradient: LinearGradient {
        LinearGradient(
            colors: [
                adaptiveColor(light: 0xFEFBF3, dark: 0x0B1117),
                accent.opacity(0.18),
                gold.opacity(0.18)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    static var goldGradient: LinearGradient {
        LinearGradient(
            colors: [goldBright, gold],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    static func categoryColor(_ category: AskCategory) -> Color {
        switch category {
        case .all: accent
        case .phones, .laptops: secondaryAccent
        case .cars, .travel: adaptiveColor(light: 0x2A7992, dark: 0x5DB2C9)
        case .restaurants, .fashion: adaptiveColor(light: 0xA75C46, dark: 0xD88C73)
        case .services, .education: adaptiveColor(light: 0x6A5EAB, dark: 0xA092DF)
        case .subscriptions, .gaming: adaptiveColor(light: 0x8B568C, dark: 0xC58FC6)
        case .home: adaptiveColor(light: 0x8A6B3D, dark: 0xC7A46A)
        case .health: adaptiveColor(light: 0xA54E5D, dark: 0xDF8292)
        case .other: secondaryText
        }
    }

    private static func adaptiveColor(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

struct WeshSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let padding: CGFloat
    let emphasized: Bool
    let goldAccent: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                emphasized ? WeshTheme.premiumSurface : WeshTheme.surface,
                in: RoundedRectangle(cornerRadius: WeshTheme.cardRadius, style: .continuous)
            )
            .overlay(alignment: .topTrailing) {
                if emphasized {
                    LinearGradient(
                        colors: [
                            WeshTheme.gold.opacity(0.10),
                            WeshTheme.accent.opacity(0.06),
                            .clear
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                    .clipShape(RoundedRectangle(cornerRadius: WeshTheme.cardRadius, style: .continuous))
                    .allowsHitTesting(false)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: WeshTheme.cardRadius, style: .continuous)
                    .stroke(
                        goldAccent ? WeshTheme.gold.opacity(0.55) : WeshTheme.hairline,
                        lineWidth: goldAccent ? 1.25 : 1
                    )
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.065),
                radius: emphasized ? 24 : 12,
                y: emphasized ? 12 : 5
            )
    }
}

extension View {
    func weshSurface(
        padding: CGFloat = 18,
        emphasized: Bool = false,
        goldAccent: Bool = false
    ) -> some View {
        modifier(WeshSurfaceModifier(padding: padding, emphasized: emphasized, goldAccent: goldAccent))
    }

    func weshContentWidth(alignment: Alignment = .topLeading) -> some View {
        frame(maxWidth: WeshTheme.contentMaxWidth, alignment: alignment)
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    func weshField() -> some View {
        padding(.horizontal, 14)
            .frame(minHeight: WeshTheme.touchTarget)
            .background(WeshTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
            .overlay {
                RoundedRectangle(cornerRadius: WeshTheme.controlRadius)
                    .stroke(WeshTheme.hairline, lineWidth: 1)
            }
    }
}

struct WeshBrandMark: View {
    var size: CGFloat = 56
    var usesGold = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(usesGold ? WeshTheme.goldGradient : WeshTheme.heroGradient)
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .stroke(WeshTheme.goldBright.opacity(0.32), lineWidth: max(1, size * 0.025))
            WeshCompassGlyph(size: size * 0.72, showsCheckmark: true)
        }
        .frame(width: size, height: size)
        .shadow(color: (usesGold ? WeshTheme.gold : WeshTheme.accent).opacity(0.24), radius: 12, y: 6)
        .accessibilityHidden(true)
    }
}

struct WeshCompassGlyph: View {
    var size: CGFloat = 44
    var showsCheckmark = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(WeshTheme.goldBright.opacity(0.8), lineWidth: max(1, size * 0.045))
            Circle()
                .stroke(WeshTheme.gold.opacity(0.24), lineWidth: max(1, size * 0.018))
                .frame(width: size * 0.72, height: size * 0.72)

            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(WeshTheme.goldBright.opacity(0.75))
                    .frame(width: max(1.5, size * 0.035), height: size * 0.14)
                    .offset(y: -size * 0.39)
                    .rotationEffect(.degrees(Double(index) * 90))
            }

            Image(systemName: showsCheckmark ? "checkmark.seal.fill" : "location.north.line.fill")
                .font(.system(size: size * (showsCheckmark ? 0.52 : 0.58), weight: .bold))
                .foregroundStyle(WeshTheme.goldGradient)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
    }
}

struct WeshIconTile: View {
    let systemImage: String
    var color = WeshTheme.accent
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: size * 0.31, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.31, style: .continuous)
                    .stroke(color.opacity(0.12), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

struct WeshSectionHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    var actionTitle: String?
    var action: (() -> Void)?

    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(WeshTheme.accent)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(WeshTheme.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WeshTheme.accent)
            }
        }
        .accessibilityElement(children: action == nil ? .combine : .contain)
    }
}

struct WeshStatusBanner: View {
    enum Kind {
        case information
        case success
        case warning
        case error

        var color: Color {
            switch self {
            case .information: WeshTheme.secondaryAccent
            case .success: WeshTheme.success
            case .warning: WeshTheme.warning
            case .error: WeshTheme.destructive
            }
        }

        var icon: String {
            switch self {
            case .information: "info.circle.fill"
            case .success: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .error: "xmark.octagon.fill"
            }
        }
    }

    let text: String
    let kind: Kind

    var body: some View {
        Label(text, systemImage: kind.icon)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(kind.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(kind.color.opacity(0.11), in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
            .overlay {
                RoundedRectangle(cornerRadius: WeshTheme.controlRadius)
                    .stroke(kind.color.opacity(0.2), lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
    }
}

struct WeshPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? .white : WeshTheme.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: WeshTheme.touchTarget)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? [WeshTheme.accentBright, WeshTheme.accent]
                        : [WeshTheme.hairline, WeshTheme.hairline],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .opacity(configuration.isPressed ? 0.84 : 1),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: isEnabled ? WeshTheme.accent.opacity(0.22) : .clear, radius: 12, y: 5)
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct WeshGoldButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Color.black.opacity(0.82) : WeshTheme.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: WeshTheme.touchTarget)
            .background(
                LinearGradient(
                    colors: isEnabled ? [WeshTheme.goldBright, WeshTheme.gold] : [WeshTheme.hairline],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .opacity(configuration.isPressed ? 0.82 : 1),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct WeshSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? WeshTheme.primaryText : WeshTheme.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: WeshTheme.touchTarget)
            .background(
                WeshTheme.surface.opacity(configuration.isPressed ? 0.72 : 1),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(WeshTheme.hairline, lineWidth: 1)
            }
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct WeshMetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 11) {
            WeshIconTile(systemImage: systemImage, color: color, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(WeshTheme.primaryText)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct WeshPill: View {
    let title: String
    let systemImage: String?
    let color: Color

    init(_ title: String, systemImage: String? = nil, color: Color = WeshTheme.accent) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        Group {
            if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.12), in: Capsule())
        .overlay { Capsule().stroke(color.opacity(0.15), lineWidth: 1) }
    }
}

struct WeshEmptyState: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            WeshIconTile(systemImage: systemImage, color: WeshTheme.secondaryText, size: 58)
            Text(title)
                .font(.title3.weight(.bold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(WeshTheme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(WeshSecondaryButtonStyle())
                    .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding(24)
        .background(WeshTheme.surface.opacity(0.65), in: RoundedRectangle(cornerRadius: WeshTheme.cardRadius))
        .accessibilityElement(children: .contain)
    }
}

struct WeshStepIndicator: View {
    let current: Int
    let titles: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                VStack(spacing: 7) {
                    ZStack {
                        Circle()
                            .fill(index <= current ? WeshTheme.accent : WeshTheme.elevatedSurface)
                        if index < current {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(index == current ? .white : WeshTheme.secondaryText)
                        }
                    }
                    .frame(width: 30, height: 30)
                    Text(title)
                        .font(.caption2.weight(index == current ? .bold : .medium))
                        .foregroundStyle(index == current ? WeshTheme.primaryText : WeshTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity)
                if index < titles.count - 1 {
                    Capsule()
                        .fill(index < current ? WeshTheme.accent : WeshTheme.hairline)
                        .frame(height: 2)
                        .offset(y: -10)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("المرحلة \(current + 1) من \(titles.count): \(titles[current])")
    }
}
