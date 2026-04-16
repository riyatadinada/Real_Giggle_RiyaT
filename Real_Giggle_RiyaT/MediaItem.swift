import Foundation
import UIKit

/// Simple model for a media post/item in the feed.
/// Stored with optional image data and basic metadata.
public struct MediaItem: Identifiable, Codable, Hashable {
    public var id: UUID = UUID()
    public var authorID: UUID?
    public var authorName: String
    public var caption: String?
    public var imageData: Data?
    public var date: Date = Date()

    public var likes: [UUID] = []

    public init(id: UUID = UUID(), authorID: UUID? = nil, authorName: String, caption: String? = nil, imageData: Data? = nil, date: Date = Date(), likes: [UUID] = []) {
        self.id = id
        self.authorID = authorID
        self.authorName = authorName
        self.caption = caption
        self.imageData = imageData
        self.date = date
        self.likes = likes
    }

    // Convenience computed property to get UIImage when available
    public var image: UIImage? {
        guard let d = imageData else { return nil }
        return UIImage(data: d)
    }
}
