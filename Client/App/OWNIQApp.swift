import SwiftUI

@main
struct OWNIQApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            OWNIQFinalAppShell()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
