import AVFoundation
import SwiftUI
import UserNotifications

struct WeshPermissionsOnboardingView: View {
    let completion: () -> Void

    @StateObject private var coordinator = WeshPermissionCoordinator()

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    VStack(spacing: 12) {
                        PermissionPurposeCard(
                            systemImage: "bell.badge.fill",
                            title: "الإشعارات",
                            message: "نطلبها فقط عندما تختار تذكيرًا لنتيجة مقارنة أو متابعة قرار.",
                            status: coordinator.notificationStatusText,
                            accent: WeshTheme.accent
                        )

                        PermissionPurposeCard(
                            systemImage: "camera.fill",
                            title: "الكاميرا",
                            message: "نطلبها فقط عند فتح كاميرا القرار لتحويل صورة منتج أو إعلان إلى مسودة قابلة للتعديل.",
                            status: coordinator.cameraStatusText,
                            accent: WeshTheme.gold
                        )

                        PermissionPurposeCard(
                            systemImage: "lock.shield.fill",
                            title: "الخصوصية",
                            message: "لا نطلب الموقع ولا تتبع التطبيقات في هذه النسخة، ولا نرفع صور الكاميرا إلى خادم.",
                            status: "محمي",
                            accent: WeshTheme.secondaryAccent
                        )
                    }

                    WeshStatusBanner(
                        text: "يمكنك استخدام التطبيق الآن. أي إذن سيظهر لاحقًا في لحظة استخدام الميزة المرتبطة به فقط.",
                        kind: .information
                    )

                    VStack(spacing: 12) {
                        Button {
                            completion()
                        } label: {
                            Label("الدخول للتطبيق", systemImage: "arrow.left.circle.fill")
                        }
                        .buttonStyle(WeshPrimaryButtonStyle())

                        Button("إعدادها لاحقًا") {
                            completion()
                        }
                        .font(.headline)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .frame(maxWidth: .infinity, minHeight: 48)
                    }
                }
                .weshContentWidth()
                .padding(.horizontal, WeshTheme.horizontalPadding)
                .padding(.vertical, 24)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .task {
            await coordinator.refreshStatuses()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            WeshBrandMark(size: 58, usesGold: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("خلّ التجربة أذكى من البداية")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(WeshTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("نشرح الأذونات بوضوح، ولا نطلب أي إذن إلا عند استخدام الميزة التي تحتاجه.")
                    .font(.title3)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PermissionPurposeCard: View {
    let systemImage: String
    let title: String
    let message: String
    let status: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            WeshIconTile(systemImage: systemImage, color: accent, size: 48)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(WeshTheme.primaryText)
                    Spacer(minLength: 8)
                    Text(status)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(accent.opacity(0.12), in: Capsule())
                }

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .weshSurface(padding: 16)
        .accessibilityElement(children: .combine)
    }
}

@MainActor
final class WeshPermissionCoordinator: NSObject, ObservableObject {
    @Published private(set) var notificationStatusText = "لم يطلب"
    @Published private(set) var cameraStatusText = "لم تطلب"

    func refreshStatuses() async {
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatusText = Self.notificationText(for: notificationSettings.authorizationStatus)
        cameraStatusText = Self.cameraText(for: AVCaptureDevice.authorizationStatus(for: .video))
    }

    private static func notificationText(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: "عند الحاجة"
        case .denied: "مرفوض"
        case .authorized, .provisional, .ephemeral: "مفعل"
        @unknown default: "غير معروف"
        }
    }

    private static func cameraText(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: "عند الاستخدام"
        case .restricted, .denied: "مرفوض"
        case .authorized: "مفعلة"
        @unknown default: "غير معروف"
        }
    }
}
