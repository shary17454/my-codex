import SwiftUI

struct EnvironmentBanner: View {
    @Environment(AppState.self) private var appState: AppState
    let report: EnvironmentalReport

    var body: some View {
        Button {
            Task {
                await appState.startLocationAndRefreshEnvironment(userInitiated: true)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: bannerIcon)
                    .font(.title3)
                    .foregroundStyle(bannerColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(bannerTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(bannerDetails)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                if appState.isEnvironmentRefreshing {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityHint("تحديث الطقس وجودة الهواء")
    }

    private var bannerIcon: String {
        guard report.isLiveData else { return "cloud.slash" }
        return report.airQualityIndex > 150 ? "exclamationmark.triangle.fill" : "sun.max.fill"
    }

    private var bannerColor: Color {
        guard report.isLiveData else { return .secondary }
        return report.airQualityIndex > 150 ? .red : .desertCopper
    }

    private var bannerTitle: String {
        if appState.isEnvironmentRefreshing { return "جاري تحديث الظروف" }
        if !report.isLiveData { return appState.environmentErrorMessage ?? "بيانات الطقس غير متاحة" }
        return report.alertText(language: appState.language)
    }

    private var bannerDetails: String {
        guard report.isLiveData else { return "اضغط للمحاولة عند توفر الإنترنت والموقع" }
        return "\(Int(report.temperatureCelsius.rounded()))°C  |  AQI \(report.airQualityDisplayText)  |  \(appState.text(.wind)) \(Int(report.windSpeedKPH.rounded())) km/h"
    }
}
