import Foundation

struct TestPersistence {
    static func documentsDirectory() -> URL {
        FileManager.default.temporaryDirectory
    }

    static func saveUserProfile(_ profile: TestUserProfile) throws {
        let url = documentsDirectory().appendingPathComponent("test_current_user.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)
        try data.write(to: url, options: .atomic)
    }

    static func loadUserProfile() throws -> TestUserProfile {
        let url = documentsDirectory().appendingPathComponent("test_current_user.json")
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TestUserProfile.self, from: data)
    }

    static func saveRegisteredEmails(_ emails: [String]) throws {
        let url = documentsDirectory().appendingPathComponent("test_registered_emails.json")
        let data = try JSONEncoder().encode(emails)
        try data.write(to: url, options: .atomic)
    }

    static func loadRegisteredEmails() throws -> [String] {
        let url = documentsDirectory().appendingPathComponent("test_registered_emails.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String].self, from: data)
    }

    static func removeTestFiles() throws {
        let a = documentsDirectory().appendingPathComponent("test_current_user.json")
        if FileManager.default.fileExists(atPath: a.path) { try FileManager.default.removeItem(at: a) }
        let b = documentsDirectory().appendingPathComponent("test_registered_emails.json")
        if FileManager.default.fileExists(atPath: b.path) { try FileManager.default.removeItem(at: b) }
    }
}
