import Foundation
import Observation

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
    var searchText = ""
    var savedQuestionIDs: Set<UUID> = []
    var appErrorMessage: String?

    init(
        questions: [AskQuestion] = AskDemoStore.questions,
        knowledgeItems: [KnowledgeItem] = AskDemoStore.knowledgeItems
    ) {
        self.questions = questions
        self.knowledgeItems = knowledgeItems
    }

    var totalVotes: Int {
        questions.reduce(0) { $0 + $1.totalVotes }
    }

    var filteredQuestions: [AskQuestion] {
        ComparisonSearchService.filterQuestions(
            questions,
            category: selectedCategory,
            query: searchText
        )
    }

    var filteredKnowledge: [KnowledgeItem] {
        KnowledgeSearchIndex.search(
            knowledgeItems,
            query: searchText,
            category: selectedCategory
        )
    }

    func loadSavedQuestionIDs() async {
        savedQuestionIDs = (try? await LocalBookmarkRepository.shared.fetchSavedComparisonIDs()) ?? []
    }

    func insertPublishedQuestion(_ question: AskQuestion) {
        questions.insert(question, at: 0)
    }

    func vote(questionID: AskQuestion.ID, optionID: PollOption.ID) -> AskQuestion? {
        guard let questionIndex = questions.firstIndex(where: { $0.id == questionID }),
              let optionIndex = questions[questionIndex].options.firstIndex(where: { $0.id == optionID }) else {
            return nil
        }

        questions[questionIndex].options[optionIndex].votes += 1
        return questions[questionIndex]
    }

    func voteWithReason(
        questionID: AskQuestion.ID,
        optionID: PollOption.ID,
        reason: String,
        authorName: String,
        reasonCategory: String? = nil,
        isVerifiedExperience: Bool = false
    ) -> AskQuestion? {
        guard let questionIndex = questions.firstIndex(where: { $0.id == questionID }),
              let optionIndex = questions[questionIndex].options.firstIndex(where: { $0.id == optionID }) else {
            return nil
        }

        let option = questions[questionIndex].options[optionIndex]
        questions[questionIndex].options[optionIndex].votes += 1

        let cleanReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
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
            appErrorMessage = AppError.unknown(error).errorDescription
        }
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
            expiresAt: nil,
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
        didPublish = true
        LocalDraftStore.shared.clear()

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
}
