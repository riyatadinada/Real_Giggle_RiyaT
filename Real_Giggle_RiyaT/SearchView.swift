import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    // Sample profiles (could be shared/fetched in a real app)
    private var sampleProfiles: [UserProfile] = [
        UserProfile(firstName: "Anya", lastName: "D", birthday: Date(), school: "Castilleja", grade: "11", email: "anya@example.com", bio: "I wash cars", skills: ["Car wash", "Detailing"], image: nil),
        UserProfile(firstName: "Sarnie", lastName: "S", birthday: Date(), school: "Castilleja", grade: "12", email: "sarnie@example.com", bio: "I bake cakes", skills: ["Baking"], image: nil),
        UserProfile(firstName: "Brook", lastName: "O", birthday: Date(), school: "Castilleja", grade: "10", email: "brook@example.com", bio: "I run fast", skills: ["Running"], image: nil),
        UserProfile(firstName: "Rubi", lastName: "O", birthday: Date(), school: "Castilleja", grade: "12", email: "rubi@example.com", bio: "I help with homework", skills: ["Tutoring"], image: nil),
        UserProfile(firstName: "Taryn", lastName: "J", birthday: Date(), school: "Castilleja", grade: "11", email: "taryn@example.com", bio: "I walk dogs", skills: ["Dog walking"], image: nil),
        UserProfile(firstName: "Riya", lastName: "T", birthday: Date(), school: "Castilleja", grade: "11", email: "riya@example.com", bio: "I tutor math", skills: ["Tutoring"], image: nil),
    ]

    private var filtered: [UserProfile] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return sampleProfiles
        }
        let lower = query.lowercased()
        return sampleProfiles.filter { p in
            p.firstName.lowercased().contains(lower) ||
            p.lastName.lowercased().contains(lower) ||
            p.email.lowercased().contains(lower) ||
            (p.bio ?? "").lowercased().contains(lower) ||
            p.skills.joined(separator: " ").lowercased().contains(lower)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SEARCH")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
            .padding([.top, .horizontal])

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search by name, skill, or service", text: $query)
                    .textInputAutocapitalization(.never)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            .padding(.horizontal)
            .padding(.top, 8)

            Divider().padding(.horizontal)

            // Results
            List {
                ForEach(filtered, id: \.id) { profile in
                    NavigationLink(destination: ProfileView(profile: profile, isEditable: false)) {
                        HStack(spacing: 12) {
                            if let img = profile.image {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle().fill(Color(.systemGray5)).frame(width: 56, height: 56)
                                    Text(initials(for: profile))
                                        .foregroundColor(.primary)
                                        .font(.headline)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(profile.firstName) \(profile.lastName)")
                                    .font(.headline)
                                Text(profile.skills.first ?? profile.bio ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.plain)

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
    }

    private func initials(for p: UserProfile) -> String {
        let first = p.firstName.first.map { String($0) } ?? ""
        let last = p.lastName.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
