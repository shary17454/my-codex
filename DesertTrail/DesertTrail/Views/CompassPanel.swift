import SwiftUI
import CoreLocation
import UIKit

struct CompassPanel: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var statusMessage: String?
    @State private var isRefreshingWeather = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.desertSand.opacity(0.9), .white], startPoint: .top, endPoint: .bottom))
                        .overlay(Circle().stroke(Color.desertCopper, lineWidth: 3))
                        .shadow(radius: 8)

                    ForEach(0..<12) { tick in
                        Rectangle()
                            .fill(tick % 3 == 0 ? Color.desertRock : Color.secondary)
                            .frame(width: tick % 3 == 0 ? 4 : 2, height: tick % 3 == 0 ? 24 : 12)
                            .offset(y: -122)
                            .rotationEffect(.degrees(Double(tick) * 30))
                    }

                    VStack(spacing: 10) {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 66))
                            .foregroundStyle(Color.oasisTeal)
                            .rotationEffect(.degrees(headingDegrees))
                        Text("\(Int(normalizedHeading))°")
                            .font(.system(.largeTitle, design: .rounded).monospacedDigit().weight(.bold))
                            .foregroundStyle(.primary)
                        Text(directionName)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 280, height: 280)
                .contentShape(Circle())
                .onTapGesture {
                    startCompassAndLocation()
                }

                permissionNotice

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.oasisTeal, in: Capsule())
                        .transition(.opacity.combined(with: .scale))
                }

                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        readingButton(title: appState.text(.altitude), value: altitudeText, icon: "mountain.2") {
                            startCompassAndLocation()
                            showStatus("تم تشغيل الموقع لتحديث الارتفاع")
                        }
                        readingButton(title: appState.text(.windSpeed), value: "\(Int(appState.environmentalReport.windSpeedKPH)) km/h", icon: "wind") {
                            refreshWeather()
                        }
                    }
                    GridRow {
                        readingButton(title: appState.text(.windDirection), value: "\(Int(appState.environmentalReport.windDirectionDegrees))°", icon: "arrow.up.right") {
                            refreshWeather()
                        }
                        readingButton(title: appState.text(.magellan), value: appState.text(.gpxReady), icon: "point.topleft.down.curvedto.point.bottomright.up") {
                            startCompassAndLocation()
                            showStatus("تم تجهيز بيانات GPX للتوجيه")
                        }
                    }
                }

                Button {
                    startCompassAndLocation()
                } label: {
                    Label(navigationButtonTitle, systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Button {
                    appState.locationManager.requestBackgroundTripUpdates()
                    showStatus("تم تفعيل تنبيهات القرب عند توفر الصلاحية")
                } label: {
                    Label("تفعيل تنبيهات قرب الأودية والخدمات", systemImage: "bell.badge")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .padding(.horizontal)
            }
            .padding(.bottom, 92)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.2), value: statusMessage)
        .onAppear {
            if appState.locationManager.authorizationStatus == .notDetermined {
                appState.locationManager.requestWhenInUse()
            } else if appState.locationManager.authorizationStatus == .authorizedWhenInUse || appState.locationManager.authorizationStatus == .authorizedAlways {
                appState.locationManager.startNavigation()
            }
        }
    }

    private var normalizedHeading: Double {
        guard let heading = appState.locationManager.heading else { return 0 }
        let value = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        return value >= 0 ? value : 0
    }

    private var headingDegrees: Double {
        -normalizedHeading
    }

    private var directionName: String {
        let directions = [
            appState.text(.north),
            appState.text(.northeast),
            appState.text(.east),
            appState.text(.southeast),
            appState.text(.south),
            appState.text(.southwest),
            appState.text(.west),
            appState.text(.northwest)
        ]
        let index = Int((normalizedHeading + 22.5) / 45.0) % directions.count
        return directions[index]
    }

    private var permissionNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: permissionIcon)
                .foregroundStyle(permissionColor)
        VStack(alignment: .leading, spacing: 3) {
                Text(permissionTitle)
                    .font(.caption.weight(.bold))
                Text(headingAccuracyText)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(permissionColor)
                Text(permissionMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(permissionColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }

    private var permissionTitle: String {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined:
            return "تفعيل الموقع والبوصلة"
        case .restricted, .denied:
            return "الموقع غير مفعل"
        default:
            return appState.locationManager.isTracking ? "البوصلة تعمل" : "جاهز للتشغيل"
        }
    }

    private var permissionMessage: String {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined:
            return "اضغط زر التشغيل للسماح بالموقع وتحديث الاتجاه والارتفاع أثناء الرحلة."
        case .restricted, .denied:
            return "فعّل صلاحية الموقع من إعدادات iOS حتى تظهر بيانات الارتفاع والاتجاه بدقة."
        default:
            return appState.locationManager.heading == nil ? "حرّك الجهاز على شكل 8 بعيداً عن المعادن، ثم اضغط القرص أو زر التشغيل." : "يستخدم التطبيق الموقع أثناء الاستخدام فقط، ويمكن تفعيل التحديث الدائم لتنبيهات الرحلات عند الحاجة."
        }
    }

    private var permissionIcon: String {
        switch appState.locationManager.authorizationStatus {
        case .restricted, .denied: return "location.slash"
        case .notDetermined: return "location.badge.questionmark"
        default: return "location.fill"
        }
    }

    private var permissionColor: Color {
        switch appState.locationManager.authorizationStatus {
        case .restricted, .denied: return .red
        case .notDetermined: return .orange
        default: return .oasisTeal
        }
    }

    private var navigationButtonTitle: String {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined:
            return "السماح بالموقع وتشغيل البوصلة"
        case .restricted, .denied:
            return "صلاحية الموقع مطلوبة"
        default:
            return appState.text(.startNavigationTools)
        }
    }

    private var headingAccuracyText: String {
        guard let heading = appState.locationManager.heading else { return "لم تصل قراءة الاتجاه بعد" }
        guard heading.headingAccuracy >= 0 else { return "تحتاج البوصلة إلى معايرة" }
        return "دقة الاتجاه ±\(Int(heading.headingAccuracy))°"
    }

    private func startCompassAndLocation() {
        switch appState.locationManager.authorizationStatus {
        case .notDetermined:
            appState.locationManager.requestWhenInUse()
            appState.locationManager.startNavigation()
            showStatus("تم طلب صلاحية الموقع")
        case .restricted, .denied:
            openAppSettings()
        default:
            appState.locationManager.startNavigation()
            showStatus("تم تشغيل البوصلة والتتبع")
        }
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.currentLocation?.altitude else { return "-- m" }
        return "\(Int(altitude)) m"
    }

    private func refreshWeather() {
        guard !isRefreshingWeather else { return }
        isRefreshingWeather = true
        showStatus("جاري تحديث الرياح والطقس")
        Task {
            let coordinate = appState.locationManager.currentLocation?.coordinate ?? appState.selectedTrip.meetingPoint
            appState.environmentalReport = await appState.weatherService.fetchReport(for: coordinate)
            isRefreshingWeather = false
            showStatus("تم تحديث بيانات الرياح")
        }
    }

    private func openAppSettings() {
        showStatus("افتح الإعدادات وفعّل الموقع للتطبيق")
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func showStatus(_ message: String) {
        statusMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if statusMessage == message {
                statusMessage = nil
            }
        }
    }

    private func readingButton(title: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(Color.desertCopper)
                    Spacer()
                    if isRefreshingWeather && (icon == "wind" || icon == "arrow.up.right") {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(value)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title): \(value)")
    }
}
