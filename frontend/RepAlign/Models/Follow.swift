import Foundation
import SwiftData

@Model
final class Follow {
    var id: String
    var followerId: String
    var followingId: String
    var timestamp: Date

    var follower: User?
    var following: User?

    init(
        id: String = UUID().uuidString,
        followerId: String,
        followingId: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.followerId = followerId
        self.followingId = followingId
        self.timestamp = timestamp
    }
}