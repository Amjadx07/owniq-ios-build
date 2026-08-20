import Foundation
import UIKit
import Vision
import CoreMedia

struct VisionGuess: Identifiable, Hashable {
    let id = UUID()
    let rawIdentifier: String
    let name: String
    let category: String
    let confidence: Double
}

enum PublicVisionEngine {
    static func analyze(image: UIImage) -> VisionGuess? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            return bestGuess(from: request.results)
        } catch {
            return nil
        }
    }

    static func analyze(sampleBuffer: CMSampleBuffer) -> VisionGuess? {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, options: [:])
        do {
            try handler.perform([request])
            return bestGuess(from: request.results)
        } catch {
            return nil
        }
    }

    private static func bestGuess(from observations: [VNClassificationObservation]?) -> VisionGuess? {
        guard let observation = observations?.first(where: { $0.confidence >= 0.18 }) else { return nil }
        let raw = observation.identifier
        let name = friendlyName(for: raw)
        return VisionGuess(
            rawIdentifier: raw,
            name: name,
            category: category(for: raw),
            confidence: Double(observation.confidence)
        )
    }

    static func dedupKey(for guess: VisionGuess) -> String {
        "\(guess.category.lowercased())|\(guess.name.lowercased())"
    }

    private static func normalized(_ raw: String) -> String {
        raw.lowercased().replacingOccurrences(of: "_", with: " ")
    }

    static func friendlyName(for raw: String) -> String {
        let value = normalized(raw)
        let mappings: [(String, String)] = [
            ("laptop", "Ordinateur portable"),
            ("notebook computer", "Ordinateur portable"),
            ("desktop computer", "Ordinateur"),
            ("computer keyboard", "Clavier"),
            ("keyboard", "Clavier"),
            ("computer mouse", "Souris"),
            ("cellular telephone", "Téléphone"),
            ("mobile phone", "Téléphone"),
            ("smartphone", "Téléphone"),
            ("television", "Télévision"),
            ("monitor", "Écran"),
            ("headphone", "Casque audio"),
            ("speaker", "Enceinte"),
            ("camera", "Appareil photo"),
            ("bottle", "Bouteille"),
            ("coffee mug", "Tasse"),
            ("cup", "Tasse"),
            ("plate", "Assiette"),
            ("fork", "Fourchette"),
            ("spoon", "Cuillère"),
            ("knife", "Couteau"),
            ("chair", "Chaise"),
            ("sofa", "Canapé"),
            ("couch", "Canapé"),
            ("table", "Table"),
            ("desk", "Bureau"),
            ("lamp", "Lampe"),
            ("book", "Livre"),
            ("backpack", "Sac à dos"),
            ("handbag", "Sac"),
            ("shoe", "Chaussure"),
            ("watch", "Montre"),
            ("bicycle", "Vélo"),
            ("ball", "Ballon"),
            ("toy", "Jouet")
        ]
        if let match = mappings.first(where: { value.contains($0.0) }) {
            return match.1
        }

        let first = raw.split(separator: ",").first.map(String.init) ?? raw
        let cleaned = first.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Objet à confirmer" : cleaned.capitalized
    }

    static func category(for raw: String) -> String {
        let value = normalized(raw)
        if containsAny(value, ["computer", "laptop", "keyboard", "mouse", "monitor", "printer"]) { return "Informatique" }
        if containsAny(value, ["phone", "telephone", "smartphone", "tablet"]) { return "Téléphonie" }
        if containsAny(value, ["game", "controller", "console", "joystick"]) { return "Jeux" }
        if containsAny(value, ["bottle", "cup", "mug", "plate", "fork", "spoon", "knife", "pan", "pot", "kettle"]) { return "Cuisine" }
        if containsAny(value, ["chair", "sofa", "couch", "table", "desk", "lamp", "cabinet", "furniture"]) { return "Maison" }
        if containsAny(value, ["shoe", "shirt", "jacket", "trouser", "dress", "clothing"]) { return "Mode" }
        if containsAny(value, ["watch", "handbag", "backpack", "wallet", "sunglass"]) { return "Accessoires" }
        if containsAny(value, ["book", "notebook", "magazine"]) { return "Livres" }
        if containsAny(value, ["ball", "bicycle", "racket", "sport"]) { return "Sport" }
        if containsAny(value, ["toy", "figurine", "card", "coin", "stamp"]) { return "Collection" }
        return "Autres"
    }

    private static func containsAny(_ value: String, _ terms: [String]) -> Bool {
        terms.contains(where: value.contains)
    }
}
