import SwiftUI
import RoomPlan

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
                            roomCard(room)
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
                Button { showScanner = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Scanner une pièce")
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            RoomScanScreen().environmentObject(store)
        }
    }

    private func roomCard(_ room: RoomRecord) -> some View {
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
                if let count = room.objectCount {
                    Text("\(count) élément\(count > 1 ? "s" : "") détecté\(count > 1 ? "s" : "")")
                        .font(.caption2)
                        .foregroundStyle(Color.owniqSecondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.owniqSecondary)
        }
        .padding(14)
        .background(Color.owniqSurface, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
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
    @State private var cameraMode: RoomCameraMode = .threeD
    @State private var showDelete = false
    @State private var showRename = false
    @State private var renameValue = ""
    @State private var show2D = false
    @State private var show3D = false
    @State private var showObjects = false

    private var room: RoomRecord? {
        store.rooms.first(where: { $0.id == roomID })
    }

    private var capturedRoom: CapturedRoom? {
        guard let room else { return nil }
        return store.capturedRoom(for: room)
    }

    private var roomItems: [VaultItem] {
        store.items.filter { $0.roomID == roomID }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let room {
                SceneRoomView(
                    url: store.roomURL(for: room),
                    style: style,
                    cameraMode: cameraMode
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                controls(room)
            } else {
                ContentUnavailableView("Pièce introuvable", systemImage: "house.slash")
            }
        }
        .owniqBackground()
        .navigationTitle(room?.name ?? "Pièce")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { beginRename() } label: {
                        Label("Renommer", systemImage: "pencil")
                    }
                    Button { showObjects = true } label: {
                        Label("Objets de la pièce", systemImage: "shippingbox")
                    }
                    Button(role: .destructive) { showDelete = true } label: {
                        Label("Supprimer la pièce", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Renommer la pièce", isPresented: $showRename) {
            TextField("Nom", text: $renameValue)
            Button("Enregistrer") {
                if let room { store.renameRoom(room, to: renameValue) }
            }
            Button("Annuler", role: .cancel) {}
        }
        .confirmationDialog("Supprimer cette pièce ?", isPresented: $showDelete) {
            Button("Supprimer", role: .destructive) {
                if let room { store.deleteRoom(room) }
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        }
        .sheet(isPresented: $showObjects) { roomObjectsSheet }
        .fullScreenCover(isPresented: $show2D) {
            if let capturedRoom {
                Organize2DView(room: capturedRoom, roomID: roomID)
            }
        }
        .fullScreenCover(isPresented: $show3D) {
            if let capturedRoom {
                Organize3DView(room: capturedRoom, roomID: roomID)
            }
        }
    }

    private func controls(_ room: RoomRecord) -> some View {
        VStack(spacing: 11) {
            Picker("Style", selection: $style) {
                ForEach(RenderStyle.allCases) { renderStyle in
                    Text(renderStyle.rawValue).tag(renderStyle)
                }
            }
            .pickerStyle(.segmented)

            Picker("Vue", selection: $cameraMode) {
                ForEach(RoomCameraMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 9) {
                Image(systemName: helpIcon)
                    .foregroundStyle(Color.owniqSignal)
                Text(helpText)
                    .font(.caption)
                    .foregroundStyle(Color.owniqSecondary)
                Spacer()
            }

            if capturedRoom != nil {
                HStack(spacing: 10) {
                    Button { show2D = true } label: {
                        Label("Plan 2D", systemImage: "square.grid.3x3")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered)

                    Button { show3D = true } label: {
                        Label("Réagencer 3D", systemImage: "move.3d")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.owniqSignal)
                }
            } else {
                Text("Les anciens scans sans données RoomPlan restent visibles en 3D, mais leur réagencement n'est pas disponible.")
                    .font(.caption2)
                    .foregroundStyle(Color.owniqSecondary)
            }

            if let walls = room.wallCount {
                HStack {
                    Label("\(walls) murs", systemImage: "square.split.2x2")
                    Spacer()
                    Label("\(roomItems.count) objets liés", systemImage: "shippingbox")
                }
                .font(.caption)
                .foregroundStyle(Color.owniqSecondary)
            }
        }
        .padding(14)
        .background(Color.owniqSurface)
    }

    private var helpIcon: String {
        switch cameraMode {
        case .fps: "hand.draw"
        case .top: "arrow.up.and.down.and.arrow.left.and.right"
        case .threeD: "rotate.3d"
        }
    }

    private var helpText: String {
        switch cameraMode {
        case .fps: "1 doigt : haut/bas pour marcher · gauche/droite pour tourner"
        case .top: "Glisse pour déplacer le plan · pince pour zoomer · double-tape pour recentrer"
        case .threeD: "Glisse pour tourner autour · pince pour zoomer · double-tape pour recentrer"
        }
    }

    private func beginRename() {
        renameValue = room?.name ?? ""
        showRename = true
    }

    private var roomObjectsSheet: some View {
        NavigationStack {
            List {
                if roomItems.isEmpty {
                    ContentUnavailableView(
                        "Aucun objet lié",
                        systemImage: "shippingbox",
                        description: Text("Les objets détectés lors d'un nouveau scan RoomPlan apparaîtront ici.")
                    )
                } else {
                    ForEach(roomItems) { item in
                        NavigationLink {
                            VaultItemDetailView(itemID: item.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                Text(item.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Objets de la pièce")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { showObjects = false }
                }
            }
        }
        .environmentObject(store)
    }
}
