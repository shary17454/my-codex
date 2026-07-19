import Foundation
import Observation
import Security

struct ComparisonSearchService {
    static func filterQuestions(
        _ questions: [AskQuestion],
        category: AskCategory,
        query: String
    ) -> [AskQuestion] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        return questions
            .filter { category == .all || $0.category == category }
            .filter { question in
                guard !cleanQuery.isEmpty else { return true }
                return ([question.title, question.details, question.author] + question.options.map(\.title))
                    .joined(separator: " ")
                    .localizedCaseInsensitiveContains(cleanQuery)
            }
    }
}

@MainActor
@Observable
final class HomeViewModel {
    var questions: [AskQuestion]
    var knowledgeItems: [KnowledgeItem]
    var selectedCategory: AskCategory = .all
    var selectedSortMode: QuestionSortMode = .newest
    var searchText = ""
    var savedQuestionIDs: Set<UUID> = []
    var appErrorMessage: String?
    private(set) var isRefreshing = false
    private(set) var isOffline = false
    private(set) var lastUpdatedAt: Date?
    private(set) var pendingVoteQuestionIDs: Set<UUID> = []
    var isBackendEnabled: Bool
    var backendBaseURLText: String
    var backendAPITokenText: String

    init(
        questions: [AskQuestion] = AskDemoStore.questions,
        knowledgeItems: [KnowledgeItem] = AskDemoStore.knowledgeItems
    ) {
        self.questions = questions
        self.knowledgeItems = knowledgeItems
        self.isBackendEnabled = BackendSettingsStore.shared.isEnabled
        self.backendBaseURLText = BackendSettingsStore.shared.baseURLText
        self.backendAPITokenText = BackendSettingsStore.shared.apiTokenText
    }

    var totalVotes: Int {
        questions.reduce(0) { $0 + $1.totalVotes }
    }

    var dashboardStatistics: DashboardStatistics {
        let categoryGroups = Dictionary(grouping: questions, by: \.category)
        let topCategory = categoryGroups
            .filter { $0.key != .all }
            .max { lhs, rhs in
                if lhs.value.count == rhs.value.count {
                    return lhs.value.reduce(0) { $0 + $1.totalVotes } < rhs.value.reduce(0) { $0 + $1.totalVotes }
                }
                return lhs.value.count < rhs.value.count
            }?
            .key ?? .other

        let mostVoted = questions
            .filter { $0.totalVotes > 0 }
            .max { lhs, rhs in
                if lhs.totalVotes == rhs.totalVotes {
                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedDescending
                }
                return lhs.totalVotes < rhs.totalVotes
            }?
            .title ?? "لا توجد تصويتات بعد"
        let closeCount = questions.filter {
            let summary = DecisionSummaryService.makeSummary(for: $0)
            return summary.clarity == .close || summary.clarity == .insufficientData
        }.count

        return DashboardStatistics(
            totalComparisons: questions.count,
            totalVotes: totalVotes,
            totalReasons: questions.reduce(0) { $0 + $1.comments.filter { $0.optionID != nil }.count },
            savedCount: savedQuestionIDs.count,
            topCategory: topCategory,
            mostVotedTitle: mostVoted,
            closeResultCount: closeCount
        )
    }

    var filteredQuestions: [AskQuestion] {
        let filtered = ComparisonSearchService.filterQuestions(
            questions,
            category: selectedCategory,
            query: searchText
        )
        return sortedQuestions(filtered)
    }

    var filteredKnowledge: [KnowledgeItem] {
        KnowledgeSearchIndex.search(
            knowledgeItems,
            query: searchText,
            category: selectedCategory
        )
    }

    func relatedQuestions(to question: AskQuestion, limit: Int = 4) -> [AskQuestion] {
        let sourceTokens = Set(
            KnowledgeSearchIndex.normalize(([question.title, question.details] + question.options.map(\.title)).joined(separator: " "))
                .split(separator: " ")
                .map(String.init)
                .filter { $0.count > 2 }
        )

        return questions
            .filter { $0.id != question.id }
            .map { candidate in
                let candidateTokens = Set(
                    KnowledgeSearchIndex.normalize(([candidate.title, candidate.details] + candidate.options.map(\.title)).joined(separator: " "))
                        .split(separator: " ")
                        .map(String.init)
                        .filter { $0.count > 2 }
                )
                let sharedTokens = sourceTokens.intersection(candidateTokens).count
                let categoryScore = candidate.category == question.category ? 8 : 0
                let voteScore = min(candidate.totalVotes / 10, 6)
                return (question: candidate, score: sharedTokens + categoryScore + voteScore)
            }
            .filter { $0.score > 0 }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.question.totalVotes > rhs.question.totalVotes
                }
                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map(\.question)
    }

    func question(fromDeepLink url: URL) -> AskQuestion? {
        guard url.scheme == "weshalray",
              url.host == "comparison",
              let idString = url.pathComponents.dropFirst().first,
              let questionID = UUID(uuidString: idString) else {
            return nil
        }
        return questions.first { $0.id == questionID }
    }

    private func sortedQuestions(_ questions: [AskQuestion]) -> [AskQuestion] {
        switch selectedSortMode {
        case .newest:
            return questions
        case .mostVoted:
            return questions.sorted { $0.totalVotes > $1.totalVotes }
        case .mostDiscussed:
            return questions.sorted { $0.comments.count > $1.comments.count }
        case .clearestDecision:
            return questions.sorted {
                DecisionSummaryService.makeSummary(for: $0).voteGapPercentage > DecisionSummaryService.makeSummary(for: $1).voteGapPercentage
            }
        case .closeResults:
            return questions.sorted {
                DecisionSummaryService.makeSummary(for: $0).voteGapPercentage < DecisionSummaryService.makeSummary(for: $1).voteGapPercentage
            }
        }
    }

    func loadSavedQuestionIDs() async {
        savedQuestionIDs = (try? await LocalBookmarkRepository.shared.fetchSavedComparisonIDs()) ?? []
    }

    func saveBackendSettings() {
        BackendSettingsStore.shared.save(
            isEnabled: isBackendEnabled,
            baseURLText: backendBaseURLText,
            apiTokenText: backendAPITokenText
        )
    }

    func refreshFromBackend() async {
        guard isBackendEnabled, let client = makeBackendClient() else { return }
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let remoteQuestions = try await client.fetchComparisons(category: selectedCategory == .all ? nil : selectedCategory)
            questions = remoteQuestions.isEmpty ? questions : remoteQuestions
            appErrorMessage = nil
            isOffline = false
            lastUpdatedAt = Date()
        } catch {
            appErrorMessage = userFacingMessage(for: error)
            isOffline = (error as? URLError)?.code == .notConnectedToInternet
        }
    }

    func publishQuestion(_ question: AskQuestion) async -> AskQuestion? {
        guard isBackendEnabled else {
            insertPublishedQuestion(question)
            return question
        }
        guard let client = makeBackendClient() else { return nil }

        do {
            let remote = try await client.createComparison(question: question)
            questions.insert(remote, at: 0)
            appErrorMessage = nil
            return remote
        } catch {
            appErrorMessage = userFacingMessage(for: error)
            return nil
        }
    }

    func insertPublishedQuestion(_ question: AskQuestion) {
        questions.insert(question, at: 0)
    }

    func vote(questionID: AskQuestion.ID, optionID: PollOption.ID) async -> AskQuestion? {
        await submitVote(
            questionID: questionID,
            optionID: optionID,
            reason: nil,
            authorName: "مستخدم",
            reasonCategory: nil,
            isVerifiedExperience: false
        )
    }

    func voteWithReason(
        questionID: AskQuestion.ID,
        optionID: PollOption.ID,
        reason: String,
        authorName: String,
        reasonCategory: String? = nil,
        isVerifiedExperience: Bool = false
    ) async -> AskQuestion? {
        await submitVote(
            questionID: questionID,
            optionID: optionID,
            reason: reason,
            authorName: authorName,
            reasonCategory: reasonCategory,
            isVerifiedExperience: isVerifiedExperience
        )
    }

    private func submitVote(
        questionID: AskQuestion.ID,
        optionID: PollOption.ID,
        reason: String?,
        authorName: String,
        reasonCategory: String?,
        isVerifiedExperience: Bool
    ) async -> AskQuestion? {
        guard !pendingVoteQuestionIDs.contains(questionID),
              let questionIndex = questions.firstIndex(where: { $0.id == questionID }),
              questions[questionIndex].options.contains(where: { $0.id == optionID }) else {
            return questions.first { $0.id == questionID }
        }

        pendingVoteQuestionIDs.insert(questionID)
        defer { pendingVoteQuestionIDs.remove(questionID) }

        let cleanReason = reason?.trimmingCharacters(in: .whitespacesAndNewlines)

        if isBackendEnabled {
            guard let client = makeBackendClient() else {
                return questions.first { $0.id == questionID }
            }
            do {
                let remoteQuestion = try await client.vote(
                    comparisonID: questionID,
                    optionID: optionID,
                    authorName: authorName,
                    reason: cleanReason?.isEmpty == true ? nil : cleanReason,
                    reasonCategory: reasonCategory,
                    isVerifiedExperience: isVerifiedExperience
                )
                if let updatedIndex = questions.firstIndex(where: { $0.id == questionID }) {
                    questions[updatedIndex] = remoteQuestion
                }
                appErrorMessage = nil
                return remoteQuestion
            } catch {
                appErrorMessage = userFacingMessage(for: error)
                return questions.first { $0.id == questionID }
            }
        }

        do {
            _ = try await LocalVotingRepository.shared.vote(
                comparisonID: questionID,
                optionID: optionID,
                reason: cleanReason?.isEmpty == true ? nil : cleanReason,
                isAnonymous: authorName == "مجهول"
            )
            appErrorMessage = nil
            return applyLocalVote(
                questionID: questionID,
                optionID: optionID,
                reason: cleanReason,
                authorName: authorName,
                reasonCategory: reasonCategory,
                isVerifiedExperience: isVerifiedExperience
            )
        } catch {
            appErrorMessage = userFacingMessage(for: error)
            return questions.first { $0.id == questionID }
        }
    }

    private func applyLocalVote(
        questionID: AskQuestion.ID,
        optionID: PollOption.ID,
        reason: String?,
        authorName: String,
        reasonCategory: String?,
        isVerifiedExperience: Bool
    ) -> AskQuestion? {
        guard let questionIndex = questions.firstIndex(where: { $0.id == questionID }),
              let optionIndex = questions[questionIndex].options.firstIndex(where: { $0.id == optionID }) else {
            return nil
        }

        let option = questions[questionIndex].options[optionIndex]
        questions[questionIndex].options[optionIndex].votes += 1

        let cleanReason = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !cleanReason.isEmpty {
            questions[questionIndex].comments.insert(
                AskComment(
                    author: authorName,
                    text: cleanReason,
                    likes: 0,
                    optionID: option.id,
                    optionTitle: option.title,
                    trustBadge: isVerifiedExperience ? "مجرّب فعليًا" : nil,
                    reasonCategory: reasonCategory
                ),
                at: 0
            )
        }

        return questions[questionIndex]
    }

    func addComment(questionID: AskQuestion.ID, text: String, authorName: String) -> AskQuestion? {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty,
              let questionIndex = questions.firstIndex(where: { $0.id == questionID }) else {
            return nil
        }

        questions[questionIndex].comments.insert(
            AskComment(author: authorName, text: cleanText, likes: 0),
            at: 0
        )
        pushCommentIfNeeded(questionID: questionID, text: cleanText, authorName: authorName)
        return questions[questionIndex]
    }

    func toggleSavedQuestion(questionID: AskQuestion.ID) async {
        do {
            if savedQuestionIDs.contains(questionID) {
                try await LocalBookmarkRepository.shared.removeSavedComparison(id: questionID)
                savedQuestionIDs.remove(questionID)
            } else {
                try await LocalBookmarkRepository.shared.saveComparison(id: questionID)
                savedQuestionIDs.insert(questionID)
            }
        } catch {
            appErrorMessage = userFacingMessage(for: error)
        }
    }

    private func makeBackendClient() -> WeshAlrayAPIClient? {
        guard let url = URL(string: backendBaseURLText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            appErrorMessage = "عنوان Backend غير صحيح."
            return nil
        }
        let cleanToken = backendAPITokenText.trimmingCharacters(in: .whitespacesAndNewlines)
        return WeshAlrayAPIClient(baseURL: url, apiToken: cleanToken.isEmpty ? nil : cleanToken)
    }

    private func userFacingMessage(for error: Error) -> String {
        if let appError = error as? AppError {
            return appError.errorDescription ?? "حدث خطأ غير متوقع."
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return AppError.networkUnavailable.errorDescription ?? "لا يوجد اتصال بالإنترنت."
            case .timedOut:
                return "استغرق الاتصال وقتًا أطول من المتوقع. حاول مرة أخرى."
            default:
                return AppError.serviceUnavailable.errorDescription ?? "الخدمة غير متاحة حاليًا."
            }
        }
        return AppError.unknown(error).errorDescription ?? "حدث خطأ غير متوقع."
    }

    private func pushCommentIfNeeded(questionID: AskQuestion.ID, text: String, authorName: String) {
        guard isBackendEnabled, let client = makeBackendClient() else { return }
        Task {
            do {
                _ = try await client.addComment(comparisonID: questionID, text: text, authorName: authorName)
            } catch {
                await MainActor.run {
                    appErrorMessage = userFacingMessage(for: error)
                }
            }
        }
    }
}

final class BackendSettingsStore: @unchecked Sendable {
    static let shared = BackendSettingsStore()
    private let enabledKey = "wash_alray_backend_enabled"
    private let baseURLKey = "wash_alray_backend_base_url"

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    var baseURLText: String {
        UserDefaults.standard.string(forKey: baseURLKey) ?? "http://localhost:8787"
    }

    var apiTokenText: String {
        BackendAPITokenStore.load()
    }

    func save(isEnabled: Bool, baseURLText: String, apiTokenText: String) {
        UserDefaults.standard.set(isEnabled, forKey: enabledKey)
        UserDefaults.standard.set(baseURLText.trimmingCharacters(in: .whitespacesAndNewlines), forKey: baseURLKey)
        BackendAPITokenStore.save(apiTokenText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

enum BackendAPITokenStore {
    private static let service = "com.weshalray.backend"
    private static let account = "api-token"

    static func load() -> String {
        var query: [String: Any] = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return ""
        }
        return token
    }

    static func save(_ token: String) {
        delete()
        guard !token.isEmpty, let data = token.data(using: .utf8) else { return }
        var attributes: [String: Any] = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

struct WeshAlrayAPIClient: Sendable {
    let baseURL: URL
    let apiToken: String?
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL, apiToken: String?, session: URLSession? = nil) {
        self.baseURL = baseURL
        self.apiToken = apiToken
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 15
            configuration.timeoutIntervalForResource = 30
            configuration.waitsForConnectivity = true
            self.session = URLSession(configuration: configuration)
        }
    }

    func fetchComparisons(category: AskCategory?) async throws -> [AskQuestion] {
        var components = URLComponents(url: baseURL.appendingPathComponent("/api/v1/comparisons"), resolvingAgainstBaseURL: false)
        if let category {
            components?.queryItems = [URLQueryItem(name: "category", value: category.rawValue)]
        }
        guard let url = components?.url else { throw AppError.invalidInput("عنوان Backend غير صحيح.") }
        let response: ComparisonListResponse = try await get(url)
        return response.comparisons.map(\.askQuestion)
    }

    func createComparison(question: AskQuestion) async throws -> AskQuestion {
        let request = CreateComparisonRequest(
            title: question.title,
            details: question.details,
            category: question.category.rawValue,
            author: question.author,
            isAnonymous: question.author == "مجهول",
            allowsComments: true,
            allowsVoteReasons: true,
            tags: [],
            options: question.options.map { CreateOptionRequest(title: $0.title) }
        )
        let response: RemoteComparison = try await post(path: "/api/v1/comparisons", body: request)
        return response.askQuestion
    }

    func vote(
        comparisonID: UUID,
        optionID: UUID,
        authorName: String,
        reason: String?,
        reasonCategory: String?,
        isVerifiedExperience: Bool
    ) async throws -> AskQuestion {
        let request = VoteRequest(
            optionID: optionID.uuidString,
            author: authorName,
            reason: reason,
            reasonCategory: reasonCategory,
            isVerifiedExperience: isVerifiedExperience,
            isAnonymous: false
        )
        let response: VoteResponse = try await post(path: "/api/v1/comparisons/\(comparisonID.uuidString)/votes", body: request)
        return response.comparison.askQuestion
    }

    func addComment(comparisonID: UUID, text: String, authorName: String) async throws -> RemoteComment {
        try await post(path: "/api/v1/comparisons/\(comparisonID.uuidString)/comments", body: CommentRequest(author: authorName, text: text))
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        try validate(response: response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func post<Body: Encodable, Response: Decodable>(path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue(DeviceClientID.value, forHTTPHeaderField: "x-client-id")
        if let apiToken, !apiToken.isEmpty {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "authorization")
        }
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try decoder.decode(Response.self, from: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw AppError.serviceUnavailable }
        guard (200..<300).contains(http.statusCode) else {
            let apiError = try? decoder.decode(APIErrorResponse.self, from: data)
            throw AppError.invalidInput(apiError?.error.message ?? "تعذر الاتصال بالـBackend.")
        }
    }
}

enum DeviceClientID {
    private static let key = "wash_alray_device_client_id"

    static var value: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: key)
        return created
    }
}

private struct APIErrorResponse: Decodable {
    let error: APIErrorBody
}

private struct APIErrorBody: Decodable {
    let message: String
}

private struct ComparisonListResponse: Decodable {
    let comparisons: [RemoteComparison]
}

private struct RemoteComparison: Decodable {
    let id: UUID
    let title: String
    let details: String
    let category: String
    let author: String
    let createdAt: String
    let options: [RemoteOption]
    let comments: [RemoteComment]

    var askQuestion: AskQuestion {
        AskQuestion(
            id: id,
            title: title,
            details: details,
            category: AskCategory(rawValue: category) ?? .other,
            author: author,
            timeAgo: "من الخادم",
            options: options.map { PollOption(id: $0.id, title: $0.title, votes: $0.votes) },
            comments: comments.map(\.askComment)
        )
    }
}

private struct RemoteOption: Decodable {
    let id: UUID
    let title: String
    let votes: Int
}

struct RemoteComment: Decodable {
    let id: UUID
    let optionID: UUID?
    let optionTitle: String?
    let author: String
    let text: String
    let likes: Int
    let trustBadge: String?
    let reasonCategory: String?

    var askComment: AskComment {
        AskComment(
            id: id,
            author: author,
            text: text,
            likes: likes,
            optionID: optionID,
            optionTitle: optionTitle,
            trustBadge: trustBadge,
            reasonCategory: reasonCategory
        )
    }
}

private struct CreateComparisonRequest: Encodable {
    let title: String
    let details: String
    let category: String
    let author: String
    let isAnonymous: Bool
    let allowsComments: Bool
    let allowsVoteReasons: Bool
    let tags: [String]
    let options: [CreateOptionRequest]
}

private struct CreateOptionRequest: Encodable {
    let title: String
}

private struct VoteRequest: Encodable {
    let optionID: String
    let author: String
    let reason: String?
    let reasonCategory: String?
    let isVerifiedExperience: Bool
    let isAnonymous: Bool
}

private struct VoteResponse: Decodable {
    let comparison: RemoteComparison
}

private struct CommentRequest: Encodable {
    let author: String
    let text: String
}

final class LocalReportStore: @unchecked Sendable {
    static let shared = LocalReportStore()
    private let key = "wash_alray_content_reports"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func save(_ report: ContentReport) {
        var reports = load()
        reports.append(report)
        guard let data = try? encoder.encode(reports) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func load() -> [ContentReport] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let reports = try? decoder.decode([ContentReport].self, from: data) else {
            return []
        }
        return reports
    }
}

@MainActor
@Observable
final class CreateComparisonViewModel {
    var title: String
    var details: String
    var category: AskCategory
    var optionCount: Int
    var optionTitles: [String]
    var tagsText = ""
    var isAnonymous = false
    var allowsComments = true
    var allowsVoteReasons = true
    var voteDuration: VoteDurationOption = .oneWeek
    var validationMessage: String?
    var didPublish = false

    init(template: KnowledgeItem? = nil) {
        title = template?.suggestedQuestion ?? ""
        details = template?.summary ?? ""
        category = template?.category ?? .phones
        optionCount = template == nil ? 2 : 3

        var options = Array(repeating: "", count: 10)
        if let template {
            options[0] = template.name
            options[1] = "بديل مشابه"
            options[2] = "أحتاج اقتراح ثالث"
        }
        optionTitles = options
    }

    var completedOptions: [String] {
        optionTitles
            .prefix(optionCount)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && completedOptions.count >= 2
    }

    var currentDraft: ComparisonDraft {
        ComparisonDraft(
            title: title,
            description: details,
            category: ComparisonCategory(rawValue: category.rawValue) ?? .other,
            options: optionTitles
                .prefix(optionCount)
                .map { ComparisonOptionDraft(title: $0) },
            expiresAt: voteDuration.expiryDate,
            isAnonymous: isAnonymous,
            allowsComments: allowsComments,
            allowsVoteReasons: allowsVoteReasons,
            tags: tagsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }

    func restoreDraftIfNeeded() {
        guard title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let draft = LocalDraftStore.shared.load() else { return }

        title = draft.title
        details = draft.description
        category = draft.category.askCategory
        tagsText = draft.tags.joined(separator: ", ")
        isAnonymous = draft.isAnonymous
        allowsComments = draft.allowsComments
        allowsVoteReasons = draft.allowsVoteReasons
        voteDuration = durationOption(for: draft.expiresAt)
        optionCount = min(max(draft.options.count, 2), 10)

        var restored = Array(repeating: "", count: 10)
        for (index, option) in draft.options.prefix(10).enumerated() {
            restored[index] = option.title
        }
        optionTitles = restored
    }

    func saveDraft() {
        LocalDraftStore.shared.save(currentDraft)
        validationMessage = "تم حفظ المسودة محليًا."
    }

    func applyQuickPrompt(_ prompt: String) {
        title = prompt
        let parts = prompt
            .replacingOccurrences(of: "؟", with: "")
            .components(separatedBy: " أم ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if parts.count >= 2 {
            optionCount = min(max(parts.count, 2), 10)
            for index in 0..<optionTitles.count {
                optionTitles[index] = index < parts.count ? parts[index] : optionTitles[index]
            }
        }

        category = inferredCategory(from: prompt)
        if details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            details = "ساعدني أقرر بناءً على التجربة والسعر والجودة والقيمة."
        }
    }

    func saveDraftOnDismissIfNeeded() {
        if !didPublish && (!canSave || !completedOptions.isEmpty) {
            LocalDraftStore.shared.save(currentDraft)
        }
    }

    func makeQuestion(authorName: String) throws -> AskQuestion {
        do {
            try ComparisonValidationService.validate(draft: currentDraft)
        } catch {
            validationMessage = error.localizedDescription
            throw error
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return AskQuestion(
            title: cleanTitle,
            details: cleanDetails.isEmpty ? "ساعد صاحب السؤال بالتصويت أو التعليق." : cleanDetails,
            category: category,
            author: isAnonymous ? "مجهول" : authorName,
            timeAgo: "الآن",
            options: completedOptions.map { PollOption(title: $0, votes: 0) },
            comments: []
        )
    }

    func markPublished() {
        didPublish = true
        validationMessage = nil
        LocalDraftStore.shared.clear()
    }

    private func durationOption(for expiryDate: Date?) -> VoteDurationOption {
        guard let expiryDate else { return .open }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 7
        return VoteDurationOption.allCases.min { lhs, rhs in
            abs(lhs.rawValue - days) < abs(rhs.rawValue - days)
        } ?? .oneWeek
    }

    private func inferredCategory(from prompt: String) -> AskCategory {
        let normalized = KnowledgeSearchIndex.normalize(prompt)
        if normalized.contains("ايفون") || normalized.contains("سامسونج") || normalized.contains("جوال") {
            return .phones
        }
        if normalized.contains("كامري") || normalized.contains("اكورد") || normalized.contains("سياره") {
            return .cars
        }
        if normalized.contains("مطعم") || normalized.contains("برجر") {
            return .restaurants
        }
        if normalized.contains("لابتوب") || normalized.contains("ماك") || normalized.contains("ويندوز") {
            return .laptops
        }
        if normalized.contains("شحن") || normalized.contains("خدمه") {
            return .services
        }
        if normalized.contains("بث") || normalized.contains("اشتراك") {
            return .subscriptions
        }
        return category
    }
}
