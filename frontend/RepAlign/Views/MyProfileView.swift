import SwiftUI
import SwiftData

struct MyProfileView: View {
    @Binding var selectedTab: Int
    @Query private var users: [User]
    @Query private var citizenProfiles: [CitizenProfile]
    @Query private var legislatorProfiles: [LegislatorProfile]

    @State private var currentUserManager = CurrentUserManager.shared
    var body: some View {
        NavigationView {
            Group {
                if let currentUser = getCurrentUser() {
                    ProfileView(
                        user: currentUser,
                        citizenProfile: getCurrentCitizenProfile(),
                        legislatorProfile: getCurrentLegislatorProfile(),
                        selectedTab: $selectedTab
                    )
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)

                        Text("Profile Not Found")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Unable to load your profile. Please try again.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                }
            }
            .navigationTitle("My Profile")
        }
    }

    private func getCurrentUser() -> User? {
        return currentUserManager.getCurrentUser(from: users)
    }

    private func getCurrentCitizenProfile() -> CitizenProfile? {
        return currentUserManager.getCurrentCitizenProfile(from: citizenProfiles)
    }

    private func getCurrentLegislatorProfile() -> LegislatorProfile? {
        return currentUserManager.getCurrentLegislatorProfile(from: legislatorProfiles)
    }
}

#Preview {
    @Previewable @State var selectedTab = 1
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: User.self, CitizenProfile.self, LegislatorProfile.self,
        configurations: config
    )

    let users = MockDataProvider.createMockUsers()
    let citizenProfiles = MockDataProvider.createMockCitizenProfiles()
    let legislatorProfiles = MockDataProvider.createMockLegislatorProfiles()

    for user in users {
        container.mainContext.insert(user)
    }
    for profile in citizenProfiles {
        container.mainContext.insert(profile)
    }
    for profile in legislatorProfiles {
        container.mainContext.insert(profile)
    }

    return MyProfileView(selectedTab: $selectedTab)
        .modelContainer(container)
}