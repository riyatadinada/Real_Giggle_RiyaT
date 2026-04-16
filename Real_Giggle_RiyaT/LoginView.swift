import SwiftUI

struct LoginView: View {
    var role: UserRole = .receiver
    @Environment(\.session) private var sessionRef: Session?
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true

    // Navigation state to push to ProfileView after successful (mock) login
    @State private var navigateToProfile: Bool = false
    @State private var loggedProfile: UserProfile = UserProfile(firstName: "", lastName: "", birthday: Date(), school: "Castilleja", grade: "11", email: "", bio: nil, skills: [], image: nil)

    var isFormValid: Bool { !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty }

    var body: some View {
        VStack {
            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sign in to your account")
                    .foregroundColor(.secondary)
                    .font(.subheadline)

                // Email field
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.username)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

                // Password field with show/hide toggle
                HStack {
                    if isSecure {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                    } else {
                        TextField("Password", text: $password)
                            .textContentType(.password)
                    }

                    Button(action: { isSecure.toggle() }) {
                        Image(systemName: isSecure ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

                // Enter button
                Button(action: {
                    // Mock login success: build a basic UserProfile from the email and navigate
                    let namePart = email.split(separator: "@").first.map(String.init) ?? ""
                    let capitalized = namePart.split(separator: ".").first.map { $0.capitalized } ?? ""
                    loggedProfile.firstName = capitalized.isEmpty ? "User" : String(capitalized)
                    loggedProfile.lastName = ""
                    loggedProfile.email = email
                    // Set session
                    sessionRef?.currentUser = loggedProfile
                    sessionRef?.role = role
                    navigateToProfile = true
                }) {
                    Text("Enter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                }
                .background(isFormValid ? Color.orange : Color.orange.opacity(0.5))
                .clipShape(Capsule())
                .disabled(!isFormValid)
                .padding(.top, 8)

                // Forgot password small blue text
                Button(action: {
                    // TODO: show forgot password flow
                }) {
                    Text("Forgot password?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationTitle("")
        .navigationDestination(isPresented: $navigateToProfile) {
            ProfileView(profile: loggedProfile)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
            }
        }
        .padding(.top)
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environment(\.session, Session())
}
