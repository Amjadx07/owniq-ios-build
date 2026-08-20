import SwiftUI

@main
struct OWNIQApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
