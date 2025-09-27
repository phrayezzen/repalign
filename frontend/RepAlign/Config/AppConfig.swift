import Foundation

enum DataSourceType {
    case congressAPI
    case customBackend
    case mockData
}

struct AppConfig {
    static let dataSource: DataSourceType = .mockData

    // Congress API Configuration
    static let congressAPIKey = "sPpMK7CUh5I47bsZYt6rNI5i9K8adkRAvxpjsreE" // TODO: Replace with actual key
    static let congressAPIBaseURL = "https://api.congress.gov/v3"
    static let currentCongress = 118

    // Backend Configuration
    static let backendBaseURL = "http://localhost:3000/api/v1"

    // Caching Configuration
    static let cacheRefreshInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    static let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    // API Rate Limiting
    static let apiRateLimit = 5000 // requests per hour
    static let apiRequestDelay: TimeInterval = 0.1 // delay between requests
}