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
                .task {
                    WeatherService.scheduleBackgroundRefresh()
                }
        }
    }
}
