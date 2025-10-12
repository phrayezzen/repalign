import Foundation

class UserService {
    static let shared = UserService()
    private let baseURL = "http://localhost:3000"

    private init() {}

    func followUser(userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/follow") else {
            throw UserError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // TODO: Add authentication token when available
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw UserError.followFailed
        }
    }

    func unfollowUser(userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/follow") else {
            throw UserError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        // TODO: Add authentication token when available
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UserError.unfollowFailed
        }
    }

    func getFollowerCount(userId: String) async throws -> Int {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/followers") else {
            throw UserError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UserError.networkError
        }

        let result = try JSONDecoder().decode(FollowerCountResponse.self, from: data)
        return result.count
    }

    func isFollowing(userId: String, targetUserId: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/users/\(userId)/following/\(targetUserId)") else {
            throw UserError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UserError.networkError
        }

        let result = try JSONDecoder().decode(FollowingStatusResponse.self, from: data)
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