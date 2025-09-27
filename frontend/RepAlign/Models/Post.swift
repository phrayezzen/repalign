import Foundation
import SwiftData

@Model
final class Post {
    var id: String
    var authorId: String
    var content: String
    var timestamp: Date
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    var tags: [String]
    var attachmentURLs: [String]

    var author: User?

    init(
        id: String = UUID().uuidString,
        authorId: String,
        content: String,
        timestamp: Date = Date(),
        likeCount: Int = 0,
        commentCount: Int = 0,
        shareCount: Int = 0,
        tags: [String] = [],
        attachmentURLs: [String] = []
    ) {
        self.id = id
        self.authorId = authorId
        self.content = content
        self.timestamp = timestamp
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.shareCount = shareCount
        self.tags = tags
        self.attachmentURLs = attachmentURLs
    }

    var engagementCount: Int {
        return likeCount + commentCount + shareCount
    }
}