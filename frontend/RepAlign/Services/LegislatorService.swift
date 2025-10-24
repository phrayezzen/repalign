import Foundation

class LegislatorService {
    static let shared = LegislatorService()
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Models

    struct Donor: Codable, Identifiable {
        let id: String
        let name: String
        let type: String
        let amount: String
        let formattedAmount: String
        let date: Date
    }

    struct RecentVote: Codable, Identifiable {
        let id: String
        let billId: String
        let billTitle: String
        let billNumber: String?
        let position: String // "Yes", "No", "Abstain", "Absent"
        let timestamp: Date
        let aligned: Bool
    }

    struct CommitteeMembership: Codable, Identifiable {
        let id: String
        let committeeName: String
        let role: String // "Chair", "Ranking Member", "Member"
    }

    struct PressRelease: Codable, Identifiable {
        let id: String
        let title: String
        let description: String
        let thumbnailUrl: String?
        let publishedAt: Date
    }

    struct DonorsResponse: Codable {
        let donors: [Donor]
        let total: Int
        let limit: Int
        let offset: Int
        let hasMore: Bool
    }

    struct VotesResponse: Codable {
        let votes: [RecentVote]
        let total: Int
        let limit: Int
        let offset: Int
        let hasMore: Bool
    }

    struct PressResponse: Codable {
        let pressReleases: [PressRelease]
        let total: Int
        let limit: Int
        let offset: Int
        let hasMore: Bool
    }

    struct LegislatorDetail: Codable, Identifiable {
        let id: String
        let firstName: String
        let lastName: String
        let photoUrl: String?
        let initials: String?
        let chamber: String
        let state: String
        let district: String?
        let party: String
        let yearsInOffice: Int
        let followerCount: Int
        let bioguideId: String
        let userId: String?
        // Contact info
        let phoneNumber: String?
        let websiteUrl: String?
        let officeAddress: String?
        let bio: String?
        // Dates
        let createdAt: Date
        let updatedAt: Date
        // Social
        let isFollowing: Bool?
        // Additional data
        let committees: [CommitteeMembership]?
        let topDonors: [Donor]?
        let recentVotes: [RecentVote]?

        var displayName: String {
            let title = chamber == "senate" ? "Sen." : "Rep."
            return "\(title) \(firstName) \(lastName)"
        }

        var fullName: String {
            "\(firstName) \(lastName)"
        }

        var titleAndParty: String {
            let title = chamber == "senate" ? "Senator" : "Representative"
            return "\(title) • \(party)"
        }

        var partyColor: String {
            switch party.lowercased() {
            case "democrat", "democratic":
                return "blue"
            case "republican":
                return "red"
            default:
                return "gray"
            }
        }

        var formattedFollowers: String {
            formatNumber(followerCount)
        }

        private func formatNumber(_ number: Int) -> String {
            if number >= 1000 {
                let value = Double(number) / 1000.0
                return String(format: "%.1fK", value)
            }
            return "\(number)"
        }
    }

    struct Legislator: Codable, Identifiable {
        let id: String
        let firstName: String
        let lastName: String
        let photoUrl: String?
        let initials: String?
        let chamber: String // "house" or "senate"
        let state: String
        let district: String?
        let party: String // Party enum as string
        let yearsInOffice: Int
        let followerCount: Int
        let bioguideId: String
        let userId: String?
        let createdAt: Date
        let updatedAt: Date
        let isFollowing: Bool?

        var displayName: String {
            let title = chamber == "senate" ? "Sen." : "Rep."
            return "\(title) \(firstName) \(lastName)"
        }

        var fullName: String {
            "\(firstName) \(lastName)"
        }

        var partyColor: String {
            switch party.lowercased() {
            case "democrat", "democratic":
                return "blue"
            case "republican":
                return "red"
            default:
                return "gray"
            }
        }

        var formattedFollowers: String {
            formatNumber(followerCount)
        }

        private func formatNumber(_ number: Int) -> String {
            if number >= 1000 {
                let value = Double(number) / 1000.0
                return String(format: "%.1fK", value)
            }
            return "\(number)"
        }
    }

    struct LegislatorsResponse: Codable {
        let legislators: [Legislator]
        let total: Int
        let limit: Int
        let offset: Int
        let hasMore: Bool
    }

    struct FollowResponse: Codable {
        let message: String
        let followerCount: Int
    }

    // MARK: - API Methods

    func getLegislators(
        state: String? = nil,
        chamber: String? = nil,
        party: String? = nil,
        search: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> LegislatorsResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        if let state = state, !state.isEmpty {
            queryItems.append(URLQueryItem(name: "state", value: state))
        }

        if let chamber = chamber, !chamber.isEmpty {
            queryItems.append(URLQueryItem(name: "chamber", value: chamber))
        }

        if let party = party, !party.isEmpty {
            queryItems.append(URLQueryItem(name: "party", value: party))
        }

        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        var components = URLComponents()
        components.queryItems = queryItems
        let queryString = components.percentEncodedQuery ?? ""
        let path = "/legislators" + (queryString.isEmpty ? "" : "?\(queryString)")

        return try await apiClient.get(path: path, requiresAuth: false)
    }

    func getLegislator(id: String) async throws -> LegislatorDetail {
        return try await apiClient.get(path: "/legislators/\(id)", requiresAuth: false)
    }

    func followLegislator(id: String) async throws -> FollowResponse {
        return try await apiClient.post(path: "/legislators/\(id)/follow", body: nil as String?, requiresAuth: true)
    }

    func unfollowLegislator(id: String) async throws -> FollowResponse {
        return try await apiClient.delete(path: "/legislators/\(id)/follow", requiresAuth: true)
    }

    func getDonors(id: String, limit: Int = 50, offset: Int = 0, type: String? = nil) async throws -> DonorsResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }

        var components = URLComponents()
        components.queryItems = queryItems
        let queryString = components.percentEncodedQuery ?? ""
        let path = "/legislators/\(id)/donors" + (queryString.isEmpty ? "" : "?\(queryString)")

        return try await apiClient.get(path: path, requiresAuth: false)
    }

    func getVotes(id: String, limit: Int = 50, offset: Int = 0) async throws -> VotesResponse {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        let queryString = components.percentEncodedQuery ?? ""
        let path = "/legislators/\(id)/votes" + (queryString.isEmpty ? "" : "?\(queryString)")

        return try await apiClient.get(path: path, requiresAuth: false)
    }

    func getPressReleases(id: String, limit: Int = 50, offset: Int = 0) async throws -> PressResponse {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        let queryString = components.percentEncodedQuery ?? ""
        let path = "/legislators/\(id)/press" + (queryString.isEmpty ? "" : "?\(queryString)")

        return try await apiClient.get(path: path, requiresAuth: false)
    }
}

// MARK: - Error Types

enum LegislatorError: LocalizedError {
    case invalidURL
    case networkError
    case unauthorized
    case requestFailed(statusCode: Int)
    case alreadyFollowing

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error occurred"
        case .unauthorized:
            return "You must be logged in to perform this action"
        case .requestFailed(let statusCode):
            return "Request failed with status code: \(statusCode)"
        case .alreadyFollowing:
            return "You are already following this legislator"
        }
    }
}
