import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum APIClientError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please log in again"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession

    private var authToken: String? {
        KeychainManager.shared.getAccessToken()
    }

    private init() {
        self.baseURL = AppConfig.shared.backendBaseURL

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Generic Request Methods

    func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = false,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        let data = try await requestData(
            path: path,
            method: method,
            body: body,
            requiresAuth: requiresAuth,
            additionalHeaders: additionalHeaders
        )

        do {
            let decoder = JSONDecoder()
            // Backend sends camelCase, so no conversion needed
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decoding error for \(T.self): \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Failed to decode this data: \(responseString)")
            }
            throw APIClientError.decodingError(error)
        }
    }

    func requestData(
        path: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = false,
        additionalHeaders: [String: String] = [:]
    ) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add ngrok header to bypass browser warning (required for ngrok tunnels)
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")

        // Add authentication if required or if token is available
        if requiresAuth || authToken != nil {
            if let token = authToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else if requiresAuth {
                throw APIClientError.unauthorized
            }
        }

        // Add additional headers
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Encode body if provided
        if let body = body {
            do {
                let encoder = JSONEncoder()
                // Don't convert to snake_case - backend expects camelCase
                request.httpBody = try encoder.encode(body)
            } catch {
                throw APIClientError.encodingError(error)
            }
        }

        // Perform request
        do {
            print("🔵 APIClient: Starting \(method.rawValue) request to: \(url.absoluteString)")
            print("🔵 Headers: \(request.allHTTPHeaderFields ?? [:])")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ APIClient: Invalid response for \(path)")
                throw APIClientError.invalidResponse
            }

            // Log response for debugging - ALWAYS log response body
            print("📡 APIClient: \(method.rawValue) \(path) -> \(httpResponse.statusCode)")
            print("📡 Response headers: \(httpResponse.allHeaderFields)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📡 Response body (\(data.count) bytes): \(responseString.prefix(500))...")
            }

            // Check status code
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw APIClientError.unauthorized
            default:
                throw APIClientError.httpError(statusCode: httpResponse.statusCode, data: data)
            }
        } catch let error as APIClientError {
            throw error
        } catch {
            print("❌ APIClient network error for \(path): \(error.localizedDescription)")
            throw APIClientError.networkError(error)
        }
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(
        path: String,
        requiresAuth: Bool = false
    ) async throws -> T {
        try await request(path: path, method: .get, requiresAuth: requiresAuth)
    }

    func post<T: Decodable>(
        path: String,
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        try await request(path: path, method: .post, body: body, requiresAuth: requiresAuth)
    }

    func post(
        path: String,
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws {
        _ = try await requestData(path: path, method: .post, body: body, requiresAuth: requiresAuth)
    }

    func put<T: Decodable>(
        path: String,
        body: Encodable? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        try await request(path: path, method: .put, body: body, requiresAuth: requiresAuth)
    }

    func delete(
        path: String,
        requiresAuth: Bool = false
    ) async throws {
        _ = try await requestData(path: path, method: .delete, requiresAuth: requiresAuth)
    }

    func delete<T: Decodable>(
        path: String,
        requiresAuth: Bool = false
    ) async throws -> T {
        try await request(path: path, method: .delete, requiresAuth: requiresAuth)
    }
}
