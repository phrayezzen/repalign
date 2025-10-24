import Foundation

class PetitionService {
    static let shared = PetitionService()
    private let baseURL: String

    private init() {
        self.baseURL = AppConfig.shared.backendBaseURL
    }

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
        var components = URLComponents(string: "\(baseURL)/congress/petitions")!

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

        components.queryItems = queryItems

        guard let url = components.url else {
            throw PetitionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add auth token if available
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PetitionError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw PetitionError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(PetitionListResponse.self, from: data)
    }

    func getPetition(id: String) async throws -> Petition {
        guard let url = URL(string: "\(baseURL)/congress/petitions/\(id)") else {
            throw PetitionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add auth token if available
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PetitionError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw PetitionError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(Petition.self, from: data)
    }

    func createPetition(petition: CreatePetitionRequest) async throws -> Petition {
        guard let url = URL(string: "\(baseURL)/congress/petitions") else {
            throw PetitionError.invalidURL
        }

        guard let token = AuthService.shared.authToken else {
            throw PetitionError.unauthorized
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(petition)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PetitionError.networkError
        }

        guard httpResponse.statusCode == 201 else {
            throw PetitionError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(Petition.self, from: data)
    }

    func signPetition(id: String, comment: String? = nil, isPublic: Bool = true) async throws -> SignatureResponse {
        guard let url = URL(string: "\(baseURL)/congress/petitions/\(id)/sign") else {
            throw PetitionError.invalidURL
        }

        guard let token = AuthService.shared.authToken else {
            throw PetitionError.unauthorized
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = SignPetitionRequest(comment: comment, isPublic: isPublic)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PetitionError.networkError
        }

        guard httpResponse.statusCode == 201 else {
            if httpResponse.statusCode == 409 {
                throw PetitionError.alreadySigned
            }
            throw PetitionError.requestFailed(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(SignatureResponse.self, from: data)
    }

    func unsignPetition(id: String) async throws -> SignatureResponse {
        guard let url = URL(string: "\(baseURL)/congress/petitions/\(id)/sign") else {
            throw PetitionError.invalidURL
        }

        guard let token = AuthService.shared.authToken else {
            throw PetitionError.unauthorized
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PetitionError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            throw PetitionError.requestFailed(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(SignatureResponse.self, from: data)
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
