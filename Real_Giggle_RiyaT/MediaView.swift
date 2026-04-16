import SwiftUI

struct MediaPost: Identifiable {
    let id = UUID()
    let author: UserProfile
    let image: UIImage?
    let caption: String
    var likes: Set<UUID> = [] // set of user ids who liked
    var favorites: Set<UUID> = []
    var comments: [Comment] = []
    let date: Date = Date()
}

struct Comment: Identifiable {
    let id = UUID()
    let authorName: String
    let text: String
    let date: Date
}

struct MediaView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session: Session?

    @State private var posts: [MediaPost] = []
    @State private var showCommentsFor: MediaPost? = nil
    @State private var newCommentText: String = ""

    init() {
        // default posts initialized in onAppear for previews to avoid heavy logic in init
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MEDIA")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
            .padding([.top, .horizontal])

            Divider().padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        MediaCard(post: binding(for: post), session: session) {
                            // show comments
                            showCommentsFor = post
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            Spacer()
            // toolbar moved to safeAreaInset
        }
        .navigationTitle("")
        .overlay(PerspectiveIndicator(), alignment: .topTrailing)
        .safeAreaInset(edge: .bottom) {
            BottomToolbar(role: .receiver)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
            }
        }
        .onAppear {
            if posts.isEmpty {
                loadSamplePosts()
            }
        }
        .sheet(item: $showCommentsFor) { post in
            CommentsSheet(post: post, onAddComment: { text in
                addComment(text: text, to: post)
            })
        }
    }

    private func binding(for post: MediaPost) -> Binding<MediaPost> {
        guard let idx = posts.firstIndex(where: { $0.id == post.id }) else {
            // Fallback: append and return binding to last
            posts.append(post)
            return $posts[posts.count-1]
        }
        return $posts[idx]
    }

    private func addComment(text: String, to post: MediaPost) {
        guard let idx = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let name = session?.currentUser?.firstName ?? "Anonymous"
        let comment = Comment(authorName: name, text: text, date: Date())
        posts[idx].comments.append(comment)
    }

    private func loadSamplePosts() {
        // use sample profiles from Explore/Search samples
        let sampleAuthors = [
            UserProfile(firstName: "Anya", lastName: "D", birthday: Date(), school: "Castilleja", grade: "11", email: "anya@example.com", bio: "I wash cars", skills: ["Car wash"], credentials: ["CPR"], image: nil),
            UserProfile(firstName: "Taryn", lastName: "J", birthday: Date(), school: "Castilleja", grade: "11", email: "taryn@example.com", bio: "I walk dogs", skills: ["Dog walking"], credentials: [], image: nil),
            UserProfile(firstName: "Riya", lastName: "T", birthday: Date(), school: "Castilleja", grade: "11", email: "riya@example.com", bio: "I tutor math", skills: ["Tutoring"], credentials: [], image: nil)
        ]

        posts = [
            MediaPost(author: sampleAuthors[0], image: nil, caption: "Fresh car wash special — only $20! PM to book." , likes: [], favorites: [], comments: [Comment(authorName: "Sarnie", text: "Looks great!", date: Date())]),
            MediaPost(author: sampleAuthors[1], image: nil, caption: "Dog walking this weekend — flexible schedule.", likes: [], favorites: [], comments: []),
            MediaPost(author: sampleAuthors[2], image: nil, caption: "Math tutoring: SAT prep and school support.", likes: [], favorites: [], comments: [Comment(authorName: "Parent", text: "Interested, send rates", date: Date().addingTimeInterval(-3600))])
        ]
    }
}

struct MediaCard: View {
    @Binding var post: MediaPost
    var session: Session?
    var onComments: () -> Void

    var isLiked: Bool {
        guard let uid = session?.currentUser?.id else { return false }
        return post.likes.contains(uid)
    }

    var isFavorited: Bool {
        guard let uid = session?.currentUser?.id else { return false }
        return post.favorites.contains(uid)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let img = post.author.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle().fill(Color(.systemGray5)).frame(width: 44, height: 44)
                        Text(initials(for: post.author))
                    }
                }

                VStack(alignment: .leading) {
                    Text("\(post.author.firstName) \(post.author.lastName)")
                        .font(.headline)
                    Text(post.caption)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(dateString(for: post.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // media image placeholder
            Rectangle()
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    Group {
                        if let _ = post.image {
                            // show post image
                            EmptyView()
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                        }
                    }
                )

            HStack(spacing: 20) {
                Button(action: { toggleLike() }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                    Text("\(post.likes.count)")
                }
                Button(action: { toggleFavorite() }) {
                    Image(systemName: isFavorited ? "bookmark.fill" : "bookmark")
                    Text("\(post.favorites.count)")
                }
                Button(action: { onComments() }) {
                    Image(systemName: "bubble.right")
                    Text("\(post.comments.count)")
                }
                Spacer()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.primary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(radius: 1))
    }

    private func toggleLike() {
        guard let uid = session?.currentUser?.id else { return }
        if post.likes.contains(uid) { post.likes.remove(uid) }
        else { post.likes.insert(uid) }
    }

    private func toggleFavorite() {
        guard let uid = session?.currentUser?.id else { return }
        if post.favorites.contains(uid) { post.favorites.remove(uid) }
        else { post.favorites.insert(uid) }
    }

    private func initials(for p: UserProfile) -> String {
        let f = p.firstName.first.map { String($0) } ?? ""
        let l = p.lastName.first.map { String($0) } ?? ""
        return (f + l).uppercased()
    }

    private func dateString(for date: Date) -> String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short
        return fmt.localizedString(for: date, relativeTo: Date())
    }
}

struct CommentsSheet: View {
    var post: MediaPost
    var onAddComment: (String) -> Void
    @State private var text: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(post.comments) { c in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(c.authorName).bold()
                                Spacer()
                                Text(timeString(from: c.date)).font(.caption).foregroundColor(.secondary)
                            }
                            Text(c.text)
                        }
                        .padding(.vertical, 6)
                    }
                }
                HStack {
                    TextField("Add a comment", text: $text)
                        .textFieldStyle(.roundedBorder)
                    Button("Send") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onAddComment(trimmed)
                            text = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short
        return fmt.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        MediaView()
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
