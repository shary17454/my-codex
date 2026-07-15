import SwiftUI
import UIKit

enum AppTab: Hashable {
    case home
    case map
    case compass
    case planner
    case community
    case tools
}

enum ScreenshotConfiguration {
    private static let environment = ProcessInfo.processInfo.environment

    static var initialTab: AppTab {
        switch environment["DESERTTRAIL_SCREENSHOT_TAB"]?.lowercased() {
        case "home":
            return .home
        case "map":
            return .map
        case "compass":
            return .compass
        case "planner":
            return .planner
        case "community":
            return .community
        case "tools":
            return .tools
        default:
            return .home
        }
    }

    static var initialMapLayer: DesertMapLayer {
        switch environment["DESERTTRAIL_MAP_LAYER"]?.lowercased() {
        case "ajaji":
            return .ajaji
        case "marked", "markedplans", "plans":
            return .markedPlans
        default:
            return .satellite
        }
    }

    static var initialAjajiImageIndex: Int {
        Int(environment["DESERTTRAIL_AJAJI_INDEX"] ?? "") ?? 1
    }

    static var showTripQR: Bool {
        environment["DESERTTRAIL_SHOW_QR"] == "1"
    }

    static var showActiveDrive: Bool {
        environment["DESERTTRAIL_SHOW_ACTIVE_DRIVE"] == "1"
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState: AppState
    @State private var selectedTab = ScreenshotConfiguration.initialTab

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeDashboardView(selectedTab: $selectedTab)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem {
                Label(appState.language == .arabic ? "الرئيسية" : "Home", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            NavigationStack {
                DesertMapView()
                    .navigationTitle(appState.text(.appTitle))
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            LanguagePicker(appState: appState)
                        }
                    }
            }
            .tabItem {
                Label(appState.text(.map), systemImage: "map")
            }
            .tag(AppTab.map)

            NavigationStack {
                CompassPanel()
                    .navigationTitle(appState.text(.compass))
            }
            .tabItem {
                Label(appState.text(.compass), systemImage: "safari")
            }
            .tag(AppTab.compass)

            NavigationStack {
                PlannerView()
                    .navigationTitle(appState.text(.planner))
            }
            .tabItem {
                Label(appState.language == .arabic ? "الرحلات" : "Trips", systemImage: "briefcase")
            }
            .tag(AppTab.planner)

            NavigationStack {
                CommunityView()
                    .navigationTitle(appState.text(.community))
            }
            .tabItem {
                Label(appState.text(.community), systemImage: "person.3")
            }
            .tag(AppTab.community)

            NavigationStack {
                AdvancedToolsView()
                    .navigationTitle(appState.language == .arabic ? "الأدوات" : "Tools")
            }
            .tabItem {
                Label(appState.language == .arabic ? "الأدوات" : "Tools", systemImage: "square.grid.2x2")
            }
            .tag(AppTab.tools)
        }
        .tint(.desertCopper)
        .environment(\.layoutDirection, appState.language == .arabic ? .rightToLeft : .leftToRight)
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
    }

}

private struct LanguagePicker: View {
    @Bindable var appState: AppState

    var body: some View {
        Menu {
            Picker("Language", selection: $appState.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
        } label: {
            Image(systemName: "globe")
                .font(.headline.weight(.semibold))
                .accessibilityLabel("Language")
        }
    }
}

extension Color {
    static let desertSand = Color(red: 0.95, green: 0.83, blue: 0.58)
    static let desertCopper = Color(red: 0.68, green: 0.36, blue: 0.14)
    static let desertRock = Color(red: 0.28, green: 0.24, blue: 0.20)
    static let oasisTeal = Color(red: 0.04, green: 0.45, blue: 0.48)
}
