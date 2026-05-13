import SwiftUI

struct ProviderExploreView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session: Session?
    @State private var showComposer = false

    var body: some View {
        VStack {
            HStack {
                Text("EXPLORE (Providers)")
                    .font(.largeTitle).bold()
                Spacer()
            }
            .padding()

            // Providers should see receiver requests; show them from session
            if let reqs = session?.receiverRequests, !reqs.isEmpty {
                List {
                    ForEach(reqs) { r in
                        HStack {
                            Image(systemName: "megaphone.fill").foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("\(r.author.firstName) \(r.author.lastName)")
                                    .font(.headline)
                                Text(r.text).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            } else {
                List {
                    Text("No requests yet")
                }
            }

            Spacer()
            // toolbar moved to safeAreaInset
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showComposer = true }) {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            ProviderPostComposer { text in
                showComposer = false
                guard let s = session, let user = s.currentUser, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                s.addProviderPost(text: text, author: user)
            }
        }
        .safeAreaInset(edge: .bottom) {
            BottomToolbar(role: .provider)
        }
    }
}

struct ProviderPostComposer: View {
    @State private var text: String = ""
    var onPost: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TextField("I provide... (service and city)", text: $text)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .padding()
                Spacer()
                Button("Post") {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { onPost(trimmed) }
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("New Post")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { onPost("") } } }
        }
    }
}

#Preview {
    NavigationStack {
        ProviderExploreView()
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
