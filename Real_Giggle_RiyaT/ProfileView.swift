import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.session) private var session: Session?
    var profile: UserProfile
    var isEditable: Bool = true
    @State private var profileState: UserProfile
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage? = nil
    @State private var bioText: String = ""
    @State private var newSkill: String = ""
    @State private var showMessage = false

    init(profile: UserProfile, isEditable: Bool = true) {
        self.profile = profile
        self.isEditable = isEditable
        self._profileState = State(initialValue: profile)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Text("Profile")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
            .padding()

            // Profile image
            if isEditable {
                Button(action: { showingImagePicker = true }) {
                    avatarView
                }
                .padding(.top, 8)
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $inputImage)
                }
            } else {
                avatarView
                    .padding(.top, 8)
            }

            // Name, grade, school
            Text("\(profileState.firstName) \(profileState.lastName)")
                .font(.title2)
                .bold()

            Text("Grade \(profileState.grade) • \(profileState.school)")
                .foregroundColor(.secondary)

            // Edit button when editable; Message button when viewing others
            if isEditable {
                HStack(spacing: 12) {
                    Button("Save") {
                        commitChanges()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Done") {
                        commitChanges()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button(action: { showMessage = true }) {
                    Text("Message")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: 180)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }

            // Bio
            VStack(alignment: .leading) {
                Text("Bio")
                    .font(.headline)
                if isEditable {
                    TextEditor(text: $bioText)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4)))
                } else {
                    Text(bioText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                }
            }
            .padding(.horizontal)

            // Skills & Credentials: hidden for receivers
            if session?.role != .receiver {
                // Skills Editor or read-only chips
                VStack(alignment: .leading) {
                    Text("Skills")
                        .font(.headline)
                    // Only providers (or previews) can add skills when editable
                    if isEditable && ((session?.role == .provider) || session?.role == nil) {
                        HStack {
                            TextField("Add a skill", text: $newSkill)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                            Button("Add") {
                                let trimmed = newSkill.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty {
                                    profileState.skills.append(trimmed)
                                    newSkill = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    // Skills chips
                    FlowLayout(items: profileState.skills, id: \.self) { skill in
                        Text(skill)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)

                // Credentials section
                VStack(alignment: .leading) {
                    Text("Credentials")
                        .font(.headline)
                    if isEditable && ((session?.role == .provider) || session?.role == nil) {
                        HStack {
                            TextField("Add credential (e.g., CPR)", text: $newSkill)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                            Button("Add") {
                                let trimmed = newSkill.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty {
                                    profileState.credentials.append(trimmed)
                                    newSkill = ""
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    FlowLayout(items: profileState.credentials, id: \.self) { cred in
                        Text(cred)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // toolbar moved to safeAreaInset below
        }
        .onAppear {
            // initialize editable values
            bioText = profileState.bio ?? ""
            inputImage = profileState.image
        }
        .onDisappear {
            // save edited values back into profile model (if needed)
            profileState.bio = bioText
            if let img = inputImage { profileState.image = img }
            commitChanges()
        }
        .navigationTitle("")
        .navigationDestination(isPresented: $showMessage) {
            MessageView(with: profileState)
        }
        .overlay(PerspectiveIndicator(), alignment: .topTrailing)
        .safeAreaInset(edge: .bottom) {
            BottomToolbar(role: (session?.role == .provider) ? .provider : .receiver)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                }
            }
        }
    }

    private var avatarView: some View {
        Group {
            if let ui = inputImage ?? profileState.image {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 4)
            } else {
                ZStack {
                    Circle().fill(Color(.systemGray5)).frame(width: 120, height: 120)
                    Image(systemName: "person.fill").font(.title)
                }
            }
        }
    }

    private func commitChanges() {
        // push local edits into the global session.currentUser if it's the same user
        profileState.bio = bioText
        if let img = inputImage { profileState.image = img }
        if let s = session, s.currentUser?.id == profileState.id {
            s.currentUser = profileState
        }
    }
}

// Simple flow layout for displaying skills as chips
struct FlowLayout<Data: RandomAccessCollection, Content: View, ID: Hashable>: View where Data.Element: Hashable {
    var items: Data
    var id: KeyPath<Data.Element, ID>
    var content: (Data.Element) -> Content

    init(items: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.id = id
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            // compute wrapping rows using available width
            let maxWidth = geometry.size.width - 40
            var rows: [[Data.Element]] = [[]]
            var currentRowWidth: CGFloat = 0

            for item in items {
                let estimatedWidth = CGFloat(String(describing: item).count) * 8 + 40
                if currentRowWidth + estimatedWidth > maxWidth {
                    rows.append([item])
                    currentRowWidth = estimatedWidth
                } else {
                    rows[rows.count - 1].append(item)
                    currentRowWidth += estimatedWidth
                }
            }

            return VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<rows.count, id: \.self) { i in
                    HStack(spacing: 8) {
                        ForEach(rows[i], id: id) { item in
                            content(item)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
        .frame(minHeight: 0)
    }
}

#Preview {
    NavigationStack {
        ProfileView(profile: UserProfile(firstName: "Riya", lastName: "T", birthday: Date(), school: "Castilleja", grade: "11", email: "test@example.com", bio: "Hi!", skills: ["Tutoring", "Dog walking"], image: nil))
    }
    .environmentObject(Session())
    .environment(\.session, Session())
}
