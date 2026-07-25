import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit
import UserNotifications

private enum DetailDiscussionTab: String, CaseIterable, Identifiable {
    case reasons
    case discussion

    var id: String { rawValue }
    var title: String { self == .reasons ? "أسباب الاختيار" : "النقاش العام" }
}

struct QuestionDetail: View {
    let question: AskQuestion
    let relatedQuestions: [AskQuestion]
    let voteAction: (AskQuestion.ID, PollOption.ID) -> Void
    let voteWithReasonAction: (AskQuestion.ID, PollOption.ID, String, String?, Bool) -> Void
    let commentAction: (AskQuestion.ID, String) -> Void
    let isVoteSubmitting: Bool
    let hasVoted: Bool
    let isSaved: Bool
    let voteTrendPoints: [VoteTrendPoint]
    let outcome: DecisionOutcomeSnapshot?
    let personalEvaluation: PersonalDecisionEvaluation?
    let saveAction: (AskQuestion.ID) -> Void
    let saveOutcomeAction: (DecisionOutcomeSnapshot) -> Void
    let savePersonalEvaluationAction: (PersonalDecisionEvaluation) -> Void
    let openRelatedQuestion: (AskQuestion) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var commentText = ""
    @State private var selectedVoteOption: PollOption?
    @State private var votedOptionID: PollOption.ID?
    @State private var voteReason = ""
    @State private var selectedReasonCategory: String?
    @State private var isVerifiedExperience = false
    @State private var decisionMode: DecisionMode = .quick
    @State private var discussionTab: DetailDiscussionTab = .reasons
    @State private var selectedReasonOptionID: PollOption.ID?
    @State private var showVerifiedReasonsOnly = false
    @State private var savedDecisionState: SavedDecisionState = .comparing
    @State private var showingQRCode = false
    @State private var showingReportSheet = false
    @State private var showingShareActions = false
    @State private var showingReminderPicker = false
    @State private var showingPersonalDecision = false
    @State private var showingOutcomeEntry = false
    @State private var localMessage: String?
    @State private var localMessageKind: WeshStatusBanner.Kind = .success
    @State private var actionFeedback = 0

    private var visibleComments: [AskComment] {
        switch discussionTab {
        case .reasons:
            return question.comments.filter { comment in
                guard comment.optionID != nil else { return false }
                let matchesOption = selectedReasonOptionID == nil || comment.optionID == selectedReasonOptionID
                let matchesExperience = !showVerifiedReasonsOnly || comment.trustBadge != nil
                return matchesOption && matchesExperience
            }
        case .discussion:
            return question.comments.filter { $0.optionID == nil }
        }
    }

    private var shareText: String {
        ComparisonShareService.shareText(for: question)
    }

    private var hidesResults: Bool {
        question.hideResultsUntilVote && !hasVoted && votedOptionID == nil
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                QuestionDetailHero(question: question)

                votingSection

                if let selectedVoteOption {
                    VoteReasonCard(
                        option: selectedVoteOption,
                        category: question.category,
                        reason: $voteReason,
                        selectedReasonCategory: $selectedReasonCategory,
                        isVerifiedExperience: $isVerifiedExperience,
                        submitWithReason: {
                            votedOptionID = selectedVoteOption.id
                            voteWithReasonAction(question.id, selectedVoteOption.id, voteReason, selectedReasonCategory, isVerifiedExperience)
                            actionFeedback += 1
                            localMessage = "تم تسجيل صوتك وسبب اختيارك."
                            localMessageKind = .success
                            self.selectedVoteOption = nil
                            voteReason = ""
                            selectedReasonCategory = nil
                            isVerifiedExperience = false
                        },
                        voteOnly: {
                            votedOptionID = selectedVoteOption.id
                            voteAction(question.id, selectedVoteOption.id)
                            actionFeedback += 1
                            localMessage = "تم تسجيل صوتك."
                            localMessageKind = .success
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

                if hidesResults {
                    WeshStatusBanner(
                        text: "اختَر وصوّت أولًا حتى تظهر النتيجة وملخص القرار.",
                        kind: .information
                    )
                } else {
                    decisionAnalysisSection
                }

                SavedDecisionCard(selection: $savedDecisionState, shareText: shareText)

                DecisionActionCard(
                    question: question,
                    shareText: shareText,
                    share: { showingShareActions = true },
                    report: { showingReportSheet = true },
                    scheduleReminder: { showingReminderPicker = true },
                    personalDecision: { showingPersonalDecision = true },
                    recordOutcome: { showingOutcomeEntry = true }
                )

                if let localMessage {
                    WeshStatusBanner(text: localMessage, kind: localMessageKind)
                }

                if !relatedQuestions.isEmpty {
                    SimilarQuestionsCard(questions: relatedQuestions, openQuestion: openRelatedQuestion)
                }

                discussionSection
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 18)
            .weshContentWidth()
        }
        .background(AppBackground())
        .navigationTitle("تفاصيل المقارنة")
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

                Button {
                    showingShareActions = true
                } label: {
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
                    localMessageKind = .information
                    showingReportSheet = false
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .sheet(isPresented: $showingShareActions) {
            ComparisonShareSheet(question: question) {
                showingShareActions = false
                showingQRCode = true
            } unavailablePDF: {
                showingShareActions = false
                localMessage = "تصدير PDF غير متاح في النسخة الحالية."
                localMessageKind = .information
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingReminderPicker) {
            ReminderPickerView(question: question) { interval in
                showingReminderPicker = false
                scheduleReminder(interval)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPersonalDecision) {
            PersonalDecisionView(
                question: question,
                initialEvaluation: personalEvaluation,
                saveAction: savePersonalEvaluationAction
            )
        }
        .sheet(isPresented: $showingOutcomeEntry) {
            DecisionOutcomeEntryView(
                question: question,
                existingOutcome: outcome,
                saveAction: saveOutcomeAction
            )
        }
    }

    private var decisionAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DecisionSummaryEducationView()
            DecisionSummaryCard(question: question)

            Picker("نوع القرار", selection: $decisionMode) {
                ForEach(DecisionMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if decisionMode == .deep {
                Button {
                    showingPersonalDecision = true
                } label: {
                    Label("احسب الأنسب حسب احتياجك", systemImage: "person.crop.circle.badge.checkmark")
                }
                .buttonStyle(WeshGoldButtonStyle())
                DecisionCriteriaCard(category: question.category)
                SpecificationComparisonCard(question: question)
                VoteTrendChartView(points: voteTrendPoints)
            }
        }
    }

    private var votingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader(
                question.totalVotes == 0 || hidesResults ? "صوّت الآن" : "النتيجة الحالية",
                subtitle: question.totalVotes == 0 || hidesResults ? "اختر الخيار الأقرب لك، ثم أضف سببك إن رغبت." : "اختر خيارًا للمشاركة؛ النسب والأعداد ظاهرة بوضوح.",
                systemImage: "checkmark.circle"
            )
            if isVoteSubmitting {
                ProgressView("جارٍ إرسال التصويت...")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(question.options) { option in
                    VoteOptionRow(
                        option: option,
                        totalVotes: hidesResults ? 0 : question.totalVotes,
                        systemImage: question.category.systemImage,
                        isWinning: !hidesResults && option.id == question.winningOption?.id,
                        isSelected: option.id == selectedVoteOption?.id,
                        isUserChoice: option.id == votedOptionID
                    ) {
                        selectedVoteOption = option
                        voteReason = ""
                    }
                    .disabled(isVoteSubmitting)
                }
            }
        }
    }

    private var discussionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            WeshSectionHeader(
                "الأسباب والنقاش",
                subtitle: "أسباب الاختيار مرتبطة بالتصويت، والنقاش العام منفصل عنها.",
                systemImage: "quote.bubble"
            )

            Picker("نوع المحتوى", selection: $discussionTab) {
                ForEach(DetailDiscussionTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            if discussionTab == .reasons {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button("الكل") { selectedReasonOptionID = nil }
                            .reasonFilterStyle(isSelected: selectedReasonOptionID == nil)
                        ForEach(question.options) { option in
                            Button(option.title) { selectedReasonOptionID = option.id }
                                .reasonFilterStyle(isSelected: selectedReasonOptionID == option.id)
                        }
                    }
                }
                Toggle("من جرّب الخيار فقط", isOn: $showVerifiedReasonsOnly)
                    .font(.subheadline.weight(.semibold))
                    .tint(WeshTheme.accent)
            } else {
                WeshStatusBanner(
                    text: "استخدم التعليقات للنقاش العام، وأضف سبب التصويت داخل الخيار الذي اخترته.",
                    kind: .information
                )
                HStack(spacing: 9) {
                    TextField("شارك سؤالًا أو ملاحظة", text: $commentText, axis: .vertical)
                        .lineLimit(1...4)
                        .weshField()
                    Button {
                        commentAction(question.id, commentText)
                        commentText = ""
                        actionFeedback += 1
                        localMessage = "تمت إضافة تعليقك."
                        localMessageKind = .success
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(WeshTheme.accent, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
                    }
                    .buttonStyle(.plain)
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("إرسال التعليق")
                }
            }

            if visibleComments.isEmpty {
                WeshEmptyState(
                    title: discussionTab == .reasons ? "لا توجد أسباب مضافة" : "ابدأ النقاش",
                    message: discussionTab == .reasons
                        ? "أضف سبب اختيارك حتى تساعد الآخرين على فهم القرار."
                        : "شارك سؤالًا أو ملاحظة مرتبطة بالمقارنة.",
                    systemImage: discussionTab == .reasons ? "quote.bubble" : "text.bubble"
                )
            } else {
                ForEach(visibleComments) { comment in
                    CommentRow(comment: comment)
                }
            }
        }
    }

    private func scheduleReminder(_ interval: TimeInterval) {
        Task {
            do {
                try await LocalNotificationScheduler.scheduleDecisionReminder(for: question, after: interval)
                await MainActor.run {
                    localMessage = "تم جدولة التذكير."
                    localMessageKind = .success
                }
            } catch {
                await MainActor.run {
                    localMessage = "فعّل الإشعارات من إعدادات الجهاز حتى يصلك التذكير."
                    localMessageKind = .warning
                }
            }
        }
    }
}

private struct QuestionDetailHero: View {
    let question: AskQuestion

    private var reasonCount: Int {
        question.comments.filter { $0.optionID != nil }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                WeshPill(
                    question.category.title,
                    systemImage: question.category.systemImage,
                    color: WeshTheme.categoryColor(question.category)
                )
                Spacer()
                Text(question.timeAgo)
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
            }

            Text(question.title)
                .font(.title.weight(.bold))
                .foregroundStyle(WeshTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text(question.details)
                .font(.body)
                .foregroundStyle(WeshTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(WeshTheme.hairline)

            HStack(spacing: 14) {
                Label(question.author, systemImage: "person.crop.circle")
                Label("\(question.totalVotes) مشاركًا", systemImage: "person.2.fill")
                Label("\(reasonCount) سببًا", systemImage: "quote.bubble.fill")
            }
            .font(.caption)
            .foregroundStyle(WeshTheme.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.68)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    func reasonFilterStyle(isSelected: Bool) -> some View {
        font(.caption.weight(.bold))
            .foregroundStyle(isSelected ? Color.white : WeshTheme.primaryText)
            .padding(.horizontal, 12)
            .frame(minHeight: 40)
            .background(isSelected ? WeshTheme.accent : WeshTheme.surface, in: Capsule())
            .overlay { Capsule().stroke(isSelected ? WeshTheme.accent : WeshTheme.hairline) }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let option: PollOption
    let totalVotes: Int
    let systemImage: String
    let isWinning: Bool
    let isSelected: Bool
    let isUserChoice: Bool
    let action: () -> Void

    private var percent: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.votes) / Double(totalVotes)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    WeshIconTile(
                        systemImage: systemImage,
                        color: isWinning ? WeshTheme.gold : WeshTheme.secondaryAccent,
                        size: 58
                    )
                    Spacer()
                    Image(systemName: isSelected || isUserChoice ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected || isUserChoice ? WeshTheme.accent : WeshTheme.secondaryText)
                        .accessibilityHidden(true)
                }

                Text(option.title)
                    .font(.headline)
                    .foregroundStyle(WeshTheme.primaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if totalVotes > 0 {
                    Text("\(Int((percent * 100).rounded()))%")
                        .font(.title2.monospacedDigit().weight(.bold))
                        .foregroundStyle(isWinning ? WeshTheme.accentBright : WeshTheme.primaryText)
                    ProgressView(value: percent)
                        .tint(isWinning ? WeshTheme.accent : WeshTheme.secondaryAccent)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: percent)
                    Text("\(option.votes) صوتًا")
                        .font(.caption)
                        .foregroundStyle(WeshTheme.secondaryText)
                    if isWinning {
                        WeshPill("المتصدر", systemImage: "crown.fill", color: WeshTheme.gold)
                    }
                    if isUserChoice {
                        Label("اختيارك", systemImage: "checkmark.seal.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(WeshTheme.accent)
                    }
                } else {
                    Text(isSelected ? "تم تحديد هذا الخيار" : "اختر هذا الخيار")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? WeshTheme.accent : WeshTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 198, alignment: .topLeading)
            .padding(17)
            .background(WeshTheme.surface, in: RoundedRectangle(cornerRadius: WeshTheme.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: WeshTheme.cardRadius)
                    .stroke(
                        isSelected || isUserChoice ? WeshTheme.accent : WeshTheme.hairline,
                        lineWidth: isSelected || isUserChoice ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityValue("\(Int((percent * 100).rounded())) بالمئة، \(option.votes) صوتًا\(isUserChoice ? "، وهو اختيارك" : "")")
        .accessibilityHint("اضغط لاختيار هذا الخيار")
        .accessibilityAddTraits(isSelected || isUserChoice ? .isSelected : [])
    }
}

struct DecisionSummaryCard: View {
    let question: AskQuestion
    private var summary: DecisionSummary {
        DecisionSummaryService.makeSummary(for: question)
    }

    private var confidencePercent: Int {
        summary.confidenceScore
    }

    private var clarityColor: Color {
        switch summary.clarity {
        case .insufficientData: WeshTheme.secondaryText
        case .close: WeshTheme.gold
        case .leaning, .decisive: WeshTheme.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            verdictHero

            WeshSectionHeader(
                "مؤشرات القرار",
                subtitle: "أرقام فعلية مستخرجة من الأصوات والأسباب الحالية",
                systemImage: "chart.bar.fill"
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 9)], spacing: 9) {
                DecisionMetric(title: "قوة النتيجة", value: summary.confidenceLevel.arabicTitle, icon: "shield.checkered", color: WeshTheme.gold)
                DecisionMetric(title: "عدد المشاركين", value: "\(summary.totalVotes)", icon: "person.2.fill", color: WeshTheme.accent)
                DecisionMetric(title: "الفارق", value: "\(Int(summary.voteGapPercentage.rounded()))%", icon: "arrow.left.and.right", color: WeshTheme.secondaryAccent)
                DecisionMetric(title: "مؤشر الثقة", value: "\(confidencePercent)%", icon: "chart.bar.fill", color: clarityColor)
                DecisionMetric(
                    title: "جودة الأدلة",
                    value: "\(summary.evidenceQuality.score)%",
                    icon: "checkmark.shield.fill",
                    color: summary.evidenceQuality.score >= 60 ? WeshTheme.accent : WeshTheme.gold
                )
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Label("جودة الأدلة", systemImage: "checkmark.shield")
                        .font(.headline)
                    Spacer()
                    Text(summary.evidenceQuality.level.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(summary.evidenceQuality.score >= 60 ? WeshTheme.accent : WeshTheme.gold)
                }
                ForEach(summary.evidenceQuality.notes, id: \.self) { note in
                    Label(note, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(WeshTheme.secondaryText)
                }
            }
            .padding(13)
            .background(WeshTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius))

            if !summary.reasonThemes.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    Label("الموضوعات الأكثر تكرارًا", systemImage: "text.magnifyingglass")
                        .font(.headline)
                    ForEach(summary.reasonThemes.prefix(5)) { theme in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(theme.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(theme.sentimentLabel)
                                    .font(.caption)
                                    .foregroundStyle(WeshTheme.secondaryText)
                            }
                            Spacer()
                            Text("\(theme.mentionCount)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(WeshTheme.accent)
                        }
                    }
                }
            }

            if !summary.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("ملخص الأسباب", systemImage: "list.bullet.clipboard.fill")
                        .font(.headline)
                        .foregroundStyle(WeshTheme.primaryText)
                    ForEach(summary.highlights) { highlight in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(highlight.title)
                                .font(.subheadline.weight(.bold))
                            Text(highlight.details)
                                .font(.subheadline)
                                .foregroundStyle(WeshTheme.secondaryText)
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

            if !summary.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("ماذا تفعل الآن؟", systemImage: "checklist")
                        .font(.headline)
                        .foregroundStyle(WeshTheme.primaryText)

                    ForEach(summary.actionItems) { item in
                        DecisionActionItemRow(item: item)
                    }
                }
            }

            if !summary.optionInsights.isEmpty {
                Divider().overlay(WeshTheme.hairline)
                VStack(alignment: .leading, spacing: 10) {
                    Label("أبرز الأسباب حسب الخيار", systemImage: "list.bullet.clipboard")
                        .font(.headline)
                        .foregroundStyle(WeshTheme.primaryText)

                    ForEach(summary.optionInsights) { insight in
                        OptionInsightView(insight: insight)
                    }
                }
            }

            WeshStatusBanner(
                text: "هذا الملخص إرشادي ويعتمد على الأصوات والأسباب الموجودة داخل المقارنة. لا يمثل تقييمًا رسميًا أو نتيجة علمية.",
                kind: .information
            )
        }
        .weshSurface(emphasized: true, goldAccent: true)
    }

    private var verdictHero: some View {
        ZStack {
            LinearGradient(
                colors: [WeshTheme.gold.opacity(0.14), WeshTheme.surface, WeshTheme.gold.opacity(0.05)],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 9) {
                    Label("بوصلة القرار", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.goldBright)

                    Text(summary.compassTitle)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(WeshTheme.goldBright)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(summary.compassSubtitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(WeshTheme.primaryText.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(summary.recommendationText)
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(summary.totalVotes > 0 ? "\(summary.leadingVotePercentage)%" : "—")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundStyle(WeshTheme.goldBright)

                    DecisionClarityPill(clarity: summary.clarity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                WeshDecisionSeal(size: 104)
                    .frame(maxWidth: 112)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: WeshTheme.controlRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: WeshTheme.controlRadius, style: .continuous)
                .stroke(WeshTheme.gold.opacity(0.38), lineWidth: 1)
        }
    }
}

struct DecisionSummaryScreen: View {
    @Environment(\.dismiss) private var dismiss

    let question: AskQuestion
    let isSaved: Bool
    let saveAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DecisionSummaryCard(question: question)

                Button(action: saveAction) {
                    Label(
                        isSaved ? "النتيجة محفوظة في المكتبة" : "حفظ النتيجة في المكتبة",
                        systemImage: isSaved ? "bookmark.fill" : "bookmark"
                    )
                }
                .buttonStyle(WeshGoldButtonStyle())
                .disabled(isSaved)
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 18)
            .weshContentWidth()
        }
        .background(AppBackground())
        .navigationTitle("ملخص القرار")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("تم") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: ComparisonShareService.shareText(for: question)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("مشاركة ملخص القرار")
            }
        }
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
                Text("أكثر الأسباب تكرارًا")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WeshTheme.secondaryText)
                FlowTags(values: Array(insight.topReasons.prefix(4)), color: WeshTheme.accent)
            }

            HStack(alignment: .top, spacing: 8) {
                if !insight.positives.isEmpty {
                    InsightList(title: "نقاط القوة", values: insight.positives, color: WeshTheme.accent, icon: "checkmark.circle.fill")
                }
                if !insight.negatives.isEmpty {
                    InsightList(title: "الملاحظات", values: insight.negatives, color: WeshTheme.gold, icon: "exclamationmark.circle.fill")
                }
            }

            if insight.evidenceCount == 0 {
                Text("لا توجد أسباب مكتوبة كافية لهذا الخيار بعد.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(13)
        .background(WeshTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
        .overlay { RoundedRectangle(cornerRadius: WeshTheme.controlRadius).stroke(WeshTheme.hairline) }
    }
}

struct DecisionActionItemRow: View {
    let item: DecisionActionItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            WeshIconTile(systemImage: item.systemImage, color: WeshTheme.gold, size: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WeshTheme.primaryText)
                Text(item.details)
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(WeshTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius))
        .overlay {
            RoundedRectangle(cornerRadius: WeshTheme.compactRadius)
                .stroke(WeshTheme.hairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius))
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
    static func scheduleDecisionReminder(for question: AskQuestion, after timeInterval: TimeInterval) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else {
            throw AppError.forbidden
        }

        let content = UNMutableNotificationContent()
        content.title = "وش الرأي"
        content.body = "راجع نتيجة: \(question.title)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, timeInterval), repeats: false)
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
    let share: () -> Void
    let report: () -> Void
    let scheduleReminder: () -> Void
    let personalDecision: () -> Void
    let recordOutcome: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader(
                "أدوات القرار",
                subtitle: "شارك النتيجة أو احتفظ بها أو عُد إليها لاحقًا.",
                systemImage: "square.grid.2x2"
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], spacing: 10) {
                Button(action: share) {
                    DecisionToolButton(title: "مشاركة", icon: "square.and.arrow.up", color: WeshTheme.accent)
                }
                .buttonStyle(.plain)
                ShareLink(item: ComparisonShareService.csvText(for: question)) {
                    DecisionToolButton(title: "تصدير CSV", icon: "tablecells", color: WeshTheme.secondaryAccent)
                }
                Button(action: scheduleReminder) {
                    DecisionToolButton(title: "إضافة تذكير", icon: "bell.badge", color: WeshTheme.gold)
                }
                .buttonStyle(.plain)
                Button(action: personalDecision) {
                    DecisionToolButton(title: "حسب احتياجي", icon: "slider.horizontal.3", color: WeshTheme.accent)
                }
                .buttonStyle(.plain)
                Button(action: recordOutcome) {
                    DecisionToolButton(title: "سجل تجربتي", icon: "star.bubble", color: WeshTheme.gold)
                }
                .buttonStyle(.plain)
                Button(action: report) {
                    DecisionToolButton(title: "إبلاغ", icon: "exclamationmark.bubble", color: WeshTheme.destructive)
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

private struct ComparisonShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let question: AskQuestion
    let showQRCode: () -> Void
    let unavailablePDF: () -> Void

    private var shareText: String { ComparisonShareService.shareText(for: question) }
    private var link: String { ComparisonShareService.deepLink(for: question).absoluteString }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ShareLink(item: shareText) {
                        ShareActionRow(title: "مشاركة المقارنة", icon: "square.and.arrow.up", color: WeshTheme.accent)
                    }
                    ShareLink(item: question.smartSummary) {
                        ShareActionRow(title: "مشاركة ملخص النتيجة", icon: "doc.text", color: WeshTheme.gold)
                    }
                    NavigationLink {
                        ShareDecisionResultView(question: question)
                    } label: {
                        ShareActionRow(title: "بطاقة نتيجة كصورة", icon: "photo.on.rectangle.angled", color: WeshTheme.gold)
                    }
                    .buttonStyle(.plain)
                    Button {
                        UIPasteboard.general.string = shareText
                        dismiss()
                    } label: {
                        ShareActionRow(title: "نسخ النص", icon: "doc.on.doc", color: WeshTheme.secondaryAccent)
                    }
                    Button(action: showQRCode) {
                        ShareActionRow(title: "إنشاء رمز QR", icon: "qrcode", color: WeshTheme.primaryText)
                    }
                    ShareLink(item: ComparisonShareService.csvText(for: question)) {
                        ShareActionRow(title: "تصدير CSV", icon: "tablecells", color: WeshTheme.secondaryAccent)
                    }
                    Button(action: unavailablePDF) {
                        ShareActionRow(title: "تصدير PDF", icon: "doc.richtext", color: WeshTheme.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("رابط التطبيق")
                            .font(.caption.weight(.bold))
                        if let inviteCode = question.inviteCode, question.visibility != .publicRoom {
                            Text("رمز الدعوة: \(inviteCode)")
                                .font(.subheadline.monospaced().weight(.bold))
                                .foregroundStyle(WeshTheme.goldBright)
                                .textSelection(.enabled)
                        }
                        Text(link)
                            .font(.caption.monospaced())
                            .foregroundStyle(WeshTheme.secondaryText)
                            .textSelection(.enabled)
                        Text("يحتاج المستلم إلى تطبيق «وش الرأي» لفتح هذا الرابط.")
                            .font(.caption)
                            .foregroundStyle(WeshTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .weshSurface(padding: 14)
                }
                .padding(18)
            }
            .background(AppBackground())
            .navigationTitle("مشاركة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
        }
    }
}

private struct ShareActionRow: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            WeshIconTile(systemImage: icon, color: color, size: 42)
            Text(title)
                .font(.headline)
                .foregroundStyle(WeshTheme.primaryText)
            Spacer()
            Image(systemName: "chevron.backward")
                .font(.caption.weight(.bold))
                .foregroundStyle(WeshTheme.secondaryText)
        }
        .padding(12)
        .background(WeshTheme.surface, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
        .overlay { RoundedRectangle(cornerRadius: WeshTheme.controlRadius).stroke(WeshTheme.hairline) }
    }
}

private struct ReminderPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let question: AskQuestion
    let schedule: (TimeInterval) -> Void
    @State private var customDate = Date().addingTimeInterval(7_200)

    private var eveningInterval: TimeInterval {
        let calendar = Calendar.current
        let todayAtEight = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date().addingTimeInterval(14_400)
        let target = todayAtEight > Date() ? todayAtEight : calendar.date(byAdding: .day, value: 1, to: todayAtEight) ?? Date().addingTimeInterval(86_400)
        return target.timeIntervalSinceNow
    }

    private var tomorrowInterval: TimeInterval {
        let target = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86_400)
        return target.timeIntervalSinceNow
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(question.title)
                        .font(.headline)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .lineLimit(2)
                        .padding(.bottom, 4)
                    ReminderChoiceButton(title: "بعد ساعة", icon: "clock") { schedule(3_600) }
                    ReminderChoiceButton(title: "مساء اليوم", icon: "moon.stars") { schedule(eveningInterval) }
                    ReminderChoiceButton(title: "غدًا", icon: "sunrise") { schedule(tomorrowInterval) }

                    VStack(alignment: .leading, spacing: 10) {
                        Label("اختيار وقت", systemImage: "calendar")
                            .font(.headline)
                        DatePicker(
                            "وقت التذكير",
                            selection: $customDate,
                            in: Date().addingTimeInterval(60)...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        Button("جدولة الوقت المحدد") {
                            schedule(customDate.timeIntervalSinceNow)
                        }
                        .buttonStyle(WeshPrimaryButtonStyle())
                    }
                    .weshSurface()

                    Text("خيار «قبل انتهاء التصويت» يحتاج تاريخ انتهاء محفوظًا مع المقارنة، وهو غير متوفر في هذه المقارنة الحالية.")
                        .font(.caption)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
            }
            .background(AppBackground())
            .navigationTitle("ذكّرني بالنتيجة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
            }
        }
    }
}

private struct ReminderChoiceButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ShareActionRow(title: title, icon: icon, color: WeshTheme.gold)
        }
        .buttonStyle(.plain)
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
                    .foregroundStyle(WeshTheme.accent)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("وش السبب الأهم لاختيارك؟")
                        .font(.headline)
                    Text("اخترت \(option.title). أضف تجربتك حتى تساعد الآخرين على فهم القرار.")
                        .font(.caption)
                        .foregroundStyle(WeshTheme.secondaryText)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("أسباب جاهزة")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                FlowTags(
                    values: DecisionFeatureCatalog.voteReasons(for: category),
                    color: WeshTheme.accent,
                    action: { value in
                        selectedReasonCategory = value
                        reason = value
                    }
                )
            }

            TextField("اكتب تجربتك أو سبب اختيارك", text: $reason, axis: .vertical)
                .lineLimit(2...5)
                .weshField()
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
                Button("إرسال التصويت والسبب", action: submitWithReason)
                    .buttonStyle(WeshPrimaryButtonStyle())
                    .disabled(!canSubmitReason)

                HStack(spacing: 10) {
                    Button("تصويت بدون سبب", action: voteOnly)
                        .buttonStyle(WeshSecondaryButtonStyle())
                        .frame(maxWidth: .infinity)

                    Button("إلغاء", action: cancel)
                        .buttonStyle(WeshSecondaryButtonStyle())
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
                HStack(spacing: 9) {
                    Text(String(comment.author.prefix(1)))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(WeshTheme.secondaryAccent, in: Circle())
                    Text(comment.author)
                        .font(.subheadline.weight(.bold))
                }
                Spacer()
                Label("\(comment.likes)", systemImage: "hand.thumbsup")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
            }
            if let optionTitle = comment.optionTitle {
                HStack(spacing: 6) {
                    Label("صوّت لـ \(optionTitle)", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(WeshTheme.accent)
                    if let trustBadge = comment.trustBadge {
                        Label(trustBadge, systemImage: "shield.fill")
                            .foregroundStyle(WeshTheme.accent)
                    }
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(WeshTheme.accent.opacity(0.10), in: Capsule())
            }
            if let reasonCategory = comment.reasonCategory {
                Text(reasonCategory)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(WeshTheme.secondaryAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WeshTheme.secondaryAccent.opacity(0.10), in: Capsule())
            }
            Text(comment.text)
                .font(.body)
                .foregroundStyle(WeshTheme.primaryText)
        }
        .weshSurface()
    }
}
