import Foundation

enum DataSourceType {
    case congressAPI
    case customBackend
    case mockData
}

enum BackendEnvironment: String, CaseIterable {
    case railway = "Railway (Production)"
    case ngrok = "ngrok (Development)"
    case local = "Local Development"

    var baseURL: String {
        switch self {
        case .railway:
            return "https://repalign-production.up.railway.app/api/v1"
        case .ngrok:
            return "https://cb8d68003a08.ngrok-free.app/api/v1"
        case .local:
            return "http://localhost:3000/api/v1"
        }
    }
}

class AppConfig {
    static let shared = AppConfig()

    let dataSource: DataSourceType = .customBackend

    // Congress API Configuration
    let congressAPIKey = "sPpMK7CUh5I47bsZYt6rNI5i9K8adkRAvxpjsreE" // TODO: Replace with actual key
    let congressAPIBaseURL = "https://api.congress.gov/v3"
    let currentCongress = 118

    // Backend Configuration
    private let backendEnvironmentKey = "selectedBackendEnvironment"

    var backendEnvironment: BackendEnvironment {
        get {
            if let savedValue = UserDefaults.standard.string(forKey: backendEnvironmentKey),
               let environment = BackendEnvironment(rawValue: savedValue) {
                return environment
            }
            return .ngrok // Default to ngrok for now
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: backendEnvironmentKey)
        }
    }

    var backendBaseURL: String {
        return backendEnvironment.baseURL
    }

    // Caching Configuration
    let cacheRefreshInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    // API Rate Limiting
    let apiRateLimit = 5000 // requests per hour
    let apiRequestDelay: TimeInterval = 0.1 // delay between requests

    private init() {}
}
