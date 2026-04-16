import SwiftUI

struct AuthChoiceView: View {
    @Environment(\.dismiss) private var dismiss
    var role: UserRole = .receiver
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Do you already have an account?")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                NavigationLink(destination: LoginView(role: role)) {
                    Text("Log in")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                }
                .background(Color.orange.opacity(0.85))
                .clipShape(Capsule())
                .padding(.horizontal, 40)

                NavigationLink(destination: SignupView(role: role)) {
                    Text("Create account")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                }
                .background(Color.orange.opacity(0.85))
                .clipShape(Capsule())
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        AuthChoiceView()
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
