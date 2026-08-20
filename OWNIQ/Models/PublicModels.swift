import SwiftUI
import UIKit

struct PublicItem: Identifiable, Equatable {
    let id: UUID
    var name: String
    var valueText: String
    var conditionText: String
    var imageData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        valueText: String,
        conditionText: String,
        imageData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.valueText = valueText
        self.conditionText = conditionText
        self.imageData = imageData
        self.createdAt = createdAt
    }
}

struct PublicRoom: Identifiable, Equatable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

final class PublicStore: ObservableObject {
    @Published var items: [PublicItem] = []
    @Published var rooms: [PublicRoom] = []

    func addCapturedObject(image: UIImage?) {
        let data = image?.jpegData(compressionQuality: 0.82)
        items.insert(
            PublicItem(
                name: "Objet à confirmer",
                valueText: "Estimation indisponible",
                conditionText: "État à vérifier",
                imageData: data
            ),
            at: 0
        )
    }

    func addRoom() {
        let index = rooms.count + 1
        rooms.append(PublicRoom(name: index == 1 ? "Ma première pièce" : "Pièce \(index)"))
    }
}
