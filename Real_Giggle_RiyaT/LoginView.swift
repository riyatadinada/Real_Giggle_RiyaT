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
    @State private var navigateToSignup: Bool = false

    // alert
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

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
                    // Check email registration first
                    if sessionRef?.isEmailRegistered(email) != true {
                        // Not registered -> navigate to signup prefilled with email
                        navigateToSignup = true
                        return
                    }

                    // Verify password stored in Keychain
                    if sessionRef?.verifyCredential(email: email, password: password) != true {
                        alertMessage = "Incorrect password. If you forgot your password, please reset it or sign up again."
                        showAlert = true
                        return
                    }

                    // Attempt to load full profile by email
                    if let p = sessionRef?.profileForEmail(email) {
                        loggedProfile = p
                    } else {
                        // Fallback: create a minimal profile from the email
                        let namePart = email.split(separator: "@").first.map(String.init) ?? ""
                        let capitalized = namePart.split(separator: ".").first.map { $0.capitalized } ?? ""
                        loggedProfile.firstName = capitalized.isEmpty ? "User" : String(capitalized)
                        loggedProfile.lastName = ""
                        loggedProfile.email = email
                    }
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
        .navigationDestination(isPresented: $navigateToSignup) {
            SignupView(initialEmail: email, role: role)
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
    .environment(\.session, Session())
}
