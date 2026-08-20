import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section("OWNIQ") {
                LabeledContent("Version", value: "0.9.1")
                LabeledContent("Build", value: "10")
            }

            Section("Build public") {
                Text("Cette version sert à tester l’interface iPhone et la chaîne de compilation. Les moteurs propriétaires de reconnaissance, de prix et d’intelligence restent privés.")
                    .font(.body)
            }

            Section("Confidentialité") {
                Label("Aucune clé privée intégrée", systemImage: "key.slash")
                Label("Aucun moteur propriétaire publié", systemImage: "lock.shield")
            }
        }
        .navigationTitle("Informations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
