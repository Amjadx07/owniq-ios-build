import SwiftUI

// MARK: - OWNIQ strict reference UI
// Final design-first pass calibrated against the five canonical 863×1822 captures.

enum OWNIQFinal {
    static let ink = Color(red: 1/255, green: 7/255, blue: 15/255)
    static let panel = Color(red: 7/255, green: 18/255, blue: 29/255)
    static let panelRaised = Color(red: 12/255, green: 25/255, blue: 38/255)
    static let cyan = Color(red: 31/255, green: 226/255, blue: 236/255)
    static let cyanBright = Color(red: 88/255, green: 239/255, blue: 239/255)
    static let violet = Color(red: 180/255, green: 105/255, blue: 248/255)
    static let amber = Color(red: 255/255, green: 183/255, blue: 70/255)
    static let blue = Color(red: 80/255, green: 183/255, blue: 255/255)
    static let secondary = Color(red: 174/255, green: 186/255, blue: 202/255)
    static let tertiary = Color(red: 118/255, green: 132/255, blue: 151/255)
    static let line = Color(red: 82/255, green: 102/255, blue: 122/255).opacity(0.68)
    static let pageInset: CGFloat = 20
    static let tabInset: CGFloat = 15

    static var cyanGradient: LinearGradient {
        LinearGradient(colors: [cyanBright, Color(red: 36/255, green: 196/255, blue: 220/255)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var panelGradient: LinearGradient {
        LinearGradient(colors: [panelRaised.opacity(0.96), panel.opacity(0.98)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum OWNIQFinalTab: String, CaseIterable, Identifiable {
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
        case .house: return "house"
        case .inventory: return "list.clipboard"
        case .profile: return "person"
        }
    }

    static func initialFromProcess() -> OWNIQFinalTab {
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

struct OWNIQFinalAppShell: View {
    @State private var selection: OWNIQFinalTab

    init() {
        _selection = State(initialValue: OWNIQFinalTab.initialFromProcess())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home: OWNIQFinalHome(select: select)
                case .scanner: OWNIQFinalScanner()
                case .house: OWNIQFinalHouse()
                case .inventory: OWNIQFinalInventory()
                case .profile: OWNIQFinalProfile()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            OWNIQFinalTabBar(selection: $selection)
                .padding(.horizontal, OWNIQFinal.tabInset)
                .padding(.bottom, 6)
                .zIndex(50)
        }
        .background(OWNIQFinal.ink.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func select(_ tab: OWNIQFinalTab) {
        withAnimation(.easeOut(duration: 0.16)) { selection = tab }
    }
}

// MARK: - Shared

struct OWNIQFinalBackground: View {
    var body: some View {
        ZStack {
            OWNIQFinal.ink
            RadialGradient(colors: [OWNIQFinal.cyan.opacity(0.055), .clear], center: .topTrailing, startRadius: 10, endRadius: 410)
            RadialGradient(colors: [OWNIQFinal.blue.opacity(0.026), .clear], center: .bottomLeading, startRadius: 10, endRadius: 420)
            FinalCircuitTrace()
                .stroke(OWNIQFinal.cyan.opacity(0.20), style: StrokeStyle(lineWidth: 0.7, lineCap: .round, lineJoin: .round))
                .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}

private struct FinalCircuitTrace: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let traces: [[CGPoint]] = [
            [.init(x: 0.53*w,y: 0.105*h),.init(x: 0.68*w,y: 0.105*h),.init(x: 0.74*w,y: 0.135*h),.init(x: 0.98*w,y: 0.135*h)],
            [.init(x: 0.48*w,y: 0.130*h),.init(x: 0.65*w,y: 0.130*h),.init(x: 0.72*w,y: 0.165*h),.init(x: 1.00*w,y: 0.165*h)],
            [.init(x: 0.58*w,y: 0.155*h),.init(x: 0.70*w,y: 0.155*h),.init(x: 0.76*w,y: 0.188*h),.init(x: 0.97*w,y: 0.188*h)],
            [.init(x: 0.00*w,y: 0.405*h),.init(x: 0.11*w,y: 0.405*h),.init(x: 0.17*w,y: 0.438*h),.init(x: 0.34*w,y: 0.438*h)],
            [.init(x: 0.00*w,y: 0.445*h),.init(x: 0.09*w,y: 0.445*h),.init(x: 0.15*w,y: 0.474*h),.init(x: 0.30*w,y: 0.474*h)]
        ]
        for points in traces {
            guard let first = points.first else { continue }
            p.move(to: first)
            points.dropFirst().forEach { p.addLine(to: $0) }
            if let last = points.last { p.addEllipse(in: CGRect(x: last.x - 1.3, y: last.y - 1.3, width: 2.6, height: 2.6)) }
        }
        return p
    }
}

private struct FinalPanel<Content: View>: View {
    var radius: CGFloat = 20
    var border: Color = OWNIQFinal.line
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(OWNIQFinal.panelGradient, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(border, lineWidth: 0.85) }
            .shadow(color: Color.black.opacity(0.22), radius: 12, y: 6)
    }
}

private struct FinalLogo: View {
    var width: CGFloat = 142
    var body: some View {
        Image("owniq_logo_reference")
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .shadow(color: OWNIQFinal.cyan.opacity(0.12), radius: 3)
            .accessibilityLabel("OWNIQ")
    }
}

private struct FinalCircleButton: View {
    let icon: String
    var badge = false
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle().fill(OWNIQFinal.panel.opacity(0.92)).overlay { Circle().stroke(OWNIQFinal.line, lineWidth: 1) }
                Image(systemName: icon).font(.system(size: 21, weight: .medium)).foregroundStyle(.white)
                if badge { Circle().fill(.orange).frame(width: 8, height: 8).offset(x: -3, y: 4) }
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
    }
}

private struct FinalAssetImage: View {
    let name: String
    var mode: ContentMode = .fit
    var body: some View {
        Image(name).resizable().aspectRatio(contentMode: mode)
    }
}

private struct FinalTabBar: View {
    @Binding var selection: OWNIQFinalTab
    var body: some View {
        HStack(spacing: 0) {
            ForEach(OWNIQFinalTab.allCases) { tab in
                Button { withAnimation(.easeOut(duration: 0.16)) { selection = tab } } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: selection == tab ? .semibold : .regular))
                            .symbolVariant(selection == tab ? .fill : .none)
                        Text(tab.rawValue).font(.system(size: 11.2, weight: selection == tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selection == tab ? OWNIQFinal.cyan : OWNIQFinal.secondary.opacity(0.88))
                    .frame(maxWidth: .infinity, minHeight: 66)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(OWNIQFinal.panel.opacity(0.975), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(OWNIQFinal.line, lineWidth: 0.9) }
        .shadow(color: .black.opacity(0.46), radius: 20, y: 7)
    }
}

private typealias OWNIQFinalTabBar = FinalTabBar

private struct FinalMetricIcon: View {
    let icon: String
    let color: Color
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.08)).overlay { Circle().stroke(color.opacity(0.48), lineWidth: 0.9) }
            Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundStyle(color)
        }
        .frame(width: 43, height: 43)
    }
}

private struct FinalShortcut: View {
    let title: String, icon: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 11) {
                Image(systemName: icon).font(.system(size: 27, weight: .medium)).foregroundStyle(color).frame(height: 29)
                Text(title).font(.system(size: 13.2, weight: .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 94)
            .background(OWNIQFinal.panelRaised.opacity(0.96), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(OWNIQFinal.line, lineWidth: 0.85) }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home

struct OWNIQFinalHome: View {
    let select: (OWNIQFinalTab) -> Void

    var body: some View {
        ZStack {
            OWNIQFinalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bonjour, Alex !").font(.system(size: 34, weight: .bold))
                        Text("Voici un aperçu de votre maison.").font(.system(size: 16.5)).foregroundStyle(OWNIQFinal.secondary)
                    }
                    .padding(.top, 4)
                    summary
                    scanCTA
                    shortcuts
                    recents
                    houseProgress
                }
                .padding(.horizontal, OWNIQFinal.pageInset)
                .padding(.top, 10)
                .padding(.bottom, 108)
            }
        }
    }

    private var header: some View {
        HStack {
            FinalLogo(width: 143)
            Spacer()
            HStack(spacing: 9) {
                FinalCircleButton(icon: "bell", badge: true)
                FinalCircleButton(icon: "person", action: { select(.profile) })
            }
        }
    }

    private var summary: some View {
        FinalPanel(border: OWNIQFinal.cyan.opacity(0.60)) {
            HStack(spacing: 4) {
                VStack(spacing: 0) {
                    homeMetric(icon: "cube", value: "248", label: "objets enregistrés", color: OWNIQFinal.cyan)
                    Divider().overlay(OWNIQFinal.line).padding(.leading, 5)
                    homeMetric(icon: "tag", value: "48 750 €", label: "valeur estimée totale", color: OWNIQFinal.violet)
                    Divider().overlay(OWNIQFinal.line).padding(.leading, 5)
                    homeMetric(icon: "house", value: "8", label: "pièces scannées", color: OWNIQFinal.amber)
                }
                .frame(width: 159)
                FinalAssetImage(name: "home_house")
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                    .padding(.trailing, 2)
            }
            .padding(10)
        }
        .frame(minHeight: 200)
    }

    private func homeMetric(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            FinalMetricIcon(icon: icon, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 21, weight: .bold)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.75)
                Text(label).font(.system(size: 10.5)).foregroundStyle(OWNIQFinal.secondary).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .frame(height: 58)
    }

    private var scanCTA: some View {
        Button { select(.scanner) } label: {
            HStack(spacing: 14) {
                Image(systemName: "viewfinder").font(.system(size: 25, weight: .medium))
                Text("Scanner un objet").font(.system(size: 20.5, weight: .bold))
            }
            .foregroundStyle(Color(red: 1/255, green: 25/255, blue: 31/255))
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(OWNIQFinal.cyanGradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: 15).stroke(OWNIQFinal.cyanBright.opacity(0.85), lineWidth: 0.8) }
            .shadow(color: OWNIQFinal.cyan.opacity(0.25), radius: 14, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var shortcuts: some View {
        HStack(spacing: 10) {
            FinalShortcut(title: "Scanner", icon: "viewfinder", color: OWNIQFinal.cyan) { select(.scanner) }
            FinalShortcut(title: "Maison", icon: "house", color: OWNIQFinal.violet) { select(.house) }
            FinalShortcut(title: "Inventaire", icon: "list.clipboard", color: OWNIQFinal.blue) { select(.inventory) }
            FinalShortcut(title: "Valeur", icon: "chart.line.uptrend.xyaxis", color: OWNIQFinal.amber) { select(.inventory) }
        }
    }

    private var recents: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Objets récents").font(.system(size: 19, weight: .bold))
                Spacer()
                Button { select(.inventory) } label: {
                    HStack(spacing: 6) { Text("Voir tout"); Image(systemName: "chevron.right").font(.caption.bold()) }
                        .font(.system(size: 13.5, weight: .medium)).foregroundStyle(OWNIQFinal.cyan)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 10) {
                recentCard(asset: "home_watch", name: "Montre Omega", room: "Accessoires", price: "4 200 €")
                recentCard(asset: "home_sofa", name: "Canapé 3 places", room: "Salon", price: "1 250 €")
                recentCard(asset: "home_lamp", name: "Lampe Panthella", room: "Bureau", price: "580 €")
            }
        }
    }

    private func recentCard(asset: String, name: String, room: String, price: String) -> some View {
        FinalPanel(radius: 14) {
            VStack(alignment: .leading, spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    FinalAssetImage(name: asset).frame(height: 96).frame(maxWidth: .infinity)
                    Image(systemName: "ellipsis").font(.caption.bold()).padding(6)
                }
                Text(name).font(.system(size: 12.1, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.68)
                Text(room).font(.system(size: 10.4)).foregroundStyle(OWNIQFinal.secondary).lineLimit(1)
                Text(price).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(OWNIQFinal.cyan)
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity)
    }

    private var houseProgress: some View {
        FinalPanel(border: OWNIQFinal.cyan.opacity(0.60)) {
            HStack(spacing: 14) {
                FinalAssetImage(name: "home_floorplan")
                    .frame(width: 128, height: 92)
                    .padding(.leading, 2)
                VStack(alignment: .leading, spacing: 7) {
                    Text("Scan de la maison").font(.system(size: 18, weight: .semibold))
                    Text("Progression globale").font(.system(size: 12)).foregroundStyle(OWNIQFinal.secondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule().fill(OWNIQFinal.cyanGradient).frame(width: geo.size.width * 0.72)
                        }
                    }
                    .frame(height: 5)
                    Text("Dernier scan · Aujourd’hui à 09:21").font(.system(size: 10.3)).foregroundStyle(OWNIQFinal.secondary).lineLimit(1)
                }
                Spacer(minLength: 2)
                Text("72 %").font(.system(size: 23, weight: .bold)).foregroundStyle(OWNIQFinal.cyan)
            }
            .padding(12)
        }
    }
}

// MARK: - Scanner

struct OWNIQFinalScanner: View {
    @State private var activeFilter = "Objet"
    @State private var capturePulse = false
    private let filters = [("Objet", "cube"), ("Marque", "tag"), ("Valeur", "chart.line.uptrend.xyaxis"), ("3D", "cube.transparent")]

    var body: some View {
        ZStack {
            OWNIQFinalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    header
                    camera
                    captureControls
                    detectedPanel
                }
                .padding(.top, 8)
                .padding(.bottom, 108)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                FinalLogo(width: 141)
                Spacer()
                FinalCircleButton(icon: "questionmark")
            }
            Text("Scanner").font(.system(size: 34, weight: .bold))
            Text("Pointez la caméra vers un objet pour l’identifier.").font(.system(size: 16)).foregroundStyle(OWNIQFinal.secondary)
        }
        .padding(.horizontal, OWNIQFinal.pageInset)
    }

    private var camera: some View {
        ZStack {
            Image("scanner_camera").resizable().scaledToFill()
            detector(title: "Fauteuil", color: OWNIQFinal.cyan, width: 127, height: 128).offset(x: -103, y: 26)
            detector(title: "Table basse", color: OWNIQFinal.amber, width: 126, height: 75).offset(x: 18, y: 83)
            detector(title: "Bibliothèque", color: OWNIQFinal.violet, width: 124, height: 176).offset(x: 107, y: -32)
        }
        .frame(height: 310)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipped()
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.10), lineWidth: 0.7) }
    }

    private func detector(title: String, color: Color, width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color, lineWidth: 1.4)
                .frame(width: width, height: height)
                .shadow(color: color.opacity(0.70), radius: 5)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(OWNIQFinal.panel.opacity(0.88), in: RoundedRectangle(cornerRadius: 6))
                .overlay { RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.85), lineWidth: 0.9) }
                .offset(y: -28)
        }
        .frame(width: width, height: height)
    }

    private var captureControls: some View {
        HStack {
            roundControl("bolt.fill")
            Spacer()
            Button { withAnimation(.spring(response: 0.18, dampingFraction: 0.72)) { capturePulse.toggle() } } label: {
                Circle().fill(.white).frame(width: capturePulse ? 77 : 72, height: capturePulse ? 77 : 72)
                    .overlay { Circle().stroke(OWNIQFinal.cyan, lineWidth: 2).padding(-8) }
                    .shadow(color: OWNIQFinal.cyan.opacity(0.30), radius: 10)
            }
            .buttonStyle(.plain)
            Spacer()
            roundControl("arrow.triangle.2.circlepath.camera")
        }
        .padding(.horizontal, 63)
        .padding(.vertical, 4)
    }

    private func roundControl(_ icon: String) -> some View {
        Button {} label: {
            Circle().fill(OWNIQFinal.panelRaised.opacity(0.92)).overlay { Circle().stroke(OWNIQFinal.line, lineWidth: 1) }
                .frame(width: 54, height: 54)
                .overlay { Image(systemName: icon).font(.system(size: 19, weight: .medium)).foregroundStyle(.white) }
        }
        .buttonStyle(.plain)
    }

    private var detectedPanel: some View {
        FinalPanel(radius: 26, border: OWNIQFinal.cyan.opacity(0.32)) {
            VStack(spacing: 11) {
                Capsule().fill(OWNIQFinal.secondary.opacity(0.66)).frame(width: 45, height: 5).padding(.top, 7)
                HStack { Text("Objets détectés").font(.system(size: 20.5, weight: .bold)); Spacer() }
                detectedRow(asset: "scanner_chair", title: "Fauteuil", value: "98 %", color: OWNIQFinal.cyan)
                detectedRow(asset: "scanner_table", title: "Table basse", value: "96 %", color: OWNIQFinal.amber)
                detectedRow(asset: "scanner_bookshelf", title: "Bibliothèque", value: "94 %", color: OWNIQFinal.violet)
                HStack(spacing: 8) {
                    ForEach(filters, id: \.0) { item in
                        Button { activeFilter = item.0 } label: {
                            HStack(spacing: 5) { Image(systemName: item.1); Text(item.0) }
                                .font(.system(size: 11.2, weight: activeFilter == item.0 ? .semibold : .regular))
                                .foregroundStyle(activeFilter == item.0 ? OWNIQFinal.cyan : OWNIQFinal.secondary)
                                .frame(maxWidth: .infinity, minHeight: 38)
                                .background(activeFilter == item.0 ? OWNIQFinal.cyan.opacity(0.10) : .clear, in: Capsule())
                                .overlay { Capsule().stroke(activeFilter == item.0 ? OWNIQFinal.cyan : OWNIQFinal.line, lineWidth: 0.9) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 14)
    }

    private func detectedRow(asset: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(asset).resizable().scaledToFit().frame(width: 58, height: 58).background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16.5, weight: .semibold))
                Text("Mobilier").font(.system(size: 12)).foregroundStyle(OWNIQFinal.secondary)
            }
            Spacer()
            Text(value).font(.system(size: 16.5, weight: .bold)).foregroundStyle(color)
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(OWNIQFinal.secondary)
        }
        .padding(8)
        .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 15))
        .overlay { RoundedRectangle(cornerRadius: 15).stroke(OWNIQFinal.line.opacity(0.86), lineWidth: 0.8) }
    }
}

// MARK: - House

struct OWNIQFinalHouse: View {
    @State private var mode = "Manga"
    var body: some View {
        ZStack {
            OWNIQFinalBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    segmented
                    FinalAssetImage(name: "house_isometric").frame(height: 295).padding(.horizontal, 5)
                    actions
                    stats
                    roomCard
                }
                .padding(.horizontal, OWNIQFinal.pageInset)
                .padding(.top, 8)
                .padding(.bottom, 108)
            }
        }
    }

    private var header: some View {
        HStack {
            FinalCircleButton(icon: "bell", badge: true)
            Spacer()
            Text("Maison").font(.system(size: 27, weight: .bold))
            Spacer()
            FinalCircleButton(icon: "person")
        }
    }

    private var segmented: some View {
        HStack(spacing: 0) {
            segment("Réel")
            segment("Manga")
        }
        .padding(3)
        .frame(width: 235, height: 48)
        .background(OWNIQFinal.panel.opacity(0.92), in: Capsule())
        .overlay { Capsule().stroke(OWNIQFinal.line, lineWidth: 0.9) }
    }

    private func segment(_ title: String) -> some View {
        Button { withAnimation(.easeOut(duration: 0.16)) { mode = title } } label: {
            Text(title).font(.system(size: 15.5, weight: .medium)).foregroundStyle(mode == title ? Color(red: 2/255, green: 23/255, blue: 31/255) : .white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(mode == title ? OWNIQFinal.cyanGradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var actions: some View {
        HStack(spacing: 10) {
            houseAction("Explorer", "magnifyingglass", OWNIQFinal.cyan)
            houseAction("FPS", "scope", OWNIQFinal.violet)
            houseAction("Organiser", "folder", OWNIQFinal.amber)
            houseAction("Pièces", "square.on.square", OWNIQFinal.cyan)
        }
    }

    private func houseAction(_ title: String, _ icon: String, _ color: Color) -> some View {
        Button {} label: {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 29, weight: .medium)).foregroundStyle(color).frame(height: 31)
                Text(title).font(.system(size: 13.5, weight: .medium)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, minHeight: 105)
            .background(OWNIQFinal.panelRaised, in: RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(OWNIQFinal.line, lineWidth: 0.9) }
        }
        .buttonStyle(.plain)
    }

    private var stats: some View {
        HStack(spacing: 10) {
            statCard(icon: "viewfinder", value: "12", label1: "pièces scannées", label2: "sur 15", color: OWNIQFinal.cyan)
            statCard(icon: "cube", value: "248", label1: "objets détectés", label2: "sur 320", color: OWNIQFinal.violet)
            statCard(icon: "circle.dotted", value: "72 %", label1: "scène complétée", label2: "en cours", color: OWNIQFinal.amber)
        }
    }

    private func statCard(icon: String, value: String, label1: String, label2: String, color: Color) -> some View {
        FinalPanel(radius: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).font(.system(size: 25, weight: .medium)).foregroundStyle(color)
                Text(value).font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
                Text(label1).font(.system(size: 11.2)).foregroundStyle(OWNIQFinal.secondary).lineLimit(1).minimumScaleFactor(0.75)
                Text(label2).font(.system(size: 11.2, weight: .medium)).foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
        }
    }

    private var roomCard: some View {
        FinalPanel(radius: 18) {
            HStack(spacing: 14) {
                Image("house_room").resizable().scaledToFill().frame(width: 112, height: 82).clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(OWNIQFinal.cyan, lineWidth: 0.9) }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Salon").font(.system(size: 19, weight: .bold))
                    Text("Dernière mise à jour").font(.system(size: 11.5)).foregroundStyle(OWNIQFinal.secondary)
                    Text("Aujourd’hui à 09:21").font(.system(size: 11.5, weight: .medium)).foregroundStyle(OWNIQFinal.cyan)
                    Label("À jour", systemImage: "checkmark.circle").font(.system(size: 11.5)).foregroundStyle(OWNIQFinal.cyan)
                }
                Spacer()
                Button {} label: {
                    HStack(spacing: 7) { Text("Aperçu"); Image(systemName: "chevron.right") }
                        .font(.system(size: 13.5, weight: .medium)).foregroundStyle(Color(red: 2/255, green: 23/255, blue: 31/255))
                        .padding(.horizontal, 15).frame(height: 44).background(OWNIQFinal.cyanGradient, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
    }
}

// MARK: - Inventory

private struct FinalInventoryItem: Identifiable {
    let id = UUID()
    let asset, title, room, price, category: String
}

struct OWNIQFinalInventory: View {
    @State private var query = ""
    @State private var category = "Tous"
    private let categories = [("Tous", "square.grid.2x2"), ("Tech", "laptopcomputer"), ("Mobilier", "chair"), ("Collections", "star"), ("Mode", "bag")]
    private let items = [
        FinalInventoryItem(asset: "inv_macbook", title: "MacBook Pro 14”", room: "Bureau", price: "2 390 €", category: "Tech"),
        FinalInventoryItem(asset: "inv_chair", title: "Fauteuil Lounge", room: "Salon", price: "1 850 €", category: "Mobilier"),
        FinalInventoryItem(asset: "inv_pikachu", title: "Carte Pikachu Holo", room: "Collection", price: "950 €", category: "Collections"),
        FinalInventoryItem(asset: "inv_omega", title: "Montre Omega Speedmaster", room: "Chambre", price: "5 450 €", category: "Mode")
    ]

    var body: some View {
        ZStack {
            OWNIQFinalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    Text("Inventaire").font(.system(size: 34, weight: .bold)).padding(.top, 3)
                    search
                    summary
                    categoryBar
                    grid
                }
                .padding(.horizontal, OWNIQFinal.pageInset)
                .padding(.top, 9)
                .padding(.bottom, 108)
            }
        }
    }

    private var header: some View {
        HStack {
            FinalLogo(width: 143)
            Spacer()
            HStack(spacing: 9) { FinalCircleButton(icon: "bell", badge: true); FinalCircleButton(icon: "person") }
        }
    }

    private var search: some View {
        HStack(spacing: 13) {
            Image(systemName: "magnifyingglass").font(.system(size: 22)).foregroundStyle(OWNIQFinal.secondary.opacity(0.72))
            TextField("Rechercher un objet", text: $query).font(.system(size: 16)).textInputAutocapitalization(.never)
            Image(systemName: "viewfinder").font(.system(size: 22, weight: .medium)).foregroundStyle(OWNIQFinal.cyan)
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(OWNIQFinal.panelRaised.opacity(0.78), in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(OWNIQFinal.line, lineWidth: 0.9) }
    }

    private var summary: some View {
        FinalPanel(radius: 18, border: OWNIQFinal.cyan.opacity(0.55)) {
            HStack(spacing: 0) {
                inventoryMetric(icon: "cube", title: "Objets au total", value: "248", color: OWNIQFinal.cyan)
                Divider().overlay(OWNIQFinal.line).frame(height: 62)
                inventoryMetric(icon: "tag", title: "Valeur estimée totale", value: "48 750 €", color: OWNIQFinal.violet)
            }
            .padding(.vertical, 13)
        }
    }

    private func inventoryMetric(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 11) {
            FinalMetricIcon(icon: icon, color: color)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12)).foregroundStyle(OWNIQFinal.secondary).lineLimit(1).minimumScaleFactor(0.75)
                Text(value).font(.system(size: 22, weight: .bold)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
    }

    private var categoryBar: some View {
        HStack(spacing: 8) {
            ForEach(categories, id: \.0) { item in
                Button { category = item.0 } label: {
                    VStack(spacing: 7) {
                        Image(systemName: item.1).font(.system(size: 18, weight: .medium))
                        Text(item.0).font(.system(size: 11.2, weight: category == item.0 ? .semibold : .medium)).lineLimit(1).minimumScaleFactor(0.72)
                    }
                    .foregroundStyle(category == item.0 ? .white : OWNIQFinal.secondary)
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .background(category == item.0 ? OWNIQFinal.cyan.opacity(0.13) : OWNIQFinal.panelRaised.opacity(0.72), in: RoundedRectangle(cornerRadius: 15))
                    .overlay { RoundedRectangle(cornerRadius: 15).stroke(category == item.0 ? OWNIQFinal.cyan : OWNIQFinal.line, lineWidth: category == item.0 ? 1.1 : 0.8) }
                    .shadow(color: category == item.0 ? OWNIQFinal.cyan.opacity(0.22) : .clear, radius: 8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filtered: [FinalInventoryItem] {
        items.filter { item in
            (category == "Tous" || item.category == category) && (query.isEmpty || item.title.localizedCaseInsensitiveContains(query))
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(filtered) { item in inventoryCard(item) }
        }
    }

    private func inventoryCard(_ item: FinalInventoryItem) -> some View {
        FinalPanel(radius: 18) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(item.asset).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: 156).padding(.horizontal, 4)
                    Image(systemName: "ellipsis").font(.caption.bold()).padding(8)
                }
                Text(item.title).font(.system(size: 15.5, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.72)
                Text(item.room).font(.system(size: 11.5)).foregroundStyle(OWNIQFinal.secondary)
                Text(item.price).font(.system(size: 16, weight: .semibold)).foregroundStyle(OWNIQFinal.cyan)
            }
            .padding(10)
        }
    }
}

// MARK: - Profile

struct OWNIQFinalProfile: View {
    private let settings: [(String, String, Color)] = [
        ("Compte", "person", OWNIQFinal.cyan),
        ("Sécurité", "checkmark.shield", OWNIQFinal.violet),
        ("Confidentialité", "lock", OWNIQFinal.violet),
        ("Sauvegarde locale", "icloud.and.arrow.up", OWNIQFinal.cyan),
        ("Notifications", "bell", OWNIQFinal.amber),
        ("Apparence", "paintpalette", OWNIQFinal.violet),
        ("Téléchargements IA", "brain.head.profile", OWNIQFinal.cyan)
    ]
    private let help: [(String, String, Color)] = [
        ("Aide", "questionmark.circle", OWNIQFinal.cyan),
        ("Nous contacter", "bubble.left.and.bubble.right", OWNIQFinal.violet),
        ("À propos", "info.circle", OWNIQFinal.amber)
    ]

    var body: some View {
        ZStack {
            OWNIQFinalBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 13) {
                    header
                    profileCard
                    settingsCard
                    storageCard
                    Text("Assistance").font(.system(size: 14.5, weight: .medium)).foregroundStyle(OWNIQFinal.cyan).padding(.leading, 5)
                    assistanceCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 108)
            }
        }
    }

    private var header: some View {
        HStack { FinalLogo(width: 126); Spacer(); Text("Paramètres").font(.system(size: 20, weight: .semibold)) }
    }

    private var profileCard: some View {
        HStack(spacing: 18) {
            Image("profile_avatar").resizable().scaledToFill().frame(width: 86, height: 86).clipShape(Circle())
                .overlay { Circle().stroke(OWNIQFinal.cyan, lineWidth: 1.1) }
                .shadow(color: OWNIQFinal.cyan.opacity(0.34), radius: 10)
            VStack(alignment: .leading, spacing: 5) {
                Text("Alex Dupont").font(.system(size: 25, weight: .bold))
                Label("OWNIQ Premium", systemImage: "crown.fill").font(.system(size: 13.8, weight: .medium)).foregroundStyle(OWNIQFinal.cyan)
                Text("Expérience complète débloquée").font(.system(size: 12.2)).foregroundStyle(OWNIQFinal.secondary)
            }
            Spacer(minLength: 2)
            Image(systemName: "chevron.right").font(.system(size: 18, weight: .medium))
        }
        .padding(18)
        .background(OWNIQFinal.panelGradient, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(OWNIQFinal.cyan.opacity(0.70), lineWidth: 0.9) }
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(settings.enumerated()), id: \.offset) { index, item in
                settingsRow(item.0, icon: item.1, color: item.2)
                if index != settings.count - 1 { Divider().overlay(OWNIQFinal.line).padding(.leading, 47) }
            }
        }
        .padding(.horizontal, 14)
        .background(OWNIQFinal.panelGradient, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(OWNIQFinal.cyan.opacity(0.53), lineWidth: 0.8) }
    }

    private func settingsRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 19, weight: .medium)).foregroundStyle(color).frame(width: 28)
            Text(title).font(.system(size: 16.2, weight: .medium))
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold))
        }
        .frame(height: 47)
    }

    private var storageCard: some View {
        VStack(spacing: 11) {
            HStack {
                Text("Stockage – Modèles IA / Packs").font(.system(size: 15.2, weight: .medium))
                Spacer(); Text("72 % utilisé").font(.system(size: 12)).foregroundStyle(OWNIQFinal.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.13))
                    Capsule().fill(OWNIQFinal.cyanGradient).frame(width: geo.size.width * 0.72)
                }
            }
            .frame(height: 6)
            HStack {
                Text("57,6 Go utilisés sur 80 Go").font(.system(size: 11.5)).foregroundStyle(OWNIQFinal.secondary)
                Spacer(); Text("Gérer").font(.system(size: 12.5, weight: .medium)).foregroundStyle(OWNIQFinal.cyan)
            }
            HStack(spacing: 10) {
                storageMetric(icon: "cube", value: "12", label: "Packs installés")
                storageMetric(icon: "arrow.down.to.line", value: "3,2 Go", label: "Espace disponible")
            }
        }
        .padding(15)
        .background(OWNIQFinal.panelGradient, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(OWNIQFinal.cyan.opacity(0.58), lineWidth: 0.8) }
    }

    private func storageMetric(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 21, weight: .medium)).foregroundStyle(OWNIQFinal.cyan)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 18, weight: .semibold))
                Text(label).font(.system(size: 10.8)).foregroundStyle(OWNIQFinal.secondary).lineLimit(1).minimumScaleFactor(0.78)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity, minHeight: 55)
        .background(OWNIQFinal.panel.opacity(0.74), in: RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(OWNIQFinal.line, lineWidth: 0.75) }
    }

    private var assistanceCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(help.enumerated()), id: \.offset) { index, item in
                settingsRow(item.0, icon: item.1, color: item.2)
                if index != help.count - 1 { Divider().overlay(OWNIQFinal.line).padding(.leading, 47) }
            }
        }
        .padding(.horizontal, 14)
        .background(OWNIQFinal.panelGradient, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(OWNIQFinal.cyan.opacity(0.53), lineWidth: 0.8) }
    }
}
