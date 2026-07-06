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

    init(id: UUID = UUID(), author: String, text: String, likes: Int) {
        self.id = id
        self.author = author
        self.text = text
        self.likes = likes
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
}

enum AskDemoStore {
    static let questions: [AskQuestion] = loadSeedQuestions()

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
            author: "فريق اسأل",
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
            author: "فريق اسأل",
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
            author: "فريق اسأل",
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
