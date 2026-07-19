import Foundation

enum AskCategory: String, CaseIterable, Identifiable, Codable {
    case all
    case phones
    case cars
    case restaurants
    case laptops
    case services
    case subscriptions
    case gaming
    case travel
    case education
    case home
    case fashion
    case health
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "الكل"
        case .phones: "جوالات"
        case .cars: "سيارات"
        case .restaurants: "مطاعم"
        case .laptops: "لابتوبات"
        case .services: "خدمات"
        case .subscriptions: "اشتراكات"
        case .gaming: "ألعاب"
        case .travel: "سفر"
        case .education: "تعليم"
        case .home: "منزل"
        case .fashion: "أزياء"
        case .health: "صحة"
        case .other: "أخرى"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "square.grid.2x2"
        case .phones: "iphone"
        case .cars: "car"
        case .restaurants: "fork.knife"
        case .laptops: "laptopcomputer"
        case .services: "wrench.and.screwdriver"
        case .subscriptions: "creditcard"
        case .gaming: "gamecontroller"
        case .travel: "airplane"
        case .education: "graduationcap"
        case .home: "house"
        case .fashion: "tshirt"
        case .health: "heart"
        case .other: "sparkles"
        }
    }
}

struct PollOption: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var votes: Int

    init(id: UUID = UUID(), title: String, votes: Int) {
        self.id = id
        self.title = title
        self.votes = votes
    }
}

struct AskComment: Identifiable, Hashable, Codable {
    let id: UUID
    var author: String
    var text: String
    var likes: Int
    var optionID: UUID?
    var optionTitle: String?
    var trustBadge: String?
    var reasonCategory: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        author: String,
        text: String,
        likes: Int,
        optionID: UUID? = nil,
        optionTitle: String? = nil,
        trustBadge: String? = nil,
        reasonCategory: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.likes = likes
        self.optionID = optionID
        self.optionTitle = optionTitle
        self.trustBadge = trustBadge
        self.reasonCategory = reasonCategory
        self.createdAt = createdAt
    }
}

struct AskQuestion: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var details: String
    var category: AskCategory
    var author: String
    var timeAgo: String
    var options: [PollOption]
    var comments: [AskComment]
    var createdAt: Date
    var closesAt: Date?
    var isAnonymous: Bool
    var allowsReasons: Bool
    var allowsComments: Bool
    var tags: [String]
    var isPublished: Bool
    var visibility: ComparisonVisibility
    var inviteCode: String?
    var hideResultsUntilVote: Bool
    var voteTrendEvents: [VoteTrendEvent]?

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        category: AskCategory,
        author: String,
        timeAgo: String,
        options: [PollOption],
        comments: [AskComment],
        createdAt: Date = Date(),
        closesAt: Date? = nil,
        isAnonymous: Bool = false,
        allowsReasons: Bool = true,
        allowsComments: Bool = true,
        tags: [String] = [],
        isPublished: Bool = true,
        visibility: ComparisonVisibility = .publicRoom,
        inviteCode: String? = nil,
        hideResultsUntilVote: Bool = false,
        voteTrendEvents: [VoteTrendEvent]? = nil
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.category = category
        self.author = author
        self.timeAgo = timeAgo
        self.options = options
        self.comments = comments
        self.createdAt = createdAt
        self.closesAt = closesAt
        self.isAnonymous = isAnonymous
        self.allowsReasons = allowsReasons
        self.allowsComments = allowsComments
        self.tags = tags
        self.isPublished = isPublished
        self.visibility = visibility
        self.inviteCode = inviteCode
        self.hideResultsUntilVote = hideResultsUntilVote
        self.voteTrendEvents = voteTrendEvents
    }

    var totalVotes: Int {
        options.reduce(0) { $0 + $1.votes }
    }

    var winningOption: PollOption? {
        guard totalVotes > 0 else {
            return nil
        }
        return options.max { $0.votes < $1.votes }
    }

    var verifiedComments: [AskComment] {
        comments.filter { $0.trustBadge != nil }
    }

    var decisionConfidence: Int {
        let sorted = options.sorted { $0.votes > $1.votes }
        let first = sorted.first.map { Double($0.votes) / Double(max(totalVotes, 1)) * 100 } ?? 0
        let second = sorted.dropFirst().first.map { Double($0.votes) / Double(max(totalVotes, 1)) * 100 } ?? 0
        let reasons = comments.filter { $0.optionID != nil }
        return DecisionStateEngine.evaluate(
            totalVotes: totalVotes,
            firstPercentage: first,
            secondPercentage: second,
            reasonCount: reasons.count,
            triedOptionCount: reasons.filter { $0.trustBadge != nil }.count
        ).confidenceScore
    }

    var repeatedPros: [String] {
        topReasonKeywords(matching: ["جودة", "سعر", "ضمان", "بطارية", "كاميرا", "راحة", "اعتمادية", "خدمة", "عملي", "قيمة"])
    }

    var repeatedCons: [String] {
        topReasonKeywords(matching: ["غالي", "صيانة", "استهلاك", "ضعيف", "بطء", "حرارة", "قطع", "زحمة", "عيب", "تأخير"])
    }

    var smartSummary: String {
        guard let winner = winningOption, totalVotes > 0 else {
            return "ابدأ بالتصويت وكتابة الأسباب حتى تظهر خلاصة تساعد صاحب السؤال على فهم الاتجاه العام."
        }

        let percent = Int((Double(winner.votes) / Double(totalVotes)) * 100)
        let reasonText: String
        if comments.isEmpty {
            reasonText = "النتيجة مبنية حاليًا على التصويت فقط، وستصبح أدق عند إضافة أسباب وتجارب مكتوبة."
        } else {
            let pros = repeatedPros.prefix(2).joined(separator: " و")
            reasonText = pros.isEmpty
                ? "الأسباب المكتوبة بدأت تعطي صورة أوضح، لكن ما زالت تحتاج مشاركات أكثر."
                : "أكثر ما يتكرر في الأسباب: \(pros)."
        }

        return "\(winner.title) هو المتقدم حاليًا بنسبة \(percent)% من الأصوات. \(reasonText) إذا كان احتياجك مختلفًا، راجع آراء أصحاب التجربة قبل القرار النهائي."
    }

    private func topReasonKeywords(matching keywords: [String]) -> [String] {
        let blob = comments.map { [$0.text, $0.reasonCategory ?? ""].joined(separator: " ") }.joined(separator: " ")
        return keywords.filter { blob.localizedCaseInsensitiveContains($0) }
    }
}

enum DecisionMode: String, CaseIterable, Identifiable {
    case quick
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quick: "قرار سريع"
        case .deep: "قرار عميق"
        }
    }
}

enum CommentFilter: String, CaseIterable, Identifiable {
    case all
    case verified
    case reasons

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "الكل"
        case .verified: "مجرّب فعليًا"
        case .reasons: "أسباب التصويت"
        }
    }
}

enum QuestionSortMode: String, CaseIterable, Identifiable {
    case newest
    case mostVoted
    case mostDiscussed
    case clearestDecision
    case closeResults

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: "الأحدث"
        case .mostVoted: "الأكثر تصويتًا"
        case .mostDiscussed: "الأكثر نقاشًا"
        case .clearestDecision: "الأوضح قرارًا"
        case .closeResults: "النتائج المتقاربة"
        }
    }

    var systemImage: String {
        switch self {
        case .newest: "clock"
        case .mostVoted: "chart.bar.fill"
        case .mostDiscussed: "text.bubble.fill"
        case .clearestDecision: "checkmark.seal.fill"
        case .closeResults: "equal.circle.fill"
        }
    }
}

enum VoteDurationOption: Int, CaseIterable, Identifiable, Codable {
    case oneDay = 1
    case threeDays = 3
    case oneWeek = 7
    case twoWeeks = 14
    case open = 0

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .oneDay: "يوم واحد"
        case .threeDays: "3 أيام"
        case .oneWeek: "أسبوع"
        case .twoWeeks: "أسبوعان"
        case .open: "مفتوحة"
        }
    }

    var expiryDate: Date? {
        guard rawValue > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: rawValue, to: Date())
    }
}

enum ComparisonVisibility: String, CaseIterable, Identifiable, Codable, Hashable {
    case publicRoom
    case linkOnly
    case inviteCode

    var id: String { rawValue }

    var title: String {
        switch self {
        case .publicRoom: "عامة"
        case .linkOnly: "خاصة بالرابط"
        case .inviteCode: "خاصة برمز"
        }
    }

    var systemImage: String {
        switch self {
        case .publicRoom: "globe"
        case .linkOnly: "link"
        case .inviteCode: "number.square"
        }
    }
}

struct DashboardStatistics: Hashable {
    let totalComparisons: Int
    let totalVotes: Int
    let totalReasons: Int
    let savedCount: Int
    let topCategory: AskCategory
    let mostVotedTitle: String
    let closeResultCount: Int
}

enum ReportableContentType: String, Codable, CaseIterable, Identifiable {
    case comparison
    case comment
    case voteReason
    case user

    var id: String { rawValue }
}

enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case abusive
    case spam
    case misleading
    case duplicate
    case inappropriateImage
    case impersonation
    case other

    var id: String { rawValue }

    var arabicTitle: String {
        switch self {
        case .abusive: "محتوى مسيء"
        case .spam: "إعلان أو إزعاج"
        case .misleading: "معلومات مضللة"
        case .duplicate: "مقارنة مكررة"
        case .inappropriateImage: "صور غير مناسبة"
        case .impersonation: "انتحال"
        case .other: "مخالفة أخرى"
        }
    }
}

struct ContentReport: Identifiable, Codable, Hashable {
    let id: UUID
    let contentID: UUID
    let contentType: ReportableContentType
    let reason: ReportReason
    let details: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        contentID: UUID,
        contentType: ReportableContentType,
        reason: ReportReason,
        details: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.contentID = contentID
        self.contentType = contentType
        self.reason = reason
        self.details = details
        self.createdAt = createdAt
    }
}

enum ComparisonShareService {
    static func deepLink(for question: AskQuestion) -> URL {
        var components = URLComponents()
        components.scheme = "weshalray"
        components.host = "comparison"
        components.path = "/\(question.id.uuidString)"
        if let inviteCode = question.inviteCode, question.visibility != .publicRoom {
            components.queryItems = [URLQueryItem(name: "invite", value: inviteCode)]
        }
        return components.url ?? URL(filePath: "/")
    }

    static func shareText(for question: AskQuestion) -> String {
        let winner = question.winningOption?.title ?? "لم تتضح النتيجة بعد"
        return """
        وش الرأي؟
        \(question.title)

        الخيارات: \(question.options.map(\.title).joined(separator: "، "))
        النتيجة الحالية: \(winner)
        \(question.smartSummary)

        افتح المقارنة:
        \(deepLink(for: question).absoluteString)
        """
    }

    static func csvText(for question: AskQuestion) -> String {
        var lines = ["\"الخيار\",\"الأصوات\",\"النسبة\",\"أسباب مكتوبة\""]
        for option in question.options {
            let reasons = question.comments.filter { $0.optionID == option.id || $0.optionTitle == option.title }.count
            let percent = question.totalVotes == 0 ? 0 : Int((Double(option.votes) / Double(question.totalVotes)) * 100)
            lines.append("\"\(escape(option.title))\",\"\(option.votes)\",\"\(percent)%\",\"\(reasons)\"")
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "\"\"")
    }
}

enum SavedDecisionState: String, CaseIterable, Identifiable {
    case thinking
    case comparing
    case decided
    case purchased

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thinking: "أفكر أشتريه"
        case .comparing: "قيد المقارنة"
        case .decided: "قررت"
        case .purchased: "تم الشراء"
        }
    }

    var systemImage: String {
        switch self {
        case .thinking: "lightbulb"
        case .comparing: "scale.3d"
        case .decided: "checkmark.seal"
        case .purchased: "bag"
        }
    }
}

enum DecisionFeatureCatalog {
    static func criteria(for category: AskCategory) -> [String] {
        switch category {
        case .phones:
            ["البطارية", "الكاميرا", "الأداء", "السعر", "النظام", "القيمة"]
        case .cars:
            ["السعر", "البنزين", "الراحة", "قطع الغيار", "إعادة البيع", "الاعتمادية"]
        case .restaurants:
            ["الطعم", "السعر", "النظافة", "الخدمة", "سرعة التوصيل", "الموقع"]
        case .laptops:
            ["الأداء", "البطارية", "الشاشة", "الوزن", "السعر", "الحرارة"]
        case .services:
            ["السعر", "الجودة", "الالتزام", "الدعم", "سرعة التنفيذ", "الضمان"]
        case .subscriptions:
            ["السعر", "المحتوى", "سهولة الإلغاء", "القيمة", "عدد الأجهزة", "الدعم"]
        case .gaming:
            ["الألعاب", "الأداء", "الاشتراكات", "السعر", "الأصدقاء", "التوفر"]
        case .travel:
            ["السعر", "الراحة", "الموقع", "الأمان", "الخدمات", "التجربة"]
        case .education:
            ["الجودة", "الاعتماد", "السعر", "مرونة الدراسة", "فرص العمل", "الدعم"]
        case .home:
            ["الجودة", "العمر الافتراضي", "الضمان", "السعر", "سهولة الصيانة", "الأمان"]
        case .fashion:
            ["الخامة", "السعر", "الراحة", "التصميم", "التحمل", "المقاس"]
        case .health:
            ["السلامة", "الاعتماد", "الجودة", "السعر", "سهولة الاستخدام", "النتائج"]
        case .all, .other:
            ["السعر", "الجودة", "التجربة", "خدمة العملاء", "الاعتمادية", "القيمة"]
        }
    }

    static func voteReasons(for category: AskCategory) -> [String] {
        switch category {
        case .phones:
            ["الكاميرا أفضل", "البطارية أقوى", "النظام أنسب", "القيمة مقابل السعر", "استخدمته فعليًا"]
        case .cars:
            ["اعتمادية أعلى", "صرفية أفضل", "قطع الغيار متوفرة", "مناسب للعائلة", "إعادة البيع ممتازة"]
        case .restaurants:
            ["الطعم أفضل", "السعر مناسب", "الخدمة أسرع", "النظافة أعلى", "مناسب للمجموعات"]
        case .laptops:
            ["الأداء أفضل", "بطارية أطول", "خفيف للتنقل", "مناسب للدراسة", "القيمة أعلى"]
        case .services:
            ["جودة أعلى", "دعم أفضل", "التزام أوضح", "سعر مناسب", "تجربة سابقة"]
        case .subscriptions:
            ["محتوى أفضل", "سعر أوفر", "إلغاء أسهل", "يناسب العائلة", "قيمة أعلى"]
        case .gaming:
            ["الألعاب أفضل", "الأصدقاء عليه", "الاشتراك أقوى", "الأداء أعلى", "السعر مناسب"]
        case .travel:
            ["أريح للسفر", "سعره أفضل", "موقعه مناسب", "تجربة الناس أفضل", "الخدمات أوضح"]
        case .education:
            ["اعتماده أفضل", "جودة أعلى", "مرونة أكثر", "سعر أنسب", "فرصه أفضل"]
        case .home:
            ["عمره أطول", "ضمان أفضل", "صيانة أسهل", "سعر مناسب", "أكثر أمانًا"]
        case .fashion:
            ["خامة أفضل", "تصميم أجمل", "مريح أكثر", "سعر مناسب", "يناسب الاستخدام"]
        case .health:
            ["أكثر أمانًا", "موثوق أكثر", "نتائجه أوضح", "سهل الاستخدام", "سعره مناسب"]
        case .all, .other:
            ["السعر أفضل", "الجودة أعلى", "تجربة شخصية", "خدمة العملاء", "عملي أكثر"]
        }
    }
}

enum AskDemoStore {
    static let questions: [AskQuestion] = loadSeedQuestions()
    static let knowledgeItems: [KnowledgeItem] = loadKnowledgeItems()

    private static func loadSeedQuestions() -> [AskQuestion] {
        guard let url = Bundle.main.url(forResource: "SeedQuestions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([SeedQuestionRecord].self, from: data) else {
            return fallbackQuestions
        }

        return records.map { record in
            AskQuestion(
                title: record.title,
                details: record.details,
                category: AskCategory(rawValue: record.category) ?? .other,
                author: record.author,
                timeAgo: record.timeAgo,
                options: record.options.map { PollOption(title: $0.title, votes: $0.votes) },
                comments: record.comments.map { AskComment(author: $0.author, text: $0.text, likes: $0.likes) }
            )
        }
    }

    private static let fallbackQuestions: [AskQuestion] = [
        AskQuestion(
            title: "أشتري iPhone 17 Pro Max أو Galaxy S26 Ultra؟",
            details: "أهم شيء عندي الكاميرا والبطارية والاستخدام اليومي لسنوات.",
            category: .phones,
            author: "فريق وش الرأي",
            timeAgo: "مثال",
            options: [
                PollOption(title: "iPhone 17 Pro Max", votes: 0),
                PollOption(title: "Galaxy S26 Ultra", votes: 0),
                PollOption(title: "انتظر الجيل القادم", votes: 0)
            ],
            comments: []
        ),
        AskQuestion(
            title: "كامري هايبرد أو أكورد هايبرد؟",
            details: "أبي سيارة عملية للدوام والخطوط، أهم شيء الاعتمادية والصرفية.",
            category: .cars,
            author: "فريق وش الرأي",
            timeAgo: "مثال",
            options: [
                PollOption(title: "كامري هايبرد", votes: 0),
                PollOption(title: "أكورد هايبرد", votes: 0)
            ],
            comments: []
        ),
        AskQuestion(
            title: "أفضل مطعم برجر للتجمع؟",
            details: "نبي مكان مناسب لعشرة أشخاص، الطعم مهم والسعر يكون معقول.",
            category: .restaurants,
            author: "فريق وش الرأي",
            timeAgo: "مثال",
            options: [
                PollOption(title: "مطعم A", votes: 0),
                PollOption(title: "مطعم B", votes: 0),
                PollOption(title: "مطعم C", votes: 0),
                PollOption(title: "مطعم D", votes: 0)
            ],
            comments: []
        )
    ]

    private static func loadKnowledgeItems() -> [KnowledgeItem] {
        guard let url = Bundle.main.url(forResource: "ProductKnowledge", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([KnowledgeItem].self, from: data) else {
            return KnowledgeItem.fallbackItems
        }

        return records
    }
}

enum KnowledgeSearchIndex {
    static func search(_ items: [KnowledgeItem], query: String, category: AskCategory) -> [KnowledgeItem] {
        let normalizedQuery = normalize(query)
        return items
            .filter { category == .all || $0.category == category }
            .map { item in
                (item: item, score: score(item, query: normalizedQuery))
            }
            .filter { normalizedQuery.isEmpty || $0.score > 0 }
            .sorted {
                if $0.score == $1.score {
                    return $0.item.name.localizedStandardCompare($1.item.name) == .orderedAscending
                }
                return $0.score > $1.score
            }
            .map(\.item)
    }

    private static func score(_ item: KnowledgeItem, query: String) -> Int {
        guard !query.isEmpty else { return 1 }

        var score = 0
        let fields: [(String, Int)] = [
            (item.name, 90),
            (item.category.title, 45),
            (item.summary, 18),
            (item.suggestedQuestion, 24),
            (item.dataQuality, 12),
            (item.strengths.joined(separator: " "), 35),
            (item.considerations.joined(separator: " "), 24),
            (item.idealFor.joined(separator: " "), 30),
            (item.tags.joined(separator: " "), 28),
            (item.specs.map { "\($0.key) \($0.value)" }.joined(separator: " "), 32)
        ]

        for (field, weight) in fields where normalize(field).contains(query) {
            score += weight
        }

        let queryTokens = query.split(separator: " ").map(String.init)
        if queryTokens.count > 1 {
            let combined = normalize(item.searchBlob)
            score += queryTokens.filter { combined.contains($0) }.count * 10
        }

        return score
    }

    static func normalize(_ text: String) -> String {
        ArabicTextNormalizer.normalize(text)
    }
}

struct KnowledgeItem: Identifiable, Hashable, Decodable {
    let id: String
    var name: String
    var category: AskCategory
    var summary: String
    var strengths: [String]
    var considerations: [String]
    var suggestedQuestion: String
    var tags: [String]
    var specs: [String: String]
    var idealFor: [String]
    var dataQuality: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case summary
        case strengths
        case considerations
        case suggestedQuestion
        case tags
        case specs
        case idealFor
        case dataQuality
    }

    init(
        id: String,
        name: String,
        category: AskCategory,
        summary: String,
        strengths: [String],
        considerations: [String],
        suggestedQuestion: String,
        tags: [String],
        specs: [String: String] = [:],
        idealFor: [String] = [],
        dataQuality: String = "مرجعي"
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.summary = summary
        self.strengths = strengths
        self.considerations = considerations
        self.suggestedQuestion = suggestedQuestion
        self.tags = tags
        self.specs = specs
        self.idealFor = idealFor
        self.dataQuality = dataQuality
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let categoryValue = try container.decode(String.self, forKey: .category)
        category = AskCategory(rawValue: categoryValue) ?? .other
        summary = try container.decode(String.self, forKey: .summary)
        strengths = try container.decode([String].self, forKey: .strengths)
        considerations = try container.decode([String].self, forKey: .considerations)
        suggestedQuestion = try container.decode(String.self, forKey: .suggestedQuestion)
        tags = try container.decode([String].self, forKey: .tags)
        specs = try container.decodeIfPresent([String: String].self, forKey: .specs) ?? [:]
        idealFor = try container.decodeIfPresent([String].self, forKey: .idealFor) ?? []
        dataQuality = try container.decodeIfPresent(String.self, forKey: .dataQuality) ?? "مرجعي"
    }

    var searchBlob: String {
        ([name, category.title, summary, suggestedQuestion, dataQuality] + strengths + considerations + idealFor + tags + specs.flatMap { [$0.key, $0.value] })
            .joined(separator: " ")
    }

    static let fallbackItems: [KnowledgeItem] = [
        KnowledgeItem(
            id: "fallback-phone",
            name: "iPhone 16 Pro Max",
            category: .phones,
            summary: "عنصر مرجعي لإنشاء أسئلة مقارنة حول الجوالات الرائدة.",
            strengths: ["كاميرا", "أداء", "نظام"],
            considerations: ["سعر", "حجم"],
            suggestedQuestion: "هل iPhone 16 Pro Max أفضل خيار للتصوير؟",
            tags: ["phones", "كاميرا", "بطارية"],
            specs: ["الفئة": "جوال رائد", "قرار الشراء": "تصوير وأداء"],
            idealFor: ["التصوير", "الاستخدام الطويل"],
            dataQuality: "مرجعي"
        )
    ]
}

enum ComparisonMode: String, CaseIterable, Identifiable {
    case text
    case audio
    case video

    var id: String { rawValue }

    var title: String {
        switch self {
        case .text: "نص"
        case .audio: "صوت"
        case .video: "سيناريو"
        }
    }

    var systemImage: String {
        switch self {
        case .text: "text.alignright"
        case .audio: "waveform"
        case .video: "list.bullet.rectangle"
        }
    }
}

enum ComparisonPriority: String, CaseIterable, Identifiable {
    case balanced
    case price
    case performance
    case dailyUse
    case professional

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balanced: "أفضل توازن"
        case .price: "أفضل سعر"
        case .performance: "أفضل أداء"
        case .dailyUse: "للاستخدام اليومي"
        case .professional: "للمحترفين"
        }
    }

    var systemImage: String {
        switch self {
        case .balanced: "scale.3d"
        case .price: "tag.fill"
        case .performance: "speedometer"
        case .dailyUse: "sun.max.fill"
        case .professional: "briefcase.fill"
        }
    }

    fileprivate var keywords: [String] {
        switch self {
        case .balanced: []
        case .price: ["سعر", "اقتصادي", "توفير", "قيمة", "رخيص"]
        case .performance: ["أداء", "سرعة", "قوة", "معالج", "احترافي"]
        case .dailyUse: ["يومي", "سهولة", "عملي", "بطارية", "راحة", "اعتمادية"]
        case .professional: ["محترف", "احترافي", "إنتاج", "تصميم", "أعمال", "متقدم"]
        }
    }
}

struct ComparisonFactor: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var summary: String
    var bestOptionName: String
}

struct ComparisonCandidate: Identifiable, Hashable {
    var id: String { item.id }
    var item: KnowledgeItem
    var score: Int
    var verdict: String
}

struct ComparisonReport: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var candidates: [ComparisonCandidate]
    var factors: [ComparisonFactor]
    var recommendation: String
    var confidence: Int
    var audioScript: String
    var videoStoryboard: [String]
}

enum ComparisonEngine {
    static func buildReport(
        for items: [KnowledgeItem],
        priority: ComparisonPriority = .balanced
    ) -> ComparisonReport {
        let normalizedItems = Array(items.prefix(10))
        let candidates = normalizedItems.enumerated().map { index, item in
            ComparisonCandidate(
                item: item,
                score: score(item: item, rank: index, priority: priority),
                verdict: verdict(for: item)
            )
        }
        .sorted { $0.score > $1.score }

        let winner = candidates.first
        let runnerUp = candidates.dropFirst().first
        let factorModels = makeFactors(from: candidates)
        let names = normalizedItems.map(\.name).joined(separator: "، ")
        let recommendation: String
        if let winner, let runnerUp {
            recommendation = "بحسب أولوية «\(priority.title)»، يتصدر \(winner.item.name) بفارق \(max(1, winner.score - runnerUp.score)) نقطة؛ لأنه يجمع مؤشرات ملاءمة أوضح وملاحظاته أقل تأثيرًا في القرار."
        } else if let winner {
            recommendation = "\(winner.item.name) خيار مناسب، لكن المقارنة تصبح أدق عند إضافة خيار آخر على الأقل."
        } else {
            recommendation = "أضف خيارين أو أكثر حتى تظهر نتيجة مقارنة دقيقة."
        }

        let audioScript = """
        مقارنة سريعة بين \(names). \
        النتيجة الحالية تشير إلى \(winner?.item.name ?? "عدم وجود ترشيح بعد"). \
        السبب: توازن أفضل بين نقاط القوة والملاحظات. \
        راجع التفاصيل قبل القرار النهائي، خصوصًا السعر والضمان وتجربة المستخدمين.
        """

        let storyboard = [
            "لقطة افتتاحية: عرض الخيارات المختارة مع المجال وعدد عناصر قاعدة المعرفة.",
            "لقطة تحليل: إبراز نقاط القوة ونقاط الانتباه لكل خيار.",
            "لقطة قرار: عرض الخيار المرشح وسبب الترشيح ونسبة الثقة."
        ]

        return ComparisonReport(
            title: normalizedItems.count > 1 ? "مقارنة \(normalizedItems.count) خيارات" : "مقارنة ذكية",
            candidates: candidates,
            factors: factorModels,
            recommendation: recommendation,
            confidence: confidence(for: candidates),
            audioScript: audioScript,
            videoStoryboard: storyboard
        )
    }

    private static func score(item: KnowledgeItem, rank: Int, priority: ComparisonPriority) -> Int {
        let strengthScore = item.strengths.count * 12
        let tagScore = min(item.tags.count * 3, 24)
        let specScore = min(item.specs.count * 4, 20)
        let fitScore = min(item.idealFor.count * 5, 20)
        let cautionPenalty = item.considerations.count * 4
        let summaryScore = min(item.summary.count / 22, 16)
        let normalizedBlob = KnowledgeSearchIndex.normalize(item.searchBlob)
        let priorityScore = priority.keywords.reduce(0) { partialResult, keyword in
            partialResult + (normalizedBlob.contains(KnowledgeSearchIndex.normalize(keyword)) ? 7 : 0)
        }
        return max(45, min(98, 50 + strengthScore + tagScore + specScore + fitScore + summaryScore + priorityScore - cautionPenalty - rank))
    }

    private static func verdict(for item: KnowledgeItem) -> String {
        let strengths = item.strengths.prefix(2).joined(separator: "، ")
        let cautions = item.considerations.prefix(1).joined()
        if cautions.isEmpty {
            return "قوي في \(strengths)، ومناسب كخيار أولي للمقارنة."
        }
        return "قوي في \(strengths)، مع الانتباه إلى \(cautions)."
    }

    private static func makeFactors(from candidates: [ComparisonCandidate]) -> [ComparisonFactor] {
        guard let winner = candidates.first else { return [] }
        let second = candidates.dropFirst().first?.item.name ?? winner.item.name
        return [
            ComparisonFactor(title: "القيمة العامة", summary: "يقارن توازن المزايا مقابل الملاحظات العملية.", bestOptionName: winner.item.name),
            ComparisonFactor(title: "وضوح نقاط القوة", summary: "يعتمد على كثافة نقاط القوة وتنوع الوسوم المرتبطة.", bestOptionName: winner.item.name),
            ComparisonFactor(title: "المخاطر قبل القرار", summary: "الخيار الأقل في نقاط الانتباه يحصل على أفضلية عند تقارب الخيارات.", bestOptionName: second),
            ComparisonFactor(title: "ملاءمة السؤال", summary: "يقيس مدى سهولة تحويل العنصر إلى سؤال تصويت واضح للمستخدمين.", bestOptionName: winner.item.name)
        ]
    }

    private static func confidence(for candidates: [ComparisonCandidate]) -> Int {
        guard candidates.count > 1 else { return 55 }
        let spread = candidates[0].score - candidates[1].score
        return min(92, max(62, 70 + spread))
    }
}

enum ComparisonStatus: String, Codable {
    case active
    case closed
    case draft
    case archived
}

enum ComparisonCategory: String, Codable, CaseIterable, Identifiable {
    case phones
    case cars
    case restaurants
    case laptops
    case services
    case subscriptions
    case travel
    case education
    case home
    case fashion
    case gaming
    case health
    case other

    var id: String { rawValue }

    var arabicTitle: String {
        AskCategory(rawValue: rawValue)?.title ?? "أخرى"
    }

    var systemImage: String {
        AskCategory(rawValue: rawValue)?.systemImage ?? "square.grid.2x2"
    }

    var askCategory: AskCategory {
        AskCategory(rawValue: rawValue) ?? .other
    }
}

struct ComparisonPost: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var category: ComparisonCategory
    var options: [ComparisonOption]
    var author: UserSummary?
    var createdAt: Date
    var expiresAt: Date?
    var isAnonymous: Bool
    var allowsComments: Bool
    var allowsVoteReasons: Bool
    var voteCount: Int
    var commentCount: Int
    var viewCount: Int
    var status: ComparisonStatus
    var tags: [String]
}

struct ComparisonOption: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var subtitle: String?
    var description: String?
    var imageURL: URL?
    var localImageName: String?
    var voteCount: Int
    var strengths: [String]
    var weaknesses: [String]
    var attributes: [ComparisonAttribute]
}

struct ComparisonAttribute: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var value: String
}

struct Vote: Identifiable, Codable, Hashable {
    let id: UUID
    let comparisonID: UUID
    let optionID: UUID
    let userID: UUID?
    let reason: String?
    let createdAt: Date
    let isAnonymous: Bool
}

struct VoteReason: Identifiable, Codable, Hashable {
    let id: UUID
    let voteID: UUID
    let optionID: UUID
    let author: UserSummary?
    let text: String
    let helpfulCount: Int
    let createdAt: Date
}

struct ComparisonComment: Identifiable, Codable, Hashable {
    let id: UUID
    let comparisonID: UUID
    let author: UserSummary?
    let text: String
    let createdAt: Date
    let helpfulCount: Int
}

struct UserSummary: Identifiable, Codable, Hashable {
    let id: UUID
    var displayName: String
    var avatarURL: URL?
    var reputationScore: Int
    var totalVotes: Int
    var totalComparisons: Int
}

struct ComparisonDraft: Codable, Equatable {
    var title: String = ""
    var description: String = ""
    var category: ComparisonCategory = .phones
    var options: [ComparisonOptionDraft] = [
        ComparisonOptionDraft(title: ""),
        ComparisonOptionDraft(title: "")
    ]
    var expiresAt: Date?
    var isAnonymous: Bool = false
    var allowsComments: Bool = true
    var allowsVoteReasons: Bool = true
    var tags: [String] = []
    var visibility: ComparisonVisibility = .publicRoom
    var hideResultsUntilVote: Bool = false

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case category
        case options
        case expiresAt
        case isAnonymous
        case allowsComments
        case allowsVoteReasons
        case tags
        case visibility
        case hideResultsUntilVote
    }

    init(
        title: String = "",
        description: String = "",
        category: ComparisonCategory = .phones,
        options: [ComparisonOptionDraft] = [ComparisonOptionDraft(title: ""), ComparisonOptionDraft(title: "")],
        expiresAt: Date? = nil,
        isAnonymous: Bool = false,
        allowsComments: Bool = true,
        allowsVoteReasons: Bool = true,
        tags: [String] = [],
        visibility: ComparisonVisibility = .publicRoom,
        hideResultsUntilVote: Bool = false
    ) {
        self.title = title
        self.description = description
        self.category = category
        self.options = options
        self.expiresAt = expiresAt
        self.isAnonymous = isAnonymous
        self.allowsComments = allowsComments
        self.allowsVoteReasons = allowsVoteReasons
        self.tags = tags
        self.visibility = visibility
        self.hideResultsUntilVote = hideResultsUntilVote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        category = try container.decodeIfPresent(ComparisonCategory.self, forKey: .category) ?? .phones
        options = try container.decodeIfPresent([ComparisonOptionDraft].self, forKey: .options)
            ?? [ComparisonOptionDraft(title: ""), ComparisonOptionDraft(title: "")]
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous) ?? false
        allowsComments = try container.decodeIfPresent(Bool.self, forKey: .allowsComments) ?? true
        allowsVoteReasons = try container.decodeIfPresent(Bool.self, forKey: .allowsVoteReasons) ?? true
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        visibility = try container.decodeIfPresent(ComparisonVisibility.self, forKey: .visibility) ?? .publicRoom
        hideResultsUntilVote = try container.decodeIfPresent(Bool.self, forKey: .hideResultsUntilVote) ?? false
    }
}

struct ComparisonOptionDraft: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var subtitle: String
    var description: String
    var localImageData: Data?
    var attributes: [ComparisonAttribute]

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        description: String = "",
        localImageData: Data? = nil,
        attributes: [ComparisonAttribute] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.localImageData = localImageData
        self.attributes = attributes
    }
}

enum DecisionConfidenceLevel: String, Codable {
    case low
    case medium
    case high

    var arabicTitle: String {
        switch self {
        case .low: "منخفضة"
        case .medium: "متوسطة"
        case .high: "عالية"
        }
    }

    var percentageRange: ClosedRange<Int> {
        switch self {
        case .low: 0...49
        case .medium: 50...74
        case .high: 75...100
        }
    }
}

struct DecisionHighlight: Identifiable, Codable {
    let id: UUID
    let optionID: UUID
    let title: String
    let details: String
}

enum DecisionClarity: String, Codable {
    case insufficientData
    case close
    case leaning
    case decisive

    var arabicTitle: String {
        switch self {
        case .insufficientData: "لا توجد بيانات كافية"
        case .close: "النتيجة متقاربة"
        case .leaning: "يميل الناس لخيار"
        case .decisive: "يوجد فائز واضح"
        }
    }

    var systemImage: String {
        switch self {
        case .insufficientData: "chart.bar.doc.horizontal"
        case .close: "equal.circle"
        case .leaning: "arrow.up.forward.circle"
        case .decisive: "checkmark.seal"
        }
    }
}

struct OptionDecisionInsight: Identifiable, Codable, Hashable {
    let id: UUID
    let optionID: UUID
    let optionTitle: String
    let votePercentage: Int
    let topReasons: [String]
    let positives: [String]
    let negatives: [String]
    let evidenceCount: Int
}

struct DecisionSummary: Codable {
    let winningOptionID: UUID?
    let confidenceLevel: DecisionConfidenceLevel
    let confidenceScore: Int
    let totalVotes: Int
    let voteGapPercentage: Double
    let leadingVotePercentage: Int
    let clarity: DecisionClarity
    let evidenceQuality: EvidenceQualityResult
    let reasonThemes: [ReasonThemeResult]
    let highlights: [DecisionHighlight]
    let optionInsights: [OptionDecisionInsight]
    let recommendationText: String
    let warningText: String?
}

struct PreferenceCriterion: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var weight: Int

    init(id: UUID = UUID(), name: String, weight: Int = 3) {
        self.id = id
        self.name = name
        self.weight = min(5, max(1, weight))
    }
}

struct OptionCriterionScore: Identifiable, Codable, Hashable {
    let id: UUID
    let optionID: UUID
    let criterionID: UUID
    let score: Double
}

struct WeightedComparisonResult: Identifiable, Codable, Hashable {
    let id: UUID
    let optionID: UUID
    let finalScore: Double
    let explanation: String
}

enum AppError: LocalizedError {
    case networkUnavailable
    case unauthorized
    case forbidden
    case invalidInput(String)
    case comparisonNotFound
    case voteAlreadyExists
    case votingClosed
    case uploadFailed
    case decodingFailed
    case serviceUnavailable
    case unavailableData
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "لا يوجد اتصال بالإنترنت."
        case .unauthorized:
            return "يجب تسجيل الدخول لإكمال العملية."
        case .forbidden:
            return "لا تملك صلاحية تنفيذ هذه العملية."
        case .invalidInput(let message):
            return message
        case .comparisonNotFound:
            return "لم يتم العثور على المقارنة."
        case .voteAlreadyExists:
            return "سبق لك التصويت في هذه المقارنة."
        case .votingClosed:
            return "انتهى التصويت في هذه المقارنة."
        case .uploadFailed:
            return "تعذر رفع الصورة."
        case .decodingFailed:
            return "تعذر قراءة البيانات."
        case .serviceUnavailable:
            return "الخدمة غير متاحة حاليًا."
        case .unavailableData:
            return "لا تتوفر بيانات حاليًا."
        case .unknown:
            return "حدث خطأ غير متوقع."
        }
    }
}

protocol ComparisonRepositoryProtocol {
    func fetchComparisons(category: ComparisonCategory?, page: Int) async throws -> [ComparisonPost]
    func fetchComparison(id: UUID) async throws -> ComparisonPost
    func createComparison(draft: ComparisonDraft) async throws -> ComparisonPost
    func updateComparison(id: UUID, draft: ComparisonDraft) async throws -> ComparisonPost
    func deleteComparison(id: UUID) async throws
    func searchComparisons(query: String) async throws -> [ComparisonPost]
}

protocol VotingRepositoryProtocol {
    func vote(comparisonID: UUID, optionID: UUID, reason: String?, isAnonymous: Bool) async throws -> Vote
    func updateVote(voteID: UUID, optionID: UUID, reason: String?) async throws -> Vote
    func deleteVote(voteID: UUID) async throws
}

protocol BookmarkRepositoryProtocol {
    func saveComparison(id: UUID) async throws
    func removeSavedComparison(id: UUID) async throws
    func fetchSavedComparisonIDs() async throws -> Set<UUID>
}

protocol CommentRepositoryProtocol {
    func fetchComments(comparisonID: UUID, page: Int) async throws -> [ComparisonComment]
    func addComment(comparisonID: UUID, text: String) async throws -> ComparisonComment
    func deleteComment(id: UUID) async throws
}

protocol AuthenticationServiceProtocol {
    var currentUser: UserSummary? { get }
    func signInWithApple() async throws -> UserSummary
    func signOut() async throws
    func deleteAccount() async throws
}

enum ComparisonValidationService {
    static func validate(draft: ComparisonDraft) throws {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            throw AppError.invalidInput("اكتب عنوان المقارنة أولًا.")
        }

        let optionNames = draft.options
            .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard optionNames.count >= 2 else {
            throw AppError.invalidInput("أضف خيارين على الأقل للمقارنة.")
        }
        guard optionNames.count <= 10 else {
            throw AppError.invalidInput("لا يمكن إضافة أكثر من عشرة خيارات.")
        }

        let normalized = optionNames.map(KnowledgeSearchIndex.normalize)
        guard Set(normalized).count == normalized.count else {
            throw AppError.invalidInput("أسماء الخيارات لا يجب أن تكون مكررة.")
        }
    }
}

final class LocalDraftStore: @unchecked Sendable {
    static let shared = LocalDraftStore()
    private let key = "wash_alray_comparison_draft"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private init() {}

    func save(_ draft: ComparisonDraft) {
        guard let data = try? encoder.encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func load() -> ComparisonDraft? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? decoder.decode(ComparisonDraft.self, from: data)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

final class LocalBookmarkRepository: BookmarkRepositoryProtocol, @unchecked Sendable {
    static let shared = LocalBookmarkRepository()
    private let key = "wash_alray_saved_comparison_ids"

    private init() {}

    func saveComparison(id: UUID) async throws {
        var ids = try await fetchSavedComparisonIDs()
        ids.insert(id)
        persist(ids)
    }

    func removeSavedComparison(id: UUID) async throws {
        var ids = try await fetchSavedComparisonIDs()
        ids.remove(id)
        persist(ids)
    }

    func fetchSavedComparisonIDs() async throws -> Set<UUID> {
        let values = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(values.compactMap(UUID.init(uuidString:)))
    }

    private func persist(_ ids: Set<UUID>) {
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: key)
    }
}

final class LocalVotingRepository: VotingRepositoryProtocol, @unchecked Sendable {
    static let shared = LocalVotingRepository()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let key = "wash_alray_local_votes"

    private init() {}

    func vote(comparisonID: UUID, optionID: UUID, reason: String?, isAnonymous: Bool) async throws -> Vote {
        var votes = loadVotes()
        if votes.contains(where: { $0.comparisonID == comparisonID }) {
            throw AppError.voteAlreadyExists
        }
        let vote = Vote(
            id: UUID(),
            comparisonID: comparisonID,
            optionID: optionID,
            userID: nil,
            reason: reason?.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date(),
            isAnonymous: isAnonymous
        )
        votes.append(vote)
        saveVotes(votes)
        return vote
    }

    func updateVote(voteID: UUID, optionID: UUID, reason: String?) async throws -> Vote {
        var votes = loadVotes()
        guard let index = votes.firstIndex(where: { $0.id == voteID }) else {
            throw AppError.unavailableData
        }
        let old = votes[index]
        let updated = Vote(
            id: old.id,
            comparisonID: old.comparisonID,
            optionID: optionID,
            userID: old.userID,
            reason: reason?.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: old.createdAt,
            isAnonymous: old.isAnonymous
        )
        votes[index] = updated
        saveVotes(votes)
        return updated
    }

    func deleteVote(voteID: UUID) async throws {
        var votes = loadVotes()
        votes.removeAll { $0.id == voteID }
        saveVotes(votes)
    }

    private func loadVotes() -> [Vote] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let votes = try? decoder.decode([Vote].self, from: data) else {
            return []
        }
        return votes
    }

    private func saveVotes(_ votes: [Vote]) {
        guard let data = try? encoder.encode(votes) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

enum DecisionSummaryService {
    static func makeSummary(for question: AskQuestion) -> DecisionSummary {
        let sorted = question.options.sorted { $0.votes > $1.votes }
        let winner = sorted.first
        let runnerUp = sorted.dropFirst().first
        let totalVotes = question.totalVotes
        let leadingPercentage = winner.map { votePercentage(option: $0, totalVotes: totalVotes) } ?? 0
        let gap: Double
        if let winner, let runnerUp, totalVotes > 0 {
            gap = (Double(winner.votes - runnerUp.votes) / Double(totalVotes)) * 100
        } else {
            gap = 0
        }

        let reasonComments = question.comments.filter { $0.optionID != nil }
        let triedOptionCount = reasonComments.filter { $0.trustBadge != nil }.count
        let firstPercentage = Double(leadingPercentage)
        let secondPercentage = runnerUp.map { Double(votePercentage(option: $0, totalVotes: totalVotes)) } ?? 0
        let stateResult = DecisionStateEngine.evaluate(
            totalVotes: totalVotes,
            firstPercentage: firstPercentage,
            secondPercentage: secondPercentage,
            reasonCount: reasonComments.count,
            triedOptionCount: triedOptionCount
        )

        let confidence: DecisionConfidenceLevel = switch stateResult.confidence {
        case .low: .low
        case .medium: .medium
        case .high: .high
        }

        let clarity: DecisionClarity = switch stateResult.state {
        case .insufficientData: .insufficientData
        case .closeResult: .close
        case .clearLean: .leaning
        case .decisive: .decisive
        }

        let lastActivity = question.comments.map(\.createdAt).max() ?? question.createdAt
        let evidenceQuality = EvidenceQualityEngine.evaluate(
            participantCount: totalVotes,
            reasonCount: reasonComments.count,
            triedOptionCount: triedOptionCount,
            lastActivityDate: lastActivity
        )
        let reasonThemes = ArabicReasonAnalyzer.analyze(reasons: reasonComments.map(\.text))

        let optionInsights = sorted.map { option in
            makeOptionInsight(for: option, in: question)
        }

        let recommendation: String
        if let winner, totalVotes > 0 {
            let reasons = optionInsights.first { $0.optionID == winner.id }?.topReasons.prefix(2).joined(separator: " و") ?? ""
            let reasonSuffix = reasons.isEmpty ? "لكن الأسباب المكتوبة ما زالت محدودة." : "وأكثر ما يدعم هذا الاتجاه: \(reasons)."
            recommendation = "يميل المصوتون إلى \(winner.title) بنسبة \(leadingPercentage)%. \(reasonSuffix) لا تعتبرها حقيقة مطلقة؛ طابقها مع احتياجك قبل القرار."
        } else {
            recommendation = "النتيجة غير حاسمة بعد. أضف تصويتات وأسبابًا حتى يظهر اتجاه أوضح."
        }

        let warning = stateResult.warning

        let highlights = sorted.prefix(3).map { option in
            let insight = optionInsights.first { $0.optionID == option.id }
            let reasons = insight?.topReasons.prefix(2).joined(separator: "، ") ?? ""
            let detail = reasons.isEmpty
                ? "\(option.votes) صوت، ولا توجد أسباب كافية بعد لهذا الخيار."
                : "\(option.votes) صوت، وأبرز الأسباب: \(reasons)."
            return DecisionHighlight(
                id: UUID(),
                optionID: option.id,
                title: option.title,
                details: detail
            )
        }

        return DecisionSummary(
            winningOptionID: winner?.id,
            confidenceLevel: confidence,
            confidenceScore: stateResult.confidenceScore,
            totalVotes: totalVotes,
            voteGapPercentage: gap,
            leadingVotePercentage: leadingPercentage,
            clarity: clarity,
            evidenceQuality: evidenceQuality,
            reasonThemes: reasonThemes,
            highlights: highlights,
            optionInsights: optionInsights,
            recommendationText: recommendation,
            warningText: warning
        )
    }

    private static func makeOptionInsight(for option: PollOption, in question: AskQuestion) -> OptionDecisionInsight {
        let relatedComments = question.comments.filter { comment in
            comment.optionID == option.id || comment.optionTitle == option.title
        }
        let analyzedThemes = ArabicReasonAnalyzer.analyze(reasons: relatedComments.map(\.text))
        let explicitReasons = rankedReasons(from: relatedComments, category: question.category)
        let topReasons = Array(
            (explicitReasons + analyzedThemes.map(\.title))
                .reduce(into: [String]()) { values, value in
                    if !values.contains(value) { values.append(value) }
                }
                .prefix(5)
        )
        let keywordPositives = rankedKeywords(
            from: relatedComments,
            keywords: ["جودة", "سعر", "ضمان", "بطارية", "كاميرا", "راحة", "اعتمادية", "خدمة", "عملي", "قيمة", "أداء", "توفير"]
        )
        let keywordNegatives = rankedKeywords(
            from: relatedComments,
            keywords: ["غالي", "صيانة", "استهلاك", "ضعيف", "بطء", "حرارة", "قطع", "زحمة", "عيب", "تأخير", "وزن", "محدود"]
        )
        let positives = Array((analyzedThemes.filter { $0.positiveCount > $0.negativeCount }.map(\.title) + keywordPositives).prefix(4))
        let negatives = Array((analyzedThemes.filter { $0.negativeCount > $0.positiveCount }.map(\.title) + keywordNegatives).prefix(4))

        return OptionDecisionInsight(
            id: UUID(),
            optionID: option.id,
            optionTitle: option.title,
            votePercentage: votePercentage(option: option, totalVotes: question.totalVotes),
            topReasons: topReasons,
            positives: positives,
            negatives: negatives,
            evidenceCount: relatedComments.count
        )
    }

    private static func votePercentage(option: PollOption, totalVotes: Int) -> Int {
        guard totalVotes > 0 else { return 0 }
        return Int((Double(option.votes) / Double(totalVotes)) * 100)
    }

    private static func rankedReasons(from comments: [AskComment], category: AskCategory) -> [String] {
        let explicitReasons = comments.compactMap { $0.reasonCategory?.trimmingCharacters(in: .whitespacesAndNewlines) }
        var counts = Dictionary(grouping: explicitReasons.filter { !$0.isEmpty }, by: { $0 }).mapValues(\.count)

        let fallbackReasons = DecisionFeatureCatalog.voteReasons(for: category)
        let blob = comments.map(\.text).joined(separator: " ")
        for reason in fallbackReasons where blob.localizedCaseInsensitiveContains(reason) {
            counts[reason, default: 0] += 1
        }

        return counts.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key < rhs.key
            }
            return lhs.value > rhs.value
        }
        .map(\.key)
    }

    private static func rankedKeywords(from comments: [AskComment], keywords: [String]) -> [String] {
        let blob = comments.map { [$0.text, $0.reasonCategory ?? ""].joined(separator: " ") }.joined(separator: " ")
        return keywords
            .filter { blob.localizedCaseInsensitiveContains($0) }
            .prefix(4)
            .map { $0 }
    }
}

enum ComparisonScoringService {
    static func score(
        question: AskQuestion,
        criteria: [PreferenceCriterion],
        optionScores: [OptionCriterionScore] = []
    ) -> [WeightedComparisonResult] {
        guard !criteria.isEmpty else {
            return question.options.map { option in
                WeightedComparisonResult(
                    id: UUID(),
                    optionID: option.id,
                    finalScore: voteShare(option: option, totalVotes: question.totalVotes),
                    explanation: "النتيجة مبنية على نسبة تصويت المجتمع فقط لعدم تحديد معايير شخصية."
                )
            }
        }

        let totalWeight = Double(criteria.reduce(0) { $0 + $1.weight })
        return question.options.map { option in
            let personalScore = criteria.reduce(0.0) { partial, criterion in
                let explicitScore = optionScores.first { $0.optionID == option.id && $0.criterionID == criterion.id }?.score
                let inferredScore = explicitScore ?? inferredCriterionScore(option: option, criterionName: criterion.name)
                return partial + (inferredScore * Double(criterion.weight))
            } / max(totalWeight, 1)
            let communityScore = voteShare(option: option, totalVotes: question.totalVotes)
            let finalScore = (personalScore * 0.65) + (communityScore * 0.35)
            return WeightedComparisonResult(
                id: UUID(),
                optionID: option.id,
                finalScore: min(100, max(0, finalScore)),
                explanation: "تم دمج أولوياتك مع اتجاه تصويت المجتمع لإعطاء ترشيح أقرب لاحتياجك."
            )
        }
        .sorted { $0.finalScore > $1.finalScore }
    }

    private static func voteShare(option: PollOption, totalVotes: Int) -> Double {
        guard totalVotes > 0 else { return 50 }
        return (Double(option.votes) / Double(totalVotes)) * 100
    }

    private static func inferredCriterionScore(option: PollOption, criterionName: String) -> Double {
        let blob = KnowledgeSearchIndex.normalize(option.title + " " + criterionName)
        if blob.contains("اقتصاد") || blob.contains("سعر") || blob.contains("قيمه") {
            return 70
        }
        if blob.contains("جوده") || blob.contains("اداء") || blob.contains("اعتماديه") {
            return 75
        }
        return 60
    }
}

struct ComparisonSpecificationRow: Identifiable, Hashable {
    let id = UUID()
    let criterion: String
    let values: [UUID: String]
    let leadingOptionID: UUID?
}

enum ComparisonSpecificationService {
    static func rows(for question: AskQuestion) -> [ComparisonSpecificationRow] {
        DecisionFeatureCatalog.criteria(for: question.category).prefix(6).map { criterion in
            let scoredOptions = question.options.map { option in
                (option: option, score: score(option: option, criterion: criterion, question: question))
            }
            let best = scoredOptions.max { $0.score < $1.score }?.option.id
            let values = Dictionary(uniqueKeysWithValues: scoredOptions.map { item in
                (item.option.id, label(for: item.score))
            })

            return ComparisonSpecificationRow(
                criterion: criterion,
                values: values,
                leadingOptionID: best
            )
        }
    }

    private static func score(option: PollOption, criterion: String, question: AskQuestion) -> Int {
        let relatedComments = question.comments.filter { $0.optionID == option.id || $0.optionTitle == option.title }
        let evidence = KnowledgeSearchIndex.normalize(
            ([option.title, criterion] + relatedComments.flatMap { [$0.text, $0.reasonCategory ?? ""] })
                .joined(separator: " ")
        )

        var score = 50
        if question.totalVotes > 0 {
            score += Int((Double(option.votes) / Double(question.totalVotes)) * 25)
        }
        if evidence.contains(KnowledgeSearchIndex.normalize(criterion)) {
            score += 14
        }
        if evidence.contains("افضل") || evidence.contains("اعلي") || evidence.contains("اقوي") || evidence.contains("ممتاز") {
            score += 8
        }
        if evidence.contains("غالي") || evidence.contains("ضعيف") || evidence.contains("عيب") || evidence.contains("تاخير") {
            score -= 10
        }
        return min(100, max(0, score))
    }

    private static func label(for score: Int) -> String {
        switch score {
        case 82...100:
            return "قوي جدًا"
        case 68..<82:
            return "قوي"
        case 52..<68:
            return "متوسط"
        default:
            return "يحتاج آراء"
        }
    }
}

enum ComparisonTemplateLibrary {
    static let quickPrompts: [String] = [
        "آيفون أم سامسونج؟",
        "كامري أم أكورد؟",
        "أفضل مطعم للعائلة؟",
        "أفضل لابتوب للدراسة؟",
        "أفضل شركة شحن؟",
        "أفضل خدمة بث؟",
        "أشتري الآن أم أنتظر؟",
        "المنتج الأصلي أم البديل الأرخص؟"
    ]
}

private struct SeedQuestionRecord: Decodable {
    let title: String
    let details: String
    let category: String
    let author: String
    let timeAgo: String
    let options: [SeedOptionRecord]
    let comments: [SeedCommentRecord]
}

private struct SeedOptionRecord: Decodable {
    let title: String
    let votes: Int
}

private struct SeedCommentRecord: Decodable {
    let author: String
    let text: String
    let likes: Int
}
