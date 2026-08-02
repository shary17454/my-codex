import SwiftUI

struct DashboardBrandHeader: View {
    let userName: String
    let isSignedIn: Bool
    let unreadNotificationCount: Int
    let showMenu: () -> Void
    let showNotifications: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: showMenu) {
                Image(systemName: "line.3.horizontal")
                    .frame(width: 44, height: 44)
                    .background(WeshTheme.surface.opacity(0.82), in: Circle())
            }
            .accessibilityLabel("القائمة")

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 5) {
                HStack(spacing: 8) {
                    Text("وش الرأي")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(WeshTheme.goldBright)
                    WeshDecisionLogo(size: 42)
                }
                Text(isSignedIn ? "قرارك أوضح، \(userName)" : "اسأل، قارن، ثم قرر بثقة")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WeshTheme.secondaryText)
                    .multilineTextAlignment(.trailing)
            }

            Button(action: showNotifications) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .frame(width: 44, height: 44)
                        .background(WeshTheme.surface.opacity(0.82), in: Circle())
                    if unreadNotificationCount > 0 {
                        Text("\(min(unreadNotificationCount, 9))")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(WeshTheme.destructive, in: Circle())
                            .offset(x: 3, y: -3)
                            .accessibilityLabel("\(unreadNotificationCount) إشعارات غير مقروءة")
                    }
                }
            }
            .accessibilityLabel("الإشعارات")
        }
        .font(.headline)
        .foregroundStyle(WeshTheme.primaryText)
        .frame(minHeight: 86)
        .accessibilityElement(children: .contain)
    }
}

struct WeshDecisionLogo: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(WeshTheme.surface.opacity(0.72))
            Circle()
                .stroke(WeshTheme.gold.opacity(0.52), lineWidth: 1)
            WeshCompassGlyph(size: size * 0.72, showsCheckmark: true)
        }
        .frame(width: size, height: size)
        .shadow(color: WeshTheme.gold.opacity(0.28), radius: 12)
        .accessibilityHidden(true)
    }
}

struct WeshDecisionSeal: View {
    var size: CGFloat = 104

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [WeshTheme.goldBright.opacity(0.28), WeshTheme.gold.opacity(0.08), .clear],
                        center: .center,
                        startRadius: 6,
                        endRadius: size * 0.72
                    )
                )
                .frame(width: size * 1.26, height: size * 1.26)
            Circle()
                .fill(WeshTheme.premiumSurface.opacity(0.62))
                .frame(width: size * 0.98, height: size * 0.98)
            Circle()
                .stroke(WeshTheme.gold.opacity(0.34), lineWidth: 1)
                .frame(width: size * 0.98, height: size * 0.98)
            WeshCompassGlyph(size: size * 0.84, showsCheckmark: true)
        }
        .frame(width: size, height: size)
        .shadow(color: WeshTheme.gold.opacity(0.32), radius: 18, y: 6)
        .accessibilityHidden(true)
    }
}

struct FeaturedDecisionCard: View {
    let question: AskQuestion?
    let openQuestion: () -> Void
    let startQuestion: () -> Void

    private var summary: DecisionSummary? {
        question.map(DecisionSummaryService.makeSummary)
    }

    private var winnerName: String? {
        guard let question,
              let summary,
              summary.totalVotes > 0,
              let winningOptionID = summary.winningOptionID else { return nil }
        return question.options.first(where: { $0.id == winningOptionID })?.title
    }

    var body: some View {
        ZStack {
            WeshTheme.decisionGradient
            .overlay(alignment: .topTrailing) {
                WeshCompassGlyph(size: 180)
                    .opacity(0.07)
                    .offset(x: -8, y: 6)
            }

            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("بوصلة القرار 2", systemImage: "location.north.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.goldBright)

                    Text(question?.title ?? "ابدأ قرارك الأول")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(WeshTheme.primaryText)
                        .lineLimit(3)

                    if let summary {
                        Text(
                            summary.totalVotes > 0
                                ? "بناءً على آراء \(summary.totalVotes) مشاركًا"
                                : "بانتظار أول الأصوات لإظهار الاتجاه"
                        )
                        .font(.caption)
                        .foregroundStyle(WeshTheme.secondaryText)

                        Text(summary.totalVotes > 0 ? "\(summary.leadingVotePercentage)%" : "—")
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .foregroundStyle(WeshTheme.goldBright)

                        Text(winnerName.map { "يفضلون \($0)" } ?? summary.clarity.arabicTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WeshTheme.secondaryText)
                            .lineLimit(2)

                        Button(action: openQuestion) {
                            HStack {
                                Text("اعرض ملخص القرار")
                                Spacer()
                                Image(systemName: "chevron.backward")
                            }
                        }
                        .buttonStyle(WeshSecondaryButtonStyle())
                        .accessibilityIdentifier("home.featuredDecision")
                    } else {
                        Text("اسأل، قارن، ثم شاهد بوصلة واضحة تجمع الأصوات والأسباب في قرار أسهل.")
                            .font(.subheadline)
                            .foregroundStyle(WeshTheme.secondaryText)
                        Button("أنشئ مقارنة", action: startQuestion)
                            .buttonStyle(WeshGoldButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                WeshDecisionSeal(size: 108)
                    .frame(maxWidth: 120)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: WeshTheme.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: WeshTheme.cardRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [WeshTheme.accent.opacity(0.48), WeshTheme.gold.opacity(0.28)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: WeshTheme.accent.opacity(0.12), radius: 18, y: 8)
        .accessibilityElement(children: .contain)
    }
}

struct DashboardQuickActions: View {
    let hasDraft: Bool
    let startQuestion: () -> Void
    let openSmartCompare: () -> Void
    let restoreDraft: () -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 105), spacing: 10)], spacing: 10) {
            QuickActionButton(title: "مقارنة جديدة", systemImage: "plus.bubble.fill", color: WeshTheme.accent, action: startQuestion)
            QuickActionButton(title: "مقارنة ذكية", systemImage: "slider.horizontal.3", color: WeshTheme.secondaryAccent, action: openSmartCompare)
            QuickActionButton(
                title: hasDraft ? "استعادة مسودة" : "لا توجد مسودة",
                systemImage: "doc.text.fill",
                color: WeshTheme.gold,
                isEnabled: hasDraft,
                action: restoreDraft
            )
        }
    }
}

private struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                WeshIconTile(systemImage: systemImage, color: color, size: 42)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isEnabled ? WeshTheme.primaryText : WeshTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 98, alignment: .topLeading)
            .weshSurface(padding: 14)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.68)
    }
}

struct CategoryScroller: View {
    @Binding var selectedCategory: AskCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(AskCategory.allCases) { category in
                    let color = WeshTheme.categoryColor(category)
                    Button {
                        selectedCategory = category
                    } label: {
                        Label(category.title, systemImage: category.systemImage)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 13)
                            .frame(minHeight: 42)
                            .background(
                                selectedCategory == category ? color : WeshTheme.surface,
                                in: Capsule()
                            )
                            .overlay {
                                Capsule().stroke(
                                    selectedCategory == category ? color : WeshTheme.hairline,
                                    lineWidth: 1
                                )
                            }
                            .foregroundStyle(selectedCategory == category ? .white : WeshTheme.primaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 1)
        }
    }
}

struct ActiveCategoryCard: View {
    let category: AskCategory

    var body: some View {
        let color = WeshTheme.categoryColor(category)
        HStack(spacing: 10) {
            WeshIconTile(systemImage: category.systemImage, color: color, size: 38)
            Text(category.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WeshTheme.primaryText)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(WeshTheme.surface, in: RoundedRectangle(cornerRadius: WeshTheme.controlRadius))
        .overlay { RoundedRectangle(cornerRadius: WeshTheme.controlRadius).stroke(WeshTheme.hairline) }
    }
}

struct KnowledgeCompactCard: View {
    let item: KnowledgeItem
    let action: () -> Void

    var body: some View {
        let color = WeshTheme.categoryColor(item.category)
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    WeshIconTile(systemImage: item.category.systemImage, color: color, size: 42)
                    Spacer()
                    Image(systemName: "arrow.up.left")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.secondaryText)
                }
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(WeshTheme.primaryText)
                    .lineLimit(2)
                Text(item.strengths.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(WeshTheme.secondaryText)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .weshSurface(padding: 15)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("ابدأ مقارنة عن \(item.name)")
    }
}

struct KnowledgeRow: View {
    let item: KnowledgeItem
    let open: () -> Void
    let useItem: () -> Void

    var body: some View {
        let color = WeshTheme.categoryColor(item.category)
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                WeshIconTile(systemImage: item.category.systemImage, color: color, size: 46)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(WeshTheme.primaryText)
                        Spacer(minLength: 8)
                        WeshPill(item.dataQuality, systemImage: "checkmark.shield", color: WeshTheme.accent)
                    }
                    Text(item.summary)
                        .font(.subheadline)
                        .foregroundStyle(WeshTheme.secondaryText)
                        .lineLimit(3)
                }
            }

            if !item.idealFor.isEmpty {
                Label("الأنسب لـ \(item.idealFor.prefix(2).joined(separator: "، "))", systemImage: "scope")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WeshTheme.secondaryText)
                    .lineLimit(2)
            }

            Text(item.strengths.prefix(3).joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(color)
                .lineLimit(2)

            HStack(spacing: 10) {
                Button(action: open) {
                    Label("التفاصيل", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(WeshSecondaryButtonStyle())
                Button(action: useItem) {
                    Label("إضافته لمقارنة", systemImage: "plus")
                }
                .buttonStyle(WeshPrimaryButtonStyle())
            }
        }
        .weshSurface()
    }
}

struct DashboardQuestionCard: View {
    let question: AskQuestion
    let open: () -> Void

    private var summary: DecisionSummary {
        DecisionSummaryService.makeSummary(for: question)
    }

    private var reasonCount: Int {
        question.comments.filter { $0.optionID != nil }.count
    }

    private var discussionCount: Int {
        question.comments.count - reasonCount
    }

    var body: some View {
        Button(action: open) {
            VStack(alignment: .leading, spacing: 14) {
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
                    .font(.headline)
                    .foregroundStyle(WeshTheme.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                VStack(spacing: 8) {
                    ForEach(question.options.prefix(2)) { option in
                        QuestionOptionMiniBar(option: option, totalVotes: question.totalVotes)
                    }
                }

                if question.options.count > 2 {
                    Text("+\(question.options.count - 2) خيارات")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.secondaryText)
                }

                HStack(spacing: 12) {
                    Label("\(question.totalVotes) مشاركًا", systemImage: "person.2.fill")
                    Label("\(reasonCount) سببًا", systemImage: "quote.bubble.fill")
                    if discussionCount > 0 {
                        Label("\(discussionCount) تعليقًا", systemImage: "text.bubble.fill")
                    }
                    Spacer(minLength: 0)
                }
                .font(.caption)
                .foregroundStyle(WeshTheme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

                HStack {
                    DecisionClarityPill(clarity: summary.clarity)
                    Spacer()
                    Image(systemName: "chevron.backward")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.secondaryText)
                }
            }
            .weshSurface()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("فتح مقارنة \(question.title)، \(summary.clarity.arabicTitle)")
    }
}

private struct QuestionOptionMiniBar: View {
    let option: PollOption
    let totalVotes: Int

    private var percent: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(option.votes) / Double(totalVotes)
    }

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(option.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WeshTheme.primaryText)
                    .lineLimit(1)
                Spacer()
                Text("\(Int((percent * 100).rounded()))%")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(WeshTheme.secondaryText)
            }
            ProgressView(value: percent)
                .tint(WeshTheme.accent)
        }
    }
}

struct DecisionClarityPill: View {
    let clarity: DecisionClarity

    private var color: Color {
        switch clarity {
        case .insufficientData: WeshTheme.secondaryText
        case .close: WeshTheme.gold
        case .leaning: WeshTheme.accentBright
        case .decisive: WeshTheme.accent
        }
    }

    private var title: String {
        switch clarity {
        case .insufficientData: "بيانات غير كافية"
        case .close: "نتيجة متقاربة"
        case .leaning: "ميل واضح"
        case .decisive: "نتيجة حاسمة"
        }
    }

    var body: some View {
        WeshPill(title, systemImage: clarity.systemImage, color: color)
    }
}

struct InfoTile: View {
    let title: String
    let values: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title)
                .font(.headline)
            FlowTags(values: values, color: color)
        }
        .weshSurface()
    }
}

struct FlowTags: View {
    let values: [String]
    let color: Color
    var action: ((String) -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(values, id: \.self) { value in
                if let action {
                    Button { action(value) } label: { FlowTagLabel(value: value, color: color) }
                        .buttonStyle(.plain)
                } else {
                    FlowTagLabel(value: value, color: color)
                }
            }
        }
    }
}

struct FlowTagLabel: View {
    let value: String
    let color: Color

    var body: some View {
        Text(value)
            .font(.caption.weight(.bold))
            .lineLimit(2)
            .minimumScaleFactor(0.76)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: WeshTheme.compactRadius))
            .overlay { RoundedRectangle(cornerRadius: WeshTheme.compactRadius).stroke(color.opacity(0.14)) }
            .foregroundStyle(color)
    }
}

struct BrowserShortcut: View {
    let title: String
    let query: String
    let action: (String) -> Void

    var body: some View {
        Button { action(query) } label: {
            Text(title)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(WeshTheme.surface, in: Capsule())
                .overlay { Capsule().stroke(WeshTheme.hairline) }
        }
        .buttonStyle(.plain)
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            WeshTheme.backgroundGradient
            RadialGradient(
                colors: [WeshTheme.gold.opacity(0.14), .clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 420
            )
            RadialGradient(
                colors: [WeshTheme.accent.opacity(0.16), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 520
            )
            LinearGradient(
                colors: [
                    WeshTheme.gold.opacity(0.05),
                    .clear,
                    WeshTheme.accent.opacity(0.05)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .allowsHitTesting(false)
        }
            .ignoresSafeArea()
    }
}
