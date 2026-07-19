import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit
import UserNotifications

struct QuestionDetail: View {
    let question: AskQuestion
    let relatedQuestions: [AskQuestion]
    let voteAction: (AskQuestion.ID, PollOption.ID) -> Void
    let voteWithReasonAction: (AskQuestion.ID, PollOption.ID, String, String?, Bool) -> Void
    let commentAction: (AskQuestion.ID, String) -> Void
    let isVoteSubmitting: Bool
    let isSaved: Bool
    let saveAction: (AskQuestion.ID) -> Void
    let openRelatedQuestion: (AskQuestion) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var selectedVoteOption: PollOption?
    @State private var voteReason = ""
    @State private var selectedReasonCategory: String?
    @State private var isVerifiedExperience = false
    @State private var decisionMode: DecisionMode = .quick
    @State private var commentFilter: CommentFilter = .all
    @State private var savedDecisionState: SavedDecisionState = .comparing
    @State private var showingQRCode = false
    @State private var showingReportSheet = false
    @State private var localMessage: String?
    @State private var actionFeedback = 0

    private var visibleComments: [AskComment] {
        switch commentFilter {
        case .all:
            return question.comments
        case .verified:
            return question.comments.filter { $0.trustBadge != nil }
        case .reasons:
            return question.comments.filter { $0.optionID != nil }
        }
    }

    private var shareText: String {
        ComparisonShareService.shareText(for: question)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(question.category.title, systemImage: question.category.systemImage)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WeshTheme.accent)
                        Spacer()
                        Text(question.timeAgo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(question.title)
                        .font(.title.weight(.bold))
                        .lineLimit(4)
                    Text(question.details)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Label(question.author, systemImage: "person.crop.circle")
                        Label("\(question.totalVotes)", systemImage: "chart.bar")
                        Label("\(question.comments.count)", systemImage: "text.bubble")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if question.totalVotes > 0 {
                    decisionAnalysisSection
                }

                votingSection

                if question.totalVotes == 0 {
                    decisionAnalysisSection
                }

                if let selectedVoteOption {
                    VoteReasonCard(
                        option: selectedVoteOption,
                        category: question.category,
                        reason: $voteReason,
                        selectedReasonCategory: $selectedReasonCategory,
                        isVerifiedExperience: $isVerifiedExperience,
                        submitWithReason: {
                            voteWithReasonAction(question.id, selectedVoteOption.id, voteReason, selectedReasonCategory, isVerifiedExperience)
                            actionFeedback += 1
                            self.selectedVoteOption = nil
                            voteReason = ""
                            selectedReasonCategory = nil
                            isVerifiedExperience = false
                        },
                        voteOnly: {
                            voteAction(question.id, selectedVoteOption.id)
                            actionFeedback += 1
                            self.selectedVoteOption = nil
                            voteReason = ""
                            selectedReasonCategory = nil
                            isVerifiedExperience = false
                        },
                        cancel: {
                            self.selectedVoteOption = nil
                            voteReason = ""
                            selectedReasonCategory = nil
                            isVerifiedExperience = false
                        }
                    )
                    .disabled(isVoteSubmitting)
                }

                SavedDecisionCard(selection: $savedDecisionState, shareText: shareText)

                DecisionActionCard(
                    question: question,
                    shareText: shareText,
                    showQRCode: { showingQRCode = true },
                    report: { showingReportSheet = true },
                    scheduleReminder: scheduleReminder
                )

                if let localMessage {
                    WeshStatusBanner(text: localMessage, kind: .success)
                }

                if !relatedQuestions.isEmpty {
                    SimilarQuestionsCard(questions: relatedQuestions, openQuestion: openRelatedQuestion)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        WeshSectionHeader(
                            "الأسباب والنقاش",
                            subtitle: "اقرأ التجارب أو أضف ملاحظة عامة",
                            systemImage: "quote.bubble"
                        )
                        Menu {
                            ForEach(CommentFilter.allCases) { filter in
                                Button(filter.title) {
                                    commentFilter = filter
                                }
                            }
                        } label: {
                            Label(commentFilter.title, systemImage: "line.3.horizontal.decrease.circle")
                                .font(.caption.weight(.bold))
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("تعليق عام على السؤال", text: $commentText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            commentAction(question.id, commentText)
                            commentText = ""
                            actionFeedback += 1
                        } label: {
                            Image(systemName: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if question.comments.isEmpty {
                        ContentUnavailableView(
                            "لا توجد أسباب بعد",
                            systemImage: "text.bubble",
                            description: Text("صوّت على خيار واكتب سبب اختيارك حتى يستفيد باقي الناس.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 150)
                    } else if visibleComments.isEmpty {
                        ContentUnavailableView(
                            "لا توجد نتائج لهذا الفلتر",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("غيّر الفلتر أو أضف سبب تصويت بتجربة موثقة.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 130)
                    } else {
                        ForEach(visibleComments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                }
            }
            .padding(16)
            .weshContentWidth()
        }
        .background(AppBackground())
        .navigationTitle("نتيجة المقارنة")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: actionFeedback)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("تم") {
                    dismiss()
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    saveAction(question.id)
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(isSaved ? "إلغاء الحفظ" : "حفظ المقارنة")

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("مشاركة المقارنة")

                Menu {
                    Button {
                        showingQRCode = true
                    } label: {
                        Label("QR", systemImage: "qrcode")
                    }
                    Button {
                        showingReportSheet = true
                    } label: {
                        Label("إبلاغ", systemImage: "exclamationmark.bubble")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("المزيد")
            }
        }
        .sheet(isPresented: $showingQRCode) {
            NavigationStack {
                QRCodeShareView(question: question)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .sheet(isPresented: $showingReportSheet) {
            NavigationStack {
                ReportContentView(contentID: question.id, contentType: .comparison) {
                    localMessage = "تم حفظ البلاغ محليًا. يتطلب إرساله للمراجعة Backend في النسخة الإنتاجية."
                    showingReportSheet = false
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    @ViewBuilder
    private var decisionAnalysisSection: some View {
        DecisionSummaryCard(question: question)

        Picker("نوع القرار", selection: $decisionMode) {
            ForEach(DecisionMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)

        if decisionMode == .deep {
            DecisionCriteriaCard(category: question.category)
            SpecificationComparisonCard(question: question)
        }
    }

    private var votingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader(
                "اختر الأنسب",
                subtitle: question.totalVotes == 0 ? "كن أول من يصوّت" : "النتائج الحالية تتحدث بعد كل تصويت",
                systemImage: "checkmark.circle"
            )
            if isVoteSubmitting {
                ProgressView("جارٍ إرسال التصويت...")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(question.options) { option in
                VoteOptionRow(
                    option: option,
                    totalVotes: question.totalVotes,
                    isWinning: option.id == question.winningOption?.id
                ) {
                    selectedVoteOption = option
                    voteReason = ""
                }
                .disabled(isVoteSubmitting)
            }
        }
    }

    private func scheduleReminder() {
        Task {
            do {
                try await LocalNotificationScheduler.scheduleDecisionReminder(for: question)
                await MainActor.run {
                    localMessage = "تم تفعيل تذكير محلي لهذه المقارنة."
                }
            } catch {
                await MainActor.run {
                    localMessage = error.localizedDescription
                }
            }
        }
    }
}


struct QuestionRow: View {
    let question: AskQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(question.category.title, systemImage: question.category.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WeshTheme.accent)
                Spacer()
                Text(question.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(question.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(question.options.map(\.title).prefix(4).joined(separator: " • "))
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
        .weshSurface()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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

                ProgressView(value: percent)
                    .tint(isWinning ? WeshTheme.accent : WeshTheme.secondaryAccent)

                Text("\(option.votes) تصويت")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .weshSurface()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityValue("\(Int(percent * 100)) بالمئة، \(option.votes) تصويت")
        .accessibilityHint("اضغط لاختيار هذا الخيار")
        .accessibilityAddTraits(isWinning ? .isSelected : [])
    }
}

struct DecisionSummaryCard: View {
    let question: AskQuestion
    private var summary: DecisionSummary {
        DecisionSummaryService.makeSummary(for: question)
    }

    private var confidencePercent: Int {
        guard summary.totalVotes > 0 else {
            return 0
        }

        return switch summary.confidenceLevel {
        case .low: min(49, question.decisionConfidence)
        case .medium: min(74, max(50, question.decisionConfidence))
        case .high: max(75, question.decisionConfidence)
        }
    }

    private var clarityColor: Color {
        switch summary.clarity {
        case .insufficientData: .secondary
        case .close: .orange
        case .leaning: .teal
        case .decisive: .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                WeshIconTile(systemImage: "checkmark.bubble.fill", color: WeshTheme.accent, size: 44)

                VStack(alignment: .leading, spacing: 6) {
                    Text("خلاصة القرار")
                        .font(.headline)
                    Text(summary.recommendationText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                DecisionMetric(title: "الثقة", value: "\(confidencePercent)%", icon: "shield.checkered", color: .teal)
                DecisionMetric(title: "المتصدر", value: "\(summary.leadingVotePercentage)%", icon: "chart.pie.fill", color: .blue)
                DecisionMetric(title: "الفارق", value: "\(Int(summary.voteGapPercentage.rounded()))%", icon: "arrow.left.and.right", color: .indigo)
            }

            Label(summary.clarity.arabicTitle, systemImage: summary.clarity.systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(clarityColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(clarityColor.opacity(0.12), in: Capsule())

            if !summary.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("أبرز ما تقوله النتيجة")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    ForEach(summary.highlights) { highlight in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(highlight.title)
                                .font(.subheadline.weight(.bold))
                            Text(highlight.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let warning = summary.warningText {
                WeshStatusBanner(text: warning, kind: .warning)
            }

            if !summary.optionInsights.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Label("تحليل الأسباب حسب الخيار", systemImage: "list.bullet.clipboard")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.accent)

                    ForEach(summary.optionInsights) { insight in
                        OptionInsightView(insight: insight)
                    }
                }
            }
        }
        .weshSurface(emphasized: true)
    }
}

struct OptionInsightView: View {
    let insight: OptionDecisionInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.optionTitle)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(insight.votePercentage)%")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
            }

            if !insight.topReasons.isEmpty {
                FlowTags(values: Array(insight.topReasons.prefix(3)), color: .teal)
            }

            HStack(alignment: .top, spacing: 8) {
                if !insight.positives.isEmpty {
                    InsightList(title: "إيجابيات", values: insight.positives, color: .green, icon: "plus.circle.fill")
                }
                if !insight.negatives.isEmpty {
                    InsightList(title: "سلبيات", values: insight.negatives, color: .orange, icon: "minus.circle.fill")
                }
            }

            if insight.evidenceCount == 0 {
                Text("لا توجد أسباب مكتوبة كافية لهذا الخيار بعد.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct InsightList: View {
    let title: String
    let values: [String]
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
            ForEach(values.prefix(3), id: \.self) { value in
                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DecisionMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)، \(value)")
    }
}

struct DecisionCriteriaCard: View {
    let category: AskCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("معايير التقييم لهذا التصنيف", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
                Text(category.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.teal)
            }

            FlowTags(values: DecisionFeatureCatalog.criteria(for: category), color: .teal)

            Text("استخدم هذه المعايير عند قراءة الأصوات: قد يكون الخيار الأعلى تصويتًا ليس الأفضل لك إذا كانت أولوياتك مختلفة.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .weshSurface()
    }
}
struct SpecificationComparisonCard: View {
    let question: AskQuestion

    private var rows: [ComparisonSpecificationRow] {
        ComparisonSpecificationService.rows(for: question)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("جدول المواصفات", systemImage: "tablecells")
                    .font(.headline)
                Spacer()
                Text("\(question.options.count) خيارات")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.teal)
            }

            Text("تقييم إرشادي يجمع بين التصويت والأسباب المكتوبة حسب معايير هذا التصنيف. لا يغني عن قراءة التفاصيل.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("المعيار")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 90, alignment: .leading)
                        ForEach(question.options) { option in
                            Text(option.title)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .frame(width: 105, alignment: .leading)
                        }
                    }

                    ForEach(rows) { row in
                        GridRow {
                            Text(row.criterion)
                                .font(.caption.weight(.bold))
                                .frame(minWidth: 90, alignment: .leading)
                            ForEach(question.options) { option in
                                SpecValueLabel(
                                    value: row.values[option.id] ?? "غير واضح",
                                    isLeading: row.leadingOptionID == option.id
                                )
                                .frame(width: 105, alignment: .leading)
                            }
                        }
                    }
                }
                .padding(10)
                .background(WeshTheme.canvas, in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
            }
        }
        .weshSurface()
    }
}

struct SpecValueLabel: View {
    let value: String
    let isLeading: Bool

    var body: some View {
        Label(value, systemImage: isLeading ? "checkmark.seal.fill" : "circle")
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(isLeading ? .teal : .secondary)
    }
}

struct SavedDecisionCard: View {
    @Binding var selection: SavedDecisionState
    let shareText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("احفظ قرارك", systemImage: "bookmark.fill")
                    .font(.headline)
                Spacer()
                ShareLink(item: shareText) {
                    Label("مشاركة", systemImage: "square.and.arrow.up")
                        .font(.caption.weight(.bold))
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                ForEach(SavedDecisionState.allCases) { state in
                    Button {
                        selection = state
                    } label: {
                        Label(state.title, systemImage: state.systemImage)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selection == state ? .white : .primary)
                    .background(
                        selection == state ? WeshTheme.accent : WeshTheme.canvas,
                        in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius)
                    )
                }
            }
        }
        .weshSurface()
    }
}

enum LocalNotificationScheduler {
    static func scheduleDecisionReminder(for question: AskQuestion) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else {
            throw AppError.forbidden
        }

        let content = UNMutableNotificationContent()
        content.title = "وش الرأي"
        content.body = "راجع نتيجة: \(question.title)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(
            identifier: "wash-alray-\(question.id.uuidString)",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }
}

struct DecisionActionCard: View {
    let question: AskQuestion
    let shareText: String
    let showQRCode: () -> Void
    let report: () -> Void
    let scheduleReminder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("أدوات القرار", systemImage: "square.grid.2x2")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], spacing: 10) {
                ShareLink(item: shareText) {
                    DecisionToolButton(title: "مشاركة الرابط", icon: "square.and.arrow.up", color: .teal)
                }
                ShareLink(item: ComparisonShareService.csvText(for: question)) {
                    DecisionToolButton(title: "تصدير CSV", icon: "tablecells", color: .indigo)
                }
                Button(action: showQRCode) {
                    DecisionToolButton(title: "QR Code", icon: "qrcode", color: .orange)
                }
                .buttonStyle(.plain)
                Button(action: scheduleReminder) {
                    DecisionToolButton(title: "تذكير محلي", icon: "bell.badge", color: .green)
                }
                .buttonStyle(.plain)
                Button(action: report) {
                    DecisionToolButton(title: "إبلاغ", icon: "exclamationmark.bubble", color: .red)
                }
                .buttonStyle(.plain)
            }
        }
        .weshSurface()
    }
}

struct DecisionToolButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
    }
}

struct QRCodeShareView: View {
    let question: AskQuestion
    @Environment(\.dismiss) private var dismiss

    private var link: String {
        ComparisonShareService.deepLink(for: question).absoluteString
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(question.title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)

            if let image = QRCodeGenerator.image(from: link) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260)
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
                    .accessibilityLabel("رمز QR لرابط المقارنة")
            }

            Text(link)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)

            ShareLink(item: link) {
                Label("مشاركة الرابط", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(WeshPrimaryButtonStyle())

            Text("الرابط العميق يفتح المقارنة داخل التطبيق عندما تكون المقارنة موجودة على نفس الجهاز. المشاركة العامة بين المستخدمين تحتاج Backend وروابط Universal Links.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(AppBackground())
        .navigationTitle("QR المقارنة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("إغلاق") {
                    dismiss()
                }
            }
        }
    }
}

enum QRCodeGenerator {
    static func image(from text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct ReportContentView: View {
    let contentID: UUID
    let contentType: ReportableContentType
    let didSubmit: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason: ReportReason = .misleading
    @State private var details = ""

    var body: some View {
        Form {
            Section("سبب البلاغ") {
                Picker("السبب", selection: $reason) {
                    ForEach(ReportReason.allCases) { reason in
                        Text(reason.arabicTitle).tag(reason)
                    }
                }
            }

            Section("تفاصيل اختيارية") {
                TextField("اكتب ما يساعد فريق المراجعة", text: $details, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Text("البلاغات تحفظ محليًا الآن. إرسالها لفريق إشراف فعلي يتطلب Backend مخصصًا.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("إبلاغ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("إلغاء") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("حفظ البلاغ") {
                    LocalReportStore.shared.save(
                        ContentReport(
                            contentID: contentID,
                            contentType: contentType,
                            reason: reason,
                            details: details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : details
                        )
                    )
                    didSubmit()
                }
            }
        }
    }
}

struct SimilarQuestionsCard: View {
    let questions: [AskQuestion]
    let openQuestion: (AskQuestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("مقارنات مشابهة", systemImage: "rectangle.stack.badge.plus")
                    .font(.headline)
                Spacer()
                Text("تجنب التكرار")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            ForEach(questions) { question in
                Button {
                    openQuestion(question)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: question.category.systemImage)
                            .foregroundStyle(WeshTheme.accent)
                            .frame(width: 30, height: 30)
                            .background(WeshTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(question.title)
                                .font(.subheadline.weight(.bold))
                                .lineLimit(2)
                            Text("\(question.totalVotes) تصويت • \(question.comments.count) سبب أو تعليق")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.backward")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
        .weshSurface()
    }
}

struct VoteReasonCard: View {
    let option: PollOption
    let category: AskCategory
    @Binding var reason: String
    @Binding var selectedReasonCategory: String?
    @Binding var isVerifiedExperience: Bool
    let submitWithReason: () -> Void
    let voteOnly: () -> Void
    let cancel: () -> Void

    private var canSubmitReason: Bool {
        let cleanReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return !cleanReason.isEmpty && cleanReason.count <= 300
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "quote.bubble.fill")
                    .foregroundStyle(.teal)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("لماذا اخترت \(option.title)؟")
                        .font(.headline)
                    Text("أضف سببك حتى يفهم الناس منطق التصويت، أو صوّت بدون سبب.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("أسباب جاهزة")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                FlowTags(
                    values: DecisionFeatureCatalog.voteReasons(for: category),
                    color: .teal,
                    action: { value in
                        selectedReasonCategory = value
                        reason = value
                    }
                )
            }

            TextField("مثال: اخترته لأن سعره أفضل وضمانه أوضح", text: $reason, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)
                .onChange(of: reason) { _, newValue in
                    if newValue.count > 300 {
                        reason = String(newValue.prefix(300))
                    }
                }

            Text("\(reason.count)/300")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Toggle(isOn: $isVerifiedExperience) {
                Label("جرّبت هذا الخيار فعليًا", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .toggleStyle(.switch)

            VStack(spacing: 10) {
                Button("صوّت مع السبب", action: submitWithReason)
                    .buttonStyle(WeshPrimaryButtonStyle())
                    .disabled(!canSubmitReason)

                HStack(spacing: 10) {
                    Button("تصويت بدون سبب", action: voteOnly)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                    Button("إلغاء", action: cancel)
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.subheadline.weight(.semibold))
        }
        .weshSurface(emphasized: true)
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
            if let optionTitle = comment.optionTitle {
                HStack(spacing: 6) {
                    Label("صوّت لـ \(optionTitle)", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.teal)
                    if let trustBadge = comment.trustBadge {
                        Label(trustBadge, systemImage: "shield.fill")
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.teal.opacity(0.10), in: Capsule())
            }
            if let reasonCategory = comment.reasonCategory {
                Text(reasonCategory)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.indigo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.10), in: Capsule())
            }
            Text(comment.text)
                .font(.body)
        }
        .weshSurface()
    }
}
