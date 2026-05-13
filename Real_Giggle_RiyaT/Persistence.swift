import Foundation

/// Tiny file-backed persistence helpers (JSON encode/decode) for simple models.
/// This follows the minimal approach from the linked article: quick, easy, and read/write to Documents.
struct Persistence {
    private static let userFile = "current_user.json"
    private static let emailsFile = "registered_emails.json"
    private static let appStateFile = "app_state.json"

    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    static func userFileURL() -> URL {
        documentsDirectory().appendingPathComponent(userFile)
    }

    static func emailsFileURL() -> URL {
        documentsDirectory().appendingPathComponent(emailsFile)
    }

    static func appStateFileURL() -> URL {
        documentsDirectory().appendingPathComponent(appStateFile)
    }

    static func saveUserProfile(_ profile: UserProfile) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)
        try data.write(to: userFileURL(), options: .atomic)
    }

    static func loadUserProfile() throws -> UserProfile {
        let data = try Data(contentsOf: userFileURL())
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserProfile.self, from: data)
    }

    static func removeUserProfile() throws {
        let url = userFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Registered Emails

    static func saveRegisteredEmails(_ emails: [String]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(emails)
        try data.write(to: emailsFileURL(), options: .atomic)
    }

    static func loadRegisteredEmails() throws -> [String] {
        let url = emailsFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([String].self, from: data)
    }

    static func removeRegisteredEmails() throws {
        let url = emailsFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Profiles (full user profiles list)

    static func profilesFileURL() -> URL {
        documentsDirectory().appendingPathComponent("profiles.json")
    }

    static func saveProfiles(_ profiles: [UserProfile]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profiles)
        try data.write(to: profilesFileURL(), options: .atomic)
    }

    static func loadProfiles() throws -> [UserProfile] {
        let url = profilesFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([UserProfile].self, from: data)
    }

    static func removeProfiles() throws {
        let url = profilesFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - App State

    static func saveAppState(_ state: AppState) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        try data.write(to: appStateFileURL(), options: .atomic)
    }

    static func loadAppState() throws -> AppState {
        let url = appStateFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return AppState() }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AppState.self, from: data)
    }

    static func removeAppState() throws {
        let url = appStateFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
