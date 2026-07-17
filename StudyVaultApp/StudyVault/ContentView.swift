import SwiftUI
import WebKit
import AVFoundation
import AuthenticationServices

final class UserSession: ObservableObject {
    @Published var isSignedIn: Bool
    @Published var displayName: String
    @Published var email: String
    @Published var userIdentifier: String

    private let defaults = UserDefaults.standard

    init() {
        isSignedIn = defaults.bool(forKey: "user.isSignedIn")
        displayName = defaults.string(forKey: "user.displayName") ?? "ضيف"
        email = defaults.string(forKey: "user.email") ?? ""
        userIdentifier = defaults.string(forKey: "user.identifier") ?? ""
    }

    var publicName: String {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanName.isEmpty ? "ضيف" : cleanName
    }

    func completeSignIn(with credential: ASAuthorizationAppleIDCredential) {
        userIdentifier = credential.user
        if let email = credential.email, !email.isEmpty {
            self.email = email
        }
        if let name = credential.fullName {
            let formatted = PersonNameComponentsFormatter().string(from: name).trimmingCharacters(in: .whitespacesAndNewlines)
            if !formatted.isEmpty {
                displayName = formatted
            }
        }
        isSignedIn = true
        persist()
    }

    func updateAlias(_ alias: String) {
        displayName = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    func signOut() {
        isSignedIn = false
        displayName = "ضيف"
        email = ""
        userIdentifier = ""
        persist()
    }

    private func persist() {
        defaults.set(isSignedIn, forKey: "user.isSignedIn")
        defaults.set(displayName, forKey: "user.displayName")
        defaults.set(email, forKey: "user.email")
        defaults.set(userIdentifier, forKey: "user.identifier")
    }
}

struct ContentView: View {
    @StateObject private var userSession = UserSession()
    @State private var homeViewModel = HomeViewModel()
    @State private var selectedQuestion: AskQuestion?
    @State private var selectedKnowledgeItem: KnowledgeItem?
    @State private var showingComposer = false
    @State private var showingSmartCompare = false
    @State private var composerTemplate: KnowledgeItem?

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(
                    questions: homeViewModel.questions,
                    knowledgeItems: homeViewModel.knowledgeItems,
                    totalVotes: homeViewModel.totalVotes,
                    openQuestion: { question in
                        selectedQuestion = question
                    },
                    openSmartCompare: {
                        showingSmartCompare = true
                    },
                    startQuestion: { item in
                        composerTemplate = item
                        showingComposer = true
                    }
                )
            }
            .tabItem {
                Label("الرئيسية", systemImage: "sparkles")
            }

            NavigationStack {
                QuestionListView(
                    questions: homeViewModel.filteredQuestions,
                    selectedCategory: $homeViewModel.selectedCategory,
                    searchText: $homeViewModel.searchText,
                    selectedQuestion: $selectedQuestion,
                    showingComposer: $showingComposer
                )
            }
            .tabItem {
                Label("الأسئلة", systemImage: "bubble.left.and.bubble.right")
            }

            NavigationStack {
                KnowledgeLibraryView(
                    items: homeViewModel.filteredKnowledge,
                    selectedCategory: $homeViewModel.selectedCategory,
                    searchText: $homeViewModel.searchText,
                    selectedItem: $selectedKnowledgeItem,
                    useItem: { item in
                        composerTemplate = item
                        showingComposer = true
                    }
                )
            }
            .tabItem {
                Label("المكتبة", systemImage: "books.vertical")
            }

            NavigationStack {
                ResearchBrowserView()
            }
            .tabItem {
                Label("المتصفح", systemImage: "safari")
            }

            NavigationStack {
                AccountView(userSession: userSession)
            }
            .tabItem {
                Label("الحساب", systemImage: "person.crop.circle")
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showingSmartCompare = true
            } label: {
                Image(systemName: "brain.head.profile")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(colors: [.teal, .indigo], startPoint: .topTrailing, endPoint: .bottomLeading),
                        in: Circle()
                    )
                    .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 1))
                    .shadow(color: .teal.opacity(0.32), radius: 18, y: 8)
            }
            .accessibilityLabel("مقارنة بالذكاء الاصطناعي")
            .padding(.trailing, 18)
            .padding(.bottom, 72)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .tint(.teal)
        .sheet(isPresented: $showingComposer) {
            NewQuestionView(template: composerTemplate, authorName: userSession.publicName) { question in
                homeViewModel.insertPublishedQuestion(question)
                selectedQuestion = question
                composerTemplate = nil
            }
        }
        .sheet(item: $selectedQuestion) { question in
            NavigationStack {
                QuestionDetail(
                    question: question,
                    relatedQuestions: homeViewModel.relatedQuestions(to: question),
                    voteAction: vote,
                    voteWithReasonAction: voteWithReason,
                    commentAction: addComment,
                    authorName: userSession.publicName,
                    isSaved: homeViewModel.savedQuestionIDs.contains(question.id),
                    saveAction: toggleSavedQuestion,
                    openRelatedQuestion: { related in
                        selectedQuestion = related
                    }
                )
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .sheet(item: $selectedKnowledgeItem) { item in
            NavigationStack {
                KnowledgeDetailView(item: item) {
                    composerTemplate = item
                    selectedKnowledgeItem = nil
                    showingComposer = true
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .sheet(isPresented: $showingSmartCompare) {
            NavigationStack {
                SmartComparisonView(items: homeViewModel.knowledgeItems)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .task {
            await homeViewModel.loadSavedQuestionIDs()
        }
        .alert("تنبيه", isPresented: Binding(
            get: { homeViewModel.appErrorMessage != nil },
            set: { if !$0 { homeViewModel.appErrorMessage = nil } }
        )) {
            Button("موافق") {
                homeViewModel.appErrorMessage = nil
            }
        } message: {
            Text(homeViewModel.appErrorMessage ?? "")
        }
    }

    private func vote(questionID: AskQuestion.ID, optionID: PollOption.ID) {
        selectedQuestion = homeViewModel.vote(questionID: questionID, optionID: optionID)
    }

    private func voteWithReason(questionID: AskQuestion.ID, optionID: PollOption.ID, reason: String) {
        voteWithReason(questionID: questionID, optionID: optionID, reason: reason, reasonCategory: nil, isVerifiedExperience: false)
    }

    private func voteWithReason(
        questionID: AskQuestion.ID,
        optionID: PollOption.ID,
        reason: String,
        reasonCategory: String?,
        isVerifiedExperience: Bool
    ) {
        selectedQuestion = homeViewModel.voteWithReason(
            questionID: questionID,
            optionID: optionID,
            reason: reason,
            authorName: userSession.publicName,
            reasonCategory: reasonCategory,
            isVerifiedExperience: isVerifiedExperience
        )
    }

    private func addComment(questionID: AskQuestion.ID, text: String) {
        selectedQuestion = homeViewModel.addComment(
            questionID: questionID,
            text: text,
            authorName: userSession.publicName
        )
    }

    private func toggleSavedQuestion(questionID: AskQuestion.ID) {
        Task {
            await homeViewModel.toggleSavedQuestion(questionID: questionID)
        }
    }
}

struct SmartComparisonView: View {
    let items: [KnowledgeItem]
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedCategory: AskCategory = .all
    @State private var selectedMode: ComparisonMode = .text
    @State private var selectedItems: [KnowledgeItem] = []
    @State private var speaker = AVSpeechSynthesizer()

    private var filteredItems: [KnowledgeItem] {
        KnowledgeSearchIndex.search(items, query: query, category: selectedCategory)
    }

    private var report: ComparisonReport {
        ComparisonEngine.buildReport(for: selectedItems)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(.teal, in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("مقارنة ذكية")
                                .font(.largeTitle.weight(.black))
                            Text("اختر من خيارين إلى عشرة خيارات، ثم اعرض النتيجة كنص أو صوت أو فيديو تمثيلي.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("نوع العرض", selection: $selectedMode) {
                        ForEach(ComparisonMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 12) {
                    Text("اختيار العناصر")
                        .font(.title3.weight(.bold))
                    TextField("ابحث في قاعدة المعرفة", text: $query)
                        .textFieldStyle(.roundedBorder)
                    CategoryScroller(selectedCategory: $selectedCategory)

                    LazyVStack(spacing: 10) {
                        ForEach(filteredItems.prefix(18)) { item in
                            Button {
                                toggle(item)
                            } label: {
                                SmartPickRow(item: item, isSelected: selectedItems.contains(item))
                            }
                            .buttonStyle(.plain)
                            .disabled(!selectedItems.contains(item) && selectedItems.count >= 10)
                        }
                    }
                }

                if selectedItems.isEmpty {
                    ContentUnavailableView(
                        "اختر عناصر للمقارنة",
                        systemImage: "checklist",
                        description: Text("ابدأ بخيارين على الأقل، ويسمح النظام حتى عشرة خيارات.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                } else {
                    ComparisonResultCard(report: report, mode: selectedMode) {
                        speak(report.audioScript)
                    }
                }
            }
            .padding(16)
        }
        .background(AppBackground())
        .navigationTitle("المقارنة المتقدمة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("إغلاق") {
                    speaker.stopSpeaking(at: .immediate)
                    dismiss()
                }
            }
        }
    }

    private func toggle(_ item: KnowledgeItem) {
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        } else if selectedItems.count < 10 {
            selectedItems.append(item)
        }
    }

    private func speak(_ text: String) {
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.45
        speaker.speak(utterance)
    }
}

struct SmartPickRow: View {
    let item: KnowledgeItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? .teal : .secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Label(item.category.title, systemImage: item.category.systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.teal)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.teal.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }
}

struct ComparisonResultCard: View {
    let report: ComparisonReport
    let mode: ComparisonMode
    let speak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.title2.weight(.black))
                    Text("ثقة التحليل \(report.confidence)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.teal)
                }
                Spacer()
                Image(systemName: mode.systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.teal, in: RoundedRectangle(cornerRadius: 14))
            }

            switch mode {
            case .text:
                textComparison
            case .audio:
                audioComparison
            case .video:
                videoComparison
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }

    private var textComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(report.recommendation)
                .font(.headline)
            ForEach(report.candidates) { candidate in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(candidate.item.name)
                            .font(.headline)
                        Spacer()
                        Text("\(candidate.score)")
                            .font(.title3.weight(.black))
                            .monospacedDigit()
                            .foregroundStyle(.teal)
                    }
                    Text(candidate.verdict)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 14))
            }

            ForEach(report.factors) { factor in
                Label("\(factor.title): \(factor.bestOptionName)", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.teal)
            }
        }
    }

    private var audioComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("نص التعليق الصوتي")
                .font(.headline)
            Text(report.audioScript)
                .foregroundStyle(.secondary)
            Button(action: speak) {
                Label("تشغيل أو إيقاف الصوت", systemImage: "speaker.wave.2.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var videoComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("سيناريو فيديو تمثيلي")
                .font(.headline)
            ForEach(Array(report.videoStoryboard.enumerated()), id: \.offset) { index, scene in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.teal, in: Circle())
                    Text(scene)
                        .font(.subheadline)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 14))
            }
            Text("النسخة الحالية تولّد سيناريو الفيديو داخل التطبيق. التسجيل الفعلي بالكاميرا يمكن إضافته لاحقًا مع أذونات الكاميرا والمايك.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct DashboardView: View {
    let questions: [AskQuestion]
    let knowledgeItems: [KnowledgeItem]
    let totalVotes: Int
    let openQuestion: (AskQuestion) -> Void
    let openSmartCompare: () -> Void
    let startQuestion: (KnowledgeItem?) -> Void

    private var highlightedItems: [KnowledgeItem] {
        Array(knowledgeItems.prefix(6))
    }

    private var categoryCount: Int {
        Set(knowledgeItems.map(\.category)).count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PremiumHeroCard(startQuestion: { startQuestion(nil) })

                HStack(spacing: 10) {
                    StatCard(value: "\(questions.count)", title: "قوالب سؤال", icon: "questionmark.bubble.fill", color: .teal)
                    StatCard(value: "\(knowledgeItems.count)", title: "عنصر معرفة", icon: "books.vertical.fill", color: .indigo)
                    StatCard(value: "\(categoryCount)", title: "مجالات", icon: "square.grid.2x2.fill", color: .orange)
                }

                IntelligencePanel(openSmartCompare: openSmartCompare)

                SectionHeader(title: "مقارنات جاهزة", subtitle: "ابدأ من فكرة ثم خل الناس يحسمونها")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 12)], spacing: 12) {
                    ForEach(highlightedItems) { item in
                        KnowledgeCompactCard(item: item) {
                            startQuestion(item)
                        }
                    }
                }

                SectionHeader(title: "نشاط المنصة", subtitle: "كل الأرقام تبدأ من الصفر، بدون تصويتات وهمية")

                VStack(spacing: 10) {
                    ForEach(questions.prefix(4)) { question in
                        DashboardQuestionCard(question: question) {
                            openQuestion(question)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("وش الرأي")
        .background(AppBackground())
    }
}

struct QuestionListView: View {
    let questions: [AskQuestion]
    @Binding var selectedCategory: AskCategory
    @Binding var searchText: String
    @Binding var selectedQuestion: AskQuestion?
    @Binding var showingComposer: Bool

    var body: some View {
        List {
            Section {
                CategoryScroller(selectedCategory: $selectedCategory)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section("أسئلة المقارنة") {
                ForEach(questions) { question in
                    Button {
                        selectedQuestion = question
                    } label: {
                        QuestionRow(question: question)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppBackground())
        .navigationTitle("الأسئلة")
        .searchable(text: $searchText, prompt: "ابحث عن منتج أو سؤال")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingComposer = true
                } label: {
                    Label("سؤال جديد", systemImage: "plus.bubble.fill")
                }
            }
        }
        .overlay {
            if questions.isEmpty {
                ContentUnavailableView("لا توجد نتائج", systemImage: "magnifyingglass", description: Text("غيّر البحث أو المجال."))
            }
        }
    }
}

struct KnowledgeLibraryView: View {
    let items: [KnowledgeItem]
    @Binding var selectedCategory: AskCategory
    @Binding var searchText: String
    @Binding var selectedItem: KnowledgeItem?
    let useItem: (KnowledgeItem) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                CategoryScroller(selectedCategory: $selectedCategory)

                Text("قاعدة معرفة محلية")
                    .font(.title2.weight(.bold))
                Text("منتجات وأماكن وأفكار مصنفة تساعدك تصيغ مقارنة واضحة. البيانات مرجعية ومنظمة وليست نتائج تصويت.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        KnowledgeRow(item: item) {
                            selectedItem = item
                        } useItem: {
                            useItem(item)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(AppBackground())
        .navigationTitle("المكتبة")
        .searchable(text: $searchText, prompt: "ابحث عن جوال، سيارة، مطعم...")
    }
}

private enum ResearchBrowserDefaults {
    static let searchURLString = "https://www.google.com/search?q=%D9%85%D9%82%D8%A7%D8%B1%D9%86%D8%A9+%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA"
    static let searchURL = URL(string: searchURLString) ?? URL(filePath: "/")
}

struct ResearchBrowserView: View {
    @State private var address = ResearchBrowserDefaults.searchURLString
    @State private var activeURL = ResearchBrowserDefaults.searchURL

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    TextField("ابحث أو اكتب رابط", text: $address)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .submitLabel(.go)
                        .padding(10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .onSubmit(loadAddress)

                    Button(action: loadAddress) {
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("فتح")
                }

                HStack {
                    BrowserShortcut(title: "جوالات", query: "مقارنة أفضل جوالات") { openSearch($0) }
                    BrowserShortcut(title: "سيارات", query: "مقارنة سيارات اقتصادية") { openSearch($0) }
                    BrowserShortcut(title: "مطاعم", query: "أفضل مطاعم قريبة") { openSearch($0) }
                }
            }
            .padding()
            .background(.background)

            WebView(url: activeURL)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding([.horizontal, .bottom], 12)
        }
        .navigationTitle("متصفح المقارنة")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppBackground())
    }

    private func loadAddress() {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let url = URL(string: trimmed), url.scheme == "https" || url.scheme == "http" {
            activeURL = url
            return
        }

        openSearch(trimmed)
    }

    private func openSearch(_ query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.google.com/search?q=\(encoded)"
        address = urlString
        activeURL = URL(string: urlString) ?? ResearchBrowserDefaults.searchURL
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }
}

struct QuestionDetail: View {
    let question: AskQuestion
    let relatedQuestions: [AskQuestion]
    let voteAction: (AskQuestion.ID, PollOption.ID) -> Void
    let voteWithReasonAction: (AskQuestion.ID, PollOption.ID, String, String?, Bool) -> Void
    let commentAction: (AskQuestion.ID, String) -> Void
    let authorName: String
    let isSaved: Bool
    let saveAction: (AskQuestion.ID) -> Void
    let openRelatedQuestion: (AskQuestion) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var selectedVoteOption: PollOption?
    @State private var voteReason = ""
    @State private var selectedReasonCategory: String?
    @State private var isVerifiedExperience = false
    @State private var decisionMode: DecisionMode = .quick
    @State private var commentFilter: CommentFilter = .all
    @State private var savedDecisionState: SavedDecisionState = .comparing

    private var visibleComments: [AskComment] {
        switch commentFilter {
        case .all:
            return question.comments
        case .verified:
            return question.comments.filter { $0.trustBadge != nil }
        case .reasons:
            return question.comments.filter { $0.optionID != nil }
        }
    }

    private var shareText: String {
        let winner = question.winningOption?.title ?? "لم تتضح النتيجة بعد"
        return """
        وش الرأي؟
        \(question.title)

        النتيجة الحالية: \(winner)
        \(question.smartSummary)
        """
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(question.category.title, systemImage: question.category.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.teal)
                    Text(question.title)
                        .font(.largeTitle.weight(.black))
                        .lineLimit(4)
                    Text(question.details)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("بواسطة \(question.author) • \(question.timeAgo)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))

                DecisionSummaryCard(question: question)

                Picker("نوع القرار", selection: $decisionMode) {
                    ForEach(DecisionMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if decisionMode == .deep {
                    DecisionCriteriaCard(category: question.category)
                    SpecificationComparisonCard(question: question)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("التصويت")
                        .font(.title3.weight(.bold))
                    ForEach(question.options) { option in
                        VoteOptionRow(
                            option: option,
                            totalVotes: question.totalVotes,
                            isWinning: option.id == question.winningOption?.id
                        ) {
                            selectedVoteOption = option
                            voteReason = ""
                        }
                    }
                }

                if let selectedVoteOption {
                    VoteReasonCard(
                        option: selectedVoteOption,
                        category: question.category,
                        reason: $voteReason,
                        selectedReasonCategory: $selectedReasonCategory,
                        isVerifiedExperience: $isVerifiedExperience,
                        submitWithReason: {
                            voteWithReasonAction(question.id, selectedVoteOption.id, voteReason, selectedReasonCategory, isVerifiedExperience)
                            self.selectedVoteOption = nil
                            voteReason = ""
                            selectedReasonCategory = nil
                            isVerifiedExperience = false
                        },
                        voteOnly: {
                            voteAction(question.id, selectedVoteOption.id)
                            self.selectedVoteOption = nil
                            voteReason = ""
                            selectedReasonCategory = nil
                            isVerifiedExperience = false
                        },
                        cancel: {
                            self.selectedVoteOption = nil
                            voteReason = ""
                            selectedReasonCategory = nil
                            isVerifiedExperience = false
                        }
                    )
                }

                SavedDecisionCard(selection: $savedDecisionState, shareText: shareText)

                if !relatedQuestions.isEmpty {
                    SimilarQuestionsCard(questions: relatedQuestions, openQuestion: openRelatedQuestion)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("أسباب الناس وتعليقاتهم")
                            .font(.title3.weight(.bold))
                        Spacer()
                        Menu {
                            ForEach(CommentFilter.allCases) { filter in
                                Button(filter.title) {
                                    commentFilter = filter
                                }
                            }
                        } label: {
                            Label(commentFilter.title, systemImage: "line.3.horizontal.decrease.circle")
                                .font(.caption.weight(.bold))
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("تعليق عام على السؤال", text: $commentText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            commentAction(question.id, commentText)
                            commentText = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if question.comments.isEmpty {
                        ContentUnavailableView(
                            "لا توجد أسباب بعد",
                            systemImage: "text.bubble",
                            description: Text("صوّت على خيار واكتب سبب اختيارك حتى يستفيد باقي الناس.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    } else if visibleComments.isEmpty {
                        ContentUnavailableView(
                            "لا توجد نتائج لهذا الفلتر",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("غيّر الفلتر أو أضف سبب تصويت بتجربة موثقة.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 130)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        ForEach(visibleComments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(AppBackground())
        .navigationTitle("نتيجة المقارنة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("تم") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveAction(question.id)
                } label: {
                    Label(isSaved ? "إلغاء الحفظ" : "حفظ", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                }
            }
        }
    }
}

struct KnowledgeDetailView: View {
    let item: KnowledgeItem
    let useItem: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(item.category.title, systemImage: item.category.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.teal)
                    Text(item.name)
                        .font(.largeTitle.weight(.black))
                    Text(item.summary)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))

                InfoTile(title: "نقاط قوة", values: item.strengths, color: .teal)
                InfoTile(title: "انتبه لها", values: item.considerations, color: .orange)
                InfoTile(title: "مناسب لمن", values: item.idealFor, color: .indigo)

                if !item.specs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("بطاقة بيانات")
                                .font(.headline)
                            Spacer()
                            Text(item.dataQuality)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.teal)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.teal.opacity(0.12), in: Capsule())
                        }

                        ForEach(item.specs.keys.sorted(), id: \.self) { key in
                            HStack(alignment: .top) {
                                Text(key)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 16)
                                Text(item.specs[key] ?? "")
                                    .font(.subheadline.weight(.bold))
                                    .multilineTextAlignment(.leading)
                            }
                            Divider()
                        }
                    }
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("سؤال مقترح")
                        .font(.headline)
                    Text(item.suggestedQuestion)
                        .font(.title3.weight(.semibold))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                Button {
                    useItem()
                } label: {
                    Label("حوّلها إلى سؤال تصويت", systemImage: "plus.bubble.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(16)
        }
        .background(AppBackground())
        .navigationTitle("تفاصيل")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("إغلاق") {
                    dismiss()
                }
            }
        }
    }
}

struct QuestionRow: View {
    let question: AskQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(question.category.title, systemImage: question.category.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.teal)
                Spacer()
                Text(question.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(question.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(question.options.map(\.title).prefix(4).joined(separator: " • "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label("\(question.options.count) خيارات", systemImage: "list.bullet.rectangle")
                Spacer()
                Label("\(question.totalVotes) تصويت", systemImage: "chart.bar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

struct VoteOptionRow: View {
    let option: PollOption
    let totalVotes: Int
    let isWinning: Bool
    let action: () -> Void

    private var percent: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.votes) / Double(totalVotes)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(option.title)
                        .font(.headline)
                    Spacer()
                    if isWinning {
                        Label("الأعلى", systemImage: "crown.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                    }
                    Text("\(Int(percent * 100))%")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.14))
                        Capsule()
                            .fill(LinearGradient(colors: [.teal, .blue], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, geometry.size.width * percent))
                    }
                }
                .frame(height: 10)

                Text("\(option.votes) تصويت")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct DecisionSummaryCard: View {
    let question: AskQuestion
    private var summary: DecisionSummary {
        DecisionSummaryService.makeSummary(for: question)
    }

    private var confidencePercent: Int {
        switch summary.confidenceLevel {
        case .low: min(49, question.decisionConfidence)
        case .medium: min(74, max(50, question.decisionConfidence))
        case .high: max(75, question.decisionConfidence)
        }
    }

    private var clarityColor: Color {
        switch summary.clarity {
        case .insufficientData: .secondary
        case .close: .orange
        case .leaning: .teal
        case .decisive: .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.teal, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 6) {
                    Text("ملخص القرار")
                        .font(.headline)
                    Text(summary.recommendationText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                DecisionMetric(title: "الثقة", value: "\(confidencePercent)%", icon: "shield.checkered", color: .teal)
                DecisionMetric(title: "المتصدر", value: "\(summary.leadingVotePercentage)%", icon: "chart.pie.fill", color: .blue)
                DecisionMetric(title: "الفارق", value: "\(Int(summary.voteGapPercentage.rounded()))%", icon: "arrow.left.and.right", color: .indigo)
            }

            Label(summary.clarity.arabicTitle, systemImage: summary.clarity.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(clarityColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(clarityColor.opacity(0.12), in: Capsule())

            if !summary.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("أبرز ما تقوله النتيجة")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    ForEach(summary.highlights) { highlight in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(highlight.title)
                                .font(.subheadline.weight(.bold))
                            Text(highlight.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            if let warning = summary.warningText {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }

            if !summary.optionInsights.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Label("تحليل الأسباب حسب الخيار", systemImage: "list.bullet.clipboard")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.teal)

                    ForEach(summary.optionInsights) { insight in
                        OptionInsightView(insight: insight)
                    }
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.teal.opacity(0.25), lineWidth: 1)
        )
    }
}

struct OptionInsightView: View {
    let insight: OptionDecisionInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.optionTitle)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(insight.votePercentage)%")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if !insight.topReasons.isEmpty {
                FlowTags(values: Array(insight.topReasons.prefix(3)), color: .teal)
            }

            HStack(alignment: .top, spacing: 8) {
                if !insight.positives.isEmpty {
                    InsightList(title: "إيجابيات", values: insight.positives, color: .green, icon: "plus.circle.fill")
                }
                if !insight.negatives.isEmpty {
                    InsightList(title: "سلبيات", values: insight.negatives, color: .orange, icon: "minus.circle.fill")
                }
            }

            if insight.evidenceCount == 0 {
                Text("لا توجد أسباب مكتوبة كافية لهذا الخيار بعد.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct InsightList: View {
    let title: String
    let values: [String]
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
            ForEach(values.prefix(3), id: \.self) { value in
                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DecisionMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DecisionCriteriaCard: View {
    let category: AskCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("معايير التقييم لهذا التصنيف", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
                Text(category.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.teal)
            }

            FlowTags(values: DecisionFeatureCatalog.criteria(for: category), color: .teal)

            Text("استخدم هذه المعايير عند قراءة الأصوات: قد يكون الخيار الأعلى تصويتًا ليس الأفضل لك إذا كانت أولوياتك مختلفة.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SpecificationComparisonCard: View {
    let question: AskQuestion

    private var rows: [ComparisonSpecificationRow] {
        ComparisonSpecificationService.rows(for: question)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("جدول المواصفات", systemImage: "tablecells")
                    .font(.headline)
                Spacer()
                Text("\(question.options.count) خيارات")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.teal)
            }

            Text("تقييم إرشادي يجمع بين التصويت والأسباب المكتوبة حسب معايير هذا التصنيف. لا يغني عن قراءة التفاصيل.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("المعيار")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 90, alignment: .leading)
                        ForEach(question.options) { option in
                            Text(option.title)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .frame(width: 105, alignment: .leading)
                        }
                    }

                    ForEach(rows) { row in
                        GridRow {
                            Text(row.criterion)
                                .font(.caption.weight(.bold))
                                .frame(minWidth: 90, alignment: .leading)
                            ForEach(question.options) { option in
                                SpecValueLabel(
                                    value: row.values[option.id] ?? "غير واضح",
                                    isLeading: row.leadingOptionID == option.id
                                )
                                .frame(width: 105, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SpecValueLabel: View {
    let value: String
    let isLeading: Bool

    var body: some View {
        Label(value, systemImage: isLeading ? "checkmark.seal.fill" : "circle")
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(isLeading ? .teal : .secondary)
    }
}

struct SavedDecisionCard: View {
    @Binding var selection: SavedDecisionState
    let shareText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("احفظ قرارك", systemImage: "bookmark.fill")
                    .font(.headline)
                Spacer()
                ShareLink(item: shareText) {
                    Label("مشاركة", systemImage: "square.and.arrow.up")
                        .font(.caption.weight(.bold))
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                ForEach(SavedDecisionState.allCases) { state in
                    Button {
                        selection = state
                    } label: {
                        Label(state.title, systemImage: state.systemImage)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selection == state ? .white : .primary)
                    .background(selection == state ? Color.teal : Color.secondary.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct SimilarQuestionsCard: View {
    let questions: [AskQuestion]
    let openQuestion: (AskQuestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("مقارنات مشابهة", systemImage: "rectangle.stack.badge.plus")
                    .font(.headline)
                Spacer()
                Text("تجنب التكرار")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            ForEach(questions) { question in
                Button {
                    openQuestion(question)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: question.category.systemImage)
                            .foregroundStyle(.teal)
                            .frame(width: 30, height: 30)
                            .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(question.title)
                                .font(.subheadline.weight(.bold))
                                .lineLimit(2)
                            Text("\(question.totalVotes) تصويت • \(question.comments.count) سبب أو تعليق")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.backward")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct VoteReasonCard: View {
    let option: PollOption
    let category: AskCategory
    @Binding var reason: String
    @Binding var selectedReasonCategory: String?
    @Binding var isVerifiedExperience: Bool
    let submitWithReason: () -> Void
    let voteOnly: () -> Void
    let cancel: () -> Void

    private var canSubmitReason: Bool {
        !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.bubble.fill")
                    .foregroundStyle(.teal)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("لماذا اخترت \(option.title)؟")
                        .font(.headline)
                    Text("أضف سببك حتى يفهم الناس منطق التصويت، أو صوّت بدون سبب.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("أسباب جاهزة")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                FlowTags(
                    values: DecisionFeatureCatalog.voteReasons(for: category),
                    color: .teal,
                    action: { value in
                        selectedReasonCategory = value
                        reason = value
                    }
                )
            }

            TextField("مثال: اخترته لأن سعره أفضل وضمانه أوضح", text: $reason, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)

            Toggle(isOn: $isVerifiedExperience) {
                Label("جرّبت هذا الخيار فعليًا", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .toggleStyle(.switch)

            HStack(spacing: 10) {
                Button("إلغاء", action: cancel)
                    .buttonStyle(.bordered)

                Spacer()

                Button("تصويت فقط", action: voteOnly)
                    .buttonStyle(.bordered)

                Button("صوّت مع السبب", action: submitWithReason)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSubmitReason)
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.teal.opacity(0.28), lineWidth: 1)
        )
    }
}

struct CommentRow: View {
    let comment: AskComment

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(comment.author)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Label("\(comment.likes)", systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let optionTitle = comment.optionTitle {
                HStack(spacing: 6) {
                    Label("صوّت لـ \(optionTitle)", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.teal)
                    if let trustBadge = comment.trustBadge {
                        Label(trustBadge, systemImage: "shield.fill")
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.teal.opacity(0.10), in: Capsule())
            }
            if let reasonCategory = comment.reasonCategory {
                Text(reasonCategory)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.10), in: Capsule())
            }
            Text(comment.text)
                .font(.body)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct NewQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateComparisonViewModel

    let authorName: String
    let saveAction: (AskQuestion) -> Void

    init(template: KnowledgeItem? = nil, authorName: String, saveAction: @escaping (AskQuestion) -> Void) {
        _viewModel = State(initialValue: CreateComparisonViewModel(template: template))
        self.authorName = authorName
        self.saveAction = saveAction
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("السؤال") {
                    TextField("مثال: أشتري السيارة A أو B؟", text: $viewModel.title, axis: .vertical)
                    TextField("تفاصيل تساعد الناس يصوتون", text: $viewModel.details, axis: .vertical)
                    Picker("المجال", selection: $viewModel.category) {
                        ForEach(AskCategory.allCases.filter { $0 != .all }) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    TextField("وسوم اختيارية مفصولة بفواصل", text: $viewModel.tagsText)
                }

                Section("خيارات المقارنة") {
                    Stepper("عدد الخيارات: \(viewModel.optionCount)", value: $viewModel.optionCount, in: 2...10)
                    ForEach(0..<viewModel.optionCount, id: \.self) { index in
                        TextField("الخيار \(index + 1)", text: $viewModel.optionTitles[index])
                    }
                }

                Section("إعدادات المشاركة") {
                    Toggle("نشر السؤال باسم مجهول", isOn: $viewModel.isAnonymous)
                    Toggle("السماح بأسباب التصويت", isOn: $viewModel.allowsVoteReasons)
                    Toggle("السماح بالتعليقات", isOn: $viewModel.allowsComments)
                }

                if let validationMessage = viewModel.validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("سؤال جديد")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.restoreDraftIfNeeded()
            }
            .onDisappear {
                viewModel.saveDraftOnDismissIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("حفظ مسودة") {
                        viewModel.saveDraft()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("نشر") {
                        do {
                            let question = try viewModel.makeQuestion(authorName: authorName)
                            saveAction(question)
                        } catch {
                            return
                        }
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

struct AccountView: View {
    @ObservedObject var userSession: UserSession
    @State private var alias = ""

    private var isAliasValid: Bool {
        !alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: userSession.isSignedIn ? "checkmark.seal.fill" : "person.crop.circle.badge.plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(.teal, in: RoundedRectangle(cornerRadius: 16))

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
                            .foregroundStyle(.teal)
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
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))

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
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 18))

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
        }
        .background(AppBackground())
        .navigationTitle("الحساب")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            alias = userSession.displayName
        }
    }
}

struct PremiumHeroCard: View {
    let startQuestion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image("HeroEmblem")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 18, y: 10)

            VStack(alignment: .leading, spacing: 8) {
                Text("وش الرأي")
                    .font(.largeTitle.weight(.black))
                Text("قرارك أوضح قبل الشراء. قارن بين خيارين أو عشرة، وافهم الفروقات من قاعدة معرفة منظمة وآراء قابلة للتصويت.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: startQuestion) {
                Label("ابدأ سؤال مقارنة", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .foregroundStyle(.teal)
        }
        .padding(20)
        .foregroundStyle(.white)
        .background(
            LinearGradient(colors: [Color(red: 0.04, green: 0.09, blue: 0.18), Color(red: 0.03, green: 0.22, blue: 0.35), Color(red: 0.58, green: 0.42, blue: 0.16)], startPoint: .topTrailing, endPoint: .bottomLeading),
            in: RoundedRectangle(cornerRadius: 24)
        )
        .shadow(color: Color(red: 0.58, green: 0.42, blue: 0.16).opacity(0.25), radius: 20, y: 12)
    }
}

struct IntelligencePanel: View {
    let openSmartCompare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "cpu.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(.indigo, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 5) {
                    Text("محرك مقارنة أذكى")
                        .font(.title3.weight(.black))
                    Text("يرتب الخيارات حسب نقاط القوة، الملاحظات، المواصفات، وملاءمة الاستخدام، ثم يحولها إلى نص أو صوت أو سيناريو عرض.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                MiniFeature(title: "نص", icon: "text.alignright")
                MiniFeature(title: "صوت", icon: "waveform")
                MiniFeature(title: "سيناريو", icon: "play.rectangle")
            }

            Button(action: openSmartCompare) {
                Label("افتح المقارنة الذكية", systemImage: "brain.head.profile")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(colors: [.teal.opacity(0.45), .indigo.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

struct MiniFeature: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(Color.secondary.opacity(0.12), in: Capsule())
    }
}

struct StatCard: View {
    let value: String
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3.weight(.bold))
            Text(value)
                .font(.title2.weight(.black))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.weight(.bold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct CategoryScroller: View {
    @Binding var selectedCategory: AskCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AskCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Label(category.title, systemImage: category.systemImage)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(selectedCategory == category ? Color.teal : Color.secondary.opacity(0.12), in: Capsule())
                            .foregroundStyle(selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct KnowledgeCompactCard: View {
    let item: KnowledgeItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: item.category.systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.teal)
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(item.strengths.prefix(2).joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

struct KnowledgeRow: View {
    let item: KnowledgeItem
    let open: () -> Void
    let useItem: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: item.category.systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.teal)
                    .frame(width: 36, height: 36)
                    .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        Spacer()
                        Text(item.dataQuality)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.teal.opacity(0.12), in: Capsule())
                    }
                    Text(item.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    if !item.specs.isEmpty {
                        Text(item.specs.keys.sorted().prefix(3).map { "\($0): \(item.specs[$0] ?? "")" }.joined(separator: "  •  "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            HStack {
                Button("التفاصيل", action: open)
                    .buttonStyle(.bordered)
                Button("اسأل عنه", action: useItem)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}

struct DashboardQuestionCard: View {
    let question: AskQuestion
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                Image(systemName: question.category.systemImage)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.teal, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(question.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text("\(question.options.count) خيارات • \(question.totalVotes) تصويت")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("فتح \(question.title)")
    }
}

struct InfoTile: View {
    let title: String
    let values: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            FlowTags(values: values, color: color)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct FlowTags: View {
    let values: [String]
    let color: Color
    var action: ((String) -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(values, id: \.self) { value in
                if let action {
                    Button {
                        action(value)
                    } label: {
                        FlowTagLabel(value: value, color: color)
                    }
                    .buttonStyle(.plain)
                } else {
                    FlowTagLabel(value: value, color: color)
                }
            }
        }
    }
}

struct FlowTagLabel: View {
    let value: String
    let color: Color

    var body: some View {
        Text(value)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.12), in: Capsule())
            .foregroundStyle(color)
    }
}

struct BrowserShortcut: View {
    let title: String
    let query: String
    let action: (String) -> Void

    var body: some View {
        Button {
            action(query)
        } label: {
            Text(title)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(uiColor: .systemBackground),
                Color.teal.opacity(0.07),
                Color.indigo.opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
