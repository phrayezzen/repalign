import SwiftUI

struct PetitionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var petitions: [PetitionService.Petition] = []
    @State private var searchText = ""
    @State private var selectedFilter: PetitionFilter = .all
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showCreatePetition = false
    @State private var currentPage = 1
    @State private var hasMore = true

    enum PetitionFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "Active"
        case myPetitions = "My Petitions"
        case popular = "Popular"

        var id: String { rawValue }

        var sortBy: String {
            switch self {
            case .popular:
                return "popular"
            case .all, .active, .myPetitions:
                return "createdAt"
            }
        }

        var status: String? {
            switch self {
            case .active:
                return "active"
            default:
                return nil
            }
        }

        var mine: Bool {
            self == .myPetitions
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search petitions", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            Task {
                                await loadPetitions(reset: true)
                            }
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            Task {
                                await loadPetitions(reset: true)
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

                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PetitionFilter.allCases) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: {
                                    selectedFilter = filter
                                    Task {
                                        await loadPetitions(reset: true)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                // Content
                if isLoading && petitions.isEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading petitions...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                    Spacer()
                } else if petitions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No petitions found")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Try adjusting your filters or search")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(petitions.enumerated()), id: \.element.id) { index, petition in
                                if index == 0 && petition.isFeatured == true {
                                    // Featured card
                                    FeaturedPetitionCard(petition: petition) {
                                        Task {
                                            await signPetition(petition)
                                        }
                                    }
                                } else {
                                    // Compact card
                                    CompactPetitionCard(petition: petition) {
                                        Task {
                                            await signPetition(petition)
                                        }
                                    }
                                }

                                // Load more trigger
                                if index == petitions.count - 3 && !isLoadingMore && hasMore {
                                    Color.clear
                                        .frame(height: 1)
                                        .onAppear {
                                            Task {
                                                await loadPetitions(reset: false)
                                            }
                                        }
                                }
                            }

                            if isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadPetitions(reset: true)
                    }
                }
            }
            .navigationTitle("Petitions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePetition = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Create Petition")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(20)
                    }
                }
            }
        }
        .task {
            await loadPetitions(reset: true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
        .sheet(isPresented: $showCreatePetition) {
            CreatePetitionView()
        }
    }

    private func loadPetitions(reset: Bool) async {
        if reset {
            currentPage = 1
            petitions = []
            isLoading = true
        } else {
            currentPage += 1
            isLoadingMore = true
        }

        do {
            let response = try await PetitionService.shared.getPetitions(
                page: currentPage,
                limit: 20,
                search: searchText.isEmpty ? nil : searchText,
                status: selectedFilter.status,
                mine: selectedFilter.mine,
                sortBy: selectedFilter.sortBy
            )

            await MainActor.run {
                if reset {
                    self.petitions = response.items
                } else {
                    self.petitions.append(contentsOf: response.items)
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

    private func signPetition(_ petition: PetitionService.Petition) async {
        do {
            let response = try await PetitionService.shared.signPetition(id: petition.id)

            await MainActor.run {
                // Update the petition in the list
                if let index = petitions.firstIndex(where: { $0.id == petition.id }) {
                    var updatedPetition = petitions[index]
                    // Create a new petition instance with updated values
                    petitions[index] = PetitionService.Petition(
                        id: updatedPetition.id,
                        title: updatedPetition.title,
                        description: updatedPetition.description,
                        category: updatedPetition.category,
                        targetSignatures: updatedPetition.targetSignatures,
                        currentSignatures: response.currentSignatures,
                        progressPercentage: Double(response.currentSignatures) / Double(updatedPetition.targetSignatures) * 100,
                        status: updatedPetition.status,
                        deadline: updatedPetition.deadline,
                        daysRemaining: updatedPetition.daysRemaining,
                        creatorId: updatedPetition.creatorId,
                        creatorName: updatedPetition.creatorName,
                        creatorAvatar: updatedPetition.creatorAvatar,
                        createdAt: updatedPetition.createdAt,
                        updatedAt: updatedPetition.updatedAt,
                        userHasSigned: true,
                        isFeatured: updatedPetition.isFeatured
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

struct FilterButton: View {
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
    PetitionsView()
}
