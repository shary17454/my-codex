import XCTest
@testable import StudyVault

@MainActor
final class StudyVaultCoreTests: XCTestCase {
    override func tearDown() {
        LocalDraftStore.shared.clear()
        super.tearDown()
    }

    func testQuestionWithoutVotesHasNoWinnerOrConfidence() {
        let question = makeQuestion(votes: [0, 0])

        XCTAssertEqual(question.totalVotes, 0)
        XCTAssertNil(question.winningOption)
        XCTAssertEqual(question.decisionConfidence, 0)

        let summary = DecisionSummaryService.makeSummary(for: question)
        XCTAssertEqual(summary.leadingVotePercentage, 0)
        XCTAssertEqual(summary.voteGapPercentage, 0)
        XCTAssertEqual(summary.clarity, .insufficientData)
    }

    func testDashboardDoesNotClaimAMostVotedQuestionWithoutVotes() {
        let questions = [
            makeQuestion(title: "مقارنة أولى", votes: [0, 0]),
            makeQuestion(title: "مقارنة ثانية", category: .cars, votes: [0, 0])
        ]
        let viewModel = HomeViewModel(questions: questions, knowledgeItems: [])

        XCTAssertEqual(viewModel.dashboardStatistics.mostVotedTitle, "لا توجد تصويتات بعد")
        XCTAssertEqual(viewModel.dashboardStatistics.closeResultCount, 2)
    }

    func testSummaryCalculatesWinnerPercentagesAndGap() {
        let question = makeQuestion(votes: [7, 3])
        let summary = DecisionSummaryService.makeSummary(for: question)

        XCTAssertEqual(question.winningOption?.title, "الخيار الأول")
        XCTAssertEqual(summary.totalVotes, 10)
        XCTAssertEqual(summary.leadingVotePercentage, 70)
        XCTAssertEqual(summary.voteGapPercentage, 40, accuracy: 0.001)
        XCTAssertEqual(summary.clarity, .leaning)
    }

    func testValidationRejectsFewerThanTwoCompletedOptions() {
        let draft = ComparisonDraft(
            title: "مقارنة",
            options: [ComparisonOptionDraft(title: "خيار واحد")]
        )

        XCTAssertThrowsError(try ComparisonValidationService.validate(draft: draft)) { error in
            XCTAssertEqual(error.localizedDescription, "أضف خيارين على الأقل للمقارنة.")
        }
    }

    func testValidationRejectsNormalizedDuplicateOptions() {
        let draft = ComparisonDraft(
            title: "مقارنة",
            options: [
                ComparisonOptionDraft(title: "آيفون"),
                ComparisonOptionDraft(title: "ايفون")
            ]
        )

        XCTAssertThrowsError(try ComparisonValidationService.validate(draft: draft)) { error in
            XCTAssertEqual(error.localizedDescription, "أسماء الخيارات لا يجب أن تكون مكررة.")
        }
    }

    func testSearchMatchesOptionAndRespectsCategory() {
        let phone = makeQuestion(
            title: "أفضل جهاز للتصوير؟",
            category: .phones,
            optionTitles: ["iPhone", "Galaxy"],
            votes: [0, 0]
        )
        let car = makeQuestion(
            title: "سيارة عائلية",
            category: .cars,
            optionTitles: ["Camry", "Accord"],
            votes: [0, 0]
        )

        XCTAssertEqual(
            ComparisonSearchService.filterQuestions([phone, car], category: .all, query: "Galaxy").map(\.id),
            [phone.id]
        )
        XCTAssertTrue(
            ComparisonSearchService.filterQuestions([phone, car], category: .cars, query: "Galaxy").isEmpty
        )
    }

    func testDraftRoundTripPreservesContent() {
        let draft = ComparisonDraft(
            title: "آيفون أم سامسونج؟",
            description: "مقارنة للتصوير والبطارية",
            category: .phones,
            options: [
                ComparisonOptionDraft(title: "آيفون"),
                ComparisonOptionDraft(title: "سامسونج")
            ],
            tags: ["جوالات", "تصوير"]
        )

        LocalDraftStore.shared.save(draft)

        XCTAssertEqual(LocalDraftStore.shared.load(), draft)
    }

    func testLocalVotingRepositoryPreventsDuplicateVote() async throws {
        let repository = LocalVotingRepository.shared
        let comparisonID = UUID()
        let optionID = UUID()
        let firstVote = try await repository.vote(
            comparisonID: comparisonID,
            optionID: optionID,
            reason: "الجودة",
            isAnonymous: false
        )

        do {
            _ = try await repository.vote(
                comparisonID: comparisonID,
                optionID: optionID,
                reason: nil,
                isAnonymous: false
            )
            XCTFail("يجب منع التصويت الثاني للمقارنة نفسها.")
        } catch AppError.voteAlreadyExists {
            // Expected policy enforcement.
        }

        try await repository.deleteVote(voteID: firstVote.id)
    }

    func testDraftIsClearedOnlyAfterConfirmedPublication() throws {
        let viewModel = CreateComparisonViewModel()
        viewModel.title = "الخيار الأول أم الثاني؟"
        viewModel.optionTitles[0] = "الخيار الأول"
        viewModel.optionTitles[1] = "الخيار الثاني"
        viewModel.saveDraft()

        _ = try viewModel.makeQuestion(authorName: "مختبر")
        XCTAssertNotNil(LocalDraftStore.shared.load())

        viewModel.markPublished()
        XCTAssertNil(LocalDraftStore.shared.load())
    }

    private func makeQuestion(
        title: String = "أي خيار أفضل؟",
        category: AskCategory = .phones,
        optionTitles: [String] = ["الخيار الأول", "الخيار الثاني"],
        votes: [Int]
    ) -> AskQuestion {
        AskQuestion(
            title: title,
            details: "تفاصيل المقارنة",
            category: category,
            author: "مختبر",
            timeAgo: "الآن",
            options: zip(optionTitles, votes).map {
                PollOption(title: $0.0, votes: $0.1)
            },
            comments: []
        )
    }
}
