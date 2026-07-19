import Foundation

struct DecisionCriterion: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var weight: Double

    init(id: UUID = UUID(), title: String, weight: Double = 1) {
        self.id = id
        self.title = title
        self.weight = min(max(weight, 0), 5)
    }
}

struct EvaluatedOption: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var title: String
    var scores: [UUID: Double]

    init(id: UUID = UUID(), title: String, scores: [UUID: Double] = [:]) {
        self.id = id
        self.title = title
        self.scores = scores
    }
}

struct RankedDecisionOption: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let title: String
    let score: Double
    let rank: Int
}

enum WeightedDecisionEngine {
    static func rank(
        options: [EvaluatedOption],
        criteria: [DecisionCriterion]
    ) -> [RankedDecisionOption] {
        let activeCriteria = criteria.filter { $0.weight > 0 }
        let totalWeight = activeCriteria.reduce(0) { $0 + $1.weight }

        guard totalWeight > 0 else {
            return options.enumerated().map { index, option in
                RankedDecisionOption(id: option.id, title: option.title, score: 0, rank: index + 1)
            }
        }

        return options
            .map { option in
                let weightedTotal = activeCriteria.reduce(0.0) { partial, criterion in
                    let rawScore = option.scores[criterion.id] ?? 0
                    return partial + min(max(rawScore, 0), 10) * criterion.weight
                }
                return (option: option, score: weightedTotal / totalWeight)
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.option.title.localizedStandardCompare(rhs.option.title) == .orderedAscending
                }
                return lhs.score > rhs.score
            }
            .enumerated()
            .map { index, item in
                RankedDecisionOption(
                    id: item.option.id,
                    title: item.option.title,
                    score: item.score,
                    rank: index + 1
                )
            }
    }
}

enum DecisionState: String, Codable, Hashable, Sendable {
    case insufficientData
    case closeResult
    case clearLean
    case decisive

    var title: String {
        switch self {
        case .insufficientData: "بيانات غير كافية"
        case .closeResult: "نتيجة متقاربة"
        case .clearLean: "ميل واضح"
        case .decisive: "نتيجة حاسمة"
        }
    }
}

enum DecisionConfidence: String, Codable, Hashable, Sendable {
    case low
    case medium
    case high

    var title: String {
        switch self {
        case .low: "منخفضة"
        case .medium: "متوسطة"
        case .high: "مرتفعة"
        }
    }
}

struct DecisionStateResult: Codable, Hashable, Sendable {
    let state: DecisionState
    let confidence: DecisionConfidence
    let confidenceScore: Int
    let margin: Double
    let warning: String?
}

enum DecisionStateEngine {
    static func evaluate(
        totalVotes: Int,
        firstPercentage: Double,
        secondPercentage: Double,
        reasonCount: Int,
        triedOptionCount: Int
    ) -> DecisionStateResult {
        let safeVotes = max(totalVotes, 0)
        let margin = max(0, firstPercentage - secondPercentage)

        let state: DecisionState
        if safeVotes < 10 {
            state = .insufficientData
        } else if margin < 5 {
            state = .closeResult
        } else if safeVotes >= 60 && firstPercentage >= 70 && margin >= 25 {
            state = .decisive
        } else {
            state = .clearLean
        }

        let sampleScore = min(Double(safeVotes) / 60, 1) * 45
        let marginScore = min(margin / 25, 1) * 30
        let reasonCoverage = safeVotes > 0 ? min(Double(reasonCount) / Double(safeVotes), 1) : 0
        let reasonScore = reasonCoverage * 15
        let triedCoverage = reasonCount > 0 ? min(Double(triedOptionCount) / Double(reasonCount), 1) : 0
        let experienceScore = triedCoverage * 10
        let confidenceScore = Int(min(sampleScore + marginScore + reasonScore + experienceScore, 100).rounded())

        let confidence: DecisionConfidence
        switch confidenceScore {
        case 0..<40: confidence = .low
        case 40..<70: confidence = .medium
        default: confidence = .high
        }

        let warning: String?
        if safeVotes < 10 {
            warning = "عدد المشاركين قليل، لذلك قد تتغير النتيجة بسرعة."
        } else if margin < 5 {
            warning = "الفارق بسيط، راجع أسباب المشاركين قبل اتخاذ القرار."
        } else if reasonCoverage < 0.15 {
            warning = "معظم المشاركين لم يضيفوا أسبابًا لاختياراتهم."
        } else {
            warning = nil
        }

        return DecisionStateResult(
            state: state,
            confidence: confidence,
            confidenceScore: confidenceScore,
            margin: margin,
            warning: warning
        )
    }
}

enum EvidenceQualityLevel: String, Codable, Hashable, Sendable {
    case weak
    case acceptable
    case good
    case strong

    var title: String {
        switch self {
        case .weak: "ضعيفة"
        case .acceptable: "مقبولة"
        case .good: "جيدة"
        case .strong: "قوية"
        }
    }
}

struct EvidenceQualityResult: Codable, Hashable, Sendable {
    let score: Int
    let level: EvidenceQualityLevel
    let notes: [String]
    let reasonCoverage: Double
    let triedCoverage: Double
}

enum EvidenceQualityEngine {
    static func evaluate(
        participantCount: Int,
        reasonCount: Int,
        triedOptionCount: Int,
        lastActivityDate: Date,
        now: Date = Date()
    ) -> EvidenceQualityResult {
        let safeParticipants = max(participantCount, 1)
        let safeReasons = max(reasonCount, 1)
        let sampleScore = min(Double(max(participantCount, 0)) / 60, 1) * 40
        let reasonCoverage = min(Double(max(reasonCount, 0)) / Double(safeParticipants), 1)
        let reasonScore = reasonCoverage * 25
        let triedCoverage = min(Double(max(triedOptionCount, 0)) / Double(safeReasons), 1)
        let triedScore = triedCoverage * 20
        let daysSinceLastActivity = max(
            Calendar.current.dateComponents([.day], from: lastActivityDate, to: now).day ?? 0,
            0
        )

        let freshnessScore: Double
        switch daysSinceLastActivity {
        case ...7: freshnessScore = 15
        case 8...30: freshnessScore = 9
        default: freshnessScore = 4
        }

        let finalScore = Int(min(sampleScore + reasonScore + triedScore + freshnessScore, 100).rounded())
        let level: EvidenceQualityLevel
        switch finalScore {
        case 0..<35: level = .weak
        case 35..<60: level = .acceptable
        case 60..<80: level = .good
        default: level = .strong
        }

        var notes: [String] = []
        if participantCount < 10 { notes.append("عدد المشاركين ما زال منخفضًا.") }
        if reasonCoverage < 0.20 { notes.append("نسبة الأسباب المكتوبة منخفضة.") }
        if triedCoverage < 0.20 { notes.append("عدد المشاركين الذين جرّبوا الخيارات محدود.") }
        if daysSinceLastActivity > 30 { notes.append("بعض البيانات قديمة نسبيًا.") }
        if notes.isEmpty { notes.append("المقارنة تحتوي على مستوى جيد من المشاركة والأسباب.") }

        return EvidenceQualityResult(
            score: finalScore,
            level: level,
            notes: notes,
            reasonCoverage: reasonCoverage,
            triedCoverage: triedCoverage
        )
    }
}

enum ArabicTextNormalizer {
    static func normalize(_ text: String) -> String {
        var result = text.lowercased()
        let replacements = [
            "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا",
            "ى": "ي", "ؤ": "و", "ئ": "ي", "ة": "ه", "ـ": ""
        ]

        for (source, replacement) in replacements {
            result = result.replacingOccurrences(of: source, with: replacement)
        }

        result = result.replacingOccurrences(
            of: "[\\u064B-\\u065F\\u0670\\u06D6-\\u06ED]",
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "[^\\p{Arabic}a-z0-9\\s]",
            with: " ",
            options: .regularExpression
        )
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ReasonThemeDefinition: Hashable, Sendable {
    let key: String
    let title: String
    let keywords: [String]
}

struct ReasonThemeResult: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let mentionCount: Int
    let positiveCount: Int
    let negativeCount: Int

    var sentimentLabel: String {
        if positiveCount > negativeCount { return "نقطة قوة" }
        if negativeCount > positiveCount { return "ملاحظة متكررة" }
        return "آراء متنوعة"
    }
}

enum ArabicReasonAnalyzer {
    private static let themes = [
        ReasonThemeDefinition(key: "camera", title: "الكاميرا والتصوير", keywords: ["كاميرا", "تصوير", "صور", "فيديو", "عدسه"]),
        ReasonThemeDefinition(key: "battery", title: "البطارية", keywords: ["بطاريه", "شحن", "يصمد", "استهلاك"]),
        ReasonThemeDefinition(key: "price", title: "السعر والقيمة", keywords: ["سعر", "غالي", "رخيص", "قيمه", "ميزانيه", "تكلفه"]),
        ReasonThemeDefinition(key: "usability", title: "سهولة الاستخدام", keywords: ["سهل", "سهوله", "استخدام", "واجهه", "بسيط"]),
        ReasonThemeDefinition(key: "reliability", title: "الاعتمادية", keywords: ["اعتماديه", "يتحمل", "ثابت", "مشاكل", "خراب", "صيانه"]),
        ReasonThemeDefinition(key: "screen", title: "الشاشة والتصميم", keywords: ["شاشه", "تصميم", "سطوع", "الوان", "حجم"]),
        ReasonThemeDefinition(key: "performance", title: "الأداء", keywords: ["اداء", "سرعه", "سريع", "تعليق", "معالج", "قوي"]),
        ReasonThemeDefinition(key: "service", title: "الخدمة والدعم", keywords: ["خدمه", "دعم", "ضمان", "فروع", "موظفين"])
    ]
    private static let positiveWords = ["ممتاز", "افضل", "رايع", "قوي", "سريع", "مريح", "واضح", "عملي", "موثوق", "مناسب", "جيد", "جميل"]
    private static let negativeWords = ["سيء", "ضعيف", "غالي", "بطيء", "مزعج", "مشاكل", "تعليق", "خراب", "صعب", "ثقيل", "رديء"]

    static func analyze(reasons: [String]) -> [ReasonThemeResult] {
        themes.compactMap { theme in
            var mentions = 0
            var positives = 0
            var negatives = 0

            for reason in reasons {
                let normalized = ArabicTextNormalizer.normalize(reason)
                guard theme.keywords.contains(where: { normalized.contains(ArabicTextNormalizer.normalize($0)) }) else {
                    continue
                }
                mentions += 1
                if positiveWords.contains(where: { normalized.contains(ArabicTextNormalizer.normalize($0)) }) {
                    positives += 1
                }
                if negativeWords.contains(where: { normalized.contains(ArabicTextNormalizer.normalize($0)) }) {
                    negatives += 1
                }
            }

            guard mentions > 0 else { return nil }
            return ReasonThemeResult(
                id: theme.key,
                title: theme.title,
                mentionCount: mentions,
                positiveCount: positives,
                negativeCount: negatives
            )
        }
        .sorted { lhs, rhs in
            if lhs.mentionCount == rhs.mentionCount { return lhs.title < rhs.title }
            return lhs.mentionCount > rhs.mentionCount
        }
    }
}

struct DecisionOutcomeSnapshot: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let comparisonID: UUID
    let chosenOptionID: UUID
    let satisfactionScore: Int
    let wouldChooseAgain: Bool
    let note: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        comparisonID: UUID,
        chosenOptionID: UUID,
        satisfactionScore: Int,
        wouldChooseAgain: Bool,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.comparisonID = comparisonID
        self.chosenOptionID = chosenOptionID
        self.satisfactionScore = min(max(satisfactionScore, 1), 5)
        self.wouldChooseAgain = wouldChooseAgain
        self.note = String(note.prefix(300))
        self.createdAt = createdAt
    }
}

struct OutcomeStatistics: Hashable, Sendable {
    let responses: Int
    let averageSatisfaction: Double
    let chooseAgainPercentage: Double
}

enum OutcomeStatisticsEngine {
    static func calculate(outcomes: [DecisionOutcomeSnapshot], optionID: UUID) -> OutcomeStatistics {
        let matching = outcomes.filter { $0.chosenOptionID == optionID }
        guard !matching.isEmpty else {
            return OutcomeStatistics(responses: 0, averageSatisfaction: 0, chooseAgainPercentage: 0)
        }
        let average = Double(matching.reduce(0) { $0 + $1.satisfactionScore }) / Double(matching.count)
        let chooseAgainCount = matching.filter(\.wouldChooseAgain).count
        return OutcomeStatistics(
            responses: matching.count,
            averageSatisfaction: average,
            chooseAgainPercentage: Double(chooseAgainCount) / Double(matching.count) * 100
        )
    }
}

struct RankedBallot: Codable, Hashable, Sendable {
    let orderedOptionIDs: [UUID]
}

struct RankedOptionResult: Identifiable, Codable, Hashable, Sendable {
    var id: UUID { optionID }
    let optionID: UUID
    let points: Int
    let rank: Int
}

enum RankedVotingEngine {
    static func calculate(optionIDs: [UUID], ballots: [RankedBallot]) -> [RankedOptionResult] {
        var points = Dictionary(uniqueKeysWithValues: optionIDs.map { ($0, 0) })
        for ballot in ballots {
            for (index, optionID) in ballot.orderedOptionIDs.prefix(3).enumerated() where points[optionID] != nil {
                points[optionID, default: 0] += max(3 - index, 0)
            }
        }
        return points
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key.uuidString < rhs.key.uuidString }
                return lhs.value > rhs.value
            }
            .enumerated()
            .map { index, item in
                RankedOptionResult(optionID: item.key, points: item.value, rank: index + 1)
            }
    }
}

struct VoteTrendEvent: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let comparisonID: UUID
    let optionID: UUID
    let optionName: String
    let createdAt: Date
}

struct VoteTrendPoint: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let optionID: UUID
    let optionName: String
    let cumulativeVotes: Int
}

enum VoteTrendEngine {
    static func cumulativePoints(events: [VoteTrendEvent]) -> [VoteTrendPoint] {
        var counts: [UUID: Int] = [:]
        return events.sorted { $0.createdAt < $1.createdAt }.map { event in
            counts[event.optionID, default: 0] += 1
            return VoteTrendPoint(
                id: event.id,
                date: event.createdAt,
                optionID: event.optionID,
                optionName: event.optionName,
                cumulativeVotes: counts[event.optionID, default: 0]
            )
        }
    }
}

struct PersonalDecisionEvaluation: Codable, Hashable, Sendable {
    var criteria: [DecisionCriterion]
    var options: [EvaluatedOption]
    var updatedAt: Date
}
