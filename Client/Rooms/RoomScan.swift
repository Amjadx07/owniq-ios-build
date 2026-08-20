import SwiftUI
import RoomPlan

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

    func didReceive(_ newInstruction: RoomCaptureSession.Instruction) {
        switch newInstruction {
        case .moveCloseToWall:
            instruction = "Rapproche-toi d'un mur."
        case .moveAwayFromWall:
            instruction = "Recule légèrement."
        case .slowDown:
            instruction = "Ralentis."
        case .turnOnLight:
            instruction = "La pièce est sombre : augmente la lumière."
        case .lowTexture:
            instruction = "Zone difficile : vise davantage de détails."
        case .normal:
            break
        @unknown default:
            break
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

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

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
                if let error {
                    model.errorMessage = error.localizedDescription
                } else {
                    model.didPresent(processedResult)
                }
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
                topBar
                Spacer()
                if RoomCaptureSession.isSupported { hud }
            }
        }
        .foregroundStyle(.white)
        .onDisappear { model.cancel() }
        .alert(
            "Erreur",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var topBar: some View {
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
            .accessibilityLabel("Fermer")

            Spacer()

            OwnIQWordmark(compact: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())

            Spacer()
            Color.clear.frame(width: 46, height: 46)
        }
        .padding()
    }

    private var hud: some View {
        VStack(spacing: 13) {
            Image(systemName: model.processedRoom == nil ? "square.3.layers.3d" : "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.owniqSignal)

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
                    .accessibilityLabel("Progression du scan")
                    .accessibilityValue("\(model.coverage) pour cent")
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
                    Button("Recommencer") {
                        roomName = ""
                        model.restart()
                    }
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
                    .disabled(model.isProcessing)
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

            let cleanName = roomName.trimmingCharacters(in: .whitespacesAndNewlines)
            let record = RoomRecord(
                id: id,
                name: cleanName.isEmpty ? "Pièce \(store.rooms.count + 1)" : cleanName,
                usdzFilename: url.lastPathComponent
            )
            store.addRoom(record)

            let roomItems = room.objects.prefix(60).map { object in
                VaultItem(
                    name: RoomObjectNaming.name(object.category),
                    category: RoomObjectNaming.category(object.category),
                    confidence: RoomObjectNaming.confidence(object.confidence),
                    needsConfirmation: true,
                    roomID: id,
                    source: .room3D
                )
            }
            store.add(Array(roomItems))
            didSave = true
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
}

enum RoomObjectNaming {
    static func name(_ category: CapturedRoom.Object.Category) -> String {
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

    static func category(_ category: CapturedRoom.Object.Category) -> String {
        switch category {
        case .television: return "Informatique"
        case .oven, .refrigerator, .sink, .stove, .dishwasher: return "Cuisine"
        case .bed, .chair, .sofa, .storage, .table: return "Maison"
        default: return "Maison"
        }
    }

    static func confidence(_ confidence: CapturedRoom.Confidence) -> Double {
        switch confidence {
        case .high: return 0.90
        case .medium: return 0.65
        case .low: return 0.40
        @unknown default: return 0.40
        }
    }
}
