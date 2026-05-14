import SwiftUI

@main
struct DotRushApp: App {
    @StateObject private var livesManager = LivesManager()
    @StateObject private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(livesManager)
                .environmentObject(storeManager)
        }
    }
}
