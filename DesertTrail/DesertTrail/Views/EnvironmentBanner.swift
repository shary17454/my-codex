import SwiftUI

struct EnvironmentBanner: View {
    @Environment(AppState.self) private var appState: AppState
    let report: EnvironmentalReport

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: report.airQualityIndex > 150 ? "exclamationmark.triangle.fill" : "sun.max.fill")
                .font(.title3)
                .foregroundStyle(report.airQualityIndex > 150 ? .red : .desertCopper)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.alertText(language: appState.language))
                    .font(.subheadline.weight(.semibold))
                Text("\(Int(report.temperatureCelsius))°C  |  AQI \(report.airQualityIndex)  |  \(appState.text(.wind)) \(Int(report.windSpeedKPH)) km/h")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
