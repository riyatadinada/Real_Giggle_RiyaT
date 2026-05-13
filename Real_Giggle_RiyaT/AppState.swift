import Foundation

// Aggregate app-wide state to persist across launches
struct AppState: Codable {
    var providerPosts: [ServicePost]
    var receiverRequests: [ServicePost]
    var mediaItems: [MediaItem]
    var savedMedia: [MediaItem]
    var pastServicesReceived: [ServicePost]
    var pendingFeedbacks: [ServiceFeedback]
    var providerFeedbacks: [ServiceFeedback]
    var messagedUserIDs: [UUID]?

    init(providerPosts: [ServicePost] = [], receiverRequests: [ServicePost] = [], mediaItems: [MediaItem] = [], savedMedia: [MediaItem] = [], pastServicesReceived: [ServicePost] = [], pendingFeedbacks: [ServiceFeedback] = [], providerFeedbacks: [ServiceFeedback] = [], messagedUserIDs: [UUID] = []) {
        self.providerPosts = providerPosts
        self.receiverRequests = receiverRequests
        self.mediaItems = mediaItems
        self.savedMedia = savedMedia
        self.pastServicesReceived = pastServicesReceived
        self.pendingFeedbacks = pendingFeedbacks
        self.providerFeedbacks = providerFeedbacks
        self.messagedUserIDs = messagedUserIDs
    }
}
