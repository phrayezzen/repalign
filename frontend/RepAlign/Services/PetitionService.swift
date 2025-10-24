import Foundation

class PetitionService {
    static let shared = PetitionService()
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Petition Models

    struct Petition: Codable, Identifiable {
        let id: String
        let title: String
        let description: String
        let category: String
        let targetSignatures: Int
        let currentSignatures: Int
        let progressPercentage: Double
        let status: String
        let deadline: Date?
        let daysRemaining: Int?
        let creatorId: String
        let creatorName: String
        let creatorAvatar: String?
        let createdAt: Date
        let updatedAt: Date
        let userHasSigned: Bool?
        let isFeatured: Bool?
    }

    struct PetitionListResponse: Codable {
        let items: [Petition]
        let total: Int
        let page: Int
        let limit: Int
        let hasMore: Bool
    }

    struct CreatePetitionRequest: Codable {
        let title: String
        let description: String
        let category: String
        let targetSignatures: Int
        let deadline: Date?
        let recipientLegislatorIds: [String]?
    }

    struct SignPetitionRequest: Codable {
        let comment: String?
        let isPublic: Bool
    }

    struct SignatureResponse: Codable {
        let message: String
        let currentSignatures: Int
    }

    // MARK: - API Methods

    func getPetitions(
        page: Int = 1,
        limit: Int = 20,
        search: String? = nil,
        status: String? = nil,
        category: String? = nil,
        mine: Bool = false,
        sortBy: String = "createdAt"
    ) async throws -> PetitionListResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }

        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        if mine {
            queryItems.append(URLQueryItem(name: "mine", value: "true"))
        }

        var components = URLComponents()
        components.queryItems = queryItems
        let queryString = components.percentEncodedQuery ?? ""
        let path = "/congress/petitions" + (queryString.isEmpty ? "" : "?\(queryString)")

        return try await apiClient.get(path: path, requiresAuth: false)
    }

    func getPetition(id: String) async throws -> Petition {
        return try await apiClient.get(path: "/congress/petitions/\(id)", requiresAuth: false)
    }

    func createPetition(petition: CreatePetitionRequest) async throws -> Petition {
        return try await apiClient.post(path: "/congress/petitions", body: petition, requiresAuth: true)
    }

    func signPetition(id: String, comment: String? = nil, isPublic: Bool = true) async throws -> SignatureResponse {
        let body = SignPetitionRequest(comment: comment, isPublic: isPublic)
        return try await apiClient.post(path: "/congress/petitions/\(id)/sign", body: body, requiresAuth: true)
    }

    func unsignPetition(id: String) async throws -> SignatureResponse {
        return try await apiClient.delete(path: "/congress/petitions/\(id)/sign", requiresAuth: true)
    }
}

// MARK: - Error Types

enum PetitionError: LocalizedError {
    case invalidURL
    case networkError
    case unauthorized
    case requestFailed(statusCode: Int)
    case alreadySigned

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
        case .alreadySigned:
            return "You have already signed this petition"
        }
    }
}
