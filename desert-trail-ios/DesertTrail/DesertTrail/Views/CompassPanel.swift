import SwiftUI

struct CompassPanel: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
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
                appState.locationManager.startNavigation()
            } label: {
                Label(appState.text(.startNavigationTools), systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Spacer()
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
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
