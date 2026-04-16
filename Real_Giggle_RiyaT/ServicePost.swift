import Foundation

// Service posts used in Explore; isProviderPost distinguishes authorship type
struct ServicePost: Identifiable, Codable, Hashable {
    let id: UUID
    let author: UserProfile
    let text: String
    let date: Date
    let isProviderPost: Bool

    init(id: UUID = UUID(), author: UserProfile, text: String, date: Date = Date(), isProviderPost: Bool) {
        self.id = id
        self.author = author
        self.text = text
        self.date = date
        self.isProviderPost = isProviderPost
    }
}
