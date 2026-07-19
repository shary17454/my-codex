import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct ActiveTripDriveView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var isTripStarted = false
    @State private var followsUserLocation = true
    @State private var statusMessage: String?
    @State private var showingOfflineMaps = false
    @State private var showingAddPlace = false
    @State private var showingDestinationPicker = false
    @State private var showingSOS = false

    @State private var driveRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.6190, longitude: 46.5730),
        span: MKCoordinateSpan(latitudeDelta: 0.075, longitudeDelta: 0.075)
    )

    var body: some View {
        ZStack {
            Color.driveBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                brandHeader
                telemetryStrip

                ZStack {
                    mapStage
                    topFloatingTools
                    compassDial
                    sideControls
                    startTripButton
                    statusToast
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.driveBlack, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await appState.startLocationAndRefreshEnvironment()
            updateVisibleRegion()
        }
        .onChange(of: appState.locationManager.currentLocation?.timestamp) { _, _ in
            guard followsUserLocation else { return }
            updateVisibleRegion()
        }
        .onChange(of: appState.selectedTrip.meetingPoint) { _, _ in
            updateVisibleRegion()
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
        .sheet(isPresented: $showingOfflineMaps) {
            OfflineMapsView(region: driveRegion)
        }
        .sheet(isPresented: $showingAddPlace) {
            HiddenPlaceForm()
        }
        .sheet(isPresented: $showingDestinationPicker) {
            DestinationPickerSheet()
        }
        .sheet(isPresented: $showingSOS) {
            SOSView(coordinate: appState.locationManager.currentLocation?.coordinate ?? appState.selectedTrip.meetingPoint)
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 4) {
            Image(systemName: "mountain.2.fill")
                .font(.title2)
                .foregroundStyle(DrivePalette.goldGradient)
            Text(appState.text(.appTitle))
                .font(.title.weight(.black))
                .foregroundStyle(DrivePalette.goldGradient)
            Text("وضع الرحلة النشطة")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Color.driveBlack, Color(red: 0.16, green: 0.13, blue: 0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var telemetryStrip: some View {
        HStack(spacing: 0) {
            driveMetric("البطارية", batteryText, nil) {
                showStatus(batteryText == "--" ? "تعذر قراءة البطارية حاليًا" : "مستوى بطارية الجهاز: \(batteryText)")
            }
            driveDivider
            driveMetric("GPS", gpsText, gpsColor) {
                toggleTracking()
            }
            driveDivider
            driveMetric("المسافة", distanceText, nil) {
                openAppleMapsDirections()
            }
            driveDivider
            driveMetric("الارتفاع", altitudeText, nil) {
                appState.locationManager.startNavigation()
                showStatus(altitudeText == "--" ? "بانتظار قراءة ارتفاع دقيقة من GPS" : "الارتفاع الحالي \(altitudeText)")
            }
            driveDivider
            driveMetric("السرعة", speedText, nil) {
                appState.locationManager.startNavigation()
                showStatus(speedText == "--" ? "بانتظار حركة الجهاز وقراءة GPS" : "السرعة الحالية \(speedText)")
            }
        }
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.black.opacity(0.72))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(DrivePalette.goldGradient)
                        .frame(height: 1)
                }
        )
    }

    private var mapStage: some View {
        MapCanvasView(
            region: driveRegion,
            route: navigationRoute,
            places: appState.hiddenPlaces.filter { $0.status == .approved },
            tileTemplateURL: nil,
            tileOpacity: 0.7
        )
        .ignoresSafeArea(edges: .horizontal)
        .overlay {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color.clear,
                    Color.black.opacity(0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }

    private var topFloatingTools: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(spacing: 8) {
                    weatherPill
                    airQualityPill
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()
        }
    }

    private var weatherPill: some View {
        HStack(spacing: 8) {
            Image(systemName: weatherIcon)
                .foregroundStyle(Color.driveGold)
            Text(weatherText)
                .font(.headline.monospacedDigit())
        }
        .drivePill()
    }

    private var airQualityPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.circle")
                .foregroundStyle(airQualityColor)
            Text(airQualityText)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(airQualityColor)
        }
        .drivePill()
    }

    private var compassDial: some View {
        VStack {
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.58))
                        .overlay(Circle().stroke(DrivePalette.goldGradient, lineWidth: 2))
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(DrivePalette.goldGradient)
                        .opacity(headingDegrees == nil ? 0.32 : 1)
                        .rotationEffect(.degrees(headingDegrees ?? 0))
                    VStack {
                        Text("N")
                        Spacer()
                        Text("S")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(7)
                    HStack {
                        Text("W")
                        Spacer()
                        Text("E")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(7)
                }
                .environment(\.layoutDirection, .leftToRight)
                .frame(width: 74, height: 74)
                .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(headingAccessibilityText)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
    }

    private var sideControls: some View {
        HStack {
            VStack(spacing: 10) {
                driveRoundButton(icon: "location.fill", title: "موقعي") {
                    appState.locationManager.startNavigation()
                    followsUserLocation = true
                    updateVisibleRegion()
                    showStatus(appState.locationManager.currentLocation == nil ? "بانتظار إشارة GPS" : "تم توسيط الخريطة على موقعك")
                }
                driveRoundButton(icon: "exclamationmark.triangle.fill", title: "تنبيه") {
                    appState.locationManager.requestBackgroundTripUpdates()
                    showStatus("تنبيهات الأودية والخدمات مفعلة")
                }
                driveRoundButton(icon: "map.fill", title: "خرائط") {
                    showingOfflineMaps = true
                }
            }

            Spacer()

            VStack(spacing: 10) {
                driveRoundButton(icon: "arrow.up.right.navigation.fill", title: "اتجاه") {
                    appState.locationManager.startNavigation()
                    openAppleMapsDirections()
                }
                driveRoundButton(icon: "scope", title: "تتبع") {
                    followsUserLocation.toggle()
                    if followsUserLocation {
                        appState.locationManager.startNavigation()
                        updateVisibleRegion()
                    }
                    showStatus(followsUserLocation ? "متابعة الموقع مفعلة" : "يمكنك الآن تحريك الخريطة بحرية")
                }
                driveRoundButton(icon: "sos.circle.fill", title: "SOS") {
                    showingSOS = true
                    showStatus("تم فتح بطاقة الاستغاثة")
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 126)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var startTripButton: some View {
        VStack {
            Spacer()
            Button {
                isTripStarted.toggle()
                if isTripStarted {
                    appState.locationManager.startNavigation()
                    followsUserLocation = true
                    updateVisibleRegion()
                } else {
                    appState.locationManager.stopNavigation()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 34, weight: .bold))
                    Text(isTripStarted ? "إيقاف الرحلة" : "بدء الرحلة")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(Color.driveBlack)
                .frame(width: 104, height: 80)
                .background(
                    Circle()
                        .fill(DrivePalette.goldGradient)
                        .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 2))
                        .shadow(color: Color.driveGold.opacity(0.65), radius: 18)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 28)
        }
    }

    private var statusToast: some View {
        VStack {
            Spacer()
            if let statusMessage {
                Text(statusMessage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.76), in: Capsule())
                    .overlay(Capsule().stroke(Color.driveGold.opacity(0.5), lineWidth: 1))
                    .padding(.bottom, 118)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: statusMessage)
    }

    private var driveDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.16))
            .frame(width: 1, height: 38)
    }

    private var batteryText: String {
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return "--" }
        return "\(Int(level * 100))%"
    }

    private var gpsText: String {
        if appState.locationManager.authorizationStatus == .denied || appState.locationManager.authorizationStatus == .restricted {
            return "مرفوض"
        }
        guard appState.locationManager.isTracking else { return "متوقف" }
        guard let accuracy = appState.locationManager.horizontalAccuracyMeters else { return "يبحث" }
        if accuracy <= 10 { return "ممتاز" }
        if accuracy <= 30 { return "جيد" }
        return "ضعيف"
    }

    private var gpsColor: Color {
        guard appState.locationManager.isTracking else { return Color.driveGold }
        guard let accuracy = appState.locationManager.horizontalAccuracyMeters else { return .orange }
        return accuracy <= 30 ? .green : .orange
    }

    private var speedText: String {
        guard let speed = appState.locationManager.speedKPH else { return "--" }
        return "\(Int(speed.rounded())) كم/س"
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.altitudeMeters else { return "--" }
        return "\(Int(altitude.rounded())) م"
    }

    private var distanceText: String {
        guard let distance = appState.locationManager.distance(to: appState.selectedTrip.meetingPoint) else { return "--" }
        if distance < 1_000 { return "\(Int(distance.rounded())) م" }
        return String(format: "%.1f كم", distance / 1_000)
    }

    private var headingDegrees: Double? {
        appState.locationManager.resolvedHeadingDegrees
    }

    private var weatherIcon: String {
        guard appState.environmentalReport.isLiveData else { return "cloud.slash" }
        return appState.environmentalReport.windSpeedKPH > 35 ? "wind" : "cloud.sun.fill"
    }

    private var weatherText: String {
        guard appState.environmentalReport.isLiveData else { return "--°" }
        return "\(Int(appState.environmentalReport.temperatureCelsius.rounded()))°C"
    }

    private var airQualityText: String {
        guard appState.environmentalReport.isAirQualityAvailable else { return "AQI --" }
        return "AQI \(appState.environmentalReport.airQualityDisplayText)"
    }

    private var airQualityColor: Color {
        guard appState.environmentalReport.isAirQualityAvailable else { return .secondary }
        return appState.environmentalReport.airQualityIndex < 80 ? .green : .orange
    }

    private var headingAccessibilityText: String {
        guard let headingDegrees else { return "البوصلة بانتظار قراءة موثوقة" }
        return "اتجاه البوصلة \(Int(headingDegrees.rounded())) درجة"
    }

    private var navigationRoute: [CLLocationCoordinate2D] {
        guard let current = appState.locationManager.currentLocation?.coordinate else { return [] }
        return [current, appState.selectedTrip.meetingPoint]
    }

    private func driveMetric(
        _ title: String,
        _ value: String,
        _ valueColor: Color?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text(value)
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(valueColor ?? .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(value)")
    }

    private func driveRoundButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DrivePalette.goldGradient)
                    .frame(width: 42, height: 38)
                    .background(Circle().fill(Color.black.opacity(0.68)))
                    .overlay(Circle().stroke(Color.driveGold.opacity(0.64), lineWidth: 1))
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(width: 54, height: 54)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }

    private func toggleTracking() {
        if appState.locationManager.isTracking {
            appState.locationManager.stopNavigation()
            showStatus("تم إيقاف تحديث GPS")
        } else {
            appState.locationManager.startNavigation()
            showStatus("تم تشغيل تحديث GPS")
        }
    }

    private func updateVisibleRegion() {
        let destination = appState.selectedTrip.meetingPoint
        guard let current = appState.locationManager.currentLocation?.coordinate else {
            driveRegion = MKCoordinateRegion(
                center: destination,
                span: MKCoordinateSpan(latitudeDelta: 0.075, longitudeDelta: 0.075)
            )
            return
        }
        let center = CLLocationCoordinate2D(
            latitude: (current.latitude + destination.latitude) / 2,
            longitude: (current.longitude + destination.longitude) / 2
        )
        let latitudeDelta = max(abs(current.latitude - destination.latitude) * 1.45, 0.015)
        let longitudeDelta = max(abs(current.longitude - destination.longitude) * 1.45, 0.015)
        driveRegion = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: min(latitudeDelta, 90), longitudeDelta: min(longitudeDelta, 180))
        )
    }

    private func openAppleMapsDirections() {
        let destination = appState.selectedTrip.meetingPoint
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "daddr", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "dirflg", value: "d")
        ]
        guard let url = components?.url else {
            showStatus("تعذر تجهيز رابط الاتجاه")
            return
        }
        UIApplication.shared.open(url) { opened in
            if !opened {
                showStatus("تعذر فتح خرائط Apple")
            }
        }
    }
}

private struct DestinationPickerSheet: View {
    @Environment(AppState.self) private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var places: [HiddenPlace] {
        let approved = appState.hiddenPlaces.filter { $0.status == .approved }
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return approved }
        return approved.filter {
            $0.name.localizedCaseInsensitiveContains(cleanQuery) ||
            $0.notes.localizedCaseInsensitiveContains(cleanQuery)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("ابحث عن وجهة أو وادي أو جبل", text: $query)
                }

                Section("اختر وجهة التوجيه") {
                    ForEach(places) { place in
                        Button {
                            appState.setTripDestination(to: place)
                            appState.locationManager.startNavigation()
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: place.imageSystemName)
                                    .foregroundStyle(Color.driveGold)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(place.name)
                                        .font(.headline)
                                    Text(place.notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    Text(String(format: "%.4f, %.4f", place.coordinate.latitude, place.coordinate.longitude))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("تحديد الوجهة")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(appState.text(.done)) { dismiss() }
                }
            }
        }
    }
}

private enum DrivePalette {
    static let goldGradient = LinearGradient(
        colors: [
            Color(red: 0.91, green: 0.72, blue: 0.38),
            Color(red: 0.58, green: 0.39, blue: 0.18),
            Color(red: 0.98, green: 0.88, blue: 0.58)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private extension View {
    func drivePill() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.black.opacity(0.66), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.driveGold.opacity(0.36), lineWidth: 1))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.32), radius: 8, y: 4)
    }
}

extension Color {
    static let driveBlack = Color(red: 0.05, green: 0.045, blue: 0.04)
    static let driveGold = Color(red: 0.86, green: 0.64, blue: 0.30)
}
