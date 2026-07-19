import SwiftUI
import BackgroundTasks

@main
struct DesertTrailApp: App {
    @State private var appState = AppState()

    init() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: WeatherService.backgroundTaskIdentifier, using: nil) { task in
            WeatherService.handleBackgroundRefresh(task: task)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(\.layoutDirection, appState.language == .arabic ? .rightToLeft : .leftToRight)
                .preferredColorScheme(appState.appearance.colorScheme)
                .task {
                    WeatherService.scheduleBackgroundRefresh()
                }
        }
    }
}

private extension AppAppearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
