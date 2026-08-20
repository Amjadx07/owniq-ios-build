import SwiftUI

struct RoomsView: View {
    @EnvironmentObject private var store: PublicStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if store.rooms.isEmpty {
                        OwnIQCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Image(systemName: "house")
                                    .font(.system(size: 38, weight: .semibold))
                                    .foregroundStyle(OwnIQTheme.accent)
                                    .accessibilityHidden(true)

                                Text("Ta maison, simplement")
                                    .font(.title2.bold())

                                Text("Ajoute une pièce pour tester le parcours. La reconstruction 3D avancée reste dans le cœur privé d’OWNIQ.")
                                    .foregroundStyle(.secondary)

                                Button {
                                    store.addRoom()
                                } label: {
                                    Label("Ajouter une pièce", systemImage: "plus")
                                }
                                .buttonStyle(PrimaryActionButtonStyle())
                            }
                        }
                    } else {
                        ForEach(store.rooms) { room in
                            OwnIQCard {
                                HStack(spacing: 14) {
                                    Image(systemName: "door.left.hand.open")
                                        .font(.title2)
                                        .foregroundStyle(OwnIQTheme.accent)
                                        .frame(width: 44, height: 44)
                                        .background(OwnIQTheme.softAccent, in: RoundedRectangle(cornerRadius: 12))
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(room.name)
                                            .font(.headline)
                                        Text("Prête pour le futur scan de pièce")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }

                        Button {
                            store.addRoom()
                        } label: {
                            Label("Ajouter une autre pièce", systemImage: "plus")
                        }
                        .buttonStyle(PrimaryActionButtonStyle())
                    }
                }
                .padding(20)
            }
            .navigationTitle("Maison")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileDestinationButton()
                }
            }
        }
    }
}
