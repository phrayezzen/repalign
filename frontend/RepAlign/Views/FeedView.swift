import SwiftUI
import SwiftData

struct FeedView: View {
    @Query(sort: \Post.timestamp, order: .reverse) private var posts: [Post]
    @Query private var users: [User]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(posts) { post in
                        if let author = users.first(where: { $0.id == post.authorId }) {
                            PostCardView(post: post, author: author)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("RepAlign")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct PostCardView: View {
    let post: Post
    let author: User
    @State private var isLiked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            Text(post.content)
                .font(.body)
                .lineLimit(nil)

            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.tags, id: \.self) { tag in
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

            engagementBar
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ProfileAvatarView(user: author, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(author.displayName)
                        .font(.headline)
                        .fontWeight(.medium)

                    if author.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }

                Text(timeAgo(from: post.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var engagementBar: some View {
        HStack(spacing: 20) {
            Button(action: { isLiked.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .secondary)

                    Text("\(post.likeCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .foregroundColor(.secondary)

                    Text("\(post.commentCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .foregroundColor(.secondary)

                    Text("\(post.shareCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Post.self, configurations: config)

    let users = MockDataProvider.createMockUsers()
    let posts = MockDataProvider.createMockPosts()

    for user in users {
        container.mainContext.insert(user)
    }
    for post in posts {
        container.mainContext.insert(post)
    }

    return FeedView()
        .modelContainer(container)
}