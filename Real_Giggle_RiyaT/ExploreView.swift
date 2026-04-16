import SwiftUI

struct ExploreView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session: Session?

    @State private var showComposer = false
    @State private var pendingFeedbackToShow: ServiceFeedback? = nil
    @State private var showingPendingFeedback = false

    private var isProvider: Bool { (session?.role == .provider) ?? false }
    private var posts: [ServicePost] { isProvider ? (session?.receiverRequests ?? []) : (session?.providerPosts ?? []) }

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
            if ((s.role == .receiver) ?? false) {
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
                    .background(
                        NavigationLink(destination: MessageView(with: post.author), isActive: $navigateToMessages) { EmptyView() }
                            .hidden()
                    )

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
