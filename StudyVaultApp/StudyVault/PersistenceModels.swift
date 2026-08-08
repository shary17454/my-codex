import Foundation
import OSLog
import SwiftData

@Model
final class ComparisonRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var detailsText: String
    var categoryRawValue: String
    var author: String
    var timeAgo: String
    var createdAt: Date
    var closesAt: Date?
    var isAnonymous: Bool
    var allowsReasons: Bool
    var allowsComments: Bool
    var tagsCSV: String
    var isPublished: Bool
    var visibilityRawValue: String
    var inviteCode: String?
    var hideResultsUntilVote: Bool

    @Relationship(deleteRule: .cascade, inverse: \ComparisonOptionRecord.comparison)
    var options: [ComparisonOptionRecord]

    @Relationship(deleteRule: .cascade, inverse: \ComparisonCommentRecord.comparison)
    var comments: [ComparisonCommentRecord]

    init(question: AskQuestion) {
        id = question.id
        title = question.title
        detailsText = question.details
        categoryRawValue = question.category.rawValue
        author = question.author
        timeAgo = question.timeAgo
        createdAt = question.createdAt
        closesAt = question.closesAt
        isAnonymous = question.isAnonymous
        allowsReasons = question.allowsReasons
        allowsComments = question.allowsComments
        tagsCSV = question.tags.joined(separator: ",")
        isPublished = question.isPublished
        visibilityRawValue = question.visibility.rawValue
        inviteCode = question.inviteCode
        hideResultsUntilVote = question.hideResultsUntilVote
        options = question.options.enumerated().map { index, option in
            ComparisonOptionRecord(option: option, sortIndex: index)
        }
        comments = question.comments.map(ComparisonCommentRecord.init)
        options.forEach { $0.comparison = self }
        comments.forEach { $0.comparison = self }
    }

    var tags: [String] {
        tagsCSV
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var askQuestion: AskQuestion {
        AskQuestion(
            id: id,
            title: title,
            details: detailsText,
            category: AskCategory(rawValue: categoryRawValue) ?? .other,
            author: author,
            timeAgo: timeAgo,
            options: options
                .sorted { $0.sortIndex < $1.sortIndex }
                .map { PollOption(id: $0.id, title: $0.name, votes: $0.voteCount) },
            comments: comments
                .sorted { $0.createdAt > $1.createdAt }
                .map(\.askComment),
            createdAt: createdAt,
            closesAt: closesAt,
            isAnonymous: isAnonymous,
            allowsReasons: allowsReasons,
            allowsComments: allowsComments,
            tags: tags,
            isPublished: isPublished,
            visibility: ComparisonVisibility(rawValue: visibilityRawValue) ?? .publicRoom,
            inviteCode: inviteCode,
            hideResultsUntilVote: hideResultsUntilVote
        )
    }
}

@Model
final class ComparisonOptionRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var detailsText: String
    var sortIndex: Int
    var voteCount: Int
    var comparison: ComparisonRecord?

    init(option: PollOption, sortIndex: Int) {
        id = option.id
        name = option.title
        detailsText = ""
        self.sortIndex = sortIndex
        voteCount = max(option.votes, 0)
    }
}

@Model
final class ComparisonCommentRecord {
    @Attribute(.unique) var id: UUID
    var author: String
    var text: String
    var likes: Int
    var optionID: UUID?
    var optionTitle: String?
    var trustBadge: String?
    var reasonCategory: String?
    var createdAt: Date
    var comparison: ComparisonRecord?

    init(comment: AskComment) {
        id = comment.id
        author = comment.author
        text = comment.text
        likes = max(comment.likes, 0)
        optionID = comment.optionID
        optionTitle = comment.optionTitle
        trustBadge = comment.trustBadge
        reasonCategory = comment.reasonCategory
        createdAt = comment.createdAt
    }

    var askComment: AskComment {
        AskComment(
            id: id,
            author: author,
            text: text,
            likes: likes,
            optionID: optionID,
            optionTitle: optionTitle,
            trustBadge: trustBadge,
            reasonCategory: reasonCategory,
            createdAt: createdAt
        )
    }
}

@Model
final class LocalVoteRecord {
    @Attribute(.unique) var id: UUID
    var comparisonID: UUID
    var optionID: UUID
    var reason: String
    var triedOption: Bool
    var isAnonymous: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        comparisonID: UUID,
        optionID: UUID,
        reason: String = "",
        triedOption: Bool = false,
        isAnonymous: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.comparisonID = comparisonID
        self.optionID = optionID
        self.reason = String(reason.prefix(300))
        self.triedOption = triedOption
        self.isAnonymous = isAnonymous
        self.createdAt = createdAt
    }
}

@Model
final class DecisionOutcomeRecord {
    @Attribute(.unique) var id: UUID
    var comparisonID: UUID
    var chosenOptionID: UUID
    var satisfactionScore: Int
    var wouldChooseAgain: Bool
    var note: String
    var createdAt: Date

    init(snapshot: DecisionOutcomeSnapshot) {
        id = snapshot.id
        comparisonID = snapshot.comparisonID
        chosenOptionID = snapshot.chosenOptionID
        satisfactionScore = snapshot.satisfactionScore
        wouldChooseAgain = snapshot.wouldChooseAgain
        note = snapshot.note
        createdAt = snapshot.createdAt
    }

    var snapshot: DecisionOutcomeSnapshot {
        DecisionOutcomeSnapshot(
            id: id,
            comparisonID: comparisonID,
            chosenOptionID: chosenOptionID,
            satisfactionScore: satisfactionScore,
            wouldChooseAgain: wouldChooseAgain,
            note: note,
            createdAt: createdAt
        )
    }
}

@Model
final class VoteTrendRecord {
    @Attribute(.unique) var id: UUID
    var comparisonID: UUID
    var optionID: UUID
    var optionName: String
    var createdAt: Date

    init(event: VoteTrendEvent) {
        id = event.id
        comparisonID = event.comparisonID
        optionID = event.optionID
        optionName = event.optionName
        createdAt = event.createdAt
    }

    var event: VoteTrendEvent {
        VoteTrendEvent(
            id: id,
            comparisonID: comparisonID,
            optionID: optionID,
            optionName: optionName,
            createdAt: createdAt
        )
    }
}

@Model
final class SavedComparisonRecord {
    @Attribute(.unique) var comparisonID: UUID
    var savedAt: Date

    init(comparisonID: UUID, savedAt: Date = Date()) {
        self.comparisonID = comparisonID
        self.savedAt = savedAt
    }
}

@Model
final class ComparisonDraftRecord {
    /// The app keeps a single in-progress draft, stored under this fixed key.
    nonisolated static let currentKey = "current"

    @Attribute(.unique) var key: String
    var payload: Data
    var updatedAt: Date

    init(key: String = ComparisonDraftRecord.currentKey, payload: Data, updatedAt: Date = Date()) {
        self.key = key
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

@Model
final class PersonalDecisionRecord {
    @Attribute(.unique) var comparisonID: UUID
    var payload: Data
    var updatedAt: Date

    init(comparisonID: UUID, payload: Data, updatedAt: Date = Date()) {
        self.comparisonID = comparisonID
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

enum PersistenceSetupError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "تعذر تجهيز التخزين المحلي الآمن. أعد تشغيل التطبيق وحاول مرة أخرى."
    }
}

@MainActor
final class WeshPersistenceStore {
    private static let logger = Logger(subsystem: "com.shary17454.esal", category: "Persistence")
    private static let legacyDraftKey = "wash_alray_comparison_draft"
    private static let legacyVotesKey = "wash_alray_local_votes"
    private static let legacyBookmarksKey = "wash_alray_saved_comparison_ids"
    private static let migrationKey = "wesh.persistence.migration.v1"

    let container: ModelContainer
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(container: ModelContainer) {
        self.container = container
    }

    static func makeContainer(inMemory: Bool = false, storeURL: URL? = nil) throws -> ModelContainer {
        let schema = Schema([
            ComparisonRecord.self,
            ComparisonOptionRecord.self,
            ComparisonCommentRecord.self,
            LocalVoteRecord.self,
            DecisionOutcomeRecord.self,
            VoteTrendRecord.self,
            SavedComparisonRecord.self,
            ComparisonDraftRecord.self,
            PersonalDecisionRecord.self
        ])
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration(
                "WeshAlRayLocal",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                "WeshAlRayLocal",
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                cloudKitDatabase: .none
            )
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    func bootstrap(seedQuestions: [AskQuestion]) throws -> [AskQuestion] {
        let context = ModelContext(container)
        var records = try context.fetch(FetchDescriptor<ComparisonRecord>())

        if records.isEmpty {
            let baseline = Date()
            for (index, original) in seedQuestions.enumerated() {
                var question = original
                question.createdAt = baseline.addingTimeInterval(-Double(index))
                let record = ComparisonRecord(question: question)
                context.insert(record)
            }
            try context.save()
            records = try context.fetch(FetchDescriptor<ComparisonRecord>())
        }

        try migrateLegacyData(in: context)
        records = try context.fetch(FetchDescriptor<ComparisonRecord>())
        return records.sorted { $0.createdAt > $1.createdAt }.map(\.askQuestion)
    }

    func questions() throws -> [AskQuestion] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<ComparisonRecord>())
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.askQuestion)
    }

    func upsert(question: AskQuestion) throws {
        let context = ModelContext(container)
        if let existing = try comparison(id: question.id, in: context) {
            update(existing, from: question, in: context)
        } else {
            context.insert(ComparisonRecord(question: question))
        }
        try context.save()
    }

    /// Fetches a single comparison by identifier instead of loading the whole table and
    /// filtering it in memory.
    private func comparison(id: UUID, in context: ModelContext) throws -> ComparisonRecord? {
        var descriptor = FetchDescriptor<ComparisonRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func hasVote(comparisonID: UUID, in context: ModelContext) throws -> Bool {
        var descriptor = FetchDescriptor<LocalVoteRecord>(
            predicate: #Predicate { $0.comparisonID == comparisonID }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).isEmpty == false
    }

    func recordVote(
        comparisonID: UUID,
        optionID: UUID,
        reason: String?,
        authorName: String,
        reasonCategory: String?,
        triedOption: Bool,
        isAnonymous: Bool
    ) throws {
        let context = ModelContext(container)
        guard try !hasVote(comparisonID: comparisonID, in: context) else {
            throw AppError.voteAlreadyExists
        }

        guard let comparison = try comparison(id: comparisonID, in: context) else {
            throw AppError.comparisonNotFound
        }
        guard comparison.closesAt.map({ $0 > Date() }) ?? true else {
            throw AppError.votingClosed
        }
        guard let option = comparison.options.first(where: { $0.id == optionID }) else {
            throw AppError.invalidInput("الخيار لا ينتمي إلى هذه المقارنة.")
        }

        let cleanReason = String((reason ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(300))
        let now = Date()
        context.insert(
            LocalVoteRecord(
                comparisonID: comparisonID,
                optionID: optionID,
                reason: cleanReason,
                triedOption: triedOption,
                isAnonymous: isAnonymous,
                createdAt: now
            )
        )
        context.insert(
            VoteTrendRecord(
                event: VoteTrendEvent(
                    id: UUID(),
                    comparisonID: comparisonID,
                    optionID: optionID,
                    optionName: option.name,
                    createdAt: now
                )
            )
        )
        option.voteCount += 1

        if !cleanReason.isEmpty && comparison.allowsReasons {
            let comment = AskComment(
                author: isAnonymous ? "مجهول" : authorName,
                text: cleanReason,
                likes: 0,
                optionID: optionID,
                optionTitle: option.name,
                trustBadge: triedOption ? "مجرّب فعليًا" : nil,
                reasonCategory: reasonCategory,
                createdAt: now
            )
            let record = ComparisonCommentRecord(comment: comment)
            record.comparison = comparison
            comparison.comments.append(record)
        }
        try context.save()
    }

    func recordRemoteVoteMarker(
        comparisonID: UUID,
        optionID: UUID,
        reason: String?,
        triedOption: Bool,
        isAnonymous: Bool
    ) throws {
        let context = ModelContext(container)
        guard try !hasVote(comparisonID: comparisonID, in: context) else { return }

        guard let comparison = try comparison(id: comparisonID, in: context) else {
            throw AppError.comparisonNotFound
        }
        guard comparison.options.contains(where: { $0.id == optionID }) else {
            throw AppError.invalidInput("الخيار لا ينتمي إلى هذه المقارنة.")
        }

        context.insert(
            LocalVoteRecord(
                comparisonID: comparisonID,
                optionID: optionID,
                reason: reason ?? "",
                triedOption: triedOption,
                isAnonymous: isAnonymous
            )
        )
        try context.save()
    }

    func addComment(comparisonID: UUID, comment: AskComment) throws {
        let context = ModelContext(container)
        guard let comparison = try comparison(id: comparisonID, in: context) else {
            throw AppError.comparisonNotFound
        }
        guard comparison.allowsComments else { throw AppError.forbidden }
        let record = ComparisonCommentRecord(comment: comment)
        record.comparison = comparison
        comparison.comments.append(record)
        try context.save()
    }

    func savedComparisonIDs() throws -> Set<UUID> {
        let context = ModelContext(container)
        return Set(try context.fetch(FetchDescriptor<SavedComparisonRecord>()).map(\.comparisonID))
    }

    func votedComparisonIDs() throws -> Set<UUID> {
        let context = ModelContext(container)
        return Set(try context.fetch(FetchDescriptor<LocalVoteRecord>()).map(\.comparisonID))
    }

    func setSaved(_ saved: Bool, comparisonID: UUID) throws {
        let context = ModelContext(container)
        let existing = try savedRecord(comparisonID: comparisonID, in: context)
        if saved {
            if existing == nil {
                context.insert(SavedComparisonRecord(comparisonID: comparisonID))
            }
        } else if let existing {
            context.delete(existing)
        }
        try context.save()
    }

    private func savedRecord(comparisonID: UUID, in context: ModelContext) throws -> SavedComparisonRecord? {
        var descriptor = FetchDescriptor<SavedComparisonRecord>(
            predicate: #Predicate { $0.comparisonID == comparisonID }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func currentDraftRecord(in context: ModelContext) throws -> ComparisonDraftRecord? {
        let key = ComparisonDraftRecord.currentKey
        var descriptor = FetchDescriptor<ComparisonDraftRecord>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func hasDraft() -> Bool {
        let context = ModelContext(container)
        return ((try? currentDraftRecord(in: context)) ?? nil) != nil
    }

    func loadDraft() -> ComparisonDraft? {
        let context = ModelContext(container)
        guard let record = (try? currentDraftRecord(in: context)) ?? nil else { return nil }
        return try? decoder.decode(ComparisonDraft.self, from: record.payload)
    }

    func saveDraft(_ draft: ComparisonDraft) throws {
        let payload = try encoder.encode(draft)
        let context = ModelContext(container)
        if let existing = try currentDraftRecord(in: context) {
            existing.payload = payload
            existing.updatedAt = Date()
        } else {
            context.insert(ComparisonDraftRecord(payload: payload))
        }
        try context.save()
    }

    func clearDraft() throws {
        let context = ModelContext(container)
        if let existing = try currentDraftRecord(in: context) {
            context.delete(existing)
        }
        try context.save()
    }

    func outcomes() throws -> [DecisionOutcomeSnapshot] {
        let context = ModelContext(container)
        return try context.fetch(FetchDescriptor<DecisionOutcomeRecord>()).map(\.snapshot)
    }

    func saveOutcome(_ snapshot: DecisionOutcomeSnapshot) throws {
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<DecisionOutcomeRecord>())
        records.filter { $0.comparisonID == snapshot.comparisonID }.forEach(context.delete)
        context.insert(DecisionOutcomeRecord(snapshot: snapshot))
        try context.save()
    }

    func voteTrend(comparisonID: UUID) throws -> [VoteTrendPoint] {
        let context = ModelContext(container)
        let events = try context.fetch(FetchDescriptor<VoteTrendRecord>())
            .filter { $0.comparisonID == comparisonID }
            .map(\.event)
        return VoteTrendEngine.cumulativePoints(events: events)
    }

    func personalEvaluation(comparisonID: UUID) -> PersonalDecisionEvaluation? {
        let context = ModelContext(container)
        guard let record = ((try? context.fetch(FetchDescriptor<PersonalDecisionRecord>())) ?? [])
            .first(where: { $0.comparisonID == comparisonID }) else {
            return nil
        }
        return try? decoder.decode(PersonalDecisionEvaluation.self, from: record.payload)
    }

    func savePersonalEvaluation(_ evaluation: PersonalDecisionEvaluation, comparisonID: UUID) throws {
        let payload = try encoder.encode(evaluation)
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<PersonalDecisionRecord>())
        if let existing = records.first(where: { $0.comparisonID == comparisonID }) {
            existing.payload = payload
            existing.updatedAt = Date()
        } else {
            context.insert(PersonalDecisionRecord(comparisonID: comparisonID, payload: payload))
        }
        try context.save()
    }

    private func update(_ record: ComparisonRecord, from question: AskQuestion, in context: ModelContext) {
        record.title = question.title
        record.detailsText = question.details
        record.categoryRawValue = question.category.rawValue
        record.author = question.author
        record.timeAgo = question.timeAgo
        record.createdAt = question.createdAt
        record.closesAt = question.closesAt
        record.isAnonymous = question.isAnonymous
        record.allowsReasons = question.allowsReasons
        record.allowsComments = question.allowsComments
        record.tagsCSV = question.tags.joined(separator: ",")
        record.isPublished = question.isPublished
        record.visibilityRawValue = question.visibility.rawValue
        record.inviteCode = question.inviteCode
        record.hideResultsUntilVote = question.hideResultsUntilVote

        // Reconcile children in place. The previous implementation deleted every option and
        // comment and re-inserted rows carrying the *same* `.unique` identifiers within one
        // transaction, which needlessly churns the store and risks a uniqueness conflict.
        var existingOptions = Dictionary(record.options.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        record.options = question.options.enumerated().map { index, option in
            if let child = existingOptions.removeValue(forKey: option.id) {
                child.name = option.title
                child.sortIndex = index
                child.voteCount = max(option.votes, 0)
                child.comparison = record
                return child
            }
            let child = ComparisonOptionRecord(option: option, sortIndex: index)
            child.comparison = record
            return child
        }
        existingOptions.values.forEach(context.delete)

        var existingComments = Dictionary(record.comments.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        record.comments = question.comments.map { comment in
            if let child = existingComments.removeValue(forKey: comment.id) {
                child.author = comment.author
                child.text = comment.text
                child.likes = max(comment.likes, 0)
                child.optionID = comment.optionID
                child.optionTitle = comment.optionTitle
                child.trustBadge = comment.trustBadge
                child.reasonCategory = comment.reasonCategory
                child.createdAt = comment.createdAt
                child.comparison = record
                return child
            }
            let child = ComparisonCommentRecord(comment: comment)
            child.comparison = record
            return child
        }
        existingComments.values.forEach(context.delete)
    }

    private func migrateLegacyData(in context: ModelContext) throws {
        guard !UserDefaults.standard.bool(forKey: Self.migrationKey) else { return }

        let existingDrafts = try context.fetch(FetchDescriptor<ComparisonDraftRecord>())
        if let payload = UserDefaults.standard.data(forKey: Self.legacyDraftKey),
           (try? decoder.decode(ComparisonDraft.self, from: payload)) != nil,
           !existingDrafts.contains(where: { $0.key == "current" }) {
            context.insert(ComparisonDraftRecord(payload: payload))
        }

        let existingVoteIDs = Set(try context.fetch(FetchDescriptor<LocalVoteRecord>()).map(\.id))
        if let payload = UserDefaults.standard.data(forKey: Self.legacyVotesKey),
           let votes = try? decoder.decode([Vote].self, from: payload) {
            for vote in votes where !existingVoteIDs.contains(vote.id) {
                context.insert(
                    LocalVoteRecord(
                        id: vote.id,
                        comparisonID: vote.comparisonID,
                        optionID: vote.optionID,
                        reason: vote.reason ?? "",
                        isAnonymous: vote.isAnonymous,
                        createdAt: vote.createdAt
                    )
                )
            }
        }

        let existingBookmarks = Set(try context.fetch(FetchDescriptor<SavedComparisonRecord>()).map(\.comparisonID))
        let bookmarkIDs = (UserDefaults.standard.stringArray(forKey: Self.legacyBookmarksKey) ?? [])
            .compactMap(UUID.init(uuidString:))
        for id in bookmarkIDs where !existingBookmarks.contains(id) {
            context.insert(SavedComparisonRecord(comparisonID: id))
        }

        try context.save()
        UserDefaults.standard.removeObject(forKey: Self.legacyDraftKey)
        UserDefaults.standard.removeObject(forKey: Self.legacyVotesKey)
        UserDefaults.standard.removeObject(forKey: Self.legacyBookmarksKey)
        UserDefaults.standard.set(true, forKey: Self.migrationKey)
        Self.logger.info("Legacy local data migrated to SwiftData")
    }
}
