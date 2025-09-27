import SwiftUI
import SwiftData

struct ProfileListView: View {
    @Query private var citizenUsers: [User]
    @Query private var citizenProfiles: [CitizenProfile]

    @State private var legislatorViewModel = LegislatorListViewModel()
    @State private var selectedFilter: UserFilter = .all
    @State private var searchText = ""

    enum UserFilter: String, CaseIterable {
        case all = "All"
        case citizens = "Citizens"
        case legislators = "Legislators"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterPicker

                if legislatorViewModel.isLoading && allUsers.isEmpty {
                    loadingView
                } else {
                    List(filteredUsers) { user in
                        NavigationLink(destination: profileDestination(for: user)) {
                            ProfileRowView(
                                user: user,
                                citizenProfile: citizenProfile(for: user),
                                legislatorProfile: legislatorProfile(for: user)
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await legislatorViewModel.refreshLegislators()
                    }
                }

                if let errorMessage = legislatorViewModel.errorMessage {
                    errorView(errorMessage)
                }
            }
            .navigationTitle("Profiles")
            .searchable(text: $searchText, prompt: "Search users...")
            .onChange(of: searchText) { _, newValue in
                legislatorViewModel.searchQuery = newValue
                Task {
                    await legislatorViewModel.searchLegislators()
                }
            }
            .task {
                await legislatorViewModel.loadLegislators()
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(UserFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // Combine citizens from SwiftData and legislators from repository
    private var allUsers: [User] {
        let citizens = citizenUsers.filter { $0.userType == .citizen }
        let legislators = legislatorViewModel.legislators.compactMap { $0.user }
        return citizens + legislators
    }

    private var filteredUsers: [User] {
        let filtered: [User]

        switch selectedFilter {
        case .all:
            filtered = allUsers
        case .citizens:
            filtered = allUsers.filter { $0.userType == .citizen }
        case .legislators:
            filtered = allUsers.filter { $0.userType == .legislator }
        }

        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { user in
                user.displayName.localizedCaseInsensitiveContains(searchText) ||
                user.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func citizenProfile(for user: User) -> CitizenProfile? {
        return citizenProfiles.first { $0.userId == user.id }
    }

    private func legislatorProfile(for user: User) -> LegislatorProfile? {
        return legislatorViewModel.legislators.first { $0.userId == user.id }
    }

    private func profileDestination(for user: User) -> some View {
        ProfileView(
            user: user,
            citizenProfile: citizenProfile(for: user),
            legislatorProfile: legislatorProfile(for: user)
        )
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading profiles...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task {
                    await legislatorViewModel.refreshLegislators()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ProfileRowView: View {
    let user: User
    let citizenProfile: CitizenProfile?
    let legislatorProfile: LegislatorProfile?

    var body: some View {
        HStack(spacing: 12) {
            ProfileAvatarView(user: user, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.headline)
                        .fontWeight(.medium)

                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }

                if let legislatorProfile = legislatorProfile {
                    Text(legislatorProfile.formattedPosition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text("RepAlign:")
                        Text("\(Int(legislatorProfile.repAlignScore))%")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(scoreColor(legislatorProfile.repAlignScore))
                } else if let citizenProfile = citizenProfile {
                    Text(user.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("\(citizenProfile.civicEngagementScore)")
                                .fontWeight(.semibold)
                            Text("points")
                        }

                        if citizenProfile.isCivicConnector {
                            Text("Civic Connector")
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                    .font(.caption)
                } else {
                    Text(user.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(user.followersCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("followers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, CitizenProfile.self, LegislatorProfile.self, configurations: config)

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

    return ProfileListView()
        .modelContainer(container)
}