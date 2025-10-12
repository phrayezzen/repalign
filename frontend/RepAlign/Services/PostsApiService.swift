import Foundation
import Combine

struct PostResponse: Codable {
    let id: String
    let authorId: String
    let content: String
    let likeCount: Int
    let commentCount: Int
    let shareCount: Int
    let createdAt: String
    let author: UserResponse?
    let comments: [CommentResponse]?
}

struct CommentResponse: Codable {
    let id: String
    let postId: String
    let authorId: String
    let content: String
    let likeCount: Int
    let createdAt: String
    let author: UserResponse?
}

struct UserResponse: Codable {
    let id: String
    let displayName: String
    let profileImageUrl: String?
}

struct CreateCommentRequest: Codable {
    let content: String
}

struct LikeStatusResponse: Codable {
    let isLiked: Bool
}

struct MessageResponse: Codable {
    let message: String
}

class PostsApiService: ObservableObject {
    static let shared = PostsApiService()

    private let baseURL = "http://localhost:3000/api/v1"
    private var authToken: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }

    private init() {}

    // MARK: - Post Methods

    func getPost(id: String) async throws -> PostResponse {
        guard let url = URL(string: "\(baseURL)/posts/\(id)") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(PostResponse.self, from: data)
    }

    func getPostComments(postId: String) async throws -> [CommentResponse] {
        guard let url = URL(string: "\(baseURL)/posts/\(postId)/comments") else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode([CommentResponse].self, from: data)
    }

    func createComment(postId: String, content: String) async throws -> CommentResponse {
        guard let url = URL(string: "\(baseURL)/posts/\(postId)/comments") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let requestBody = CreateCommentRequest(content: content)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(CommentResponse.self, from: data)
    }

    // MARK: - Like Methods

    func likePost(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/posts/\(id)/like") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }

    func unlikePost(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/posts/\(id)/like") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }

    func getPostLikeStatus(id: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/posts/\(id)/like-status") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let likeStatus = try JSONDecoder().decode(LikeStatusResponse.self, from: data)
        return likeStatus.isLiked
    }

    func likeComment(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/comments/\(id)/like") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }

    func unlikeComment(id: String) async throws {
        guard let url = URL(string: "\(baseURL)/comments/\(id)/like") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }

    func getCommentLikeStatus(id: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/comments/\(id)/like-status") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let likeStatus = try JSONDecoder().decode(LikeStatusResponse.self, from: data)
        return likeStatus.isLiked
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}