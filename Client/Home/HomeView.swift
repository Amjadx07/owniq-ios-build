import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    scannerCard
                    destinations
                    privacyNote
                }
                .padding(20)
            }
            .owniqBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            OwnIQWordmark()
            Spacer()
            Label("Privé", systemImage: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.owniqSecondary)
        }
        .padding(.bottom, 8)
    }

    private var scannerCard: some View {
        NavigationLink {
            ScanHubView()
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.owniqSignal.opacity(0.15))
                        Image(systemName: "viewfinder")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.owniqSignal)
                    }
                    .frame(width: 70, height: 70)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.headline.bold())
                        .foregroundStyle(Color.owniqSignal)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Scanner")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text("Un objet, plusieurs objets ou une pièce entière.")
                        .font(.body)
                        .foregroundStyle(Color.owniqSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.owniqSurface2, Color.owniqSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.owniqSignal.opacity(0.22), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Ouvre les modes de scan")
    }

    private var destinations: some View {
        HStack(spacing: 12) {
            NavigationLink {
                VaultView()
            } label: {
                destinationCard(
                    title: "Mes objets",
                    subtitle: "Inventaire",
                    icon: "shippingbox.fill",
                    accent: .owniqViolet
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                RoomLibraryView()
            } label: {
                destinationCard(
                    title: "Maison",
                    subtitle: "Pièces 3D",
                    icon: "house.fill",
                    accent: .owniqCoral
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func destinationCard(title: String, subtitle: String, icon: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Image(systemName: icon)
                .font(.title2.bold())
                .foregroundStyle(accent)
                .frame(width: 48, height: 48)
                .background(accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.owniqSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
        .padding(16)
        .background(Color.owniqSurface, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color.owniqSignal)
            Text("Cette version de test garde l'expérience complète. Le moteur propriétaire d'OWNIQ n'est pas publié : la reconnaissance utilise un fallback local Apple Vision et reste volontairement prudente.")
                .font(.caption)
                .foregroundStyle(Color.owniqSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }
}
