import Foundation
import SwiftData

enum UserType: String, CaseIterable, Codable {
    case citizen = "citizen"
    case legislator = "legislator"
}

@Model
final class User {
    var id: String
    var username: String
    var displayName: String
    var bio: String?
    var profileImageURL: String?
    var location: String
    var postsCount: Int
    var followersCount: Int
    var followingCount: Int
    var userType: UserType
    var isVerified: Bool
    var joinDate: Date
    var lastActive: Date

    init(
        id: String = UUID().uuidString,
        username: String,
        displayName: String,
        bio: String? = nil,
        profileImageURL: String? = nil,
        location: String,
        postsCount: Int = 0,
        followersCount: Int = 0,
        followingCount: Int = 0,
        userType: UserType,
        isVerified: Bool = false,
        joinDate: Date = Date(),
        lastActive: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.location = location
        self.postsCount = postsCount
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.userType = userType
        self.isVerified = isVerified
        self.joinDate = joinDate
        self.lastActive = lastActive
    }
}