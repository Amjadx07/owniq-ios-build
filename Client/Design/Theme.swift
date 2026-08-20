import SwiftUI

extension Color {
    static let owniqBackground = Color(red: 0.045, green: 0.05, blue: 0.06)
    static let owniqSurface = Color(red: 0.09, green: 0.10, blue: 0.12)
    static let owniqSurface2 = Color(red: 0.13, green: 0.14, blue: 0.17)
    static let owniqSignal = Color(red: 0.35, green: 0.88, blue: 0.67)
    static let owniqViolet = Color(red: 0.57, green: 0.49, blue: 0.96)
    static let owniqCoral = Color(red: 0.98, green: 0.43, blue: 0.37)
    static let owniqSecondary = Color.white.opacity(0.64)
}

struct OwnIQWordmark: View {
    var compact = false

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 10 : 13, style: .continuous)
                    .fill(Color.owniqSignal.opacity(0.16))
                Image(systemName: "viewfinder")
                    .font(compact ? .subheadline.bold() : .headline.bold())
                    .foregroundStyle(Color.owniqSignal)
            }
            .frame(width: compact ? 34 : 42, height: compact ? 34 : 42)

            Text("OWNIQ")
                .font(compact ? .headline.bold() : .title3.weight(.black))
                .tracking(1.3)
        }
        .accessibilityElement(children: .combine)
    }
}

struct OwnIQCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(Color.owniqSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            }
    }
}

extension View {
    func owniqBackground() -> some View {
        background(Color.owniqBackground.ignoresSafeArea())
    }
}
