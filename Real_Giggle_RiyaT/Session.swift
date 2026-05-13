import Foundation
import SwiftUI
import Combine
import CloudKit

final class Session: ObservableObject {
    @Published var currentUser: UserProfile? = nil {
        didSet { persistCurrentUser() }
    }
    @Published var role: UserRole? = nil

    // Registered emails persisted across launches
    @Published var registeredEmails: [String] = [] {
        didSet { persistRegisteredEmails() }
    }

    // Posts created by providers describing services
    @Published var providerPosts: [ServicePost] = [] {
        didSet { persistAppState() }
    }
    // Requests created by receivers asking for services
    @Published var receiverRequests: [ServicePost] = [] {
        didSet { persistAppState() }
    }

    // Media items posted by providers
    @Published var mediaItems: [MediaItem] = [] {
        didSet { persistAppState() }
    }
    // Saved media for receivers
    @Published var savedMedia: [MediaItem] = [] {
        didSet { persistAppState() }
    }

    // Track services that a receiver has received (providers should mark completed)
    @Published var pastServicesReceived: [ServicePost] = [] {
        didSet { persistAppState() }
    }

    // Feedback
    @Published var pendingFeedbacks: [ServiceFeedback] = [] {
        didSet { persistAppState() }
    }
    @Published var providerFeedbacks: [ServiceFeedback] = [] {
        didSet { persistAppState() }
    }

    // Persisted profiles list
    @Published var profiles: [UserProfile] = [] {
        didSet { persistProfiles() }
    }

    // Track which users have been messaged (controls when names appear)
    @Published var messagedUserIDs: Set<UUID> = [] {
        didSet { persistAppState() }
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        // try to load persisted user
        do {
            let u = try Persistence.loadUserProfile()
            self.currentUser = u
            print("[Session] Loaded persisted user: \(u.email)")
            // infer role if you want; keep it nil for now
        } catch {
            // no persisted user - okay
            self.currentUser = nil
            print("[Session] No persisted user found")
        }

        // load registered emails
        do {
            self.registeredEmails = try Persistence.loadRegisteredEmails()
            print("[Session] Loaded registered emails count: \(self.registeredEmails.count)")
        } catch {
            self.registeredEmails = []
            print("[Session] No registered emails file")
        }

        // load profiles
        do {
            self.profiles = try Persistence.loadProfiles()
            print("[Session] Loaded profiles count: \(self.profiles.count)")
        } catch {
            self.profiles = []
            print("[Session] No profiles file")
        }

        // load app state
        do {
            let s = try Persistence.loadAppState()
            self.providerPosts = s.providerPosts
            self.receiverRequests = s.receiverRequests
            self.mediaItems = s.mediaItems
            self.savedMedia = s.savedMedia
            self.pastServicesReceived = s.pastServicesReceived
            self.pendingFeedbacks = s.pendingFeedbacks
            self.providerFeedbacks = s.providerFeedbacks
            self.messagedUserIDs = Set(s.messagedUserIDs ?? [])
            print("[Session] Loaded app state: providerPosts=\(providerPosts.count) receiverRequests=\(receiverRequests.count) mediaItems=\(mediaItems.count)")
        } catch {
            // start with empty state
            self.providerPosts = []
            self.receiverRequests = []
            self.mediaItems = []
            self.savedMedia = []
            self.pastServicesReceived = []
            self.pendingFeedbacks = []
            self.providerFeedbacks = []
            self.messagedUserIDs = []
            print("[Session] No app state file; starting fresh")
        }
    }

    private func persistCurrentUser() {
        DispatchQueue.global(qos: .background).async {
            guard let u = self.currentUser else {
                // if current user set to nil, remove persisted file
                try? Persistence.removeUserProfile()
                print("[Session] Removed persisted user")
                return
            }
            do {
                try Persistence.saveUserProfile(u)
                print("[Session] Saved current user: \(u.email)")
                // Also attempt to persist the profile to the user's private CloudKit database if we have a cloudRecordName
                if let recordName = u.cloudRecordName {
                    self.saveUserProfileToCloud(u) { result in
                        switch result {
                        case .success:
                            print("[Session] Saved user profile to CloudKit for record \(recordName)")
                        case .failure(let err):
                            print("[Session] CloudKit save failed: \(err)")
                        }
                    }
                }
            } catch {
                print("Failed to save user profile: \(error)")
            }
        }
    }

    // MARK: - CloudKit integration (private database)

    /// Sign in using the user's iCloud account. This fetches the user's iCloud recordName and then attempts
    /// to load an existing `UserProfile` record from the private database. If none exists, a minimal record is created.
    func signInWithiCloud(role: UserRole, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        // Safety guard: avoid invoking CloudKit APIs when the app/process is not configured
        // with iCloud/CloudKit entitlements. This prevents the EXC_BREAKPOINT crash that occurs
        // when CloudKit is called without the proper entitlements during development.
        // Toggle via Info.plist key `DisableCloudKitUsage` (Boolean). If the key is missing,
        // default to true (safe) to avoid unexpected crashes; set the key to `NO` when
        // you have enabled the iCloud capability in Xcode and updated provisioning.
        let disableCloudKit = Bundle.main.object(forInfoDictionaryKey: "DisableCloudKitUsage") as? Bool ?? true
        if disableCloudKit {
            DispatchQueue.main.async {
                let err = NSError(domain: "Session", code: -9999, userInfo: [NSLocalizedDescriptionKey: "CloudKit usage is disabled (DisableCloudKitUsage Info.plist key). Enable iCloud/CloudKit entitlements in the target settings to use CloudKit."])
                completion(.failure(err))
            }
            return
        }

        let container = CKContainer.default()
        container.fetchUserRecordID { recordID, error in
            if let err = error {
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            guard let rid = recordID else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Session", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain iCloud record ID"])) ) }
                return
            }

            let recordName = rid.recordName
            let privateDB = container.privateCloudDatabase
            let ckID = CKRecord.ID(recordName: recordName)
            privateDB.fetch(withRecordID: ckID) { record, fetchErr in
                if let record = record {
                    // map record to UserProfile
                    let profile = self.userProfile(from: record, cloudRecordName: recordName)
                    DispatchQueue.main.async {
                        self.currentUser = profile
                        self.role = role
                        completion(.success(profile))
                    }
                    return
                }

                // If fetch failed because record doesn't exist, create a new one
                let newRec = CKRecord(recordType: "UserProfile", recordID: ckID)
                newRec["firstName"] = "" as NSString
                newRec["lastName"] = "" as NSString
                newRec["email"] = "" as NSString
                newRec["school"] = "" as NSString
                newRec["grade"] = "" as NSString
                newRec["bio"] = "" as NSString
                newRec["birthday"] = Date() as NSDate

                privateDB.save(newRec) { saved, saveErr in
                    if let saveErr = saveErr {
                        DispatchQueue.main.async { completion(.failure(saveErr)) }
                        return
                    }
                    guard let saved = saved else {
                        DispatchQueue.main.async { completion(.failure(NSError(domain: "Session", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to save new CloudKit profile"])) ) }
                        return
                    }
                    let profile = self.userProfile(from: saved, cloudRecordName: recordName)
                    DispatchQueue.main.async {
                        self.currentUser = profile
                        self.role = role
                        completion(.success(profile))
                    }
                }
            }
        }
    }

    /// Save a UserProfile to the user's private CloudKit database. Uses `cloudRecordName` as the recordName.
    func saveUserProfileToCloud(_ profile: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let recordName = profile.cloudRecordName else {
            completion(.failure(NSError(domain: "Session", code: -3, userInfo: [NSLocalizedDescriptionKey: "Profile not associated with iCloud record"])))
            return
        }
        let container = CKContainer.default()
        let privateDB = container.privateCloudDatabase
        let ckID = CKRecord.ID(recordName: recordName)

        // Fetch existing record (if any) so we update rather than overwrite lost fields like assets
        privateDB.fetch(withRecordID: ckID) { existing, fetchErr in
            let rec = existing ?? CKRecord(recordType: "UserProfile", recordID: ckID)
            rec["firstName"] = profile.firstName as NSString
            rec["lastName"] = profile.lastName as NSString
            rec["email"] = profile.email as NSString
            rec["school"] = profile.school as NSString
            rec["grade"] = profile.grade as NSString
            rec["bio"] = profile.bio as NSString?
            rec["birthday"] = profile.birthday as NSDate
            rec["skills"] = profile.skills as [NSString]
            rec["credentials"] = profile.credentials as [NSString]

            // image -> CKAsset if available
            if let img = profile.image, let data = img.jpegData(compressionQuality: 0.8) {
                let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("profile_\(recordName).jpg")
                do {
                    try data.write(to: tmp)
                    let asset = CKAsset(fileURL: tmp)
                    rec["image"] = asset
                } catch {
                    print("[Session] Failed to write image temp file: \(error)")
                }
            }

            privateDB.save(rec) { saved, saveErr in
                if let saveErr = saveErr {
                    DispatchQueue.main.async { completion(.failure(saveErr)) }
                    return
                }
                DispatchQueue.main.async { completion(.success(())) }
            }
        }
    }

    // Helper to map CKRecord -> UserProfile
    private func userProfile(from record: CKRecord, cloudRecordName: String) -> UserProfile {
        let firstName = record["firstName"] as? String ?? ""
        let lastName = record["lastName"] as? String ?? ""
        let email = record["email"] as? String ?? ""
        let school = record["school"] as? String ?? "Castilleja"
        let grade = record["grade"] as? String ?? ""
        let bio = record["bio"] as? String
        let birthday = record["birthday"] as? Date ?? Date()
        let skills = (record["skills"] as? [String]) ?? []
        let credentials = (record["credentials"] as? [String]) ?? []

        var profile = UserProfile(firstName: firstName, lastName: lastName, birthday: birthday, school: school, grade: grade, email: email, bio: bio, skills: skills, credentials: credentials, image: nil, cloudRecordName: cloudRecordName)

        if let asset = record["image"] as? CKAsset, let url = asset.fileURL, let data = try? Data(contentsOf: url), let ui = UIImage(data: data) {
            profile.image = ui
        }

        return profile
    }

    private func persistProfiles() {
        DispatchQueue.global(qos: .background).async {
            do {
                try Persistence.saveProfiles(self.profiles)
                print("[Session] Persisted profiles count: \(self.profiles.count)")
            } catch {
                print("Failed to save profiles: \(error)")
            }
        }
    }

    private func persistRegisteredEmails() {
        DispatchQueue.global(qos: .background).async {
            do {
                try Persistence.saveRegisteredEmails(self.registeredEmails)
                print("[Session] Persisted registered emails count: \(self.registeredEmails.count)")
            } catch {
                print("Failed to save registered emails: \(error)")
            }
        }
    }

    private func persistAppState() {
        let state = AppState(providerPosts: providerPosts, receiverRequests: receiverRequests, mediaItems: mediaItems, savedMedia: savedMedia, pastServicesReceived: pastServicesReceived, pendingFeedbacks: pendingFeedbacks, providerFeedbacks: providerFeedbacks, messagedUserIDs: Array(messagedUserIDs))
        DispatchQueue.global(qos: .background).async {
            do {
                try Persistence.saveAppState(state)
                print("[Session] Persisted app state: providerPosts=\(state.providerPosts.count) receiverRequests=\(state.receiverRequests.count) mediaItems=\(state.mediaItems.count)")
            } catch {
                print("Failed to save app state: \(error)")
            }
        }
    }

    // register an email (lowercased) if not already present
    func registerEmail(_ email: String) {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !e.isEmpty else { return }
        if !registeredEmails.contains(e) {
            registeredEmails.insert(e, at: 0)
        }
    }

    func isEmailRegistered(_ email: String) -> Bool {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return registeredEmails.contains(e)
    }

    // Credential storage using Keychain
    private static let credentialService = "com.riyatad.RealGiggle.credentials"

    func saveCredential(email: String, password: String) {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !e.isEmpty else { return }
        guard let data = password.data(using: .utf8) else { return }
        do {
            try KeychainHelper.standard.save(data, service: Self.credentialService, account: e)
            print("[Session] Saved credential for \(e)")
        } catch {
            print("[Session] Failed to save credential: \(error)")
        }
    }

    func verifyCredential(email: String, password: String) -> Bool {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !e.isEmpty else { return false }
        do {
            let stored = try KeychainHelper.standard.read(service: Self.credentialService, account: e)
            if let s = String(data: stored, encoding: .utf8) {
                return s == password
            }
        } catch {
            print("[Session] verifyCredential read error: \(error)")
        }
        return false
    }

    func deleteCredential(email: String) {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !e.isEmpty else { return }
        do {
            try KeychainHelper.standard.delete(service: Self.credentialService, account: e)
            print("[Session] Deleted credential for \(e)")
        } catch {
            print("[Session] Failed to delete credential: \(error)")
        }
    }

    // Simple account representation (email + whether a credential exists in Keychain).
    // Passwords remain stored securely in Keychain; we don't expose them here.
    struct AccountInfo {
        let email: String
        var hasCredential: Bool {
            let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !e.isEmpty else { return false }
            do {
                _ = try KeychainHelper.standard.read(service: Session.credentialService, account: e)
                return true
            } catch {
                return false
            }
        }
    }

    // Return all known accounts (from registeredEmails). This provides a simple data
    // structure that maps usernames (emails) to whether a stored credential exists.
    func allAccounts() -> [AccountInfo] {
        return registeredEmails.map { AccountInfo(email: $0) }
    }

    func addProfile(_ profile: UserProfile) {
        // avoid duplicates by email
        if let idx = profiles.firstIndex(where: { $0.email.lowercased() == profile.email.lowercased() }) {
            profiles[idx] = profile
        } else {
            profiles.insert(profile, at: 0)
        }
        // Also register email list
        registerEmail(profile.email)
    }

    func profileForEmail(_ email: String) -> UserProfile? {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return profiles.first { $0.email.lowercased() == e }
    }

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
        persistAppState()
    }

    func saveMediaItem(_ item: MediaItem) {
        if !savedMedia.contains(item) { savedMedia.insert(item, at: 0); persistAppState() }
    }

    func markServiceReceived(_ post: ServicePost) {
        pastServicesReceived.insert(post, at: 0)
        persistAppState()
    }

    // Create pending feedback when a provider marks a receiver's request as completed.
    func createPendingFeedback(for post: ServicePost, provider: UserProfile) {
        // post.author is the receiver
        let fb = ServiceFeedback(providerID: provider.id, providerName: "\(provider.firstName) \(provider.lastName)", postID: post.id, postText: post.text, receiverID: post.author.id)
        pendingFeedbacks.insert(fb, at: 0)
        persistAppState()
    }

    // Submit feedback: move from pending to providerFeedbacks
    func submitFeedback(feedbackID: UUID, rating: Int, comment: String?) {
        guard let idx = pendingFeedbacks.firstIndex(where: { $0.id == feedbackID }) else { return }
        var fb = pendingFeedbacks.remove(at: idx)
        fb.rating = rating
        fb.comment = comment
        fb.date = Date()
        providerFeedbacks.insert(fb, at: 0)
        persistAppState()
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

    // Mark a userID as having been messaged
    func markMessaged(with userID: UUID) {
        messagedUserIDs.insert(userID)
        persistAppState()
    }

    // Sign out and remove persisted user
    func signOut() {
        currentUser = nil
        role = nil
        // persisted file removed via didSet logic
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
