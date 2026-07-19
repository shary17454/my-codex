import AVFoundation
import SwiftUI

struct SmartComparisonView: View {
    let items: [KnowledgeItem]
    let isPresentedModally: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var query = ""
    @State private var selectedCategory: AskCategory = .all
    @State private var selectedMode: ComparisonMode = .text
    @State private var selectedPriority: ComparisonPriority = .balanced
    @State private var selectedItems: [KnowledgeItem] = []
    @State private var generatedReport: ComparisonReport?
    @State private var speaker = AVSpeechSynthesizer()
    @State private var speechRevision = 0

    init(items: [KnowledgeItem], isPresentedModally: Bool = true) {
        self.items = items
        self.isPresentedModally = isPresentedModally
    }

    private var filteredItems: [KnowledgeItem] {
        KnowledgeSearchIndex.search(items, query: query, category: selectedCategory)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                comparisonHeader

                if horizontalSizeClass == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        selectionPanel.frame(maxWidth: 430)
                        resultPanel.frame(maxWidth: .infinity)
                    }
                } else {
                    selectionPanel
                    resultPanel
                }
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.vertical, 18)
            .weshContentWidth()
        }
        .background(AppBackground())
        .navigationTitle("قارن")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: selectedItems.count)
        .toolbar {
            if isPresentedModally {
                ToolbarItem(placement: .topBarLeading) {
                    Button("إغلاق") {
                        speaker.stopSpeaking(at: .immediate)
                        dismiss()
                    }
                }
            }
        }
    }

    private var comparisonHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                WeshIconTile(systemImage: "slider.horizontal.3", color: WeshTheme.gold, size: 52)
                VStack(alignment: .leading, spacing: 5) {
                    Text("مقارنة ذكية")
                        .font(.largeTitle.weight(.bold))
                    Text("اختر من عنصرين إلى عشرة عناصر، وسنرتبها بناءً على معلومات المكتبة والمعايير المناسبة للتصنيف.")
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            WeshStatusBanner(
                text: "يعتمد الترتيب على قواعد ثابتة ومعلومات المكتبة، وليس على نموذج ذكاء اصطناعي.",
                kind: .information
            )
        }
        .weshSurface(emphasized: true, goldAccent: true)
    }

    private var selectionPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            WeshSectionHeader("اختيار العناصر", subtitle: "ابحث داخل المكتبة وحدد الخيارات التي تريد مقارنتها")

            TextField("ابحث داخل المكتبة", text: $query)
                .textInputAutocapitalization(.never)
                .weshField()

            if !selectedItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedItems) { item in
                            SelectedItemChip(item: item) {
                                toggle(item)
                            }
                        }
                    }
                }
            }

            CategoryScroller(selectedCategory: $selectedCategory)

            VStack(alignment: .leading, spacing: 9) {
                Text("وش يهمك أكثر؟")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ComparisonPriority.allCases) { priority in
                            Button {
                                selectedPriority = priority
                                generatedReport = nil
                            } label: {
                                Label(priority.title, systemImage: priority.systemImage)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(1)
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 42)
                                    .foregroundStyle(selectedPriority == priority ? .black.opacity(0.82) : WeshTheme.primaryText)
                                    .background(
                                        selectedPriority == priority ? WeshTheme.gold : WeshTheme.elevatedSurface,
                                        in: Capsule()
                                    )
                                    .overlay { Capsule().stroke(selectedPriority == priority ? WeshTheme.gold : WeshTheme.hairline) }
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selectedPriority == priority ? .isSelected : [])
                        }
                    }
                }
            }

            if filteredItems.isEmpty {
                WeshEmptyState(
                    title: "ما لقينا عنصرًا مطابقًا",
                    message: "جرّب اسمًا مختلفًا أو غيّر التصنيف.",
                    systemImage: "magnifyingglass"
                )
            } else {
                LazyVStack(spacing: 9) {
                    ForEach(filteredItems.prefix(20)) { item in
                        Button { toggle(item) } label: {
                            SmartPickRow(item: item, isSelected: selectedItems.contains(item))
                        }
                        .buttonStyle(.plain)
                        .disabled(!selectedItems.contains(item) && selectedItems.count >= 10)
                    }
                }
            }

            Button(action: generateComparison) {
                Label("إنشاء المقارنة", systemImage: "sparkles.rectangle.stack")
            }
            .buttonStyle(WeshPrimaryButtonStyle())
            .disabled(selectedItems.count < 2)
        }
        .weshSurface()
    }

    @ViewBuilder
    private var resultPanel: some View {
        if let generatedReport {
            VStack(alignment: .leading, spacing: 14) {
                Picker("نوع العرض", selection: $selectedMode) {
                    ForEach(ComparisonMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                ComparisonResultCard(
                    report: generatedReport,
                    mode: selectedMode,
                    isSpeaking: speaker.isSpeaking,
                    speak: { speak(generatedReport.audioScript) }
                )
                .id(speechRevision)
            }
        } else {
            WeshEmptyState(
                title: selectedItems.count < 2 ? "اختر خيارين على الأقل" : "الخيارات جاهزة",
                message: selectedItems.count < 2
                    ? "اختر عناصر من المكتبة حتى تبدأ المقارنة."
                    : "اضغط «إنشاء المقارنة» لعرض الترتيب والخلاصة.",
                systemImage: "checklist"
            )
            .weshSurface()
        }
    }

    private func toggle(_ item: KnowledgeItem) {
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        } else if selectedItems.count < 10 {
            selectedItems.append(item)
        }
        generatedReport = nil
        if speaker.isSpeaking { speaker.stopSpeaking(at: .immediate) }
        speechRevision += 1
    }

    private func generateComparison() {
        guard selectedItems.count >= 2 else { return }
        generatedReport = ComparisonEngine.buildReport(for: selectedItems, priority: selectedPriority)
    }

    private func speak(_ text: String) {
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
            speechRevision += 1
            return
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.45
        speaker.speak(utterance)
        speechRevision += 1
    }
}

private struct SelectedItemChip: View {
    let item: KnowledgeItem
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            Text(item.name)
                .font(.caption.weight(.bold))
                .lineLimit(1)
            Button(action: remove) {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("إزالة \(item.name)")
        }
        .foregroundStyle(WeshTheme.accent)
        .padding(.horizontal, 11)
        .frame(minHeight: 40)
        .background(WeshTheme.accent.opacity(0.11), in: Capsule())
        .overlay { Capsule().stroke(WeshTheme.accent.opacity(0.22)) }
    }
}

struct SmartPickRow: View {
    let item: KnowledgeItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? WeshTheme.accent : WeshTheme.secondaryText)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(WeshTheme.primaryText)
                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .lineLimit(2)
            }
            Spacer()
            WeshIconTile(
                systemImage: item.category.systemImage,
                color: WeshTheme.categoryColor(item.category),
                size: 38
            )
        }
        .padding(12)
        .background(
            isSelected ? WeshTheme.accent.opacity(0.09) : WeshTheme.elevatedSurface,
            in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: WeshTheme.controlRadius)
                .stroke(isSelected ? WeshTheme.accent : WeshTheme.hairline, lineWidth: isSelected ? 1.5 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ComparisonResultCard: View {
    let report: ComparisonReport
    let mode: ComparisonMode
    let isSpeaking: Bool
    let speak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.title2.weight(.bold))
                    Text("ثقة الترتيب \(report.confidence)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.gold)
                }
                Spacer()
                WeshIconTile(systemImage: mode.systemImage, color: WeshTheme.gold, size: 46)
            }

            switch mode {
            case .text:
                textComparison
            case .audio:
                audioComparison
            case .video:
                scenarioComparison
            }
        }
        .weshSurface(emphasized: true, goldAccent: true)
    }

    private var textComparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(report.candidates.enumerated()), id: \.element.id) { index, candidate in
                RankedCandidateCard(candidate: candidate, rank: index + 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("الخلاصة", systemImage: "checkmark.bubble.fill")
                    .font(.headline)
                    .foregroundStyle(WeshTheme.gold)
                Text(report.recommendation)
                    .font(.body)
                    .foregroundStyle(WeshTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .weshSurface(padding: 15, goldAccent: true)

            ForEach(report.factors) { factor in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(WeshTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(factor.title)
                            .font(.subheadline.weight(.bold))
                        Text(factor.bestOptionName)
                            .font(.caption)
                            .foregroundStyle(WeshTheme.secondaryText)
                    }
                }
            }
        }
    }

    private var audioComparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(report.audioScript)
                .font(.body)
                .foregroundStyle(WeshTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: speak) {
                Label(
                    isSpeaking ? "إيقاف القراءة" : "الاستماع للملخص",
                    systemImage: isSpeaking ? "stop.fill" : "speaker.wave.2.fill"
                )
            }
            .buttonStyle(WeshPrimaryButtonStyle())
            if isSpeaking {
                Text("جاري قراءة الملخص…")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WeshTheme.accent)
            }
        }
    }

    private var scenarioComparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("سيناريو مشاركة")
                    .font(.headline)
                Text("نص منظم يمكنك استخدامه في فيديو أو منشور.")
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
            }
            ForEach(Array(report.videoStoryboard.enumerated()), id: \.offset) { index, scene in
                HStack(alignment: .top, spacing: 11) {
                    Text("\(index + 1)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.black.opacity(0.8))
                        .frame(width: 34, height: 34)
                        .background(WeshTheme.gold, in: Circle())
                    Text(scene)
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.primaryText)
                }
                .padding(.vertical, 5)
            }
            ShareLink(item: report.videoStoryboard.joined(separator: "\n\n")) {
                Label("مشاركة السيناريو", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(WeshSecondaryButtonStyle())
        }
    }
}

private struct RankedCandidateCard: View {
    let candidate: ComparisonCandidate
    let rank: Int

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Text("\(rank)")
                .font(.title2.monospacedDigit().weight(.heavy))
                .foregroundStyle(rank == 1 ? Color.black.opacity(0.8) : WeshTheme.primaryText)
                .frame(width: 44, height: 44)
                .background(rank == 1 ? WeshTheme.gold : WeshTheme.elevatedSurface, in: Circle())
                .overlay { Circle().stroke(rank == 1 ? WeshTheme.gold : WeshTheme.hairline) }

            VStack(alignment: .leading, spacing: 5) {
                Text(candidate.item.name)
                    .font(.headline)
                    .foregroundStyle(WeshTheme.primaryText)
                Text(candidate.verdict)
                    .font(.subheadline)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text("\(candidate.score)")
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(rank == 1 ? WeshTheme.gold : WeshTheme.accent)
        }
        .padding(14)
        .background(WeshTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
        .overlay {
            RoundedRectangle(cornerRadius: WeshTheme.controlRadius)
                .stroke(rank == 1 ? WeshTheme.gold.opacity(0.65) : WeshTheme.hairline, lineWidth: rank == 1 ? 1.5 : 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("المركز \(rank)، \(candidate.item.name)، \(candidate.score) نقطة")
    }
}
