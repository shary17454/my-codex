import SwiftUI

struct AIAssistantMessage: Identifiable, Equatable {
    enum Role: Equatable {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String
    let sources: [String]

    init(id: UUID = UUID(), role: Role, text: String, sources: [String] = []) {
        self.id = id
        self.role = role
        self.text = text
        self.sources = sources
    }
}

struct AIAssistantSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let prompt: String
    let systemImage: String
}

struct AIAssistantResponse: Equatable {
    let answer: String
    let sources: [String]
    let matchedQuestionIDs: [UUID]
}

enum AIDecisionAssistantEngine {
    static let systemDisclosure = "إجابة ذكية إرشادية من بيانات التطبيق المتاحة، وليست حكمًا نهائيًا."

    static func answer(
        prompt: String,
        questions: [AskQuestion],
        knowledgeItems: [KnowledgeItem]
    ) -> AIAssistantResponse {
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanPrompt.count >= 2 else {
            return AIAssistantResponse(
                answer: "اكتب سؤالك بشكل أوضح، مثل: «وش أكثر مقارنة تحتاج حسم؟» أو «لخص مقارنة الآيفون».",
                sources: [],
                matchedQuestionIDs: []
            )
        }

        let normalizedPrompt = KnowledgeSearchIndex.normalize(cleanPrompt)
        let matchedQuestions = rankQuestions(questions, query: normalizedPrompt)
        let matchedItems = KnowledgeSearchIndex.search(knowledgeItems, query: cleanPrompt, category: .all)

        if asksForSuggestions(normalizedPrompt) {
            return suggestionResponse(questions: questions, knowledgeItems: knowledgeItems)
        }

        if asksForSummary(normalizedPrompt), let question = matchedQuestions.first {
            return summaryResponse(for: question)
        }

        if asksForSearch(normalizedPrompt) || !matchedQuestions.isEmpty || !matchedItems.isEmpty {
            return searchResponse(
                prompt: cleanPrompt,
                matchedQuestions: matchedQuestions,
                matchedItems: Array(matchedItems.prefix(3))
            )
        }

        return AIAssistantResponse(
            answer: """
            ما لقيت بيانات كافية داخل التطبيق تجاوب على سؤالك بثقة.

            أقدر أساعدك في:
            - تلخيص مقارنة موجودة.
            - البحث عن مقارنة أو عنصر من المكتبة.
            - اقتراح خطوة تالية لتحسين قرارك.
            - صياغة عنوان مقارنة أو أسباب تصويت.
            """,
            sources: [],
            matchedQuestionIDs: []
        )
    }

    static func defaultSuggestions(questions: [AskQuestion]) -> [AIAssistantSuggestion] {
        let closeCount = questions.filter {
            let summary = DecisionSummaryService.makeSummary(for: $0)
            return summary.clarity == .close || summary.clarity == .insufficientData
        }.count

        return [
            AIAssistantSuggestion(
                title: "لخّص أقرب قرار",
                prompt: "لخص أكثر مقارنة تحتاج قرار واضح",
                systemImage: "sparkles.rectangle.stack"
            ),
            AIAssistantSuggestion(
                title: "وش يحتاج تحسين؟",
                prompt: "اقترح لي خطوات لتحسين جودة المقارنات الحالية وعددها \(questions.count) وفيها \(closeCount) غير حاسمة",
                systemImage: "lightbulb.max.fill"
            ),
            AIAssistantSuggestion(
                title: "ابحث طبيعيًا",
                prompt: "ابحث عن مقارنات الجوالات أو الكاميرا أو السعر",
                systemImage: "magnifyingglass"
            )
        ]
    }

    private static func rankQuestions(_ questions: [AskQuestion], query: String) -> [AskQuestion] {
        guard !query.isEmpty else { return [] }
        return questions
            .map { question -> (AskQuestion, Int) in
                let text = KnowledgeSearchIndex.normalize(
                    ([question.title, question.details, question.category.title] + question.options.map(\.title) + question.tags)
                        .joined(separator: " ")
                )
                let queryTokens = query.split(separator: " ").map(String.init)
                let score = queryTokens.reduce(0) { partial, token in
                    partial + (text.contains(token) ? 1 : 0)
                } + (text.contains(query) ? 3 : 0)
                return (question, score)
            }
            .filter { $0.1 > 0 }
            .sorted {
                if $0.1 == $1.1 { return $0.0.totalVotes > $1.0.totalVotes }
                return $0.1 > $1.1
            }
            .map(\.0)
    }

    private static func asksForSummary(_ prompt: String) -> Bool {
        ["لخص", "تلخيص", "خلاصه", "ملخص", "اشرح"].contains { prompt.contains($0) }
    }

    private static func asksForSuggestions(_ prompt: String) -> Bool {
        ["اقترح", "اقتراح", "وش اسوي", "الخطوه", "التالي", "تحسين"].contains { prompt.contains($0) }
    }

    private static func asksForSearch(_ prompt: String) -> Bool {
        ["ابحث", "دور", "فين", "وين", "اعرض"].contains { prompt.contains($0) }
    }

    private static func summaryResponse(for question: AskQuestion) -> AIAssistantResponse {
        let summary = DecisionSummaryService.makeSummary(for: question)
        let winner = question.winningOption?.title ?? "لا يوجد متصدر بعد"
        let reasons = question.comments.filter { $0.optionID != nil }
        let topReasons = Array(question.repeatedPros.prefix(3)).joined(separator: "، ")
        let action = summary.clarity == .insufficientData || summary.clarity == .close
            ? "الخطوة الأنسب: شارك المقارنة واطلب أسبابًا أكثر قبل الحسم."
            : "الخطوة الأنسب: راجع أسباب المعارضين للمتصدر قبل القرار النهائي."

        let answer = """
        \(systemDisclosure)

        \(question.title)

        المتصدر: \(winner)
        المشاركون: \(question.totalVotes)
        حالة القرار: \(summary.clarity.arabicTitle)
        الثقة: \(question.decisionConfidence)%
        الأسباب المكتوبة: \(reasons.count)
        أبرز الإشارات: \(topReasons.isEmpty ? "لا توجد أسباب كافية بعد" : topReasons)

        \(action)
        """

        return AIAssistantResponse(
            answer: answer,
            sources: [question.title],
            matchedQuestionIDs: [question.id]
        )
    }

    private static func searchResponse(
        prompt: String,
        matchedQuestions: [AskQuestion],
        matchedItems: [KnowledgeItem]
    ) -> AIAssistantResponse {
        var lines: [String] = [systemDisclosure, ""]
        var sources: [String] = []
        var ids: [UUID] = []

        if !matchedQuestions.isEmpty {
            lines.append("أقرب المقارنات:")
            for question in matchedQuestions.prefix(4) {
                let summary = DecisionSummaryService.makeSummary(for: question)
                lines.append("- \(question.title): \(question.totalVotes) صوت، الحالة \(summary.clarity.arabicTitle).")
                sources.append(question.title)
                ids.append(question.id)
            }
        }

        if !matchedItems.isEmpty {
            lines.append("")
            lines.append("من المكتبة:")
            for item in matchedItems {
                lines.append("- \(item.name): \(item.summary)")
                sources.append(item.name)
            }
        }

        if sources.isEmpty {
            lines.append("ما وجدت نتيجة واضحة لـ«\(prompt)». جرّب كلمة أبسط أو اسم خيار محدد.")
        }

        return AIAssistantResponse(answer: lines.joined(separator: "\n"), sources: sources, matchedQuestionIDs: ids)
    }

    private static func suggestionResponse(
        questions: [AskQuestion],
        knowledgeItems: [KnowledgeItem]
    ) -> AIAssistantResponse {
        let closeQuestions = questions.filter {
            let summary = DecisionSummaryService.makeSummary(for: $0)
            return summary.clarity == .close || summary.clarity == .insufficientData
        }
        let lowReasonQuestions = questions.filter { question in
            let reasonCount = question.comments.filter { $0.optionID != nil }.count
            return question.totalVotes > 0 && reasonCount < max(2, question.totalVotes / 5)
        }
        let sourceQuestion = closeQuestions.first ?? lowReasonQuestions.first ?? questions.first

        var answer = """
        \(systemDisclosure)

        اقتراحات عملية:
        - فعّل سبب التصويت في المقارنات المهمة حتى لا تعتمد على النسبة فقط.
        - ركّز على المقارنات غير الحاسمة واطلب من المشاركين ذكر التجربة والسعر والجودة.
        - استخدم مكتبة المعرفة لإنشاء مقارنة من عناصر جاهزة بدل كتابة كل شيء يدويًا.
        """

        if let sourceQuestion {
            answer += "\n\nأولوية الآن: «\(sourceQuestion.title)» لأنها تحتاج بيانات أو أسباب أكثر."
        }
        if let item = knowledgeItems.first {
            answer += "\n\nاقتراح إنشاء: جرّب مقارنة حول «\(item.name)» من المكتبة."
        }

        return AIAssistantResponse(
            answer: answer,
            sources: [sourceQuestion?.title, knowledgeItems.first?.name].compactMap { $0 },
            matchedQuestionIDs: sourceQuestion.map { [$0.id] } ?? []
        )
    }
}

@MainActor
@Observable
final class AIAssistantViewModel {
    var input = ""
    var messages: [AIAssistantMessage] = [
        AIAssistantMessage(
            role: .assistant,
            text: "أنا مساعد قرار داخل «وش الرأي». أقدر ألخص المقارنات، أبحث طبيعيًا، وأقترح الخطوة التالية اعتمادًا على بيانات التطبيق المتاحة."
        )
    ]
    var isLoading = false
    var errorMessage: String?

    private let questions: [AskQuestion]
    private let knowledgeItems: [KnowledgeItem]
    private let backendClient: WeshAlrayAPIClient?

    init(questions: [AskQuestion], knowledgeItems: [KnowledgeItem], backendClient: WeshAlrayAPIClient? = nil) {
        self.questions = questions
        self.knowledgeItems = knowledgeItems
        self.backendClient = backendClient
    }

    var suggestions: [AIAssistantSuggestion] {
        AIDecisionAssistantEngine.defaultSuggestions(questions: questions)
    }

    func send(_ prompt: String? = nil) {
        let text = (prompt ?? input).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            errorMessage = "اكتب سؤالك أولًا."
            return
        }

        input = ""
        errorMessage = nil
        isLoading = true
        messages.append(AIAssistantMessage(role: .user, text: text))

        Task {
            let response: AIAssistantResponse
            if let backendClient {
                do {
                    response = try await backendClient.aiChat(prompt: text)
                } catch {
                    response = AIDecisionAssistantEngine.answer(
                        prompt: text,
                        questions: questions,
                        knowledgeItems: knowledgeItems
                    )
                    errorMessage = "تعذر الوصول للمساعد عبر Backend، عرضنا إجابة محلية من بيانات الجهاز."
                }
            } else {
                try? await Task.sleep(for: .milliseconds(180))
                response = AIDecisionAssistantEngine.answer(
                    prompt: text,
                    questions: questions,
                    knowledgeItems: knowledgeItems
                )
            }
            messages.append(AIAssistantMessage(role: .assistant, text: response.answer, sources: response.sources))
            isLoading = false
        }
    }
}

struct AIDecisionAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AIAssistantViewModel

    init(questions: [AskQuestion], knowledgeItems: [KnowledgeItem], backendClient: WeshAlrayAPIClient? = nil) {
        _viewModel = State(
            initialValue: AIAssistantViewModel(
                questions: questions,
                knowledgeItems: knowledgeItems,
                backendClient: backendClient
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            assistantHeader
                            suggestionsSection
                            ForEach(viewModel.messages) { message in
                                AIAssistantBubble(message: message)
                            }
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                    Text("يفكر في بيانات التطبيق...")
                                        .font(.caption)
                                        .foregroundStyle(WeshTheme.secondaryText)
                                }
                                .weshSurface(padding: 12)
                            }
                            if let errorMessage = viewModel.errorMessage {
                                WeshStatusBanner(text: errorMessage, kind: .warning)
                            }
                        }
                        .padding(.horizontal, WeshTheme.horizontalPadding)
                        .padding(.vertical, 18)
                        .weshContentWidth()
                    }

                    composer
                }
            }
            .navigationTitle("المساعد الذكي")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var assistantHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                WeshIconTile(systemImage: "sparkles", color: WeshTheme.gold, size: 50)
                VStack(alignment: .leading, spacing: 4) {
                    Text("مساعد القرار")
                        .font(.title2.weight(.bold))
                    Text("يستخدم Backend آمن عند تفعيله، أو يرجع لبيانات الجهاز دون تخزين المحادثة.")
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.secondaryText)
                }
            }
            WeshStatusBanner(text: AIDecisionAssistantEngine.systemDisclosure, kind: .information)
        }
        .weshSurface(goldAccent: true)
    }

    private var suggestionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.suggestions) { suggestion in
                    Button {
                        viewModel.send(suggestion.prompt)
                    } label: {
                        Label(suggestion.title, systemImage: suggestion.systemImage)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 42)
                            .background(WeshTheme.elevatedSurface, in: Capsule())
                            .overlay { Capsule().stroke(WeshTheme.hairline) }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .accessibilityLabel("اقتراحات المساعد الذكي")
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("اسأل عن مقارنة، نتيجة، أو خطوة تالية", text: $viewModel.input, axis: .vertical)
                .lineLimit(1...4)
                .weshField()
                .submitLabel(.send)
                .onSubmit { viewModel.send() }
                .accessibilityIdentifier("ai-assistant-input")

            Button {
                viewModel.send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(WeshTheme.accent)
            }
            .disabled(viewModel.isLoading)
            .accessibilityLabel("إرسال السؤال للمساعد الذكي")
        }
        .padding(.horizontal, WeshTheme.horizontalPadding)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

private struct AIAssistantBubble: View {
    let message: AIAssistantMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.role == .assistant ? "المساعد" : "أنت")
                .font(.caption.weight(.bold))
                .foregroundStyle(message.role == .assistant ? WeshTheme.goldBright : WeshTheme.accentBright)

            Text(message.text)
                .font(.body)
                .foregroundStyle(WeshTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if !message.sources.isEmpty {
                FlowTags(values: Array(message.sources.prefix(4)), color: WeshTheme.secondaryAccent)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .assistant ? .leading : .trailing)
        .weshSurface(padding: 14, goldAccent: message.role == .assistant)
        .accessibilityElement(children: .combine)
    }
}
