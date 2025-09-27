import Foundation
import SwiftData

@Observable
class CurrentUserManager {
    static let shared = CurrentUserManager()

    var currentUserId: String = "john_doe"

    private init() {}

    func getCurrentUser(from users: [User]) -> User? {
        return users.first { $0.id == currentUserId }
    }

    func getCurrentCitizenProfile(from profiles: [CitizenProfile]) -> CitizenProfile? {
        return profiles.first { $0.userId == currentUserId }
    }

    func getCurrentLegislatorProfile(from profiles: [LegislatorProfile]) -> LegislatorProfile? {
        return profiles.first { $0.userId == currentUserId }
    }
}