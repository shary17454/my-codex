import SwiftUI

struct PlannerView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var showingQR = ScreenshotConfiguration.showTripQR
    @State private var showingCreateTrip = false
    @State private var newParticipant = ""

    var body: some View {
        @Bindable var appState = appState

        List {
                Section("الرحلات") {
                    if appState.trips.isEmpty {
                        ContentUnavailableView {
                            Label("لا توجد رحلات", systemImage: "map")
                        } description: {
                            Text("أنشئ رحلة باسمك وحدد وقتها، ثم اختر الوجهة من الخريطة أو المواقع المحفوظة.")
                        } actions: {
                            Button("إنشاء رحلة") {
                                showingCreateTrip = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.desertCopper)
                        }
                    }

                    ForEach(appState.trips) { trip in
                        Button {
                            appState.selectTrip(trip)
                            syncEditableTrip()
                        } label: {
                            TripListRow(trip: trip, isSelected: trip.id == appState.selectedTrip.id)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: appState.removeTrips)
                }

                if appState.hasSelectedTrip {
                    Section(appState.text(.tripDetails)) {
                        TextField(appState.text(.tripTitle), text: $appState.selectedTrip.title)
                            .textInputAutocapitalization(.words)
                            .onSubmit { appState.saveSelectedTrip() }

                        DatePicker(appState.text(.start), selection: $appState.selectedTrip.startDate)
                        DatePicker(appState.text(.end), selection: $appState.selectedTrip.endDate, in: appState.selectedTrip.startDate...)

                        TextField(appState.text(.packingNotes), text: $appState.selectedTrip.notes, axis: .vertical)
                            .lineLimit(3...5)

                        Text(String(format: "%.4f, %.4f", appState.selectedTrip.meetingPoint.latitude, appState.selectedTrip.meetingPoint.longitude))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    Section(appState.text(.participants)) {
                        HStack {
                            TextField("اسم مشارك جديد", text: $newParticipant)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .onSubmit(addParticipant)
                            Button(action: addParticipant) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newParticipant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        if appState.selectedTrip.participants.isEmpty {
                            Text("لم تتم إضافة مشاركين بعد")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(appState.selectedTrip.participants, id: \.self) { participant in
                            Label(participant, systemImage: "person.crop.circle")
                        }
                        .onDelete { offsets in
                            appState.removeParticipants(at: offsets)
                        }
                    }

                    Section(appState.text(.sharingPrivacy)) {
                        Toggle(appState.text(.shareConsent), isOn: $appState.consentedToTripSharing)
                        ShareLink(item: appState.selectedTrip.shareURL) {
                            Label(appState.text(.shareLink), systemImage: "square.and.arrow.up")
                        }
                        .disabled(!appState.consentedToTripSharing)

                        Button {
                            showingQR = true
                        } label: {
                            Label(appState.text(.showQR), systemImage: "qrcode")
                        }
                        .disabled(!appState.consentedToTripSharing)
                    }
                }
            }
            .navigationTitle(appState.text(.planner))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateTrip = true
                    } label: {
                        Label("إنشاء رحلة", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("حفظ") {
                        appState.saveSelectedTrip()
                    }
                    .disabled(!appState.hasSelectedTrip)
                }
            }
            .onChange(of: appState.selectedTrip) { _, _ in
                if appState.hasSelectedTrip {
                    appState.saveSelectedTrip()
                }
            }
            .onAppear {
                if ScreenshotConfiguration.showTripQR {
                    appState.consentedToTripSharing = true
                }
            }
            .sheet(isPresented: $showingQR) {
                TripQRSheet(trip: appState.selectedTrip, doneTitle: appState.text(.done)) {
                    showingQR = false
                }
            }
            .sheet(isPresented: $showingCreateTrip) {
                CreateTripSheet()
            }
    }

    private func addParticipant() {
        appState.addParticipant(newParticipant)
        newParticipant = ""
    }

    private func syncEditableTrip() {
        newParticipant = ""
    }
}

private struct TripListRow: View {
    let trip: TripPlan
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.desertCopper : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(trip.startDate.formatted(date: .abbreviated, time: .shortened)) - \(trip.endDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(trip.notes.isEmpty ? "بدون ملاحظات" : trip.notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text("\(trip.participants.count)")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.desertCopper.opacity(0.14), in: Capsule())
        }
        .contentShape(Rectangle())
    }
}

struct CreateTripSheet: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .hour, value: 8, to: .now) ?? .now
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("رحلة جديدة") {
                    TextField("اسم الرحلة (اختياري)", text: $title)
                    DatePicker("البداية", selection: $startDate)
                    DatePicker("النهاية", selection: $endDate)
                    TextField("ملاحظات الرحلة", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section {
                    Label("إذا تركت الاسم فارغًا سيستخدم التطبيق اسم رحلة جديد. سيتم استخدام موقعك الحالي إذا كان GPS متاحًا، وإلا تُستخدم الوجهة الافتراضية حتى تختار وجهة من الخريطة.", systemImage: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("إنشاء رحلة")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(appState.text(.cancel)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(appState.text(.done)) {
                        appState.createTrip(title: title, startDate: startDate, endDate: endDate, notes: notes)
                        dismiss()
                    }
                    .disabled(endDate < startDate)
                }
            }
            .onAppear {
                appState.locationManager.startNavigation()
            }
        }
    }
}

private struct TripQRSheet: View {
    let trip: TripPlan
    let doneTitle: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(trip.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            QRCodeGenerator.image(from: trip.shareURL.absoluteString)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 240, height: 240)
            Text(trip.shareURL.absoluteString)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(doneTitle, action: onDone)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.medium])
    }
}
