import Foundation

protocol FeedDataSource {
    func fetchFeed(page: Int, limit: Int, search: String?) async throws -> FeedResponse
}

class BackendFeedDataSource: FeedDataSource {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = AppConfig.shared.backendBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchFeed(page: Int = 1, limit: Int = 20, search: String? = nil) async throws -> FeedResponse {
        var components = URLComponents(string: "\(baseURL)/feed")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let search = search, !search.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "search", value: search))
        }

        guard let url = components.url else {
            throw FeedError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FeedError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FeedError.serverError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try decoder.decode(FeedResponse.self, from: data)
        } catch {
            if error is FeedError {
                throw error
            } else {
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