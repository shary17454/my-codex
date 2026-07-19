import SwiftUI

private enum AppTab: Hashable {
    case home
    case questions
    case compare
    case library
    case account
}

struct ContentView: View {
    @StateObject private var userSession = UserSession()
    @State private var homeViewModel = HomeViewModel()
    @State private var selectedTab: AppTab = .home
    @State private var selectedQuestion: AskQuestion?
    @State private var selectedKnowledgeItem: KnowledgeItem?
    @State private var showingComposer = false
    @State private var showingResearchBrowser = false
    @State private var composerTemplate: KnowledgeItem?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(
                    questions: homeViewModel.questions,
                    knowledgeItems: homeViewModel.knowledgeItems,
                    statistics: homeViewModel.dashboardStatistics,
                    isRefreshing: homeViewModel.isRefreshing,
                    isOffline: homeViewModel.isOffline,
                    refresh: {
                        await homeViewModel.refreshFromBackend()
                    },
                    openQuestion: { question in
                        selectedQuestion = question
                    },
                    openSmartCompare: {
                        selectedTab = .compare
                    },
                    startQuestion: { item in
                        composerTemplate = item
                        showingComposer = true
                    }
                )
            }
            .tabItem {
                Label("الرئيسية", systemImage: "house")
            }
            .tag(AppTab.home)

            NavigationStack {
                QuestionListView(
                    questions: homeViewModel.filteredQuestions,
                    selectedCategory: $homeViewModel.selectedCategory,
                    selectedSortMode: $homeViewModel.selectedSortMode,
                    searchText: $homeViewModel.searchText,
                    selectedQuestion: $selectedQuestion,
                    showingComposer: $showingComposer,
                    refresh: {
                        await homeViewModel.refreshFromBackend()
                    }
                )
            }
            .tabItem {
                Label("اكتشف", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(AppTab.questions)

            NavigationStack {
                SmartComparisonView(items: homeViewModel.knowledgeItems, isPresentedModally: false)
            }
            .tabItem {
                Label("قارن", systemImage: "slider.horizontal.3")
            }
            .tag(AppTab.compare)

            NavigationStack {
                KnowledgeLibraryView(
                    items: homeViewModel.filteredKnowledge,
                    selectedCategory: $homeViewModel.selectedCategory,
                    searchText: $homeViewModel.searchText,
                    selectedItem: $selectedKnowledgeItem,
                    useItem: { item in
                        composerTemplate = item
                        showingComposer = true
                    },
                    openResearch: {
                        showingResearchBrowser = true
                    },
                    refresh: {
                        await homeViewModel.refreshFromBackend()
                    }
                )
            }
            .tabItem {
                Label("المكتبة", systemImage: "books.vertical")
            }
            .tag(AppTab.library)

            NavigationStack {
                AccountView(
                    userSession: userSession,
                    statistics: homeViewModel.dashboardStatistics,
                    isBackendEnabled: $homeViewModel.isBackendEnabled,
                    backendBaseURLText: $homeViewModel.backendBaseURLText,
                    backendAPITokenText: $homeViewModel.backendAPITokenText,
                    saveBackendSettings: {
                        homeViewModel.saveBackendSettings()
                    },
                    refreshBackend: {
                        Task {
                            await homeViewModel.refreshFromBackend()
                        }
                    }
                )
            }
            .tabItem {
                Label("الحساب", systemImage: "person.crop.circle")
            }
            .tag(AppTab.account)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .tint(WeshTheme.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $showingComposer) {
            NewQuestionView(template: composerTemplate, authorName: userSession.publicName) { question in
                let published = await homeViewModel.publishQuestion(question)
                if let published {
                    selectedQuestion = published
                    composerTemplate = nil
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
        .sheet(isPresented: $showingResearchBrowser) {
            NavigationStack {
                ResearchBrowserView()
            }
            .environment(\.layoutDirection, .rightToLeft)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await homeViewModel.loadSavedQuestionIDs()
            await homeViewModel.refreshFromBackend()
        }
        .onOpenURL { url in
            if let question = homeViewModel.question(fromDeepLink: url) {
                selectedQuestion = question
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

    private func vote(questionID: AskQuestion.ID, optionID: PollOption.ID) {
        Task {
            selectedQuestion = await homeViewModel.vote(questionID: questionID, optionID: optionID)
        }
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
        Task {
            selectedQuestion = await homeViewModel.voteWithReason(
                questionID: questionID,
                optionID: optionID,
                reason: reason,
                authorName: userSession.publicName,
                reasonCategory: reasonCategory,
                isVerifiedExperience: isVerifiedExperience
            )
        }
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
