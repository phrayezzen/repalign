import Foundation
import SwiftData

enum BadgeType: String, CaseIterable, Codable {
    case civicConnector = "civic_connector"
    case activist = "activist"
    case firstPost = "first_post"
    case socialButterfly = "social_butterfly"
    case thoughtLeader = "thought_leader"
}

@Model
final class CitizenProfile {
    var userId: String
    var civicEngagementScore: Int
    var level: Int
    var badges: [BadgeType]
    var isCivicConnector: Bool

    var user: User?

    init(
        userId: String,
        civicEngagementScore: Int = 0,
        badges: [BadgeType] = [],
        isCivicConnector: Bool = false
    ) {
        self.userId = userId
        self.civicEngagementScore = civicEngagementScore
        self.level = Self.calculateLevel(from: civicEngagementScore)
        self.badges = badges
        self.isCivicConnector = isCivicConnector
    }

    static func calculateLevel(from score: Int) -> Int {
        return min(max(1, (score / 500) + 1), 10)
    }

    var nextLevelPoints: Int {
        let nextLevel = min(level + 1, 10)
        return nextLevel * 500 - civicEngagementScore
    }
}