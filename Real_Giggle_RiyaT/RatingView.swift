import SwiftUI

struct RatingView: View {
    @Environment(\.session) private var session: Session?
    var provider: UserProfile

    private var feedbacks: [ServiceFeedback] {
        session?.feedbacks(forProviderID: provider.id) ?? []
    }

    private var average: Double? {
        session?.averageRating(forProviderID: provider.id)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("RATINGS")
                    .font(.largeTitle).bold()
                Spacer()
            }
            .padding()

            HStack(alignment: .center, spacing: 16) {
                if let avg = average {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: "%.1f", avg))
                            .font(.system(size: 48, weight: .bold))
                        StarsBigView(rating: avg)
                    }
                    .padding(.leading)
                } else {
                    Text("No ratings yet")
                        .foregroundColor(.secondary)
                        .padding(.leading)
                }

                Spacer()
            }
            .padding(.horizontal)

            Text("REVIEWS")
                .font(.title2)
                .bold()
                .padding(.horizontal)
                .padding(.top, 6)

            if feedbacks.isEmpty {
                Text("No feedback yet")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(feedbacks) { fb in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top) {
                                    Text(fb.providerName)
                                        .font(.headline)
                                    Spacer()
                                    Text(String(format: "%.1f", Double(fb.rating ?? 0)))
                                        .font(.subheadline).bold()
                                }

                                Text(fb.comment ?? "No comment")
                                    .font(.body)

                                if !fb.postText.isEmpty {
                                    Text(fb.postText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }

            Spacer()
        }
        .navigationTitle("Ratings")
    }
}

// Larger stars view for the header
struct StarsBigView: View {
    var rating: Double // 0-5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { i in
                let threshold = Double(i) + 1
                Image(systemName: rating >= threshold ? "star.fill" : (rating > Double(i) ? "star.leadinghalf.filled" : "star"))
                    .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.yellow)
            }
        }
    }
}

#Preview {
    NavigationStack {
        RatingView(provider: UserProfile(firstName: "Anya", lastName: "D", birthday: Date(), school: "Castilleja", grade: "11", email: "anya@example.com"))
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
