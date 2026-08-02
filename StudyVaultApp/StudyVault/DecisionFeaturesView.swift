import Charts
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct PersonalDecisionView: View {
    @Environment(\.dismiss) private var dismiss
    let question: AskQuestion
    let saveAction: (PersonalDecisionEvaluation) -> Void

    @State private var criteria: [DecisionCriterion]
    @State private var options: [EvaluatedOption]
    @State private var didSave = false

    init(
        question: AskQuestion,
        initialEvaluation: PersonalDecisionEvaluation?,
        saveAction: @escaping (PersonalDecisionEvaluation) -> Void
    ) {
        self.question = question
        self.saveAction = saveAction
        let evaluation = initialEvaluation ?? Self.defaultEvaluation(for: question)
        _criteria = State(initialValue: evaluation.criteria)
        _options = State(initialValue: evaluation.options)
    }

    private var ranking: [RankedDecisionOption] {
        WeightedDecisionEngine.rank(options: options, criteria: criteria)
    }

    private var communityWinner: PollOption? {
        question.winningOption
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WeshStatusBanner(
                        text: "هذه نتيجة شخصية تعتمد على الأوزان والدرجات التي تحددها أنت، وليست تحليل ذكاء اصطناعي.",
                        kind: .information
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        WeshSectionHeader(
                            "أهمية المعايير",
                            subtitle: "صفر يعني أن المعيار لا يؤثر، وخمسة تعني أنه مهم جدًا.",
                            systemImage: "slider.horizontal.3"
                        )
                        ForEach($criteria) { $criterion in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(criterion.title)
                                        .font(.subheadline.weight(.bold))
                                    Spacer()
                                    Text("\(Int(criterion.weight)) من 5")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(WeshTheme.secondaryText)
                                }
                                Slider(value: $criterion.weight, in: 0...5, step: 1)
                                    .tint(WeshTheme.accent)
                                    .accessibilityLabel("أهمية \(criterion.title)")
                            }
                        }
                    }
                    .weshSurface()

                    VStack(alignment: .leading, spacing: 12) {
                        WeshSectionHeader(
                            "تقييم الخيارات",
                            subtitle: "قيّم كل خيار من صفر إلى عشرة وفق المعلومات أو تجربتك.",
                            systemImage: "list.number"
                        )
                        ForEach($options) { $option in
                            DisclosureGroup {
                                VStack(spacing: 12) {
                                    ForEach(criteria) { criterion in
                                        criterionScoreEditor(option: $option, criterion: criterion)
                                    }
                                }
                                .padding(.top, 10)
                            } label: {
                                Text(option.title)
                                    .font(.headline)
                            }
                            .padding(13)
                            .background(WeshTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius))
                        }
                    }
                    .weshSurface()

                    PersonalDecisionResultCard(
                        ranking: ranking,
                        communityWinner: communityWinner,
                        criteria: criteria
                    )

                    Button {
                        let evaluation = PersonalDecisionEvaluation(
                            criteria: criteria,
                            options: options,
                            updatedAt: Date()
                        )
                        saveAction(evaluation)
                        didSave = true
                    } label: {
                        Label(didSave ? "تم حفظ معاييرك" : "حفظ النتيجة الشخصية", systemImage: didSave ? "checkmark" : "tray.and.arrow.down")
                    }
                    .buttonStyle(WeshGoldButtonStyle())
                }
                .padding(WeshTheme.horizontalPadding)
                .weshContentWidth()
            }
            .background(AppBackground())
            .navigationTitle("مقارنة حسب احتياجي")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("تم") { dismiss() }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func criterionScoreEditor(
        option: Binding<EvaluatedOption>,
        criterion: DecisionCriterion
    ) -> some View {
        let score = Binding<Double>(
            get: { option.wrappedValue.scores[criterion.id] ?? 5 },
            set: { option.wrappedValue.scores[criterion.id] = $0 }
        )
        return VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(criterion.title)
                    .font(.subheadline)
                Spacer()
                Text(score.wrappedValue.formatted(.number.precision(.fractionLength(1))))
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(WeshTheme.accent)
            }
            Slider(value: score, in: 0...10, step: 0.5)
                .tint(WeshTheme.accent)
                .accessibilityLabel("تقييم \(option.wrappedValue.title) في \(criterion.title)")
        }
    }

    private static func defaultEvaluation(for question: AskQuestion) -> PersonalDecisionEvaluation {
        let criteria = DecisionFeatureCatalog.criteria(for: question.category)
            .prefix(6)
            .map { DecisionCriterion(title: $0, weight: 3) }
        let neutralScores = Dictionary(uniqueKeysWithValues: criteria.map { ($0.id, 5.0) })
        let options = question.options.map {
            EvaluatedOption(id: $0.id, title: $0.title, scores: neutralScores)
        }
        return PersonalDecisionEvaluation(criteria: criteria, options: options, updatedAt: Date())
    }
}

private struct PersonalDecisionResultCard: View {
    let ranking: [RankedDecisionOption]
    let communityWinner: PollOption?
    let criteria: [DecisionCriterion]

    private var leadingCriterion: DecisionCriterion? {
        criteria.max { $0.weight < $1.weight }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            WeshSectionHeader("نتيجتك الشخصية", subtitle: "متوسط موزون من 10", systemImage: "person.crop.circle.badge.checkmark")

            ForEach(ranking) { result in
                HStack(spacing: 12) {
                    Text("\(result.rank)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(result.rank == 1 ? WeshTheme.goldBright : WeshTheme.secondaryText)
                        .frame(width: 30, height: 30)
                        .background(WeshTheme.elevatedSurface, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(result.title)
                            .font(.subheadline.weight(.bold))
                        Text("\(result.score.formatted(.number.precision(.fractionLength(1)))) من 10")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(WeshTheme.secondaryText)
                    }
                    Spacer()
                    if result.rank == 1 {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(WeshTheme.gold)
                    }
                }
            }

            if let personalWinner = ranking.first,
               let communityWinner,
               personalWinner.id != communityWinner.id {
                WeshStatusBanner(
                    text: "اختيار المجتمع: \(communityWinner.title). اختيارك حسب معاييرك: \(personalWinner.title). قد يرجع الفرق إلى زيادة وزن \(leadingCriterion?.title ?? "أولوياتك الشخصية").",
                    kind: .information
                )
            }
        }
        .weshSurface(emphasized: true, goldAccent: true)
    }
}

struct DecisionOutcomeEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let question: AskQuestion
    let saveAction: (DecisionOutcomeSnapshot) -> Void

    @State private var selectedOptionID: UUID?
    @State private var satisfaction: Int
    @State private var wouldChooseAgain: Bool
    @State private var note: String
    @State private var errorMessage: String?

    init(
        question: AskQuestion,
        existingOutcome: DecisionOutcomeSnapshot?,
        saveAction: @escaping (DecisionOutcomeSnapshot) -> Void
    ) {
        self.question = question
        self.saveAction = saveAction
        _selectedOptionID = State(initialValue: existingOutcome?.chosenOptionID)
        _satisfaction = State(initialValue: existingOutcome?.satisfactionScore ?? 4)
        _wouldChooseAgain = State(initialValue: existingOutcome?.wouldChooseAgain ?? true)
        _note = State(initialValue: existingOutcome?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    WeshSectionHeader("وش اخترت بالنهاية؟", subtitle: "سجّل النتيجة بعد الشراء أو التجربة.", systemImage: "checkmark.circle")

                    VStack(spacing: 9) {
                        ForEach(question.options) { option in
                            Button {
                                selectedOptionID = option.id
                            } label: {
                                HStack {
                                    Text(option.title)
                                        .font(.headline)
                                        .foregroundStyle(WeshTheme.primaryText)
                                    Spacer()
                                    Image(systemName: selectedOptionID == option.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedOptionID == option.id ? WeshTheme.accent : WeshTheme.secondaryText)
                                }
                                .padding(14)
                                .background(WeshTheme.surface, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
                                .overlay {
                                    RoundedRectangle(cornerRadius: WeshTheme.controlRadius)
                                        .stroke(selectedOptionID == option.id ? WeshTheme.accent : WeshTheme.hairline)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("مدى رضاك عن القرار")
                            .font(.headline)
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    satisfaction = value
                                } label: {
                                    Image(systemName: value <= satisfaction ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(WeshTheme.gold)
                                        .frame(minWidth: 44, minHeight: 44)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(value) من 5")
                            }
                        }
                        Toggle("سأختار الخيار نفسه مرة أخرى", isOn: $wouldChooseAgain)
                            .tint(WeshTheme.accent)
                    }
                    .weshSurface()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ملاحظتك")
                            .font(.headline)
                        TextField("وش أكثر شيء أعجبك أو ندمت عليه؟", text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .weshField()
                        Text("\(note.count) من 300")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(note.count > 300 ? WeshTheme.destructive : WeshTheme.secondaryText)
                    }
                    .weshSurface()

                    if let errorMessage {
                        WeshStatusBanner(text: errorMessage, kind: .warning)
                    }

                    Button("حفظ تجربتي", action: save)
                        .buttonStyle(WeshGoldButtonStyle())
                        .disabled(selectedOptionID == nil || note.count > 300)

                    WeshStatusBanner(
                        text: "هذه تجربة ذاتية منك، وليست تقييمًا رسميًا للخيار.",
                        kind: .information
                    )
                }
                .padding(WeshTheme.horizontalPadding)
                .weshContentWidth()
            }
            .background(AppBackground())
            .navigationTitle("نتيجة قرارك")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func save() {
        guard let selectedOptionID else {
            errorMessage = "اختر الخيار الذي اتخذته."
            return
        }
        saveAction(
            DecisionOutcomeSnapshot(
                comparisonID: question.id,
                chosenOptionID: selectedOptionID,
                satisfactionScore: satisfaction,
                wouldChooseAgain: wouldChooseAgain,
                note: note
            )
        )
        dismiss()
    }
}

struct DecisionShareCard: View {
    let question: AskQuestion
    let size: CGSize

    private var summary: DecisionSummary { DecisionSummaryService.makeSummary(for: question) }
    private var winnerName: String {
        guard summary.totalVotes > 0,
              let id = summary.winningOptionID,
              let winner = question.options.first(where: { $0.id == id }) else {
            return "بانتظار المشاركات"
        }
        return winner.title
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.055, blue: 0.075), Color(red: 0.03, green: 0.16, blue: 0.13)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: size.width * 0.025) {
                HStack {
                    WeshDecisionLogo(size: size.width * 0.09)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("وش الرأي")
                            .font(.system(size: size.width * 0.042, weight: .bold))
                        Text("قرارك أوضح")
                            .font(.system(size: size.width * 0.022, weight: .semibold))
                            .foregroundStyle(WeshTheme.accentBright)
                    }
                    Spacer()
                }

                Text(question.title)
                    .font(.system(size: size.width * 0.046, weight: .bold))
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.72)

                VStack(alignment: .leading, spacing: size.width * 0.012) {
                    Text(summary.totalVotes > 0 ? "في الصدارة" : "الحالة الحالية")
                        .font(.system(size: size.width * 0.023))
                        .foregroundStyle(Color.white.opacity(0.68))
                    Text(winnerName)
                        .font(.system(size: size.width * 0.048, weight: .bold))
                        .minimumScaleFactor(0.68)
                    Text(summary.totalVotes > 0 ? "\(summary.leadingVotePercentage)%" : "—")
                        .font(.system(size: size.width * 0.09, weight: .heavy, design: .rounded))
                        .foregroundStyle(WeshTheme.goldBright)
                    Text(summary.clarity.arabicTitle)
                        .font(.system(size: size.width * 0.026, weight: .semibold))
                }
                .padding(size.width * 0.032)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: size.width * 0.035))

                HStack(spacing: size.width * 0.014) {
                    shareMetric(title: "الثقة", value: "\(summary.confidenceScore)%")
                    shareMetric(title: "جودة الأدلة", value: "\(summary.evidenceQuality.score)%")
                    shareMetric(title: "المشاركون", value: "\(summary.totalVotes)")
                }

                Spacer(minLength: 0)

                HStack(alignment: .bottom) {
                    Text("النتيجة إرشادية وتعتمد على أصوات وأسباب المشاركين.")
                        .font(.system(size: size.width * 0.018))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    if let image = QRCodeImageGenerator.image(for: ComparisonShareService.publicURL(for: question).absoluteString) {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: size.width * 0.13, height: size.width * 0.13)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: size.width * 0.012))
                    }
                }
            }
            .padding(size.width * 0.05)
        }
        .frame(width: size.width, height: size.height)
        .foregroundStyle(.white)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func shareMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: size.width * 0.015))
                .foregroundStyle(Color.white.opacity(0.62))
            Text(value)
                .font(.system(size: size.width * 0.022, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(size.width * 0.018)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: size.width * 0.02))
    }
}

@MainActor
enum DecisionShareImageGenerator {
    static func createPNG(question: AskQuestion) throws -> URL {
        let size = CGSize(width: 1080, height: 1350)
        let renderer = ImageRenderer(content: DecisionShareCard(question: question, size: size))
        renderer.scale = 1
        guard let image = renderer.uiImage, let data = image.pngData() else {
            throw ShareImageError.renderFailed
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wesh-al-ray-\(question.id.uuidString).png")
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        return url
    }
}

enum ShareImageError: LocalizedError {
    case renderFailed

    var errorDescription: String? { "تعذر إنشاء صورة النتيجة." }
}

struct ShareDecisionResultView: View {
    let question: AskQuestion
    @State private var generatedURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                DecisionShareCard(question: question, size: CGSize(width: 300, height: 375))
                    .clipShape(RoundedRectangle(cornerRadius: WeshTheme.cardRadius))
                    .shadow(color: WeshTheme.gold.opacity(0.18), radius: 18, y: 8)

                if let generatedURL {
                    ShareLink(item: generatedURL, preview: SharePreview("ملخص قرار \(question.title)")) {
                        Label("مشاركة البطاقة", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(WeshGoldButtonStyle())
                } else {
                    Button(action: generate) {
                        Label("تجهيز بطاقة المشاركة", systemImage: "photo")
                    }
                    .buttonStyle(WeshGoldButtonStyle())
                }

                if let errorMessage {
                    WeshStatusBanner(text: errorMessage, kind: .warning)
                }
            }
            .padding(20)
            .weshContentWidth(alignment: .center)
        }
        .background(AppBackground())
        .navigationTitle("بطاقة النتيجة")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func generate() {
        do {
            generatedURL = try DecisionShareImageGenerator.createPNG(question: question)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum QRCodeImageGenerator {
    static func image(for value: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(value.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let transformed = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct VoteTrendChartView: View {
    let points: [VoteTrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader(
                "تغير النتيجة بمرور الوقت",
                subtitle: "يعتمد على أحداث التصويت المحفوظة فعليًا دون نقاط تقديرية.",
                systemImage: "chart.xyaxis.line"
            )

            if points.isEmpty {
                WeshEmptyState(
                    title: "لا يوجد سجل زمني بعد",
                    message: "ستظهر حركة الأصوات الجديدة هنا دون إنشاء نقاط تاريخية تقديرية.",
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("الوقت", point.date),
                        y: .value("الأصوات", point.cumulativeVotes)
                    )
                    .foregroundStyle(by: .value("الخيار", point.optionName))
                    .interpolationMethod(.stepEnd)

                    PointMark(
                        x: .value("الوقت", point.date),
                        y: .value("الأصوات", point.cumulativeVotes)
                    )
                    .foregroundStyle(by: .value("الخيار", point.optionName))
                }
                .chartLegend(position: .bottom, alignment: .leading)
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 230)
                .accessibilityLabel("مخطط تغير أصوات الخيارات بمرور الوقت")
            }
        }
        .weshSurface()
    }
}
