import Foundation

protocol FeedDataSource {
    func fetchFeed(page: Int, limit: Int, search: String?) async throws -> FeedResponse
}

class BackendFeedDataSource: FeedDataSource {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchFeed(page: Int = 1, limit: Int = 20, search: String? = nil) async throws -> FeedResponse {
        var path = "/feed?page=\(page)&limit=\(limit)"

        if let search = search, !search.isEmpty {
            path += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? search)"
        }

        do {
            return try await apiClient.get(path: path, requiresAuth: false)
        } catch let error as APIClientError {
            switch error {
            case .invalidURL:
                throw FeedError.invalidURL
            case .invalidResponse:
                throw FeedError.invalidResponse
            case .httpError(let statusCode, _):
                throw FeedError.serverError(statusCode)
            case .decodingError(let decodingError):
                throw FeedError.decodingError(decodingError)
            case .networkError(let networkError):
                throw FeedError.networkError(networkError)
            case .unauthorized:
                throw FeedError.serverError(401)
            default:
                throw FeedError.networkError(error)
            }
        }
    }
}

enum FeedError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}