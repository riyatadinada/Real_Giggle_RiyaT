import Foundation
import UIKit

// Central user profile model used across multiple views
struct UserProfile: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var firstName: String
    var lastName: String
    var birthday: Date
    var school: String
    var grade: String
    var email: String
    var bio: String?
    var skills: [String]
    var credentials: [String]

    // UIImage cannot be encoded directly; keep an in-memory image property
    var image: UIImage?

    init(id: UUID = UUID(), firstName: String, lastName: String, birthday: Date, school: String, grade: String, email: String, bio: String? = nil, skills: [String] = [], credentials: [String] = [], image: UIImage? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.birthday = birthday
        self.school = school
        self.grade = grade
        self.email = email
        self.bio = bio
        self.skills = skills
        self.credentials = credentials
        self.image = image
    }

    // Coding keys include all codable properties; image is encoded as Data under `imageData`
    private enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, birthday, school, grade, email, bio, skills, credentials, imageData
    }

    // Custom encode to transform UIImage -> Data
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(birthday, forKey: .birthday)
        try container.encode(school, forKey: .school)
        try container.encode(grade, forKey: .grade)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(skills, forKey: .skills)
        try container.encode(credentials, forKey: .credentials)

        if let img = image {
            // Use JPEG representation for smaller size; fallback to PNG if JPEG fails
            if let data = img.jpegData(compressionQuality: 0.8) ?? img.pngData() {
                try container.encode(data, forKey: .imageData)
            }
        }
    }

    // Custom decode to rebuild UIImage from Data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        birthday = try container.decode(Date.self, forKey: .birthday)
        school = try container.decode(String.self, forKey: .school)
        grade = try container.decode(String.self, forKey: .grade)
        email = try container.decode(String.self, forKey: .email)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        skills = try container.decode([String].self, forKey: .skills)
        credentials = try container.decodeIfPresent([String].self, forKey: .credentials) ?? []

        if let imageData = try container.decodeIfPresent(Data.self, forKey: .imageData) {
            image = UIImage(data: imageData)
        } else {
            image = nil
        }
    }
}
