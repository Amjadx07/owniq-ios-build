import SwiftUI
import AVFoundation
import UIKit

struct VideoScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var isRunning = true
    @State private var guesses: [VisionGuess] = []
    @State private var seenKeys: Set<String> = []
    @State private var didSave = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LiveVideoScanner(isRunning: isRunning) { guess in
                receive(guess)
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.62), .clear, .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 14) {
                topBar
                Spacer()
                detectionPanel
                controls
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .onDisappear { isRunning = false }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .frame(width: 46, height: 46)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Scanner des objets")
                    .font(.headline)
                Text(isRunning ? "Déplace lentement la caméra" : "Scan en pause")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Text("\(guesses.count)")
                .font(.headline.monospacedDigit())
                .frame(width: 46, height: 46)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityLabel("\(guesses.count) objets proposés")
        }
        .foregroundStyle(.white)
    }

    private var detectionPanel: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Objets repérés")
                    .font(.headline)
                Spacer()
                Text("À confirmer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            if guesses.isEmpty {
                Text("Aucun objet proposé pour l'instant. Approche-toi d'un objet et garde-le quelques instants dans le cadre.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(guesses) { guess in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(guess.name)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text(guess.category)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .foregroundStyle(.white)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Button {
                isRunning.toggle()
            } label: {
                Label(isRunning ? "Terminer le scan" : "Reprendre le scan", systemImage: isRunning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRunning ? Color.owniqCoral : Color.owniqSignal)

            if !isRunning && !guesses.isEmpty {
                Button {
                    saveAll()
                } label: {
                    Label(didSave ? "Ajoutés à Mes objets" : "Ajouter \(guesses.count) à Mes objets", systemImage: didSave ? "checkmark.circle.fill" : "shippingbox.fill")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.owniqSignal)
                .disabled(didSave)
            }
        }
    }

    private func receive(_ guess: VisionGuess) {
        let key = PublicVisionEngine.dedupKey(for: guess)
        guard !seenKeys.contains(key) else { return }
        seenKeys.insert(key)
        guesses.append(guess)
        didSave = false
    }

    private func saveAll() {
        let items = guesses.map { guess in
            VaultItem(
                name: guess.name,
                category: guess.category,
                confidence: guess.confidence,
                needsConfirmation: true,
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
