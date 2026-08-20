import SwiftUI

struct RoomLibraryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showScanner = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.rooms.isEmpty ? "Aucune pièce" : "\(store.rooms.count) pièce\(store.rooms.count > 1 ? "s" : "")")
                            .font(.title2.bold())
                        Text("Scans 3D enregistrés sur l'appareil")
                            .font(.caption)
                            .foregroundStyle(Color.owniqSecondary)
                    }
                    Spacer()
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundStyle(Color.owniqCoral)
                }

                if store.rooms.isEmpty {
                    ContentUnavailableView(
                        "Aucune pièce scannée",
                        systemImage: "cube.transparent",
                        description: Text("Scanne une pièce compatible LiDAR pour créer sa vue 3D.")
                    )
                    .frame(minHeight: 320)
                } else {
                    ForEach(store.rooms) { room in
                        NavigationLink {
                            RoomDetailView(roomID: room.id)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "cube.transparent.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.owniqCoral)
                                    .frame(width: 54, height: 54)
                                    .background(Color.owniqCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(room.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(room.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(Color.owniqSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.owniqSecondary)
                            }
                            .padding(14)
                            .background(Color.owniqSurface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(18)
        }
        .owniqBackground()
        .navigationTitle("Maison")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScanner = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Scanner une pièce")
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            RoomScanScreen()
                .environmentObject(store)
        }
    }
}

struct RoomDetailView: View {
    enum RenderStyle: String, CaseIterable, Identifiable {
        case real = "Réel"
        case manga = "Manga"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let roomID: UUID

    @State private var style: RenderStyle = .real
    @State private var showDelete = false

    private var room: RoomRecord? {
        store.rooms.first(where: { $0.id == roomID })
    }

    var body: some View {
        VStack(spacing: 0) {
            if let room {
                SceneRoomView(url: store.roomURL(for: room), style: style)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 12) {
                    Picker("Style", selection: $style) {
                        ForEach(RenderStyle.allCases) { renderStyle in
                            Text(renderStyle.rawValue).tag(renderStyle)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Label("Glisse pour tourner", systemImage: "rotate.3d")
                        Spacer()
                        Label("Pince pour zoomer", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                    .font(.caption)
                    .foregroundStyle(Color.owniqSecondary)
                }
                .padding(14)
                .background(Color.owniqSurface)
            } else {
                ContentUnavailableView("Pièce introuvable", systemImage: "house.slash")
            }
        }
        .owniqBackground()
        .navigationTitle(room?.name ?? "Pièce")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Supprimer cette pièce ?", isPresented: $showDelete) {
            Button("Supprimer", role: .destructive) {
                if let room { store.deleteRoom(room) }
                dismiss()
            }
        }
    }
}
