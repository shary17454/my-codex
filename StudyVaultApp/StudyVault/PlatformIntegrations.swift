import AppIntents
import Foundation
import OSLog
import SwiftUI
import TipKit

enum PendingComparisonIntentStore {
    static let titleKey = "wesh.pendingComparison.title"
    private static let createdAtKey = "wesh.pendingComparison.createdAt"

    static func save(title: String) {
        UserDefaults.standard.set(title, forKey: titleKey)
        UserDefaults.standard.set(Date(), forKey: createdAtKey)
    }

    static func consumeTitle() -> String? {
        guard let title = UserDefaults.standard.string(forKey: titleKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            return nil
        }
        UserDefaults.standard.removeObject(forKey: titleKey)
        UserDefaults.standard.removeObject(forKey: createdAtKey)
        return title
    }
}

struct CreateComparisonIntent: AppIntent {
    static let title: LocalizedStringResource = "إنشاء مقارنة في وش الرأي"
    static let description = IntentDescription("يجهز عنوان مقارنة جديدة ويفتح التطبيق لإكمال الخيارات والنشر.")

    static var openAppWhenRun: Bool { true }

    @available(iOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @IntentParameter<String>(title: "عنوان المقارنة")
    var comparisonTitle: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let cleanTitle = comparisonTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanTitle.count >= 3 else {
            throw CreateComparisonIntentError.titleTooShort
        }
        PendingComparisonIntentStore.save(title: String(cleanTitle.prefix(180)))
        return .result(dialog: "تم تجهيز العنوان. أكمل الخيارات داخل وش الرأي.")
    }
}

enum CreateComparisonIntentError: LocalizedError {
    case titleTooShort

    var errorDescription: String? { "اكتب عنوانًا أوضح للمقارنة." }
}

struct WeshAlRayShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateComparisonIntent(),
            phrases: [
                "أنشئ مقارنة في \(.applicationName)",
                "مقارنة جديدة في \(.applicationName)",
                "اسأل الناس في \(.applicationName)"
            ],
            shortTitle: "مقارنة جديدة",
            systemImageName: "plus.bubble.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .teal }
}

struct DecisionSummaryTip: Tip {
    var title: Text { Text("ملخص القرار") }
    var message: Text? { Text("يجمع المتصدر والفارق وجودة الأدلة وأهم الأسباب في خلاصة واحدة.") }
    var image: Image? { Image(systemName: "checkmark.message.fill") }
}

struct TriedOptionTip: Tip {
    var title: Text { Text("هل جرّبت الخيار؟") }
    var message: Text? { Text("حدد هذا الخيار عندما يكون رأيك مبنيًا على تجربة شخصية.") }
    var image: Image? { Image(systemName: "hand.thumbsup.fill") }
}

struct DecisionSummaryEducationView: View {
    private let tip = DecisionSummaryTip()

    var body: some View {
        TipView(tip)
            .tipBackground(WeshTheme.surface)
            .accessibilityIdentifier("tip.decisionSummary")
    }
}

@MainActor
enum WeshTipConfiguration {
    private static var didConfigure = false
    private static let logger = Logger(subsystem: "com.shary17454.esal", category: "TipKit")

    static func configure() {
        guard !didConfigure else { return }
        do {
            if ProcessInfo.processInfo.arguments.contains("-WeshSkipOnboarding") {
                Tips.hideAllTipsForTesting()
            }
            try Tips.configure([
                .displayFrequency(.weekly),
                .datastoreLocation(.applicationDefault)
            ])
            didConfigure = true
        } catch {
            logger.error("TipKit configuration failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
