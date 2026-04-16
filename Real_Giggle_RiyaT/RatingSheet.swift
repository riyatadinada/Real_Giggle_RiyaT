import SwiftUI

struct RatingSheet: View {
    let feedback: ServiceFeedback
    var onSubmit: (Int, String?) -> Void
    var onLater: () -> Void

    @State private var stars: Int = 5
    @State private var comment: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Rate \(feedback.providerName)")
                    .font(.headline)
                    .padding(.top)

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= stars ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .onTapGesture { stars = i }
                    }
                }
                .padding(.vertical)

                TextEditor(text: $comment)
                    .frame(height: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))

                Spacer()

                HStack {
                    Button("Later") {
                        onLater()
                        dismiss()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Submit") {
                        onSubmit(stars, comment.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Leave Feedback")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

#Preview {
    NavigationStack {
        RatingSheet(feedback: ServiceFeedback(providerID: UUID(), providerName: "Anya", postID: UUID(), postText: "Walk my dog", receiverID: UUID()), onSubmit: { _, _ in }, onLater: {})
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
