import SwiftUI

enum WeshTheme {
    static let accent = Color(red: 0.02, green: 0.47, blue: 0.45)
    static let secondaryAccent = Color(red: 0.24, green: 0.36, blue: 0.72)
    static let highlight = Color(red: 0.86, green: 0.53, blue: 0.14)
    static let success = Color(red: 0.16, green: 0.55, blue: 0.32)
    static let cornerRadius: CGFloat = 8
    static let contentMaxWidth: CGFloat = 980

    static var canvas: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    static var surface: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    static var elevatedSurface: Color {
        Color(uiColor: .tertiarySystemGroupedBackground)
    }

    static var hairline: Color {
        Color.primary.opacity(0.08)
    }
}

struct WeshSurfaceModifier: ViewModifier {
    let padding: CGFloat
    let emphasized: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                emphasized ? WeshTheme.elevatedSurface : WeshTheme.surface,
                in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: WeshTheme.cornerRadius, style: .continuous)
                    .stroke(WeshTheme.hairline, lineWidth: 1)
            }
    }
}

extension View {
    func weshSurface(padding: CGFloat = 16, emphasized: Bool = false) -> some View {
        modifier(WeshSurfaceModifier(padding: padding, emphasized: emphasized))
    }

    func weshContentWidth(alignment: Alignment = .topLeading) -> some View {
        frame(maxWidth: WeshTheme.contentMaxWidth, alignment: alignment)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

struct WeshIconTile: View {
    let systemImage: String
    var color = WeshTheme.accent
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
            .accessibilityHidden(true)
    }
}

struct WeshSectionHeader: View {
    let title: String
    let subtitle: String?
    let systemImage: String?

    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(WeshTheme.accent)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.bold))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct WeshStatusBanner: View {
    enum Kind {
        case information
        case success
        case warning

        var color: Color {
            switch self {
            case .information: WeshTheme.secondaryAccent
            case .success: WeshTheme.success
            case .warning: WeshTheme.highlight
            }
        }

        var icon: String {
            switch self {
            case .information: "info.circle.fill"
            case .success: "checkmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
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
            .padding(12)
            .background(kind.color.opacity(0.10), in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
            .accessibilityElement(children: .combine)
    }
}

struct WeshPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? .white : .secondary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 16)
            .background(
                isEnabled
                    ? WeshTheme.accent.opacity(configuration.isPressed ? 0.78 : 1)
                    : Color.secondary.opacity(0.14),
                in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct WeshSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? WeshTheme.accent : .secondary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 16)
            .background(
                (isEnabled ? WeshTheme.accent : Color.secondary)
                    .opacity(configuration.isPressed ? 0.16 : 0.09),
                in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: WeshTheme.cornerRadius, style: .continuous)
                    .stroke(
                        (isEnabled ? WeshTheme.accent : Color.secondary).opacity(0.22),
                        lineWidth: 1
                    )
            }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct WeshMetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            WeshIconTile(systemImage: systemImage, color: color, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
