import SwiftUI
import RoomPlan

struct ScanHubView: View {
    @State private var showVideo = false
    @State private var showPhoto = false
    @State private var showRoom = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    OwnIQWordmark(compact: true)
                    Spacer()
                    Label("Local", systemImage: "iphone")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.owniqSecondary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Scanner")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                    Text("Qu'est-ce que tu veux scanner ?")
                        .font(.subheadline)
                        .foregroundStyle(Color.owniqSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

                Button { showVideo = true } label: {
                    scanCard(
                        title: "Des objets",
                        subtitle: "Filme autour de toi pour créer un inventaire",
                        icon: "video.fill",
                        accent: .owniqSignal
                    )
                }
                .buttonStyle(.plain)

                Button { showPhoto = true } label: {
                    scanCard(
                        title: "Un objet",
                        subtitle: "Photo ou bibliothèque pour l'identifier plus précisément",
                        icon: "camera.fill",
                        accent: .owniqViolet
                    )
                }
                .buttonStyle(.plain)

                Button { showRoom = true } label: {
                    scanCard(
                        title: "Une pièce",
                        subtitle: RoomCaptureSession.isSupported
                            ? "Scanner la pièce en 3D avec le LiDAR"
                            : "Nécessite un iPhone ou iPad compatible RoomPlan/LiDAR",
                        icon: "cube.transparent",
                        accent: .owniqCoral
                    )
                }
                .buttonStyle(.plain)
                .disabled(!RoomCaptureSession.isSupported)
                .opacity(RoomCaptureSession.isSupported ? 1 : 0.48)
            }
            .padding(20)
        }
        .owniqBackground()
        .navigationTitle("Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showVideo) { VideoScanView() }
        .fullScreenCover(isPresented: $showPhoto) { PhotoScanView() }
        .fullScreenCover(isPresented: $showRoom) { RoomScanScreen() }
    }

    private func scanCard(title: String, subtitle: String, icon: String, accent: Color) -> some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(accent.opacity(0.13))
                Image(systemName: icon)
                    .font(.title2.bold())
                    .foregroundStyle(accent)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.owniqSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.subheadline.bold())
                .foregroundStyle(accent)
        }
        .padding(17)
        .background(Color.owniqSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        }
    }
}
