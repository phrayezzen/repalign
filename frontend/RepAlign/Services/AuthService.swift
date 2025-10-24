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
    let expiresIn: Int?  // Optional - backend may include this

    enum CodingKeys: String, CodingKey {
        case accessToken, refreshToken, user, expiresIn
    }
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

    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
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

        let loginRequest = LoginRequest(usernameOrEmail: usernameOrEmail, password: password)

        do {
            let authResponse: AuthResponse = try await apiClient.request(
                path: "/auth/login",
                method: .post,
                body: loginRequest,
                additionalHeaders: ["ngrok-skip-browser-warning": "1"]
            )

            try KeychainManager.shared.saveAccessToken(authResponse.accessToken)
            try KeychainManager.shared.saveRefreshToken(authResponse.refreshToken)

            currentUser = authResponse.user
            isAuthenticated = true

        } catch let error as APIClientError {
            if case .httpError(let statusCode, _) = error, statusCode == 401 {
                throw AuthError.invalidCredentials
            }
            throw AuthError.networkError
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

        let registerRequest = RegisterRequest(
            username: username,
            email: email,
            password: password,
            displayName: displayName
        )

        do {
            let authResponse: AuthResponse = try await apiClient.request(
                path: "/auth/register",
                method: .post,
                body: registerRequest,
                additionalHeaders: ["ngrok-skip-browser-warning": "1"]
            )

            try KeychainManager.shared.saveAccessToken(authResponse.accessToken)
            try KeychainManager.shared.saveRefreshToken(authResponse.refreshToken)

            currentUser = authResponse.user
            isAuthenticated = true

        } catch let error as APIClientError {
            if case .httpError(let statusCode, _) = error, statusCode == 409 {
                throw AuthError.userExists
            }
            throw AuthError.networkError
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
        // Fire and forget - don't wait for response
        try? await apiClient.post(path: "/auth/logout", requiresAuth: true)
    }

    private func fetchCurrentUser() async {
        guard authToken != nil else {
            await MainActor.run {
                logout()
            }
            return
        }

        do {
            let user: UserProfile = try await apiClient.get(path: "/auth/profile", requiresAuth: true)

            await MainActor.run {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            print("❌ Failed to fetch current user: \(error)")
            if let apiError = error as? APIClientError {
                print("❌ API Error: \(apiError.errorDescription ?? "Unknown")")
            }
            await MainActor.run {
                logout()
            }
        }
    }

    func refreshAuthToken() async throws {
        guard let refreshToken = refreshToken else {
            throw AuthError.tokenExpired
        }

        struct RefreshTokenRequest: Codable {
            let refreshToken: String
        }

        do {
            let requestBody = RefreshTokenRequest(refreshToken: refreshToken)
            let authResponse: AuthResponse = try await apiClient.post(
                path: "/auth/refresh",
                body: requestBody
            )

            try KeychainManager.shared.saveAccessToken(authResponse.accessToken)
            try KeychainManager.shared.saveRefreshToken(authResponse.refreshToken)
        } catch {
            await MainActor.run {
                logout()
            }
            throw AuthError.tokenExpired
        }
    }

    // MARK: - Onboarding Methods

    @MainActor
    func updateUserType(userType: String) async throws {
        struct UserTypeRequest: Codable {
            let userType: String
        }

        do {
            let requestBody = UserTypeRequest(userType: userType)
            let _: EmptyResponse = try await apiClient.request(
                path: "/users/me/onboarding/user-type",
                method: .patch,
                body: requestBody,
                requiresAuth: true
            )
        } catch {
            throw AuthError.networkError
        }
    }

    private struct EmptyResponse: Codable {}

    @MainActor
    func updateLocation(state: String, congressionalDistrict: String?, city: String) async throws {
        struct LocationRequest: Codable {
            let state: String
            let city: String
            let congressionalDistrict: String?
        }

        do {
            let requestBody = LocationRequest(
                state: state,
                city: city,
                congressionalDistrict: congressionalDistrict
            )
            let _: EmptyResponse = try await apiClient.request(
                path: "/users/me/onboarding/location",
                method: .patch,
                body: requestBody,
                requiresAuth: true
            )
        } catch {
            throw AuthError.networkError
        }
    }

    @MainActor
    func updateInterests(causes: [String]) async throws {
        struct InterestsRequest: Codable {
            let causes: [String]
        }

        do {
            let requestBody = InterestsRequest(causes: causes)
            let _: EmptyResponse = try await apiClient.request(
                path: "/users/me/onboarding/interests",
                method: .patch,
                body: requestBody,
                requiresAuth: true
            )
        } catch {
            throw AuthError.networkError
        }
    }

    @MainActor
    func completeOnboarding() async throws {
        do {
            try await apiClient.post(path: "/users/me/onboarding/complete", requiresAuth: true)

            // Refresh user profile after completing onboarding
            await fetchCurrentUser()
        } catch {
            throw AuthError.networkError
        }
    }
}