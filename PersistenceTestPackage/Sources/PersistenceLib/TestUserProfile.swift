import Foundation

struct TestUserProfile: Codable, Equatable {
    var firstName: String
    var lastName: String
    var email: String
    var bio: String?
    var skills: [String]
    var credentials: [String]
    var birthday: Date
}
