import Foundation
import SwiftUI
import RoomPlan

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

    // Public-build metadata: useful to preserve the full UI contract without
    // pretending the private pricing/intelligence engine is embedded here.
    var estimatedLow: Double?
    var estimatedHigh: Double?
    var condition: String?
    var brand: String?
    var model: String?
    var notes: String?
    var keep: Bool?

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
        source: Source,
        estimatedLow: Double? = nil,
        estimatedHigh: Double? = nil,
        condition: String? = nil,
        brand: String? = nil,
        model: String? = nil,
        notes: String? = nil,
        keep: Bool? = nil
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
        self.estimatedLow = estimatedLow
        self.estimatedHigh = estimatedHigh
        self.condition = condition
        self.brand = brand
        self.model = model
        self.notes = notes
        self.keep = keep
    }

    var midpoint: Double? {
        guard let low = estimatedLow, let high = estimatedHigh else { return nil }
        return (low + high) / 2
    }
}

struct RoomRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var usdzFilename: String
    var createdAt: Date
    var jsonFilename: String?
    var wallCount: Int?
    var objectCount: Int?
    var doorCount: Int?
    var windowCount: Int?

    init(
        id: UUID = UUID(),
        name: String,
        usdzFilename: String,
        createdAt: Date = Date(),
        jsonFilename: String? = nil,
        wallCount: Int? = nil,
        objectCount: Int? = nil,
        doorCount: Int? = nil,
        windowCount: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.usdzFilename = usdzFilename
        self.createdAt = createdAt
        self.jsonFilename = jsonFilename
        self.wallCount = wallCount
        self.objectCount = objectCount
        self.doorCount = doorCount
        self.windowCount = windowCount
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var items: [VaultItem] = []
    @Published private(set) var rooms: [RoomRecord] = []
    @Published private(set) var customCategories: [String] = []

    static let defaultCategories = [
        "Informatique", "Téléphonie", "Jeux", "Maison", "Mobilier", "Cuisine",
        "Mode", "Accessoires", "Livres", "Collection", "Outils", "Sport",
        "Enfants & jouets", "Autres"
    ]

    private struct PersistedState: Codable {
        var items: [VaultItem]
        var rooms: [RoomRecord]
        var customCategories: [String]
    }

    private let itemsKey = "owniq.public.items.v2"
    private let roomsKey = "owniq.public.rooms.v2"
    private let stateFilename = "public-state.dat"

    init() {
        load()
    }

    var allCategories: [String] {
        let dynamic = Set(items.map(\.category).filter { !$0.isEmpty })
        return Array(Set(Self.defaultCategories + customCategories).union(dynamic)).sorted()
    }

    var totalKnownValue: Double {
        items.compactMap(\.midpoint).reduce(0, +)
    }

    func add(_ item: VaultItem) {
        items.insert(item, at: 0)
        save()
    }

    func add(_ newItems: [VaultItem]) {
        guard !newItems.isEmpty else { return }
        items.insert(contentsOf: newItems, at: 0)
        save()
    }

    func update(_ item: VaultItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
    }

    func delete(_ item: VaultItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func addCustomCategory(_ value: String) {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, !allCategories.contains(clean) else { return }
        customCategories.append(clean)
        customCategories.sort()
        save()
    }

    func addRoom(_ room: RoomRecord) {
        rooms.insert(room, at: 0)
        save()
    }

    func renameRoom(_ room: RoomRecord, to name: String) {
        guard let index = rooms.firstIndex(where: { $0.id == room.id }) else { return }
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        rooms[index].name = clean
        save()
    }

    func deleteRoom(_ room: RoomRecord) {
        try? FileManager.default.removeItem(at: roomURL(for: room))
        if let jsonFilename = room.jsonFilename {
            try? FileManager.default.removeItem(at: roomsDirectory().appendingPathComponent(jsonFilename))
        }
        for index in items.indices where items[index].roomID == room.id {
            items[index].roomID = nil
        }
        rooms.removeAll { $0.id == room.id }
        save()
    }

    func roomURL(for room: RoomRecord) -> URL {
        roomsDirectory().appendingPathComponent(room.usdzFilename)
    }

    func newRoomURL(id: UUID) -> URL {
        roomsDirectory().appendingPathComponent("room_\(id.uuidString.lowercased()).usdz")
    }

    func newRoomJSONURL(id: UUID) -> URL {
        roomsDirectory().appendingPathComponent("room_\(id.uuidString.lowercased()).json")
    }

    func capturedRoom(for room: RoomRecord) -> CapturedRoom? {
        guard let filename = room.jsonFilename else { return nil }
        let url = roomsDirectory().appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CapturedRoom.self, from: data)
    }

    func protectFile(_ url: URL) {
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }

    private func roomsDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("OWNIQRooms", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func stateURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("OWNIQPublic", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent(stateFilename)
    }

    private func load() {
        let decoder = JSONDecoder()

        if let raw = try? Data(contentsOf: stateURL()),
           let clear = try? PublicSecureStore.shared.open(raw),
           let state = try? decoder.decode(PersistedState.self, from: clear) {
            items = state.items
            rooms = state.rooms.filter { FileManager.default.fileExists(atPath: roomURL(for: $0).path) }
            customCategories = state.customCategories
            return
        }

        // One-time migration from the earlier public-shell UserDefaults storage.
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? decoder.decode([VaultItem].self, from: data) {
            items = decoded
        }
        if let data = UserDefaults.standard.data(forKey: roomsKey),
           let decoded = try? decoder.decode([RoomRecord].self, from: data) {
            rooms = decoded.filter { FileManager.default.fileExists(atPath: roomURL(for: $0).path) }
        }
        save()
    }

    private func save() {
        let state = PersistedState(items: items, rooms: rooms, customCategories: customCategories)
        guard let clear = try? JSONEncoder().encode(state),
              let sealed = try? PublicSecureStore.shared.seal(clear) else { return }
        do {
            try sealed.write(to: stateURL(), options: .atomic)
            protectFile(stateURL())
            UserDefaults.standard.removeObject(forKey: itemsKey)
            UserDefaults.standard.removeObject(forKey: roomsKey)
        } catch {
            // Keep the in-memory state usable even when persistence temporarily fails.
        }
    }
}
