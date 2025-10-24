import Foundation

// MARK: - Data Source Protocol
protocol LegislatorDataSourceProtocol {
    func fetchAllCurrentLegislators() async throws -> [LegislatorProfile]
    func fetchLegislators(limit: Int, offset: Int) async throws -> [LegislatorProfile]
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
        return try await fetchLegislators(limit: 50, offset: 0)
    }

    func fetchLegislators(limit: Int, offset: Int) async throws -> [LegislatorProfile] {
        // Congress API doesn't support pagination, so we fetch all and slice
        let allLegislators = try await fetchAllLegislatorsFromAPI()
        let endIndex = min(offset + limit, allLegislators.count)

        if offset >= allLegislators.count {
            return []
        }

        return Array(allLegislators[offset..<endIndex])
    }

    private func fetchAllLegislatorsFromAPI() async throws -> [LegislatorProfile] {
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

// MARK: - Backend Data Source
class BackendAPIDataSource: LegislatorDataSourceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchAllCurrentLegislators() async throws -> [LegislatorProfile] {
        // For initial load, just fetch first page
        return try await fetchLegislators(limit: 50, offset: 0)
    }

    func fetchLegislators(limit: Int = 50, offset: Int = 0) async throws -> [LegislatorProfile] {
        print("DEBUG: BackendAPIDataSource.fetchLegislators() called with limit=\(limit), offset=\(offset)")

        do {
            let backendResponse: BackendLegislatorsResponse = try await apiClient.get(
                path: "/legislators?limit=\(limit)&offset=\(offset)",
                requiresAuth: false
            )
            print("DEBUG: Decoded \(backendResponse.legislators.count) legislators from backend")
            let mappedLegislators = backendResponse.legislators.compactMap { BackendLegislatorMapper.mapToDomain($0) }
            print("DEBUG: Mapped \(mappedLegislators.count) legislators to domain objects")
            return mappedLegislators
        } catch {
            print("DEBUG: Backend API error: \(error)")
            throw DataSourceError.networkError(URLError(.badServerResponse))
        }
    }

    func fetchLegislator(bioguideId: String) async throws -> LegislatorProfile? {
        // First try to find by bioguideId in the full list
        let allLegislators = try await fetchAllCurrentLegislators()
        return allLegislators.first { $0.bioguideId == bioguideId }
    }

    func fetchLegislatorsByState(state: String) async throws -> [LegislatorProfile] {
        do {
            let backendLegislators: [BackendLegislator] = try await apiClient.get(
                path: "/legislators/states/\(state)",
                requiresAuth: false
            )
            return backendLegislators.compactMap { BackendLegislatorMapper.mapToDomain($0) }
        } catch {
            throw DataSourceError.networkError(URLError(.badServerResponse))
        }
    }

    func fetchLegislatorsByParty(party: Party) async throws -> [LegislatorProfile] {
        let allLegislators = try await fetchAllCurrentLegislators()
        return allLegislators.filter { $0.party == party }
    }
}

// MARK: - Mock Data Source (for testing)
class MockDataSource: LegislatorDataSourceProtocol {
    func fetchAllCurrentLegislators() async throws -> [LegislatorProfile] {
        return try await fetchLegislators(limit: 50, offset: 0)
    }

    func fetchLegislators(limit: Int, offset: Int) async throws -> [LegislatorProfile] {
        // Return existing mock data with pagination
        let allMock = MockDataProvider.createMockLegislatorProfiles()
        let endIndex = min(offset + limit, allMock.count)

        if offset >= allMock.count {
            return []
        }

        return Array(allMock[offset..<endIndex])
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

// MARK: - Backend Response Models
struct BackendLegislatorsResponse: Codable {
    let legislators: [BackendLegislator]
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
}

struct BackendLegislator: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let photoUrl: String?
    let initials: String?
    let chamber: String // "house" or "senate"
    let state: String
    let district: String?
    let party: String // "DEMOCRAT", "REPUBLICAN", "INDEPENDENT"
    let yearsInOffice: Int
    let bioguideId: String
    let userId: String?
    let createdAt: String
    let updatedAt: String
}

// MARK: - Backend Legislator Mapper
struct BackendLegislatorMapper {
    static func mapToDomain(_ backendLegislator: BackendLegislator) -> LegislatorProfile? {
        // Create User first
        let user = createUser(from: backendLegislator)

        // Map party
        guard let party = mapParty(backendLegislator.party) else {
            print("Unknown party: \(backendLegislator.party)")
            return nil
        }

        // Map position
        let position: PoliticalPosition = backendLegislator.chamber == "senate" ? .senator : .representative

        // Create district string
        let district = createDistrictString(
            state: backendLegislator.state,
            district: backendLegislator.district,
            position: position
        )

        // Create LegislatorProfile
        let profile = LegislatorProfile(
            userId: user.id,
            bioguideId: backendLegislator.bioguideId,
            position: position,
            district: district,
            party: party,
            yearsInOffice: backendLegislator.yearsInOffice,
            alignmentRating: generateRandomRating(), // TODO: Get from your backend
            responsivenessRating: generateRandomRating(),
            transparencyRating: generateRandomRating(),
            officialWebsiteURL: generateOfficialWebsite(for: backendLegislator),
            contactPhoneNumber: nil,
            committees: [], // TODO: Add when backend provides this
            leadership: [] // TODO: Add when backend provides this
        )

        // IMPORTANT: Set the user property so UI can display it
        profile.user = user

        return profile
    }

    private static func createUser(from backendLegislator: BackendLegislator) -> User {
        let displayName = "\(backendLegislator.chamber == "senate" ? "Sen." : "Rep.") \(backendLegislator.firstName) \(backendLegislator.lastName)"
        let location = "\(backendLegislator.state), USA"

        return User(
            id: backendLegislator.bioguideId,
            username: backendLegislator.bioguideId.lowercased(),
            displayName: displayName,
            bio: generateBio(for: backendLegislator),
            profileImageURL: backendLegislator.photoUrl,
            location: location,
            postsCount: 0,
            followersCount: generateRandomFollowerCount(),
            followingCount: 0,
            userType: .legislator,
            isVerified: true
        )
    }

    private static func mapParty(_ partyString: String) -> Party? {
        switch partyString.uppercased() {
        case "DEMOCRAT", "DEMOCRATIC":
            return .democrat
        case "REPUBLICAN":
            return .republican
        case "INDEPENDENT":
            return .independent
        default:
            return nil
        }
    }

    private static func createDistrictString(
        state: String,
        district: String?,
        position: PoliticalPosition
    ) -> String? {
        switch position {
        case .senator:
            return state
        case .representative:
            if let district = district, district != "0" {
                return "\(state)-\(district)"
            } else {
                return "\(state) At-Large"
            }
        default:
            return state
        }
    }

    private static func generateBio(for legislator: BackendLegislator) -> String {
        let title = legislator.chamber == "senate" ? "Senator" : "Representative"
        let location = legislator.district != nil ? "District \(legislator.district!)" : legislator.state
        return "\(title) representing \(location). Committed to serving the people and advancing important legislation."
    }

    private static func generateRandomRating() -> Double {
        return Double.random(in: 60...95)
    }

    private static func generateRandomFollowerCount() -> Int {
        return Int.random(in: 1000...50000)
    }

    private static func generateOfficialWebsite(for legislator: BackendLegislator) -> String? {
        let lastName = legislator.lastName.lowercased()
        return legislator.chamber == "senate" ?
            "https://\(lastName).senate.gov" :
            "https://\(lastName).house.gov"
    }
}