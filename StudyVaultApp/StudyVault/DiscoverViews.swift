import SwiftUI
import WebKit

struct QuestionListView: View {
    let questions: [AskQuestion]
    @Binding var selectedCategory: AskCategory
    @Binding var selectedSortMode: QuestionSortMode
    @Binding var searchText: String
    @Binding var selectedQuestion: AskQuestion?
    @Binding var showingComposer: Bool
    let refresh: () async -> Void
    let joinPrivateRoom: (String) async -> AskQuestion?

    @State private var showingFilters = false
    @State private var showingRoomJoiner = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                DiscoverHeader(
                    resultCount: questions.count,
                    showingFilters: $showingFilters
                )

                CategoryScroller(selectedCategory: $selectedCategory)
                SortModePicker(selectedSortMode: $selectedSortMode)

                if questions.isEmpty {
                    WeshEmptyState(
                        title: "ما لقينا نتيجة مطابقة",
                        message: "جرّب كلمة مختلفة أو وسّع خيارات التصفية.",
                        systemImage: "magnifyingglass",
                        actionTitle: "مسح التصفية"
                    ) {
                        clearFilters()
                    }
                    .frame(maxWidth: .infinity, minHeight: 330)
                } else {
                    HStack {
                        Text("\(questions.count) نتيجة")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WeshTheme.secondaryText)
                        Spacer()
                        Text(selectedSortMode.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WeshTheme.accent)
                    }

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 320), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(questions) { question in
                            DashboardQuestionCard(question: question) {
                                selectedQuestion = question
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 18)
            .weshContentWidth()
        }
        .background(AppBackground())
        .refreshable { await refresh() }
        .navigationTitle("اكتشف")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "ابحث عن مقارنة، خيار، أو تصنيف")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingRoomJoiner = true
                } label: {
                    Image(systemName: "key.fill")
                }
                .accessibilityLabel("الانضمام إلى غرفة خاصة")

                Button {
                    showingComposer = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("مقارنة جديدة")
            }
        }
        .sheet(isPresented: $showingFilters) {
            DiscoveryFilterSheet(
                selectedCategory: $selectedCategory,
                selectedSortMode: $selectedSortMode,
                clear: clearFilters
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRoomJoiner) {
            JoinDecisionRoomView { code in
                guard let room = await joinPrivateRoom(code) else { return false }
                selectedQuestion = room
                return true
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func clearFilters() {
        searchText = ""
        selectedCategory = .all
        selectedSortMode = .newest
    }
}

private struct JoinDecisionRoomView: View {
    @Environment(\.dismiss) private var dismiss
    let joinAction: (String) async -> Bool

    @State private var code = ""
    @State private var isJoining = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: 20) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(WeshTheme.goldBright)
                        .frame(width: 66, height: 66)
                        .background(WeshTheme.gold.opacity(0.12), in: Circle())
                        .accessibilityHidden(true)

                    VStack(spacing: 7) {
                        Text("غرفة قرار خاصة")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(WeshTheme.primaryText)
                        Text("أدخل رمز الدعوة الذي شاركه معك منشئ المقارنة.")
                            .font(.subheadline)
                            .foregroundStyle(WeshTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    TextField("رمز الدعوة", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.center)
                        .font(.title3.monospaced().weight(.bold))
                        .weshField()
                        .accessibilityIdentifier("room.inviteCode")

                    if let errorMessage {
                        WeshStatusBanner(text: errorMessage, kind: .warning)
                    }

                    Button {
                        join()
                    } label: {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("فتح الغرفة", systemImage: "arrow.left")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(WeshPrimaryButtonStyle())
                    .disabled(cleanCode.isEmpty || isJoining)
                    .accessibilityIdentifier("room.join")
                }
                .padding(24)
                .weshContentWidth()
            }
            .navigationTitle("الانضمام برمز")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var cleanCode: String {
        code
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .uppercased()
    }

    private func join() {
        guard !cleanCode.isEmpty else { return }
        isJoining = true
        errorMessage = nil
        Task {
            let succeeded = await joinAction(cleanCode)
            isJoining = false
            if succeeded {
                dismiss()
            } else {
                errorMessage = "تعذر فتح الغرفة. تحقق من الرمز والاتصال ثم حاول مرة أخرى."
            }
        }
    }
}

private struct DiscoverHeader: View {
    let resultCount: Int
    @Binding var showingFilters: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("اكتشف")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(WeshTheme.primaryText)
                Text("آراء وتجارب تساعدك تشوف الصورة كاملة.")
                    .font(.subheadline)
                    .foregroundStyle(WeshTheme.secondaryText)
            }
            Spacer(minLength: 8)
            Button {
                showingFilters = true
            } label: {
                Label("تصفية", systemImage: "line.3.horizontal.decrease")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 13)
                    .frame(minHeight: 44)
                    .background(WeshTheme.surface, in: Capsule())
                    .overlay { Capsule().stroke(WeshTheme.hairline) }
            }
            .buttonStyle(.plain)
            .accessibilityHint("يعرض خيارات التصنيف والترتيب")
        }
        .accessibilityElement(children: .contain)
    }
}

private struct DiscoveryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: AskCategory
    @Binding var selectedSortMode: QuestionSortMode
    let clear: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        WeshSectionHeader("التصنيف", subtitle: "اختر المجال الأقرب لقرارك")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], spacing: 10) {
                            ForEach(AskCategory.allCases) { category in
                                FilterChoice(
                                    title: category.title,
                                    systemImage: category.systemImage,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        WeshSectionHeader("الترتيب", subtitle: "رتّب النتائج بالطريقة المناسبة لك")
                        ForEach(QuestionSortMode.allCases) { mode in
                            FilterChoice(
                                title: mode.title,
                                systemImage: mode.systemImage,
                                isSelected: selectedSortMode == mode
                            ) {
                                selectedSortMode = mode
                            }
                        }
                    }
                }
                .padding(18)
            }
            .background(AppBackground())
            .navigationTitle("تصفية النتائج")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("مسح") {
                        clear()
                    }
                    .foregroundStyle(WeshTheme.destructive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

private struct FilterChoice: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .frame(width: 22)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 6)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(WeshTheme.accent)
                }
            }
            .foregroundStyle(WeshTheme.primaryText)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                isSelected ? WeshTheme.accent.opacity(0.11) : WeshTheme.surface,
                in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: WeshTheme.controlRadius)
                    .stroke(isSelected ? WeshTheme.accent.opacity(0.6) : WeshTheme.hairline)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct KnowledgeLibraryView: View {
    let items: [KnowledgeItem]
    let savedQuestions: [AskQuestion]
    @Binding var selectedCategory: AskCategory
    @Binding var searchText: String
    @Binding var selectedItem: KnowledgeItem?
    let useItem: (KnowledgeItem) -> Void
    let openSavedQuestion: (AskQuestion) -> Void
    let unsaveQuestion: (AskQuestion.ID) -> Void
    let openResearch: () -> Void
    let refresh: () async -> Void

    private var categoryCount: Int {
        Set(items.map(\.category)).count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("المكتبة")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(WeshTheme.primaryText)
                    Text("معلومات منظمة تساعدك على المقارنة بشكل أسرع.")
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.secondaryText)
                    Label("\(items.count) عنصرًا في \(categoryCount) تصنيفًا", systemImage: "books.vertical.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.accent)
                        .padding(.top, 3)
                }

                savedComparisonsSection

                CategoryScroller(selectedCategory: $selectedCategory)

                if items.isEmpty {
                    WeshEmptyState(
                        title: "ما لقينا عنصرًا مطابقًا",
                        message: "غيّر كلمة البحث أو اختر تصنيفًا آخر.",
                        systemImage: "books.vertical"
                    )
                    .frame(maxWidth: .infinity, minHeight: 330)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 330), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(items) { item in
                            KnowledgeRow(item: item) {
                                selectedItem = item
                            } useItem: {
                                useItem(item)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 18)
            .weshContentWidth()
        }
        .background(AppBackground())
        .refreshable { await refresh() }
        .navigationTitle("المكتبة")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "ابحث عن منتج، خدمة، أو خيار")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: openResearch) {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("بحث خارجي")
            }
        }
    }

    @ViewBuilder
    private var savedComparisonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader(
                "المقارنات المحفوظة",
                subtitle: savedQuestions.isEmpty
                    ? "احفظ أي مقارنة من صفحتها لتجدها هنا."
                    : "\(savedQuestions.count) مقارنة محفوظة على هذا الجهاز.",
                systemImage: "bookmark.fill"
            )

            if savedQuestions.isEmpty {
                Text("لم تحفظ أي مقارنة بعد. افتح أي مقارنة واضغط على أيقونة الحفظ لتظهر هنا.")
                    .font(.footnote)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 330), spacing: 14)],
                    spacing: 14
                ) {
                    ForEach(savedQuestions) { question in
                        DashboardQuestionCard(question: question) {
                            openSavedQuestion(question)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                unsaveQuestion(question.id)
                            } label: {
                                Label("إزالة من المحفوظات", systemImage: "bookmark.slash")
                            }
                        }
                    }
                }
            }
        }
        .weshSurface()
        .accessibilityIdentifier("library.savedComparisons")
    }
}

private enum ResearchBrowserDefaults {
    static let searchURLString = "https://www.google.com/search?q=%D9%85%D9%82%D8%A7%D8%B1%D9%86%D8%A9+%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA"
    static let searchURL = URL(string: searchURLString) ?? URL(filePath: "/")
}

struct ResearchBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var address = ResearchBrowserDefaults.searchURLString
    @State private var activeURL = ResearchBrowserDefaults.searchURL
    @State private var validationMessage: String?
    @State private var isLoading = false
    @State private var loadFailure: String?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack(spacing: 9) {
                    TextField("ابحث أو اكتب رابطًا آمنًا", text: $address)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.webSearch)
                        .submitLabel(.go)
                        .weshField()
                        .onSubmit(loadAddress)

                    Button(action: loadAddress) {
                        Image(systemName: "arrow.up.forward")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(WeshTheme.accent, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("فتح")
                }

                HStack {
                    BrowserShortcut(title: "جوالات", query: "مقارنة أفضل جوالات") { openSearch($0) }
                    BrowserShortcut(title: "سيارات", query: "مقارنة سيارات اقتصادية") { openSearch($0) }
                    BrowserShortcut(title: "مطاعم", query: "أفضل مطاعم قريبة") { openSearch($0) }
                }

                if let validationMessage {
                    WeshStatusBanner(text: validationMessage, kind: .warning)
                }
                if let loadFailure {
                    WeshStatusBanner(text: loadFailure, kind: .warning)
                }
            }
            .padding(14)
            .background(WeshTheme.surface)

            WebView(
                url: activeURL,
                isLoading: $isLoading,
                loadFailure: $loadFailure
            )
            .clipShape(RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
            .padding(12)
            .overlay(alignment: .top) {
                if isLoading {
                    ProgressView()
                        .tint(WeshTheme.accent)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 18)
                        .accessibilityLabel("جاري تحميل الصفحة")
                }
            }
        }
        .navigationTitle("بحث المقارنة")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppBackground())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("إغلاق") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Link(destination: activeURL) {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("فتح في Safari")
            }
        }
    }

    private func loadAddress() {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "اكتب كلمة بحث أو رابطًا يبدأ بـ https://"
            return
        }

        if let url = URL(string: trimmed), url.scheme?.lowercased() == "https", url.host?.isEmpty == false {
            validationMessage = nil
            activeURL = url
            return
        }

        // An explicit non-HTTPS address is rejected rather than silently searched for it, so the
        // user understands why their link did not open.
        if let scheme = URL(string: trimmed)?.scheme?.lowercased(), scheme != "https" {
            validationMessage = "نفتح الروابط الآمنة فقط (https). بحثنا عن النص بدلًا من ذلك."
            openSearch(trimmed, keepingValidationMessage: true)
            return
        }

        if let url = URL(string: "https://\(trimmed)"), url.host?.contains(".") == true {
            validationMessage = nil
            address = url.absoluteString
            activeURL = url
            return
        }

        openSearch(trimmed)
    }

    private func openSearch(_ query: String, keepingValidationMessage: Bool = false) {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        let url = components?.url ?? ResearchBrowserDefaults.searchURL
        if !keepingValidationMessage {
            validationMessage = nil
        }
        address = url.absoluteString
        activeURL = url
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    var isLoading: Binding<Bool>?
    var loadFailure: Binding<String?>?

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: isLoading, loadFailure: loadFailure)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        context.coordinator.requestedURL = url
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.isLoading = isLoading
        context.coordinator.loadFailure = loadFailure
        // Compare against the URL this view last asked for, not the web view's current URL:
        // once the user browses onwards those differ, and reloading here would yank them back
        // to the starting page on every unrelated SwiftUI update.
        guard context.coordinator.requestedURL != url else { return }
        context.coordinator.requestedURL = url
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30))
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var requestedURL: URL?
        var isLoading: Binding<Bool>?
        var loadFailure: Binding<String?>?

        init(isLoading: Binding<Bool>?, loadFailure: Binding<String?>?) {
            self.isLoading = isLoading
            self.loadFailure = loadFailure
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading?.wrappedValue = true
            loadFailure?.wrappedValue = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading?.wrappedValue = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            finish(with: error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            finish(with: error)
        }

        private func finish(with error: Error) {
            isLoading?.wrappedValue = false
            // A cancelled load is what happens when the user navigates again mid-request; it is
            // not a failure worth surfacing.
            guard (error as? URLError)?.code != .cancelled else { return }
            loadFailure?.wrappedValue = "تعذر فتح الصفحة. تحقق من الاتصال أو جرّب رابطًا آخر."
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
                KnowledgeDetailHero(item: item)

                if !item.idealFor.isEmpty {
                    InfoTile(title: "الأنسب لـ", values: item.idealFor, color: WeshTheme.secondaryAccent)
                }
                InfoTile(title: "نقاط القوة", values: item.strengths, color: WeshTheme.accent)
                InfoTile(title: "الملاحظات", values: item.considerations, color: WeshTheme.gold)

                if !item.specs.isEmpty {
                    SpecificationCard(item: item)
                }

                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        Label("جودة البيانات", systemImage: "checkmark.shield.fill")
                            .font(.headline)
                        Spacer()
                        WeshPill(item.dataQuality, color: WeshTheme.accent)
                    }
                    Text("المعلومات مناسبة للمقارنة العامة وقد لا تشمل جميع التفاصيل أو التحديثات.")
                        .font(.footnote)
                        .foregroundStyle(WeshTheme.secondaryText)
                }
                .weshSurface(goldAccent: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("سؤال مقترح")
                        .font(.headline)
                    Text(item.suggestedQuestion)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(WeshTheme.primaryText)
                }
                .weshSurface()

                Button(action: useItem) {
                    Label("إضافته إلى مقارنة", systemImage: "plus")
                }
                .buttonStyle(WeshPrimaryButtonStyle())
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 18)
            .weshContentWidth()
        }
        .background(AppBackground())
        .navigationTitle("معلومات العنصر")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("إغلاق") { dismiss() }
            }
        }
    }
}

private struct KnowledgeDetailHero: View {
    let item: KnowledgeItem

    var body: some View {
        let color = WeshTheme.categoryColor(item.category)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                WeshIconTile(systemImage: item.category.systemImage, color: color, size: 54)
                Spacer()
                WeshPill(item.category.title, color: color)
            }
            Text(item.name)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(WeshTheme.primaryText)
            Text(item.summary)
                .font(.body)
                .foregroundStyle(WeshTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .weshSurface(emphasized: true)
        .accessibilityElement(children: .combine)
    }
}

private struct SpecificationCard: View {
    let item: KnowledgeItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader("المواصفات", systemImage: "list.bullet.rectangle")
            ForEach(Array(item.specs.keys.sorted().enumerated()), id: \.element) { index, key in
                HStack(alignment: .firstTextBaseline, spacing: 18) {
                    Text(key)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WeshTheme.secondaryText)
                    Spacer(minLength: 12)
                    Text(item.specs[key] ?? "")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WeshTheme.primaryText)
                        .multilineTextAlignment(.leading)
                }
                if index < item.specs.count - 1 {
                    Divider().overlay(WeshTheme.hairline)
                }
            }
        }
        .weshSurface()
    }
}
