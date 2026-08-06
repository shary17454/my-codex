import SwiftUI
import UIKit

enum AppTab: Hashable {
    case home
    case map
    case compass
    case planner
    case community
    case tools
}

enum ScreenshotConfiguration {
    private static let environment = ProcessInfo.processInfo.environment

    static var initialTab: AppTab {
        switch environment["DESERTTRAIL_SCREENSHOT_TAB"]?.lowercased() {
        case "home":
            return .home
        case "map":
            return .map
        case "compass":
            return .compass
        case "planner":
            return .planner
        case "community":
            return .community
        case "tools":
            return .tools
        default:
            return .home
        }
    }

    static var initialMapLayer: DesertMapLayer {
        switch environment["DESERTTRAIL_MAP_LAYER"]?.lowercased() {
        case "ajaji":
            return .ajaji
        case "marked", "markedplans", "plans":
            return .markedPlans
        default:
            return .satellite
        }
    }

    static var initialAjajiImageIndex: Int {
        Int(environment["DESERTTRAIL_AJAJI_INDEX"] ?? "") ?? 1
    }

    static var showTripQR: Bool {
        environment["DESERTTRAIL_SHOW_QR"] == "1"
    }

    static var showActiveDrive: Bool {
        environment["DESERTTRAIL_SHOW_ACTIVE_DRIVE"] == "1"
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = ScreenshotConfiguration.initialTab

    var body: some View {
        Group {
            if appState.acceptedTermsAndPrivacy {
                mainTabs
            } else {
                FirstLaunchConsentView()
            }
        }
        .tint(.trailSignal)
        .environment(\.layoutDirection, appState.language == .arabic ? .rightToLeft : .leftToRight)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeDashboardView(selectedTab: $selectedTab)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label(appState.language == .arabic ? "الرئيسية" : "Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            NavigationStack {
                DesertMapView()
                    .navigationTitle(appState.text(.appTitle))
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            LanguagePicker(appState: appState)
                        }
                    }
            }
            .tabItem {
                Label(appState.text(.map), systemImage: "map")
            }
            .tag(AppTab.map)

            NavigationStack {
                CompassPanel()
                    .navigationTitle(appState.text(.compass))
            }
            .tabItem {
                Label(appState.text(.compass), systemImage: "safari")
            }
            .tag(AppTab.compass)

            NavigationStack {
                PlannerView()
                    .navigationTitle(appState.text(.planner))
            }
            .tabItem {
                Label(appState.language == .arabic ? "الرحلات" : "Trips", systemImage: "briefcase")
            }
            .tag(AppTab.planner)

            NavigationStack {
                CommunityView()
                    .navigationTitle(appState.text(.community))
            }
            .tabItem {
                Label(appState.text(.community), systemImage: "person.3")
            }
            .tag(AppTab.community)

            NavigationStack {
                AdvancedToolsView()
                    .navigationTitle(appState.language == .arabic ? "الأدوات" : "Tools")
            }
            .tabItem {
                Label(appState.language == .arabic ? "الأدوات" : "Tools", systemImage: "square.grid.2x2")
            }
            .tag(AppTab.tools)
        }
        .toolbarBackground(tabBarBackground, for: .tabBar)
        .toolbarColorScheme(tabBarColorScheme, for: .tabBar)
    }

    private var tabBarBackground: Color {
        colorScheme == .dark ? .trailBase : Color(.systemBackground)
    }

    private var tabBarColorScheme: ColorScheme {
        colorScheme == .dark ? .dark : .light
    }
}

private struct FirstLaunchConsentView: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var acceptedTerms = false
    @State private var requestedLocation = false
    @State private var requestedNotifications = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                termsCard
                permissionsCard
                privacyCard
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 36)
        }
        .background(consentBackground.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color.trailAmber)
                .accessibilityHidden(true)

            Text("خرايم")
                .font(.largeTitle.bold())
                .foregroundStyle(primaryText)

            Text("قبل بدء الملاحة، راجع شروط الاستخدام واختر الأذونات التي تحتاجها للرحلات والتنبيهات.")
                .font(.body)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var termsCard: some View {
        ConsentCard(title: "شروط الاستخدام", icon: "doc.text.fill") {
            consentRow("استخدم التطبيق كأداة مساعدة للملاحة البرية، ولا تعتمد عليه وحده في السلامة أو الطوارئ.")
            consentRow("دقة الموقع، البوصلة، الطقس، وجودة الهواء تعتمد على حساسات الجهاز والاتصال بالخدمات.")
            consentRow("الخرائط غير المتصلة تحفظ مناطق مرجعية ولا تستبدل الخرائط الرسمية أو تعليمات الجهات المختصة.")
            consentRow("أنت مسؤول عن التحقق من حالة الطريق والتصاريح والطقس قبل الرحلة.")

            Toggle(isOn: $acceptedTerms) {
                Text("أوافق على شروط الاستخدام والخصوصية")
                    .font(.headline)
                    .foregroundStyle(primaryText)
            }
            .toggleStyle(.switch)
            .padding(.top, 6)
        }
    }

    private var permissionsCard: some View {
        ConsentCard(title: "الأذونات المطلوبة", icon: "hand.raised.fill") {
            permissionRow(
                title: "الموقع وتتبع الرحلة",
                detail: "يُستخدم موقعك لحساب المسافة والاتجاه والارتفاع وتشغيل تنبيهات القرب أثناء الرحلة.",
                icon: "location.fill",
                isDone: requestedLocation || appState.locationManager.authorizationStatus != .notDetermined
            ) {
                requestedLocation = true
                appState.locationManager.requestNavigationAccessAndStart(userInitiated: true)
            }

            permissionRow(
                title: "الإشعارات",
                detail: "تُستخدم للتنبيه عند الاقتراب من أودية أو مناطق تحتاج انتباهًا، وعند تنبيهات الرحلة المهمة.",
                icon: "bell.badge.fill",
                isDone: requestedNotifications
            ) {
                requestedNotifications = true
                appState.locationManager.requestNotificationAccess()
            }

            permissionRow(
                title: "الموقع الدائم اختياري",
                detail: "لا يُطلب إلا عند تفعيل تنبيهات القرب في الخلفية. يمكنك رفضه واستخدام التطبيق أثناء التشغيل فقط.",
                icon: "location.circle.fill",
                isDone: appState.locationManager.authorizationStatus == .authorizedAlways
            ) {
                requestedLocation = true
                appState.locationManager.requestBackgroundTripUpdates()
            }
        }
    }

    private var privacyCard: some View {
        ConsentCard(title: "الخصوصية", icon: "lock.shield.fill") {
            consentRow("لا يستخدم خرايم تتبعًا إعلانيًا عبر التطبيقات أو المواقع الأخرى.")
            consentRow("بيانات الرحلات والمواقع تُحفظ محليًا على الجهاز، ولا تُشارك إلا عند اختيارك المشاركة.")
            consentRow("يمكنك تغيير صلاحيات الموقع والإشعارات لاحقًا من إعدادات iOS.")
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                appState.acceptTermsAndPrivacy()
            } label: {
                Label("الدخول إلى التطبيق", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!acceptedTerms)

            Button {
                appState.language = appState.language == .arabic ? .english : .arabic
            } label: {
                Label(appState.language == .arabic ? "English" : "العربية", systemImage: "globe")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .accessibilityElement(children: .contain)
    }

    private func consentRow(_ text: String) -> some View {
        Label {
            Text(text)
                .font(.callout)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.trailSignal)
        }
    }

    private func permissionRow(
        title: String,
        detail: String,
        icon: String,
        isDone: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.trailAmber)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(primaryText)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            Button {
                action()
            } label: {
                Label(isDone ? "تم الطلب" : "طلب الإذن", systemImage: isDone ? "checkmark.circle.fill" : "arrow.up.forward.app.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isDone)
        }
        .padding(.vertical, 4)
    }

    private var consentBackground: Color {
        colorScheme == .dark ? .trailBase : Color(.systemGroupedBackground)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.72) : .secondary
    }
}

private struct ConsentCard<Content: View>: View {
    var title: String
    var icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
                .foregroundStyle(.primary)

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }
}

private struct LanguagePicker: View {
    @Bindable var appState: AppState

    var body: some View {
        Menu {
            Picker("Language", selection: $appState.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
        } label: {
            Image(systemName: "globe")
                .font(.headline.weight(.semibold))
                .accessibilityLabel("Language")
        }
    }
}

extension Color {
    static let desertSand = Color(red: 0.86, green: 0.69, blue: 0.39)
    static let desertCopper = Color(red: 0.78, green: 0.40, blue: 0.16)
    static let desertRock = Color(red: 0.20, green: 0.17, blue: 0.14)
    static let oasisTeal = Color(red: 0.02, green: 0.55, blue: 0.58)
    static let trailBase = Color(red: 0.025, green: 0.035, blue: 0.040)
    static let trailNight = Color(red: 0.035, green: 0.055, blue: 0.060)
    static let trailSignal = Color(red: 0.09, green: 0.78, blue: 0.74)
    static let trailAmber = Color(red: 0.92, green: 0.54, blue: 0.18)
    static let trailMist = Color(red: 0.88, green: 0.94, blue: 0.91)
}
