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
    @State private var selectedItems: [KnowledgeItem] = []
    @State private var speaker = AVSpeechSynthesizer()

    init(items: [KnowledgeItem], isPresentedModally: Bool = true) {
        self.items = items
        self.isPresentedModally = isPresentedModally
    }

    private var filteredItems: [KnowledgeItem] {
        KnowledgeSearchIndex.search(items, query: query, category: selectedCategory)
    }

    private var report: ComparisonReport {
        ComparisonEngine.buildReport(for: selectedItems)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                comparisonHeader

                if horizontalSizeClass == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        selectionPanel
                            .frame(maxWidth: 420)
                        resultPanel
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        selectionPanel
                        resultPanel
                    }
                }
            }
            .padding(16)
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
            HStack(alignment: .top, spacing: 12) {
                WeshIconTile(systemImage: "slider.horizontal.3", color: WeshTheme.secondaryAccent, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text("مقارنة حسب احتياجك")
                        .font(.title2.weight(.bold))
                    Text("اختر من خيارين إلى عشرة، ثم اقرأ النتيجة أو استمع إليها.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text("\(selectedItems.count)/10")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(WeshTheme.secondaryAccent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(WeshTheme.secondaryAccent.opacity(0.10), in: Capsule())
            }

            Picker("نوع العرض", selection: $selectedMode) {
                ForEach(ComparisonMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .weshSurface(emphasized: true)
    }

    private var selectionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader("اختر الخيارات", subtitle: "ابحث أو صفِّ حسب المجال")

            TextField("ابحث في دليل الخيارات", text: $query)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)

            CategoryScroller(selectedCategory: $selectedCategory)

            if filteredItems.isEmpty {
                ContentUnavailableView(
                    "لا توجد نتائج",
                    systemImage: "magnifyingglass",
                    description: Text("غيّر البحث أو المجال.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredItems.prefix(18)) { item in
                        Button {
                            toggle(item)
                        } label: {
                            SmartPickRow(item: item, isSelected: selectedItems.contains(item))
                        }
                        .buttonStyle(.plain)
                        .disabled(!selectedItems.contains(item) && selectedItems.count >= 10)
                    }
                }
            }
        }
        .weshSurface()
    }

    @ViewBuilder
    private var resultPanel: some View {
        if selectedItems.count < 2 {
            ContentUnavailableView(
                "اختر خيارين على الأقل",
                systemImage: "checklist",
                description: Text("ستظهر النتيجة فور اكتمال الاختيار.")
            )
            .frame(maxWidth: .infinity, minHeight: 320)
            .weshSurface()
        } else {
            ComparisonResultCard(report: report, mode: selectedMode) {
                speak(report.audioScript)
            }
        }
    }

    private func toggle(_ item: KnowledgeItem) {
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        } else if selectedItems.count < 10 {
            selectedItems.append(item)
        }
    }

    private func speak(_ text: String) {
        if speaker.isSpeaking {
            speaker.stopSpeaking(at: .immediate)
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.45
        speaker.speak(utterance)
    }
}

struct SmartPickRow: View {
    let item: KnowledgeItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? WeshTheme.accent : .secondary)
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: item.category.systemImage)
                .foregroundStyle(WeshTheme.accent)
                .accessibilityLabel(item.category.title)
        }
        .padding(12)
        .background(WeshTheme.canvas, in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: WeshTheme.cornerRadius)
                .stroke(isSelected ? WeshTheme.accent.opacity(0.55) : WeshTheme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ComparisonResultCard: View {
    let report: ComparisonReport
    let mode: ComparisonMode
    let speak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.title)
                        .font(.title2.weight(.black))
                    Text("ثقة التحليل \(report.confidence)%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.accent)
                }
                Spacer()
                WeshIconTile(systemImage: mode.systemImage, color: WeshTheme.accent, size: 46)
            }

            switch mode {
            case .text:
                textComparison
            case .audio:
                audioComparison
            case .video:
                videoComparison
            }
        }
        .weshSurface()
    }

    private var textComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(report.recommendation)
                .font(.headline)
            ForEach(report.candidates) { candidate in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(candidate.item.name)
                            .font(.headline)
                        Spacer()
                        Text("\(candidate.score)")
                            .font(.title3.weight(.black))
                            .monospacedDigit()
                            .foregroundStyle(WeshTheme.accent)
                    }
                    Text(candidate.verdict)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                Divider()
            }

            ForEach(report.factors) { factor in
                Label("\(factor.title): \(factor.bestOptionName)", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WeshTheme.accent)
            }
        }
    }

    private var audioComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("نص التعليق الصوتي")
                .font(.headline)
            Text(report.audioScript)
                .foregroundStyle(.secondary)
            Button(action: speak) {
                Label("تشغيل أو إيقاف الصوت", systemImage: "speaker.wave.2.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var videoComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("سيناريو عرض القرار")
                .font(.headline)
            ForEach(Array(report.videoStoryboard.enumerated()), id: \.offset) { index, scene in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(WeshTheme.accent, in: Circle())
                    Text(scene)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
                Divider()
            }
            Text("مخطط موجز يرتب النتيجة ومبرراتها في مشاهد قابلة للمشاركة.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
