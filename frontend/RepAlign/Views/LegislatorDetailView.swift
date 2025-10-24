import SwiftUI

struct LegislatorDetailView: View {
    let legislatorId: String
    @Environment(\.dismiss) private var dismiss
    @State private var legislator: LegislatorService.LegislatorDetail?
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var isTogglingFollow = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showVolunteerAlert = false

    private let tabs = ["Overview", "Committees", "Donors", "Voting", "Press"]

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading profile...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if let legislator = legislator {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Profile Image with verified badge
                        ZStack(alignment: .bottomTrailing) {
                            if let photoUrl = legislator.photoUrl, let url = URL(string: photoUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color(.systemGray5))
                                        .overlay(
                                            Text(legislator.initials ?? "")
                                                .font(.largeTitle)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        )
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(legislator.initials ?? "")
                                            .font(.largeTitle)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    )
                            }

                            // Verified badge
                            Circle()
                                .fill(.blue)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 4, y: 4)
                        }

                        // Name and Title
                        VStack(spacing: 4) {
                            Text(legislator.fullName)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(legislator.titleAndParty)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Location and Followers
                        HStack(spacing: 20) {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(.secondary)
                                Text(legislator.state)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "person.2")
                                    .foregroundColor(.secondary)
                                Text("\(legislator.formattedFollowers) followers")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Tab Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 32) {
                            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                                VStack(spacing: 8) {
                                    Text(tab)
                                        .font(.subheadline)
                                        .fontWeight(selectedTab == index ? .semibold : .regular)
                                        .foregroundColor(selectedTab == index ? .primary : .secondary)

                                    Rectangle()
                                        .fill(selectedTab == index ? Color.red : Color.clear)
                                        .frame(height: 2)
                                }
                                .onTapGesture {
                                    selectedTab = index
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    Divider()

                    // Content based on selected tab
                    switch selectedTab {
                    case 0: // Overview
                        VStack(spacing: 20) {
                            // RepAlign Score Card
                            RepAlignScoreCard()
                                .padding(.horizontal, 20)
                                .padding(.top, 20)

                            // About Section
                            if let bio = legislator.bio {
                                AboutSection(bio: bio)
                                    .padding(.horizontal, 20)
                            }

                            // Top Donors Section
                            if let donors = legislator.topDonors, !donors.isEmpty {
                                TopDonorsSection(donors: donors)
                                    .padding(.horizontal, 20)
                            }

                            // Contact Information
                            ContactInfoSection(
                                officeAddress: legislator.officeAddress,
                                phoneNumber: legislator.phoneNumber,
                                websiteUrl: legislator.websiteUrl
                            )
                            .padding(.horizontal, 20)

                            // Recent Votes
                            if let votes = legislator.recentVotes, !votes.isEmpty {
                                RecentVotesSection(votes: votes)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 100) // Space for floating button bar

                    case 1: // Committees
                        CommitteesTabView(legislatorId: legislatorId, committees: legislator.committees ?? [])
                            .padding(.bottom, 100)

                    case 2: // Donors
                        DonorsTabView(legislatorId: legislatorId)
                            .padding(.bottom, 100)

                    case 3: // Voting
                        VotingTabView(legislatorId: legislatorId)
                            .padding(.bottom, 100)

                    case 4: // Press
                        PressTabView(legislatorId: legislatorId)
                            .padding(.bottom, 100)

                    default:
                        EmptyView()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Official Profile")
                    .font(.headline)
            }
        }
        .overlay(alignment: .bottom) {
            if let legislator = legislator {
                ActionButtonBar(
                    legislator: legislator,
                    isTogglingFollow: isTogglingFollow,
                    onFollow: {
                        Task {
                            await toggleFollow()
                        }
                    },
                    onVolunteer: {
                        showVolunteerAlert = true
                    },
                    onDonate: {
                        openDonationLink(party: legislator.party)
                    }
                )
            }
        }
        .task {
            await loadLegislator()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
        .alert("Volunteer", isPresented: $showVolunteerAlert) {
            Button("OK") { }
        } message: {
            Text("Volunteer opportunities coming soon!")
        }
    }

    private func loadLegislator() async {
        isLoading = true

        do {
            let loadedLegislator = try await LegislatorService.shared.getLegislator(id: legislatorId)
            await MainActor.run {
                self.legislator = loadedLegislator
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

    private func toggleFollow() async {
        guard let legislator = legislator else { return }

        isTogglingFollow = true
        let isCurrentlyFollowing = legislator.isFollowing ?? false

        do {
            let response: LegislatorService.FollowResponse
            if isCurrentlyFollowing {
                response = try await LegislatorService.shared.unfollowLegislator(id: legislator.id)
            } else {
                response = try await LegislatorService.shared.followLegislator(id: legislator.id)
            }

            await MainActor.run {
                self.legislator = LegislatorService.LegislatorDetail(
                    id: legislator.id,
                    firstName: legislator.firstName,
                    lastName: legislator.lastName,
                    photoUrl: legislator.photoUrl,
                    initials: legislator.initials,
                    chamber: legislator.chamber,
                    state: legislator.state,
                    district: legislator.district,
                    party: legislator.party,
                    yearsInOffice: legislator.yearsInOffice,
                    followerCount: response.followerCount,
                    bioguideId: legislator.bioguideId,
                    userId: legislator.userId,
                    phoneNumber: legislator.phoneNumber,
                    websiteUrl: legislator.websiteUrl,
                    officeAddress: legislator.officeAddress,
                    bio: legislator.bio,
                    createdAt: legislator.createdAt,
                    updatedAt: legislator.updatedAt,
                    isFollowing: !isCurrentlyFollowing,
                    committees: legislator.committees,
                    topDonors: legislator.topDonors,
                    recentVotes: legislator.recentVotes
                )
                self.isTogglingFollow = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isTogglingFollow = false
            }
        }
    }

    private func openDonationLink(party: String) {
        let urlString: String
        switch party.lowercased() {
        case "democrat", "democratic":
            urlString = "https://secure.actblue.com"
        case "republican":
            urlString = "https://winred.com"
        default:
            return
        }

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - RepAlign Score Card

struct RepAlignScoreCard: View {
    // Mock data
    private let overallMatch = 87
    private let responsiveness = 92
    private let transparency = 84

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.red)
                    Text("RepAlign Score")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("\(overallMatch)% Match")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Overall Alignment
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Overall Alignment")
                            .font(.subheadline)
                        Spacer()
                        Text("\(overallMatch)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    ProgressView(value: Double(overallMatch) / 100.0)
                        .tint(.black)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }

                // Responsiveness and Transparency
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Responsiveness")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(responsiveness)%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transparency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(transparency)%")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - About Section

struct AboutSection: View {
    let bio: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .fontWeight(.semibold)

            Text(bio)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Top Donors Section

struct TopDonorsSection: View {
    let donors: [LegislatorService.Donor]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                    Text("Top Donors")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text("View All")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            VStack(spacing: 12) {
                ForEach(donors.prefix(3)) { donor in
                    DonorRow(donor: donor)

                    if donor.id != donors.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct DonorRow: View {
    let donor: LegislatorService.Donor

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(donor.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(donor.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(donor.formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
    }
}

// MARK: - Contact Info Section

struct ContactInfoSection: View {
    let officeAddress: String?
    let phoneNumber: String?
    let websiteUrl: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                if let office = officeAddress {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2")
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        Text(office)
                            .font(.subheadline)
                    }
                }

                if let phone = phoneNumber {
                    HStack(spacing: 12) {
                        Image(systemName: "phone")
                            .foregroundColor(.secondary)
                            .frame(width: 20)

                        Text(phone)
                            .font(.subheadline)
                    }
                }

                if let website = websiteUrl {
                    Button(action: {
                        if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .foregroundColor(.secondary)
                                .frame(width: 20)

                            Text(website)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Recent Votes Section

struct RecentVotesSection: View {
    let votes: [LegislatorService.RecentVote]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Votes")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("View All")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            VStack(spacing: 12) {
                ForEach(votes.prefix(3)) { vote in
                    VoteRow(vote: vote)

                    if vote.id != votes.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct VoteRow: View {
    let vote: LegislatorService.RecentVote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vote.billTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(formatDate(vote.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    // Position badge
                    Text(vote.position)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(vote.position == "Yes" ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(vote.position == "Yes" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(4)

                    // Aligned badge
                    Text(vote.aligned ? "Aligned" : "Opposed")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(vote.aligned ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(vote.aligned ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Action Button Bar

struct ActionButtonBar: View {
    let legislator: LegislatorService.LegislatorDetail
    let isTogglingFollow: Bool
    let onFollow: () -> Void
    let onVolunteer: () -> Void
    let onDonate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Follow Button
            Button(action: onFollow) {
                HStack {
                    if isTogglingFollow {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }

                    Text(legislator.isFollowing == true ? "Following" : "Follow")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isTogglingFollow)

            // Volunteer Button
            Button(action: onVolunteer) {
                Text("Volunteer")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }

            // Donate Button
            Button(action: onDonate) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Donate")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
        )
    }
}

// MARK: - Committees Tab View

struct CommitteesTabView: View {
    let legislatorId: String
    let committees: [LegislatorService.CommitteeMembership]

    var body: some View {
        VStack(spacing: 0) {
            if committees.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No committee memberships")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(committees) { committee in
                            CommitteeCard(committee: committee)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
    }
}

struct CommitteeCard: View {
    let committee: LegislatorService.CommitteeMembership

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(committee.committeeName)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Text(committee.role)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(committee.role == "Chair" ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(committee.role == "Chair" ? Color.black : Color(.systemGray6))
                    .cornerRadius(4)

                Spacer()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Donors Tab View

struct DonorsTabView: View {
    let legislatorId: String
    @State private var donors: [LegislatorService.Donor] = []
    @State private var selectedFilter: DonorFilter = .all
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentOffset = 0
    @State private var hasMore = true
    @State private var errorMessage: String?
    @State private var showError = false

    enum DonorFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case individuals = "Individuals"
        case pacs = "PACs"

        var id: String { rawValue }

        var apiValue: String {
            switch self {
            case .all:
                return "all"
            case .individuals:
                return "individual"
            case .pacs:
                return "pac"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DonorFilter.allCases) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                                Task {
                                    await loadDonors(reset: true)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 12)

            Divider()

            // Content
            if isLoading && donors.isEmpty {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading donors...")
                    .foregroundColor(.secondary)
                    .padding(.top)
                Spacer()
            } else if donors.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No donors found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(donors.enumerated()), id: \.element.id) { index, donor in
                            DonorCard(donor: donor)

                            // Load more trigger
                            if index == donors.count - 5 && !isLoadingMore && hasMore {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        Task {
                                            await loadDonors(reset: false)
                                        }
                                    }
                            }
                        }

                        if isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .task {
            await loadDonors(reset: true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
    }

    private func loadDonors(reset: Bool) async {
        if reset {
            currentOffset = 0
            donors = []
            isLoading = true
        } else {
            currentOffset += 50
            isLoadingMore = true
        }

        do {
            let response = try await LegislatorService.shared.getDonors(
                id: legislatorId,
                limit: 50,
                offset: currentOffset,
                type: selectedFilter.apiValue
            )

            await MainActor.run {
                if reset {
                    self.donors = response.donors
                } else {
                    self.donors.append(contentsOf: response.donors)
                }
                self.hasMore = response.hasMore
                self.isLoading = false
                self.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
                self.isLoadingMore = false
            }
        }
    }
}

struct DonorCard: View {
    let donor: LegislatorService.Donor

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(donor.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(donor.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(donor.formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Voting Tab View

struct VotingTabView: View {
    let legislatorId: String
    @State private var votes: [LegislatorService.RecentVote] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentOffset = 0
    @State private var hasMore = true
    @State private var errorMessage: String?
    @State private var showError = false

    // Mock alignment stats
    private let alignmentRate = 87
    private let totalVotes = 156

    var body: some View {
        VStack(spacing: 0) {
            // Stats Cards
            HStack(spacing: 12) {
                VotingStatCard(value: "\(alignmentRate)%", label: "Alignment Rate", color: .green)
                VotingStatCard(value: "\(totalVotes)", label: "Recent Votes", color: .blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)

            Divider()

            // Content
            if isLoading && votes.isEmpty {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading votes...")
                    .foregroundColor(.secondary)
                    .padding(.top)
                Spacer()
            } else if votes.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "checklist")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No votes found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(votes.enumerated()), id: \.element.id) { index, vote in
                            VoteCard(vote: vote)

                            // Load more trigger
                            if index == votes.count - 5 && !isLoadingMore && hasMore {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        Task {
                                            await loadVotes(reset: false)
                                        }
                                    }
                            }
                        }

                        if isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .task {
            await loadVotes(reset: true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
    }

    private func loadVotes(reset: Bool) async {
        if reset {
            currentOffset = 0
            votes = []
            isLoading = true
        } else {
            currentOffset += 50
            isLoadingMore = true
        }

        do {
            let response = try await LegislatorService.shared.getVotes(
                id: legislatorId,
                limit: 50,
                offset: currentOffset
            )

            await MainActor.run {
                if reset {
                    self.votes = response.votes
                } else {
                    self.votes.append(contentsOf: response.votes)
                }
                self.hasMore = response.hasMore
                self.isLoading = false
                self.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
                self.isLoadingMore = false
            }
        }
    }
}

struct VotingStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct VoteCard: View {
    let vote: LegislatorService.RecentVote

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(vote.billTitle)
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                // Position badge
                Text(vote.position)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(vote.position == "Yes" ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(vote.position == "Yes" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(4)

                // Aligned badge
                Text(vote.aligned ? "Aligned" : "Opposed")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(vote.aligned ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(vote.aligned ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    .cornerRadius(4)

                Spacer()

                Text(formatDate(vote.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Press Tab View

struct PressTabView: View {
    let legislatorId: String
    @State private var pressReleases: [LegislatorService.PressRelease] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var currentOffset = 0
    @State private var hasMore = true
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .foregroundColor(.primary)
                Text("Press Releases")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            // Content
            if isLoading && pressReleases.isEmpty {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading press releases...")
                    .foregroundColor(.secondary)
                    .padding(.top)
                Spacer()
            } else if pressReleases.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No press releases found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(pressReleases.enumerated()), id: \.element.id) { index, press in
                            PressReleaseCard(pressRelease: press)

                            // Load more trigger
                            if index == pressReleases.count - 5 && !isLoadingMore && hasMore {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        Task {
                                            await loadPressReleases(reset: false)
                                        }
                                    }
                            }
                        }

                        if isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .task {
            await loadPressReleases(reset: true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
    }

    private func loadPressReleases(reset: Bool) async {
        if reset {
            currentOffset = 0
            pressReleases = []
            isLoading = true
        } else {
            currentOffset += 50
            isLoadingMore = true
        }

        do {
            let response = try await LegislatorService.shared.getPressReleases(
                id: legislatorId,
                limit: 50,
                offset: currentOffset
            )

            await MainActor.run {
                if reset {
                    self.pressReleases = response.pressReleases
                } else {
                    self.pressReleases.append(contentsOf: response.pressReleases)
                }
                self.hasMore = response.hasMore
                self.isLoading = false
                self.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
                self.isLoadingMore = false
            }
        }
    }
}

struct PressReleaseCard: View {
    let pressRelease: LegislatorService.PressRelease

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            if let thumbnailUrl = pressRelease.thumbnailUrl, let url = URL(string: thumbnailUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Image(systemName: "doc.text")
                            .foregroundColor(.secondary)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(pressRelease.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(pressRelease.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Text(formatDate(pressRelease.publishedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("Read More")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        LegislatorDetailView(legislatorId: "sample-id")
    }
}
