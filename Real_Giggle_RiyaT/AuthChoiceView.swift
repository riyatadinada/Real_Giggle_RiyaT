import SwiftUI

struct AuthChoiceView: View {
    @Environment(\.dismiss) private var dismiss
    var role: UserRole = .receiver
    @Environment(\.session) private var sessionRef: Session?
    // Navigation state
    @State private var navigateToProfile: Bool = false
    @State private var isSigningInWithICloud: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
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
                // iCloud sign-in button (preferred)
                Button(action: {
                    guard let sess = sessionRef else { return }
                    isSigningInWithICloud = true
                    sess.signInWithiCloud(role: role) { result in
                        DispatchQueue.main.async {
                            isSigningInWithICloud = false
                            switch result {
                            case .success(let profile):
                                // session will already have currentUser set in success path; navigate to profile
                                navigateToProfile = true
                                print("Signed in with iCloud: \(profile.email)")
                            case .failure(let err):
                                showError = true
                                errorMessage = err.localizedDescription
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "icloud.fill")
                        Text(isSigningInWithICloud ? "Signing in with iCloud..." : "Sign in with iCloud")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .clipShape(Capsule())
                    .padding(.horizontal, 40)
                }

                // iCloud-only flow: manual Login/Signup removed
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
        .navigationDestination(isPresented: $navigateToProfile) {
            // show profile for the signed-in user; they will add details manually
            if let user = sessionRef?.currentUser {
                ProfileView(profile: user)
            } else {
                Text("No profile available")
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Sign in failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
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
