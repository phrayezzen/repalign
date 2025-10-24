import SwiftUI

struct FeedView: View {
    @StateObject private var repository = FeedRepository()
    @State private var feedItems: [FeedItem] = []
    @State private var searchText = ""
    @State private var selectedFilter: FeedItemType? = nil
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showPetitions = false

    private let filterOptions: [(String, FeedItemType?)] = [
        ("General", nil),
        ("Updates", .post),
        ("Discussions", .post),
        ("Events", .event),
        ("Petitions", .petition)
    ]

    var filteredItems: [FeedItem] {
        var items = feedItems

        // Apply type filter
        if let selectedFilter = selectedFilter {
            items = items.filter { $0.type == selectedFilter }
        }

        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText) ||
                (item.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                item.authorName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Filter Tabs
                FilterTabsView(
                    options: filterOptions,
                    selectedFilter: $selectedFilter,
                    onPetitionsTab: {
                        showPetitions = true
                    }
                )
                .padding(.horizontal)

                // Feed Content
                if isLoading && feedItems.isEmpty {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                FeedCard(item: item)
                                    .onAppear {
                                        loadMoreIfNeeded(item: item)
                                    }
                            }

                            if isLoadingMore {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        await refreshFeed()
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadInitialFeed()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unexpected error occurred")
            }
        }
        .fullScreenCover(isPresented: $showPetitions) {
            PetitionsView()
        }
    }

    private func loadInitialFeed() async {
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

    private func refreshFeed() async {
        do {
            let items = try await repository.refreshFeed()
            await MainActor.run {
                self.feedItems = items
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }

    private func loadMoreIfNeeded(item: FeedItem) {
        let thresholdIndex = filteredItems.index(filteredItems.endIndex, offsetBy: -5)
        if let itemIndex = filteredItems.firstIndex(where: { $0.id == item.id }),
           itemIndex >= thresholdIndex,
           !isLoadingMore,
           repository.canLoadMore {

            Task {
                await loadMoreFeed()
            }
        }
    }

    private func loadMoreFeed() async {
        guard !isLoadingMore else { return }

        isLoadingMore = true

        do {
            let items = try await repository.loadMoreFeed()
            await MainActor.run {
                self.feedItems = items
                self.isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoadingMore = false
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search feed...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FilterTabsView: View {
    let options: [(String, FeedItemType?)]
    @Binding var selectedFilter: FeedItemType?
    let onPetitionsTab: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.0) { option in
                    FilterTab(
                        title: option.0,
                        isSelected: selectedFilter == option.1,
                        action: {
                            // Special handling for Petitions
                            if option.0 == "Petitions" {
                                onPetitionsTab()
                            } else {
                                selectedFilter = selectedFilter == option.1 ? nil : option.1
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct FilterTab: View {
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
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading feed...")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    FeedView()
}