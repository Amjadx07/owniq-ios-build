import Foundation
import SwiftUI

struct VaultItem: Identifiable, Codable, Hashable {
    enum Source: String, Codable, CaseIterable {
        case photo = "Photo"
        case video = "Vidéo"
        case room3D = "Pièce 3D"
        case manual = "Manuel"
    }

    var id: UUID
    var name: String
    var category: String
    var confidence: Double?
    var needsConfirmation: Bool
    var createdAt: Date
    var lastSeenAt: Date
    var roomID: UUID?
    var photoData: Data?
    var source: Source

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        confidence: Double? = nil,
        needsConfirmation: Bool = true,
        createdAt: Date = Date(),
        lastSeenAt: Date = Date(),
        roomID: UUID? = nil,
        photoData: Data? = nil,
        source: Source
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.confidence = confidence
        self.needsConfirmation = needsConfirmation
        self.createdAt = createdAt
        self.lastSeenAt = lastSeenAt
        self.roomID = roomID
        self.photoData = photoData
        self.source = source
    }
}

struct RoomRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var usdzFilename: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, usdzFilename: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.usdzFilename = usdzFilename
        self.createdAt = createdAt
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var items: [VaultItem] = []
    @Published private(set) var rooms: [RoomRecord] = []

    static let defaultCategories = [
        "Informatique", "Téléphonie", "Jeux", "Maison", "Cuisine",
        "Mode", "Accessoires", "Livres", "Collection", "Sport", "Autres"
    ]

    private let itemsKey = "owniq.public.items.v2"
    private let roomsKey = "owniq.public.rooms.v2"

    init() {
        load()
    }

    var allCategories: [String] {
        let dynamic = Set(items.map(\.category).filter { !$0.isEmpty })
        return Array(Set(Self.defaultCategories).union(dynamic)).sorted()
    }

    func add(_ item: VaultItem) {
        items.insert(item, at: 0)
        saveItems()
    }

    func add(_ newItems: [VaultItem]) {
        guard !newItems.isEmpty else { return }
        items.insert(contentsOf: newItems, at: 0)
        saveItems()
    }

    func update(_ item: VaultItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        saveItems()
    }

    func delete(_ item: VaultItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    func addRoom(_ room: RoomRecord) {
        rooms.insert(room, at: 0)
        saveRooms()
    }

    func renameRoom(_ room: RoomRecord, to name: String) {
        guard let index = rooms.firstIndex(where: { $0.id == room.id }) else { return }
        rooms[index].name = name
        saveRooms()
    }

    func deleteRoom(_ room: RoomRecord) {
        let url = roomURL(for: room)
        try? FileManager.default.removeItem(at: url)
        rooms.removeAll { $0.id == room.id }
        saveRooms()
    }

    func roomURL(for room: RoomRecord) -> URL {
        roomsDirectory().appendingPathComponent(room.usdzFilename)
    }

    func newRoomURL(id: UUID) -> URL {
        roomsDirectory().appendingPathComponent("room_\(id.uuidString).usdz")
    }

    private func roomsDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("OWNIQRooms", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? decoder.decode([VaultItem].self, from: data) {
            items = decoded
        }
        if let data = UserDefaults.standard.data(forKey: roomsKey),
           let decoded = try? decoder.decode([RoomRecord].self, from: data) {
            rooms = decoded.filter { FileManager.default.fileExists(atPath: roomURL(for: $0).path) }
        }
    }

    private func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
    }

    private func saveRooms() {
        if let data = try? JSONEncoder().encode(rooms) {
            UserDefaults.standard.set(data, forKey: roomsKey)
        }
    }
}
