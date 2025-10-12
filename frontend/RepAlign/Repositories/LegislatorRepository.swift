import Foundation
import SwiftData

// MARK: - Repository Protocol
protocol LegislatorRepositoryProtocol {
    func fetchAllLegislators() async throws -> [LegislatorProfile]
    func fetchLegislator(bioguideId: String) async throws -> LegislatorProfile?
    func syncLegislators() async throws
    func searchLegislators(query: String) async -> [LegislatorProfile]
    func getCachedLegislators() -> [LegislatorProfile]
    func shouldRefreshData() -> Bool
}

// MARK: - Repository Implementation
@Observable
class LegislatorRepository: LegislatorRepositoryProtocol {
    private let dataSource: LegislatorDataSourceProtocol
    private let cache: LegislatorCacheProtocol

    init(dataSource: LegislatorDataSourceProtocol? = nil, cache: LegislatorCacheProtocol? = nil) {
        // Dependency injection for easy testing and switching
        switch AppConfig.shared.dataSource {
        case .congressAPI:
            self.dataSource = dataSource ?? CongressAPIDataSource()
        case .customBackend:
            self.dataSource = dataSource ?? BackendAPIDataSource()
        case .mockData:
            self.dataSource = dataSource ?? MockDataSource()
        }

        self.cache = cache ?? SwiftDataLegislatorCache()
    }

    func fetchAllLegislators() async throws -> [LegislatorProfile] {
        print("DEBUG: fetchAllLegislators() called")
        print("DEBUG: Data source type: \(AppConfig.shared.dataSource)")

        // Try cache first
        let cachedLegislators = getCachedLegislators()

        // If cache is fresh, return it
        if !shouldRefreshData() && !cachedLegislators.isEmpty {
            print("DEBUG: Using cached data - \(cachedLegislators.count) legislators")
            return cachedLegislators
        }

        // Otherwise, fetch from remote and cache
        print("DEBUG: Cache is stale or empty, fetching from backend")
        try await syncLegislators()
        let legislators = getCachedLegislators()
        print("DEBUG: After sync, got \(legislators.count) legislators from cache")
        return legislators
    }

    func fetchLegislator(bioguideId: String) async throws -> LegislatorProfile? {
        // Check cache first
        if let cached = cache.getLegislator(bioguideId: bioguideId) {
            return cached
        }

        // Fetch from remote
        if let legislator = try await dataSource.fetchLegislator(bioguideId: bioguideId) {
            cache.saveLegislator(legislator)
            return legislator
        }

        return nil
    }

    func syncLegislators() async throws {
        print("DEBUG: syncLegislators() called - fetching from data source")
        let legislators = try await dataSource.fetchAllCurrentLegislators()
        print("DEBUG: Fetched \(legislators.count) legislators from data source")
        cache.saveLegislators(legislators)
        cache.updateLastSyncDate()
        print("DEBUG: Saved legislators to cache and updated sync date")
    }

    func searchLegislators(query: String) async -> [LegislatorProfile] {
        let allLegislators = getCachedLegislators()

        if query.isEmpty {
            return allLegislators
        }

        return allLegislators.filter { legislator in
            legislator.user?.displayName.localizedCaseInsensitiveContains(query) == true ||
            legislator.user?.location.localizedCaseInsensitiveContains(query) == true ||
            legislator.party.rawValue.localizedCaseInsensitiveContains(query) == true ||
            legislator.position.rawValue.localizedCaseInsensitiveContains(query) == true
        }
    }

    func getCachedLegislators() -> [LegislatorProfile] {
        return cache.getAllLegislators()
    }

    func shouldRefreshData() -> Bool {
        return cache.shouldRefresh()
    }
}

// MARK: - Singleton Access
extension LegislatorRepository {
    static let shared = LegislatorRepository()
}