import OSLog
import SwiftData
import SwiftUI

@main
struct StudyVaultApp: App {
    @UIApplicationDelegateAdaptor(WeshNotificationAppDelegate.self) private var notificationDelegate
    private let persistence: WeshPersistenceStore?

    init() {
        do {
            persistence = WeshPersistenceStore(container: try WeshPersistenceStore.makeContainer())
        } catch {
            Logger(subsystem: "com.shary17454.esal", category: "AppLaunch")
                .error("SwiftData setup failed: \(error.localizedDescription, privacy: .private)")
            persistence = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let persistence {
                WeshRootExperience(persistence: persistence)
                    .modelContainer(persistence.container)
            } else {
                PersistenceUnavailableView()
            }
        }
    }
}

private struct WeshRootExperience: View {
    private enum Phase {
        case splash
        case onboarding
        case application
    }

    @AppStorage("wesh.onboarding.completed") private var completedOnboarding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .splash
    let persistence: WeshPersistenceStore

    private var skipsLaunchExperience: Bool {
        ProcessInfo.processInfo.arguments.contains("-WeshSkipOnboarding")
    }

    var body: some View {
        Group {
            if skipsLaunchExperience {
                ContentView(persistence: persistence)
            } else {
                switch phase {
                case .splash:
                    WeshSplashView()
                        .transition(.opacity)
                case .onboarding:
                    WeshOnboardingView {
                        completedOnboarding = true
                        move(to: .application)
                    }
                    .transition(.opacity)
                case .application:
                    ContentView(persistence: persistence)
                        .transition(.opacity)
                }
            }
        }
        .task {
            WeshTipConfiguration.configure()
        }
        .task {
            guard !skipsLaunchExperience, phase == .splash else { return }
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 450 : 1250))
            guard !Task.isCancelled else { return }
            move(to: completedOnboarding ? .application : .onboarding)
        }
    }

    private func move(to nextPhase: Phase) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.32)) {
            phase = nextPhase
        }
    }
}

private struct PersistenceUnavailableView: View {
    var body: some View {
        ZStack {
            AppBackground()
            WeshEmptyState(
                title: "تعذر فتح بياناتك المحلية",
                message: "لم نحذف أي بيانات. أغلق التطبيق وافتحه مرة أخرى، وإذا استمرت المشكلة حدّث النظام ثم حاول.",
                systemImage: "externaldrive.badge.exclamationmark"
            )
            .padding(24)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

private struct WeshSplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.043, green: 0.055, blue: 0.075), Color(red: 0.065, green: 0.082, blue: 0.11)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                WeshBrandMark(size: 86)
                    .scaleEffect(isVisible ? 1 : 0.88)
                VStack(spacing: 8) {
                    Text("وش الرأي")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    Text("قرارك أوضح.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WeshTheme.goldBright)
                }
            }
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.45)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("وش الرأي. قرارك أوضح.")
    }
}

private struct WeshOnboardingView: View {
    fileprivate struct Page: Identifiable {
        let id: Int
        let title: String
        let message: String
        let systemImage: String
        let accent: Color
    }

    let completion: () -> Void
    @State private var pageIndex = 0

    private let pages = [
        Page(
            id: 0,
            title: "اسأل وقارن بسهولة",
            message: "أنشئ مقارنة بين منتجات أو خدمات أو خيارات، وشاركها مع الآخرين خلال ثوانٍ.",
            systemImage: "rectangle.2.swap",
            accent: WeshTheme.accent
        ),
        Page(
            id: 1,
            title: "افهم سبب الاختيار",
            message: "لا تكتفِ بنسبة التصويت. تعرّف على أبرز الأسباب ونقاط القوة والضعف لكل خيار.",
            systemImage: "quote.bubble.fill",
            accent: WeshTheme.secondaryAccent
        ),
        Page(
            id: 2,
            title: "خذ قرارًا أوضح",
            message: "يحوّل التطبيق الأصوات والأسباب إلى خلاصة مبسطة تساعدك على رؤية الصورة كاملة.",
            systemImage: "checkmark.seal.fill",
            accent: WeshTheme.gold
        )
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
                HStack {
                    WeshBrandMark(size: 48)
                    Text("وش الرأي")
                        .font(.title2.weight(.bold))
                    Spacer()
                    if pageIndex < pages.count - 1 {
                        Button("تخطي", action: completion)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WeshTheme.secondaryText)
                    }
                }
                .padding(.horizontal, WeshTheme.horizontalPadding)
                .padding(.top, 12)

                TabView(selection: $pageIndex) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                            .padding(.horizontal, WeshTheme.horizontalPadding)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == pageIndex ? WeshTheme.accent : WeshTheme.hairline)
                            .frame(width: index == pageIndex ? 28 : 8, height: 8)
                            .animation(.easeOut(duration: 0.2), value: pageIndex)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("الصفحة \(pageIndex + 1) من \(pages.count)")

                VStack(spacing: 12) {
                    Button {
                        if pageIndex == pages.count - 1 {
                            completion()
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                pageIndex += 1
                            }
                        }
                    } label: {
                        Text(pageIndex == pages.count - 1 ? "ابدأ الآن" : "التالي")
                    }
                    .buttonStyle(WeshPrimaryButtonStyle())

                    Text("يمكنك استخدام التطبيق دون تسجيل الدخول.")
                        .font(.footnote)
                        .foregroundStyle(WeshTheme.secondaryText)
                }
                .padding(.horizontal, WeshTheme.horizontalPadding)
                .padding(.bottom, 18)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

private struct OnboardingPageView: View {
    let page: WeshOnboardingView.Page

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            ZStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(page.accent.opacity(0.12))
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(page.accent.opacity(0.22), lineWidth: 1)
                Image(systemName: page.systemImage)
                    .font(.system(size: 76, weight: .semibold))
                    .foregroundStyle(page.accent)
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(maxWidth: 330, maxHeight: 330)
            .aspectRatio(1, contentMode: .fit)
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.title3)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
        }
        .weshContentWidth(alignment: .center)
        .accessibilityElement(children: .combine)
    }
}
