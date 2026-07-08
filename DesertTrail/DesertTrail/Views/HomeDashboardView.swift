import CoreLocation
import MapKit
import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedTab: AppTab
    @State private var route = GPXParser.loadRoute(named: "SampleRoute")
    @State private var showingQR = false
    @State private var showingActiveTrip = false

    private let dashboardRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                mapHero
                tripMetricBar
                quickActions
                contentCards
                primaryActions
                communitySummary
                alertStrip
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(Color.desertBackground.ignoresSafeArea())
        .sheet(isPresented: $showingQR) {
            TripQRCodeSheet(trip: appState.selectedTrip)
        }
        .navigationDestination(isPresented: $showingActiveTrip) {
            ActiveTripDriveView()
        }
        .onAppear {
            if ScreenshotConfiguration.showActiveDrive {
                showingActiveTrip = true
            }
        }
        .task {
            let coordinate = appState.locationManager.currentLocation?.coordinate ?? appState.selectedTrip.meetingPoint
            appState.environmentalReport = await appState.weatherService.fetchReport(for: coordinate)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                selectedTab = .tools
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 3) {
                HStack(spacing: 8) {
                    Text(appState.text(.appTitle))
                        .font(.title2.weight(.bold))
                    Image(systemName: "mountain.2.fill")
                        .foregroundStyle(Color.desertCopper)
                }
                Text(appState.language == .arabic ? "رحلتك تبدأ من هنا" : "Your trail starts here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                selectedTab = .community
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                        .background(Color.white, in: Circle())
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 9, height: 9)
                        .offset(x: -7, y: 8)
                }
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.desertInk)
    }

    private var mapHero: some View {
        ZStack(alignment: .topTrailing) {
            MapCanvasView(
                region: dashboardRegion,
                route: route,
                places: appState.hiddenPlaces.filter { $0.status == .approved },
                tileTemplateURL: nil,
                tileOpacity: 0.7
            )
            .frame(height: 218)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 10) {
                mapToolButton("square.3.layers.3d")
                mapToolButton("location")
                mapToolButton("plus")
                mapToolButton("minus")
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)

            gpsPill
                .padding(12)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    scaleBar
                        .padding(12)
                }
            }
        }
        .frame(height: 218)
    }

    private var gpsPill: some View {
        HStack(spacing: 6) {
            Text(appState.language == .arabic ? "GPS قوي" : "Strong GPS")
                .font(.caption.weight(.bold))
            Circle()
                .fill(Color.green)
                .frame(width: 7, height: 7)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.62), in: Capsule())
    }

    private var scaleBar: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("1 كم")
                .font(.caption2.weight(.semibold))
            Rectangle()
                .fill(Color.desertInk)
                .frame(width: 70, height: 3)
        }
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var tripMetricBar: some View {
        HStack(spacing: 0) {
            dashboardMetric(title: "الاتجاه", value: headingText, subtitle: "315°", icon: "safari")
            Divider().frame(height: 54)
            dashboardMetric(title: "الارتفاع", value: altitudeText, subtitle: "متر", icon: "mountain.2")
            Divider().frame(height: 54)
            dashboardMetric(title: "السرعة", value: speedText, subtitle: "كم/س", icon: "speedometer")
            Divider().frame(height: 54)
            dashboardMetric(title: "المسافة", value: distanceText, subtitle: "كم", icon: "mappin")
            Divider().frame(height: 54)
            dashboardMetric(title: "حالة الموقع", value: "جيد", subtitle: "12/13", icon: "location.north")
        }
        .padding(.vertical, 14)
        .background(Color.desertPanel, in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.white)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            quickAction(title: "البوصلة", icon: "safari") { selectedTab = .compass }
            quickAction(title: "لوحة القيادة", icon: "speedometer") { showingActiveTrip = true }
            quickAction(title: "الطقس", icon: "cloud.sun.fill") { selectedTab = .tools }
            quickAction(title: "جودة الهواء", icon: "leaf.fill") { selectedTab = .tools }
            quickAction(title: "أدوات الرحلة", icon: "briefcase.fill") { selectedTab = .planner }
        }
    }

    private var contentCards: some View {
        HStack(alignment: .top, spacing: 12) {
            upcomingTripCard
            featuredPlaceCard
        }
    }

    private var upcomingTripCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("رحلاتي القادمة")
                        .font(.headline)
                    Image(systemName: "map")
                        .foregroundStyle(Color.desertCopper)
                }

                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.desertCopper.opacity(0.85), Color.desertSand.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "car.side.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(width: 82, height: 82)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("رحلة النفود الكبير")
                            .font(.subheadline.weight(.bold))
                        Label("الرياض - النفود", systemImage: "mappin")
                        Label("5 مشاركين", systemImage: "person.2")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                ProgressView(value: 0.6)
                    .tint(Color.desertCopper)

                Button {
                    showingActiveTrip = true
                } label: {
                    HStack {
                        Text("متابعة الرحلة")
                        Spacer()
                        Image(systemName: "arrow.left")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.desertCopper, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var featuredPlaceCard: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("اكتشف مواقع جديدة")
                        .font(.headline)
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Color.desertCopper)
                }

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.62, green: 0.38, blue: 0.18), Color(red: 0.96, green: 0.68, blue: 0.34)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("جبل عروق بني معارض")
                                .font(.subheadline.weight(.bold))
                            Text("منطقة خلابة")
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                        .padding(10)
                    }
                    .frame(height: 110)

                HStack {
                    Text("4.7")
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("(128)")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .font(.caption.weight(.semibold))
            }
        }
    }

    private var primaryActions: some View {
        HStack(spacing: 12) {
            Button {
                selectedTab = .planner
            } label: {
                Label("إنشاء رحلة جديدة", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DashboardActionButtonStyle())

            Button {
                showingQR = true
            } label: {
                Label("مشاركة رحلة", systemImage: "qrcode")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DashboardActionButtonStyle())
        }
    }

    private var communitySummary: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    HStack(spacing: -8) {
                        ForEach(["person.crop.circle.fill", "person.crop.circle", "person.crop.circle.badge.checkmark"], id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(Color.desertCopper)
                                .background(Color.white, in: Circle())
                        }
                    }
                    Text("+128")
                        .font(.caption.weight(.bold))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("المجتمع")
                            .font(.headline)
                        Text("شارك مواقعك وتجاربك مع رحالة رفيق الخلا")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    communityStat("المستخدمون", "12.4K", "person")
                    communityStat("المواقع", "2.1K", "mappin")
                    communityStat("الرحلات", "3.8K", "figure.hiking")
                    communityStat("النقاط", "18,760", "trophy")
                }
            }
        }
    }

    private var alertStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("تنبيهات مهمة", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Color.desertCopper)

            HStack(spacing: 8) {
                alertChip("جودة الهواء جيدة", "leaf.fill", .green)
                alertChip("رياح قوية", "wind", .orange)
                alertChip("ارتفاع حرارة", "thermometer.sun", .yellow)
                alertChip("احتمال سيول منخفض", "cloud.rain", .blue)
            }
        }
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
    }

    private var headingText: String {
        guard let heading = appState.locationManager.heading else { return "NW" }
        let value = heading.trueHeading > 0 ? heading.trueHeading : heading.magneticHeading
        return value > 0 ? "\(Int(value))°" : "NW"
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.currentLocation?.altitude else { return "842" }
        return "\(Int(altitude))"
    }

    private var speedText: String {
        guard let speed = appState.locationManager.currentLocation?.speed, speed > 0 else { return "32" }
        return "\(Int(speed * 3.6))"
    }

    private var distanceText: String {
        guard let current = appState.locationManager.currentLocation else { return "12.4" }
        let target = CLLocation(latitude: appState.selectedTrip.meetingPoint.latitude, longitude: appState.selectedTrip.meetingPoint.longitude)
        return String(format: "%.1f", current.distance(from: target) / 1000)
    }

    private func mapToolButton(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.headline)
            .foregroundStyle(Color.desertInk)
            .frame(width: 38, height: 38)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    private func dashboardMetric(title: String, value: String, subtitle: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.76))
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.92))
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, minHeight: 74)
    }

    private func quickAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.desertCopper)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.desertInk)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.horizontal, 4)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func communityStat(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline.weight(.bold).monospacedDigit())
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.desertCopper)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(Color.desertBackground, in: RoundedRectangle(cornerRadius: 8))
    }

    private func alertChip(_ title: String, _ icon: String, _ color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 6)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DashboardCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

private struct DashboardActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.desertInk)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(configuration.isPressed ? Color.desertSand.opacity(0.45) : Color.white, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

private struct TripQRCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let trip: TripPlan

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text(trip.title)
                    .font(.title3.weight(.bold))

                QRCodeGenerator.image(from: trip.shareURL.absoluteString)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8))

                Text(trip.shareURL.absoluteString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(Color.desertBackground)
            .navigationTitle("مشاركة الرحلة")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension Color {
    static let desertBackground = Color(red: 0.97, green: 0.94, blue: 0.88)
    static let desertInk = Color(red: 0.20, green: 0.14, blue: 0.09)
    static let desertPanel = Color(red: 0.26, green: 0.18, blue: 0.11).opacity(0.88)
}
