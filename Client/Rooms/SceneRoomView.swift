import SwiftUI
import SceneKit

struct SceneRoomView: UIViewRepresentable {
    let url: URL
    let style: RoomDetailView.RenderStyle

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = UIColor.black
        view.antialiasingMode = .multisampling4X
        view.autoenablesDefaultLighting = true
        view.allowsCameraControl = true
        render(in: view)
        context.coordinator.style = style.rawValue
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        if context.coordinator.style != style.rawValue {
            render(in: view)
            context.coordinator.style = style.rawValue
        }
    }

    final class Coordinator {
        var style = ""
    }

    private func render(in view: SCNView) {
        guard let scene = try? SCNScene(url: url, options: nil) else { return }

        if style == .manga {
            scene.rootNode.enumerateChildNodes { node, _ in
                guard let geometry = node.geometry else { return }
                for material in geometry.materials {
                    material.lightingModel = .lambert
                    material.roughness.contents = 1.0
                    material.metalness.contents = 0.0
                    material.shaderModifiers = [
                        .fragment: "#pragma body\n_output.color.rgb = floor(_output.color.rgb * 4.0 + 0.5) / 4.0;"
                    ]
                }
            }
            scene.background.contents = UIColor(red: 0.075, green: 0.065, blue: 0.10, alpha: 1)
        } else {
            scene.rootNode.enumerateChildNodes { node, _ in
                guard let geometry = node.geometry else { return }
                for material in geometry.materials {
                    material.lightingModel = .physicallyBased
                    material.roughness.contents = 0.72
                    material.metalness.contents = 0.02
                    material.shaderModifiers = nil
                }
            }
            scene.background.contents = UIColor(red: 0.045, green: 0.05, blue: 0.06, alpha: 1)
        }

        view.scene = scene
    }
}
