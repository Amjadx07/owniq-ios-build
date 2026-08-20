import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var preferences: PublicPreferences
    @EnvironmentObject private var appLock: PublicAppLock

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                OwnIQCard {
                    HStack(spacing: 15) {
                        ZStack {
                            Circle().fill(Color.owniqSignal.opacity(0.14))
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundStyle(Color.owniqSignal)
                        }
                        .frame(width: 68, height: 68)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mon OWNIQ")
                                .font(.title2.bold())
                            Text("Données locales sur cet appareil")
                                .font(.caption)
                                .foregroundStyle(Color.owniqSecondary)
                        }
                        Spacer()
                    }
                }

                HStack(spacing: 10) {
                    metric("\(store.items.count)", "Objets", "shippingbox.fill")
                    metric("\(store.rooms.count)", "Pièces", "house.fill")
                }

                OwnIQCard {
                    VStack(spacing: 0) {
                        NavigationLink { ProfileSettingsView() } label: {
                            row("Paramètres", icon: "slider.horizontal.3")
                        }
                        Divider().overlay(Color.white.opacity(0.08))
                        NavigationLink { PrivacyView() } label: {
                            row("Confidentialité", icon: "lock.shield.fill")
                        }
                        Divider().overlay(Color.white.opacity(0.08))
                        NavigationLink { StorageView() } label: {
                            row("Stockage", icon: "externaldrive.fill")
                        }
                        Divider().overlay(Color.white.opacity(0.08))
                        NavigationLink { AboutView() } label: {
                            row("À propos", icon: "info.circle.fill")
                        }
                    }
                }
            }
            .padding(18)
        }
        .owniqBackground()
        .navigationTitle("Profil")
    }

    private func metric(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(Color.owniqSignal)
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(Color.owniqSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color.owniqSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func row(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.owniqSignal)
                .frame(width: 28)
            Text(title).foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(Color.owniqSecondary)
        }
        .frame(minHeight: 54)
        .contentShape(Rectangle())
    }
}

struct ProfileSettingsView: View {
    @EnvironmentObject private var preferences: PublicPreferences
    @EnvironmentObject private var appLock: PublicAppLock

    var body: some View {
        Form {
            Section("Sécurité") {
                Toggle("Verrouiller OWNIQ", isOn: $appLock.enabled)
                Text("Utilise Face ID, Touch ID ou le code de l’iPhone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if appLock.enabled {
                    Button("Verrouiller maintenant") { appLock.lock() }
                }
            }

            Section("Apparence") {
                Picker("Thème", selection: $preferences.appearance) {
                    ForEach(PublicPreferences.Appearance.allCases) { appearance in
                        Text(appearance.rawValue).tag(appearance)
                    }
                }
            }

            Section("Interactions") {
                Toggle("Sons", isOn: $preferences.sounds)
                Toggle("Vibrations", isOn: $preferences.haptics)
                Toggle("Aide faible lumière", isOn: $preferences.nightAssist)
            }
        }
        .navigationTitle("Paramètres")
    }
}

struct PrivacyView: View {
    var body: some View {
        List {
            Section("Sur l’iPhone") {
                Label("Inventaire et métadonnées chiffrés en AES-GCM", systemImage: "lock.shield.fill")
                Label("Clé locale conservée dans le Trousseau iOS", systemImage: "key.fill")
                Label("Fichiers de pièces protégés par iOS", systemImage: "externaldrive.badge.shield.half.filled")
            }
            Section("Version publique de test") {
                Text("Le cerveau propriétaire OWNIQ n’est pas inclus. La reconnaissance de cette IPA repose sur Apple Vision et reste volontairement prudente.")
                Text("Aucune donnée marketplace live n’est revendiquée par cette version.")
            }
        }
        .navigationTitle("Confidentialité")
    }
}

struct StorageView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        List {
            Section("Contenu local") {
                LabeledContent("Objets", value: "\(store.items.count)")
                LabeledContent("Pièces 3D", value: "\(store.rooms.count)")
            }
            Section {
                Text("Supprimer un objet ou une pièce depuis son écran de détails supprime également son enregistrement local associé.")
            }
        }
        .navigationTitle("Stockage")
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                OwnIQWordmark()
                Text("OWNIQ 0.9.1 · client de test public")
                Text("Scanner — Mes objets — Maison")
                    .foregroundStyle(.secondary)
            }
            Section("3D") {
                Text("Le mode Réel exploite la géométrie et les matériaux disponibles dans RoomPlan. Il ne prétend pas recréer une photographie exacte de la pièce.")
                Text("Le mode Manga applique une stylisation locale à la géométrie disponible.")
            }
        }
        .navigationTitle("À propos")
    }
}
