import SwiftUI
import AVFoundation
import UIKit

struct VideoScanView: View {
    struct ReviewObject: Identifiable, Hashable {
        let id: UUID
        var name: String
        var category: String
        var confidence: Double?
        var selected: Bool
        var manual: Bool

        init(guess: VisionGuess) {
            id = UUID()
            name = guess.name
            category = guess.category
            confidence = guess.confidence
            selected = true
            manual = false
        }

        init(name: String, category: String = "Autres") {
            id = UUID()
            self.name = name
            self.category = category
            confidence = nil
            selected = true
            manual = true
        }
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var isRunning = true
    @State private var objects: [ReviewObject] = []
    @State private var seenKeys: Set<String> = []
    @State private var removed: [ReviewObject] = []
    @State private var showManualAdd = false
    @State private var manualName = ""
    @State private var manualCategory = "Autres"
    @State private var editingID: UUID?
    @State private var editName = ""
    @State private var editCategory = "Autres"
    @State private var didSave = false

    private var selectedCount: Int { objects.filter(\.selected).count }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LiveVideoScanner(isRunning: isRunning) { guess in
                receive(guess)
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.62), .clear, .black.opacity(0.86)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                topBar
                Spacer()
                if isRunning { livePanel } else { reviewPanel }
                controls
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .onDisappear { isRunning = false }
        .alert("Ajouter un objet", isPresented: $showManualAdd) {
            TextField("Ex. Airfryer Ninja", text: $manualName)
            TextField("Catégorie", text: $manualCategory)
            Button("Ajouter") { addManual() }
                .disabled(manualName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Annuler", role: .cancel) { manualName = "" }
        } message: {
            Text("Ajoute ce qu'OWNIQ n'a pas reconnu. Tu pourras encore corriger le nom avant de garder le scan.")
        }
        .alert("Corriger l'objet", isPresented: Binding(
            get: { editingID != nil },
            set: { if !$0 { editingID = nil } }
        )) {
            TextField("Nom", text: $editName)
            TextField("Catégorie", text: $editCategory)
            Button("Enregistrer") { applyCorrection() }
                .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Annuler", role: .cancel) { editingID = nil }
        } message: {
            Text("Le nom suffit dans la plupart des cas.")
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Fermer")

            Spacer()

            VStack(spacing: 2) {
                Text(isRunning ? "Scanner des objets" : "Vérifier le scan")
                    .font(.headline)
                Text(isRunning ? "Déplace lentement la caméra" : "Garde seulement ce qui est juste")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Text("\(objects.count)")
                .font(.headline.monospacedDigit())
                .frame(width: 46, height: 46)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityLabel("\(objects.count) objets proposés")
        }
        .foregroundStyle(.white)
    }

    private var livePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Objets trouvés")
                    .font(.headline)
                Spacer()
                Button { showManualAdd = true } label: {
                    Label("Ajouter", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
            }

            if objects.isEmpty {
                Text("Rien pour l'instant. Approche-toi d'un objet et garde-le quelques instants dans le cadre.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(objects) { object in
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(object.name)
                                        .font(.caption.weight(.semibold))
                                        .lineLimit(1)
                                    Text(object.manual ? "Ajouté manuellement" : "À confirmer")
                                        .font(.caption2)
                                        .foregroundStyle(object.manual ? Color.owniqSignal : .orange)
                                }

                                Button { remove(object) } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption.bold())
                                        .frame(width: 30, height: 30)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Retirer \(object.name)")
                            }
                            .padding(.leading, 11)
                            .padding(.trailing, 5)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }

            if !removed.isEmpty {
                Button { undoRemoval() } label: {
                    Label("Annuler le dernier retrait", systemImage: "arrow.uturn.backward")
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .foregroundStyle(.white)
    }

    private var reviewPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Voilà ce que j'ai trouvé")
                    .font(.headline)
                Spacer()
                Button { showManualAdd = true } label: {
                    Label("Ajouter", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
            }

            Text("Touchez un nom pour le corriger. Décoche ce qui ne correspond pas à un objet réel.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.70))

            if objects.isEmpty {
                Text("Aucun objet à garder. Tu peux en ajouter manuellement ou reprendre le scan.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(objects) { object in
                            reviewRow(object)
                        }
                    }
                    .frame(maxHeight: 330)
                }
            }
        }
        .padding(14)
        .background(.black.opacity(0.76), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.09), lineWidth: 1) }
        .foregroundStyle(.white)
    }

    private func reviewRow(_ object: ReviewObject) -> some View {
        HStack(spacing: 10) {
            Button { toggle(object.id) } label: {
                Image(systemName: object.selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(object.selected ? Color.owniqSignal : .white.opacity(0.45))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(object.selected ? "Retirer cet objet" : "Garder cet objet")

            Button { beginEdit(object) } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(object.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text(object.category)
                        Text("·")
                        Text(object.manual ? "Manuel" : "À confirmer")
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.62))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Corriger le nom ou la catégorie")

            Button { beginEdit(object) } label: {
                Image(systemName: "pencil")
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Corriger \(object.name)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            object.selected ? Color.white.opacity(0.09) : Color.white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .opacity(object.selected ? 1 : 0.58)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if isRunning {
                Button {
                    isRunning = false
                } label: {
                    Label("Terminer", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.owniqCoral)
            } else {
                HStack(spacing: 10) {
                    Button {
                        isRunning = true
                        didSave = false
                    } label: {
                        Label("Reprendre", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.bordered)

                    Button { saveSelected() } label: {
                        Label(
                            didSave ? "Ajoutés" : (selectedCount == 0 ? "Terminer" : "Ajouter \(selectedCount)"),
                            systemImage: didSave ? "checkmark.circle.fill" : "plus.circle.fill"
                        )
                        .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.owniqSignal)
                    .disabled(didSave)
                }
            }
        }
    }

    private func receive(_ guess: VisionGuess) {
        let key = PublicVisionEngine.dedupKey(for: guess)
        guard !seenKeys.contains(key) else { return }
        seenKeys.insert(key)
        objects.append(ReviewObject(guess: guess))
        didSave = false
    }

    private func remove(_ object: ReviewObject) {
        objects.removeAll { $0.id == object.id }
        removed.append(object)
    }

    private func undoRemoval() {
        guard let object = removed.popLast() else { return }
        objects.append(object)
    }

    private func addManual() {
        let clean = manualName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let category = manualCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        objects.append(ReviewObject(name: clean, category: category.isEmpty ? "Autres" : category))
        manualName = ""
        manualCategory = "Autres"
        didSave = false
    }

    private func toggle(_ id: UUID) {
        guard let index = objects.firstIndex(where: { $0.id == id }) else { return }
        objects[index].selected.toggle()
    }

    private func beginEdit(_ object: ReviewObject) {
        editingID = object.id
        editName = object.name
        editCategory = object.category
    }

    private func applyCorrection() {
        guard let id = editingID,
              let index = objects.firstIndex(where: { $0.id == id }) else { return }
        let cleanName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = editCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        objects[index].name = cleanName
        objects[index].category = cleanCategory.isEmpty ? "Autres" : cleanCategory
        objects[index].selected = true
        objects[index].manual = true
        editingID = nil
    }

    private func saveSelected() {
        let chosen = objects.filter(\.selected)
        let items = chosen.map { object in
            VaultItem(
                name: object.name,
                category: object.category,
                confidence: object.confidence,
                needsConfirmation: !object.manual,
                source: .video
            )
        }
        store.add(items)
        didSave = true
    }
}

struct LiveVideoScanner: UIViewRepresentable {
    var isRunning: Bool
    let onGuess: (VisionGuess) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onGuess: onGuess)
    }

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        context.coordinator.setRunning(isRunning)
    }

    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private let session = AVCaptureSession()
        private let sessionQueue = DispatchQueue(label: "owniq.public.camera.session")
        private let analysisQueue = DispatchQueue(label: "owniq.public.camera.analysis", qos: .userInitiated)
        private let onGuess: (VisionGuess) -> Void
        private var configured = false
        private var desiredRunning = true
        private var lastAnalysis = Date.distantPast
        private var emitted: Set<String> = []

        init(onGuess: @escaping (VisionGuess) -> Void) {
            self.onGuess = onGuess
        }

        func attach(to view: CameraPreviewView) {
            view.previewLayer.session = session
            view.previewLayer.videoGravity = .resizeAspectFill
            requestAndConfigure()
        }

        func setRunning(_ running: Bool) {
            desiredRunning = running
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if running {
                    if self.configured && !self.session.isRunning { self.session.startRunning() }
                } else if self.session.isRunning {
                    self.session.stopRunning()
                }
            }
        }

        func stop() {
            desiredRunning = false
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if self.session.isRunning { self.session.stopRunning() }
            }
        }

        private func requestAndConfigure() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                configure()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted { self?.configure() }
                }
            default:
                break
            }
        }

        private func configure() {
            sessionQueue.async { [weak self] in
                guard let self, !self.configured else { return }
                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    return
                }
                self.session.addInput(input)

                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.setSampleBufferDelegate(self, queue: self.analysisQueue)
                guard self.session.canAddOutput(output) else {
                    self.session.commitConfiguration()
                    return
                }
                self.session.addOutput(output)
                self.session.commitConfiguration()
                self.configured = true
                if self.desiredRunning { self.session.startRunning() }
            }
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            let now = Date()
            guard now.timeIntervalSince(lastAnalysis) >= 0.8 else { return }
            lastAnalysis = now

            guard let guess = PublicVisionEngine.analyze(sampleBuffer: sampleBuffer), guess.confidence >= 0.20 else { return }
            let key = PublicVisionEngine.dedupKey(for: guess)
            guard !emitted.contains(key) else { return }
            emitted.insert(key)

            DispatchQueue.main.async { [onGuess] in
                onGuess(guess)
            }
        }
    }
}

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
