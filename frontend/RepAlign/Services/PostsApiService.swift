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
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Post Methods

    func getPost(id: String) async throws -> PostResponse {
        try await apiClient.get(path: "/posts/\(id)")
    }

    func getPostComments(postId: String) async throws -> [CommentResponse] {
        try await apiClient.get(path: "/posts/\(postId)/comments")
    }

    func createComment(postId: String, content: String) async throws -> CommentResponse {
        let requestBody = CreateCommentRequest(content: content)
        return try await apiClient.post(path: "/posts/\(postId)/comments", body: requestBody, requiresAuth: true)
    }

    // MARK: - Like Methods

    func likePost(id: String) async throws {
        try await apiClient.post(path: "/posts/\(id)/like", requiresAuth: true)
    }

    func unlikePost(id: String) async throws {
        try await apiClient.delete(path: "/posts/\(id)/like", requiresAuth: true)
    }

    func getPostLikeStatus(id: String) async throws -> Bool {
        let likeStatus: LikeStatusResponse = try await apiClient.get(path: "/posts/\(id)/like-status", requiresAuth: true)
        return likeStatus.isLiked
    }

    func likeComment(id: String) async throws {
        try await apiClient.post(path: "/comments/\(id)/like", requiresAuth: true)
    }

    func unlikeComment(id: String) async throws {
        try await apiClient.delete(path: "/comments/\(id)/like", requiresAuth: true)
    }

    func getCommentLikeStatus(id: String) async throws -> Bool {
        let likeStatus: LikeStatusResponse = try await apiClient.get(path: "/comments/\(id)/like-status", requiresAuth: true)
        return likeStatus.isLiked
    }
}