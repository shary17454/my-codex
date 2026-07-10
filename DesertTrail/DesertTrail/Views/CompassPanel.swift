import SwiftUI
import CoreLocation

struct CompassPanel: View {
    @EnvironmentObject private var appState: AppState

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
                        .offset(y: -132)
                        .rotationEffect(.degrees(Double(tick) * 30))
                }

                VStack(spacing: 12) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.oasisTeal)
                        .rotationEffect(.degrees(headingDegrees))
                    Text("\(Int(normalizedHeading))°")
                        .font(.system(.largeTitle, design: .rounded).monospacedDigit().weight(.bold))
                    Text(directionName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 300, height: 300)

            permissionNotice

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    reading(title: appState.text(.altitude), value: altitudeText, icon: "mountain.2")
                    reading(title: appState.text(.windSpeed), value: "\(Int(appState.environmentalReport.windSpeedKPH)) km/h", icon: "wind")
                }
                GridRow {
                    reading(title: appState.text(.windDirection), value: "\(Int(appState.environmentalReport.windDirectionDegrees))°", icon: "arrow.up.right")
                    reading(title: appState.text(.magellan), value: appState.text(.gpxReady), icon: "point.topleft.down.curvedto.point.bottomright.up")
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
            } label: {
                Label("تفعيل تنبيهات قرب الأودية والخدمات", systemImage: "bell.badge")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .padding(.horizontal)
            }
        }
        .padding()
    }

    private var normalizedHeading: Double {
        appState.locationManager.heading?.trueHeading ?? appState.locationManager.heading?.magneticHeading ?? 0
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
            return "يستخدم التطبيق الموقع أثناء الاستخدام فقط، ويمكن تفعيل التحديث الدائم لتنبيهات الرحلات عند الحاجة."
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

    private func startCompassAndLocation() {
        if appState.locationManager.authorizationStatus == .notDetermined {
            appState.locationManager.requestWhenInUse()
        }
        appState.locationManager.startNavigation()
    }

    private var altitudeText: String {
        guard let altitude = appState.locationManager.currentLocation?.altitude else { return "-- m" }
        return "\(Int(altitude)) m"
    }

    private func reading(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.desertCopper)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
