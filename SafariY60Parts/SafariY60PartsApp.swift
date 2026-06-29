import SwiftUI

@main
struct SafariY60PartsApp: App {
    @StateObject private var store = PartsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
