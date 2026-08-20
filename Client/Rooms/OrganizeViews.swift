import SwiftUI
import SceneKit
import RoomPlan
import simd

struct Organize2DView: View {
    @Environment(\.dismiss) private var dismiss
    let room: CapturedRoom
    let roomID: UUID

    @State private var offsets: [UUID: CGSize] = [:]
    @State private var selected: UUID?
    @State private var savedToast = false

    private var storageKey: String { "owniq.public.organize2d.\(roomID.uuidString)" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("PLAN INTERACTIF")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.owniqSignal)
                        Text("Déplace les meubles")
                            .font(.title3.bold())
                    }
                    Spacer()
                    Button("Enregistrer") { saveLayout() }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.owniqSignal)
                }
                .padding()

                GeometryReader { geo in
                    let bounds = boundsFor(room.objects)
                    ZStack {
                        Color.owniqBackground
                        roomOutline(bounds: bounds, size: geo.size)

                        ForEach(room.objects, id: \.identifier) { object in
                            piece(object, bounds: bounds, size: geo.size)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Text("Glisse directement un bloc · la disposition d'origine reste intacte")
                            .font(.caption)
                            .foregroundStyle(Color.owniqSecondary)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.bottom, 12)
                    }
                }
            }
            .owniqBackground()
            .navigationTitle("Organiser en 2D")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Réinitialiser") {
                        offsets = [:]
                        UserDefaults.standard.removeObject(forKey: storageKey)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .onAppear { loadLayout() }
            .alert("Disposition enregistrée", isPresented: $savedToast) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Le scénario est gardé localement. Le scan RoomPlan d'origine n'est pas modifié.")
            }
        }
    }

    @ViewBuilder
    private func roomOutline(
        bounds: (minX: Float, maxX: Float, minZ: Float, maxZ: Float),
        size: CGSize
    ) -> some View {
        let inset: CGFloat = 26
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color.white.opacity(0.18), lineWidth: 2)
            .padding(inset)
    }

    private func piece(
        _ object: CapturedRoom.Object,
        bounds: (minX: Float, maxX: Float, minZ: Float, maxZ: Float),
        size: CGSize
    ) -> some View {
        let widthRange = max(0.1, bounds.maxX - bounds.minX)
        let depthRange = max(0.1, bounds.maxZ - bounds.minZ)
        let x = object.transform.columns.3.x
        let z = object.transform.columns.3.z
        let nx = CGFloat((x - bounds.minX) / widthRange)
        let nz = CGFloat((z - bounds.minZ) / depthRange)
        let usableW = max(1, size.width - 60)
        let usableH = max(1, size.height - 90)
        let width = min(150, max(58, CGFloat(object.dimensions.x / widthRange) * usableW))
        let height = min(110, max(48, CGFloat(object.dimensions.z / depthRange) * usableH))
        let isSelected = selected == object.identifier

        return VStack(spacing: 3) {
            Image(systemName: "move.3d")
                .font(.caption)
            Text(RoomObjectNaming.name(object.category).replacingOccurrences(of: " à confirmer", with: ""))
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .frame(width: width, height: height)
        .background(
            isSelected ? Color.owniqSignal.opacity(0.34) : Color.owniqViolet.opacity(0.24),
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isSelected ? Color.owniqSignal : Color.white.opacity(0.18), lineWidth: isSelected ? 2 : 1)
        }
        .position(
            x: 30 + nx * usableW,
            y: 36 + nz * usableH
        )
        .offset(offsets[object.identifier] ?? .zero)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    selected = object.identifier
                    offsets[object.identifier] = value.translation
                }
                .onEnded { _ in selected = nil }
        )
        .accessibilityLabel(RoomObjectNaming.name(object.category))
        .accessibilityHint("Glisse pour déplacer")
    }

    private func boundsFor(_ objects: [CapturedRoom.Object]) -> (minX: Float, maxX: Float, minZ: Float, maxZ: Float) {
        guard !objects.isEmpty else { return (-2, 2, -2, 2) }
        let xs = objects.map { $0.transform.columns.3.x }
        let zs = objects.map { $0.transform.columns.3.z }
        return (
            (xs.min() ?? -2) - 1,
            (xs.max() ?? 2) + 1,
            (zs.min() ?? -2) - 1,
            (zs.max() ?? 2) + 1
        )
    }

    private func saveLayout() {
        let raw = offsets.reduce(into: [String: [Double]]()) { result, entry in
            result[entry.key.uuidString] = [Double(entry.value.width), Double(entry.value.height)]
        }
        UserDefaults.standard.set(raw, forKey: storageKey)
        savedToast = true
    }

    private func loadLayout() {
        guard let raw = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: [Double]] else { return }
        offsets = raw.reduce(into: [UUID: CGSize]()) { result, entry in
            guard let id = UUID(uuidString: entry.key), entry.value.count == 2 else { return }
            result[id] = CGSize(width: entry.value[0], height: entry.value[1])
        }
    }
}

struct Organize3DView: View {
    enum CameraMode: String, CaseIterable, Identifiable {
        case top = "Plan"
        case threeD = "3D"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    let room: CapturedRoom
    let roomID: UUID

    @State private var selectedID: UUID?
    @State private var cameraMode: CameraMode = .top
    @State private var saveNonce = 0
    @State private var resetNonce = 0
    @State private var recenterNonce = 0
    @State private var saved = false

    var body: some View {
        ZStack {
            Organize3DSceneView(
                room: room,
                roomID: roomID,
                selectedID: $selectedID,
                cameraMode: cameraMode,
                saveNonce: saveNonce,
                resetNonce: resetNonce,
                recenterNonce: recenterNonce
            )
            .ignoresSafeArea()

            VStack {
                HStack(spacing: 10) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Réagencer")
                            .font(.headline.bold())
                        Text(selectedID == nil ? "Touchez un meuble" : "Meuble sélectionné")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    Spacer()
                    Button { recenterNonce += 1 } label: {
                        Image(systemName: "scope")
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Recentrer")
                    Button {
                        saveNonce += 1
                        saved = true
                    } label: {
                        Image(systemName: "checkmark")
                            .frame(width: 42, height: 42)
                            .background(Color.owniqSignal.opacity(0.28), in: Circle())
                    }
                    .accessibilityLabel("Enregistrer")
                }
                .padding()

                Spacer()

                VStack(spacing: 10) {
                    Picker("Vue", selection: $cameraMode) {
                        ForEach(CameraMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 9) {
                        Image(systemName: selectedID == nil ? "hand.draw" : "move.3d")
                            .foregroundStyle(Color.owniqSignal)
                        Text(instruction)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.80))
                        Spacer()
                        if selectedID != nil {
                            Button("OK") { selectedID = nil }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.owniqSignal)
                        }
                    }

                    HStack {
                        Button {
                            resetNonce += 1
                            selectedID = nil
                        } label: {
                            Label("Réinitialiser", systemImage: "arrow.counterclockwise")
                        }
                        .font(.caption.weight(.semibold))
                        Spacer()
                        Text("Le scan d'origine reste intact")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 23, style: .continuous))
                .padding()
            }
            .foregroundStyle(.white)
        }
        .background(Color.black)
        .alert("Disposition enregistrée", isPresented: $saved) {
            Button("OK", role: .cancel) {}
        }
    }

    private var instruction: String {
        if selectedID != nil {
            return "1 doigt : déplacer · 2 doigts : tourner · le meuble reste au sol"
        }
        return cameraMode == .top
            ? "Glisse le plan · pince pour zoomer · touche un meuble pour le sélectionner"
            : "Glisse pour tourner autour · pince pour zoomer · touche un meuble pour le sélectionner"
    }
}

private struct Organize3DSceneView: UIViewRepresentable {
    let room: CapturedRoom
    let roomID: UUID
    @Binding var selectedID: UUID?
    let cameraMode: Organize3DView.CameraMode
    let saveNonce: Int
    let resetNonce: Int
    let recenterNonce: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedID: $selectedID, roomID: roomID)
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = UIColor(red: 0.045, green: 0.05, blue: 0.06, alpha: 1)
        view.antialiasingMode = .multisampling4X
        view.autoenablesDefaultLighting = false
        context.coordinator.build(room: room, in: view)
        context.coordinator.installGestures(on: view)
        context.coordinator.setCamera(cameraMode, force: true)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        let c = context.coordinator
        c.setCamera(cameraMode)
        if c.selectedLocal != selectedID {
            c.selectedLocal = selectedID
            c.highlight()
        }
        if c.lastSave != saveNonce { c.lastSave = saveNonce; c.save() }
        if c.lastReset != resetNonce { c.lastReset = resetNonce; c.reset() }
        if c.lastRecenter != recenterNonce { c.lastRecenter = recenterNonce; c.recenter() }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        struct Pose: Codable {
            var x: Float
            var y: Float
            var z: Float
            var yaw: Float
        }

        @Binding var selectedID: UUID?
        let roomID: UUID
        weak var view: SCNView?
        var selectedLocal: UUID?
        var nodes: [UUID: SCNNode] = [:]
        var originals: [UUID: simd_float4x4] = [:]
        var sizes: [UUID: SIMD3<Float>] = [:]
        var poses: [UUID: Pose] = [:]
        var camera = SCNNode()
        var center = SIMD3<Float>(0, 0, 0)
        var span: Float = 4
        var orbitYaw: Float = .pi * 0.25
        var orbitPitch: Float = -0.48
        var orbitDistance: Float = 5
        var currentMode: Organize3DView.CameraMode = .top
        var lastSave = -1
        var lastReset = -1
        var lastRecenter = -1
        var lastCamera: Organize3DView.CameraMode?

        private var storageKey: String { "owniq.public.organize3d.\(roomID.uuidString)" }

        init(selectedID: Binding<UUID?>, roomID: UUID) {
            _selectedID = selectedID
            self.roomID = roomID
        }

        func build(room: CapturedRoom, in view: SCNView) {
            self.view = view
            let scene = SCNScene()

            let floor = SCNNode(geometry: SCNFloor())
            floor.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.16, green: 0.17, blue: 0.19, alpha: 1)
            floor.geometry?.firstMaterial?.roughness.contents = 0.95
            scene.rootNode.addChildNode(floor)

            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 420
            scene.rootNode.addChildNode(ambient)

            let key = SCNNode()
            key.light = SCNLight()
            key.light?.type = .directional
            key.light?.intensity = 900
            key.light?.castsShadow = true
            key.eulerAngles = SCNVector3(-0.85, -0.55, 0)
            scene.rootNode.addChildNode(key)

            for wall in room.walls {
                let d = wall.dimensions
                let box = SCNBox(
                    width: CGFloat(max(0.03, d.x)),
                    height: CGFloat(max(0.03, d.y)),
                    length: CGFloat(max(0.03, d.z)),
                    chamferRadius: 0
                )
                let material = SCNMaterial()
                material.diffuse.contents = UIColor(white: 0.64, alpha: 0.32)
                material.isDoubleSided = true
                box.materials = [material]
                let node = SCNNode(geometry: box)
                node.simdTransform = wall.transform
                scene.rootNode.addChildNode(node)
            }

            for object in room.objects {
                let d = object.dimensions
                let box = SCNBox(
                    width: CGFloat(max(0.08, d.x)),
                    height: CGFloat(max(0.08, d.y)),
                    length: CGFloat(max(0.08, d.z)),
                    chamferRadius: 0.035
                )
                let material = SCNMaterial()
                material.diffuse.contents = color(for: object.category)
                material.lightingModel = .physicallyBased
                material.roughness.contents = 0.72
                box.materials = [material]

                let node = SCNNode(geometry: box)
                node.name = "owniq-object-\(object.identifier.uuidString)"
                node.simdTransform = object.transform
                scene.rootNode.addChildNode(node)
                nodes[object.identifier] = node
                originals[object.identifier] = object.transform
                sizes[object.identifier] = object.dimensions
            }

            load()
            applyPoses()

            let xs = room.objects.map { $0.transform.columns.3.x }
            let zs = room.objects.map { $0.transform.columns.3.z }
            let minX = xs.min() ?? -2
            let maxX = xs.max() ?? 2
            let minZ = zs.min() ?? -2
            let maxZ = zs.max() ?? 2
            center = SIMD3((minX + maxX) * 0.5, 0.8, (minZ + maxZ) * 0.5)
            span = max(2.5, max(maxX - minX, maxZ - minZ) + 2)

            camera.camera = SCNCamera()
            camera.camera?.zNear = 0.02
            camera.camera?.zFar = 300
            scene.rootNode.addChildNode(camera)
            view.scene = scene
            view.pointOfView = camera
        }

        func installGestures(on view: SCNView) {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
            view.addGestureRecognizer(tap)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
            pan.maximumNumberOfTouches = 2
            pan.delegate = self
            view.addGestureRecognizer(pan)

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
            pinch.delegate = self
            view.addGestureRecognizer(pinch)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool { true }

        @objc func tap(_ gesture: UITapGestureRecognizer) {
            guard let view else { return }
            let point = gesture.location(in: view)
            guard let hit = view.hitTest(point, options: nil).first else {
                select(nil)
                return
            }
            var node: SCNNode? = hit.node
            while let current = node {
                if let name = current.name,
                   name.hasPrefix("owniq-object-"),
                   let id = UUID(uuidString: String(name.dropFirst("owniq-object-".count))) {
                    select(id)
                    return
                }
                node = current.parent
            }
            select(nil)
        }

        @objc func pan(_ gesture: UIPanGestureRecognizer) {
            guard let view, gesture.state == .changed else { return }
            let delta = gesture.translation(in: view)

            if let id = selectedLocal, let node = nodes[id] {
                if gesture.numberOfTouches >= 2 {
                    node.eulerAngles.y -= Float(delta.x) * 0.006
                    var pose = poses[id] ?? poseFor(node)
                    pose.yaw = node.eulerAngles.y
                    poses[id] = pose
                } else {
                    let point = gesture.location(in: view)
                    if let world = worldPoint(onY: node.simdPosition.y, screen: point, view: view) {
                        let snapped = SIMD3(
                            (world.x / 0.05).rounded() * 0.05,
                            node.simdPosition.y,
                            (world.z / 0.05).rounded() * 0.05
                        )
                        if !collides(id, at: snapped) {
                            node.simdPosition = snapped
                            poses[id] = poseFor(node)
                        }
                    }
                }
            } else {
                moveCamera(delta)
            }

            gesture.setTranslation(.zero, in: view)
        }

        @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
            guard gesture.state == .changed else { return }
            let factor = Float(1 / max(0.82, min(1.18, gesture.scale)))
            if currentMode == .top {
                camera.simdPosition.y = max(span * 0.55, min(span * 4, camera.simdPosition.y * factor))
            } else {
                orbitDistance = max(span * 0.35, min(span * 4, orbitDistance * factor))
                updateOrbit()
            }
            gesture.scale = 1
        }

        func setCamera(_ mode: Organize3DView.CameraMode, force: Bool = false) {
            guard force || lastCamera != mode else { return }
            lastCamera = mode
            currentMode = mode
            recenter()
        }

        func recenter() {
            if currentMode == .top {
                camera.simdPosition = SIMD3(center.x, center.y + span * 1.55, center.z + 0.001)
                camera.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            } else {
                orbitYaw = .pi * 0.25
                orbitPitch = -0.48
                orbitDistance = span * 1.2
                updateOrbit()
            }
        }

        private func moveCamera(_ delta: CGPoint) {
            if currentMode == .top {
                let speed = span * 0.001
                camera.simdPosition.x -= Float(delta.x) * speed
                camera.simdPosition.z -= Float(delta.y) * speed
            } else {
                orbitYaw -= Float(delta.x) * 0.0045
                orbitPitch = max(-1.10, min(-0.10, orbitPitch - Float(delta.y) * 0.0038))
                updateOrbit()
            }
        }

        private func updateOrbit() {
            let horizontal = cosf(orbitPitch) * orbitDistance
            camera.simdPosition = SIMD3(
                center.x + sinf(orbitYaw) * horizontal,
                center.y - sinf(orbitPitch) * orbitDistance,
                center.z + cosf(orbitYaw) * horizontal
            )
            camera.look(
                at: SCNVector3(center.x, center.y, center.z),
                up: SCNVector3(0, 1, 0),
                localFront: SCNVector3(0, 0, -1)
            )
            var e = camera.eulerAngles
            e.z = 0
            camera.eulerAngles = e
        }

        private func worldPoint(onY y: Float, screen: CGPoint, view: SCNView) -> SIMD3<Float>? {
            let near = view.unprojectPoint(SCNVector3(Float(screen.x), Float(screen.y), 0))
            let far = view.unprojectPoint(SCNVector3(Float(screen.x), Float(screen.y), 1))
            let direction = SIMD3<Float>(far.x - near.x, far.y - near.y, far.z - near.z)
            guard abs(direction.y) > 0.0001 else { return nil }
            let t = (y - near.y) / direction.y
            guard t > 0 else { return nil }
            return SIMD3<Float>(near.x, near.y, near.z) + direction * t
        }

        private func collides(_ movingID: UUID, at point: SIMD3<Float>) -> Bool {
            guard let moving = sizes[movingID] else { return false }
            for (id, node) in nodes where id != movingID {
                guard let size = sizes[id] else { continue }
                let p = node.simdPosition
                let overlapX = abs(point.x - p.x) < (moving.x + size.x) * 0.43
                let overlapZ = abs(point.z - p.z) < (moving.z + size.z) * 0.43
                if overlapX && overlapZ { return true }
            }
            return false
        }

        private func select(_ id: UUID?) {
            selectedLocal = id
            selectedID = id
            highlight()
        }

        func highlight() {
            for (id, node) in nodes {
                node.geometry?.firstMaterial?.emission.contents = id == selectedLocal
                    ? UIColor(red: 0.35, green: 0.88, blue: 0.67, alpha: 0.30)
                    : UIColor.clear
                node.scale = id == selectedLocal ? SCNVector3(1.025, 1.025, 1.025) : SCNVector3(1, 1, 1)
            }
        }

        func reset() {
            poses.removeAll()
            UserDefaults.standard.removeObject(forKey: storageKey)
            for (id, transform) in originals { nodes[id]?.simdTransform = transform }
            select(nil)
            recenter()
        }

        func save() {
            for (id, node) in nodes { poses[id] = poseFor(node) }
            if let data = try? JSONEncoder().encode(poses) {
                UserDefaults.standard.set(data, forKey: storageKey)
            }
        }

        private func load() {
            guard let data = UserDefaults.standard.data(forKey: storageKey),
                  let decoded = try? JSONDecoder().decode([UUID: Pose].self, from: data) else { return }
            poses = decoded
        }

        private func applyPoses() {
            for (id, pose) in poses {
                guard let node = nodes[id] else { continue }
                node.simdPosition = SIMD3(pose.x, pose.y, pose.z)
                node.eulerAngles.y = pose.yaw
            }
        }

        private func poseFor(_ node: SCNNode) -> Pose {
            let p = node.simdPosition
            return Pose(x: p.x, y: p.y, z: p.z, yaw: node.eulerAngles.y)
        }

        private func color(for category: CapturedRoom.Object.Category) -> UIColor {
            switch category {
            case .bed: UIColor(red: 0.52, green: 0.47, blue: 0.42, alpha: 1)
            case .chair: UIColor(red: 0.40, green: 0.44, blue: 0.45, alpha: 1)
            case .sofa: UIColor(red: 0.47, green: 0.42, blue: 0.39, alpha: 1)
            case .table: UIColor(red: 0.46, green: 0.34, blue: 0.25, alpha: 1)
            case .television: UIColor(red: 0.18, green: 0.19, blue: 0.21, alpha: 1)
            default: UIColor(red: 0.50, green: 0.50, blue: 0.47, alpha: 1)
            }
        }
    }
}
