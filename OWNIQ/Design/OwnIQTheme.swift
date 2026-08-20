import SwiftUI

enum OwnIQTheme {
    static let accent = Color(red: 0.24, green: 0.29, blue: 0.92)
    static let softAccent = accent.opacity(0.10)
    static let success = Color.green
}

struct OwnIQCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 18)
            .foregroundStyle(.white)
            .background(
                OwnIQTheme.accent.opacity(configuration.isPressed ? 0.82 : 1),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .contentShape(Rectangle())
    }
}
