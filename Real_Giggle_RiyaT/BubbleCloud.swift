import SwiftUI

struct BubbleCloud: View {
    var posts: [ServicePost]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let subset = Array(posts.prefix(8))
                ForEach(subset.indices, id: \.self) { idx in
                    let post = subset[idx]
                    let size: CGFloat = 72 - CGFloat(idx * 4)
                    // place in a circle-like spread
                    let angle = Double(idx) / Double(max(1, min(subset.count, 8))) * .pi * 2
                    let radius = min(geo.size.width, geo.size.height) / 3
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius

                    Button(action: {
                        // placeholder action
                        print("Bubble tapped: \(post.id)")
                    }) {
                        Text(shortText(for: post))
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: size, height: size)
                            .background(Circle().fill(Color.blue))
                    }
                    .position(x: geo.size.width/2 + CGFloat(x), y: geo.size.height/2 + CGFloat(y))
                }
            }
        }
        .frame(height: 120)
    }

    private func shortText(for post: ServicePost) -> String {
        // use first 2-3 words or the author's service-like bio
        let words = post.text.split(separator: " ")
        if words.count <= 3 { return String(post.text) }
        return words.prefix(3).joined(separator: " ")
    }
}

#Preview {
    BubbleCloud(posts: [ServicePost(author: UserProfile(firstName: "Anya", lastName: "D", birthday: Date(), school: "Castilleja", grade: "11", email: "anya@example.com"), text: "I wash cars", isProviderPost: true), ServicePost(author: UserProfile(firstName: "Taryn", lastName: "J", birthday: Date(), school: "Castilleja", grade: "11", email: "taryn@example.com"), text: "I walk dogs around Palo Alto", isProviderPost: true)])
}
