import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var userSession: UserSession
    let statistics: DashboardStatistics
    @Binding var isBackendEnabled: Bool
    @Binding var backendBaseURLText: String
    @Binding var backendAPITokenText: String
    let adminOverview: AdminOverview?
    let saveBackendSettings: () -> Void
    let refreshBackend: () -> Void
    let refreshAdminOverview: () -> Void

    @State private var alias = ""
    @State private var selectedInterests: Set<AskCategory> = []
    @State private var savedAliasFeedback = false

    private let interestsKey = "wash_alray_user_interests"

    private var isAliasValid: Bool {
        !alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                accountHero
                AccountStatisticsCard(statistics: statistics)
                WeshAppleFeaturesCard()
                WeshPlusCard(hasOwnerAccess: userSession.hasOwnerAccess)
                if userSession.hasOwnerAccess {
                    AdminOperationsCard(overview: adminOverview, refresh: refreshAdminOverview)
                }
                publicIdentityCard
                interestsCard
                privacyCard

                #if DEBUG
                developmentBackendCard
                #endif

                if userSession.isSignedIn {
                    Button(role: .destructive) {
                        userSession.signOut()
                        alias = userSession.displayName
                    } label: {
                        Label("تسجيل الخروج", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .buttonStyle(WeshSecondaryButtonStyle())
                }
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 18)
            .weshContentWidth()
        }
        .background(AppBackground())
        .navigationTitle("الحساب")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            alias = userSession.displayName
            loadInterests()
        }
        .sensoryFeedback(.success, trigger: savedAliasFeedback)
    }

    private var accountHero: some View {
        VStack(spacing: 16) {
            if userSession.isSignedIn {
                Text(String(userSession.publicName.prefix(1)))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 82, height: 82)
                    .background(WeshTheme.heroGradient, in: Circle())
                    .overlay { Circle().stroke(WeshTheme.accentBright.opacity(0.5), lineWidth: 2) }

                VStack(spacing: 5) {
                    Text(userSession.publicName)
                        .font(.title.weight(.bold))
                    Label("تم تسجيل الدخول باستخدام Apple", systemImage: "apple.logo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WeshTheme.accent)
                    if userSession.hasOwnerAccess {
                        Label("حساب المالك: كل الوظائف مفعّلة بدون اشتراك", systemImage: "crown.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WeshTheme.gold)
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("حساب المالك، كل الوظائف مفعلة بدون اشتراك")
                    }
                }
            } else {
                WeshBrandMark(size: 72)
                VStack(spacing: 6) {
                    Text("احفظ تفضيلاتك")
                        .font(.title2.weight(.bold))
                    Text("سجّل الدخول لحفظ هويتك العامة وإدارة تفضيلاتك. يمكنك استخدام معظم التطبيق دون حساب.")
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    if case .success(let authorization) = result,
                       let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        userSession.completeSignIn(with: credential)
                        alias = userSession.displayName
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                Text("يمكنك استخدام التطبيق دون تسجيل الدخول.")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .weshSurface(emphasized: true, goldAccent: userSession.isSignedIn)
    }

    private var publicIdentityCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            WeshSectionHeader(
                "الاسم العام",
                subtitle: "الاسم الذي سيظهر للآخرين",
                systemImage: "person.text.rectangle"
            )
            TextField("مثال: خبير التقنية", text: $alias)
                .textContentType(.nickname)
                .weshField()

            Button {
                userSession.updateAlias(alias)
                savedAliasFeedback.toggle()
            } label: {
                Label("حفظ الاسم", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(WeshPrimaryButtonStyle())
            .disabled(!isAliasValid || alias.trimmingCharacters(in: .whitespacesAndNewlines) == userSession.displayName)

            Text("يمكنك النشر باسمك أو بصورة مجهولة عند إنشاء كل مقارنة.")
                .font(.footnote)
                .foregroundStyle(WeshTheme.secondaryText)
        }
        .weshSurface()
    }

    private var interestsCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            WeshSectionHeader(
                "اهتماماتي",
                subtitle: "اختر التصنيفات الأقرب لقراراتك",
                systemImage: "heart.text.square"
            )
            InterestPicker(selection: $selectedInterests, toggle: toggleInterest)

            if selectedInterests.isEmpty {
                Text("لم تحدد اهتمامات بعد.")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
            } else {
                Text("المحدد: \(selectedInterests.map(\.title).sorted().joined(separator: "، "))")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .weshSurface()
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader(
                "الخصوصية",
                subtitle: "وضوح في ما يُحفظ وما يظهر للآخرين",
                systemImage: "lock.shield.fill"
            )
            AccountPrivacyRow(icon: "person.crop.circle", title: "الاسم العام", detail: "يمكن تغييره أو إخفاؤه عند النشر.")
            AccountPrivacyRow(icon: "key.fill", title: "بيانات Apple", detail: "المعرّف والبريد محفوظان بأمان في Keychain ولا يظهران للمستخدمين.")
            AccountPrivacyRow(icon: "internaldrive.fill", title: "المسودات والاهتمامات", detail: "تُحفظ محليًا على هذا الجهاز.")
        }
        .weshSurface()
    }

    #if DEBUG
    private var developmentBackendCard: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("تفعيل المزامنة مع الخادم", isOn: $isBackendEnabled)
                    .tint(WeshTheme.accent)
                TextField("مثال: http://localhost:8787", text: $backendBaseURLText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .weshField()
                SecureField("API token للتطوير أو الاختبار", text: $backendAPITokenText)
                    .textInputAutocapitalization(.never)
                    .weshField()
                HStack(spacing: 10) {
                    Button("حفظ") { saveBackendSettings() }
                        .buttonStyle(WeshPrimaryButtonStyle())
                    Button("مزامنة") {
                        saveBackendSettings()
                        refreshBackend()
                    }
                    .buttonStyle(WeshSecondaryButtonStyle())
                }
                WeshStatusBanner(
                    text: "هذه الإعدادات للتطوير والاختبار الداخلي فقط ولا تظهر في نسخة Release.",
                    kind: .warning
                )
            }
            .padding(.top, 12)
        } label: {
            Label("إعدادات خادم التطوير", systemImage: "server.rack")
                .font(.headline)
        }
        .weshSurface()
    }
    #endif

    private func toggleInterest(_ category: AskCategory) {
        if selectedInterests.contains(category) {
            selectedInterests.remove(category)
        } else {
            selectedInterests.insert(category)
        }
        UserDefaults.standard.set(selectedInterests.map(\.rawValue), forKey: interestsKey)
    }

    private func loadInterests() {
        let rawValues = UserDefaults.standard.stringArray(forKey: interestsKey) ?? []
        selectedInterests = Set(rawValues.compactMap(AskCategory.init(rawValue:)))
    }
}

private struct AccountStatisticsCard: View {
    let statistics: DashboardStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            WeshSectionHeader("لوحتك الشخصية", systemImage: "chart.bar.xaxis")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                WeshMetricTile(title: "مقارنات", value: "\(statistics.totalComparisons)", systemImage: "bubble.left.and.bubble.right.fill", color: WeshTheme.accent)
                WeshMetricTile(title: "تصويتًا", value: "\(statistics.totalVotes)", systemImage: "chart.bar.fill", color: WeshTheme.secondaryAccent)
                WeshMetricTile(title: "أسباب", value: "\(statistics.totalReasons)", systemImage: "quote.bubble.fill", color: WeshTheme.gold)
                WeshMetricTile(title: "محفوظة", value: "\(statistics.savedCount)", systemImage: "bookmark.fill", color: WeshTheme.accentBright)
            }
        }
        .weshSurface(goldAccent: true)
    }
}

private struct AccountPrivacyRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            WeshIconTile(systemImage: icon, color: WeshTheme.accent, size: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AdminOperationsCard: View {
    let overview: AdminOverview?
    let refresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WeshSectionHeader(
                "لوحة الإدارة",
                subtitle: "مراقبة البلاغات والنشاط والتشغيل لحساب المالك.",
                systemImage: "wrench.and.screwdriver.fill"
            )

            if let overview {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                    WeshMetricTile(title: "مقارنات", value: "\(overview.comparisons)", systemImage: "bubble.left.and.bubble.right.fill", color: WeshTheme.accent)
                    WeshMetricTile(title: "أصوات", value: "\(overview.votes)", systemImage: "chart.bar.fill", color: WeshTheme.secondaryAccent)
                    WeshMetricTile(title: "بلاغات مفتوحة", value: "\(overview.openReports)", systemImage: "exclamationmark.bubble.fill", color: WeshTheme.destructive)
                    WeshMetricTile(title: "أجهزة", value: "\(overview.devices)", systemImage: "iphone", color: WeshTheme.gold)
                    WeshMetricTile(title: "تنبيهات", value: "\(overview.queuedNotifications)", systemImage: "bell.badge.fill", color: WeshTheme.accentBright)
                    WeshMetricTile(title: "محظورون", value: "\(overview.blockedClients)", systemImage: "hand.raised.fill", color: WeshTheme.destructive)
                }
            } else {
                WeshStatusBanner(
                    text: "اربط Backend ثم حدّث لوحة الإدارة لقراءة مؤشرات التشغيل.",
                    kind: .information
                )
            }

            Button {
                refresh()
            } label: {
                Label("تحديث لوحة الإدارة", systemImage: "arrow.clockwise")
            }
            .buttonStyle(WeshSecondaryButtonStyle())
        }
        .weshSurface(goldAccent: true)
    }
}

struct InterestPicker: View {
    @Binding var selection: Set<AskCategory>
    let toggle: (AskCategory) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 8)], spacing: 8) {
            ForEach(AskCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                let isSelected = selection.contains(category)
                Button {
                    toggle(category)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: category.systemImage)
                        Text(category.title).lineLimit(1)
                        Spacer(minLength: 0)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .accessibilityHidden(true)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .foregroundStyle(isSelected ? .white : WeshTheme.primaryText)
                    .background(
                        isSelected ? WeshTheme.categoryColor(category) : WeshTheme.elevatedSurface,
                        in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: WeshTheme.compactRadius)
                            .stroke(isSelected ? WeshTheme.categoryColor(category) : WeshTheme.hairline)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
