import SwiftUI

@main
struct OWNIQApp: App {
    @StateObject private var store = PublicStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
