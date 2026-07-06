import SwiftUI

struct ContentView: View {
    @State private var selectedCategory: AskCategory = .all
    @State private var searchText = ""
    @State private var questions = AskDemoStore.questions
    @State private var selectedQuestionID: AskQuestion.ID? = AskDemoStore.questions.first?.id
    @State private var showingComposer = false

    private var filteredQuestions: [AskQuestion] {
        questions
            .filter { question in
                selectedCategory == .all || question.category == selectedCategory
            }
            .filter { question in
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return true }
                return ([question.title, question.details, question.author] + question.options.map(\.title))
                    .joined(separator: " ")
                    .localizedCaseInsensitiveContains(query)
            }
    }

    private var selectedQuestion: AskQuestion? {
        if let selectedQuestionID,
           let question = questions.first(where: { $0.id == selectedQuestionID }) {
            return question
        }
        return filteredQuestions.first
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let selectedQuestion {
                QuestionDetail(
                    question: selectedQuestion,
                    voteAction: vote,
                    commentAction: addComment
                )
            } else {
                ContentUnavailableView(
                    "لا توجد أسئلة",
                    systemImage: "questionmark.bubble",
                    description: Text("اكتب سؤال مقارنة جديد أو غيّر التصفية.")
                )
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showingComposer) {
            NewQuestionView { question in
                questions.insert(question, at: 0)
                selectedQuestionID = question.id
            }
        }
    }

    private var sidebar: some View {
        List {
            Section {
                heroCard
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section("المجالات") {
                Picker("المجال", selection: $selectedCategory) {
                    ForEach(AskCategory.allCases) { category in
                        Label(category.title, systemImage: category.systemImage).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("أمثلة مقارنة") {
                ForEach(filteredQuestions) { question in
                    Button {
                        selectedQuestionID = question.id
                    } label: {
                        QuestionRow(
                            question: question,
                            isSelected: selectedQuestionID == question.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("اسأل")
        .searchable(text: $searchText, prompt: "ابحث عن منتج أو سؤال")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingComposer = true
                } label: {
                    Label("سؤال جديد", systemImage: "plus.bubble")
                }
            }
        }
        .onChange(of: selectedCategory) {
            selectedQuestionID = filteredQuestions.first?.id
        }
        .onChange(of: searchText) {
            guard let selectedQuestionID,
                  filteredQuestions.contains(where: { $0.id == selectedQuestionID }) else {
                self.selectedQuestionID = filteredQuestions.first?.id
                return
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "person.3.sequence")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.teal, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text("اسأل الناس")
                        .font(.title2.weight(.bold))
                    Text("قارن بين خيارين أو أكثر، وابدأ التصويت من الصفر.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                MetricPill(value: "\(questions.count)", label: "سؤال")
                MetricPill(value: "\(questions.reduce(0) { $0 + $1.totalVotes })", label: "تصويت")
                MetricPill(value: "2-10", label: "خيارات")
            }
        }
        .padding()
        .background(.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private func vote(questionID: AskQuestion.ID, optionID: PollOption.ID) {
        guard let questionIndex = questions.firstIndex(where: { $0.id == questionID }),
              let optionIndex = questions[questionIndex].options.firstIndex(where: { $0.id == optionID }) else {
            return
        }

        questions[questionIndex].options[optionIndex].votes += 1
    }

    private func addComment(questionID: AskQuestion.ID, text: String) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty,
              let questionIndex = questions.firstIndex(where: { $0.id == questionID }) else {
            return
        }

        questions[questionIndex].comments.insert(
            AskComment(author: "أنت", text: cleanText, likes: 0),
            at: 0
        )
    }
}

struct QuestionRow: View {
    let question: AskQuestion
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(question.category.title, systemImage: question.category.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.teal)
                Spacer()
                Text(question.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(question.title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(summaryText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label("\(question.options.count) خيارات", systemImage: "list.bullet.rectangle")
                Spacer()
                Label("\(question.totalVotes) تصويت", systemImage: "chart.bar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 5)
        .background(isSelected ? Color.teal.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
    }

    private var summaryText: String {
        question.options.map(\.title).prefix(3).joined(separator: " • ")
    }
}

struct QuestionDetail: View {
    let question: AskQuestion
    let voteAction: (AskQuestion.ID, PollOption.ID) -> Void
    let commentAction: (AskQuestion.ID, String) -> Void

    @State private var commentText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(question.category.title, systemImage: question.category.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.teal)
                    Text(question.title)
                        .font(.largeTitle.weight(.bold))
                    Text(question.details)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("بواسطة \(question.author) • \(question.timeAgo)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("التصويت")
                        .font(.title3.weight(.bold))
                    ForEach(question.options) { option in
                        VoteOptionRow(
                            option: option,
                            totalVotes: question.totalVotes,
                            isWinning: option.id == question.winningOption?.id
                        ) {
                            voteAction(question.id, option.id)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("التعليقات")
                        .font(.title3.weight(.bold))
                    HStack(spacing: 8) {
                        TextField("اكتب رأيك باختصار", text: $commentText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            commentAction(question.id, commentText)
                            commentText = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if question.comments.isEmpty {
                        ContentUnavailableView(
                            "لا توجد تعليقات بعد",
                            systemImage: "text.bubble",
                            description: Text("كن أول من يضيف رأيه على هذه المقارنة.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        ForEach(question.comments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("نتيجة المقارنة")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VoteOptionRow: View {
    let option: PollOption
    let totalVotes: Int
    let isWinning: Bool
    let action: () -> Void

    private var percent: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.votes) / Double(totalVotes)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(option.title)
                        .font(.headline)
                    Spacer()
                    if isWinning {
                        Label("الأعلى", systemImage: "crown.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                    }
                    Text("\(Int(percent * 100))%")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.14))
                        Capsule()
                            .fill(isWinning ? Color.teal : Color.blue)
                            .frame(width: max(8, geometry.size.width * percent))
                    }
                }
                .frame(height: 9)

                Text("\(option.votes) تصويت")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct CommentRow: View {
    let comment: AskComment

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(comment.author)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Label("\(comment.likes)", systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(comment.text)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MetricPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.background, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct NewQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var details = ""
    @State private var category: AskCategory = .phones
    @State private var optionCount = 2
    @State private var optionTitles = Array(repeating: "", count: 10)

    let saveAction: (AskQuestion) -> Void

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && completedOptions.count >= 2
    }

    private var completedOptions: [String] {
        optionTitles
            .prefix(optionCount)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("السؤال") {
                    TextField("مثال: أشتري السيارة A أو B؟", text: $title, axis: .vertical)
                    TextField("تفاصيل تساعد الناس يصوتون", text: $details, axis: .vertical)
                    Picker("المجال", selection: $category) {
                        ForEach(AskCategory.allCases.filter { $0 != .all }) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                }

                Section("خيارات المقارنة") {
                    Stepper("عدد الخيارات: \(optionCount)", value: $optionCount, in: 2...10)
                    ForEach(0..<optionCount, id: \.self) { index in
                        TextField("الخيار \(index + 1)", text: $optionTitles[index])
                    }
                }
            }
            .navigationTitle("سؤال جديد")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("نشر") {
                        let question = AskQuestion(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            details: details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? "ساعد صاحب السؤال بالتصويت أو التعليق."
                                : details.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: category,
                            author: "أنت",
                            timeAgo: "الآن",
                            options: completedOptions.map { PollOption(title: $0, votes: 0) },
                            comments: []
                        )
                        saveAction(question)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
