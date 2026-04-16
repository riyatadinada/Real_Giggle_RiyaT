import SwiftUI

struct SettingsReceiverView: View {
    @Environment(\.session) private var session: Session?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeedback: ServiceFeedback? = nil
    @State private var showingRating = false

    var body: some View {
        List {
            Section(header: Text("Pending Ratings")) {
                if let pending = session?.pendingFeedbacks, !pending.isEmpty {
                    ForEach(pending) { fb in
                        Button(action: { selectedFeedback = fb; showingRating = true }) {
                            HStack { Text("Rate \(fb.providerName)"); Spacer(); Text("Later") }
                        }
                    }
                } else {
                    Text("No pending ratings")
                }
            }

            Section(header: Text("Account")) {
                HStack { Text("Name"); Spacer(); Text(session?.currentUser?.firstName ?? "-") }
                HStack { Text("Email"); Spacer(); Text(session?.currentUser?.email ?? "-") }
                NavigationLink(destination: ProfileView(profile: session?.currentUser ?? UserProfile(firstName: "", lastName: "", birthday: Date(), school: "Castilleja", grade: "", email: ""))) {
                    Text("Edit account")
                }
            }

            Section(header: Text("Saved Media")) {
                if let saved = session?.savedMedia, !saved.isEmpty {
                    ForEach(saved) { m in
                        VStack(alignment: .leading) {
                            Text(m.caption ?? "-").font(.body)
                            Text("\(m.date, style: .date)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No saved media")
                }
            }

            Section(header: Text("Explore History")) {
                if let posts = session?.providerPosts, !posts.isEmpty {
                    ForEach(posts) { p in
                        VStack(alignment: .leading) {
                            Text(p.text).font(.body)
                            Text("\(p.date, style: .date)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No explore history")
                }
            }

            Section(header: Text("Past Services Received")) {
                if let history = session?.pastServicesReceived, !history.isEmpty {
                    ForEach(history) { p in
                        VStack(alignment: .leading) {
                            Text(p.text).font(.body)
                            Text("\(p.date, style: .date)").font(.caption).foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("No past services recorded")
                }
            }
        }
        .navigationTitle("Receiver Settings")
        .sheet(isPresented: $showingRating, onDismiss: { selectedFeedback = nil }) {
            if let fb = selectedFeedback {
                RatingSheet(feedback: fb, onSubmit: { stars, comment in
                    session?.submitFeedback(feedbackID: fb.id, rating: stars, comment: comment)
                }, onLater: {
                    // do nothing; it remains pending
                })
            } else {
                EmptyView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) { Image(systemName: "chevron.left") }
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsReceiverView() }
    .environmentObject(Session())
    .environment(\.session, Session())
}
