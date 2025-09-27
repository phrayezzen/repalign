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
        switch AppConfig.dataSource {
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
        // Try cache first
        let cachedLegislators = getCachedLegislators()

        // If cache is fresh, return it
        if !shouldRefreshData() && !cachedLegislators.isEmpty {
            return cachedLegislators
        }

        // Otherwise, fetch from remote and cache
        try await syncLegislators()
        return getCachedLegislators()
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
        let legislators = try await dataSource.fetchAllCurrentLegislators()
        cache.saveLegislators(legislators)
        cache.updateLastSyncDate()
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