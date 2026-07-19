import SwiftUI

struct DashboardBrandHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            WeshIconTile(systemImage: "checkmark.bubble.fill", color: WeshTheme.accent, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text("وش الرأي")
                    .font(.largeTitle.weight(.bold))
                Text("قارن، اسأل، وخذ قرارك على بينة")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DecisionLaunchPanel: View {
    let startQuestion: () -> Void
    let openSmartCompare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ما القرار الذي يشغلك اليوم؟")
                    .font(.title2.weight(.bold))
                Text("اطرح الخيارات للناس أو قارنها فورًا حسب السعر والجودة والاحتياج.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    launchButtons
                }
                VStack(spacing: 10) {
                    launchButtons
                }
            }
        }
        .weshSurface(padding: 18, emphasized: true)
    }

    @ViewBuilder
    private var launchButtons: some View {
        Button(action: startQuestion) {
            Label("مقارنة جديدة", systemImage: "plus")
        }
        .buttonStyle(WeshPrimaryButtonStyle())

        Button(action: openSmartCompare) {
            Label("قارن الآن", systemImage: "slider.horizontal.3")
        }
        .buttonStyle(WeshSecondaryButtonStyle())
    }
}

struct CategoryScroller: View {
    @Binding var selectedCategory: AskCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AskCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                            Label(category.title, systemImage: category.systemImage)
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            selectedCategory == category ? WeshTheme.accent : WeshTheme.surface,
                            in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius)
                        )
                        .foregroundStyle(selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct KnowledgeCompactCard: View {
    let item: KnowledgeItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: item.category.systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(WeshTheme.accent)
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                Text(item.strengths.prefix(2).joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .weshSurface()
        }
        .buttonStyle(.plain)
    }
}

struct KnowledgeRow: View {
    let item: KnowledgeItem
    let open: () -> Void
    let useItem: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: item.category.systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(WeshTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(WeshTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                        Spacer()
                        Text(item.dataQuality)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WeshTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(WeshTheme.accent.opacity(0.12), in: Capsule())
                    }
                    Text(item.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    if !item.specs.isEmpty {
                        Text(item.specs.keys.sorted().prefix(3).map { "\($0): \(item.specs[$0] ?? "")" }.joined(separator: "  •  "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            HStack {
                Button("التفاصيل", action: open)
                    .buttonStyle(.bordered)
                Button("اسأل عنه", action: useItem)
                    .buttonStyle(.borderedProminent)
            }
        }
        .weshSurface()
    }
}

struct DashboardQuestionCard: View {
    let question: AskQuestion
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 12) {
                WeshIconTile(systemImage: question.category.systemImage, color: WeshTheme.accent, size: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(question.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text("\(question.options.count) خيارات • \(question.totalVotes) تصويت")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .weshSurface(padding: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("فتح \(question.title)")
    }
}

struct InfoTile: View {
    let title: String
    let values: [String]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(values, id: \.self) { value in
                if let action {
                    Button {
                        action(value)
                    } label: {
                        FlowTagLabel(value: value, color: color)
                    }
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
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.12), in: Capsule())
            .foregroundStyle(color)
    }
}

struct BrowserShortcut: View {
    let title: String
    let query: String
    let action: (String) -> Void

    var body: some View {
        Button {
            action(query)
        } label: {
            Text(title)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct AppBackground: View {
    var body: some View {
        WeshTheme.canvas
            .ignoresSafeArea()
    }
}
