import SwiftUI

struct NewQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: CreateComparisonViewModel
    @State private var currentStep = 0
    @State private var showingPreview = false
    @State private var showingCamera = false
    @State private var isPublishing = false
    @State private var publishedQuestion: AskQuestion?
    @StateObject private var cameraAssistant: CameraDecisionAssistant

    let authorName: String
    let saveAction: (AskQuestion) async -> AskQuestion?

    private let stepTitles = ["الأساس", "الخيارات", "النشر"]

    init(
        template: KnowledgeItem? = nil,
        initialTitle: String = "",
        persistence: WeshPersistenceStore? = nil,
        backendClient: WeshAlrayAPIClient? = nil,
        authorName: String,
        saveAction: @escaping (AskQuestion) async -> AskQuestion?
    ) {
        _viewModel = State(
            initialValue: CreateComparisonViewModel(
                template: template,
                initialTitle: initialTitle,
                persistence: persistence
            )
        )
        _cameraAssistant = StateObject(wrappedValue: CameraDecisionAssistant(backendClient: backendClient))
        self.authorName = authorName
        self.saveAction = saveAction
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if let publishedQuestion {
                    PublishedComparisonSuccess(
                        question: publishedQuestion,
                        close: { dismiss() }
                    )
                } else {
                    editor(viewModel: viewModel)
                }
            }
            .navigationTitle(publishedQuestion == nil ? "مقارنة جديدة" : "تم النشر")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if publishedQuestion == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("إلغاء") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            viewModel.saveDraft()
                        } label: {
                            Image(systemName: "tray.and.arrow.down")
                        }
                        .accessibilityLabel("حفظ كمسودة")
                    }
                }
            }
        }
        .onAppear { viewModel.restoreDraftIfNeeded() }
        .onDisappear { viewModel.saveDraftOnDismissIfNeeded() }
        .onChange(of: viewModel.currentDraft) { _, _ in
            viewModel.saveDraftSilently()
        }
        .sheet(isPresented: $showingPreview) {
            if let question = try? viewModel.makeQuestion(authorName: authorName) {
                CreateComparisonPreviewSheet(
                    question: question,
                    isPublishing: isPublishing,
                    publish: { publish(question) }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            WeshCameraCaptureView(
                onCapture: { image in
                    showingCamera = false
                    Task {
                        if let draft = await cameraAssistant.analyze(image) {
                            viewModel.applyCameraDecisionDraft(draft)
                        }
                    }
                },
                onCancel: { showingCamera = false }
            )
            .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: publishedQuestion?.id)
    }

    private func editor(viewModel: CreateComparisonViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                WeshStepIndicator(current: currentStep, titles: stepTitles)
                    .padding(.bottom, 2)

                Group {
                    switch currentStep {
                    case 0:
                        ComparisonBasicsStep(
                            viewModel: viewModel,
                            cameraAssistant: cameraAssistant,
                            openCamera: { showingCamera = true }
                        )
                    case 1:
                        ComparisonOptionsStep(viewModel: viewModel)
                    default:
                        ComparisonPublishingStep(viewModel: viewModel)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))

                if let validationMessage = viewModel.validationMessage {
                    WeshStatusBanner(text: validationMessage, kind: validationMessage.contains("حفظ") ? .success : .warning)
                }

                Text("حفظنا تعديلاتك تلقائيًا.")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 18)
            .weshContentWidth()
        }
        .background(AppBackground())
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                if currentStep == 2 {
                    Button(action: advance) {
                        Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                    }
                    .buttonStyle(WeshGoldButtonStyle())
                } else {
                    Button(action: advance) {
                        Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                    }
                    .buttonStyle(WeshPrimaryButtonStyle())
                }

                if currentStep > 0 {
                    Button {
                        withAnimation(stepAnimation) { currentStep -= 1 }
                        viewModel.validationMessage = nil
                    } label: {
                        Label("رجوع", systemImage: "chevron.forward")
                    }
                    .buttonStyle(WeshSecondaryButtonStyle())
                }
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private var primaryButtonTitle: String {
        currentStep == 2 ? "معاينة المقارنة" : "التالي"
    }

    private var primaryButtonIcon: String {
        currentStep == 2 ? "eye.fill" : "arrow.left"
    }

    private var stepAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.25)
    }

    private func advance() {
        let isValid: Bool
        switch currentStep {
        case 0:
            isValid = viewModel.validateBasics()
        case 1:
            isValid = viewModel.validateOptions()
        default:
            isValid = viewModel.validateBasics() && viewModel.validateOptions()
        }

        guard isValid else { return }
        if currentStep < 2 {
            withAnimation(stepAnimation) { currentStep += 1 }
        } else {
            showingPreview = true
        }
    }

    private func publish(_ question: AskQuestion) {
        guard !isPublishing else { return }
        isPublishing = true
        Task {
            if let savedQuestion = await saveAction(question) {
                viewModel.markPublished()
                showingPreview = false
                publishedQuestion = savedQuestion
            } else {
                viewModel.validationMessage = "تعذر نشر المقارنة. احتفظنا بالمسودة لتتمكن من المحاولة مرة أخرى."
                showingPreview = false
            }
            isPublishing = false
        }
    }
}

private struct ComparisonBasicsStep: View {
    @Bindable var viewModel: CreateComparisonViewModel
    @ObservedObject var cameraAssistant: CameraDecisionAssistant
    let openCamera: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("وش حاب تقارن؟")
                    .font(.title.weight(.bold))
                Text("ابدأ بعنوان مباشر، وأضف تفاصيل تساعد الناس يفهمون احتياجك.")
                    .font(.subheadline)
                    .foregroundStyle(WeshTheme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 14) {
                WeshFieldLabel(title: "عنوان المقارنة", isRequired: true)
                TextField("مثال: آيفون أم سامسونج؟", text: $viewModel.title, axis: .vertical)
                    .lineLimit(2...4)
                    .weshField()
                    .accessibilityIdentifier("comparison-title-field")

                WeshFieldLabel(title: "الوصف", isRequired: false)
                TextField("وضّح احتياجك أو سبب المقارنة", text: $viewModel.details, axis: .vertical)
                    .lineLimit(3...6)
                    .weshField()

                WeshFieldLabel(title: "التصنيف", isRequired: true)
                Menu {
                    ForEach(AskCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                        Button {
                            viewModel.category = category
                        } label: {
                            Label(category.title, systemImage: category.systemImage)
                        }
                    }
                } label: {
                    HStack {
                        Label(viewModel.category.title, systemImage: viewModel.category.systemImage)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(WeshTheme.primaryText)
                    .weshField()
                }
            }
            .weshSurface()

            CameraDecisionAssistantCard(
                isAnalyzing: cameraAssistant.isAnalyzing,
                errorMessage: cameraAssistant.errorMessage,
                usedBackend: cameraAssistant.usedBackend,
                lastDraft: viewModel.lastCameraDraft,
                openCamera: openCamera
            )

            VStack(alignment: .leading, spacing: 12) {
                WeshSectionHeader("قوالب جاهزة", subtitle: "اختر مثالًا وعدّله بما يناسب قرارك")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(ComparisonTemplateLibrary.quickPrompts, id: \.self) { prompt in
                            Button(prompt) {
                                viewModel.applyQuickPrompt(prompt)
                            }
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .padding(.horizontal, 13)
                            .frame(minHeight: 42)
                            .background(WeshTheme.accent.opacity(0.11), in: Capsule())
                            .overlay { Capsule().stroke(WeshTheme.accent.opacity(0.2)) }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .weshSurface()
        }
    }
}

private struct ComparisonOptionsStep: View {
    @Bindable var viewModel: CreateComparisonViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("أضف الخيارات")
                    .font(.title.weight(.bold))
                Text("يمكنك إضافة من خيارين إلى عشرة خيارات وترتيبها كما تريد.")
                    .font(.subheadline)
                    .foregroundStyle(WeshTheme.secondaryText)
            }

            ForEach(0..<viewModel.optionCount, id: \.self) { index in
                OptionEditorCard(
                    index: index,
                    title: $viewModel.optionTitles[index],
                    canDelete: viewModel.optionCount > 2,
                    canMoveUp: index > 0,
                    canMoveDown: index < viewModel.optionCount - 1,
                    delete: { viewModel.removeOption(at: index) },
                    moveUp: { viewModel.moveOption(at: index, offset: -1) },
                    moveDown: { viewModel.moveOption(at: index, offset: 1) }
                )
            }

            if viewModel.optionCount < 10 {
                Button {
                    viewModel.addOption()
                } label: {
                    Label("إضافة خيار آخر", systemImage: "plus.circle.fill")
                }
                .buttonStyle(WeshSecondaryButtonStyle())
            }
        }
    }
}

private struct OptionEditorCard: View {
    let index: Int
    @Binding var title: String
    let canDelete: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let delete: () -> Void
    let moveUp: () -> Void
    let moveDown: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("الخيار \(index + 1)")
                    .font(.headline)
                Spacer()
                HStack(spacing: 3) {
                    Button(action: moveUp) { Image(systemName: "arrow.up") }
                        .disabled(!canMoveUp)
                        .accessibilityLabel("تحريك الخيار للأعلى")
                    Button(action: moveDown) { Image(systemName: "arrow.down") }
                        .disabled(!canMoveDown)
                        .accessibilityLabel("تحريك الخيار للأسفل")
                    Button(role: .destructive, action: delete) { Image(systemName: "trash") }
                        .disabled(!canDelete)
                        .accessibilityLabel("حذف الخيار")
                }
                .buttonStyle(.borderless)
                .frame(minHeight: 44)
            }
            TextField("اسم الخيار", text: $title)
                .weshField()
                .accessibilityIdentifier("comparison-option-\(index + 1)")
        }
        .weshSurface()
    }
}

private struct ComparisonPublishingStep: View {
    @Bindable var viewModel: CreateComparisonViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("إعدادات النشر")
                    .font(.title.weight(.bold))
                Text("تحكّم بطريقة ظهور المقارنة والمشاركة فيها.")
                    .font(.subheadline)
                    .foregroundStyle(WeshTheme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 14) {
                WeshFieldLabel(title: "طريقة النشر", isRequired: true)
                Picker("طريقة النشر", selection: $viewModel.isAnonymous) {
                    Text("باسمي").tag(false)
                    Text("بصورة مجهولة").tag(true)
                }
                .pickerStyle(.segmented)

                Divider().overlay(WeshTheme.hairline)

                Toggle(isOn: $viewModel.allowsVoteReasons) {
                    Label("السماح بأسباب التصويت", systemImage: "quote.bubble")
                }
                Toggle(isOn: $viewModel.allowsComments) {
                    Label("السماح بالتعليقات", systemImage: "text.bubble")
                }
                .tint(WeshTheme.accent)
            }
            .weshSurface()

            VStack(alignment: .leading, spacing: 12) {
                WeshFieldLabel(title: "خصوصية المقارنة", isRequired: true)
                ForEach(ComparisonVisibility.allCases) { visibility in
                    Button {
                        viewModel.visibility = visibility
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: visibility.systemImage)
                                .frame(width: 26)
                            Text(visibility.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: viewModel.visibility == visibility ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.visibility == visibility ? WeshTheme.accent : WeshTheme.secondaryText)
                        }
                        .foregroundStyle(WeshTheme.primaryText)
                        .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(viewModel.visibility == visibility ? .isSelected : [])
                }

                Divider().overlay(WeshTheme.hairline)

                Toggle("إخفاء النتائج حتى التصويت", isOn: $viewModel.hideResultsUntilVote)
                    .tint(WeshTheme.accent)
                Text("يقلل هذا الخيار تأثر المشاركين برأي الأغلبية قبل اختيارهم.")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
            }
            .weshSurface()

            VStack(alignment: .leading, spacing: 12) {
                WeshFieldLabel(title: "مدة التصويت", isRequired: true)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 9)], spacing: 9) {
                    ForEach(VoteDurationOption.allCases) { duration in
                        Button {
                            viewModel.voteDuration = duration
                        } label: {
                            HStack {
                                Text(duration.title)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                if viewModel.voteDuration == duration {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(viewModel.voteDuration == duration ? WeshTheme.accent : WeshTheme.primaryText)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 46)
                            .background(
                                viewModel.voteDuration == duration ? WeshTheme.accent.opacity(0.11) : WeshTheme.elevatedSurface,
                                in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: WeshTheme.compactRadius)
                                    .stroke(viewModel.voteDuration == duration ? WeshTheme.accent : WeshTheme.hairline)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(viewModel.voteDuration == duration ? .isSelected : [])
                    }
                }
            }
            .weshSurface()

            VStack(alignment: .leading, spacing: 10) {
                WeshFieldLabel(title: "الوسوم", isRequired: false)
                TextField("مثال: جوالات، كاميرا، بطارية", text: $viewModel.tagsText)
                    .weshField()
                Text("أضف وسومًا مفصولة بفواصل حتى يسهل الوصول إلى المقارنة.")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
            }
            .weshSurface()
        }
    }
}

private struct WeshFieldLabel: View {
    let title: String
    let isRequired: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .font(.subheadline.weight(.bold))
            if !isRequired {
                Text("اختياري")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
            }
        }
    }
}

private struct CreateComparisonPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let question: AskQuestion
    let isPublishing: Bool
    let publish: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WeshStatusBanner(
                        text: "وضع المعاينة — لن تظهر المقارنة للآخرين بعد",
                        kind: .warning
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        WeshPill(
                            question.category.title,
                            systemImage: question.category.systemImage,
                            color: WeshTheme.categoryColor(question.category)
                        )
                        Text(question.title)
                            .font(.title.weight(.bold))
                            .foregroundStyle(WeshTheme.primaryText)
                        Text(question.details)
                            .font(.body)
                            .foregroundStyle(WeshTheme.secondaryText)
                        Divider().overlay(WeshTheme.hairline)
                        ForEach(question.options) { option in
                            HStack(spacing: 12) {
                                Image(systemName: "circle")
                                    .foregroundStyle(WeshTheme.accent)
                                Text(option.title)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(14)
                            .background(WeshTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
                        }
                    }
                    .weshSurface(emphasized: true)

                    Button(action: publish) {
                        if isPublishing {
                            ProgressView()
                                .tint(.black)
                                .accessibilityLabel("جارٍ نشر المقارنة")
                        } else {
                            Label("نشر المقارنة", systemImage: "paperplane.fill")
                        }
                    }
                    .buttonStyle(WeshGoldButtonStyle())
                    .disabled(isPublishing)

                    Button("رجوع للتعديل") { dismiss() }
                        .buttonStyle(WeshSecondaryButtonStyle())
                        .disabled(isPublishing)
                }
                .padding(18)
                .weshContentWidth()
            }
            .background(AppBackground())
            .navigationTitle("معاينة المقارنة")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct PublishedComparisonSuccess: View {
    let question: AskQuestion
    let close: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(WeshTheme.accent.opacity(0.14))
                        .frame(width: 112, height: 112)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 62, weight: .bold))
                        .foregroundStyle(WeshTheme.accent)
                }
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("تم نشر المقارنة")
                        .font(.largeTitle.weight(.bold))
                    Text("أصبحت جاهزة للتصويت والمشاركة.")
                        .font(.body)
                        .foregroundStyle(WeshTheme.secondaryText)
                }

                VStack(alignment: .leading, spacing: 10) {
                    WeshPill(question.category.title, color: WeshTheme.categoryColor(question.category))
                    Text(question.title)
                        .font(.title3.weight(.bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .weshSurface(goldAccent: true)

                ShareLink(item: ComparisonShareService.shareText(for: question)) {
                    Label("مشاركة الرابط", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(WeshPrimaryButtonStyle())

                Button("عرض المقارنة", action: close)
                    .buttonStyle(WeshGoldButtonStyle())

                Button("العودة للرئيسية", action: close)
                    .buttonStyle(WeshSecondaryButtonStyle())
            }
            .padding(24)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(AppBackground())
        .accessibilityElement(children: .contain)
    }
}

struct CreateComparisonPreview: View {
    let title: String
    let category: AskCategory
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WeshPill(category.title, systemImage: category.systemImage, color: WeshTheme.categoryColor(category))
            Text(title)
                .font(.headline)
            ForEach(options.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { option in
                Label(option, systemImage: "circle")
                    .font(.subheadline)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
