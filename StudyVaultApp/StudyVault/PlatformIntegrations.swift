import AppIntents
import Foundation
import OSLog
import SwiftUI
import TipKit

enum PendingComparisonIntentStore {
    static let titleKey = "wesh.pendingComparison.title"
    static let actionKey = "wesh.pendingAction"
    private static let createdAtKey = "wesh.pendingComparison.createdAt"

    static func save(title: String) {
        UserDefaults.standard.set(title, forKey: titleKey)
        UserDefaults.standard.set(Date(), forKey: createdAtKey)
    }

    static func save(action: PendingAppAction) {
        UserDefaults.standard.set(action.rawValue, forKey: actionKey)
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

    static func consumeAction() -> PendingAppAction? {
        guard let rawValue = UserDefaults.standard.string(forKey: actionKey),
              let action = PendingAppAction(rawValue: rawValue) else {
            return nil
        }
        UserDefaults.standard.removeObject(forKey: actionKey)
        UserDefaults.standard.removeObject(forKey: createdAtKey)
        return action
    }
}

enum PendingAppAction: String {
    case openDiscover
    case openLibrary
    case openLatestResult
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
        AppShortcut(
            intent: OpenDiscoverIntent(),
            phrases: [
                "افتح اكتشف في \(.applicationName)",
                "اعرض المقارنات في \(.applicationName)"
            ],
            shortTitle: "اكتشف",
            systemImageName: "safari.fill"
        )
        AppShortcut(
            intent: OpenMyLibraryIntent(),
            phrases: [
                "افتح مكتبتي في \(.applicationName)",
                "اعرض محفوظاتي في \(.applicationName)"
            ],
            shortTitle: "مكتبتي",
            systemImageName: "tray.full.fill"
        )
        AppShortcut(
            intent: OpenLatestResultIntent(),
            phrases: [
                "افتح آخر نتيجة في \(.applicationName)",
                "اعرض آخر قرار في \(.applicationName)"
            ],
            shortTitle: "آخر نتيجة",
            systemImageName: "chart.bar.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .teal }
}

struct OpenDiscoverIntent: AppIntent {
    static let title: LocalizedStringResource = "فتح اكتشف"
    static let description = IntentDescription("يفتح تبويب اكتشف في وش الرأي.")
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        PendingComparisonIntentStore.save(action: .openDiscover)
        return .result(dialog: "سأفتح اكتشف في وش الرأي.")
    }
}

struct OpenMyLibraryIntent: AppIntent {
    static let title: LocalizedStringResource = "فتح مكتبتي"
    static let description = IntentDescription("يفتح الحساب ومكتبتك الخاصة.")
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        PendingComparisonIntentStore.save(action: .openLibrary)
        return .result(dialog: "سأفتح مكتبتك الخاصة.")
    }
}

struct OpenLatestResultIntent: AppIntent {
    static let title: LocalizedStringResource = "فتح آخر نتيجة"
    static let description = IntentDescription("يفتح آخر نتيجة أو مقارنة متاحة داخل وش الرأي.")
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        PendingComparisonIntentStore.save(action: .openLatestResult)
        return .result(dialog: "سأفتح آخر نتيجة في وش الرأي.")
    }
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
