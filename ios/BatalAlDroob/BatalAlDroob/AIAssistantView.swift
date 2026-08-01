import SwiftUI

struct AIAssistantView: View {
    @Bindable var viewModel: CatalogViewModel
    let exitAssistant: () -> Void
    @FocusState private var isInputFocused: Bool
    @State private var navigationPath: [Part] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            AIAssistantHeader(viewModel: viewModel)

                            if viewModel.aiMessages.isEmpty {
                                AIAssistantEmptyState(viewModel: viewModel)
                            }

                            ForEach(viewModel.aiMessages) { message in
                                AIAssistantBubble(message: message, viewModel: viewModel)
                                    .id(message.id)
                            }

                            if viewModel.isAIResponding {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text(viewModel.text(ar: "جاري تحليل سياق الكتالوج...", en: "Analyzing catalog context..."))
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .premiumPanel()
                                .accessibilityIdentifier("assistant.loading")
                            }

                            if let error = viewModel.aiErrorMessage {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label(error, systemImage: "exclamationmark.triangle")
                                        .font(.callout)
                                        .foregroundStyle(.orange)
                                    Button {
                                        Task { await viewModel.retryLastAssistantQuestion() }
                                    } label: {
                                        Label(viewModel.text(ar: "إعادة المحاولة", en: "Retry"), systemImage: "arrow.clockwise")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.batalSecondary)
                                    .disabled(viewModel.isAIResponding)
                                }
                                .padding(14)
                                .premiumPanel()
                                .accessibilityIdentifier("assistant.error")
                            }

                            if !viewModel.aiSuggestions.isEmpty {
                                AIAssistantSuggestions(viewModel: viewModel) { part in
                                    navigationPath.append(part)
                                }
                            }
                        }
                        .padding(BatalDesign.screenPadding)
                    }
                    .onChange(of: viewModel.aiMessages.count) { _, _ in
                        guard let lastID = viewModel.aiMessages.last?.id else { return }
                        withAnimation(AppTheme.animation) {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }

                AIAssistantComposer(viewModel: viewModel, isInputFocused: $isInputFocused)
            }
            .background(BatalDesign.canvas)
            .navigationTitle(viewModel.text(ar: "مساعد بطل الدروب", en: "Batal Assistant"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        AppHaptics.lightImpact()
                        isInputFocused = false
                        if navigationPath.isEmpty {
                            exitAssistant()
                        } else {
                            navigationPath.removeLast()
                        }
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.headline.weight(.bold))
                            .frame(width: 42, height: 42)
                            .background(BatalDesign.surface, in: Circle())
                            .overlay(Circle().stroke(BatalDesign.border))
                    }
                    .accessibilityIdentifier("assistant.back")
                    .accessibilityLabel(viewModel.text(ar: "رجوع للرئيسية", en: "Back to Home"))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    LanguageMenu(viewModel: viewModel)
                }
            }
            .navigationDestination(for: Part.self) { part in
                PartDetailView(part: part, viewModel: viewModel)
            }
        }
    }
}

private struct AIAssistantHeader: View {
    @Bindable var viewModel: CatalogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 42, height: 42)
                    .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.text(ar: "اسأل عن القطع والتوافق", en: "Ask about parts and fitment"))
                        .font(.headline)
                    Text(viewModel.text(
                        ar: "يستخدم نتائج الكتالوج الحالية وملف سيارتك بدون إرسال VIN أو أرقام مغلقة.",
                        en: "Uses current catalog results and your vehicle profile without sending VIN or locked numbers."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Label(
                viewModel.isRemoteAIConfigured
                    ? viewModel.text(ar: "AI متصل بالخادم الآمن", en: "AI connected through secure backend")
                    : viewModel.text(ar: "وضع محلي آمن", en: "Safe local mode"),
                systemImage: viewModel.isRemoteAIConfigured ? "lock.shield" : "iphone"
            )
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.tint.opacity(0.12), in: Capsule())
            .accessibilityIdentifier("assistant.mode")
        }
        .padding(14)
        .premiumPanel()
    }
}

private struct AIAssistantEmptyState: View {
    @Bindable var viewModel: CatalogViewModel

    private var prompts: [String] {
        [
            viewModel.text(ar: "ما أقرب قطعة لبحثي الحالي؟", en: "What is the closest part for my current search?"),
            viewModel.text(ar: "هل هذه القطعة تناسب سيارتي؟", en: "Does this part fit my vehicle?"),
            viewModel.text(ar: "ما الخطوة التالية قبل طلب القطعة؟", en: "What should I do before requesting this part?")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.text(ar: "اقتراحات سريعة", en: "Quick prompts"))
                .font(.headline)
            ForEach(prompts, id: \.self) { prompt in
                Button {
                    Task { await viewModel.askAssistant(prompt) }
                } label: {
                    HStack {
                        Text(prompt)
                            .font(.callout)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .imageScale(.small)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isAIResponding)
                .accessibilityIdentifier("assistant.prompt")
            }
        }
        .padding(14)
        .premiumPanel()
    }
}

private struct AIAssistantBubble: View {
    let message: AIAssistantMessage
    @Bindable var viewModel: CatalogViewModel

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 32) }
            VStack(alignment: .leading, spacing: 6) {
                if !isUser {
                    Label(
                        message.generatedByAI
                            ? viewModel.text(ar: "رد مولد بالذكاء الاصطناعي", en: "AI-generated answer")
                            : viewModel.text(ar: "رد محلي", en: "Local answer"),
                        systemImage: message.generatedByAI ? "sparkles" : "iphone"
                    )
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                }
                Text(message.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                isUser ? BatalDesign.brand.opacity(0.16) : BatalDesign.surface,
                in: RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BatalDesign.cardRadius, style: .continuous)
                    .stroke(BatalDesign.border)
            )
            .accessibilityIdentifier(isUser ? "assistant.message.user" : "assistant.message.ai")
            if !isUser { Spacer(minLength: 32) }
        }
    }
}

private struct AIAssistantSuggestions: View {
    @Bindable var viewModel: CatalogViewModel
    let openPart: (Part) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.text(ar: "خطوات مقترحة", en: "Suggested next steps"))
                .font(.headline)
            ForEach(viewModel.aiSuggestions) { suggestion in
                Button {
                    AppHaptics.lightImpact()
                    perform(suggestion)
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.title)
                                .font(.callout.bold())
                            Text(suggestion.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: icon(for: suggestion.id))
                            .font(.headline)
                            .foregroundStyle(BatalDesign.brand)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("assistant.suggestion.\(suggestion.id)")
            }
        }
        .padding(14)
        .premiumPanel()
    }

    private func icon(for id: String) -> String {
        switch id {
        case "review-top-result":
            "arrow.up.forward.square"
        case "prepare-request":
            "cart.badge.plus"
        case "complete-vehicle":
            "car"
        default:
            "arrow.up.left"
        }
    }

    private func perform(_ suggestion: AISuggestion) {
        switch suggestion.id {
        case "review-top-result":
            if let part = viewModel.assistantTopResult {
                openPart(part)
            } else {
                viewModel.aiErrorMessage = viewModel.text(
                    ar: "لا توجد نتيجة حالية لفتحها. ابدأ ببحث في الكتالوج أولًا.",
                    en: "There is no current result to open. Start with a catalog search first."
                )
            }
        case "prepare-request":
            viewModel.prepareAssistantPartRequest()
        case "complete-vehicle":
            viewModel.explainVehicleProfileCompletion()
        default:
            viewModel.aiQuestion = suggestion.title
        }
    }
}

private struct AIAssistantComposer: View {
    @Bindable var viewModel: CatalogViewModel
    var isInputFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(
                viewModel.text(ar: "اسأل عن رقم قطعة أو توافق أو طلب...", en: "Ask about a part, fitment, or request..."),
                text: $viewModel.aiQuestion,
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFieldStyle(.roundedBorder)
            .focused(isInputFocused)
            .accessibilityIdentifier("assistant.input")

            Button {
                Task { await viewModel.askAssistant() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.batalPrimary)
            .disabled(viewModel.isAIResponding || viewModel.aiQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel(viewModel.text(ar: "إرسال السؤال", en: "Send question"))
            .accessibilityIdentifier("assistant.send")
        }
        .padding(.horizontal, BatalDesign.screenPadding)
        .padding(.vertical, 12)
        .background(.bar)
    }
}
