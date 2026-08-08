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
            BatalLog.persistence
                .error("Notification permission request failed: \(String(describing: error), privacy: .public)")
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
            GeometryReader { geometry in
                let contentWidth = min(max(geometry.size.width - 40, 0), AppTheme.maximumContentWidth)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(width: contentWidth)
                        customerAccess
                        permissionCards
                        footer
                    }
                    .frame(
                        width: contentWidth,
                        alignment: .leading
                    )
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                }
                .background(BatalDesign.canvas)
            }
            .navigationTitle(text(ar: "مرحبًا", en: "Welcome"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func header(width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            onboardingHeroImage
                .frame(width: width, height: 252)
                .clipped()

            LinearGradient(
                colors: [.black.opacity(0.82), .black.opacity(0.38), .black.opacity(0.06)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(width: width, height: 252)

            VStack(alignment: .leading, spacing: 10) {
                Label(text(ar: "بطل الدروب", en: "Batal Al-Droob"), systemImage: "car.side.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BatalDesign.brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())

                Text(text(ar: "مرحبًا في بطل الدروب", en: "Welcome to Batal Al-Droob"))
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(text(
                    ar: "ابدأ بملف بسيط لحسابك وسيارتك، ثم فعّل التنبيهات الاختيارية لطلبات القطع والصيانة.",
                    en: "Start with a simple local profile, then enable optional alerts for part requests and maintenance."
                ))
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(3)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(width: width, height: 252, alignment: .bottomLeading)
        }
        .frame(width: width, height: 252)
        .clipShape(RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
                .stroke(.white.opacity(0.14))
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var onboardingHeroImage: some View {
        if let image = bundledHeroImage(named: "patrol-y60") {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [AppColors.brandDeep, AppColors.brand, AppColors.accent.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func bundledHeroImage(named name: String) -> UIImage? {
        Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "models")
            .flatMap { UIImage(contentsOfFile: $0.path) }
            ?? Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "models")
            .flatMap { UIImage(contentsOfFile: $0.path) }
    }

    private var customerAccess: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(text(ar: "خيارات الدخول", en: "Sign-in options"), systemImage: "person.crop.circle.badge.checkmark")
                .font(.headline)

            Text(text(
                ar: "سجل بريدك أو ادخل ببريد محفوظ على هذا الجهاز قبل استخدام التطبيق. هذا ليس اشتراكًا ولا يفتح مشتريات الكتالوج.",
                en: "Register or sign in with an email saved on this device before using the app. This is not a subscription and does not unlock catalog purchases."
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)

            TextField(text(ar: "الاسم اختياري", en: "Name optional"), text: $customerName)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("onboarding.customer.name")

            TextField(text(ar: "البريد الإلكتروني", en: "Email address"), text: $customerEmail)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.continue)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("onboarding.customer.email")

            if let accountMessage {
                Text(accountMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    saveAccount(successMessage: text(ar: "تم إنشاء الحساب المحلي.", en: "Local account created."))
                } label: {
                    Label(text(ar: "تسجيل جديد", en: "Register"), systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.batalSecondary)
                .accessibilityIdentifier("onboarding.customer.register")

                Button {
                    saveAccount(successMessage: text(ar: "تم تسجيل الدخول محليًا.", en: "Signed in locally."))
                } label: {
                    Label(text(ar: "تسجيل الدخول", en: "Sign in"), systemImage: "person.crop.circle.badge.checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.batalSecondary)
                .accessibilityIdentifier("onboarding.customer.signin")
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
                    if !ensureSignedIn() {
                        return
                    }
                    await coordinator.requestRecommendedPermissions()
                    completeOnboarding()
                }
            } label: {
                if coordinator.isRequesting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label(
                        text(ar: "تسجيل وتفعيل الإشعارات", en: "Sign in and enable alerts"),
                        systemImage: "checkmark.shield"
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.batalPrimary)
            .disabled(coordinator.isRequesting)
            .accessibilityIdentifier("permissions.allow.continue")

            Button(text(ar: "تسجيل ومتابعة بدون إشعارات", en: "Sign in without alerts")) {
                if ensureSignedIn() {
                    completeOnboarding()
                }
            }
            .buttonStyle(.batalSecondary)
            .disabled(coordinator.isRequesting)
            .accessibilityIdentifier("permissions.skip")

            Text(text(
                ar: "لا يمكن دخول التطبيق بدون تسجيل بريد صحيح. نطلب الإشعارات فقط الآن ويمكن رفضها.",
                en: "A valid email is required to enter the app. We only request notifications now, and they can be denied."
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

    /// Routes through the view model so first-run copy uses the same translation table as
    /// the rest of the app. The local `language == .arabic ? ar : en` this replaced meant
    /// the entire welcome screen — the first thing a new user sees — stayed English for
    /// the eight non-Arabic languages the app ships, even when they were selected.
    private func text(ar: String, en: String) -> String {
        viewModel.text(ar: ar, en: en)
    }

    private func saveAccount(successMessage: String) {
        if viewModel.saveLocalCustomer(name: customerName, email: customerEmail) {
            accountMessage = successMessage
        } else {
            accountMessage = text(ar: "اكتب بريدًا صحيحًا للمتابعة.", en: "Enter a valid email to continue.")
        }
    }

    private func ensureSignedIn() -> Bool {
        if
            viewModel.customerProfile.hasCompletedSignInChoice,
            viewModel.isValidCustomerEmail(viewModel.customerProfile.email)
        {
            return true
        }
        if viewModel.saveLocalCustomer(name: customerName, email: customerEmail) {
            return true
        }
        accountMessage = text(ar: "اكتب بريدًا صحيحًا للمتابعة.", en: "Enter a valid email to continue.")
        return false
    }

    private func completeOnboarding() {
        guard
            viewModel.customerProfile.hasCompletedSignInChoice,
            viewModel.isValidCustomerEmail(viewModel.customerProfile.email) else { return }
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
