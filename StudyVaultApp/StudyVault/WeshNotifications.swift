import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class WeshNotificationCenterStore: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = WeshNotificationCenterStore()

    @Published private(set) var items: [WeshNotificationItem] = []
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var lastRegistrationError: String?
    /// Comparison the user asked to open by tapping a delivered notification.
    @Published var pendingComparisonID: UUID?

    private let storageKey = "wesh.notifications.items"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private override init() {
        super.init()
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        load()
        UNUserNotificationCenter.current().delegate = self
    }

    var unreadCount: Int {
        items.filter { !$0.isRead }.count
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorizationAndRegister() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            guard granted else { return false }
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return true
        } catch {
            lastRegistrationError = "تعذر طلب إذن الإشعارات."
            return false
        }
    }

    func registerDeviceToken(_ tokenData: Data, using client: WeshAlrayAPIClient?) async {
        let token = tokenData.map { String(format: "%02x", $0) }.joined()
        guard let client else {
            lastRegistrationError = "لم يتم ضبط Backend لإرسال تنبيهات Push."
            return
        }
        do {
            try await client.registerDevice(pushToken: token)
            lastRegistrationError = nil
        } catch {
            lastRegistrationError = error.localizedDescription
        }
    }

    func setRemoteNotifications(_ remoteItems: [WeshNotificationItem]) {
        let merged = (remoteItems + items)
            .reduce(into: [UUID: WeshNotificationItem]()) { result, item in
                result[item.id] = result[item.id] ?? item
            }
            .values
            .sorted { $0.createdAt > $1.createdAt }
        items = Array(merged.prefix(80))
        save()
    }

    func addLocal(_ item: WeshNotificationItem) {
        if !items.contains(where: { $0.id == item.id }) {
            items.insert(item, at: 0)
            items = Array(items.prefix(80))
            save()
        }
    }

    func markAllRead() {
        items = items.map { item in
            var copy = item
            copy.isRead = true
            return copy
        }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let rawID = userInfo[WeshNotificationPayloadKey.comparisonID] as? String,
              let comparisonID = UUID(uuidString: rawID) else {
            return
        }
        await MainActor.run { pendingComparisonID = comparisonID }
    }

    /// Reads and clears the comparison queued by a notification tap.
    func consumePendingComparisonID() -> UUID? {
        defer { pendingComparisonID = nil }
        return pendingComparisonID
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? decoder.decode([WeshNotificationItem].self, from: data) else {
            items = []
            return
        }
        items = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func save() {
        guard let data = try? encoder.encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

final class WeshNotificationAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            await WeshNotificationCenterStore.shared.registerDeviceToken(
                deviceToken,
                using: WeshNotificationBackendBridge.shared.clientProvider?()
            )
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            WeshNotificationCenterStore.shared.addLocal(
                WeshNotificationItem(
                    // Stable ID so repeated registration failures collapse into one entry
                    // instead of flooding the notification centre with duplicates.
                    id: Self.pushRegistrationFailureID,
                    kind: .system,
                    title: "لم يتم تفعيل Push بعد",
                    body: "يلزم تفعيل Push Notifications وAPNs على حساب Apple لإرسال التنبيهات خارج التطبيق."
                )
            )
        }
    }

    private static let pushRegistrationFailureID = UUID(uuidString: "1E4C1F92-4A3B-4F5E-9C2D-8B7A6D5E4F30") ?? UUID()
}

@MainActor
final class WeshNotificationBackendBridge {
    static let shared = WeshNotificationBackendBridge()
    var clientProvider: (() -> WeshAlrayAPIClient?)?

    private init() {}
}

extension LocalNotificationScheduler {
    static func scheduleClosingReminderIfPossible(
        for question: AskQuestion,
        authorization: AuthorizationPolicy = .existingOnly
    ) async throws {
        guard let closesAt = question.closesAt else {
            throw AppError.invalidInput("لا يوجد وقت انتهاء لهذه المقارنة.")
        }
        let reminderDate = closesAt.addingTimeInterval(-3_600)
        guard reminderDate > Date().addingTimeInterval(60) else {
            throw AppError.invalidInput("وقت انتهاء المقارنة قريب جدًا لجدولة تذكير مسبق.")
        }
        try await schedule(
            identifier: "wesh-closing-\(question.id.uuidString)",
            title: "اقترب انتهاء المقارنة",
            body: "راجع آخر نتيجة: \(question.title)",
            date: reminderDate,
            comparisonID: question.id,
            authorization: authorization
        )
    }

    static func scheduleOutcomeFollowUp(
        for question: AskQuestion,
        after timeInterval: TimeInterval = 604_800,
        authorization: AuthorizationPolicy = .existingOnly
    ) async throws {
        try await schedule(
            identifier: "wesh-outcome-\(question.id.uuidString)",
            title: "وش اخترت بالنهاية؟",
            body: "سجّل تجربتك مع: \(question.title). هل أنت راضٍ عن القرار؟",
            date: Date().addingTimeInterval(max(3_600, timeInterval)),
            comparisonID: question.id,
            authorization: authorization
        )
    }

    private static func schedule(
        identifier: String,
        title: String,
        body: String,
        date: Date,
        comparisonID: UUID?,
        authorization: AuthorizationPolicy
    ) async throws {
        let center = UNUserNotificationCenter.current()
        try await ensureAuthorization(authorization)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let comparisonID {
            content.userInfo = [WeshNotificationPayloadKey.comparisonID: comparisonID.uuidString]
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        try await center.add(request)
    }
}

struct WeshNotificationsView: View {
    @ObservedObject var store: WeshNotificationCenterStore
    let openQuestion: (UUID) -> Void
    let refresh: () async -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty {
                    WeshEmptyState(
                        title: "لا توجد إشعارات جديدة",
                        message: "ستظهر هنا تنبيهات التصويت، تغير المتصدر، قرب انتهاء المقارنة، وتذكير متابعة التجربة.",
                        systemImage: "bell"
                    )
                    .padding(24)
                } else {
                    List {
                        ForEach(store.items) { item in
                            Button {
                                if let comparisonID = item.comparisonID {
                                    openQuestion(comparisonID)
                                }
                            } label: {
                                NotificationRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppBackground())
            .navigationTitle("الإشعارات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("تحديث") {
                        Task { await refresh() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("قراءة الكل") {
                        store.markAllRead()
                    }
                    .disabled(store.unreadCount == 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct NotificationRow: View {
    let item: WeshNotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WeshIconTile(systemImage: item.kind.systemImage, color: accent, size: 42)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(WeshTheme.primaryText)
                    Spacer(minLength: 8)
                    if !item.isRead {
                        Circle()
                            .fill(WeshTheme.accentBright)
                            .frame(width: 8, height: 8)
                            .accessibilityLabel("غير مقروء")
                    }
                }
                Text(item.body)
                    .font(.subheadline)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.kind.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accent)
            }
        }
        .padding(12)
        .background(WeshTheme.surface, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
        .overlay { RoundedRectangle(cornerRadius: WeshTheme.controlRadius).stroke(WeshTheme.hairline) }
        .accessibilityElement(children: .combine)
    }

    private var accent: Color {
        switch item.kind {
        case .voteReceived, .outcomeFollowUp: WeshTheme.accent
        case .leaderChanged, .closingSoon: WeshTheme.gold
        case .system: WeshTheme.secondaryAccent
        }
    }
}
