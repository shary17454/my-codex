import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct ActiveTripDriveView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var route = GPXParser.loadRoute(named: "SampleRoute")
    @State private var isTripStarted = false
    @State private var statusMessage: String?

    private let driveRegion = MKCoordinateRegion(
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
                    routeNodes
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
        }
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
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
            driveMetric("الزعامة", batteryText, nil)
            driveDivider
            driveMetric("GPS", gpsText, gpsColor)
            driveDivider
            driveMetric("المسافة المتبقية", distanceText, nil)
            driveDivider
            driveMetric("الارتفاع", altitudeText, nil)
            driveDivider
            driveMetric("السرعة", speedText, nil)
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
            route: route,
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
        .overlay {
            TripGlowPath()
                .stroke(
                    LinearGradient(
                        colors: [.clear, Color.driveGold, Color.white.opacity(0.94), Color.driveGold],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: Color.driveGold.opacity(0.9), radius: 12)
                .padding(.horizontal, 28)
                .padding(.vertical, 60)
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
            Text("\(Int(appState.environmentalReport.temperatureCelsius))°C")
                .font(.headline.monospacedDigit())
        }
        .drivePill()
    }

    private var airQualityPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "leaf.circle")
                .foregroundStyle(.green)
            Text(appState.environmentalReport.airQualityIndex < 80 ? "Good" : "تنبيه")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(appState.environmentalReport.airQualityIndex < 80 ? .green : .orange)
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
                    Image(systemName: "safari.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(DrivePalette.goldGradient)
                        .rotationEffect(.degrees(headingDegrees))
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
                .frame(width: 74, height: 74)
                .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
    }

    private var routeNodes: some View {
        ZStack {
            driveNode(icon: "house.fill", x: 0.70, y: 0.25)
            driveNode(icon: "fuelpump.fill", x: 0.50, y: 0.42)
            driveNode(icon: "wrench.and.screwdriver.fill", x: 0.64, y: 0.55)
            driveNode(icon: "tent.fill", x: 0.36, y: 0.63)
            driveNode(icon: "mappin", x: 0.72, y: 0.74)
            driveNode(icon: "flag.fill", x: 0.18, y: 0.37, emphasized: true)
        }
        .allowsHitTesting(false)
    }

    private var sideControls: some View {
        HStack {
            VStack(spacing: 10) {
                driveRoundButton(icon: "location.fill", title: "موقعي") {
                    appState.locationManager.requestWhenInUse()
                    appState.locationManager.startNavigation()
                    showStatus("تم طلب صلاحية الموقع")
                }
                driveRoundButton(icon: "exclamationmark.triangle.fill", title: "تنبيه") {
                    appState.locationManager.requestBackgroundTripUpdates()
                    showStatus("تنبيهات الأودية والخدمات مفعلة")
                }
                driveRoundButton(icon: "map.fill", title: "خرائط") {
                    showStatus("وضع الخريطة")
                }
            }

            Spacer()

            VStack(spacing: 10) {
                driveRoundButton(icon: "arrow.up.right.navigation.fill", title: "اتجاه") {
                    appState.locationManager.startNavigation()
                    showStatus("تم تشغيل التوجيه")
                }
                driveRoundButton(icon: "scope", title: "تتبع") {
                    appState.locationManager.startNavigation()
                    showStatus("تم تشغيل التتبع")
                }
                driveRoundButton(icon: "sos.circle.fill", title: "SOS") {
                    showStatus("تم تجهيز طلب SOS عند الحاجة")
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 142)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var startTripButton: some View {
        VStack {
            Spacer()
            Button {
                isTripStarted.toggle()
                if isTripStarted {
                    appState.locationManager.startNavigation()
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
        guard level >= 0 else { return "87%" }
        return "\(Int(level * 100))%"
    }

    private var gpsText: String {
        appState.locationManager.isTracking ? "Green" : "جاهز"
    }

    private var gpsColor: Color {
        appState.locationManager.isTracking ? .green : Color.driveGold
    }

    private var speedText: String {
        guard let speed = appState.locationManager.currentLocation?.speed, speed > 0 else { return "65 km/h" }
        return "\(Int(speed * 3.6)) km/h"
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.currentLocation?.altitude else { return "840 m" }
        return "\(Int(altitude)) m"
    }

    private var distanceText: String {
        guard let current = appState.locationManager.currentLocation else { return "127 km" }
        let target = CLLocation(latitude: appState.selectedTrip.meetingPoint.latitude, longitude: appState.selectedTrip.meetingPoint.longitude)
        return String(format: "%.0f km", current.distance(from: target) / 1000)
    }

    private var headingDegrees: Double {
        guard let heading = appState.locationManager.heading else { return 315 }
        let value = heading.trueHeading > 0 ? heading.trueHeading : heading.magneticHeading
        return value > 0 ? value : 315
    }

    private var weatherIcon: String {
        appState.environmentalReport.windSpeedKPH > 35 ? "wind" : "cloud.sun.fill"
    }

    private func driveMetric(_ title: String, _ value: String, _ valueColor: Color?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.74))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(valueColor ?? .white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
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
            .frame(width: 58, height: 56)
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

    private func driveNode(icon: String, x: CGFloat, y: CGFloat, emphasized: Bool = false) -> some View {
        GeometryReader { proxy in
            Image(systemName: icon)
                .font(.system(size: emphasized ? 20 : 14, weight: .bold))
                .foregroundStyle(emphasized ? Color.driveBlack : Color.driveGold)
                .frame(width: emphasized ? 48 : 34, height: emphasized ? 48 : 34)
                .background(Circle().fill(emphasized ? Color.driveGold : Color.black.opacity(0.64)))
                .overlay(Circle().stroke(Color.driveGold.opacity(0.7), lineWidth: 1))
                .shadow(color: emphasized ? Color.driveGold.opacity(0.7) : .black.opacity(0.4), radius: emphasized ? 13 : 6)
                .position(x: proxy.size.width * x, y: proxy.size.height * y)
        }
    }
}

private struct TripGlowPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.maxY - rect.height * 0.10))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY - rect.height * 0.34),
            control1: CGPoint(x: rect.minX + rect.width * 0.07, y: rect.maxY - rect.height * 0.22),
            control2: CGPoint(x: rect.minX + rect.width * 0.24, y: rect.maxY - rect.height * 0.25)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.55, y: rect.maxY - rect.height * 0.48),
            control1: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY - rect.height * 0.45),
            control2: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.maxY - rect.height * 0.36)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.maxY - rect.height * 0.62),
            control1: CGPoint(x: rect.minX + rect.width * 0.66, y: rect.maxY - rect.height * 0.60),
            control2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.maxY - rect.height * 0.47)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.maxY - rect.height * 0.86),
            control1: CGPoint(x: rect.minX + rect.width * 0.86, y: rect.maxY - rect.height * 0.75),
            control2: CGPoint(x: rect.minX + rect.width * 0.77, y: rect.maxY - rect.height * 0.79)
        )
        return path
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
