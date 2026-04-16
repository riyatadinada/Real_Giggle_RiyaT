import SwiftUI

struct Conversation: Identifiable {
    let id = UUID()
    let other: UserProfile
    var lastMessage: String
    var time: Date
    var unread: Bool
}

struct MessagesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session: Session?

    // Sample conversations
    @State private var conversations: [Conversation] = [
        Conversation(other: UserProfile(firstName: "Shea", lastName: "W", birthday: Date(), school: "Castilleja", grade: "11", email: "shea@example.com", bio: "Baby sitter", skills: ["Babysitting"], credentials: ["CPR"], image: nil), lastMessage: "Kk ill watch", time: Date(), unread: true),
        Conversation(other: UserProfile(firstName: "Mom", lastName: "", birthday: Date(), school: "Castilleja", grade: "", email: "mom@example.com", bio: "", skills: [], credentials: [], image: nil), lastMessage: "Important to close the loop", time: Date().addingTimeInterval(-3600*24), unread: false),
        Conversation(other: UserProfile(firstName: "Brook", lastName: "O", birthday: Date(), school: "Castilleja", grade: "10", email: "brook@example.com", bio: "", skills: ["Tutoring"], credentials: [], image: nil), lastMessage: "List of courses for first and second semesters; English, at calc, stats, bio c...", time: Date().addingTimeInterval(-3600*48), unread: false),
    ]

    var body: some View {
        List {
            ForEach(conversations) { conv in
                NavigationLink(destination: MessageView(with: conv.other)) {
                    HStack(spacing: 12) {
                        if let img = conv.other.image {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle().fill(Color(.systemGray5)).frame(width: 56, height: 56)
                                Text(initials(for: conv.other))
                                    .foregroundColor(.primary)
                                    .font(.headline)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(conv.other.firstName) \(conv.other.lastName)")
                                    .font(.headline)
                                Spacer()
                                Text(timeString(from: conv.time))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text(conv.lastMessage)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Messages")
        .overlay(PerspectiveIndicator(), alignment: .topTrailing)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
            }
        }
    }

    private func initials(for p: UserProfile) -> String {
        let first = p.firstName.first.map { String($0) } ?? ""
        let last = p.lastName.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }

    private func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        MessagesView()
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
