import Foundation
import CryptoKit
import Security
import LocalAuthentication
import SwiftUI

final class PublicSecureStore: @unchecked Sendable {
    static let shared = PublicSecureStore()

    private let magic = Data("OWNIQ-PUBLIC-AES1".utf8)
    private let service = "com.owniq.publicbuild.storage"
    private let account = "master-key"

    private init() {}

    func seal(_ data: Data) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: try key())
        guard let combined = sealed.combined else {
            throw NSError(domain: "OWNIQ.Security", code: 1)
        }
        return magic + combined
    }

    func open(_ data: Data) throws -> Data {
        guard data.starts(with: magic) else { return data }
        let box = try AES.GCM.SealedBox(combined: Data(data.dropFirst(magic.count)))
        return try AES.GCM.open(box, using: try key())
    }

    private func key() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return SymmetricKey(data: data)
        }
        guard status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }

        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
        }
        return SymmetricKey(data: data)
    }
}

@MainActor
final class PublicAppLock: ObservableObject {
    @Published var enabled: Bool {
        didSet {
            UserDefaults.standard.set(enabled, forKey: "owniq.public.lock")
            if !enabled { isUnlocked = true }
        }
    }
    @Published private(set) var isUnlocked = true
    @Published private(set) var errorMessage: String?

    init() {
        enabled = UserDefaults.standard.bool(forKey: "owniq.public.lock")
        isUnlocked = !enabled
    }

    func lock() {
        if enabled { isUnlocked = false }
    }

    func authenticate() async {
        guard enabled else { isUnlocked = true; return }
        let context = LAContext()
        context.localizedCancelTitle = "Annuler"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Authentification indisponible"
            return
        }
        let success = await withCheckedContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Déverrouiller OWNIQ"
            ) { ok, authError in
                Task { @MainActor in
                    self.errorMessage = authError?.localizedDescription
                    continuation.resume(returning: ok)
                }
            }
        }
        isUnlocked = success
    }
}

@MainActor
final class PublicPreferences: ObservableObject {
    enum Appearance: String, CaseIterable, Identifiable {
        case system = "Système"
        case dark = "Sombre"
        case light = "Clair"
        var id: String { rawValue }
    }

    @Published var appearance: Appearance { didSet { save() } }
    @Published var sounds = true { didSet { save() } }
    @Published var haptics = true { didSet { save() } }
    @Published var nightAssist = false { didSet { save() } }

    init() {
        let defaults = UserDefaults.standard
        appearance = Appearance(rawValue: defaults.string(forKey: "owniq.public.appearance") ?? "") ?? .dark
        sounds = defaults.object(forKey: "owniq.public.sounds") as? Bool ?? true
        haptics = defaults.object(forKey: "owniq.public.haptics") as? Bool ?? true
        nightAssist = defaults.object(forKey: "owniq.public.nightAssist") as? Bool ?? false
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: nil
        case .dark: .dark
        case .light: .light
        }
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(appearance.rawValue, forKey: "owniq.public.appearance")
        defaults.set(sounds, forKey: "owniq.public.sounds")
        defaults.set(haptics, forKey: "owniq.public.haptics")
        defaults.set(nightAssist, forKey: "owniq.public.nightAssist")
    }
}
