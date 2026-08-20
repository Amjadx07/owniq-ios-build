import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ScannerView()
                .tabItem {
                    Label("Scanner", systemImage: "viewfinder")
                }

            ObjectsView()
                .tabItem {
                    Label("Mes objets", systemImage: "square.grid.2x2")
                }

            RoomsView()
                .tabItem {
                    Label("Maison", systemImage: "house")
                }
        }
        .tint(OwnIQTheme.accent)
    }
}

struct ProfileDestinationButton: View {
    var body: some View {
        NavigationLink {
            AboutView()
        } label: {
            Image(systemName: "person.crop.circle")
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Profil et informations")
    }
}
