import SwiftUI

struct MediaViewProvider: View {
    @Environment(\.session) private var session: Session?
    @State private var posts: [MediaPost] = []
    @State private var showComposer: Bool = false

    var body: some View {
        VStack {
            HStack {
                Text("MEDIA (Provider)")
                    .font(.largeTitle).bold()
                Spacer()
            }
            .padding()

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(posts) { p in
                        MediaCard(post: .constant(p), session: session, onComments: {})
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }

            Spacer()

            // toolbar moved to safeAreaInset
        }
        .overlay(PerspectiveIndicator(), alignment: .topTrailing)
        .safeAreaInset(edge: .bottom) {
            BottomToolbar(role: .provider)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showComposer = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showComposer) {
            ProviderMediaComposer { caption, image in
                let post = MediaPost(author: session?.currentUser ?? UserProfile(firstName: "You", lastName: "", birthday: Date(), school: "Castilleja", grade: "", email: "", bio: nil, skills: [], credentials: [], image: image), image: image, caption: caption)
                posts.insert(post, at: 0)
                showComposer = false
            }
        }
        .onAppear {
            if posts.isEmpty { loadSample() }
        }
    }

    private func loadSample() {
        posts = [
            MediaPost(author: UserProfile(firstName: "Anya", lastName: "D", birthday: Date(), school: "Castilleja", grade: "11", email: "anya@example.com", bio: "I wash cars", skills: ["Car wash"], credentials: ["CPR"], image: nil), image: nil, caption: "Offering weekend car washes!"),
        ]
    }
}

struct ProviderMediaComposer: View {
    @State private var caption: String = ""
    @State private var image: UIImage? = nil
    @Environment(\.dismiss) private var dismiss
    var onPost: (String, UIImage?) -> Void
    @State private var showImagePicker = false

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Write a caption...", text: $caption)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .padding()

                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .padding()
                }

                Button(action: { showImagePicker = true }) { Text("Add Photo") }
                    .padding()

                Spacer()
                Button("Post") {
                    onPost(caption, image)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $image)
            }
            .navigationTitle("New Media")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

#Preview {
    NavigationStack { MediaViewProvider() }
    .environmentObject(Session())
    .environment(\.session, Session())
}
