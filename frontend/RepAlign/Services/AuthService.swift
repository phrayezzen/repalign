import Foundation
import Combine

struct LoginRequest: Codable {
    let usernameOrEmail: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let displayName: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserProfile
}

struct UserProfile: Codable {
    let id: String
    let username: String
    let email: String
    let displayName: String
    let userType: String
    let profileImageUrl: String?
    let isVerified: Bool
    let onboardingCompleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, username, email, displayName, userType, profileImageUrl, isVerified, onboardingCompleted
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userExists
    case networkError
    case invalidResponse
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userExists:
            return "User already exists"
        case .networkError:
            return "Network connection error"
        case .invalidResponse:
            return "Invalid server response"
        case .tokenExpired:
            return "Session expired, please login again"
        }
    }
}

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false

    private let baseURL: String
    private var cancellables = Set<AnyCancellable>()

    private var authBaseURL: String {
        "\(baseURL)/auth"
    }

    private var onboardingBaseURL: String {
        "\(baseURL)/users/me/onboarding"
    }

    private init() {
        self.baseURL = AppConfig.shared.backendBaseURL
        checkAuthenticationStatus()
    }

    var authToken: String? {
        KeychainManager.shared.getAccessToken()
    }

    private var refreshToken: String? {
        KeychainManager.shared.getRefreshToken()
    }

    func checkAuthenticationStatus() {
        if let token = authToken {
            Task {
                await fetchCurrentUser()
            }
        }
    }

    @MainActor
    func login(usernameOrEmail: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(authBaseURL)/login") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginRequest = LoginRequest(usernameOrEmail: usernameOrEmail, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }

            if httpResponse.statusCode == 401 {
                throw AuthError.invalidCredentials
            }

            guard httpResponse.statusCode == 200 else {
                throw AuthError.invalidResponse
            }

            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

            try KeychainManager.shared.saveAccessToken(authResponse.accessToken)
            try KeychainManager.shared.saveRefreshToken(authResponse.refreshToken)

            currentUser = authResponse.user
            isAuthenticated = true

        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }

    @MainActor
    func register(username: String, email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "\(authBaseURL)/register") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let registerRequest = RegisterRequest(
            username: username,
            email: email,
            password: password,
            displayName: displayName
        )
        request.httpBody = try JSONEncoder().encode(registerRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.networkError
            }

            if httpResponse.statusCode == 409 {
                throw AuthError.userExists
            }

            guard httpResponse.statusCode == 201 else {
                throw AuthError.invalidResponse
            }

            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

            try KeychainManager.shared.saveAccessToken(authResponse.accessToken)
            try KeychainManager.shared.saveRefreshToken(authResponse.refreshToken)

            currentUser = authResponse.user
            isAuthenticated = true

        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError
        }
    }

    @MainActor
    func logout() {
        // Call backend logout endpoint if we have a token
        if let token = authToken {
            Task {
                await callLogoutEndpoint(token: token)
            }
        }

        // Clear tokens from Keychain
        KeychainManager.shared.deleteTokens()
        currentUser = nil
        isAuthenticated = false
    }

    private func callLogoutEndpoint(token: String) async {
        guard let url = URL(string: "\(authBaseURL)/logout") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Fire and forget - don't wait for response
        _ = try? await URLSession.shared.data(for: request)
    }

    private func fetchCurrentUser() async {
        guard let token = authToken,
              let url = URL(string: "\(authBaseURL)/profile") else {
            await MainActor.run {
                logout()
            }
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    logout()
                }
                return
            }

            let user = try JSONDecoder().decode(UserProfile.self, from: data)

            await MainActor.run {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                logout()
            }
        }
    }

    func refreshAuthToken() async throws {
        guard let refreshToken = refreshToken,
              let url = URL(string: "\(authBaseURL)/refresh") else {
            throw AuthError.tokenExpired
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Send refresh token in body, not header
        let body = ["refreshToken": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            await MainActor.run {
                logout()
            }
            throw AuthError.tokenExpired
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        try KeychainManager.shared.saveAccessToken(authResponse.accessToken)
        try KeychainManager.shared.saveRefreshToken(authResponse.refreshToken)
    }

    // MARK: - Onboarding Methods

    @MainActor
    func updateUserType(userType: String) async throws {
        guard let token = authToken,
              let url = URL(string: "\(onboardingBaseURL)/user-type") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = ["userType": userType]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.networkError
        }
    }

    @MainActor
    func updateLocation(state: String, congressionalDistrict: String?, city: String) async throws {
        guard let token = authToken,
              let url = URL(string: "\(onboardingBaseURL)/location") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "state": state,
            "city": city
        ]
        if let district = congressionalDistrict {
            body["congressionalDistrict"] = district
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.networkError
        }
    }

    @MainActor
    func updateInterests(causes: [String]) async throws {
        guard let token = authToken,
              let url = URL(string: "\(onboardingBaseURL)/interests") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = ["causes": causes]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.networkError
        }
    }

    @MainActor
    func completeOnboarding() async throws {
        guard let token = authToken,
              let url = URL(string: "\(onboardingBaseURL)/complete") else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.networkError
        }

        // Refresh user profile after completing onboarding
        await fetchCurrentUser()
    }
}