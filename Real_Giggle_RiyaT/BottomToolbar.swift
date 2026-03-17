import SwiftUI

enum ToolbarRole {
    case provider
    case receiver
    case both
}

struct BottomToolbar: View {
    let role: ToolbarRole

    var body: some View {
        HStack(spacing: 20) {
            NavigationLink(destination: PlaceholderView(title: "Profile")) {
                VStack { Image(systemName: "person.crop.circle"); Text("Profile").font(.caption) }
            }

            NavigationLink(destination: PlaceholderView(title: "Home")) {
                VStack { Image(systemName: "house"); Text("Home").font(.caption) }
            }

            NavigationLink(destination: PlaceholderView(title: "Messages")) {
                VStack { Image(systemName: "bubble.left.and.bubble.right"); Text("Messages").font(.caption) }
            }

            NavigationLink(destination: PlaceholderView(title: "Media")) {
                VStack { Image(systemName: "play.circle"); Text("Media").font(.caption) }
            }

            NavigationLink(destination: PlaceholderView(title: "Settings")) {
                VStack { Image(systemName: "gearshape"); Text("Settings").font(.caption) }
            }

            switch role {
            case .provider:
                NavigationLink(destination: PlaceholderView(title: "Ratings")) {
                    VStack { Image(systemName: "star"); Text("Ratings").font(.caption) }
                }
            case .receiver:
                NavigationLink(destination: PlaceholderView(title: "Search")) {
                    VStack { Image(systemName: "magnifyingglass"); Text("Search").font(.caption) }
                }
                NavigationLink(destination: PlaceholderView(title: "Explore")) {
                    VStack { Image(systemName: "safari"); Text("Explore").font(.caption) }
                }
            case .both:
                NavigationLink(destination: PlaceholderView(title: "Ratings")) {
                    VStack { Image(systemName: "star"); Text("Ratings").font(.caption) }
                }
                NavigationLink(destination: PlaceholderView(title: "Search")) {
                    VStack { Image(systemName: "magnifyingglass"); Text("Search").font(.caption) }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(BlurView(style: .systemThinMaterial))
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        Text("\(title) view coming soon")
            .font(.title2)
            .navigationTitle(title)
    }
}

// reuse small UIKit blur wrapper
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: style)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct BottomToolbar_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VStack { Spacer(); BottomToolbar(role: .receiver) }
        }
    }
}
