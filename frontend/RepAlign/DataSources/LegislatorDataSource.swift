import Foundation

// MARK: - Data Source Protocol
protocol LegislatorDataSourceProtocol {
    func fetchAllCurrentLegislators() async throws -> [LegislatorProfile]
    func fetchLegislator(bioguideId: String) async throws -> LegislatorProfile?
    func fetchLegislatorsByState(state: String) async throws -> [LegislatorProfile]
    func fetchLegislatorsByParty(party: Party) async throws -> [LegislatorProfile]
}

// MARK: - Congress API Data Source
class CongressAPIDataSource: LegislatorDataSourceProtocol {
    private let apiService: CongressAPIService

    init(apiService: CongressAPIService = CongressAPIService()) {
        self.apiService = apiService
    }

    func fetchAllCurrentLegislators() async throws -> [LegislatorProfile] {
        // Fetch both House and Senate members
        async let houseMembers = apiService.fetchHouseMembers()
        async let senateMembers = apiService.fetchSenateMembers()

        let (house, senate) = try await (houseMembers, senateMembers)

        // Convert API models to domain models
        let houseLegislators = house.compactMap { LegislatorMapper.mapToDomain($0) }
        let senateLegislators = senate.compactMap { LegislatorMapper.mapToDomain($0) }

        return houseLegislators + senateLegislators
    }

    func fetchLegislator(bioguideId: String) async throws -> LegislatorProfile? {
        let member = try await apiService.fetchMember(bioguideId: bioguideId)
        return LegislatorMapper.mapToDomain(member)
    }

    func fetchLegislatorsByState(state: String) async throws -> [LegislatorProfile] {
        let members = try await apiService.fetchMembersByState(state: state)
        return members.compactMap { LegislatorMapper.mapToDomain($0) }
    }

    func fetchLegislatorsByParty(party: Party) async throws -> [LegislatorProfile] {
        // This would require filtering all members by party
        let allMembers = try await fetchAllCurrentLegislators()
        return allMembers.filter { $0.party == party }
    }
}

// MARK: - Future Backend Data Source
class BackendAPIDataSource: LegislatorDataSourceProtocol {
    private let baseURL = AppConfig.backendBaseURL

    func fetchAllCurrentLegislators() async throws -> [LegislatorProfile] {
        // TODO: Implement when backend is ready
        // This will call your custom backend API
        // which will have processed Congress data + your custom ratings
        throw DataSourceError.notImplemented
    }

    func fetchLegislator(bioguideId: String) async throws -> LegislatorProfile? {
        // TODO: Implement backend call
        throw DataSourceError.notImplemented
    }

    func fetchLegislatorsByState(state: String) async throws -> [LegislatorProfile] {
        // TODO: Implement backend call
        throw DataSourceError.notImplemented
    }

    func fetchLegislatorsByParty(party: Party) async throws -> [LegislatorProfile] {
        // TODO: Implement backend call
        throw DataSourceError.notImplemented
    }
}

// MARK: - Mock Data Source (for testing)
class MockDataSource: LegislatorDataSourceProtocol {
    func fetchAllCurrentLegislators() async throws -> [LegislatorProfile] {
        // Return existing mock data
        return MockDataProvider.createMockLegislatorProfiles()
    }

    func fetchLegislator(bioguideId: String) async throws -> LegislatorProfile? {
        let allMock = MockDataProvider.createMockLegislatorProfiles()
        return allMock.first // Return first mock legislator
    }

    func fetchLegislatorsByState(state: String) async throws -> [LegislatorProfile] {
        return MockDataProvider.createMockLegislatorProfiles()
    }

    func fetchLegislatorsByParty(party: Party) async throws -> [LegislatorProfile] {
        return MockDataProvider.createMockLegislatorProfiles().filter { $0.party == party }
    }
}

// MARK: - Data Source Errors
enum DataSourceError: Error, LocalizedError {
    case notImplemented
    case networkError(Error)
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Feature not implemented yet"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .invalidResponse:
            return "Invalid API response"
        }
    }
}