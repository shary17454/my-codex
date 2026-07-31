import AuthenticationServices
import Combine
import CryptoKit
import Foundation
import Security

@MainActor
final class UserSession: ObservableObject {
    @Published private(set) var isSignedIn: Bool
    @Published private(set) var displayName: String
    @Published private(set) var email: String
    @Published private(set) var userIdentifier: String

    private let defaults: UserDefaults
    private let secureStore: UserSessionSecureStore
    nonisolated private static let ownerEmailDigest = "036a6f30eceeeeac0d800e80c2e824b3686decfe06d353a246ba282ce39cb36e"

    init(
        defaults: UserDefaults = .standard,
        secureStore: UserSessionSecureStore = .shared
    ) {
        self.defaults = defaults
        self.secureStore = secureStore
        self.isSignedIn = defaults.bool(forKey: "user.isSignedIn")
        self.displayName = defaults.string(forKey: "user.displayName") ?? "ضيف"
        self.email = secureStore.load(.email) ?? defaults.string(forKey: "user.email") ?? ""
        self.userIdentifier = secureStore.load(.identifier) ?? defaults.string(forKey: "user.identifier") ?? ""
        migrateLegacyCredentialsIfNeeded()
    }

    var publicName: String {
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanName.isEmpty ? "ضيف" : cleanName
    }

    var hasOwnerAccess: Bool {
        Self.isOwnerEmail(email)
    }

    var hasFullFeatureAccess: Bool {
        hasOwnerAccess
    }

    nonisolated static func isOwnerEmail(_ email: String) -> Bool {
        sha256Digest(for: normalizedEmail(email)) == ownerEmailDigest
    }

    func completeSignIn(with credential: ASAuthorizationAppleIDCredential) {
        userIdentifier = credential.user
        if let email = credential.email, !email.isEmpty {
            self.email = email
        }
        if let name = credential.fullName {
            let formatted = PersonNameComponentsFormatter()
                .string(from: name)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !formatted.isEmpty {
                displayName = formatted
            }
        }
        isSignedIn = true
        persist()
    }

    func updateAlias(_ alias: String) {
        displayName = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
    }

    func signOut() {
        isSignedIn = false
        displayName = "ضيف"
        email = ""
        userIdentifier = ""
        secureStore.deleteAll()
        persistPublicState()
    }

    private func migrateLegacyCredentialsIfNeeded() {
        if secureStore.load(.email) == nil, !email.isEmpty {
            secureStore.save(email, for: .email)
        }
        if secureStore.load(.identifier) == nil, !userIdentifier.isEmpty {
            secureStore.save(userIdentifier, for: .identifier)
        }
        defaults.removeObject(forKey: "user.email")
        defaults.removeObject(forKey: "user.identifier")
    }

    private func persist() {
        persistPublicState()
        secureStore.save(email, for: .email)
        secureStore.save(userIdentifier, for: .identifier)
    }

    private func persistPublicState() {
        defaults.set(isSignedIn, forKey: "user.isSignedIn")
        defaults.set(displayName, forKey: "user.displayName")
    }

    nonisolated private static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    nonisolated private static func sha256Digest(for value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

struct UserSessionSecureStore: Sendable {
    enum Key: String, Sendable {
        case email
        case identifier
    }

    static let shared = UserSessionSecureStore()
    private let service = "com.shary17454.esal.user-session"

    func load(_ key: Key) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func save(_ value: String, for key: Key) {
        delete(key)
        guard !value.isEmpty, let data = value.data(using: .utf8) else { return }

        var attributes = baseQuery(for: key)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func deleteAll() {
        Key.allCases.forEach(delete)
    }

    private func delete(_ key: Key) {
        SecItemDelete(baseQuery(for: key) as CFDictionary)
    }

    private func baseQuery(for key: Key) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
    }
}

extension UserSessionSecureStore.Key: CaseIterable {}
