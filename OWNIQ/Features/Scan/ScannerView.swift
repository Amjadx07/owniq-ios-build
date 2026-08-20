import SwiftUI
import UIKit

struct ScannerView: View {
    @EnvironmentObject private var store: PublicStore
    @State private var showCamera = false
    @State private var capturedImage: UIImage?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Scanner")
                            .font(.largeTitle.bold())
                        Text("Montre simplement un objet. OWNIQ t’aide à le comprendre puis à décider quoi en faire.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    if let capturedImage {
                        ScanReviewCard(image: capturedImage) {
                            store.addCapturedObject(image: capturedImage)
                            self.capturedImage = nil
                        } retake: {
                            self.capturedImage = nil
                            showCamera = true
                        }
                    } else {
                        OwnIQCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(OwnIQTheme.accent)
                                    .accessibilityHidden(true)

                                Text("Un objet devant toi ?")
                                    .font(.title2.bold())

                                Text("Prends une photo. Le résultat restera prudent tant que l’identification n’est pas certaine.")
                                    .foregroundStyle(.secondary)

                                Button {
                                    showCamera = true
                                } label: {
                                    Label("Scanner un objet", systemImage: "camera.fill")
                                }
                                .buttonStyle(PrimaryActionButtonStyle())
                                .disabled(!cameraAvailable)
                                .accessibilityHint("Ouvre la caméra pour photographier un objet")

                                if !cameraAvailable {
                                    Text("La caméra n’est pas disponible sur cet appareil.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        OwnIQCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Le résultat va droit au but")
                                    .font(.headline)
                                Label("Ce que c’est", systemImage: "tag")
                                Label("Valeur approximative quand elle est fiable", systemImage: "eurosign.circle")
                                Label("État simple", systemImage: "checkmark.circle")
                                Label("Ce que tu peux en faire", systemImage: "arrow.right.circle")
                            }
                            .font(.body)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileDestinationButton()
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView { image in
                    capturedImage = image
                    showCamera = false
                } onCancel: {
                    showCamera = false
                }
                .ignoresSafeArea()
            }
        }
    }
}

private struct ScanReviewCard: View {
    let image: UIImage
    let add: () -> Void
    let retake: () -> Void

    var body: some View {
        OwnIQCard {
            VStack(alignment: .leading, spacing: 16) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("Photo de l’objet scanné")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Objet à confirmer")
                        .font(.title2.bold())
                    Text("Valeur estimée : —")
                        .font(.headline)
                    Text("État : à vérifier")
                        .foregroundStyle(.secondary)
                    Text("Le cœur privé de reconnaissance et de prix n’est volontairement pas publié dans ce dépôt de build.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button("Ajouter à mes objets", action: add)
                    .buttonStyle(PrimaryActionButtonStyle())

                Button("Reprendre la photo", action: retake)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
    }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
