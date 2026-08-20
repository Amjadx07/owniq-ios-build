import SwiftUI
import PhotosUI
import UIKit

struct PhotoScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    @State private var photoItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var guess: VisionGuess?
    @State private var isAnalyzing = false
    @State private var showCamera = false
    @State private var name = ""
    @State private var category = "Autres"
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    imageCard
                    actions

                    if isAnalyzing {
                        ProgressView("Analyse locale…")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if image != nil {
                        resultCard
                    } else {
                        instructions
                    }
                }
                .padding(20)
            }
            .owniqBackground()
            .navigationTitle("Un objet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraImagePicker { captured in
                    image = captured
                    analyze(captured)
                }
                .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                        analyze(uiImage)
                    }
                }
            }
        }
    }

    private var imageCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.owniqSurface)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(4)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(Color.owniqViolet)
                    Text("Cadre l'objet seul si possible")
                        .font(.headline)
                    Text("Plus l'objet est visible, plus le résultat sera utile.")
                        .font(.caption)
                        .foregroundStyle(Color.owniqSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(28)
            }
        }
        .frame(minHeight: 300)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                showCamera = true
            } label: {
                Label("Caméra", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.owniqSignal)

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Photos", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
        }
    }

    private var instructions: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.owniqSignal)
            Text("La version publique utilise uniquement Apple Vision. Une identification incertaine reste marquée « À confirmer » au lieu d'inventer un modèle ou un prix.")
                .font(.caption)
                .foregroundStyle(Color.owniqSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resultCard: some View {
        OwnIQCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Résultat")
                        .font(.title3.bold())
                    Spacer()
                    Label("À confirmer", systemImage: "questionmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }

                TextField("Nom de l'objet", text: $name)
                    .textFieldStyle(.roundedBorder)

                Picker("Catégorie", selection: $category) {
                    ForEach(AppStore.defaultCategories, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }
                .pickerStyle(.menu)

                if let guess {
                    HStack {
                        Text("Confiance du fallback")
                        Spacer()
                        Text("\(Int((guess.confidence * 100).rounded())) %")
                            .foregroundStyle(Color.owniqSecondary)
                    }
                    .font(.caption)
                }

                Button {
                    save()
                } label: {
                    Label(saved ? "Ajouté" : "Ajouter à Mes objets", systemImage: saved ? "checkmark.circle.fill" : "plus.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.owniqSignal)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || saved)
            }
        }
    }

    private func analyze(_ image: UIImage) {
        isAnalyzing = true
        saved = false
        guess = nil
        name = ""
        category = "Autres"

        DispatchQueue.global(qos: .userInitiated).async {
            let result = PublicVisionEngine.analyze(image: image)
            DispatchQueue.main.async {
                guess = result
                name = result?.name ?? "Objet à confirmer"
                category = result?.category ?? "Autres"
                isAnalyzing = false
            }
        }
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        let item = VaultItem(
            name: cleanName,
            category: category,
            confidence: guess?.confidence,
            needsConfirmation: true,
            photoData: image?.jpegData(compressionQuality: 0.72),
            source: .photo
        )
        store.add(item)
        saved = true
    }
}

struct CameraImagePicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraImagePicker
        init(parent: CameraImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
