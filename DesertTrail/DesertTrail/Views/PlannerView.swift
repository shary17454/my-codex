import SwiftUI

struct PlannerView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var startDate = TripPlan.sample.startDate
    @State private var endDate = TripPlan.sample.endDate
    @State private var notes = TripPlan.sample.notes
    @State private var showingQR = ScreenshotConfiguration.showTripQR

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section(appState.text(.tripDetails)) {
                TextField(appState.text(.tripTitle), text: $appState.selectedTrip.title)
                DatePicker(appState.text(.start), selection: $startDate)
                DatePicker(appState.text(.end), selection: $endDate)
                TextField(appState.text(.packingNotes), text: $notes, axis: .vertical)
                    .lineLimit(3...5)
            }

            Section(appState.text(.participants)) {
                ForEach(appState.selectedTrip.participants, id: \.self) { participant in
                    Label(participant, systemImage: "person.crop.circle")
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
        .onChange(of: startDate) { _, newValue in
            appState.selectedTrip.startDate = newValue
        }
        .onChange(of: endDate) { _, newValue in
            appState.selectedTrip.endDate = newValue
        }
        .onChange(of: notes) { _, newValue in
            appState.selectedTrip.notes = newValue
        }
        .onAppear {
            if ScreenshotConfiguration.showTripQR {
                appState.consentedToTripSharing = true
            }
        }
        .sheet(isPresented: $showingQR) {
            VStack(spacing: 20) {
                Text(appState.selectedTrip.title)
                    .font(.title2.weight(.bold))
                QRCodeGenerator.image(from: appState.selectedTrip.shareURL.absoluteString)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                Text(appState.selectedTrip.shareURL.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button(appState.text(.done)) {
                    showingQR = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }
}
