import SwiftUI

struct OfficialsView: View {
    @State private var legislators: [LegislatorService.Legislator] = []
    @State private var searchText = ""
    @State private var selectedChamber: ChamberFilter = .all
    @State private var selectedParty: PartyFilter? = nil
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var currentOffset = 0
    @State private var hasMore = true

    enum ChamberFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case senators = "Senators"
        case representatives = "Representatives"

        var id: String { rawValue }

        var apiValue: String? {
            switch self {
            case .all:
                return nil
            case .senators:
                return "senate"
            case .representatives:
                return "house"
            }
        }
    }

    enum PartyFilter: String, CaseIterable, Identifiable {
        case democrat = "Democrat"
        case republican = "Republican"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search legislators...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            Task {
                                await loadLegislators(reset: true)
                            }
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            Task {
                                await loadLegislators(reset: true)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                // Chamber Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ChamberFilter.allCases) { chamber in
                            FilterChip(
                                title: chamber.rawValue,
                                isSelected: selectedChamber == chamber,
                                action: {
                                    selectedChamber = chamber
                                    Task {
                                        await loadLegislators(reset: true)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                // Party Filter Chips (Optional)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PartyFilter.allCases) { party in
                            FilterChip(
                                title: party.rawValue,
                                isSelected: selectedParty == party,
                                action: {
                                    if selectedParty == party {
                                        selectedParty = nil
                                    } else {
                                        selectedParty = party
                                    }
                                    Task {
                                        await loadLegislators(reset: true)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                Divider()

                // Content
                if isLoading && legislators.isEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading legislators...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                } else if legislators.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No legislators found")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Try adjusting your filters or search")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(legislators.enumerated()), id: \.element.id) { index, legislator in
                                VStack(spacing: 0) {
                                    NavigationLink(destination: LegislatorDetailView(legislatorId: legislator.id)) {
                                        LegislatorCard(legislator: legislator) {
                                            Task {
                                                await toggleFollow(legislator)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    if index < legislators.count - 1 {
                                        Divider()
                                            .padding(.leading, 96) // Align with content
                                    }
                                }

                                // Load more trigger
                                if index == legislators.count - 5 && !isLoadingMore && hasMore {
                                    Color.clear
                                        .frame(height: 1)
                                        .onAppear {
                                            Task {
                                                await loadLegislators(reset: false)
                                            }
                                        }
                                }
                            }

                            if isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                    }
                    .refreshable {
                        await loadLegislators(reset: true)
                    }
                }
            }
            .navigationTitle(selectedChamber == .senators ? "Senators" : selectedChamber == .representatives ? "Representatives" : "Officials")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await loadLegislators(reset: true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
    }

    private func loadLegislators(reset: Bool) async {
        if reset {
            currentOffset = 0
            legislators = []
            isLoading = true
        } else {
            currentOffset += 50
            isLoadingMore = true
        }

        do {
            let response = try await LegislatorService.shared.getLegislators(
                chamber: selectedChamber.apiValue,
                party: selectedParty?.rawValue,
                search: searchText.isEmpty ? nil : searchText,
                limit: 50,
                offset: currentOffset
            )

            await MainActor.run {
                if reset {
                    self.legislators = response.legislators
                } else {
                    self.legislators.append(contentsOf: response.legislators)
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

    private func toggleFollow(_ legislator: LegislatorService.Legislator) async {
        let isCurrentlyFollowing = legislator.isFollowing ?? false

        do {
            let response: LegislatorService.FollowResponse
            if isCurrentlyFollowing {
                response = try await LegislatorService.shared.unfollowLegislator(id: legislator.id)
            } else {
                response = try await LegislatorService.shared.followLegislator(id: legislator.id)
            }

            await MainActor.run {
                // Update the legislator in the list
                if let index = legislators.firstIndex(where: { $0.id == legislator.id }) {
                    legislators[index] = LegislatorService.Legislator(
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
                        createdAt: legislator.createdAt,
                        updatedAt: legislator.updatedAt,
                        isFollowing: !isCurrentlyFollowing
                    )
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.red : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

#Preview {
    OfficialsView()
}
