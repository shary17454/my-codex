import XCTest
@testable import StudyVault

@MainActor
final class StudyVaultCoreTests: XCTestCase {
    override func tearDown() {
        LocalDraftStore.shared.clear()
        LocalReportStore.shared.clear()
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

    func testPremiumPolicyUnlocksPlusForOwnerOnly() {
        XCTAssertTrue(PremiumAccessPolicy.hasPlus(ownerAccess: true))
        XCTAssertFalse(PremiumAccessPolicy.hasPlus(ownerAccess: false))
        XCTAssertFalse(WeshPlusCatalog.productIdentifiers.isEmpty)
    }

    func testDecisionPDFExporterCreatesReadableFile() throws {
        let question = makeQuestion(title: "آيفون أم سامسونج؟", votes: [8, 4])

        let url = try DecisionPDFExporter.createPDF(question: question, watermark: true)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

        XCTAssertEqual(url.pathExtension, "pdf")
        XCTAssertGreaterThan(attributes[.size] as? Int ?? 0, 500)
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

    func testOwnerEmailUnlocksFullFeatureAccess() {
        XCTAssertTrue(UserSession.isOwnerEmail("  SHARYALHWAID@gmail.com "))
        XCTAssertFalse(UserSession.isOwnerEmail("other@example.com"))
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

    func testPublicPublishingRequiresBackendWhenLocalPublicPublishingIsDisabled() async {
        UserDefaults.standard.set(false, forKey: "wash_alray_backend_enabled")
        defer {
            UserDefaults.standard.removeObject(forKey: "wash_alray_backend_enabled")
        }

        let viewModel = HomeViewModel(
            questions: [],
            knowledgeItems: [],
            allowLocalPublicPublishing: false
        )
        let question = makeQuestion(title: "تلفلكس وشاهد", votes: [0, 0])

        let published = await viewModel.publishQuestion(question)

        XCTAssertNil(published)
        XCTAssertTrue(viewModel.questions.isEmpty)
        XCTAssertEqual(
            viewModel.appErrorMessage,
            "النشر العام يتطلب اتصالًا بخادم وش الرأي حتى تظهر المقارنة للمستخدمين الآخرين."
        )
    }

    func testCreateComparisonViewModelManagesOptionsAndRejectsDuplicates() {
        let viewModel = CreateComparisonViewModel()
        viewModel.optionTitles[0] = "آيفون"
        viewModel.optionTitles[1] = "ايفون"

        XCTAssertTrue(viewModel.hasDuplicateOptions)
        XCTAssertFalse(viewModel.validateOptions())
        XCTAssertEqual(viewModel.validationMessage, "هذا الخيار موجود بالفعل. استخدم اسمًا مختلفًا.")

        viewModel.optionTitles[1] = "سامسونج"
        viewModel.addOption()
        viewModel.optionTitles[2] = "بيكسل"
        viewModel.moveOption(at: 2, offset: -1)

        XCTAssertEqual(viewModel.optionCount, 3)
        XCTAssertEqual(viewModel.completedOptions, ["آيفون", "بيكسل", "سامسونج"])

        viewModel.removeOption(at: 1)
        XCTAssertEqual(viewModel.optionCount, 2)
        XCTAssertEqual(viewModel.completedOptions, ["آيفون", "سامسونج"])
        XCTAssertTrue(viewModel.validateOptions())
    }

    func testCameraDecisionDraftPrefillsEditableComparison() {
        let viewModel = CreateComparisonViewModel()
        let draft = CameraDecisionDraft(
            title: "آيفون 15 برو أم بديل أفضل؟",
            details: "اقتراح من صورة المنتج.",
            primaryOption: "آيفون 15 برو",
            optionSuggestions: ["آيفون 15 برو", "جوال بديل"],
            suggestedCriteria: ["الكاميرا", "البطارية"],
            tags: ["ايفون", "كاميرا"],
            category: .phones,
            confidence: 0.82,
            recognizedText: ["iPhone 15 Pro"]
        )

        viewModel.applyCameraDecisionDraft(draft)

        XCTAssertEqual(viewModel.title, draft.title)
        XCTAssertEqual(viewModel.category, .phones)
        XCTAssertEqual(viewModel.completedOptions, ["آيفون 15 برو", "جوال بديل"])
        XCTAssertTrue(viewModel.tagsText.contains("ايفون"))
        XCTAssertTrue(viewModel.tagsText.contains("كاميرا"))
        XCTAssertEqual(viewModel.validationMessage, "حللنا الصورة واقترحنا خيارات ومعايير قابلة للتعديل.")
    }

    func testCameraDecisionAnalyzerSuggestsEditableOptionsAndCriteriaFromRecognizedText() {
        let draft = CameraDecisionAnalyzer.makeDraft(
            fromRecognizedText: [
                "iPhone 15 Pro",
                "Camera battery price",
                "Apple"
            ]
        )

        XCTAssertEqual(draft.category, .phones)
        XCTAssertGreaterThanOrEqual(draft.optionSuggestions.count, 2)
        XCTAssertEqual(draft.optionSuggestions.first, draft.primaryOption)
        XCTAssertTrue(draft.suggestedCriteria.contains("الكاميرا"))
        XCTAssertTrue(draft.suggestedCriteria.contains("البطارية"))
    }

    func testAIAssistantSummarizesFromAllowedAppContext() {
        let question = makeQuestion(
            title: "آيفون أم سامسونج للتصوير؟",
            category: .phones,
            optionTitles: ["آيفون", "سامسونج"],
            votes: [7, 3]
        )

        let response = AIDecisionAssistantEngine.answer(
            prompt: "لخص مقارنة الآيفون للتصوير",
            questions: [question],
            knowledgeItems: []
        )

        XCTAssertTrue(response.answer.contains("إجابة ذكية إرشادية"))
        XCTAssertTrue(response.answer.contains("آيفون أم سامسونج للتصوير؟"))
        XCTAssertEqual(response.sources, [question.title])
        XCTAssertEqual(response.matchedQuestionIDs, [question.id])
    }

    func testAIAssistantDoesNotInventWhenNoContextMatches() {
        let response = AIDecisionAssistantEngine.answer(
            prompt: "وش أفضل طائرة خاصة؟",
            questions: [],
            knowledgeItems: []
        )

        XCTAssertTrue(response.answer.contains("ما لقيت بيانات كافية"))
        XCTAssertTrue(response.sources.isEmpty)
        XCTAssertTrue(response.matchedQuestionIDs.isEmpty)
    }

    func testSmartComparisonPriorityChangesTheLeadingCandidate() {
        let affordable = KnowledgeItem(
            id: "affordable",
            name: "الخيار الاقتصادي",
            category: .phones,
            summary: "سعر اقتصادي يقدم قيمة وتوفيرًا واضحًا.",
            strengths: ["سعر مناسب"],
            considerations: [],
            suggestedQuestion: "هل الخيار الاقتصادي مناسب؟",
            tags: ["قيمة"]
        )
        let powerful = KnowledgeItem(
            id: "powerful",
            name: "خيار الأداء",
            category: .phones,
            summary: "أداء قوي وسرعة ومعالج مناسب للاستخدام الاحترافي.",
            strengths: ["أداء قوي"],
            considerations: [],
            suggestedQuestion: "هل خيار الأداء مناسب؟",
            tags: ["سرعة"]
        )

        let priceReport = ComparisonEngine.buildReport(for: [affordable, powerful], priority: .price)
        let performanceReport = ComparisonEngine.buildReport(for: [affordable, powerful], priority: .performance)

        XCTAssertEqual(priceReport.candidates.first?.item.id, affordable.id)
        XCTAssertEqual(performanceReport.candidates.first?.item.id, powerful.id)
        XCTAssertTrue(priceReport.recommendation.contains(ComparisonPriority.price.title))
        XCTAssertTrue(performanceReport.recommendation.contains(ComparisonPriority.performance.title))
    }

    func testWeightedDecisionEngineRespectsPersonalPriorities() {
        let price = DecisionCriterion(title: "السعر", weight: 5)
        let camera = DecisionCriterion(title: "الكاميرا", weight: 1)
        let balanced = EvaluatedOption(
            title: "الخيار الاقتصادي",
            scores: [price.id: 9, camera.id: 4]
        )
        let cameraFirst = EvaluatedOption(
            title: "خيار التصوير",
            scores: [price.id: 5, camera.id: 10]
        )

        let ranking = WeightedDecisionEngine.rank(
            options: [cameraFirst, balanced],
            criteria: [price, camera]
        )

        XCTAssertEqual(ranking.first?.id, balanced.id)
        XCTAssertEqual(ranking.first?.rank, 1)
        XCTAssertEqual(ranking.first?.score ?? 0, 49.0 / 6.0, accuracy: 0.001)
    }

    func testDecisionStateSeparatesSampleSizeFromWinningMargin() {
        let smallSample = DecisionStateEngine.evaluate(
            totalVotes: 3,
            firstPercentage: 100,
            secondPercentage: 0,
            reasonCount: 3,
            triedOptionCount: 3
        )
        let decisiveSample = DecisionStateEngine.evaluate(
            totalVotes: 80,
            firstPercentage: 75,
            secondPercentage: 25,
            reasonCount: 40,
            triedOptionCount: 20
        )

        XCTAssertEqual(smallSample.state, .insufficientData)
        XCTAssertNotNil(smallSample.warning)
        XCTAssertEqual(decisiveSample.state, .decisive)
        XCTAssertEqual(decisiveSample.confidence, .high)
    }

    func testEvidenceQualityUsesParticipationReasonsExperienceAndFreshness() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let result = EvidenceQualityEngine.evaluate(
            participantCount: 60,
            reasonCount: 30,
            triedOptionCount: 15,
            lastActivityDate: now,
            now: now
        )

        XCTAssertEqual(result.score, 78)
        XCTAssertEqual(result.level, .good)
        XCTAssertEqual(result.reasonCoverage, 0.5, accuracy: 0.001)
        XCTAssertEqual(result.triedCoverage, 0.5, accuracy: 0.001)
    }

    func testArabicReasonAnalyzerNormalizesArabicAndKeepsOpposingSignals() {
        XCTAssertEqual(
            ArabicTextNormalizer.normalize("آيفون سَهل، وكاميرته ممتازة!"),
            "ايفون سهل وكاميرته ممتازه"
        )

        let insights = ArabicReasonAnalyzer.analyze(reasons: [
            "الكاميرا ممتازة والتصوير واضح",
            "البطارية جيدة لكن السعر غالي",
            "السعر مناسب وقيمة ممتازة",
            "الصيانة أرخص وقطع الغيار متوفرة"
        ])

        XCTAssertEqual(insights.first(where: { $0.id == "price" })?.mentionCount, 3)
        XCTAssertEqual(insights.first(where: { $0.id == "camera" })?.sentimentLabel, "نقطة قوة")
        XCTAssertEqual(insights.first(where: { $0.id == "battery" })?.mentionCount, 1)
        XCTAssertEqual(insights.first(where: { $0.id == "maintenance" })?.sentimentLabel, "نقطة قوة")
        XCTAssertEqual(insights.first(where: { $0.id == "availability" })?.mentionCount, 1)
    }

    func testRankedVotingAwardsThreeTwoOnePoints() {
        let first = UUID()
        let second = UUID()
        let third = UUID()
        let results = RankedVotingEngine.calculate(
            optionIDs: [first, second, third],
            ballots: [
                RankedBallot(orderedOptionIDs: [first, second, third]),
                RankedBallot(orderedOptionIDs: [first, second, third])
            ]
        )

        XCTAssertEqual(results.first?.optionID, first)
        XCTAssertEqual(results.first?.points, 6)
        XCTAssertEqual(results.first?.rank, 1)
        XCTAssertEqual(results.last?.points, 2)
    }

    func testSwiftDataPersistsComparisonVoteReasonAndBookmark() throws {
        let container = try WeshPersistenceStore.makeContainer(inMemory: true)
        let store = WeshPersistenceStore(container: container)
        let question = makeQuestion(votes: [2, 1])
        let optionID = try XCTUnwrap(question.options.first?.id)

        try store.upsert(question: question)
        try store.recordVote(
            comparisonID: question.id,
            optionID: optionID,
            reason: "الكاميرا ممتازة",
            authorName: "مختبر",
            reasonCategory: "الكاميرا",
            triedOption: true,
            isAnonymous: false
        )
        try store.setSaved(true, comparisonID: question.id)

        let reloadedStore = WeshPersistenceStore(container: container)
        let restored = try XCTUnwrap(reloadedStore.questions().first(where: { $0.id == question.id }))
        XCTAssertEqual(restored.totalVotes, 4)
        XCTAssertEqual(restored.comments.first?.text, "الكاميرا ممتازة")
        XCTAssertEqual(restored.comments.first?.trustBadge, "مجرّب فعليًا")
        XCTAssertTrue(try reloadedStore.savedComparisonIDs().contains(question.id))
        XCTAssertTrue(try reloadedStore.votedComparisonIDs().contains(question.id))
        XCTAssertEqual(try reloadedStore.voteTrend(comparisonID: question.id).last?.cumulativeVotes, 1)

        XCTAssertThrowsError(
            try reloadedStore.recordVote(
                comparisonID: question.id,
                optionID: optionID,
                reason: nil,
                authorName: "مختبر",
                reasonCategory: nil,
                triedOption: false,
                isAnonymous: false
            )
        ) { error in
            guard case AppError.voteAlreadyExists = error else {
                return XCTFail("يجب رفض التصويت المكرر، وليس إرجاع \(error).")
            }
        }
    }

    func testSwiftDataRestoresDraftOutcomeAndPersonalEvaluation() throws {
        let container = try WeshPersistenceStore.makeContainer(inMemory: true)
        let store = WeshPersistenceStore(container: container)
        let draft = ComparisonDraft(
            title: "قرار محفوظ",
            options: [
                ComparisonOptionDraft(title: "الأول"),
                ComparisonOptionDraft(title: "الثاني")
            ],
            visibility: .linkOnly,
            hideResultsUntilVote: true
        )
        let comparisonID = UUID()
        let optionID = UUID()
        let outcome = DecisionOutcomeSnapshot(
            comparisonID: comparisonID,
            chosenOptionID: optionID,
            satisfactionScore: 5,
            wouldChooseAgain: true,
            note: "قرار موفق"
        )
        let criterion = DecisionCriterion(title: "الجودة", weight: 5)
        let evaluation = PersonalDecisionEvaluation(
            criteria: [criterion],
            options: [EvaluatedOption(id: optionID, title: "الأول", scores: [criterion.id: 9])],
            updatedAt: Date()
        )

        try store.saveDraft(draft)
        try store.saveOutcome(outcome)
        try store.savePersonalEvaluation(evaluation, comparisonID: comparisonID)

        let reloadedStore = WeshPersistenceStore(container: container)
        XCTAssertEqual(reloadedStore.loadDraft(), draft)
        XCTAssertEqual(try reloadedStore.outcomes().first, outcome)
        XCTAssertEqual(reloadedStore.personalEvaluation(comparisonID: comparisonID), evaluation)
    }

    func testRemoteVoteMarkerSurvivesRelaunchWithoutChangingServerTotals() throws {
        let container = try WeshPersistenceStore.makeContainer(inMemory: true)
        let store = WeshPersistenceStore(container: container)
        let question = makeQuestion(votes: [5, 3])
        let optionID = try XCTUnwrap(question.options.first?.id)

        try store.upsert(question: question)
        try store.recordRemoteVoteMarker(
            comparisonID: question.id,
            optionID: optionID,
            reason: "تجربة فعلية",
            triedOption: true,
            isAnonymous: false
        )
        try store.recordRemoteVoteMarker(
            comparisonID: question.id,
            optionID: optionID,
            reason: "إعادة استجابة",
            triedOption: true,
            isAnonymous: false
        )

        let reopenedStore = WeshPersistenceStore(container: container)
        let restored = try XCTUnwrap(reopenedStore.questions().first(where: { $0.id == question.id }))
        XCTAssertEqual(restored.totalVotes, 8)
        XCTAssertTrue(try reopenedStore.votedComparisonIDs().contains(question.id))
        XCTAssertTrue(try reopenedStore.voteTrend(comparisonID: question.id).isEmpty)
    }

    func testPrivateComparisonDeepLinkCarriesInviteCode() throws {
        var question = makeQuestion(votes: [0, 0])
        question.visibility = .inviteCode
        question.inviteCode = "A1B2C3D4E5"
        let link = ComparisonShareService.deepLink(for: question)
        let viewModel = HomeViewModel(questions: [question], knowledgeItems: [])

        XCTAssertEqual(link.scheme, "weshalray")
        XCTAssertEqual(link.host, "comparison")
        XCTAssertEqual(viewModel.question(fromDeepLink: link)?.id, question.id)
        XCTAssertEqual(viewModel.inviteCode(fromDeepLink: link), "A1B2C3D4E5")
    }

    func testPublicShareURLUsesWebPathAndParsesAsUniversalLink() throws {
        let question = makeQuestion(title: "آيفون أم جالكسي؟", votes: [3, 2])
        let link = ComparisonShareService.publicURL(
            for: question,
            baseURLText: "https://share.weshalray.example"
        )
        let viewModel = HomeViewModel(questions: [question], knowledgeItems: [])

        XCTAssertEqual(link.absoluteString, "https://share.weshalray.example/c/\(question.id.uuidString)")
        XCTAssertEqual(viewModel.question(fromDeepLink: link)?.id, question.id)
        XCTAssertNil(viewModel.inviteCode(fromDeepLink: link))
    }

    func testPrivatePublicShareURLCarriesInviteCode() throws {
        var question = makeQuestion(votes: [0, 0])
        question.visibility = .inviteCode
        question.inviteCode = "JOIN123"
        let link = ComparisonShareService.publicURL(
            for: question,
            baseURLText: "https://share.weshalray.example"
        )

        XCTAssertTrue(link.absoluteString.contains("/c/\(question.id.uuidString)"))
        XCTAssertEqual(ComparisonShareService.comparisonID(fromSharedURL: link), question.id)
        XCTAssertEqual(ComparisonShareService.inviteCode(fromSharedURL: link), "JOIN123")
    }

    func testContentReportFallsBackToLocalQueueWhenBackendIsDisabled() async {
        LocalReportStore.shared.clear()
        let question = makeQuestion(votes: [0, 0])
        let viewModel = HomeViewModel(questions: [question], knowledgeItems: [])
        viewModel.isBackendEnabled = false

        let sent = await viewModel.submitContentReport(
            contentID: question.id,
            contentType: .comparison,
            reason: .misleading,
            details: "تفاصيل بلاغ"
        )

        let reports = LocalReportStore.shared.load()
        XCTAssertFalse(sent)
        XCTAssertEqual(reports.count, 1)
        XCTAssertEqual(reports.first?.contentID, question.id)
        XCTAssertEqual(reports.first?.contentType, .comparison)
        XCTAssertEqual(reports.first?.reason, .misleading)
        XCTAssertEqual(reports.first?.details, "تفاصيل بلاغ")
    }

    func testSwiftDataSurvivesRecreatedModelContainer() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("wesh-persistence-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("WeshAlRay.sqlite")
        let question = makeQuestion(title: "مقارنة تبقى بعد إعادة الفتح", votes: [4, 2])

        try autoreleasepool {
            let container = try WeshPersistenceStore.makeContainer(storeURL: storeURL)
            let store = WeshPersistenceStore(container: container)
            try store.upsert(question: question)
            try store.saveDraft(
                ComparisonDraft(
                    title: question.title,
                    options: question.options.map { ComparisonOptionDraft(title: $0.title) }
                )
            )
        }

        try autoreleasepool {
            let reopenedContainer = try WeshPersistenceStore.makeContainer(storeURL: storeURL)
            let reopenedStore = WeshPersistenceStore(container: reopenedContainer)
            XCTAssertEqual(try reopenedStore.questions().first?.id, question.id)
            XCTAssertEqual(reopenedStore.loadDraft()?.title, question.title)
        }
    }

    func testDecisionSummaryProducesCompassAndActionItems() {
        let question = makeQuestion(
            votes: [45, 15],
            comments: [
                AskComment(
                    author: "مستخدم",
                    text: "الكاميرا ممتازة وسهولة الاستخدام واضحة",
                    likes: 3,
                    optionTitle: "الخيار الأول",
                    trustBadge: "مجرّب فعليًا",
                    reasonCategory: "الكاميرا"
                ),
                AskComment(
                    author: "مستخدم",
                    text: "السعر غالي لكن الأداء قوي",
                    likes: 1,
                    optionTitle: "الخيار الأول",
                    reasonCategory: "الأداء"
                ),
                AskComment(
                    author: "مستخدم",
                    text: "الخيار الثاني أوفر وقطع الغيار متوفرة والصيانة أرخص",
                    likes: 2,
                    optionTitle: "الخيار الثاني",
                    reasonCategory: "الصيانة"
                )
            ]
        )

        let summary = DecisionSummaryService.makeSummary(for: question)

        XCTAssertTrue(summary.compassTitle.contains("الخيار الأول"))
        XCTAssertFalse(summary.compassSubtitle.isEmpty)
        XCTAssertFalse(summary.actionItems.isEmpty)
        XCTAssertTrue(summary.actionItems.contains { $0.title == "أهم محور في النقاش" })
        XCTAssertEqual(summary.leaderReasonBalance?.leaderTitle, "الخيار الأول")
        XCTAssertNotNil(summary.leaderReasonBalance)
        XCTAssertEqual(summary.communityNeedMatch.communityChoice, "الخيار الأول")
        XCTAssertFalse(summary.communityNeedMatch.explanation.isEmpty)
    }

    // MARK: - Regression coverage for the 2.3 hardening pass

    /// The backend emits timestamps with `Date.prototype.toISOString()`, which *always* carries
    /// milliseconds. The old per-call `ISO8601DateFormatter()` could not read that shape, so every
    /// server timestamp silently degraded — `createdAt` collapsed to "now" and `closesAt` became
    /// nil, quietly turning time-limited comparisons into open-ended ones.
    func testISO8601ParserReadsBackendTimestampsWithMilliseconds() throws {
        let whole = try XCTUnwrap(WeshISO8601.date(from: "2026-08-08T10:30:00Z"))
        let backendShape = try XCTUnwrap(WeshISO8601.date(from: "2026-08-08T10:30:00.000Z"))
        let fractional = try XCTUnwrap(WeshISO8601.date(from: "2026-08-08T10:30:00.250Z"))

        XCTAssertEqual(backendShape, whole)
        XCTAssertEqual(fractional.timeIntervalSince(whole), 0.25, accuracy: 0.001)
        XCTAssertNil(WeshISO8601.date(from: "ليس تاريخًا"))
    }

    func testSavedQuestionsExposeBookmarkedComparisonsNewestFirst() async {
        let older = makeQuestion(title: "مقارنة قديمة", votes: [1, 1])
        var newer = makeQuestion(title: "مقارنة حديثة", votes: [2, 1])
        newer.createdAt = older.createdAt.addingTimeInterval(120)
        let unsaved = makeQuestion(title: "غير محفوظة", votes: [0, 0])

        let container = try? WeshPersistenceStore.makeContainer(inMemory: true)
        let store = container.map(WeshPersistenceStore.init(container:))
        let viewModel = HomeViewModel(
            questions: [older, newer, unsaved],
            knowledgeItems: [],
            persistence: store
        )
        try? store?.upsert(question: older)
        try? store?.upsert(question: newer)

        await viewModel.toggleSavedQuestion(questionID: older.id)
        await viewModel.toggleSavedQuestion(questionID: newer.id)

        XCTAssertEqual(viewModel.savedQuestions.map(\.title), ["مقارنة حديثة", "مقارنة قديمة"])
        XCTAssertEqual(viewModel.dashboardStatistics.savedCount, 2)

        await viewModel.toggleSavedQuestion(questionID: newer.id)
        XCTAssertEqual(viewModel.savedQuestions.map(\.title), ["مقارنة قديمة"])
    }

    func testDeletingAccountClearsIdentityAndInterests() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "wesh.tests.accountDeletion"))
        defaults.removePersistentDomain(forName: "wesh.tests.accountDeletion")
        defaults.set(true, forKey: "user.isSignedIn")
        defaults.set("خبير التقنية", forKey: "user.displayName")
        defaults.set(["phones", "cars"], forKey: "wash_alray_user_interests")

        let session = UserSession(defaults: defaults)
        XCTAssertTrue(session.isSignedIn)

        session.deleteAccountData()

        XCTAssertFalse(session.isSignedIn)
        XCTAssertEqual(session.publicName, "ضيف")
        XCTAssertNil(defaults.stringArray(forKey: "wash_alray_user_interests"))
        XCTAssertNil(defaults.string(forKey: "user.displayName"))
        defaults.removePersistentDomain(forName: "wesh.tests.accountDeletion")
    }

    func testMalformedBackendURLIsRejectedWithGuidance() async {
        let viewModel = HomeViewModel(questions: [], knowledgeItems: [])
        viewModel.isBackendEnabled = true
        viewModel.backendBaseURLText = "خادم-بدون-بروتوكول"

        await viewModel.refreshAdminOverview()

        let message = viewModel.appErrorMessage ?? ""
        XCTAssertTrue(message.contains("غير صحيح"), "توقعنا رسالة عن عنوان غير صحيح، وجاء: \(message)")
        XCTAssertNil(viewModel.adminOverview)
    }

    func testDraftLifecycleUsesSingleCurrentRecord() throws {
        let container = try WeshPersistenceStore.makeContainer(inMemory: true)
        let store = WeshPersistenceStore(container: container)

        XCTAssertFalse(store.hasDraft())

        try store.saveDraft(ComparisonDraft(title: "أول", options: [ComparisonOptionDraft(title: "أ")]))
        try store.saveDraft(ComparisonDraft(title: "ثاني", options: [ComparisonOptionDraft(title: "ب")]))

        XCTAssertTrue(store.hasDraft())
        XCTAssertEqual(store.loadDraft()?.title, "ثاني")

        try store.clearDraft()
        XCTAssertFalse(store.hasDraft())
        XCTAssertNil(store.loadDraft())
    }

    private func makeQuestion(
        title: String = "أي خيار أفضل؟",
        category: AskCategory = .phones,
        optionTitles: [String] = ["الخيار الأول", "الخيار الثاني"],
        votes: [Int],
        comments: [AskComment] = []
    ) -> AskQuestion {
        let options = zip(optionTitles, votes).map {
            PollOption(title: $0.0, votes: $0.1)
        }
        let comments = comments.map { comment in
            guard comment.optionID == nil,
                  let optionTitle = comment.optionTitle,
                  let optionID = options.first(where: { $0.title == optionTitle })?.id else {
                return comment
            }

            var linkedComment = comment
            linkedComment.optionID = optionID
            return linkedComment
        }

        return AskQuestion(
            title: title,
            details: "تفاصيل المقارنة",
            category: category,
            author: "مختبر",
            timeAgo: "الآن",
            options: options,
            comments: comments
        )
    }
}
