import Foundation
import SwiftUI
import Combine

final class Session: ObservableObject {
    @Published var currentUser: UserProfile? = nil
    @Published var role: UserRole? = nil

    // Posts created by providers describing services
    @Published var providerPosts: [ServicePost] = []
    // Requests created by receivers asking for services
    @Published var receiverRequests: [ServicePost] = []

    // Media items posted by providers
    @Published var mediaItems: [MediaItem] = []
    // Saved media for receivers
    @Published var savedMedia: [MediaItem] = []

    // Track services that a receiver has received (providers should mark completed)
    @Published var pastServicesReceived: [ServicePost] = []

    // Feedback
    @Published var pendingFeedbacks: [ServiceFeedback] = []
    @Published var providerFeedbacks: [ServiceFeedback] = []

    func addProviderPost(text: String, author: UserProfile) {
        let post = ServicePost(author: author, text: text, isProviderPost: true)
        providerPosts.insert(post, at: 0)
        //h
    }

    func addReceiverRequest(text: String, author: UserProfile) {
        let post = ServicePost(author: author, text: text, isProviderPost: false)
        receiverRequests.insert(post, at: 0)
    }

    // Accept the full UserProfile so we can set both authorID and authorName
    func addMediaItem(caption: String, author: UserProfile) {
        let item = MediaItem(authorID: author.id, authorName: "\(author.firstName) \(author.lastName)", caption: caption)
        mediaItems.insert(item, at: 0)
    }

    func saveMediaItem(_ item: MediaItem) {
        if !savedMedia.contains(item) { savedMedia.insert(item, at: 0) }
    }

    func markServiceReceived(_ post: ServicePost) {
        pastServicesReceived.insert(post, at: 0)
    }

    // Create pending feedback when a provider marks a receiver's request as completed.
    func createPendingFeedback(for post: ServicePost, provider: UserProfile) {
        // post.author is the receiver
        let fb = ServiceFeedback(providerID: provider.id, providerName: "\(provider.firstName) \(provider.lastName)", postID: post.id, postText: post.text, receiverID: post.author.id)
        pendingFeedbacks.insert(fb, at: 0)
    }

    // Submit feedback: move from pending to providerFeedbacks
    func submitFeedback(feedbackID: UUID, rating: Int, comment: String?) {
        guard let idx = pendingFeedbacks.firstIndex(where: { $0.id == feedbackID }) else { return }
        var fb = pendingFeedbacks.remove(at: idx)
        fb.rating = rating
        fb.comment = comment
        fb.date = Date()
        providerFeedbacks.insert(fb, at: 0)
    }

    // Helper: feedbacks for a provider
    func feedbacks(forProviderID id: UUID) -> [ServiceFeedback] {
        return providerFeedbacks.filter { $0.providerID == id }
    }

    // Helper: average rating for a provider
    func averageRating(forProviderID id: UUID) -> Double? {
        let f = feedbacks(forProviderID: id).compactMap { $0.rating }
        guard !f.isEmpty else { return nil }
        return Double(f.reduce(0, +)) / Double(f.count)
    }

    // Return pending feedback for a given receiver and post, if any
    func pendingFeedback(forReceiverID receiverID: UUID, postID: UUID) -> ServiceFeedback? {
        return pendingFeedbacks.first { $0.receiverID == receiverID && $0.postID == postID }
    }

    // Return whether feedback was already submitted for a receiver/post
    func hasSubmittedFeedback(forReceiverID receiverID: UUID, postID: UUID) -> Bool {
        return providerFeedbacks.contains { $0.receiverID == receiverID && $0.postID == postID }
    }
}

// Feedback model used when receiver rates a provider
struct ServiceFeedback: Identifiable, Codable, Hashable {
    let id: UUID
    let providerID: UUID
    var providerName: String
    let postID: UUID
    var postText: String
    let receiverID: UUID
    var rating: Int?
    var comment: String?
    var date: Date?

    init(id: UUID = UUID(), providerID: UUID, providerName: String = "", postID: UUID, postText: String = "", receiverID: UUID, rating: Int? = nil, comment: String? = nil, date: Date? = nil) {
        self.id = id
        self.providerID = providerID
        self.providerName = providerName
        self.postID = postID
        self.postText = postText
        self.receiverID = receiverID
        self.rating = rating
        self.comment = comment
        self.date = date
    }
}

// Provide an optional Session via EnvironmentValues so views can read it safely in previews
private struct OptionalSessionKey: EnvironmentKey {
    static let defaultValue: Session? = nil
}

extension EnvironmentValues {
    var session: Session? {
        get { self[OptionalSessionKey.self] }
        set { self[OptionalSessionKey.self] = newValue }
    }
}
