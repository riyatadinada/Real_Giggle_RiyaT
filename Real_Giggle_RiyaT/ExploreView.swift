import SwiftUI

struct ServiceProfile: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let color: Color
    let size: CGSize
    let offset: CGSize
}

struct BubbleView: View {
    let profile: ServiceProfile

    var body: some View {
        ZStack {
            // cloud-like background using rounded rectangles and opacity
            RoundedRectangle(cornerRadius: 40)
                .fill(profile.color.opacity(0.25))
                .frame(width: profile.size.width, height: profile.size.height)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 2, y: 2)

            VStack(alignment: .center, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(profile.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 8)
        }
        .offset(profile.offset)
    }
}

struct ExploreView: View {
    // sample data laid out to look "scattered"
    private let profiles: [ServiceProfile] = [
        ServiceProfile(name: "Anya D", subtitle: "I am a good soccer player", color: .gray, size: CGSize(width: 160, height: 90), offset: CGSize(width: -110, height: -40)),
        ServiceProfile(name: "Sarnie S", subtitle: "I bake cakes", color: .teal, size: CGSize(width: 120, height: 70), offset: CGSize(width: 90, height: -120)),
        ServiceProfile(name: "Brook O", subtitle: "I run fast.", color: .gray, size: CGSize(width: 120, height: 70), offset: CGSize(width: 20, height: -40)),
        ServiceProfile(name: "Rubi O", subtitle: "I am so nice, and can be ur therapist", color: .teal, size: CGSize(width: 180, height: 100), offset: CGSize(width: -70, height: 20)),
        ServiceProfile(name: "Taryn J", subtitle: "I play golf.", color: .teal, size: CGSize(width: 110, height: 75), offset: CGSize(width: 80, height: 40)),
        ServiceProfile(name: "Riya T", subtitle: "I wash cars.", color: .teal, size: CGSize(width: 140, height: 90), offset: CGSize(width: -90, height: 120)),
        ServiceProfile(name: "Elise W", subtitle: "I am a good tutor", color: .gray, size: CGSize(width: 140, height: 90), offset: CGSize(width: 70, height: 140)),
        ServiceProfile(name: "Jessie E", subtitle: "I write essays", color: .gray, size: CGSize(width: 120, height: 70), offset: CGSize(width: -10, height: 220)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("EXPLORE")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
            .padding([.top, .horizontal])

            Divider()
                .padding(.horizontal)

            ZStack {
                Color.white

                ForEach(profiles) { profile in
                    BubbleView(profile: profile)
                }
            }
            .clipped()
            .padding(.horizontal)

            Spacer()

            // use reusable bottom toolbar for receiver role
            BottomToolbar(role: .receiver)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// small UIKit blur wrapper so bottom bar gets frosted look
//struct BlurView: UIViewRepresentable {
//    var style: UIBlurEffect.Style = .systemMaterial
//    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: style)) }
//    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
//}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
