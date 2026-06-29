import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: PartsStore

    var body: some View {
        TabView {
            PartsBrowserView()
                .tabItem {
                    Label("القطع", systemImage: "magnifyingglass")
                }

            SystemsView()
                .tabItem {
                    Label("الأنظمة", systemImage: "square.grid.2x2")
                }
        }
    }
}

struct PartsBrowserView: View {
    @EnvironmentObject private var store: PartsStore
    @State private var searchText = ""
    @State private var selectedSystemKey = "all"
    @State private var selectedYear = "all"
    @State private var selectedEngine = "all"
    @State private var selectedCondition = "all"

    private var availableYears: [Int] {
        Array(Set(store.parts.flatMap(\.compatibleYears))).sorted()
    }

    private var availableEngines: [String] {
        Array(Set(store.parts.flatMap(\.engineTags))).sorted()
    }

    private var filteredParts: [PartRecord] {
        store.parts.filter { part in
            let matchesSystem = selectedSystemKey == "all" || part.systemKey == selectedSystemKey
            let matchesYear = selectedYear == "all" || part.compatibleYears.contains(Int(selectedYear) ?? -1)
            let matchesEngine = selectedEngine == "all" || part.engineTags.contains(selectedEngine)
            let matchesCondition = selectedCondition == "all" || part.condition == selectedCondition
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return matchesSystem && matchesYear && matchesEngine && matchesCondition }
            let text = [
                part.partNumber,
                part.name,
                part.nameAr,
                part.unitTitle,
                part.systemNameAr,
                part.diagramCode
            ].joined(separator: " ").lowercased()
            return matchesSystem && matchesYear && matchesEngine && matchesCondition && text.contains(query.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let vehicle = store.vehicle {
                    Section {
                        VehicleSummaryCard(vehicle: vehicle, totalParts: store.parts.count)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                    }
                }

                Section {
                    Picker("النظام", selection: $selectedSystemKey) {
                        Text("كل الأنظمة").tag("all")
                        ForEach(store.systems) { system in
                            Text(system.nameAr).tag(system.key)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("السنة", selection: $selectedYear) {
                        Text("كل السنوات").tag("all")
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year)).tag(String(year))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("المحرك", selection: $selectedEngine) {
                        Text("كل المحركات").tag("all")
                        ForEach(availableEngines, id: \.self) { engine in
                            Text(engine).tag(engine)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("الحالة", selection: $selectedCondition) {
                        Text("كل الحالات").tag("all")
                        Text("أصلي OEM").tag("OEM")
                        Text("بعد السوق").tag("Aftermarket")
                        Text("مستخدم").tag("Used")
                    }
                    .pickerStyle(.segmented)
                }

                Section("النتائج: \(filteredParts.count)") {
                    ForEach(filteredParts) { part in
                        NavigationLink {
                            PartDetailView(part: part)
                        } label: {
                            PartRowView(part: part)
                        }
                    }
                }
            }
            .navigationTitle("قطع سفاري Y60")
            .searchable(text: $searchText, prompt: "ابحث برقم القطعة أو الاسم")
        }
    }
}

struct SystemsView: View {
    @EnvironmentObject private var store: PartsStore

    var body: some View {
        NavigationStack {
            List(store.systems) { system in
                NavigationLink {
                    SystemPartsView(system: system)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(system.nameAr)
                                .font(.headline)
                            Text(system.key)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(store.parts(for: system).count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("تصنيف الأنظمة")
        }
    }
}

struct SystemPartsView: View {
    @EnvironmentObject private var store: PartsStore
    let system: PartSystem

    var body: some View {
        List(store.parts(for: system)) { part in
            NavigationLink {
                PartDetailView(part: part)
            } label: {
                PartRowView(part: part)
            }
        }
        .navigationTitle(system.nameAr)
    }
}

struct PartDetailView: View {
    @EnvironmentObject private var store: PartsStore
    let part: PartRecord

    @State private var noteText = ""
    @State private var showingNoteSheet = false
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(part.partNumber)
                        .font(.title2.weight(.bold))
                        .textSelection(.enabled)
                    Text(part.nameAr)
                        .font(.headline)
                    Text(part.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Label(part.systemNameAr, systemImage: "shippingbox")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("بيانات القطعة") {
                DetailRow(title: "رقم المخطط", value: part.diagramCode)
                DetailRow(title: "الكمية", value: part.quantity)
                DetailRow(title: "التطبيق", value: part.application)
                DetailRow(title: "المواصفات", value: part.specification)
                DetailRow(title: "النطاق", value: part.dateRange)
                DetailRow(title: "سنوات التوافق", value: part.compatibleYears.map(String.init).joined(separator: ", "))
                DetailRow(title: "المحركات", value: part.engineTags.joined(separator: ", "))
                DetailRow(title: "حالة القطعة", value: part.condition)
                DetailRow(title: "الوحدة", value: part.unitTitle)
                DetailRow(title: "وصف الوحدة", value: part.unitInfo)
                DetailRow(title: "فهرس الوحدة", value: part.unitIndex.map(String.init) ?? "-")
            }

            if let sourceURL = URL(string: part.unitUrl), !part.unitUrl.isEmpty {
                Section("المصدر") {
                    Link(destination: sourceURL) {
                        Label("فتح صفحة المصدر", systemImage: "link")
                    }
                }
            }

            Section {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Label("إضافة صور", systemImage: "photo.badge.plus")
                }

                Button {
                    showingNoteSheet = true
                } label: {
                    Label("إضافة ملاحظة", systemImage: "note.text.badge.plus")
                }
            }

            Section("الصور") {
                let photos = store.photos(for: part.id)
                if photos.isEmpty {
                    ContentUnavailableRow(text: "لا توجد صور مضافة لهذه القطعة")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(photos) { photo in
                                VStack(alignment: .leading, spacing: 8) {
                                    if let uiImage = UIImage(contentsOfFile: store.photoURL(for: photo).path) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 170, height: 128)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                    Text(photo.createdAt.formatted(date: .numeric, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Button(role: .destructive) {
                                        store.deletePhoto(photo, from: part.id)
                                    } label: {
                                        Label("حذف", systemImage: "trash")
                                    }
                                    .font(.caption)
                                }
                                .frame(width: 170, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }

            Section("الملاحظات") {
                let notes = store.notes(for: part.id)
                if notes.isEmpty {
                    ContentUnavailableRow(text: "لا توجد ملاحظات بعد")
                } else {
                    ForEach(notes) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.text)
                            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                store.deleteNote(note, from: part.id)
                            } label: {
                                Label("حذف", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("تفاصيل القطعة")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNoteSheet) {
            NavigationStack {
                VStack {
                    TextEditor(text: $noteText)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .navigationTitle("ملاحظة جديدة")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("إلغاء") {
                            noteText = ""
                            showingNoteSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("حفظ") {
                            store.addNote(noteText, to: part.id)
                            noteText = ""
                            showingNoteSheet = false
                        }
                        .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .task(id: selectedItems) {
            guard !selectedItems.isEmpty else { return }
            let items = selectedItems
            selectedItems = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    try? store.addPhoto(data: data, to: part.id)
                }
            }
        }
    }
}

private struct VehicleSummaryCard: View {
    let vehicle: VehicleProfile
    let totalParts: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vehicle.name)
                .font(.headline)
            Text("شاصي: \(vehicle.chassisNumber)")
                .font(.subheadline)
            Text("الموديل: \(vehicle.modelCode)")
                .font(.subheadline)
            Text("المحرك: \(vehicle.engine) | القير: \(vehicle.transmission)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("إجمالي القطع المفهرسة: \(totalParts)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct PartRowView: View {
    @EnvironmentObject private var store: PartsStore
    let part: PartRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(part.partNumber)
                        .font(.headline.monospaced())
                    Text(part.nameAr)
                        .font(.subheadline.weight(.semibold))
                    Text(part.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(part.diagramCode)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Text(part.quantity.isEmpty ? "-" : "Qty \(part.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(part.unitTitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label(part.systemNameAr, systemImage: "square.grid.2x2")
                let content = store.partContent(for: part.id)
                Spacer()
                Label("\(content.notes.count)", systemImage: "note.text")
                Label("\(content.photos.count)", systemImage: "photo")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(value.isEmpty ? "-" : value)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}

private struct ContentUnavailableRow: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
    }
}
