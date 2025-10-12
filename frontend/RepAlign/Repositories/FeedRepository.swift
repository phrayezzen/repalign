import Foundation
import Combine

class FeedRepository: ObservableObject {
    private let dataSource: FeedDataSource
    @Published private var cache: [FeedItem] = []
    private var currentPage = 1
    private var hasMorePages = true

    init(dataSource: FeedDataSource = BackendFeedDataSource()) {
        self.dataSource = dataSource
    }

    @MainActor
    func loadInitialFeed() async throws -> [FeedItem] {
        currentPage = 1
        hasMorePages = true
        cache.removeAll()

        let response = try await dataSource.fetchFeed(page: currentPage, limit: 20, search: nil)
        cache = response.items
        hasMorePages = response.hasMore

        return cache
    }

    @MainActor
    func loadMoreFeed() async throws -> [FeedItem] {
        guard hasMorePages else { return cache }

        currentPage += 1
        let response = try await dataSource.fetchFeed(page: currentPage, limit: 20, search: nil)

        cache.append(contentsOf: response.items)
        hasMorePages = response.hasMore

        return cache
    }

    @MainActor
    func refreshFeed() async throws -> [FeedItem] {
        return try await loadInitialFeed()
    }

    func searchFeed(query: String) async throws -> [FeedItem] {
        let response = try await dataSource.fetchFeed(page: 1, limit: 50, search: query)
        return response.items
    }

    var canLoadMore: Bool {
        hasMorePages
    }

    var cachedItems: [FeedItem] {
        cache
    }
}