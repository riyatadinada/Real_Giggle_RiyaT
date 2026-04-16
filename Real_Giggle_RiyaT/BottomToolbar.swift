import SwiftUI

enum ToolbarRole {
    case provider
    case receiver
    case both
}

struct BottomToolbar: View {
    let role: ToolbarRole
    // accept a session optionally so previews or callers can pass it explicitly
    var session: Session?
    @Environment(\.session) private var envSession: Session?

    init(role: ToolbarRole, session: Session? = nil) {
        self.role = role
        self.session = session
    }

    var body: some View {
        HStack(spacing: 20) {
            // Profile - if user exists, push to their profile, otherwise show placeholder requesting login
            let currentUser = session?.currentUser ?? envSession?.currentUser

            if let user = currentUser {
                NavigationLink(destination: ProfileView(profile: user)) {
                    VStack { Image(systemName: "person.crop.circle"); Text("Profile").font(.caption) }
                }
            } else {
                NavigationLink(destination: PlaceholderView(title: "Profile")) {
                    VStack { Image(systemName: "person.crop.circle"); Text("Profile").font(.caption) }
                }
            }

            NavigationLink(destination: MessagesView()) {
                VStack { Image(systemName: "bubble.left.and.bubble.right"); Text("Messages").font(.caption) }
            }

            // Media: providers can post, receivers can browse
            if (session?.role ?? envSession?.role) == .provider {
                NavigationLink(destination: MediaViewProvider()) {
                    VStack { Image(systemName: "play.circle"); Text("Media").font(.caption) }
                }
            } else {
                NavigationLink(destination: MediaView()) {
                    VStack { Image(systemName: "play.circle"); Text("Media").font(.caption) }
                }
            }

            // Update Settings NavigationLink to route to role-appropriate settings view based on session role
            switch session?.role ?? envSession?.role {
            case .provider:
                NavigationLink(destination: SettingsProviderView()) {
                    VStack { Image(systemName: "gearshape"); Text("Settings").font(.caption) }
                }
            case .receiver:
                NavigationLink(destination: SettingsReceiverView()) {
                    VStack { Image(systemName: "gearshape"); Text("Settings").font(.caption) }
                }
            default:
                NavigationLink(destination: PlaceholderView(title: "Settings")) {
                    VStack { Image(systemName: "gearshape"); Text("Settings").font(.caption) }
                }
            }

            switch role {
            case .provider:
                NavigationLink(destination: ExploreView()) {
                    VStack { Image(systemName: "safari"); Text("Explore").font(.caption) }
                }
                if let user = currentUser {
                    NavigationLink(destination: RatingView(provider: user)) {
                        VStack { Image(systemName: "star"); Text("Ratings").font(.caption) }
                    }
                } else {
                    NavigationLink(destination: PlaceholderView(title: "Ratings")) {
                        VStack { Image(systemName: "star"); Text("Ratings").font(.caption) }
                    }
                }
            case .receiver:
                NavigationLink(destination: SearchView()) {
                    VStack { Image(systemName: "magnifyingglass"); Text("Search").font(.caption) }
                }
                NavigationLink(destination: ExploreView()) {
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
            VStack { Spacer(); BottomToolbar(role: .receiver, session: Session()) }
        }
    }
}
