import SwiftUI

private enum AppTab: String, CaseIterable, Hashable, Identifiable {
    case home
    case questions
    case compare
    case library
    case account

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "الرئيسية"
        case .questions: "اكتشف"
        case .compare: "قارن"
        case .library: "المكتبة"
        case .account: "الحساب"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .questions: "safari.fill"
        case .compare: "slider.horizontal.3"
        case .library: "books.vertical.fill"
        case .account: "person.crop.circle.fill"
        }
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var userSession = UserSession()
    @StateObject private var notificationStore = WeshNotificationCenterStore.shared
    @State private var homeViewModel: HomeViewModel
    @State private var selectedTab: AppTab = .home
    @State private var selectedQuestion: AskQuestion?
    @State private var summaryQuestion: AskQuestion?
    @State private var selectedKnowledgeItem: KnowledgeItem?
    @State private var showingComposer = false
    @State private var showingResearchBrowser = false
    @State private var showingAIAssistant = false
    @State private var composerTemplate: KnowledgeItem?
    @State private var pendingComposerTitle = ""
    /// Cached because reading it hits SwiftData; recomputing it inside `body` would run a
    /// fetch on every re-render.
    @State private var hasSavedDraft = false
    let persistence: WeshPersistenceStore

    init(persistence: WeshPersistenceStore) {
        self.persistence = persistence
        _homeViewModel = State(initialValue: HomeViewModel(persistence: persistence))
    }

    private func refreshDraftAvailability() {
        hasSavedDraft = persistence.hasDraft()
    }

    private var compactTabs: [AppTab] {
        [.home, .questions, .library, .account]
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                sidebarLayout
            } else {
                compactTabLayout
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .tint(WeshTheme.accent)
        .sheet(isPresented: $showingComposer) {
            NewQuestionView(
                template: composerTemplate,
                initialTitle: pendingComposerTitle,
                persistence: persistence,
                backendClient: homeViewModel.optionalAIBackendClient(),
                authorName: userSession.publicName
            ) { question in
                let published = await homeViewModel.publishQuestion(question)
                if let published {
                    selectedQuestion = published
                    composerTemplate = nil
                    pendingComposerTitle = ""
                }
                return published
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedQuestion) { question in
            NavigationStack {
                QuestionDetail(
                    question: question,
                    relatedQuestions: homeViewModel.relatedQuestions(to: question),
                    voteAction: vote,
                    voteWithReasonAction: voteWithReason,
                    commentAction: addComment,
                    isVoteSubmitting: homeViewModel.pendingVoteQuestionIDs.contains(question.id),
                    hasVoted: homeViewModel.votedQuestionIDs.contains(question.id),
                    isSaved: homeViewModel.savedQuestionIDs.contains(question.id),
                    voteTrendPoints: homeViewModel.voteTrendsByComparisonID[question.id] ?? [],
                    outcome: homeViewModel.outcomesByComparisonID[question.id],
                    personalEvaluation: homeViewModel.personalEvaluationsByComparisonID[question.id],
                    saveAction: toggleSavedQuestion,
                    saveOutcomeAction: homeViewModel.saveOutcome,
                    savePersonalEvaluationAction: { evaluation in
                        homeViewModel.savePersonalEvaluation(evaluation, comparisonID: question.id)
                    },
                    reportAction: homeViewModel.submitContentReport,
                    followNotificationsAction: homeViewModel.followForNotifications,
                    hasPremiumAccess: userSession.hasOwnerAccess,
                    openRelatedQuestion: { related in
                        selectedQuestion = related
                    }
                )
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .sheet(item: $summaryQuestion) { question in
            NavigationStack {
                DecisionSummaryScreen(
                    question: question,
                    isSaved: homeViewModel.savedQuestionIDs.contains(question.id),
                    saveAction: { toggleSavedQuestion(questionID: question.id) }
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
        .sheet(isPresented: $showingResearchBrowser) {
            NavigationStack {
                ResearchBrowserView()
            }
            .environment(\.layoutDirection, .rightToLeft)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingAIAssistant) {
            AIDecisionAssistantView(
                questions: homeViewModel.questions,
                knowledgeItems: homeViewModel.knowledgeItems,
                backendClient: homeViewModel.optionalAIBackendClient()
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            WeshNotificationBackendBridge.shared.clientProvider = { homeViewModel.optionalAIBackendClient() }
            await notificationStore.refreshAuthorizationStatus()
            homeViewModel.loadPersistentState()
            refreshDraftAvailability()
            openPendingComparisonIntentIfNeeded()
            openComparisonFromNotificationIfNeeded()
            await homeViewModel.refreshFromBackend()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshDraftAvailability()
            openPendingComparisonIntentIfNeeded()
            openComparisonFromNotificationIfNeeded()
        }
        .onChange(of: notificationStore.pendingComparisonID) { _, _ in
            openComparisonFromNotificationIfNeeded()
        }
        .onChange(of: showingComposer) { _, isPresented in
            guard !isPresented else { return }
            composerTemplate = nil
            pendingComposerTitle = ""
            refreshDraftAvailability()
        }
        .onOpenURL { url in
            if let question = homeViewModel.question(fromDeepLink: url) {
                selectedQuestion = question
            } else if let inviteCode = homeViewModel.inviteCode(fromDeepLink: url) {
                Task {
                    if let questionID = homeViewModel.comparisonID(fromSharedURL: url) {
                        selectedQuestion = await homeViewModel.fetchSharedQuestion(id: questionID, inviteCode: inviteCode)
                    } else {
                        selectedQuestion = await homeViewModel.joinPrivateRoom(inviteCode: inviteCode)
                    }
                }
            } else if let questionID = homeViewModel.comparisonID(fromSharedURL: url) {
                Task {
                    selectedQuestion = await homeViewModel.fetchSharedQuestion(id: questionID, inviteCode: nil)
                }
            }
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

    private var compactTabLayout: some View {
        ZStack {
            tabDestination(selectedTab)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            WeshCompactTabBar(
                tabs: compactTabs,
                selection: $selectedTab,
                createAction: {
                    composerTemplate = nil
                    showingComposer = true
                }
            )
        }
    }

    private var sidebarLayout: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    WeshBrandMark(size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("وش الرأي")
                            .font(.title3.weight(.bold))
                        Text("قرارك أوضح.")
                            .font(.caption)
                            .foregroundStyle(WeshTheme.secondaryText)
                    }
                    Spacer()
                }
                .padding(18)

                List {
                    ForEach(AppTab.allCases) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            Label(tab.title, systemImage: tab.systemImage)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 7)
                                .foregroundStyle(selectedTab == tab ? WeshTheme.accent : WeshTheme.primaryText)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            selectedTab == tab
                                ? WeshTheme.accent.opacity(0.12)
                                : Color.clear
                        )
                        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                    }
                }
                .listStyle(.sidebar)

                Button {
                    composerTemplate = nil
                    showingComposer = true
                } label: {
                    Label("مقارنة جديدة", systemImage: "plus")
                }
                .buttonStyle(WeshPrimaryButtonStyle())
                .padding(16)
            }
            .background(AppBackground())
            .navigationSplitViewColumnWidth(min: 230, ideal: 270, max: 320)
        } detail: {
            tabDestination(selectedTab)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func tabDestination(_ tab: AppTab) -> some View {
        switch tab {
        case .home:
            NavigationStack {
                DashboardView(
                    questions: homeViewModel.questions,
                    knowledgeItems: homeViewModel.knowledgeItems,
                    statistics: homeViewModel.dashboardStatistics,
                    notificationStore: notificationStore,
                    userName: userSession.publicName,
                    isSignedIn: userSession.isSignedIn,
                    hasDraft: hasSavedDraft,
                    isRefreshing: homeViewModel.isRefreshing,
                    isOffline: homeViewModel.isOffline,
                    refresh: { await homeViewModel.refreshFromBackend() },
                    refreshNotifications: { await homeViewModel.refreshNotifications() },
                    enablePushNotifications: { await homeViewModel.enablePushNotifications() },
                    followForNotifications: { await homeViewModel.followForNotifications(questionID: $0) },
                    openQuestion: {
                        selectedQuestion = $0
                    },
                    openQuestionByID: { id in
                        selectedQuestion = homeViewModel.questions.first { $0.id == id }
                    },
                    openDecisionSummary: { summaryQuestion = $0 },
                    openAIAssistant: { showingAIAssistant = true },
                    openDiscover: { selectedTab = .questions },
                    openSmartCompare: { selectedTab = .compare },
                    startQuestion: { item in
                        composerTemplate = item
                        showingComposer = true
                    },
                    restoreDraft: {
                        composerTemplate = nil
                        showingComposer = true
                    }
                )
            }
        case .questions:
            NavigationStack {
                QuestionListView(
                    questions: homeViewModel.filteredQuestions,
                    selectedCategory: $homeViewModel.selectedCategory,
                    selectedSortMode: $homeViewModel.selectedSortMode,
                    searchText: $homeViewModel.searchText,
                    selectedQuestion: $selectedQuestion,
                    showingComposer: $showingComposer,
                    refresh: { await homeViewModel.refreshFromBackend() },
                    joinPrivateRoom: { code in
                        await homeViewModel.joinPrivateRoom(inviteCode: code)
                    }
                )
            }
        case .compare:
            NavigationStack {
                SmartComparisonView(items: homeViewModel.knowledgeItems, isPresentedModally: false)
            }
        case .library:
            NavigationStack {
                KnowledgeLibraryView(
                    items: homeViewModel.filteredKnowledge,
                    savedQuestions: homeViewModel.savedQuestions,
                    selectedCategory: $homeViewModel.selectedCategory,
                    searchText: $homeViewModel.searchText,
                    selectedItem: $selectedKnowledgeItem,
                    useItem: { item in
                        composerTemplate = item
                        showingComposer = true
                    },
                    openSavedQuestion: { selectedQuestion = $0 },
                    unsaveQuestion: toggleSavedQuestion,
                    openResearch: { showingResearchBrowser = true },
                    refresh: { await homeViewModel.refreshFromBackend() }
                )
            }
        case .account:
            NavigationStack {
                AccountView(
                    userSession: userSession,
                    statistics: homeViewModel.dashboardStatistics,
                    isBackendEnabled: $homeViewModel.isBackendEnabled,
                    backendBaseURLText: $homeViewModel.backendBaseURLText,
                    backendAPITokenText: $homeViewModel.backendAPITokenText,
                    adminOverview: homeViewModel.adminOverview,
                    saveBackendSettings: { homeViewModel.saveBackendSettings() },
                    refreshBackend: {
                        Task { await homeViewModel.refreshFromBackend() }
                    },
                    refreshAdminOverview: {
                        Task { await homeViewModel.refreshAdminOverview() }
                    }
                )
            }
        }
    }

    private func vote(questionID: AskQuestion.ID, optionID: PollOption.ID) {
        Task {
            // Keep the open sheet in place when the vote cannot be applied; assigning nil here
            // would dismiss the comparison the user is still reading.
            if let updated = await homeViewModel.vote(questionID: questionID, optionID: optionID) {
                selectedQuestion = updated
            }
        }
    }

    private func voteWithReason(questionID: AskQuestion.ID, optionID: PollOption.ID, reason: String) {
        voteWithReason(
            questionID: questionID,
            optionID: optionID,
            reason: reason,
            reasonCategory: nil,
            isVerifiedExperience: false
        )
    }

    private func voteWithReason(
        questionID: AskQuestion.ID,
        optionID: PollOption.ID,
        reason: String,
        reasonCategory: String?,
        isVerifiedExperience: Bool
    ) {
        Task {
            let updated = await homeViewModel.voteWithReason(
                questionID: questionID,
                optionID: optionID,
                reason: reason,
                authorName: userSession.publicName,
                reasonCategory: reasonCategory,
                isVerifiedExperience: isVerifiedExperience
            )
            if let updated {
                selectedQuestion = updated
            }
        }
    }

    private func addComment(questionID: AskQuestion.ID, text: String) {
        if let updated = homeViewModel.addComment(
            questionID: questionID,
            text: text,
            authorName: userSession.publicName
        ) {
            selectedQuestion = updated
        }
    }

    private func toggleSavedQuestion(questionID: AskQuestion.ID) {
        Task {
            await homeViewModel.toggleSavedQuestion(questionID: questionID)
        }
    }

    private func openPendingComparisonIntentIfNeeded() {
        if let title = PendingComparisonIntentStore.consumeTitle() {
            composerTemplate = nil
            pendingComposerTitle = title
            showingComposer = true
            return
        }
        guard let action = PendingComparisonIntentStore.consumeAction() else { return }
        switch action {
        case .openDiscover:
            selectedTab = .questions
        case .openLibrary:
            selectedTab = .library
        case .openLatestResult:
            selectedQuestion = homeViewModel.questions.first
        }
    }

    private func openComparisonFromNotificationIfNeeded() {
        guard let comparisonID = notificationStore.consumePendingComparisonID() else { return }
        if let question = homeViewModel.questions.first(where: { $0.id == comparisonID }) {
            selectedQuestion = question
        }
    }
}

private struct WeshCompactTabBar: View {
    let tabs: [AppTab]
    @Binding var selection: AppTab
    let createAction: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            tabButton(tabs[0])
            tabButton(tabs[1])
            createButton
            tabButton(tabs[2])
            tabButton(tabs[3])
        }
        .frame(height: 82)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(WeshTheme.hairline.opacity(0.9), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.18), radius: 18, y: -3)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("main-tab-bar")
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 19, weight: .semibold))
                Text(tab.title)
                    .font(.caption2.weight(selection == tab ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(selection == tab ? WeshTheme.accentBright : WeshTheme.secondaryText)
            .frame(maxWidth: .infinity, minHeight: 58)
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(selection == tab ? WeshTheme.accentBright : .clear)
                    .frame(width: 18, height: 3)
                    .offset(y: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab.\(tab.rawValue)")
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }

    private var createButton: some View {
        Button(action: createAction) {
            VStack(spacing: 2) {
                Image(systemName: "plus")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(WeshTheme.heroGradient, in: Circle())
                    .overlay { Circle().stroke(WeshTheme.goldBright.opacity(0.36), lineWidth: 1) }
                    .shadow(color: WeshTheme.accent.opacity(0.36), radius: 16, y: 6)
                Text("مقارنة جديدة")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WeshTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
            .offset(y: -9)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("مقارنة جديدة")
        .accessibilityIdentifier("tab.createComparison")
    }
}
