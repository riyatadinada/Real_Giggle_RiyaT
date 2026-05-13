import SwiftUI

struct ExploreView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session: Session?

    @State private var showComposer = false
    @State private var pendingFeedbackToShow: ServiceFeedback? = nil
    @State private var showingPendingFeedback = false

    private var isProvider: Bool { session?.role == .provider }
    private var posts: [ServicePost] { isProvider ? (session?.receiverRequests ?? []) : (session?.providerPosts ?? []) }

    // For receivers, expose the current user's own requests (both pending and completed)
    private var myPendingRequests: [ServicePost] {
        guard let s = session, let me = s.currentUser else { return [] }
        return s.receiverRequests.filter { $0.author.id == me.id }
    }
    private var myCompletedRequests: [ServicePost] {
        guard let s = session, let me = s.currentUser else { return [] }
        return s.pastServicesReceived.filter { $0.author.id == me.id }
    }

    // For providers, expose the current user's own provided services
    private var myProvidedServices: [ServicePost] {
        guard let s = session, let me = s.currentUser else { return [] }
        return s.providerPosts.filter { $0.author.id == me.id }
    }

    // Heuristic: count receiver requests that might be interested in a provider post.
    // We do a simple keyword match: split provider post text into words (length >= 3)
    // and count receiver requests containing any of those words (case-insensitive).
    private func interestedRequestCount(for post: ServicePost) -> Int {
        guard let s = session else { return 0 }
        let words = Set(post.text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count >= 3 })
        guard !words.isEmpty else { return 0 }
        return s.receiverRequests.filter { req in
            let txt = req.text.lowercased()
            for w in words { if txt.contains(w) { return true } }
            return false
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("EXPLORE")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
            .padding([.top, .horizontal])

            Divider().padding(.horizontal)

            // For receivers show providerPosts as cloud at the top
            if !(session?.providerPosts.isEmpty ?? true) && !(isProvider) {
                BubbleCloud(posts: session?.providerPosts ?? [])
                    .padding(.horizontal)
            }

            // Show the current receiver's own requests at the very top so they can remember
            // what they asked for and see whether any have been completed/accepted.
            if !isProvider {
                if let s = session, s.currentUser != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your requests")
                            .font(.headline)
                            .padding(.horizontal)

                        // Pending requests (newest first)
                        if !myPendingRequests.isEmpty {
                            ForEach(myPendingRequests) { req in
                                PostCard(post: req, isProviderView: false, currentUser: s.currentUser)
                                    .padding(.horizontal)
                            }
                        }

                        // Completed requests (recent completions)
                        if !myCompletedRequests.isEmpty {
                            Text("Completed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            ForEach(myCompletedRequests) { req in
                                PostCard(post: req, isProviderView: false, currentUser: s.currentUser)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }

            // For providers, show their own services at the top so they can remember
            // what they offer and see if there are requests that seem to match / express interest.
            if isProvider {
                if let s = session, s.currentUser != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your services")
                            .font(.headline)
                            .padding(.horizontal)

                        if !myProvidedServices.isEmpty {
                            ForEach(myProvidedServices) { svc in
                                let count = interestedRequestCount(for: svc)
                                ZStack(alignment: .topTrailing) {
                                    PostCard(post: svc, isProviderView: false, currentUser: s.currentUser)
                                    if count > 0 {
                                        Text("\(count) interested")
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.12))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                            .padding(.trailing, 24)
                                            .padding(.top, 8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }

            ScrollView {
                LazyVStack(spacing: 12, pinnedViews: []) {
                    if posts.isEmpty {
                        ForEach(sampleFallback(), id: \.id) { post in
                            PostCard(post: post, isProviderView: isProvider, currentUser: session?.currentUser)
                                .padding(.horizontal)
                        }
                    } else {
                        ForEach(posts) { post in
                            PostCard(post: post, isProviderView: isProvider, currentUser: session?.currentUser)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }

            Spacer()
        }
        .navigationTitle("")
        .overlay(PerspectiveIndicator(), alignment: .topTrailing)
        .safeAreaInset(edge: .bottom) {
            BottomToolbar(role: isProvider ? .provider : .receiver)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showComposer = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showComposer) {
            ServicePostComposer(isProvider: isProvider) { text in
                guard let s = session, let user = s.currentUser else { return }
                if isProvider {
                    s.addProviderPost(text: text, author: user)
                } else {
                    s.addReceiverRequest(text: text, author: user)
                }
            }
        }
        .onAppear {
            // if current user is a receiver and has pending feedback, present it
            guard let s = session, let me = s.currentUser else { return }
            if s.role == .receiver {
                if let pending = s.pendingFeedbacks.first(where: { $0.receiverID == me.id }) {
                    pendingFeedbackToShow = pending
                    showingPendingFeedback = true
                }
            }
        }
        .sheet(isPresented: $showingPendingFeedback, onDismiss: { pendingFeedbackToShow = nil }) {
            if let fb = pendingFeedbackToShow {
                RatingSheet(feedback: fb, onSubmit: { stars, comment in
                    session?.submitFeedback(feedbackID: fb.id, rating: stars, comment: comment)
                }, onLater: {
                    // do nothing; user chose to rate later
                })
            } else {
                EmptyView()
            }
        }
    }

    // Card view for a post
    struct PostCard: View {
        let post: ServicePost
        let isProviderView: Bool // whether viewer is provider (so they see receiver requests)
        let currentUser: UserProfile?
        @Environment(\.session) private var session: Session?
        @State private var navigateToMessages = false

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 12) {
                    avatar

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center) {
                            Text("\(post.author.firstName) \(post.author.lastName)")
                                .font(.headline)

                            if post.author.id == currentUser?.id {
                                Text("• You")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // If this post belongs to the current user, show a small status for
                            // receiver requests only. Provider-authored provider posts will be
                            // handled in the provider "Your services" section (showing interested counts).
                            if post.author.id == currentUser?.id {
                                Spacer()
                                if !post.isProviderPost {
                                    // Determine status: pending if still in receiverRequests, completed if in pastServicesReceived
                                    if let sess = session {
                                        let completed = sess.pastServicesReceived.contains(where: { $0.id == post.id })
                                        Text(completed ? "Completed" : "Pending")
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(completed ? Color.green.opacity(0.15) : Color.yellow.opacity(0.12))
                                            .foregroundColor(completed ? .green : .orange)
                                            .clipShape(Capsule())
                                    }
                                }
                            } else {
                                Spacer()
                            }

                            Spacer()

                            Text(relativeTime(for: post.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(post.text)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        // show a few skill chips if available
                        if !post.author.skills.isEmpty {
                            FlowLayout(items: Array(post.author.skills.prefix(4)), id: \.self) { skill in
                                Text(skill)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    NavigationLink(destination: ProfileView(profile: post.author, isEditable: post.author.id == currentUser?.id)) {
                        Text("View profile")
                            .font(.subheadline)
                    }

                    Spacer()

                    Button(action: { navigateToMessages = true }) {
                        Label("Message", systemImage: "bubble.right")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)

                    // If provider viewing receiver requests, allow marking as completed
                    if isProviderView {
                        Button(action: {
                            if let sess = session {
                                if let prov = sess.currentUser {
                                    sess.createPendingFeedback(for: post, provider: prov)
                                    // record the service in receiver's history
                                    sess.markServiceReceived(post)
                                    // remove the request from the list
                                    if let idx = sess.receiverRequests.firstIndex(where: { $0.id == post.id }) {
                                        sess.receiverRequests.remove(at: idx)
                                    }
                                }
                            }
                        }) {
                            Text("Mark completed")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.04), radius: 4, x: 0, y: 2))
            .navigationDestination(isPresented: $navigateToMessages) {
                MessageView(with: post.author)
            }
        }

        private var avatar: some View {
            Group {
                if let img = post.author.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle().fill(Color(.systemGray5)).frame(width: 56, height: 56)
                        Text(initials(for: post.author))
                            .foregroundColor(.primary)
                            .font(.headline)
                    }
                }
            }
        }

        private func initials(for p: UserProfile) -> String {
            let first = p.firstName.first.map { String($0) } ?? ""
            let last = p.lastName.first.map { String($0) } ?? ""
            return (first + last).uppercased()
        }

        private func relativeTime(for date: Date) -> String {
            let fmt = RelativeDateTimeFormatter()
            fmt.unitsStyle = .short
            return fmt.localizedString(for: date, relativeTo: Date())
        }
    }

    // Composer used for both roles (text-only for now)
    struct ServicePostComposer: View {
        var isProvider: Bool
        var onPost: (String) -> Void
        @Environment(\.dismiss) private var dismiss
        @State private var text: String = ""
        @State private var location: String = ""

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading) {
                    Text(isProvider ? "Post a service you provide" : "Request a service you need")
                        .font(.headline)
                        .padding()

                    TextField(isProvider ? "E.g. I provide dog walking in Palo Alto" : "E.g. I need a tutor for biology", text: $text)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .padding(.horizontal)

                    TextField("Optional city / neighborhood", text: $location)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .padding(.horizontal)
                        .padding(.top, 4)

                    Spacer()

                    Button("Post") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        var finalText = trimmed
                        if !location.trimmingCharacters(in: .whitespaces).isEmpty {
                            finalText += " — \(location.trimmingCharacters(in: .whitespaces))"
                        }
                        onPost(finalText)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .navigationTitle(isProvider ? "New Service" : "New Request")
                .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
            }
        }
    }

    // Fallback sample posts to show until session has posts
    private func sampleFallback() -> [ServicePost] {
        let authors = [
            UserProfile(firstName: "Anya", lastName: "D", birthday: Date(), school: "Castilleja", grade: "11", email: "anya@example.com", bio: "Car washer", skills: ["Car wash"], credentials: [], image: nil),
            UserProfile(firstName: "Taryn", lastName: "J", birthday: Date(), school: "Castilleja", grade: "11", email: "taryn@example.com", bio: "Dog walker", skills: ["Dog walking"], credentials: [], image: nil),
            UserProfile(firstName: "Riya", lastName: "T", birthday: Date(), school: "Castilleja", grade: "11", email: "riya@example.com", bio: "Math tutor", skills: ["Tutoring"], credentials: [], image: nil)
        ]

        return authors.map { ServicePost(author: $0, text: $0.bio ?? "Service", isProviderPost: true) }
    }
}

#Preview {
    NavigationStack {
        ExploreView()
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}

