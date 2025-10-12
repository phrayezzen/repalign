import Foundation

enum DataSourceType {
    case congressAPI
    case customBackend
    case mockData
}

struct AppConfig {
    static let shared = AppConfig()

    let dataSource: DataSourceType = .customBackend

    // Congress API Configuration
    let congressAPIKey = "sPpMK7CUh5I47bsZYt6rNI5i9K8adkRAvxpjsreE" // TODO: Replace with actual key
    let congressAPIBaseURL = "https://api.congress.gov/v3"
    let currentCongress = 118

    // Backend Configuration
    let backendBaseURL = "http://localhost:3000/api/v1"

    // Caching Configuration
    let cacheRefreshInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    // API Rate Limiting
    let apiRateLimit = 5000 // requests per hour
    let apiRequestDelay: TimeInterval = 0.1 // delay between requests

    private init() {}
}