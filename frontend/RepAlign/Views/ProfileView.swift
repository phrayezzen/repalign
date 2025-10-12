import SwiftUI
import SwiftData

struct ProfileView: View {
    let user: User
    let citizenProfile: CitizenProfile?
    let legislatorProfile: LegislatorProfile?
    @State private var isFollowing = false
    @State private var showingTakeAction = false
    @EnvironmentObject private var authService: AuthService

    @Query private var bills: [Bill]
    @Query private var votes: [Vote]
    @Query private var contributors: [CampaignContributor]
    @Query private var events: [Event]
    @Query private var allUsers: [User]
    @Query private var allLegislatorProfiles: [LegislatorProfile]

    private var isCurrentUser: Bool {
        // Check if this user matches the authenticated user
        // For now, we'll use user ID matching when we have proper auth
        authService.currentUser?.id == user.id
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                statsSection
                actionButtons

                if let citizenProfile = citizenProfile {
                    citizenEngagementCard(citizenProfile)
                } else if let legislatorProfile = legislatorProfile {
                    legislatorRatingsCard(legislatorProfile)
                    legislatorExtraContent
                }

                // User's Feed Section
                ProfileFeedSection(userId: user.id)

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCurrentUser {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        authService.logout()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showingTakeAction) {
            TakeActionView()
        }
    }

    @ViewBuilder
    private var legislatorExtraContent: some View {
        if user.userType == .legislator {
            VStack(spacing: 20) {
                VotingRecordView(
                    votes: votesForLegislator,
                    bills: bills,
                    stats: votingStats
                )

                CampaignContributorsView(
                    contributors: contributorsForLegislator
                )

                UpcomingEventsView(
                    events: eventsForLegislator
                )

                RelatedLegislatorsView(
                    relatedLegislators: relatedLegislators,
                    legislatorProfiles: allLegislatorProfiles
                )
            }
        }
    }

    private var votesForLegislator: [Vote] {
        return votes.filter { $0.legislatorId == user.id }
    }

    private var contributorsForLegislator: [CampaignContributor] {
        return contributors.filter { $0.legislatorId == user.id }
    }

    private var eventsForLegislator: [Event] {
        return events.filter { $0.organizerId == user.id }
    }

    private var relatedLegislators: [User] {
        return allUsers.filter {
            $0.userType == .legislator && $0.id != user.id
        }.prefix(4).map { $0 }
    }

    private var votingStats: VotingStats {
        let userVotes = votesForLegislator
        let alignedVotes = userVotes.filter { vote in
            bills.first(where: { $0.id == vote.billId })?.isAlignedWithUser == true
        }.count
        let totalVotes = userVotes.count

        return VotingStats(
            totalVotes: totalVotes,
            alignedVotes: alignedVotes,
            againstVotes: totalVotes - alignedVotes
        )
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ProfileAvatarView(user: user, size: 80)

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(user.displayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }

                if user.userType == .legislator, let legislatorProfile = legislatorProfile {
                    Text(legislatorProfile.formattedPosition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(legislatorProfile.party.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                } else {
                    Text(user.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let citizenProfile = citizenProfile, citizenProfile.isCivicConnector {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Civic Connector")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 40) {
            StatItem(value: user.postsCount, label: "Posts")
            StatItem(value: user.followersCount, label: "Followers")
            StatItem(value: user.followingCount, label: "Following")
        }
        .padding(.vertical, 16)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if user.userType == .legislator {
                legislatorActionButtons
            } else {
                citizenActionButtons
            }
        }
    }

    private var citizenActionButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: { isFollowing.toggle() }) {
                    Text(isFollowing ? "Following" : "Follow")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isFollowing ? Color.gray.opacity(0.2) : Color.red)
                        .foregroundColor(isFollowing ? .primary : .white)
                        .cornerRadius(8)
                }

                Button(action: {}) {
                    Text("Message")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }

            Button(action: { showingTakeAction = true }) {
                HStack {
                    Image(systemName: "megaphone")
                    Text("Take Action")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }

    private var legislatorActionButtons: some View {
        VStack(spacing: 8) {
            Button(action: { isFollowing.toggle() }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text(isFollowing ? "Following" : "Follow")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            HStack(spacing: 12) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "dollarsign.circle")
                        Text("Donate")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button(action: {}) {
                    HStack {
                        Image(systemName: "message")
                        Text("Contact")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }

            Button(action: { showingTakeAction = true }) {
                HStack {
                    Image(systemName: "megaphone")
                    Text("Take Action")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }

    private func citizenEngagementCard(_ profile: CitizenProfile) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Civic Engagement Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Text("\(profile.civicEngagementScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text("points")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                LevelBadgeView(level: profile.level)
            }

            if profile.level < 10 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Next Level")
                        Spacer()
                        Text("\(profile.nextLevelPoints) points to go")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    ProgressView(value: Double(profile.civicEngagementScore % 500), total: 500.0)
                        .tint(.blue)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private func legislatorRatingsCard(_ profile: LegislatorProfile) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RepAlign Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Text("\(Int(profile.repAlignScore))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor(profile.repAlignScore))

                        Text(profile.matchStatus.rawValue)
                            .font(.subheadline)
                            .foregroundColor(scoreColor(profile.repAlignScore))
                    }
                }

                Spacer()

                LevelBadgeView(level: Int(profile.repAlignScore / 10), isLegislator: true)
            }

            HStack(spacing: 20) {
                RatingItemView(
                    title: "Responsiveness",
                    percentage: profile.responsivenessRating
                )

                RatingItemView(
                    title: "Transparency",
                    percentage: profile.transparencyRating
                )
            }

            if profile.yearsInOffice > 0 {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text("\(profile.yearsInOffice) years in office")
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

struct StatItem: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct RatingItemView: View {
    let title: String
    let percentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(percentage))%")
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

struct ProfileFeedSection: View {
    let userId: String
    @StateObject private var repository = FeedRepository()
    @State private var feedItems: [FeedItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var userFeedItems: [FeedItem] {
        return feedItems.filter { $0.authorId == userId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                if !userFeedItems.isEmpty {
                    Text("\(userFeedItems.count) posts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading activity...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if userFeedItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No posts yet")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("This user hasn't shared any content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(userFeedItems.prefix(5)) { item in
                        FeedCard(item: item)
                    }

                    if userFeedItems.count > 5 {
                        Button(action: {
                            // TODO: Navigate to full profile feed
                        }) {
                            Text("View All Posts (\(userFeedItems.count))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
        .background(Color(.systemGroupedBackground))
        .task {
            await loadUserFeed()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
    }

    private func loadUserFeed() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let items = try await repository.loadInitialFeed()
            await MainActor.run {
                self.feedItems = items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }
}

#Preview {
    let user = MockDataProvider.createMockUsers().first!
    let citizenProfile = MockDataProvider.createMockCitizenProfiles().first!

    return ProfileView(
        user: user,
        citizenProfile: citizenProfile,
        legislatorProfile: nil
    )
}