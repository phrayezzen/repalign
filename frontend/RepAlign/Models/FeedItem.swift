import Foundation

enum FeedItemType: String, Codable, CaseIterable {
    case post = "post"
    case event = "event"
    case petition = "petition"
}

struct FeedItem: Codable, Identifiable {
    let id: String
    let type: FeedItemType
    let title: String?
    let content: String
    let authorId: String
    let authorName: String
    let authorAvatar: String?
    let createdAt: Date

    // Event-specific fields
    let eventDate: Date?
    let eventLocation: String?
    let eventType: String?
    let eventEndDate: Date?
    let eventAddress: String?
    let eventDuration: String?
    let eventFormat: String?
    let eventNote: String?
    let eventDetailedDescription: String?
    let organizerFollowers: Int?
    let organizerEventsCount: Int?
    let organizerYearsActive: Int?
    let heroImageUrl: String?

    // Petition-specific fields
    let petitionSignatures: Int?
    let petitionTargetSignatures: Int?
    let petitionDeadline: Date?
    let petitionCategory: String?

    // Post-specific fields
    let postType: String?
    let imageUrl: String?
    let attachmentUrls: [String]?
    let tags: [String]?

    // Engagement metrics
    let likeCount: Int?
    let commentCount: Int?
    let shareCount: Int?

    // Computed properties for easier use
    var displayTitle: String {
        title ?? (type == .post ? "Post" : "Update")
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var formattedEngagement: String {
        let likes = likeCount ?? 0
        let comments = commentCount ?? 0
        let shares = shareCount ?? 0

        var parts: [String] = []
        if likes > 0 { parts.append("\(likes) likes") }
        if comments > 0 { parts.append("\(comments) comments") }
        if shares > 0 { parts.append("\(shares) shares") }

        return parts.joined(separator: " • ")
    }
}

struct FeedResponse: Codable {
    let items: [FeedItem]
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool
}