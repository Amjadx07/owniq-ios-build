import SwiftUI
import SceneKit
import simd

enum RoomCameraMode: String, CaseIterable, Identifiable {
    case threeD = "3D"
    case fps = "FPS"
    case top = "Dessus"
    var id: String { rawValue }
}

struct SceneRoomView: UIViewRepresentable {
    let url: URL
    let style: RoomDetailView.RenderStyle
    let cameraMode: RoomCameraMode

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = UIColor.black
        view.antialiasingMode = .multisampling4X
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = false
        view.preferredFramesPerSecond = 60
        context.coordinator.attach(to: view)
        render(in: view, coordinator: context.coordinator)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        let coordinator = context.coordinator
        if coordinator.style != style.rawValue {
            render(in: view, coordinator: coordinator)
        } else if coordinator.mode != cameraMode {
            coordinator.mode = cameraMode
            coordinator.configureCamera(for: cameraMode)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var view: SCNView?
        var style = ""
        var mode: RoomCameraMode = .threeD
        var camera = SCNNode()
        var center = SIMD3<Float>(0, 0, 0)
        var span: Float = 3
        var orbitYaw: Float = .pi * 0.25
        var orbitPitch: Float = -0.38
        var orbitDistance: Float = 4

        func attach(to view: SCNView) {
            self.view = view

            let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
            pan.maximumNumberOfTouches = 2
            pan.delegate = self
            view.addGestureRecognizer(pan)

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
            pinch.delegate = self
            view.addGestureRecognizer(pinch)

            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(recenter))
            doubleTap.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTap)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool { true }

        @objc func recenter() {
            configureCamera(for: mode)
        }

        @objc func pan(_ gesture: UIPanGestureRecognizer) {
            guard let view, gesture.state == .changed else { return }
            let delta = gesture.translation(in: view)
            let dx = Float(delta.x)
            let dy = Float(delta.y)

            switch mode {
            case .fps:
                if gesture.numberOfTouches <= 1 {
                    // Mobile-game style: one thumb turns and walks directly.
                    camera.eulerAngles.y -= dx * 0.0047
                    camera.eulerAngles.z = 0
                    let yaw = camera.eulerAngles.y
                    let forward = SIMD3<Float>(-sinf(yaw), 0, -cosf(yaw))
                    camera.simdPosition += forward * (-dy * max(0.0017, span * 0.00085))
                } else {
                    let yaw = camera.eulerAngles.y
                    let right = SIMD3<Float>(cosf(yaw), 0, -sinf(yaw))
                    camera.simdPosition += right * (-dx * max(0.0017, span * 0.00085))
                    camera.eulerAngles.x = max(-0.62, min(0.62, camera.eulerAngles.x - dy * 0.0032))
                    camera.eulerAngles.z = 0
                }

            case .top:
                let speed = max(0.002, span * 0.00105)
                camera.position.x -= dx * speed
                camera.position.z -= dy * speed
                camera.eulerAngles.z = 0

            case .threeD:
                orbitYaw -= dx * 0.0045
                orbitPitch = max(-1.12, min(-0.08, orbitPitch - dy * 0.0038))
                updateOrbit()
            }

            gesture.setTranslation(.zero, in: view)
        }

        @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
            guard gesture.state == .changed else { return }
            let factor = Float(1 / max(0.82, min(1.18, gesture.scale)))

            switch mode {
            case .fps:
                let yaw = camera.eulerAngles.y
                let forward = SIMD3<Float>(-sinf(yaw), 0, -cosf(yaw))
                camera.simdPosition += forward * ((1 - factor) * span * 0.55)

            case .top:
                let height = max(span * 0.55, min(span * 4.5, camera.simdPosition.y * factor))
                camera.simdPosition.y = height

            case .threeD:
                orbitDistance = max(span * 0.28, min(span * 4.2, orbitDistance * factor))
                updateOrbit()
            }
            gesture.scale = 1
        }

        func configureCamera(for mode: RoomCameraMode) {
            self.mode = mode
            camera.eulerAngles = SCNVector3Zero
            camera.camera?.fieldOfView = mode == .fps ? 72 : 55

            switch mode {
            case .threeD:
                orbitYaw = .pi * 0.25
                orbitPitch = -0.42
                orbitDistance = max(2.2, span * 1.15)
                updateOrbit()

            case .fps:
                camera.simdPosition = SIMD3(center.x, max(center.y + span * 0.08, 1.35), center.z + span * 0.28)
                lookUpright(at: SIMD3(center.x, camera.simdPosition.y, center.z - span * 0.60))

            case .top:
                camera.simdPosition = SIMD3(center.x, center.y + max(3, span * 1.6), center.z + 0.001)
                camera.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                camera.eulerAngles.z = 0
            }
            view?.pointOfView = camera
        }

        private func updateOrbit() {
            let horizontal = cosf(orbitPitch) * orbitDistance
            camera.simdPosition = SIMD3(
                center.x + sinf(orbitYaw) * horizontal,
                center.y - sinf(orbitPitch) * orbitDistance,
                center.z + cosf(orbitYaw) * horizontal
            )
            lookUpright(at: center)
        }

        private func lookUpright(at target: SIMD3<Float>) {
            camera.look(
                at: SCNVector3(target.x, target.y, target.z),
                up: SCNVector3(0, 1, 0),
                localFront: SCNVector3(0, 0, -1)
            )
            var euler = camera.eulerAngles
            euler.z = 0
            camera.eulerAngles = euler
        }
    }

    private func render(in view: SCNView, coordinator: Coordinator) {
        guard let scene = try? SCNScene(url: url, options: nil) else { return }

        removeGeneratedNodes(scene)
        apply(style, to: scene)

        let box = scene.rootNode.boundingBox
        let center = SIMD3<Float>(
            (box.min.x + box.max.x) * 0.5,
            (box.min.y + box.max.y) * 0.5,
            (box.min.z + box.max.z) * 0.5
        )
        let span = max(
            Float(1.2),
            max(box.max.x - box.min.x, max(box.max.y - box.min.y, box.max.z - box.min.z))
        )

        let camera = SCNNode()
        camera.name = "owniq.public.camera"
        camera.camera = SCNCamera()
        camera.camera?.zNear = 0.025
        camera.camera?.zFar = 300
        scene.rootNode.addChildNode(camera)

        coordinator.camera = camera
        coordinator.center = center
        coordinator.span = span
        coordinator.style = style.rawValue
        coordinator.mode = cameraMode
        coordinator.orbitDistance = max(2.2, span * 1.15)

        view.scene = scene
        coordinator.configureCamera(for: cameraMode)
    }

    private func apply(_ style: RoomDetailView.RenderStyle, to scene: SCNScene) {
        var index = 0
        let palette: [UIColor] = [
            UIColor(red: 0.72, green: 0.68, blue: 0.62, alpha: 1),
            UIColor(red: 0.48, green: 0.45, blue: 0.41, alpha: 1),
            UIColor(red: 0.61, green: 0.57, blue: 0.51, alpha: 1),
            UIColor(red: 0.82, green: 0.79, blue: 0.72, alpha: 1)
        ]

        var nodes: [SCNNode] = []
        scene.rootNode.enumerateChildNodes { node, _ in
            if node.geometry != nil, node.name?.hasPrefix("owniq.public.") != true {
                nodes.append(node)
            }
        }

        for node in nodes {
            guard let geometry = node.geometry else { continue }
            let structural = isStructural(node)
            let sourceColor = geometry.materials.compactMap { material -> UIColor? in
                if let color = material.diffuse.contents as? UIColor { return color }
                if let color = material.diffuse.contents as? CGColor { return UIColor(cgColor: color) }
                return nil
            }.first

            if style == .real {
                for material in geometry.materials {
                    material.lightingModel = .physicallyBased
                    material.roughness.contents = structural ? 0.92 : 0.76
                    material.metalness.contents = 0.01
                    material.isDoubleSided = true
                    material.shaderModifiers = nil
                }
            } else {
                let base = sourceColor ?? palette[index % palette.count]
                index += 1
                let material = SCNMaterial()
                material.diffuse.contents = normalizedMangaColor(base, structural: structural)
                material.lightingModel = .lambert
                material.roughness.contents = 1.0
                material.metalness.contents = 0.0
                material.isDoubleSided = true
                material.shaderModifiers = [
                    .fragment: "#pragma body\n_output.color.rgb = floor(_output.color.rgb * 4.0 + 0.5) / 4.0;"
                ]
                geometry.materials = [material]
                if !structural || shouldOutline(node) { installOutline(on: node) }
            }
        }

        installLighting(in: scene, manga: style == .manga)
        scene.background.contents = style == .manga
            ? UIColor(red: 0.93, green: 0.91, blue: 0.86, alpha: 1)
            : UIColor(red: 0.045, green: 0.05, blue: 0.06, alpha: 1)
    }

    private func installLighting(in scene: SCNScene, manga: Bool) {
        let ambient = SCNNode()
        ambient.name = "owniq.public.ambient"
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = manga ? 360 : 300
        ambient.light?.color = manga ? UIColor(white: 0.96, alpha: 1) : UIColor(red: 1, green: 0.96, blue: 0.91, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.name = "owniq.public.key"
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = manga ? 620 : 900
        key.light?.castsShadow = true
        key.eulerAngles = SCNVector3(-0.82, -0.62, 0)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.name = "owniq.public.fill"
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = manga ? 210 : 300
        fill.eulerAngles = SCNVector3(-0.35, 2.3, 0)
        scene.rootNode.addChildNode(fill)
    }

    private func installOutline(on node: SCNNode) {
        guard let geometry = node.geometry?.copy() as? SCNGeometry else { return }
        let ink = SCNMaterial()
        ink.diffuse.contents = UIColor(white: 0.08, alpha: 1)
        ink.emission.contents = UIColor(white: 0.08, alpha: 1)
        ink.lightingModel = .constant
        ink.cullMode = .front
        geometry.materials = [ink]
        let outline = SCNNode(geometry: geometry)
        outline.name = "owniq.public.outline"
        outline.scale = SCNVector3(1.006, 1.006, 1.006)
        node.addChildNode(outline)
    }

    private func removeGeneratedNodes(_ scene: SCNScene) {
        var generated: [SCNNode] = []
        scene.rootNode.enumerateChildNodes { node, _ in
            if node.name?.hasPrefix("owniq.public.") == true { generated.append(node) }
        }
        generated.forEach { $0.removeFromParentNode() }
    }

    private func isStructural(_ node: SCNNode) -> Bool {
        let value = (node.name ?? "").lowercased()
        return ["wall", "floor", "ceiling", "door", "window", "opening", "mur", "sol", "plafond"]
            .contains(where: { value.contains($0) })
    }

    private func shouldOutline(_ node: SCNNode) -> Bool {
        let value = (node.name ?? "").lowercased()
        return ["door", "window", "opening", "porte", "fenetre", "fenêtre"]
            .contains(where: { value.contains($0) })
    }

    private func normalizedMangaColor(_ color: UIColor, structural: Bool) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return structural ? UIColor(white: 0.84, alpha: 1) : color
        }
        return UIColor(
            hue: h,
            saturation: structural ? min(s, 0.18) : min(max(s, 0.18), 0.55),
            brightness: structural ? max(0.76, b) : min(max(b, 0.46), 0.88),
            alpha: 1
        )
    }
}
