import Foundation

enum AskCategory: String, CaseIterable, Identifiable {
    case all
    case phones
    case cars
    case restaurants
    case laptops
    case gaming
    case travel
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "الكل"
        case .phones: "جوالات"
        case .cars: "سيارات"
        case .restaurants: "مطاعم"
        case .laptops: "لابتوبات"
        case .gaming: "ألعاب"
        case .travel: "سفر"
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
        case .gaming: "gamecontroller"
        case .travel: "airplane"
        case .other: "sparkles"
        }
    }
}

struct PollOption: Identifiable, Hashable {
    let id: UUID
    var title: String
    var votes: Int

    init(id: UUID = UUID(), title: String, votes: Int) {
        self.id = id
        self.title = title
        self.votes = votes
    }
}

struct AskComment: Identifiable, Hashable {
    let id: UUID
    var author: String
    var text: String
    var likes: Int
    var optionID: UUID?
    var optionTitle: String?
    var trustBadge: String?
    var reasonCategory: String?

    init(
        id: UUID = UUID(),
        author: String,
        text: String,
        likes: Int,
        optionID: UUID? = nil,
        optionTitle: String? = nil,
        trustBadge: String? = nil,
        reasonCategory: String? = nil
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.likes = likes
        self.optionID = optionID
        self.optionTitle = optionTitle
        self.trustBadge = trustBadge
        self.reasonCategory = reasonCategory
    }
}

struct AskQuestion: Identifiable, Hashable {
    let id: UUID
    var title: String
    var details: String
    var category: AskCategory
    var author: String
    var timeAgo: String
    var options: [PollOption]
    var comments: [AskComment]

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        category: AskCategory,
        author: String,
        timeAgo: String,
        options: [PollOption],
        comments: [AskComment]
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.category = category
        self.author = author
        self.timeAgo = timeAgo
        self.options = options
        self.comments = comments
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
        guard totalVotes > 0, let winner = winningOption else { return 52 }
        let lead = Double(winner.votes) / Double(max(totalVotes, 1))
        let reasonDepth = min(comments.count * 4, 24)
        let verifiedBoost = min(verifiedComments.count * 7, 21)
        return min(96, max(55, Int(lead * 58) + reasonDepth + verifiedBoost))
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
        case .gaming:
            ["الألعاب", "الأداء", "الاشتراكات", "السعر", "الأصدقاء", "التوفر"]
        case .travel:
            ["السعر", "الراحة", "الموقع", "الأمان", "الخدمات", "التجربة"]
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
        case .gaming:
            ["الألعاب أفضل", "الأصدقاء عليه", "الاشتراك أقوى", "الأداء أعلى", "السعر مناسب"]
        case .travel:
            ["أريح للسفر", "سعره أفضل", "موقعه مناسب", "تجربة الناس أفضل", "الخدمات أوضح"]
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
        text
            .lowercased()
            .replacingOccurrences(of: "أ", with: "ا")
            .replacingOccurrences(of: "إ", with: "ا")
            .replacingOccurrences(of: "آ", with: "ا")
            .replacingOccurrences(of: "ى", with: "ي")
            .replacingOccurrences(of: "ة", with: "ه")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
        case .video: "فيديو"
        }
    }

    var systemImage: String {
        switch self {
        case .text: "text.alignright"
        case .audio: "waveform"
        case .video: "play.rectangle.fill"
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
    static func buildReport(for items: [KnowledgeItem]) -> ComparisonReport {
        let normalizedItems = Array(items.prefix(10))
        let candidates = normalizedItems.enumerated().map { index, item in
            ComparisonCandidate(
                item: item,
                score: score(item: item, rank: index),
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
            recommendation = "الأقرب للترشيح هو \(winner.item.name) بفارق \(max(1, winner.score - runnerUp.score)) نقطة؛ لأنه يجمع نقاط قوة أوضح وملاحظاته أقل تأثيرًا في قرار الشراء."
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

    private static func score(item: KnowledgeItem, rank: Int) -> Int {
        let strengthScore = item.strengths.count * 12
        let tagScore = min(item.tags.count * 3, 24)
        let specScore = min(item.specs.count * 4, 20)
        let fitScore = min(item.idealFor.count * 5, 20)
        let cautionPenalty = item.considerations.count * 4
        let summaryScore = min(item.summary.count / 22, 16)
        return max(45, min(98, 50 + strengthScore + tagScore + specScore + fitScore + summaryScore - cautionPenalty - rank))
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
