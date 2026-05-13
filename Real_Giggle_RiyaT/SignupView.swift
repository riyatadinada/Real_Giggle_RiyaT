import SwiftUI

struct SignupView: View {
    var role: UserRole
    // allow pre-filling an email when navigating from LoginView
    init(initialEmail: String = "", role: UserRole = .receiver) {
        self.role = role
        _email = State(initialValue: initialEmail)
    }
    @Environment(\.session) private var sessionRef: Session?
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: Date = Date()
    @State private var selectedSchool: String = "Castilleja"
    @State private var selectedGrade: String = "9"
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var navigateToProfile: Bool = false
    @State private var profileToShow: UserProfile? = nil

    // alert state
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let schools = ["Castilleja"]
    private let grades = ["9", "10", "11", "12"]

    private var passwordsMatch: Bool {
        password == confirmPassword || confirmPassword.isEmpty
    }

    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty &&
        password == confirmPassword
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Create account")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Fill in your details to create an account")
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                    // First & Last name
                    HStack(spacing: 12) {
                        TextField("First name", text: $firstName)
                            .textContentType(.givenName)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

                        TextField("Last name", text: $lastName)
                            .textContentType(.familyName)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    }

                    // Birthday
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Birthday")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        DatePicker("", selection: $birthday, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    }

                    // School picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("School")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("School", selection: $selectedSchool) {
                            ForEach(schools, id: \.self) { school in
                                Text(school).tag(school)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    }

                    // Grade picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Grade")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Grade", selection: $selectedGrade) {
                            ForEach(grades, id: \.self) { g in
                                Text(g).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    }

                    // Email
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

                    // Password
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .textContentType(.newPassword)
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                        }

                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

                    // Confirm Password
                    HStack {
                        if showConfirmPassword {
                            TextField("Confirm password", text: $confirmPassword)
                                .textContentType(.newPassword)
                        } else {
                            SecureField("Confirm password", text: $confirmPassword)
                                .textContentType(.newPassword)
                        }

                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye" : "eye.slash")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

                    if !passwordsMatch {
                        Text("Passwords do not match")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }

                    Button(action: {
                        if isFormValid {
                            // check if email already registered
                            if sessionRef?.isEmailRegistered(email) == true {
                                alertMessage = "An account with this email already exists. Please log in or use a different email."
                                showAlert = true
                                return
                            }

                            // construct the profile to pass
                            let newProfile = UserProfile(firstName: firstName, lastName: lastName, birthday: birthday, school: selectedSchool, grade: selectedGrade, email: email)
                            profileToShow = newProfile
                            // set as current user in session
                            sessionRef?.currentUser = newProfile
                            sessionRef?.role = role
                            // register the email for persistence
                            sessionRef?.registerEmail(email)
                            // save credential securely in Keychain
                            sessionRef?.saveCredential(email: email, password: password)
                            // add to profiles list so the full profile is saved
                            sessionRef?.addProfile(newProfile)
                            navigateToProfile = true
                        }
                    }) {
                        Text("Create account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                    }
                    .background(isFormValid ? Color.orange : Color.orange.opacity(0.5))
                    .clipShape(Capsule())
                    .disabled(!isFormValid)
                    .padding(.top, 8)

                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        // present ProfileView when navigateToProfile is true
        .navigationDestination(isPresented: $navigateToProfile) {
            Group {
                if let p = profileToShow {
                    ProfileView(profile: p)
                } else {
                    EmptyView()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    NavigationStack {
        SignupView()
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
