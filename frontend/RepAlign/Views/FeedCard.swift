import SwiftUI

struct FeedCard: View {
    let item: FeedItem

    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(alignment: .leading, spacing: 0) {
                // Type badge at top
                typeBadge

                // Main content
                VStack(alignment: .leading, spacing: 12) {
                    mainContent
                    bottomInfo
                    actionButton
                }
                .padding(16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var destinationView: some View {
        if item.type == .event {
            EventDetailView(event: item)
        } else {
            PostDetailView(post: item)
        }
    }

    private var typeBadge: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: item.type == .event ? "calendar" : (item.type == .petition ? "person.2" : "doc.text"))
                    .font(.caption)
                Text(item.type == .event ? "Events" : (item.type == .petition ? "Petitions" : "Posts"))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(16)
            .padding(.top, 16)
            .padding(.leading, 16)

            Spacer()
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image (if available)
            if let imageUrl = item.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                        )
                }
            }

            // Title (if available)
            if let title = item.title {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(3)
            }

            // Content description
            Text(item.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(4)
        }
    }

    private var bottomInfo: some View {
        HStack(spacing: 16) {
            // Author info
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.authorName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Date
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(item.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Share count (if available)
            if let shareCount = item.shareCount, shareCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(shareCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if item.type == .event {
            // For events, show RSVP button styling but make it part of the navigation
            Text("RSVP")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(8)
        } else {
            // For posts and petitions, show a visual button that doesn't block navigation
            Text("View Discussion")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(8)
        }
    }

}

struct EventDetailsView: View {
    let date: Date
    let location: String
    let eventType: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.green)
                Text(formatDate(date))
                    .font(.caption)
                    .fontWeight(.medium)
            }

            HStack(spacing: 8) {
                Image(systemName: "location")
                    .foregroundColor(.green)
                Text(location)
                    .font(.caption)
            }

            if let eventType = eventType {
                HStack(spacing: 8) {
                    Image(systemName: "tag")
                        .foregroundColor(.green)
                    Text(eventType)
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PetitionProgressView: View {
    let current: Int
    let target: Int
    let deadline: Date?

    private var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(current) of \(target) signatures")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))

            if let deadline = deadline {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text("Deadline: \(formatDeadline(deadline))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    private func formatDeadline(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct TagsView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FeedCard(item: FeedItem(
            id: "1",
            type: .post,
            title: nil,
            content: "This is a sample post content that would appear in the feed.",
            authorId: "author1",
            authorName: "John Doe",
            authorAvatar: nil,
            createdAt: Date(),
            eventDate: nil,
            eventLocation: nil,
            eventType: nil,
            eventEndDate: nil,
            eventAddress: nil,
            eventDuration: nil,
            eventFormat: nil,
            eventNote: nil,
            eventDetailedDescription: nil,
            organizerFollowers: nil,
            organizerEventsCount: nil,
            organizerYearsActive: nil,
            heroImageUrl: nil,
            petitionSignatures: nil,
            petitionTargetSignatures: nil,
            petitionDeadline: nil,
            petitionCategory: nil,
            postType: "update",
            imageUrl: nil,
            attachmentUrls: nil,
            tags: ["politics", "update"],
            likeCount: 42,
            commentCount: 8,
            shareCount: 3
        ))

        FeedCard(item: FeedItem(
            id: "2",
            type: .event,
            title: "Town Hall Meeting",
            content: "Join us for a community discussion about local infrastructure improvements.",
            authorId: "author2",
            authorName: "City Council",
            authorAvatar: nil,
            createdAt: Date(),
            eventDate: Date().addingTimeInterval(86400),
            eventLocation: "Community Center",
            eventType: "Town Hall",
            eventEndDate: nil,
            eventAddress: nil,
            eventDuration: nil,
            eventFormat: nil,
            eventNote: nil,
            eventDetailedDescription: nil,
            organizerFollowers: nil,
            organizerEventsCount: nil,
            organizerYearsActive: nil,
            heroImageUrl: nil,
            petitionSignatures: nil,
            petitionTargetSignatures: nil,
            petitionDeadline: nil,
            petitionCategory: nil,
            postType: nil,
            imageUrl: nil,
            attachmentUrls: nil,
            tags: nil,
            likeCount: nil,
            commentCount: nil,
            shareCount: nil
        ))
    }
    .padding()
}