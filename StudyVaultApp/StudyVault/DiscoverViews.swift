import SwiftUI
import WebKit

struct QuestionListView: View {
    let questions: [AskQuestion]
    @Binding var selectedCategory: AskCategory
    @Binding var selectedSortMode: QuestionSortMode
    @Binding var searchText: String
    @Binding var selectedQuestion: AskQuestion?
    @Binding var showingComposer: Bool
    let refresh: () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                WeshSectionHeader(
                    "استكشف المقارنات",
                    subtitle: "ابحث حسب المنتج أو المجال، ثم رتّب النتائج بالطريقة المناسبة لك",
                    systemImage: "sparkle.magnifyingglass"
                )

                CategoryScroller(selectedCategory: $selectedCategory)
                SortModePicker(selectedSortMode: $selectedSortMode)

                if questions.isEmpty {
                    ContentUnavailableView(
                        "لا توجد نتائج",
                        systemImage: "magnifyingglass",
                        description: Text("غيّر عبارة البحث أو اختر مجالًا آخر.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    Text("\(questions.count) نتيجة")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(questions) { question in
                        Button {
                            selectedQuestion = question
                        } label: {
                            QuestionRow(question: question)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .weshContentWidth()
        }
        .background(AppBackground())
        .refreshable {
            await refresh()
        }
        .navigationTitle("اكتشف")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "ابحث عن منتج أو سؤال")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingComposer = true
                } label: {
                    Label("سؤال جديد", systemImage: "plus.bubble.fill")
                }
            }
        }
    }
}
struct KnowledgeLibraryView: View {
    let items: [KnowledgeItem]
    @Binding var selectedCategory: AskCategory
    @Binding var searchText: String
    @Binding var selectedItem: KnowledgeItem?
    let useItem: (KnowledgeItem) -> Void
    let openResearch: () -> Void
    let refresh: () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                WeshSectionHeader(
                    "دليل الخيارات",
                    subtitle: "معلومات منظمة تساعدك على صياغة مقارنة أدق",
                    systemImage: "books.vertical.fill"
                )

                CategoryScroller(selectedCategory: $selectedCategory)

                if items.isEmpty {
                    ContentUnavailableView(
                        "لا توجد عناصر",
                        systemImage: "books.vertical",
                        description: Text("غيّر البحث أو المجال لعرض عناصر أخرى.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 10)], spacing: 10) {
                        ForEach(items) { item in
                            KnowledgeRow(item: item) {
                                selectedItem = item
                            } useItem: {
                                useItem(item)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .weshContentWidth()
        }
        .background(AppBackground())
        .refreshable {
            await refresh()
        }
        .navigationTitle("المكتبة")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "ابحث عن جوال، سيارة، مطعم...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: openResearch) {
                    Label("بحث خارجي", systemImage: "safari")
                }
            }
        }
    }
}

private enum ResearchBrowserDefaults {
    static let searchURLString = "https://www.google.com/search?q=%D9%85%D9%82%D8%A7%D8%B1%D9%86%D8%A9+%D8%A7%D9%84%D9%85%D9%86%D8%AA%D8%AC%D8%A7%D8%AA"
    static let searchURL = URL(string: searchURLString) ?? URL(filePath: "/")
}

struct ResearchBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var address = ResearchBrowserDefaults.searchURLString
    @State private var activeURL = ResearchBrowserDefaults.searchURL

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    TextField("ابحث أو اكتب رابط", text: $address)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .submitLabel(.go)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(loadAddress)

                    Button(action: loadAddress) {
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("فتح")
                }

                HStack {
                    BrowserShortcut(title: "جوالات", query: "مقارنة أفضل جوالات") { openSearch($0) }
                    BrowserShortcut(title: "سيارات", query: "مقارنة سيارات اقتصادية") { openSearch($0) }
                    BrowserShortcut(title: "مطاعم", query: "أفضل مطاعم قريبة") { openSearch($0) }
                }
            }
            .padding()
            .background(.background)

            WebView(url: activeURL)
                .clipShape(RoundedRectangle(cornerRadius: WeshTheme.cornerRadius))
                .padding([.horizontal, .bottom], 12)
        }
        .navigationTitle("متصفح المقارنة")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppBackground())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("إغلاق") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Link(destination: activeURL) {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("فتح في Safari")
            }
        }
    }

    private func loadAddress() {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let url = URL(string: trimmed), url.scheme == "https" || url.scheme == "http" {
            activeURL = url
            return
        }

        openSearch(trimmed)
    }

    private func openSearch(_ query: String) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.google.com/search?q=\(encoded)"
        address = urlString
        activeURL = URL(string: urlString) ?? ResearchBrowserDefaults.searchURL
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }
}


struct KnowledgeDetailView: View {
    let item: KnowledgeItem
    let useItem: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(item.category.title, systemImage: item.category.systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WeshTheme.accent)
                    Text(item.name)
                        .font(.title.weight(.bold))
                    Text(item.summary)
                        .foregroundStyle(.secondary)
                }

                InfoTile(title: "نقاط قوة", values: item.strengths, color: WeshTheme.success)
                InfoTile(title: "انتبه لها", values: item.considerations, color: WeshTheme.highlight)
                InfoTile(title: "مناسب لمن", values: item.idealFor, color: WeshTheme.secondaryAccent)

                if !item.specs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("بطاقة بيانات")
                                .font(.headline)
                            Spacer()
                            Text(item.dataQuality)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(WeshTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(WeshTheme.accent.opacity(0.12), in: Capsule())
                        }

                        ForEach(item.specs.keys.sorted(), id: \.self) { key in
                            HStack(alignment: .top) {
                                Text(key)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 16)
                                Text(item.specs[key] ?? "")
                                    .font(.subheadline.weight(.bold))
                                    .multilineTextAlignment(.leading)
                            }
                            Divider()
                        }
                    }
                    .weshSurface()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("سؤال مقترح")
                        .font(.headline)
                    Text(item.suggestedQuestion)
                        .font(.title3.weight(.semibold))
                }
                .weshSurface()

                Button {
                    useItem()
                } label: {
                    Label("استخدم في مقارنة جديدة", systemImage: "plus.bubble.fill")
                }
                .buttonStyle(WeshPrimaryButtonStyle())
            }
            .padding(16)
            .weshContentWidth()
        }
        .background(AppBackground())
        .navigationTitle("تفاصيل")
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
