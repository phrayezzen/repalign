import Foundation

class UserService {
    static let shared = UserService()
    private let apiClient = APIClient.shared

    private init() {}

    func followUser(userId: String) async throws {
        try await apiClient.post(path: "/users/\(userId)/follow", requiresAuth: true)
    }

    func unfollowUser(userId: String) async throws {
        try await apiClient.delete(path: "/users/\(userId)/follow", requiresAuth: true)
    }

    func getFollowerCount(userId: String) async throws -> Int {
        let result: FollowerCountResponse = try await apiClient.get(path: "/users/\(userId)/followers")
        return result.count
    }

    func isFollowing(userId: String, targetUserId: String) async throws -> Bool {
        let result: FollowingStatusResponse = try await apiClient.get(path: "/users/\(userId)/following/\(targetUserId)")
        return result.isFollowing
    }
}

struct FollowerCountResponse: Codable {
    let count: Int
}

struct FollowingStatusResponse: Codable {
    let isFollowing: Bool
}

enum UserError: Error {
    case invalidURL
    case followFailed
    case unfollowFailed
    case networkError
}