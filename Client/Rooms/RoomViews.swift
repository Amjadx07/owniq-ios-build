import SwiftUI
import RoomPlan
import SceneKit

@MainActor
final class PublicRoomScanModel: ObservableObject {
    @Published var coverage = 0
    @Published var instruction = "Appuie sur Démarrer quand tu es prêt."
    @Published var isScanning = false
    @Published var isProcessing = false
    @Published var processedRoom: CapturedRoom?
    @Published var errorMessage: String?

    weak var captureView: RoomCaptureView?

    func attach(_ view: RoomCaptureView) {
        captureView = view
    }

    func start() {
        guard RoomCaptureSession.isSupported else {
            errorMessage = "RoomPlan nécessite un appareil LiDAR compatible."
            return
        }
        processedRoom = nil
        coverage = 0
        instruction = "Fais lentement le tour. Montre les murs, les coins et les meubles."
        isScanning = true
        isProcessing = false
        var configuration = RoomCaptureSession.Configuration()
        configuration.isCoachingEnabled = true
        captureView?.captureSession.run(configuration: configuration)
    }

    func restart() {
        captureView?.captureSession.stop()
        isScanning = false
        isProcessing = false
        processedRoom = nil
        coverage = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.start()
        }
    }

    func finish() {
        guard isScanning else { return }
        isScanning = false
        isProcessing = true
        instruction = "OWNIQ prépare la pièce 3D…"
        captureView?.captureSession.stop()
    }

    func cancel() {
        isScanning = false
        isProcessing = false
        captureView?.captureSession.stop()
    }

    func didUpdate(_ room: CapturedRoom) {
        let walls = min(58, room.walls.count * 14)
        let openings = min(18, (room.doors.count + room.windows.count + room.openings.count) * 4)
        let objects = min(18, room.objects.count * 2)
        coverage = min(95, walls + openings + objects + (room.walls.count >= 3 ? 8 : 0))

        if coverage < 35 {
            instruction = "Continue : montre les murs et les coins."
        } else if coverage < 65 {
            instruction = "Scanne plus haut, plus bas et autour des meubles."
        } else if coverage < 85 {
            instruction = "Complète les zones manquantes et les objets importants."
        } else {
            instruction = "Couverture élevée. Tu peux terminer."
        }
    }

    func didReceive(_ instruction: RoomCaptureSession.Instruction) {
        switch instruction {
        case .moveCloseToWall: self.instruction = "Rapproche-toi d'un mur."
        case .moveAwayFromWall: self.instruction = "Recule légèrement."
        case .slowDown: self.instruction = "Ralentis."
        case .turnOnLight: self.instruction = "La pièce est sombre : augmente la lumière."
        case .lowTexture: self.instruction = "Zone difficile : vise davantage de détails."
        case .normal: break
        @unknown default: break
        }
    }

    func didPresent(_ room: CapturedRoom) {
        processedRoom = room
        coverage = 100
        instruction = "La pièce est prête. Donne-lui un nom puis ajoute-la à Maison."
        isProcessing = false
    }
}

struct PublicRoomCaptureRepresentable: UIViewRepresentable {
    @ObservedObject var model: PublicRoomScanModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> RoomCaptureView {
        let view = RoomCaptureView(frame: .zero)
        view.isModelEnabled = true
        view.delegate = context.coordinator
        view.captureSession.delegate = context.coordinator
        model.attach(view)
        return view
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}

    @objc(OWNIQPublicRoomCaptureCoordinator)
    final class Coordinator: NSObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate {
        private var model: PublicRoomScanModel?

        init(model: PublicRoomScanModel) {
            self.model = model
            super.init()
        }

        required init?(coder: NSCoder) {
            self.model = nil
            super.init()
        }

        func encode(with coder: NSCoder) {}

        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            guard let model else { return }
            Task { @MainActor in model.didUpdate(room) }
        }

        func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
            guard let model else { return }
            Task { @MainActor in model.didReceive(instruction) }
        }

        func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?) {
            guard let model, let error else { return }
            Task { @MainActor in model.errorMessage = error.localizedDescription }
        }

        func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
            if let model, let error {
                Task { @MainActor in model.errorMessage = error.localizedDescription }
            }
            return true
        }

        func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
            guard let model else { return }
            Task { @MainActor in
                if let error { model.errorMessage = error.localizedDescription }
                else { model.didPresent(processedResult) }
            }
        }
    }
}

struct RoomScanScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @StateObject private var model = PublicRoomScanModel()
    @State private var roomName = ""
    @State private var didSave = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if RoomCaptureSession.isSupported {
                PublicRoomCaptureRepresentable(model: model)
                    .ignoresSafeArea()
            } else {
                unsupported
            }

            VStack(spacing: 0) {
                HStack {
                    Button {
                        model.cancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .frame(width: 46, height: 46)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                    OwnIQWordmark(compact: true)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                    Color.clear.frame(width: 46, height: 46)
                }
                .padding()

                Spacer()

                if RoomCaptureSession.isSupported {
                    hud
                }
            }
        }
        .foregroundStyle(.white)
        .onDisappear { model.cancel() }
        .alert("Erreur", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var hud: some View {
        VStack(spacing: 13) {
            Image(systemName: model.processedRoom == nil ? "square.3.layers.3d" : "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(model.processedRoom == nil ? Color.owniqSignal : Color.owniqSignal)

            Text(statusTitle)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(model.instruction)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)

            if model.isScanning || model.isProcessing {
                ProgressView(value: Double(model.coverage), total: 100)
                    .tint(Color.owniqSignal)
            }

            controls
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding()
    }

    private var statusTitle: String {
        if didSave { return "Pièce ajoutée" }
        if model.processedRoom != nil { return "La pièce est prête" }
        if model.isProcessing { return "Finalisation 3D…" }
        if model.isScanning { return "Bouge doucement dans la pièce" }
        return "Scanner une pièce"
    }

    @ViewBuilder
    private var controls: some View {
        if didSave {
            Button("Voir dans Maison") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(Color.owniqSignal)
        } else if model.processedRoom != nil {
            VStack(spacing: 10) {
                TextField("Nom de la pièce · ex. Salon", text: $roomName)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 13)
                    .frame(minHeight: 50)
                    .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(spacing: 10) {
                    Button("Recommencer") { roomName = ""; model.restart() }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                    Button("Ajouter") { saveRoom() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.owniqSignal)
                        .frame(maxWidth: .infinity)
                }
            }
        } else if model.isScanning {
            HStack(spacing: 10) {
                Button("Recommencer") { model.restart() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                Button("Terminer") { model.finish() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.owniqSignal)
                    .frame(maxWidth: .infinity)
            }
        } else {
            Button {
                model.start()
            } label: {
                Label("Démarrer", systemImage: "viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.owniqSignal)
        }
    }

    private var unsupported: some View {
        VStack(spacing: 14) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 52))
                .foregroundStyle(Color.owniqSecondary)
            Text("Scan 3D indisponible")
                .font(.title2.bold())
            Text("RoomPlan nécessite un appareil compatible LiDAR.")
                .foregroundStyle(Color.owniqSecondary)
                .multilineTextAlignment(.center)
            Button("Fermer") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(30)
    }

    @MainActor
    private func saveRoom() {
        guard let room = model.processedRoom else { return }
        let id = UUID()
        let url = store.newRoomURL(id: id)
        do {
            try? FileManager.default.removeItem(at: url)
            try room.export(to: url, exportOptions: .mesh)
            let clean = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
            let record = RoomRecord(id: id, name: clean.isEmpty ? "Pièce \(store.rooms.count + 1)" : clean, usdzFilename: url.lastPathComponent)
            store.addRoom(record)

            let roomItems = room.objects.prefix(60).map { object in
                VaultItem(
                    name: roomObjectName(object.category),
                    category: roomObjectCategory(object.category),
                    confidence: roomObjectConfidence(object.confidence),
                    needsConfirmation: true,
                    roomID: id,
                    source: .video
                )
            }
            store.add(Array(roomItems))
            didSave = true
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }

    private func roomObjectName(_ category: CapturedRoom.Object.Category) -> String {
        switch category {
        case .bathtub: return "Baignoire"
        case .bed: return "Lit"
        case .chair: return "Chaise"
        case .dishwasher: return "Lave-vaisselle"
        case .fireplace: return "Cheminée"
        case .oven: return "Four à confirmer"
        case .refrigerator: return "Réfrigérateur à confirmer"
        case .sink: return "Évier"
        case .sofa: return "Canapé"
        case .stairs: return "Escalier"
        case .storage: return "Rangement"
        case .stove: return "Plaque ou cuisinière à confirmer"
        case .table: return "Table"
        case .television: return "Télévision"
        case .toilet: return "Toilettes"
        case .washerDryer: return "Lave-linge ou sèche-linge à confirmer"
        @unknown default: return "Objet à confirmer"
        }
    }

    private func roomObjectCategory(_ category: CapturedRoom.Object.Category) -> String {
        switch category {
        case .television: return "Informatique"
        case .oven, .refrigerator, .sink, .stove, .dishwasher: return "Cuisine"
        case .bed, .chair, .sofa, .storage, .table: return "Maison"
        default: return "Maison"
        }
    }

    private func roomObjectConfidence(_ confidence: CapturedRoom.Confidence) -> Double {
        switch confidence {
        case .high: return 0.90
        case .medium: return 0.65
        case .low: return 0.40
        @unknown default: return 0.40
        }
    }
}

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
                Button { showScanner = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
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

    private var room: RoomRecord? { store.rooms.first(where: { $0.id == roomID }) }

    var body: some View {
        VStack(spacing: 0) {
            if let room {
                SceneRoomView(url: store.roomURL(for: room), style: style)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 12) {
                    Picker("Style", selection: $style) {
                        ForEach(RenderStyle.allCases) { Text($0.rawValue).tag($0) }
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
                Button(role: .destructive) { showDelete = true } label: { Image(systemName: "trash") }
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

struct SceneRoomView: UIViewRepresentable {
    let url: URL
    let style: RoomDetailView.RenderStyle

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = UIColor.black
        view.antialiasingMode = .multisampling4X
        view.autoenablesDefaultLighting = true
        view.allowsCameraControl = true
        render(in: view)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        if context.coordinatorStyle != style.rawValue {
            render(in: view)
            context.coordinatorStyle = style.rawValue
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var style = ""
    }

    private func render(in view: SCNView) {
        guard let scene = try? SCNScene(url: url, options: nil) else { return }
        if style == .manga {
            scene.rootNode.enumerateChildNodes { node, _ in
                guard let geometry = node.geometry else { return }
                for material in geometry.materials {
                    material.lightingModel = .lambert
                    material.roughness.contents = 1.0
                    material.metalness.contents = 0.0
                    material.shaderModifiers = [
                        .fragment: "#pragma body\n_output.color.rgb = floor(_output.color.rgb * 4.0 + 0.5) / 4.0;"
                    ]
                }
            }
            scene.background.contents = UIColor(red: 0.075, green: 0.065, blue: 0.10, alpha: 1)
        } else {
            scene.background.contents = UIColor(red: 0.045, green: 0.05, blue: 0.06, alpha: 1)
        }
        view.scene = scene
        view.prepare([scene], shouldAbortBlock: nil)
    }
}

private extension Context where Coordinator == SceneRoomView.Coordinator {
    var coordinatorStyle: String {
        get { coordinator.style }
        nonmutating set { coordinator.style = newValue }
    }
}
