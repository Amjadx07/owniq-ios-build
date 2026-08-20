import SwiftUI

@main
struct OWNIQApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = AppStore()
    @StateObject private var preferences = PublicPreferences()
    @StateObject private var appLock = PublicAppLock()

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .environmentObject(store)
                    .environmentObject(preferences)
                    .environmentObject(appLock)

                if appLock.enabled && !appLock.isUnlocked {
                    PublicLockedView()
                        .environmentObject(appLock)
                        .zIndex(100)
                }
            }
            .preferredColorScheme(preferences.colorScheme)
            .task { await appLock.authenticate() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await appLock.authenticate() }
                } else {
                    appLock.lock()
                }
            }
        }
    }
}

private struct PublicLockedView: View {
    @EnvironmentObject private var appLock: PublicAppLock

    var body: some View {
        ZStack {
            Color.owniqBackground.ignoresSafeArea()
            VStack(spacing: 18) {
                OwnIQWordmark()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.owniqSignal)
                Text("OWNIQ est verrouillé")
                    .font(.title.bold())
                Text("Déverrouille pour voir tes objets et tes pièces.")
                    .foregroundStyle(Color.owniqSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await appLock.authenticate() }
                } label: {
                    Label("Déverrouiller", systemImage: "faceid")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.owniqSignal)

                if let error = appLock.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color.owniqSecondary)
                }
            }
            .padding(28)
        }
    }
}
