import SwiftUI

struct NewQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateComparisonViewModel
    @State private var isPublishing = false

    let authorName: String
    let saveAction: (AskQuestion) async -> AskQuestion?

    init(
        template: KnowledgeItem? = nil,
        authorName: String,
        saveAction: @escaping (AskQuestion) async -> AskQuestion?
    ) {
        _viewModel = State(initialValue: CreateComparisonViewModel(template: template))
        self.authorName = authorName
        self.saveAction = saveAction
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        WeshIconTile(systemImage: "plus.bubble.fill", color: WeshTheme.accent, size: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ابنِ مقارنة واضحة")
                                .font(.headline)
                            Text("عنوان مختصر وخيارات محددة تعطي نتائج أفضل.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }

                Section("ابدأ بسرعة") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ComparisonTemplateLibrary.quickPrompts, id: \.self) { prompt in
                                Button {
                                    viewModel.applyQuickPrompt(prompt)
                                } label: {
                                    Text(prompt)
                                        .font(.caption.weight(.bold))
                                        .lineLimit(1)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.teal.opacity(0.12), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("السؤال") {
                    TextField("مثال: أشتري السيارة A أو B؟", text: $viewModel.title, axis: .vertical)
                    TextField("تفاصيل تساعد الناس يصوتون", text: $viewModel.details, axis: .vertical)
                    Picker("المجال", selection: $viewModel.category) {
                        ForEach(AskCategory.allCases.filter { $0 != .all }) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    TextField("وسوم اختيارية مفصولة بفواصل", text: $viewModel.tagsText)
                }

                Section("خيارات المقارنة") {
                    Stepper("عدد الخيارات: \(viewModel.optionCount)", value: $viewModel.optionCount, in: 2...10)
                    ForEach(0..<viewModel.optionCount, id: \.self) { index in
                        TextField("الخيار \(index + 1)", text: $viewModel.optionTitles[index])
                    }
                }

                Section("إعدادات المشاركة") {
                    Toggle("نشر السؤال باسم مجهول", isOn: $viewModel.isAnonymous)
                    Toggle("السماح بأسباب التصويت", isOn: $viewModel.allowsVoteReasons)
                    Toggle("السماح بالتعليقات", isOn: $viewModel.allowsComments)
                    Picker("مدة التصويت", selection: $viewModel.voteDuration) {
                        ForEach(VoteDurationOption.allCases) { duration in
                            Text(duration.title).tag(duration)
                        }
                    }
                }

                if let validationMessage = viewModel.validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                if viewModel.canSave {
                    Section("معاينة") {
                        CreateComparisonPreview(
                            title: viewModel.title,
                            category: viewModel.category,
                            options: Array(viewModel.optionTitles.prefix(viewModel.optionCount))
                        )
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("مقارنة جديدة")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.restoreDraftIfNeeded()
            }
            .onDisappear {
                viewModel.saveDraftOnDismissIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.saveDraft()
                    } label: {
                        Label("حفظ مسودة", systemImage: "doc.badge.plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: publish) {
                    if isPublishing {
                        ProgressView()
                            .tint(.white)
                            .accessibilityLabel("جارٍ نشر المقارنة")
                    } else {
                        Label("نشر المقارنة", systemImage: "paperplane.fill")
                    }
                }
                .buttonStyle(WeshPrimaryButtonStyle())
                .disabled(!viewModel.canSave || isPublishing)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
    }

    private func publish() {
        guard !isPublishing,
              let question = try? viewModel.makeQuestion(authorName: authorName) else {
            return
        }
        isPublishing = true
        Task {
            if await saveAction(question) != nil {
                viewModel.markPublished()
                dismiss()
            } else {
                viewModel.validationMessage = "تعذر نشر المقارنة. احتفظنا بالمسودة لتتمكن من المحاولة مرة أخرى."
            }
            isPublishing = false
        }
    }
}

struct CreateComparisonPreview: View {
    let title: String
    let category: AskCategory
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(category.title, systemImage: category.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(WeshTheme.accent)
            Text(title)
                .font(.headline)
            ForEach(options.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { option in
                Label(option, systemImage: "circle")
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
