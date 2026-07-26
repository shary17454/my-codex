import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingHeaderMenu = false
    @State private var showingNotifications = false

    let questions: [AskQuestion]
    let knowledgeItems: [KnowledgeItem]
    let statistics: DashboardStatistics
    let userName: String
    let isSignedIn: Bool
    let hasDraft: Bool
    let isRefreshing: Bool
    let isOffline: Bool
    let refresh: () async -> Void
    let openQuestion: (AskQuestion) -> Void
    let openDecisionSummary: (AskQuestion) -> Void
    let openDiscover: () -> Void
    let openSmartCompare: () -> Void
    let startQuestion: (KnowledgeItem?) -> Void
    let restoreDraft: () -> Void

    private var highlightedItems: [KnowledgeItem] {
        Array(knowledgeItems.prefix(4))
    }

    private var activeCategories: [AskCategory] {
        let available = Set(knowledgeItems.map(\.category))
        return AskCategory.allCases.filter { $0 != .all && available.contains($0) }.prefix(7).map { $0 }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                DashboardBrandHeader(
                    userName: userName,
                    isSignedIn: isSignedIn,
                    showMenu: { showingHeaderMenu = true },
                    showNotifications: { showingNotifications = true }
                )

                connectionStatus

                WeshStatusBanner(
                    text: "نسخة 2 تقدم تجربة قرار جديدة: أوضح، أهدأ، وأكثر تركيزًا على الأسباب وجودة الأدلة.",
                    kind: .information
                )

                FeaturedDecisionCard(
                    question: questions.first,
                    openQuestion: {
                        if let question = questions.first {
                            openDecisionSummary(question)
                        }
                    },
                    startQuestion: { startQuestion(nil) }
                )

                if horizontalSizeClass == .regular {
                    regularDashboardColumns
                } else {
                    compactDashboardSections
                }
            }
            .padding(.horizontal, WeshTheme.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .weshContentWidth()
        }
        .background(AppBackground())
        .refreshable { await refresh() }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .navigationBar)
        .confirmationDialog("اختصارات", isPresented: $showingHeaderMenu, titleVisibility: .visible) {
            Button("مقارنة جديدة") { startQuestion(nil) }
            Button("مقارنة ذكية") { openSmartCompare() }
            if hasDraft {
                Button("استعادة المسودة") { restoreDraft() }
            }
            Button("إلغاء", role: .cancel) {}
        }
        .sheet(isPresented: $showingNotifications) {
            NavigationStack {
                WeshEmptyState(
                    title: "لا توجد إشعارات جديدة",
                    message: "ستظهر هنا تحديثات التصويت والتعليقات والتنبيهات المجدولة.",
                    systemImage: "bell"
                )
                .padding(24)
                .navigationTitle("الإشعارات")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var connectionStatus: some View {
        if isOffline {
            WeshStatusBanner(
                text: "تأكد من اتصالك بالإنترنت. نعرض آخر بيانات متاحة على الجهاز.",
                kind: .warning
            )
        } else if isRefreshing {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(WeshTheme.accent)
                Text("نحدّث المقارنات...")
                    .font(.subheadline)
                    .foregroundStyle(WeshTheme.secondaryText)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var compactDashboardSections: some View {
        Group {
            compactComparisonsSection
            quickActionsSection
            categoriesSection
            DashboardInsightsCard(statistics: statistics)
            highlightedItemsSection(adaptiveCards: true)
        }
    }

    @ViewBuilder
    private var compactComparisonsSection: some View {
        if questions.isEmpty {
            WeshEmptyState(
                title: "لا توجد مقارنات بعد",
                message: "ابدأ أول مقارنة، وحدد الخيارات التي تحتاج رأي الناس فيها.",
                systemImage: "bubble.left.and.bubble.right",
                actionTitle: "أنشئ مقارنة",
                action: { startQuestion(nil) }
            )
            .weshSurface()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                WeshSectionHeader(
                    "رحلات قرارك",
                    subtitle: "تابع المقارنات التي تحتاج حسمًا أو آراء أكثر",
                    systemImage: "point.topleft.down.curvedto.point.bottomright.up",
                    actionTitle: "عرض الكل",
                    action: openDiscover
                )
                ForEach(questions.prefix(3)) { question in
                    ReferenceComparisonRow(question: question) {
                        openQuestion(question)
                    }
                }
            }
        }
    }

    private var regularDashboardColumns: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 20) {
                DashboardInsightsCard(statistics: statistics, compact: true)
                categoriesSection
            }
            .frame(maxWidth: .infinity, alignment: .top)

            questionsSection(adaptiveCards: false)
                .frame(maxWidth: .infinity, alignment: .top)

            VStack(alignment: .leading, spacing: 20) {
                quickActionsSection
                highlightedItemsSection(adaptiveCards: false)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader("ابدأ بسرعة", subtitle: "أقصر طريق من الحيرة إلى صورة أوضح")
            DashboardQuickActions(
                hasDraft: hasDraft,
                startQuestion: { startQuestion(nil) },
                openSmartCompare: openSmartCompare,
                restoreDraft: restoreDraft
            )
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeshSectionHeader(
                "التصنيفات النشطة",
                subtitle: "استكشف المجالات الأكثر حضورًا في المكتبة",
                systemImage: "square.grid.2x2.fill"
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(activeCategories) { category in
                        ActiveCategoryCard(category: category)
                    }
                }
                .padding(.horizontal, 1)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func questionsSection(adaptiveCards: Bool) -> some View {
        if !questions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                WeshSectionHeader(
                    "قرارات بانتظار الحسم",
                    subtitle: "شاهد الاتجاه، ثم اقرأ الأسباب قبل أن تحسم",
                    systemImage: "clock.fill"
                )

                LazyVGrid(
                    columns: [GridItem(adaptiveCards ? .adaptive(minimum: 320) : .flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(questions.prefix(4)) { question in
                        DashboardQuestionCard(question: question) {
                            openQuestion(question)
                        }
                    }
                }
            }
        } else if !isRefreshing {
            WeshEmptyState(
                title: "لا توجد مقارنات بعد",
                message: "ابدأ أول مقارنة، وحدد الخيارات التي تحتاج رأي الناس فيها.",
                systemImage: "bubble.left.and.bubble.right",
                actionTitle: "أنشئ مقارنة",
                action: { startQuestion(nil) }
            )
            .weshSurface()
        }
    }

    @ViewBuilder
    private func highlightedItemsSection(adaptiveCards: Bool) -> some View {
        if !highlightedItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                WeshSectionHeader(
                    "مكتبة القرار",
                    subtitle: "حوّل عنصرًا من المكتبة إلى مقارنة خلال ثوانٍ",
                    systemImage: "bolt.fill"
                )

                LazyVGrid(
                    columns: [GridItem(adaptiveCards ? .adaptive(minimum: 180) : .flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(highlightedItems) { item in
                        KnowledgeCompactCard(item: item) {
                            startQuestion(item)
                        }
                    }
                }
            }
        }
    }
}

private struct ReferenceComparisonRow: View {
    let question: AskQuestion
    let open: () -> Void

    private var summary: DecisionSummary {
        DecisionSummaryService.makeSummary(for: question)
    }

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                WeshIconTile(
                    systemImage: question.category.systemImage,
                    color: WeshTheme.categoryColor(question.category),
                    size: 46
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(question.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WeshTheme.primaryText)
                        .lineLimit(2)
                    Text("\(question.totalVotes) صوتًا · \(summary.clarity.arabicTitle)")
                        .font(.caption2)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if summary.totalVotes > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(WeshTheme.accent)
                        .accessibilityHidden(true)
                }
                Image(systemName: "chevron.backward")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WeshTheme.secondaryText)
                    .accessibilityHidden(true)
            }
            .weshSurface(padding: 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("فتح مقارنة \(question.title)")
    }
}

struct DashboardInsightsCard: View {
    let statistics: DashboardStatistics
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if compact {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundStyle(WeshTheme.accent)
                        Text("ملخص النشاط")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(WeshTheme.primaryText)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    Text("الأرقام الحالية")
                        .font(.caption)
                        .foregroundStyle(WeshTheme.secondaryText)
                }
            } else {
                WeshSectionHeader(
                    "ملخص النشاط",
                    subtitle: "الأرقام الحالية داخل وش الرأي",
                    systemImage: "chart.bar.xaxis"
                )
            }

            LazyVGrid(columns: metricColumns, spacing: 12) {
                insightMetric(title: "المقارنات", value: statistics.totalComparisons, icon: "square.stack.3d.up.fill", color: WeshTheme.accent)
                insightMetric(title: "الأصوات", value: statistics.totalVotes, icon: "chart.bar.fill", color: WeshTheme.secondaryAccent)
                insightMetric(title: "الأسباب", value: statistics.totalReasons, icon: "quote.bubble.fill", color: WeshTheme.gold)
                insightMetric(title: "المحفوظة", value: statistics.savedCount, icon: "bookmark.fill", color: WeshTheme.success)
            }

            Divider().overlay(WeshTheme.hairline)

            if compact {
                VStack(alignment: .leading, spacing: 12) {
                    Label(statistics.topCategory.title, systemImage: statistics.topCategory.systemImage)
                        .font(.headline)
                        .foregroundStyle(WeshTheme.categoryColor(statistics.topCategory))
                    Text("التصنيف الأكثر نشاطًا")
                        .font(.caption)
                        .foregroundStyle(WeshTheme.secondaryText)

                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text("\(statistics.closeResultCount)")
                            .font(.title2.monospacedDigit().weight(.bold))
                            .foregroundStyle(WeshTheme.gold)
                        Text("مقارنة تحتاج آراء أكثر")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WeshTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        activeCategorySummary
                        Spacer(minLength: 8)
                        closeResultsSummary
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        activeCategorySummary
                        closeResultsSummary
                    }
                }
            }
        }
        .weshSurface(emphasized: true)
    }

    private var metricColumns: [GridItem] {
        if compact {
            return [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ]
        }
        return [GridItem(.adaptive(minimum: 135), spacing: 12)]
    }

    @ViewBuilder
    private func insightMetric(title: String, value: Int, icon: String, color: Color) -> some View {
        if compact {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                Text("\(value)")
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(WeshTheme.primaryText)
                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(WeshTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius))
            .accessibilityElement(children: .combine)
        } else {
            InsightMetric(title: title, value: "\(value)", icon: icon, color: color)
        }
    }

    private var activeCategorySummary: some View {
        HStack(alignment: .top, spacing: 12) {
            WeshIconTile(
                systemImage: statistics.topCategory.systemImage,
                color: WeshTheme.categoryColor(statistics.topCategory)
            )
            VStack(alignment: .leading, spacing: 4) {
                Text("الأكثر نشاطًا: \(statistics.topCategory.title)")
                    .font(.subheadline.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(statistics.mostVotedTitle)
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .lineLimit(2)
            }
        }
    }

    private var closeResultsSummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(statistics.closeResultCount)")
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(WeshTheme.gold)
            Text("تحتاج آراء أكثر")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(WeshTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(statistics.closeResultCount) مقارنة تحتاج آراء أكثر")
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
                        Label(mode.title, systemImage: mode.systemImage)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 40)
                            .foregroundStyle(selectedSortMode == mode ? .white : WeshTheme.primaryText)
                            .background(
                                selectedSortMode == mode ? WeshTheme.accent : WeshTheme.surface,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule().stroke(selectedSortMode == mode ? WeshTheme.accent : WeshTheme.hairline)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedSortMode == mode ? .isSelected : [])
                }
            }
            .padding(.horizontal, 1)
            .padding(.vertical, 4)
        }
    }
}
