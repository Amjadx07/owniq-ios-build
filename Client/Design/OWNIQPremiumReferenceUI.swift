import SwiftUI

// MARK: - OWNIQ premium reference pass
// No stylistic reinvention: same five canonical screens, with richer material,
// color depth, micro-glow, borders and procedural artwork so the compiled app
// keeps the premium density of the reference captures without missing assets.

enum OWNIQPremium {
    static let ink = Color(red: 1/255, green: 6/255, blue: 14/255)
    static let inkLift = Color(red: 3/255, green: 12/255, blue: 23/255)
    static let panel = Color(red: 6/255, green: 18/255, blue: 30/255)
    static let panelTop = Color(red: 12/255, green: 32/255, blue: 48/255)
    static let panelLift = Color(red: 16/255, green: 38/255, blue: 55/255)
    static let coolWhite = Color(red: 242/255, green: 249/255, blue: 255/255)
    static let cyan = Color(red: 30/255, green: 226/255, blue: 236/255)
    static let cyanHot = Color(red: 103/255, green: 251/255, blue: 247/255)
    static let cyanDeep = Color(red: 17/255, green: 164/255, blue: 207/255)
    static let violet = Color(red: 186/255, green: 104/255, blue: 252/255)
    static let violetHot = Color(red: 215/255, green: 151/255, blue: 255/255)
    static let amber = Color(red: 255/255, green: 184/255, blue: 68/255)
    static let amberHot = Color(red: 255/255, green: 218/255, blue: 133/255)
    static let blue = Color(red: 73/255, green: 183/255, blue: 255/255)
    static let secondary = Color(red: 179/255, green: 193/255, blue: 209/255)
    static let tertiary = Color(red: 113/255, green: 132/255, blue: 151/255)
    static let hairline = Color(red: 85/255, green: 111/255, blue: 136/255).opacity(0.72)
    static let pageInset: CGFloat = 20

    static var cyanGradient: LinearGradient {
        LinearGradient(colors: [cyanHot, cyan, cyanDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var premiumPanelGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: panelLift.opacity(0.98), location: 0),
                .init(color: panelTop.opacity(0.98), location: 0.28),
                .init(color: panel.opacity(0.99), location: 1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum OWNIQPremiumTab: String, CaseIterable, Identifiable {
    case home = "Accueil"
    case scanner = "Scanner"
    case house = "Maison"
    case inventory = "Inventaire"
    case profile = "Profil"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .scanner: return "viewfinder"
        case .house: return "house.fill"
        case .inventory: return "list.clipboard"
        case .profile: return "person"
        }
    }

    static func initialFromProcess() -> OWNIQPremiumTab {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "--tab"), args.indices.contains(index + 1) else { return .home }
        switch args[index + 1].lowercased() {
        case "scanner": return .scanner
        case "house": return .house
        case "inventory": return .inventory
        case "profile": return .profile
        default: return .home
        }
    }
}

struct OWNIQPremiumAppShell: View {
    @State private var selection: OWNIQPremiumTab

    init() {
        _selection = State(initialValue: OWNIQPremiumTab.initialFromProcess())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home: PremiumHome(select: select)
                case .scanner: PremiumScanner()
                case .house: PremiumHouse()
                case .inventory: PremiumInventory()
                case .profile: PremiumProfile()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PremiumTabBar(selection: $selection)
                .padding(.horizontal, 14)
                .padding(.bottom, 5)
                .zIndex(100)
        }
        .background(OWNIQPremium.ink.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func select(_ tab: OWNIQPremiumTab) {
        withAnimation(.easeOut(duration: 0.16)) { selection = tab }
    }
}

// MARK: - Shared premium material

private struct PremiumCircuitMesh: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let groups: [[CGPoint]] = [
            [.init(x: 0.44*w,y: 0.08*h),.init(x: 0.62*w,y: 0.08*h),.init(x: 0.69*w,y: 0.108*h),.init(x: 0.95*w,y: 0.108*h)],
            [.init(x: 0.51*w,y: 0.105*h),.init(x: 0.66*w,y: 0.105*h),.init(x: 0.73*w,y: 0.136*h),.init(x: 1.01*w,y: 0.136*h)],
            [.init(x: 0.58*w,y: 0.132*h),.init(x: 0.71*w,y: 0.132*h),.init(x: 0.78*w,y: 0.163*h),.init(x: 0.97*w,y: 0.163*h)],
            [.init(x: 0.00*w,y: 0.38*h),.init(x: 0.10*w,y: 0.38*h),.init(x: 0.16*w,y: 0.408*h),.init(x: 0.31*w,y: 0.408*h)],
            [.init(x: -0.01*w,y: 0.417*h),.init(x: 0.08*w,y: 0.417*h),.init(x: 0.14*w,y: 0.447*h),.init(x: 0.28*w,y: 0.447*h)],
            [.init(x: 0.68*w,y: 0.64*h),.init(x: 0.84*w,y: 0.64*h),.init(x: 0.90*w,y: 0.671*h),.init(x: 1.01*w,y: 0.671*h)],
            [.init(x: 0.00*w,y: 0.79*h),.init(x: 0.15*w,y: 0.79*h),.init(x: 0.21*w,y: 0.821*h),.init(x: 0.38*w,y: 0.821*h)]
        ]
        for points in groups {
            guard let first = points.first else { continue }
            p.move(to: first)
            for point in points.dropFirst() { p.addLine(to: point) }
            if let last = points.last {
                p.addEllipse(in: CGRect(x: last.x - 1.6, y: last.y - 1.6, width: 3.2, height: 3.2))
            }
        }
        return p
    }
}

private struct PremiumBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [OWNIQPremium.inkLift, OWNIQPremium.ink, Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(colors: [OWNIQPremium.cyan.opacity(0.13), .clear], center: .topTrailing, startRadius: 8, endRadius: 420)
            RadialGradient(colors: [OWNIQPremium.violet.opacity(0.055), .clear], center: UnitPoint(x: 0.14, y: 0.53), startRadius: 10, endRadius: 360)
            RadialGradient(colors: [OWNIQPremium.blue.opacity(0.055), .clear], center: .bottomTrailing, startRadius: 10, endRadius: 420)
            PremiumCircuitMesh()
                .stroke(LinearGradient(colors: [OWNIQPremium.cyan.opacity(0.30), OWNIQPremium.blue.opacity(0.08)], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 0.7, lineCap: .round, lineJoin: .round))
                .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}

private struct PremiumPanel<Content: View>: View {
    var radius: CGFloat = 20
    var accent: Color = OWNIQPremium.cyan
    var accentStrength: Double = 0.17
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(OWNIQPremium.premiumPanelGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(LinearGradient(colors: [Color.white.opacity(0.055), .clear, Color.black.opacity(0.11)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(LinearGradient(colors: [Color.white.opacity(0.18), accent.opacity(0.42), OWNIQPremium.hairline.opacity(0.42)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.9)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: max(1, radius - 1), style: .continuous)
                            .stroke(Color.black.opacity(0.36), lineWidth: 0.55)
                            .padding(1)
                    }
            }
            .shadow(color: Color.black.opacity(0.56), radius: 20, y: 10)
            .shadow(color: accent.opacity(accentStrength), radius: 16, y: 1)
    }
}

private struct PremiumLogo: View {
    var width: CGFloat = 142
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(OWNIQPremium.cyanHot, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(45))
                    .shadow(color: OWNIQPremium.cyan.opacity(0.65), radius: 6)
                Circle().fill(OWNIQPremium.cyanHot).frame(width: 5, height: 5)
                    .shadow(color: OWNIQPremium.cyanHot, radius: 5)
            }
            Text("OWNIQ")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(LinearGradient(colors: [OWNIQPremium.coolWhite, OWNIQPremium.cyanHot], startPoint: .top, endPoint: .bottom))
                .shadow(color: OWNIQPremium.cyan.opacity(0.22), radius: 5)
        }
        .frame(width: width, alignment: .leading)
        .accessibilityLabel("OWNIQ")
    }
}

private struct PremiumCircleButton: View {
    let icon: String
    var badge = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(LinearGradient(colors: [OWNIQPremium.panelLift, OWNIQPremium.panel], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay { Circle().stroke(LinearGradient(colors: [Color.white.opacity(0.18), OWNIQPremium.cyan.opacity(0.20), OWNIQPremium.hairline], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.9) }
                    .shadow(color: .black.opacity(0.45), radius: 8, y: 5)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(OWNIQPremium.coolWhite)
                if badge {
                    Circle().fill(OWNIQPremium.amberHot).frame(width: 8, height: 8)
                        .overlay { Circle().stroke(Color.black.opacity(0.55), lineWidth: 1) }
                        .shadow(color: OWNIQPremium.amber, radius: 4)
                        .offset(x: -2, y: 4)
                }
            }
            .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
    }
}

private struct PremiumIconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 43

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.19), color.opacity(0.045)], center: .topLeading, startRadius: 2, endRadius: 38))
                .overlay { Circle().stroke(color.opacity(0.58), lineWidth: 0.85) }
                .shadow(color: color.opacity(0.24), radius: 7)
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.55), radius: 4)
        }
        .frame(width: size, height: size)
    }
}

private struct PremiumTabBar: View {
    @Binding var selection: OWNIQPremiumTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(OWNIQPremiumTab.allCases) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.16)) { selection = tab }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selection == tab {
                                Capsule()
                                    .fill(OWNIQPremium.cyan.opacity(0.10))
                                    .frame(width: 44, height: 29)
                                    .overlay { Capsule().stroke(OWNIQPremium.cyan.opacity(0.30), lineWidth: 0.7) }
                                    .shadow(color: OWNIQPremium.cyan.opacity(0.20), radius: 7)
                            }
                            Image(systemName: tab.icon)
                                .font(.system(size: 21, weight: selection == tab ? .semibold : .regular))
                                .symbolVariant(selection == tab ? .fill : .none)
                        }
                        .frame(height: 30)
                        Text(tab.rawValue)
                            .font(.system(size: 11.1, weight: selection == tab ? .semibold : .regular))
                            .tracking(selection == tab ? 0.08 : 0)
                    }
                    .foregroundStyle(selection == tab ? OWNIQPremium.cyanHot : OWNIQPremium.secondary.opacity(0.82))
                    .frame(maxWidth: .infinity, minHeight: 65)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .fill(LinearGradient(colors: [OWNIQPremium.panelTop.opacity(0.98), OWNIQPremium.panel.opacity(0.985)], startPoint: .top, endPoint: .bottom))
                .overlay { RoundedRectangle(cornerRadius: 23).fill(LinearGradient(colors: [Color.white.opacity(0.055), .clear], startPoint: .top, endPoint: .center)) }
                .overlay { RoundedRectangle(cornerRadius: 23).stroke(LinearGradient(colors: [Color.white.opacity(0.18), OWNIQPremium.cyan.opacity(0.25), OWNIQPremium.hairline], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.9) }
        }
        .shadow(color: .black.opacity(0.68), radius: 22, y: 9)
        .shadow(color: OWNIQPremium.cyan.opacity(0.10), radius: 18)
    }
}

private struct PremiumShortcut: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                PremiumIconBadge(icon: icon, color: color, size: 39)
                Text(title)
                    .font(.system(size: 13.1, weight: .semibold))
                    .foregroundStyle(OWNIQPremium.coolWhite)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 98)
            .background {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(OWNIQPremium.premiumPanelGradient)
                    .overlay { RoundedRectangle(cornerRadius: 17).stroke(LinearGradient(colors: [color.opacity(0.52), Color.white.opacity(0.13), OWNIQPremium.hairline], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.85) }
            }
            .shadow(color: .black.opacity(0.40), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Procedural reference artwork

private enum PremiumObjectKind {
    case watch, sofa, lamp, laptop, chair, card, shelf
}

private struct PremiumObjectArt: View {
    let kind: PremiumObjectKind
    var accent: Color = OWNIQPremium.cyan

    var symbol: String {
        switch kind {
        case .watch: return "applewatch"
        case .sofa: return "sofa.fill"
        case .lamp: return "lamp.desk.fill"
        case .laptop: return "laptopcomputer"
        case .chair: return "chair.lounge.fill"
        case .card: return "rectangle.portrait.on.rectangle.portrait"
        case .shelf: return "books.vertical.fill"
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [accent.opacity(0.14), Color.white.opacity(0.025), Color.black.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(accent.opacity(0.10)).frame(width: 104, height: 104).blur(radius: 17)
            Image(systemName: symbol)
                .font(.system(size: 53, weight: .light))
                .foregroundStyle(LinearGradient(colors: [OWNIQPremium.coolWhite, accent.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: accent.opacity(0.45), radius: 11)
            RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.075), lineWidth: 0.7).padding(2)
        }
    }
}

private struct PremiumHouseArt: View {
    var compact = false

    var body: some View {
        ZStack {
            Ellipse().fill(OWNIQPremium.cyan.opacity(0.10)).frame(width: compact ? 180 : 270, height: compact ? 70 : 92).blur(radius: 18).offset(y: compact ? 42 : 64)
            ZStack {
                isoBlock(offsetX: -54, offsetY: 18, width: 118, height: 72, color: Color(red: 37/255, green: 75/255, blue: 88/255))
                isoBlock(offsetX: 38, offsetY: 7, width: 126, height: 82, color: Color(red: 44/255, green: 86/255, blue: 100/255))
                isoBlock(offsetX: -8, offsetY: -52, width: 130, height: 76, color: Color(red: 51/255, green: 102/255, blue: 111/255))
                roomGlow(x: -72, y: -4, color: OWNIQPremium.amber)
                roomGlow(x: 50, y: -18, color: OWNIQPremium.cyan)
                roomGlow(x: -8, y: -66, color: OWNIQPremium.violet)
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i.isMultiple(of: 2) ? OWNIQPremium.cyanHot.opacity(0.82) : OWNIQPremium.amberHot.opacity(0.78))
                        .frame(width: 13, height: 9)
                        .rotationEffect(.degrees(30))
                        .offset(x: CGFloat(i * 27) - 60, y: CGFloat((i % 2) * 25) - 16)
                        .shadow(color: OWNIQPremium.cyan.opacity(0.45), radius: 4)
                }
            }
            .scaleEffect(compact ? 0.72 : 1)
            .rotation3DEffect(.degrees(12), axis: (x: 1, y: 0, z: 0))
        }
        .accessibilityHidden(true)
    }

    private func isoBlock(offsetX: CGFloat, offsetY: CGFloat, width: CGFloat, height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(LinearGradient(colors: [color.opacity(0.95), color.opacity(0.48), Color.black.opacity(0.56)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: width, height: height)
            .rotationEffect(.degrees(30))
            .overlay {
                RoundedRectangle(cornerRadius: 8).stroke(LinearGradient(colors: [Color.white.opacity(0.27), OWNIQPremium.cyan.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    .frame(width: width, height: height)
                    .rotationEffect(.degrees(30))
            }
            .offset(x: offsetX, y: offsetY)
            .shadow(color: Color.black.opacity(0.48), radius: 8, y: 7)
    }

    private func roomGlow(x: CGFloat, y: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(0.36))
            .frame(width: 40, height: 24)
            .rotationEffect(.degrees(30))
            .offset(x: x, y: y)
            .blur(radius: 1.2)
            .shadow(color: color.opacity(0.80), radius: 9)
    }
}

private struct PremiumFloorplanArt: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.18))
            Path { p in
                p.move(to: CGPoint(x: 13, y: 14)); p.addLine(to: CGPoint(x: 94, y: 14)); p.addLine(to: CGPoint(x: 94, y: 69)); p.addLine(to: CGPoint(x: 60, y: 69)); p.addLine(to: CGPoint(x: 60, y: 84)); p.addLine(to: CGPoint(x: 13, y: 84)); p.closeSubpath()
                p.move(to: CGPoint(x: 52, y: 14)); p.addLine(to: CGPoint(x: 52, y: 69))
                p.move(to: CGPoint(x: 13, y: 49)); p.addLine(to: CGPoint(x: 94, y: 49))
            }
            .stroke(OWNIQPremium.cyanHot, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            .shadow(color: OWNIQPremium.cyan.opacity(0.62), radius: 4)
            Circle().fill(OWNIQPremium.amber).frame(width: 7, height: 7).offset(x: -21, y: 12)
            Circle().fill(OWNIQPremium.violet).frame(width: 7, height: 7).offset(x: 22, y: -17)
        }
    }
}

private struct PremiumScannerScene: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(colors: [Color(red: 37/255, green: 45/255, blue: 49/255), Color(red: 18/255, green: 25/255, blue: 30/255)], startPoint: .top, endPoint: .bottom)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h*0.58)); p.addLine(to: CGPoint(x: w, y: h*0.50)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)); p.closeSubpath()
                }.fill(LinearGradient(colors: [Color(red: 77/255, green: 67/255, blue: 57/255), Color(red: 31/255, green: 30/255, blue: 29/255)], startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 4).fill(Color(red: 118/255, green: 132/255, blue: 132/255).opacity(0.24)).frame(width: w*0.31, height: h*0.34).offset(x: -w*0.23, y: -h*0.21)
                Rectangle().fill(LinearGradient(colors: [Color.white.opacity(0.28), Color.cyan.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: w*0.22, height: h*0.28).offset(x: -w*0.27, y: -h*0.23)
                Rectangle().fill(Color.black.opacity(0.50)).frame(width: w*0.21, height: h*0.55).offset(x: w*0.33, y: -h*0.06)
                VStack(spacing: 7) {
                    ForEach(0..<5, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { col in
                                RoundedRectangle(cornerRadius: 1).fill([OWNIQPremium.amber, OWNIQPremium.cyan, OWNIQPremium.violet, Color.red.opacity(0.8)][(row+col)%4].opacity(0.72)).frame(width: 8, height: 18)
                            }
                        }
                    }
                }.offset(x: w*0.33, y: -h*0.07)
                PremiumObjectArt(kind: .chair, accent: OWNIQPremium.cyan).frame(width: w*0.29, height: h*0.34).offset(x: -w*0.24, y: h*0.20)
                PremiumObjectArt(kind: .sofa, accent: OWNIQPremium.secondary).frame(width: w*0.34, height: h*0.23).offset(x: w*0.08, y: h*0.17)
                Capsule().fill(LinearGradient(colors: [Color(red: 143/255, green: 103/255, blue: 69/255), Color(red: 72/255, green: 51/255, blue: 37/255)], startPoint: .top, endPoint: .bottom)).frame(width: w*0.31, height: 22).offset(x: w*0.05, y: h*0.29).shadow(color: .black.opacity(0.7), radius: 7, y: 6)
                Rectangle().fill(Color.white.opacity(0.06)).blendMode(.screen)
            }
            .overlay {
                LinearGradient(colors: [Color.white.opacity(0.08), .clear, Color.black.opacity(0.28)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
}

private struct DetectorBox: View {
    let title: String
    let color: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 7)
                .stroke(color.opacity(0.92), lineWidth: 1.35)
                .frame(width: width, height: height)
                .shadow(color: color.opacity(0.80), radius: 6)
            CornerBrackets().stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round)).frame(width: width, height: height)
                .shadow(color: color.opacity(0.80), radius: 4)
            Text(title)
                .font(.system(size: 10.8, weight: .semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(OWNIQPremium.ink.opacity(0.89), in: RoundedRectangle(cornerRadius: 6))
                .overlay { RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.86), lineWidth: 0.8) }
                .shadow(color: color.opacity(0.35), radius: 4)
                .offset(y: -27)
        }
    }
}

private struct CornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path(); let l: CGFloat = min(18, min(rect.width, rect.height)*0.18)
        p.move(to: CGPoint(x: 0, y: l)); p.addLine(to: .zero); p.addLine(to: CGPoint(x: l, y: 0))
        p.move(to: CGPoint(x: rect.width-l, y: 0)); p.addLine(to: CGPoint(x: rect.width, y: 0)); p.addLine(to: CGPoint(x: rect.width, y: l))
        p.move(to: CGPoint(x: rect.width, y: rect.height-l)); p.addLine(to: CGPoint(x: rect.width, y: rect.height)); p.addLine(to: CGPoint(x: rect.width-l, y: rect.height))
        p.move(to: CGPoint(x: l, y: rect.height)); p.addLine(to: CGPoint(x: 0, y: rect.height)); p.addLine(to: CGPoint(x: 0, y: rect.height-l))
        return p
    }
}

// MARK: - Home

private struct PremiumHome: View {
    let select: (OWNIQPremiumTab) -> Void

    var body: some View {
        ZStack {
            PremiumBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        PremiumLogo(width: 145)
                        Spacer()
                        HStack(spacing: 9) {
                            PremiumCircleButton(icon: "bell", badge: true)
                            PremiumCircleButton(icon: "person", action: { select(.profile) })
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bonjour, Alex !").font(.system(size: 34, weight: .bold)).tracking(-0.6).foregroundStyle(OWNIQPremium.coolWhite)
                        Text("Voici un aperçu de votre maison.").font(.system(size: 16.2)).foregroundStyle(OWNIQPremium.secondary)
                    }
                    summary
                    scanCTA
                    HStack(spacing: 10) {
                        PremiumShortcut(title: "Scanner", icon: "viewfinder", color: OWNIQPremium.cyan) { select(.scanner) }
                        PremiumShortcut(title: "Maison", icon: "house.fill", color: OWNIQPremium.violet) { select(.house) }
                        PremiumShortcut(title: "Inventaire", icon: "list.clipboard", color: OWNIQPremium.blue) { select(.inventory) }
                        PremiumShortcut(title: "Valeur", icon: "chart.line.uptrend.xyaxis", color: OWNIQPremium.amber) { select(.inventory) }
                    }
                    recents
                    houseProgress
                }
                .padding(.horizontal, OWNIQPremium.pageInset)
                .padding(.top, 9)
                .padding(.bottom, 108)
            }
        }
    }

    private var summary: some View {
        PremiumPanel(radius: 21, accent: OWNIQPremium.cyan, accentStrength: 0.24) {
            HStack(spacing: 2) {
                VStack(spacing: 0) {
                    metric(icon: "cube", value: "248", label: "objets enregistrés", color: OWNIQPremium.cyan)
                    Divider().overlay(OWNIQPremium.hairline).padding(.leading, 6)
                    metric(icon: "tag", value: "48 750 €", label: "valeur estimée totale", color: OWNIQPremium.violet)
                    Divider().overlay(OWNIQPremium.hairline).padding(.leading, 6)
                    metric(icon: "house.fill", value: "8", label: "pièces scannées", color: OWNIQPremium.amber)
                }
                .frame(width: 158)
                PremiumHouseArt(compact: true).frame(maxWidth: .infinity).frame(height: 192)
            }
            .padding(10)
        }
        .frame(minHeight: 204)
    }

    private func metric(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            PremiumIconBadge(icon: icon, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 20.5, weight: .bold)).foregroundStyle(color).shadow(color: color.opacity(0.30), radius: 4).lineLimit(1).minimumScaleFactor(0.72)
                Text(label).font(.system(size: 10.3)).foregroundStyle(OWNIQPremium.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 59)
    }

    private var scanCTA: some View {
        Button { select(.scanner) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous).fill(OWNIQPremium.cyanGradient)
                RoundedRectangle(cornerRadius: 15).fill(LinearGradient(colors: [Color.white.opacity(0.28), .clear], startPoint: .top, endPoint: .center)).padding(1)
                HStack(spacing: 13) {
                    Image(systemName: "viewfinder").font(.system(size: 25, weight: .semibold))
                    Text("Scanner un objet").font(.system(size: 20.2, weight: .bold)).tracking(-0.2)
                }.foregroundStyle(Color(red: 0, green: 24/255, blue: 31/255))
            }
            .frame(maxWidth: .infinity, minHeight: 63)
            .overlay { RoundedRectangle(cornerRadius: 15).stroke(OWNIQPremium.cyanHot.opacity(0.95), lineWidth: 0.9) }
            .shadow(color: OWNIQPremium.cyan.opacity(0.38), radius: 16, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var recents: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Objets récents").font(.system(size: 19, weight: .bold)).foregroundStyle(OWNIQPremium.coolWhite)
                Spacer()
                Button { select(.inventory) } label: {
                    HStack(spacing: 5) { Text("Voir tout"); Image(systemName: "chevron.right").font(.caption.bold()) }
                        .font(.system(size: 13.3, weight: .medium)).foregroundStyle(OWNIQPremium.cyanHot)
                }.buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                recent(kind: .watch, accent: OWNIQPremium.cyan, name: "Montre Omega", room: "Accessoires", price: "4 200 €")
                recent(kind: .sofa, accent: OWNIQPremium.violet, name: "Canapé 3 places", room: "Salon", price: "1 250 €")
                recent(kind: .lamp, accent: OWNIQPremium.amber, name: "Lampe Panthella", room: "Bureau", price: "580 €")
            }
        }
    }

    private func recent(kind: PremiumObjectKind, accent: Color, name: String, room: String, price: String) -> some View {
        PremiumPanel(radius: 15, accent: accent, accentStrength: 0.10) {
            VStack(alignment: .leading, spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    PremiumObjectArt(kind: kind, accent: accent).frame(height: 97)
                    Image(systemName: "ellipsis").font(.caption.bold()).foregroundStyle(OWNIQPremium.secondary).padding(7)
                }
                Text(name).font(.system(size: 12.1, weight: .semibold)).foregroundStyle(OWNIQPremium.coolWhite).lineLimit(1).minimumScaleFactor(0.68)
                Text(room).font(.system(size: 10.3)).foregroundStyle(OWNIQPremium.secondary).lineLimit(1)
                Text(price).font(.system(size: 14.3, weight: .semibold)).foregroundStyle(OWNIQPremium.cyanHot).shadow(color: OWNIQPremium.cyan.opacity(0.20), radius: 3)
            }.padding(8)
        }.frame(maxWidth: .infinity)
    }

    private var houseProgress: some View {
        PremiumPanel(radius: 19, accent: OWNIQPremium.cyan, accentStrength: 0.18) {
            HStack(spacing: 14) {
                PremiumFloorplanArt().frame(width: 128, height: 92)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Scan de la maison").font(.system(size: 18, weight: .semibold)).foregroundStyle(OWNIQPremium.coolWhite)
                    Text("Progression globale").font(.system(size: 12)).foregroundStyle(OWNIQPremium.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule().fill(OWNIQPremium.cyanGradient).frame(width: geo.size.width * 0.72).shadow(color: OWNIQPremium.cyan.opacity(0.55), radius: 4)
                        }
                    }.frame(height: 6)
                    Text("Dernier scan · Aujourd’hui à 09:21").font(.system(size: 10.1)).foregroundStyle(OWNIQPremium.secondary).lineLimit(1)
                }
                Spacer(minLength: 1)
                Text("72 %").font(.system(size: 22.5, weight: .bold)).foregroundStyle(OWNIQPremium.cyanHot).shadow(color: OWNIQPremium.cyan.opacity(0.40), radius: 5)
            }.padding(12)
        }
    }
}

// MARK: - Scanner

private struct PremiumScanner: View {
    @State private var activeFilter = "Objet"
    @State private var capturePulse = false
    private let filters = [("Objet", "cube"), ("Marque", "tag"), ("Valeur", "chart.line.uptrend.xyaxis"), ("3D", "cube.transparent")]

    var body: some View {
        ZStack {
            PremiumBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack { PremiumLogo(width: 145); Spacer(); PremiumCircleButton(icon: "questionmark") }
                        Text("Scanner").font(.system(size: 34, weight: .bold)).tracking(-0.6).foregroundStyle(OWNIQPremium.coolWhite)
                        Text("Pointez la caméra vers un objet pour l’identifier.").font(.system(size: 16)).foregroundStyle(OWNIQPremium.secondary)
                    }.padding(.horizontal, OWNIQPremium.pageInset)
                    camera
                    captureControls
                    detectedPanel
                }
                .padding(.top, 8)
                .padding(.bottom, 108)
            }
        }
    }

    private var camera: some View {
        ZStack {
            PremiumScannerScene()
            DetectorBox(title: "Fauteuil", color: OWNIQPremium.cyanHot, width: 127, height: 128).offset(x: -103, y: 27)
            DetectorBox(title: "Table basse", color: OWNIQPremium.amberHot, width: 126, height: 76).offset(x: 18, y: 83)
            DetectorBox(title: "Bibliothèque", color: OWNIQPremium.violetHot, width: 124, height: 175).offset(x: 107, y: -31)
        }
        .frame(height: 312)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(LinearGradient(colors: [Color.white.opacity(0.22), OWNIQPremium.cyan.opacity(0.24), OWNIQPremium.hairline], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.9) }
        .shadow(color: .black.opacity(0.58), radius: 18, y: 8)
        .shadow(color: OWNIQPremium.cyan.opacity(0.12), radius: 14)
    }

    private var captureControls: some View {
        HStack {
            roundControl("bolt.fill")
            Spacer()
            Button {
                withAnimation(.spring(response: 0.18, dampingFraction: 0.72)) { capturePulse.toggle() }
            } label: {
                ZStack {
                    Circle().stroke(OWNIQPremium.cyanHot, lineWidth: 2).frame(width: 88, height: 88).shadow(color: OWNIQPremium.cyan.opacity(0.52), radius: 9)
                    Circle().fill(LinearGradient(colors: [.white, Color(red: 220/255, green: 248/255, blue: 250/255)], startPoint: .top, endPoint: .bottom)).frame(width: capturePulse ? 76 : 72, height: capturePulse ? 76 : 72)
                    Circle().stroke(Color.white.opacity(0.55), lineWidth: 1).frame(width: 66, height: 66)
                }
            }.buttonStyle(.plain)
            Spacer()
            roundControl("arrow.triangle.2.circlepath.camera")
        }.padding(.horizontal, 62).padding(.vertical, 4)
    }

    private func roundControl(_ icon: String) -> some View {
        Button {} label: {
            PremiumIconBadge(icon: icon, color: OWNIQPremium.coolWhite.opacity(0.94), size: 54)
        }.buttonStyle(.plain)
    }

    private var detectedPanel: some View {
        PremiumPanel(radius: 27, accent: OWNIQPremium.cyan, accentStrength: 0.22) {
            VStack(spacing: 11) {
                Capsule().fill(LinearGradient(colors: [OWNIQPremium.secondary.opacity(0.75), OWNIQPremium.cyan.opacity(0.25)], startPoint: .leading, endPoint: .trailing)).frame(width: 46, height: 5).padding(.top, 7)
                HStack { Text("Objets détectés").font(.system(size: 20.5, weight: .bold)).foregroundStyle(OWNIQPremium.coolWhite); Spacer() }
                detectedRow(kind: .chair, title: "Fauteuil", value: "98 %", color: OWNIQPremium.cyanHot)
                detectedRow(kind: .sofa, title: "Table basse", value: "96 %", color: OWNIQPremium.amberHot)
                detectedRow(kind: .shelf, title: "Bibliothèque", value: "94 %", color: OWNIQPremium.violetHot)
                HStack(spacing: 8) {
                    ForEach(filters, id: \.0) { item in
                        Button { activeFilter = item.0 } label: {
                            HStack(spacing: 5) { Image(systemName: item.1); Text(item.0) }
                                .font(.system(size: 11.1, weight: activeFilter == item.0 ? .semibold : .regular))
                                .foregroundStyle(activeFilter == item.0 ? OWNIQPremium.cyanHot : OWNIQPremium.secondary)
                                .frame(maxWidth: .infinity, minHeight: 39)
                                .background(activeFilter == item.0 ? OWNIQPremium.cyan.opacity(0.12) : Color.white.opacity(0.018), in: Capsule())
                                .overlay { Capsule().stroke(activeFilter == item.0 ? OWNIQPremium.cyanHot.opacity(0.80) : OWNIQPremium.hairline, lineWidth: 0.9) }
                                .shadow(color: activeFilter == item.0 ? OWNIQPremium.cyan.opacity(0.18) : .clear, radius: 5)
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(.horizontal, 14).padding(.bottom, 14)
        }.padding(.horizontal, 14)
    }

    private func detectedRow(kind: PremiumObjectKind, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            PremiumObjectArt(kind: kind, accent: color).frame(width: 58, height: 58)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16.5, weight: .semibold)).foregroundStyle(OWNIQPremium.coolWhite)
                Text("Mobilier").font(.system(size: 12)).foregroundStyle(OWNIQPremium.secondary)
            }
            Spacer()
            Text(value).font(.system(size: 16.4, weight: .bold)).foregroundStyle(color).shadow(color: color.opacity(0.4), radius: 4)
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(OWNIQPremium.secondary)
        }
        .padding(8)
        .background(Color.white.opacity(0.026), in: RoundedRectangle(cornerRadius: 15))
        .overlay { RoundedRectangle(cornerRadius: 15).stroke(LinearGradient(colors: [color.opacity(0.34), OWNIQPremium.hairline], startPoint: .leading, endPoint: .trailing), lineWidth: 0.8) }
    }
}

// MARK: - House

private struct PremiumHouse: View {
    @State private var mode = "Manga"

    var body: some View {
        ZStack {
            PremiumBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack {
                        PremiumCircleButton(icon: "bell", badge: true)
                        Spacer()
                        Text("Maison").font(.system(size: 27, weight: .bold)).tracking(-0.3).foregroundStyle(OWNIQPremium.coolWhite)
                        Spacer()
                        PremiumCircleButton(icon: "person")
                    }
                    segmented
                    PremiumHouseArt().frame(height: 297).padding(.horizontal, 4)
                    HStack(spacing: 10) {
                        houseAction("Explorer", "magnifyingglass", OWNIQPremium.cyan)
                        houseAction("FPS", "scope", OWNIQPremium.violet)
                        houseAction("Organiser", "folder", OWNIQPremium.amber)
                        houseAction("Pièces", "square.on.square", OWNIQPremium.cyan)
                    }
                    HStack(spacing: 10) {
                        statCard(icon: "viewfinder", value: "12", label1: "pièces scannées", label2: "sur 15", color: OWNIQPremium.cyan)
                        statCard(icon: "cube", value: "248", label1: "objets détectés", label2: "sur 320", color: OWNIQPremium.violet)
                        statCard(icon: "circle.dotted", value: "72 %", label1: "scène complétée", label2: "en cours", color: OWNIQPremium.amber)
                    }
                    roomCard
                }
                .padding(.horizontal, OWNIQPremium.pageInset)
                .padding(.top, 8)
                .padding(.bottom, 108)
            }
        }
    }

    private var segmented: some View {
        HStack(spacing: 0) { segment("Réel"); segment("Manga") }
            .padding(3).frame(width: 235, height: 48)
            .background(OWNIQPremium.panel.opacity(0.94), in: Capsule())
            .overlay { Capsule().stroke(LinearGradient(colors: [Color.white.opacity(0.16), OWNIQPremium.hairline], startPoint: .top, endPoint: .bottom), lineWidth: 0.9) }
            .shadow(color: .black.opacity(0.40), radius: 8, y: 4)
    }

    private func segment(_ title: String) -> some View {
        Button { withAnimation(.easeOut(duration: 0.16)) { mode = title } } label: {
            Text(title).font(.system(size: 15.3, weight: .medium))
                .foregroundStyle(mode == title ? Color(red: 1/255, green: 22/255, blue: 30/255) : OWNIQPremium.coolWhite)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(mode == title ? AnyShapeStyle(OWNIQPremium.cyanGradient) : AnyShapeStyle(Color.clear), in: Capsule())
                .shadow(color: mode == title ? OWNIQPremium.cyan.opacity(0.38) : .clear, radius: 7)
        }.buttonStyle(.plain)
    }

    private func houseAction(_ title: String, _ icon: String, _ color: Color) -> some View {
        Button {} label: {
            VStack(spacing: 11) {
                PremiumIconBadge(icon: icon, color: color, size: 44)
                Text(title).font(.system(size: 13.2, weight: .medium)).foregroundStyle(OWNIQPremium.coolWhite).lineLimit(1).minimumScaleFactor(0.70)
            }
            .frame(maxWidth: .infinity, minHeight: 106)
            .background(OWNIQPremium.premiumPanelGradient, in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(LinearGradient(colors: [color.opacity(0.44), OWNIQPremium.hairline], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.85) }
            .shadow(color: .black.opacity(0.38), radius: 9, y: 5)
        }.buttonStyle(.plain)
    }

    private func statCard(icon: String, value: String, label1: String, label2: String, color: Color) -> some View {
        PremiumPanel(radius: 16, accent: color, accentStrength: 0.10) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).font(.system(size: 24, weight: .medium)).foregroundStyle(color).shadow(color: color.opacity(0.45), radius: 5)
                Text(value).font(.system(size: 27, weight: .bold)).foregroundStyle(OWNIQPremium.coolWhite)
                Text(label1).font(.system(size: 11)).foregroundStyle(OWNIQPremium.secondary).lineLimit(1).minimumScaleFactor(0.72)
                Text(label2).font(.system(size: 11.1, weight: .medium)).foregroundStyle(color)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(13)
        }
    }

    private var roomCard: some View {
        PremiumPanel(radius: 18, accent: OWNIQPremium.cyan, accentStrength: 0.15) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [OWNIQPremium.cyan.opacity(0.14), OWNIQPremium.panel], startPoint: .topLeading, endPoint: .bottomTrailing))
                    PremiumHouseArt(compact: true).scaleEffect(0.72)
                }
                .frame(width: 112, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(OWNIQPremium.cyan.opacity(0.75), lineWidth: 0.9) }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Salon").font(.system(size: 19, weight: .bold)).foregroundStyle(OWNIQPremium.coolWhite)
                    Text("Dernière mise à jour").font(.system(size: 11.4)).foregroundStyle(OWNIQPremium.secondary)
                    Text("Aujourd’hui à 09:21").font(.system(size: 11.4, weight: .medium)).foregroundStyle(OWNIQPremium.cyanHot)
                    Label("À jour", systemImage: "checkmark.circle.fill").font(.system(size: 11.4)).foregroundStyle(OWNIQPremium.cyanHot)
                }
                Spacer(minLength: 0)
                Button {} label: {
                    HStack(spacing: 6) { Text("Aperçu"); Image(systemName: "chevron.right") }
                        .font(.system(size: 13.2, weight: .medium)).foregroundStyle(Color(red: 1/255, green: 22/255, blue: 30/255))
                        .padding(.horizontal, 14).frame(height: 44).background(OWNIQPremium.cyanGradient, in: RoundedRectangle(cornerRadius: 13))
                }.buttonStyle(.plain)
            }.padding(12)
        }
    }
}

// MARK: - Inventory

private struct PremiumInventoryItem: Identifiable {
    let id = UUID()
    let kind: PremiumObjectKind
    let title: String
    let room: String
    let price: String
    let category: String
    let accent: Color
}

private struct PremiumInventory: View {
    @State private var query = ""
    @State private var category = "Tous"
    private let categories = [("Tous", "square.grid.2x2"), ("Tech", "laptopcomputer"), ("Mobilier", "chair"), ("Collections", "star"), ("Mode", "bag")]
    private let items = [
        PremiumInventoryItem(kind: .laptop, title: "MacBook Pro 14”", room: "Bureau", price: "2 390 €", category: "Tech", accent: OWNIQPremium.blue),
        PremiumInventoryItem(kind: .chair, title: "Fauteuil Lounge", room: "Salon", price: "1 850 €", category: "Mobilier", accent: OWNIQPremium.cyan),
        PremiumInventoryItem(kind: .card, title: "Carte Pikachu Holo", room: "Collection", price: "950 €", category: "Collections", accent: OWNIQPremium.amber),
        PremiumInventoryItem(kind: .watch, title: "Montre Omega Speedmaster", room: "Chambre", price: "5 450 €", category: "Mode", accent: OWNIQPremium.violet)
    ]

    var body: some View {
        ZStack {
            PremiumBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { PremiumLogo(width: 145); Spacer(); HStack(spacing: 9) { PremiumCircleButton(icon: "bell", badge: true); PremiumCircleButton(icon: "person") } }
                    Text("Inventaire").font(.system(size: 34, weight: .bold)).tracking(-0.6).foregroundStyle(OWNIQPremium.coolWhite).padding(.top, 2)
                    search
                    summary
                    categoryBar
                    grid
                }
                .padding(.horizontal, OWNIQPremium.pageInset)
                .padding(.top, 9)
                .padding(.bottom, 108)
            }
        }
    }

    private var search: some View {
        HStack(spacing: 13) {
            Image(systemName: "magnifyingglass").font(.system(size: 21)).foregroundStyle(OWNIQPremium.secondary.opacity(0.74))
            TextField("Rechercher un objet", text: $query).font(.system(size: 16)).foregroundStyle(OWNIQPremium.coolWhite).textInputAutocapitalization(.never)
            Image(systemName: "viewfinder").font(.system(size: 22, weight: .medium)).foregroundStyle(OWNIQPremium.cyanHot).shadow(color: OWNIQPremium.cyan.opacity(0.40), radius: 5)
        }
        .padding(.horizontal, 16).frame(height: 60)
        .background(OWNIQPremium.premiumPanelGradient, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(LinearGradient(colors: [Color.white.opacity(0.16), OWNIQPremium.cyan.opacity(0.19), OWNIQPremium.hairline], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.9) }
        .shadow(color: .black.opacity(0.36), radius: 10, y: 5)
    }

    private var summary: some View {
        PremiumPanel(radius: 18, accent: OWNIQPremium.cyan, accentStrength: 0.18) {
            HStack(spacing: 0) {
                inventoryMetric(icon: "cube", title: "Objets au total", value: "248", color: OWNIQPremium.cyan)
                Divider().overlay(OWNIQPremium.hairline).frame(height: 62)
                inventoryMetric(icon: "tag", title: "Valeur estimée totale", value: "48 750 €", color: OWNIQPremium.violet)
            }.padding(.vertical, 13)
        }
    }

    private func inventoryMetric(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 11) {
            PremiumIconBadge(icon: icon, color: color)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 11.8)).foregroundStyle(OWNIQPremium.secondary).lineLimit(1).minimumScaleFactor(0.72)
                Text(value).font(.system(size: 21.5, weight: .bold)).foregroundStyle(color).shadow(color: color.opacity(0.24), radius: 4).lineLimit(1).minimumScaleFactor(0.72)
            }
            Spacer(minLength: 0)
        }.padding(.horizontal, 14).frame(maxWidth: .infinity)
    }

    private var categoryBar: some View {
        HStack(spacing: 8) {
            ForEach(categories, id: \.0) { item in
                Button { category = item.0 } label: {
                    VStack(spacing: 7) {
                        Image(systemName: item.1).font(.system(size: 18, weight: .medium))
                        Text(item.0).font(.system(size: 11.1, weight: category == item.0 ? .semibold : .medium)).lineLimit(1).minimumScaleFactor(0.70)
                    }
                    .foregroundStyle(category == item.0 ? OWNIQPremium.coolWhite : OWNIQPremium.secondary)
                    .frame(maxWidth: .infinity, minHeight: 67)
                    .background(category == item.0 ? OWNIQPremium.cyan.opacity(0.13) : Color.white.opacity(0.018), in: RoundedRectangle(cornerRadius: 15))
                    .overlay { RoundedRectangle(cornerRadius: 15).stroke(category == item.0 ? OWNIQPremium.cyanHot.opacity(0.86) : OWNIQPremium.hairline, lineWidth: category == item.0 ? 1 : 0.8) }
                    .shadow(color: category == item.0 ? OWNIQPremium.cyan.opacity(0.25) : .black.opacity(0.20), radius: 8, y: 3)
                }.buttonStyle(.plain)
            }
        }
    }

    private var filtered: [PremiumInventoryItem] {
        items.filter { item in
            (category == "Tous" || item.category == category) && (query.isEmpty || item.title.localizedCaseInsensitiveContains(query))
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(filtered) { item in
                PremiumPanel(radius: 18, accent: item.accent, accentStrength: 0.09) {
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack(alignment: .topTrailing) {
                            PremiumObjectArt(kind: item.kind, accent: item.accent).frame(maxWidth: .infinity).frame(height: 157)
                            Image(systemName: "ellipsis").font(.caption.bold()).foregroundStyle(OWNIQPremium.secondary).padding(8)
                        }
                        Text(item.title).font(.system(size: 15.2, weight: .semibold)).foregroundStyle(OWNIQPremium.coolWhite).lineLimit(1).minimumScaleFactor(0.70)
                        Text(item.room).font(.system(size: 11.4)).foregroundStyle(OWNIQPremium.secondary)
                        Text(item.price).font(.system(size: 15.8, weight: .semibold)).foregroundStyle(OWNIQPremium.cyanHot).shadow(color: OWNIQPremium.cyan.opacity(0.20), radius: 3)
                    }.padding(10)
                }
            }
        }
    }
}

// MARK: - Profile

private struct PremiumProfile: View {
    private let settings: [(String, String, Color)] = [
        ("Compte", "person", OWNIQPremium.cyan),
        ("Sécurité", "checkmark.shield", OWNIQPremium.violet),
        ("Confidentialité", "lock", OWNIQPremium.violet),
        ("Sauvegarde locale", "icloud.and.arrow.up", OWNIQPremium.cyan),
        ("Notifications", "bell", OWNIQPremium.amber),
        ("Apparence", "paintpalette", OWNIQPremium.violet),
        ("Téléchargements IA", "brain.head.profile", OWNIQPremium.cyan)
    ]
    private let help: [(String, String, Color)] = [
        ("Aide", "questionmark.circle", OWNIQPremium.cyan),
        ("Nous contacter", "bubble.left.and.bubble.right", OWNIQPremium.violet),
        ("À propos", "info.circle", OWNIQPremium.amber)
    ]

    var body: some View {
        ZStack {
            PremiumBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 13) {
                    HStack { PremiumLogo(width: 130); Spacer(); Text("Paramètres").font(.system(size: 20, weight: .semibold)).foregroundStyle(OWNIQPremium.coolWhite) }
                    profileCard
                    settingsCard
                    storageCard
                    Text("Assistance").font(.system(size: 14.5, weight: .medium)).foregroundStyle(OWNIQPremium.cyanHot).padding(.leading, 5)
                    assistanceCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 108)
            }
        }
    }

    private var profileCard: some View {
        PremiumPanel(radius: 19, accent: OWNIQPremium.cyan, accentStrength: 0.26) {
            HStack(spacing: 17) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [OWNIQPremium.cyan.opacity(0.28), OWNIQPremium.violet.opacity(0.20), OWNIQPremium.panel], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 68, weight: .light)).foregroundStyle(LinearGradient(colors: [OWNIQPremium.coolWhite, OWNIQPremium.cyan.opacity(0.70)], startPoint: .top, endPoint: .bottom))
                }
                .frame(width: 86, height: 86)
                .overlay { Circle().stroke(LinearGradient(colors: [OWNIQPremium.cyanHot, OWNIQPremium.violet.opacity(0.50)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.2) }
                .shadow(color: OWNIQPremium.cyan.opacity(0.40), radius: 11)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Alex Dupont").font(.system(size: 25, weight: .bold)).foregroundStyle(OWNIQPremium.coolWhite)
                    Label("OWNIQ Premium", systemImage: "crown.fill").font(.system(size: 13.8, weight: .semibold)).foregroundStyle(LinearGradient(colors: [OWNIQPremium.cyanHot, OWNIQPremium.violetHot], startPoint: .leading, endPoint: .trailing)).shadow(color: OWNIQPremium.cyan.opacity(0.32), radius: 4)
                    Text("Expérience complète débloquée").font(.system(size: 12.1)).foregroundStyle(OWNIQPremium.secondary)
                }
                Spacer(minLength: 1)
                Image(systemName: "chevron.right").font(.system(size: 17, weight: .medium)).foregroundStyle(OWNIQPremium.secondary)
            }.padding(18)
        }
    }

    private var settingsCard: some View {
        PremiumPanel(radius: 18, accent: OWNIQPremium.cyan, accentStrength: 0.13) {
            VStack(spacing: 0) {
                ForEach(Array(settings.enumerated()), id: \.offset) { index, item in
                    settingRow(item.0, icon: item.1, color: item.2)
                    if index != settings.count - 1 { Divider().overlay(OWNIQPremium.hairline.opacity(0.72)).padding(.leading, 50) }
                }
            }.padding(.horizontal, 14)
        }
    }

    private func settingRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.08)).frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 17, weight: .medium)).foregroundStyle(color).shadow(color: color.opacity(0.50), radius: 4)
            }
            Text(title).font(.system(size: 16, weight: .medium)).foregroundStyle(OWNIQPremium.coolWhite)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13.5, weight: .semibold)).foregroundStyle(OWNIQPremium.secondary)
        }.frame(height: 48)
    }

    private var storageCard: some View {
        PremiumPanel(radius: 18, accent: OWNIQPremium.cyan, accentStrength: 0.18) {
            VStack(spacing: 11) {
                HStack {
                    Text("Stockage – Modèles IA / Packs").font(.system(size: 15.1, weight: .medium)).foregroundStyle(OWNIQPremium.coolWhite)
                    Spacer(); Text("72 % utilisé").font(.system(size: 12)).foregroundStyle(OWNIQPremium.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.13))
                        Capsule().fill(OWNIQPremium.cyanGradient).frame(width: geo.size.width * 0.72).shadow(color: OWNIQPremium.cyan.opacity(0.56), radius: 5)
                    }
                }.frame(height: 7)
                HStack {
                    Text("57,6 Go utilisés sur 80 Go").font(.system(size: 11.4)).foregroundStyle(OWNIQPremium.secondary)
                    Spacer(); Text("Gérer").font(.system(size: 12.5, weight: .medium)).foregroundStyle(OWNIQPremium.cyanHot)
                }
                HStack(spacing: 10) {
                    storageMetric(icon: "cube", value: "12", label: "Packs installés")
                    storageMetric(icon: "arrow.down.to.line", value: "3,2 Go", label: "Espace disponible")
                }
            }.padding(15)
        }
    }

    private func storageMetric(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            PremiumIconBadge(icon: icon, color: OWNIQPremium.cyan, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 18, weight: .semibold)).foregroundStyle(OWNIQPremium.coolWhite)
                Text(label).font(.system(size: 10.7)).foregroundStyle(OWNIQPremium.secondary).lineLimit(1).minimumScaleFactor(0.76)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10).frame(maxWidth: .infinity, minHeight: 57)
        .background(LinearGradient(colors: [OWNIQPremium.panelTop.opacity(0.86), OWNIQPremium.panel.opacity(0.80)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(OWNIQPremium.hairline, lineWidth: 0.75) }
    }

    private var assistanceCard: some View {
        PremiumPanel(radius: 18, accent: OWNIQPremium.violet, accentStrength: 0.10) {
            VStack(spacing: 0) {
                ForEach(Array(help.enumerated()), id: \.offset) { index, item in
                    settingRow(item.0, icon: item.1, color: item.2)
                    if index != help.count - 1 { Divider().overlay(OWNIQPremium.hairline.opacity(0.72)).padding(.leading, 50) }
                }
            }.padding(.horizontal, 14)
        }
    }
}
