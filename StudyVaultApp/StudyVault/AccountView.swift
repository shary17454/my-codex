import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @ObservedObject var userSession: UserSession
    let statistics: DashboardStatistics
    @Binding var isBackendEnabled: Bool
    @Binding var backendBaseURLText: String
    @Binding var backendAPITokenText: String
    let saveBackendSettings: () -> Void
    let refreshBackend: () -> Void
    @State private var alias = ""
    @State private var selectedInterests: Set<AskCategory> = []

    private let interestsKey = "wash_alray_user_interests"

    private var isAliasValid: Bool {
        !alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        WeshIconTile(
                            systemImage: userSession.isSignedIn ? "checkmark.seal.fill" : "person.crop.circle.badge.plus",
                            color: WeshTheme.accent,
                            size: 48
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(userSession.isSignedIn ? "حسابك جاهز" : "تسجيل الدخول")
                                .font(.title2.weight(.black))
                            Text("استخدم اسمًا مستعارًا يظهر للناس عند السؤال أو التصويت.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if userSession.isSignedIn {
                        Label("تم تسجيل الدخول عبر Apple", systemImage: "apple.logo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WeshTheme.accent)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            if case .success(let authorization) = result,
                               let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                userSession.completeSignIn(with: credential)
                                alias = userSession.displayName
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
                    }
                }
                .weshSurface(emphasized: true)

                VStack(alignment: .leading, spacing: 14) {
                    Text("الاسم الظاهر")
                        .font(.title3.weight(.bold))
                    TextField("مثال: خبير التقنية", text: $alias)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        userSession.updateAlias(alias)
                    } label: {
                        Label("حفظ الاسم المستعار", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isAliasValid)

                    Text("الاسم الحقيقي والبريد لا يظهران للمستخدمين. التعليقات والأسئلة تستخدم الاسم المستعار فقط.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .weshSurface()

                #if DEBUG
                VStack(alignment: .leading, spacing: 12) {
                    Text("إعدادات خادم التطوير")
                        .font(.title3.weight(.bold))
                    Toggle("تفعيل المزامنة مع الخادم", isOn: $isBackendEnabled)
                    TextField("مثال: http://localhost:8787", text: $backendBaseURLText)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .textFieldStyle(.roundedBorder)
                    SecureField("API token للتطوير أو الاختبار", text: $backendAPITokenText)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button {
                            saveBackendSettings()
                        } label: {
                            Label("حفظ الإعداد", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            saveBackendSettings()
                            refreshBackend()
                        } label: {
                            Label("مزامنة", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("عند إيقافه يعمل التطبيق محليًا. عند تفعيله يرسل إنشاء المقارنات والتصويت والتعليقات إلى Backend المحدد.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("لا تستخدم رمزًا ثابتًا داخل نسخة App Store كبديل لتسجيل دخول المستخدمين. هذا الحقل مناسب للتطوير والاختبار الداخلي فقط.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .weshSurface()
                #endif

                VStack(alignment: .leading, spacing: 12) {
                    Text("لوحتك الشخصية")
                        .font(.title3.weight(.bold))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 10)], spacing: 10) {
                        InsightMetric(title: "المقارنات", value: "\(statistics.totalComparisons)", icon: "bubble.left.and.bubble.right.fill", color: WeshTheme.accent)
                        InsightMetric(title: "الأصوات", value: "\(statistics.totalVotes)", icon: "chart.bar.fill", color: WeshTheme.secondaryAccent)
                        InsightMetric(title: "الأسباب", value: "\(statistics.totalReasons)", icon: "quote.bubble.fill", color: WeshTheme.highlight)
                        InsightMetric(title: "المحفوظة", value: "\(statistics.savedCount)", icon: "bookmark.fill", color: WeshTheme.success)
                    }
                }
                .weshSurface()

                VStack(alignment: .leading, spacing: 12) {
                    Text("اهتماماتك")
                        .font(.title3.weight(.bold))
                    Text("تُحفظ محليًا لتخصيص المقارنات والتنبيهات لاحقًا عند توفر Backend.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    InterestPicker(selection: $selectedInterests) { category in
                        toggleInterest(category)
                    }

                    if !selectedInterests.isEmpty {
                        Text("المحدد: \(selectedInterests.map(\.title).sorted().joined(separator: "، "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .weshSurface()

                if userSession.isSignedIn {
                    Button(role: .destructive) {
                        userSession.signOut()
                        alias = userSession.displayName
                    } label: {
                        Label("تسجيل الخروج", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(16)
            .weshContentWidth()
        }
        .background(AppBackground())
        .navigationTitle("الحساب")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            alias = userSession.displayName
            loadInterests()
        }
    }

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
struct InterestPicker: View {
    @Binding var selection: Set<AskCategory>
    let toggle: (AskCategory) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 8)], spacing: 8) {
            ForEach(AskCategory.allCases.filter { $0 != .all }) { category in
                let isSelected = selection.contains(category)
                Button {
                    toggle(category)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: category.systemImage)
                        Text(category.title)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .accessibilityHidden(true)
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 42)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .background(
                        isSelected ? WeshTheme.accent : WeshTheme.canvas,
                        in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
