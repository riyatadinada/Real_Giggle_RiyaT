import SwiftUI

struct MessageView: View {
    var with: UserProfile
    @State private var newMessage: String = ""
    @State private var messages: [String] = ["Hi! Interested in your services."]

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages.indices, id: \.self) { i in
                        HStack {
                            if i % 2 == 0 { Spacer() }
                            Text(messages[i])
                                .padding(10)
                                .background(i % 2 == 0 ? Color(.systemGray5) : Color.blue.opacity(0.9))
                                .foregroundColor(i % 2 == 0 ? .primary : .white)
                                .cornerRadius(10)
                            if i % 2 != 0 { Spacer() }
                        }
                    }
                }
                .padding()
            }

            HStack {
                TextField("Message", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    let trimmed = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        messages.append(trimmed)
                        newMessage = ""
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle(with.firstName)
    }
}

#Preview {
    NavigationStack {
        MessageView(with: UserProfile(firstName: "Anya", lastName: "D", birthday: Date(), school: "Castilleja", grade: "11", email: "anya@example.com", bio: "", skills: [], image: nil))
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
