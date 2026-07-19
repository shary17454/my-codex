import SwiftUI

struct DashboardView: View {
    let questions: [AskQuestion]
    let knowledgeItems: [KnowledgeItem]
    let statistics: DashboardStatistics
    let isRefreshing: Bool
    let isOffline: Bool
    let refresh: () async -> Void
    let openQuestion: (AskQuestion) -> Void
    let openSmartCompare: () -> Void
    let startQuestion: (KnowledgeItem?) -> Void

    private var highlightedItems: [KnowledgeItem] {
        Array(knowledgeItems.prefix(4))
    }

    private var categoryCount: Int {
        Set(knowledgeItems.map(\.category)).count
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                DashboardBrandHeader()

                if isOffline {
                    WeshStatusBanner(
                        text: "لا يوجد اتصال بالخادم. تُعرض آخر بيانات متاحة على الجهاز.",
                        kind: .warning
                    )
                } else if isRefreshing {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("جارٍ تحديث المقارنات...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }

                DecisionLaunchPanel(
                    startQuestion: { startQuestion(nil) },
                    openSmartCompare: openSmartCompare
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10)], spacing: 10) {
                    WeshMetricTile(
                        title: "مقارنة متاحة",
                        value: "\(questions.count)",
                        systemImage: "questionmark.bubble.fill",
                        color: WeshTheme.accent
                    )
                    .weshSurface(padding: 12)

                    WeshMetricTile(
                        title: "عنصر في الدليل",
                        value: "\(knowledgeItems.count)",
                        systemImage: "books.vertical.fill",
                        color: WeshTheme.secondaryAccent
                    )
                    .weshSurface(padding: 12)

                    WeshMetricTile(
                        title: "مجال قرار",
                        value: "\(categoryCount)",
                        systemImage: "square.grid.2x2.fill",
                        color: WeshTheme.highlight
                    )
                    .weshSurface(padding: 12)
                }

                DashboardInsightsCard(statistics: statistics)

                WeshSectionHeader(
                    "ابدأ من خيار جاهز",
                    subtitle: "حوّل أي عنصر إلى مقارنة قابلة للتصويت",
                    systemImage: "bolt.fill"
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 10)], spacing: 10) {
                    ForEach(highlightedItems) { item in
                        KnowledgeCompactCard(item: item) {
                            startQuestion(item)
                        }
                    }
                }

                WeshSectionHeader(
                    "أحدث المقارنات",
                    subtitle: "نتائج حقيقية تبدأ من استخدام المشاركين",
                    systemImage: "clock.fill"
                )

                LazyVStack(spacing: 10) {
                    ForEach(questions.prefix(4)) { question in
                        DashboardQuestionCard(question: question) {
                            openQuestion(question)
                        }
                    }
                }
            }
            .padding(16)
            .weshContentWidth()
        }
        .navigationTitle("الرئيسية")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppBackground())
        .refreshable {
            await refresh()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    startQuestion(nil)
                } label: {
                    Label("مقارنة جديدة", systemImage: "plus")
                }
            }
        }
    }
}

struct DashboardInsightsCard: View {
    let statistics: DashboardStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WeshSectionHeader(
                "لمحة سريعة",
                subtitle: "نشاطك والاتجاه العام للمقارنات",
                systemImage: "chart.bar.xaxis"
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 10)], spacing: 10) {
                InsightMetric(title: "المقارنات", value: "\(statistics.totalComparisons)", icon: "square.stack.3d.up.fill", color: WeshTheme.accent)
                InsightMetric(title: "الأصوات", value: "\(statistics.totalVotes)", icon: "chart.bar.fill", color: WeshTheme.secondaryAccent)
                InsightMetric(title: "الأسباب", value: "\(statistics.totalReasons)", icon: "quote.bubble.fill", color: WeshTheme.highlight)
                InsightMetric(title: "المحفوظة", value: "\(statistics.savedCount)", icon: "bookmark.fill", color: WeshTheme.success)
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                WeshIconTile(systemImage: statistics.topCategory.systemImage, color: WeshTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("الأكثر نشاطًا: \(statistics.topCategory.title)")
                        .font(.subheadline.weight(.bold))
                    Text(statistics.mostVotedTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(statistics.closeResultCount)")
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(WeshTheme.highlight)
                    Text("تحتاج آراء أكثر")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(statistics.closeResultCount) مقارنة تحتاج آراء أكثر")
            }
        }
        .weshSurface()
    }
}

struct InsightMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        WeshMetricTile(title: title, value: value, systemImage: icon, color: color)
    }
}

struct SortModePicker: View {
    @Binding var selectedSortMode: QuestionSortMode

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(QuestionSortMode.allCases) { mode in
                    Button {
                        selectedSortMode = mode
                    } label: {
                        HStack(spacing: 5) {
                            if selectedSortMode == mode {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                            Label(mode.title, systemImage: mode.systemImage)
                        }
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedSortMode == mode ? .white : .primary)
                        .background(
                            selectedSortMode == mode ? WeshTheme.accent : WeshTheme.surface,
                            in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedSortMode == mode ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
