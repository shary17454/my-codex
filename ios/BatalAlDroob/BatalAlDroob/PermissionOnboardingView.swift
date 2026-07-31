import SwiftUI
import UserNotifications

@MainActor
final class AppPermissionCoordinator: ObservableObject {
    @Published private(set) var isRequesting = false
    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined

    init() {
        refreshNotificationStatus()
    }

    func requestRecommendedPermissions() async {
        guard !isRequesting else { return }
        isRequesting = true
        defer { isRequesting = false }

        await requestNotificationsIfNeeded()
    }

    func refreshNotificationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationStatus = settings.authorizationStatus
        }
    }

    private func requestNotificationsIfNeeded() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationStatus = settings.authorizationStatus
        guard settings.authorizationStatus == .notDetermined else { return }

        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            let updatedSettings = await UNUserNotificationCenter.current().notificationSettings()
            notificationStatus = updatedSettings.authorizationStatus
        } catch {
            BatalLog.persistence.error("Notification permission request failed: \(String(describing: error), privacy: .public)")
        }
    }

}

struct PermissionOnboardingView: View {
    @Bindable var viewModel: CatalogViewModel
    let complete: () -> Void
    @StateObject private var coordinator = AppPermissionCoordinator()
    @State private var customerName = ""
    @State private var customerEmail = ""
    @State private var accountMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    customerAccess
                    permissionCards
                    footer
                }
                .frame(maxWidth: AppTheme.maximumContentWidth, alignment: .leading)
                .padding(20)
            }
            .background(BatalDesign.canvas)
            .navigationTitle(text(ar: "إعداد الأذونات", en: "Permissions"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(text(ar: "ليس الآن", en: "Not now")) {
                        completeOnboarding()
                    }
                    .disabled(coordinator.isRequesting)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(BatalDesign.brand)
                .frame(width: 58, height: 58)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))

            Text(text(ar: "فعّل بطل الدروب بكامل قدرته", en: "Enable Batal Al-Droob fully"))
                .font(.largeTitle.bold())
                .lineLimit(3)
                .minimumScaleFactor(0.72)

            Text(text(
                ar: "نطلب الأذونات مرة واحدة عند أول تشغيل حتى تعمل التنبيهات والمزايا القريبة والقياس الاختياري بوضوح. يمكنك رفض أي إذن وتغييره لاحقًا من إعدادات iOS.",
                en: "We ask once on first launch so alerts, nearby features, and optional measurement are clear. You can deny any permission and change it later in iOS Settings."
            ))
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var customerAccess: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(text(ar: "خيارات الدخول", en: "Sign-in options"), systemImage: "person.crop.circle.badge.checkmark")
                .font(.headline)

            Text(text(
                ar: "يمكنك البدء كضيف، أو حفظ بريدك محليًا على هذا الجهاز لتخصيص الطلبات لاحقًا. هذا ليس اشتراكًا ولا يفتح مشتريات الكتالوج.",
                en: "Start as a guest, or save your email locally on this device for later request personalization. This is not a subscription and does not unlock catalog purchases."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)

            TextField(text(ar: "الاسم اختياري", en: "Name optional"), text: $customerName)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("onboarding.customer.name")

            TextField(text(ar: "البريد الإلكتروني اختياري", en: "Email optional"), text: $customerEmail)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("onboarding.customer.email")

            if let accountMessage {
                Text(accountMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.continueAsGuest()
                    accountMessage = text(ar: "تم اختيار الدخول كضيف.", en: "Guest access selected.")
                } label: {
                    Label(text(ar: "متابعة كضيف", en: "Continue as guest"), systemImage: "person")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.batalSecondary)
                .accessibilityIdentifier("onboarding.customer.guest")

                Button {
                    if viewModel.saveLocalCustomer(name: customerName, email: customerEmail) {
                        accountMessage = text(ar: "تم حفظ البريد على هذا الجهاز.", en: "Email saved on this device.")
                    } else {
                        accountMessage = text(ar: "اكتب بريدًا صحيحًا أو تابع كضيف.", en: "Enter a valid email or continue as guest.")
                    }
                } label: {
                    Label(text(ar: "حفظ البريد", en: "Save email"), systemImage: "envelope")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.batalSecondary)
                .accessibilityIdentifier("onboarding.customer.email.save")
            }
        }
        .padding(14)
        .background(BatalDesign.surface, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: BatalDesign.cardRadius)
                .stroke(BatalDesign.border)
        )
    }

    private var permissionCards: some View {
        VStack(spacing: 12) {
            PermissionExplanationCard(
                symbol: "bell.badge",
                title: text(ar: "الإشعارات", en: "Notifications"),
                detail: text(
                    ar: "لتذكيرك بطلبات القطع، تحديثات الصيانة، والتنبيهات المهمة داخل التطبيق.",
                    en: "For part request reminders, maintenance updates, and important in-app alerts."
                ),
                status: notificationStatusText
            )

            PermissionExplanationCard(
                symbol: "location.fill",
                title: text(ar: "الموقع", en: "Location"),
                detail: text(
                    ar: "لا يطلب بطل الدروب إذن الموقع حاليًا لأن التطبيق لا يحتوي ميزة خريطة أو تتبع موقع. سيُطلب لاحقًا فقط عند إضافة ميزة واضحة تحتاجه.",
                    en: "Batal Al-Droob does not request location now because the app has no map or location tracking feature. It will be requested later only for a clear feature that needs it."
                ),
                status: text(ar: "غير مطلوب حاليًا", en: "Not currently needed")
            )

            PermissionExplanationCard(
                symbol: "scope",
                title: text(ar: "التتبع", en: "Tracking"),
                detail: text(
                    ar: "بطل الدروب لا يتتبعك عبر التطبيقات والمواقع، لذلك لا نعرض طلب تتبع من النظام في هذا الإصدار.",
                    en: "Batal Al-Droob does not track you across apps and websites, so this version does not show a system tracking prompt."
                ),
                status: text(ar: "غير مستخدم", en: "Not used")
            )
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    if !viewModel.customerProfile.hasCompletedSignInChoice {
                        viewModel.continueAsGuest()
                    }
                    await coordinator.requestRecommendedPermissions()
                    completeOnboarding()
                }
            } label: {
                if coordinator.isRequesting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label(text(ar: "السماح والمتابعة", en: "Allow and continue"), systemImage: "checkmark.shield")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.batalPrimary)
            .disabled(coordinator.isRequesting)
            .accessibilityIdentifier("permissions.allow.continue")

            Button(text(ar: "المتابعة بدون تفعيل", en: "Continue without enabling")) {
                completeOnboarding()
            }
            .buttonStyle(.batalSecondary)
            .disabled(coordinator.isRequesting)
            .accessibilityIdentifier("permissions.skip")

            Text(text(
                ar: "نطلب الإشعارات فقط الآن. أي إذن إضافي يجب أن يكون مرتبطًا بميزة فعلية وواضحة داخل التطبيق.",
                en: "We only request notifications now. Any additional permission must be tied to a real, clear in-app feature."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

    private var notificationStatusText: String {
        switch coordinator.notificationStatus {
        case .notDetermined: return text(ar: "لم يُطلب بعد", en: "Not requested")
        case .denied: return text(ar: "مرفوض", en: "Denied")
        case .authorized, .provisional, .ephemeral: return text(ar: "مفعّل", en: "Enabled")
        @unknown default: return text(ar: "غير معروف", en: "Unknown")
        }
    }

    private func text(ar: String, en: String) -> String {
        viewModel.language == .arabic ? ar : en
    }

    private func completeOnboarding() {
        if !viewModel.customerProfile.hasCompletedSignInChoice {
            viewModel.continueAsGuest()
        }
        complete()
    }
}

private struct PermissionExplanationCard: View {
    let symbol: String
    let title: String
    let detail: String
    let status: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(BatalDesign.brand)
                .frame(width: 42, height: 42)
                .background(BatalDesign.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.control))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                    Spacer(minLength: 8)
                    Text(status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: Capsule())
                }

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(BatalDesign.surface, in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: BatalDesign.cardRadius)
                .stroke(BatalDesign.border)
        )
        .accessibilityElement(children: .combine)
    }
}
