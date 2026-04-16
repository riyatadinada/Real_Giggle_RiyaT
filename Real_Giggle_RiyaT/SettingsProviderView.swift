import SwiftUI

struct SettingsProviderView: View {
    @Environment(\.session) private var session: Session?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(header: Text("Account")) {
                HStack { Text("Name"); Spacer(); Text(session?.currentUser?.firstName ?? "-") }
                HStack { Text("Email"); Spacer(); Text(session?.currentUser?.email ?? "-") }
                if let user = session?.currentUser {
                    HStack { Text("Average rating"); Spacer(); Text(session?.averageRating(forProviderID: user.id).map { String(format: "%.1f", $0) } ?? "-") }
                    NavigationLink(destination: RatingView(provider: user)) { Text("View ratings & feedback") }
                }
                NavigationLink(destination: ProfileView(profile: session?.currentUser ?? UserProfile(firstName: "", lastName: "", birthday: Date(), school: "Castilleja", grade: "", email: ""))) {
                    Text("Edit account")
                }
            }

            Section(header: Text("Past Jobs")) {
                // Placeholder: In a real app this would be historical completed jobs
                if let posts = session?.providerPosts, !posts.isEmpty {
                    ForEach(posts) { p in
                        VStack(alignment: .leading) {
                            Text(p.text).font(.body)
                            Text("Posted on \(p.date, style: .date)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No past jobs found")
                }
            }

            Section(header: Text("Media Posts")) {
                if let media = session?.mediaItems, !media.isEmpty {
                    ForEach(media) { m in
                        VStack(alignment: .leading) {
                            Text(m.caption ?? "-").font(.body)
                            Text("\(m.date, style: .date)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No media posts")
                }
            }
        }
        .navigationTitle("Provider Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) { Image(systemName: "chevron.left") }
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsProviderView() }
    .environmentObject(Session())
    .environment(\.session, Session())
}
