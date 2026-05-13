import XCTest
@testable import PersistenceLib

final class PersistenceTests: XCTestCase {
    override func setUpWithError() throws {
        try TestPersistence.removeTestFiles()
    }

    override func tearDownWithError() throws {
        try TestPersistence.removeTestFiles()
    }

    func testUserProfileSaveAndLoad() throws {
        let profile = TestUserProfile(firstName: "Test", lastName: "User", email: "test@example.com", bio: "Hello", skills: ["Tutoring","Dog walking"], credentials: ["CPR"], birthday: Date(timeIntervalSince1970: 0))
        try TestPersistence.saveUserProfile(profile)
        let loaded = try TestPersistence.loadUserProfile()
        XCTAssertEqual(loaded, profile)
    }

    func testRegisteredEmailsSaveAndLoad() throws {
        let emails = ["a@example.com", "b@example.com"]
        try TestPersistence.saveRegisteredEmails(emails)
        let loaded = try TestPersistence.loadRegisteredEmails()
        XCTAssertEqual(loaded, emails)
    }
}
