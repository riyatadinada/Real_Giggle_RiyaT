import SwiftUI

struct PerspectiveIndicator: View {
    @Environment(\.session) private var session: Session?

    var body: some View {
        Group {
            if let role = session?.role {
                HStack(spacing: 8) {
                    Image(systemName: role == .provider ? "wrench.fill" : "person.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Text(role == .provider ? "PROVIDER" : "RECEIVER")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(role == .provider ? Color.purple : Color.blue)
                .clipShape(Capsule())
                .padding([.top, .trailing], 12)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        VStack { Spacer(); Text("Demo") }
            .overlay(PerspectiveIndicator(), alignment: .topTrailing)
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
