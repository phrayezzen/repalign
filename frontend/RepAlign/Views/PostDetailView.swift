import SwiftUI

struct PostDetailView: View {
    let post: FeedItem
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var newCommentText = ""
    @State private var isLiked = false
    @State private var likeCount: Int
    @State private var commentCount: Int
    @State private var sortOption: CommentSortOption = .top
    @Environment(\.dismiss) private var dismiss
    @StateObject private var postsApiService = PostsApiService.shared

    init(post: FeedItem) {
        self.post = post
        self.likeCount = post.likeCount ?? 0
        self.commentCount = post.commentCount ?? 0
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Post Content
                ScrollView {
                    VStack(spacing: 0) {
                        postHeader
                        postContent
                        postActions
                        commentsSection
                    }
                }

                // Comment Input
                commentInputSection
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Share Post", action: sharePost)
                        Button("Report Post", action: reportPost)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .task {
            await loadComments()
            await loadLikeStatus()
        }
    }

    private func loadLikeStatus() async {
        do {
            let liked = try await postsApiService.getPostLikeStatus(id: post.id)
            await MainActor.run {
                self.isLiked = liked
            }
        } catch {
            print("Error loading like status: \(error)")
        }
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Author Avatar
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.authorName.prefix(1)))
                            .font(.headline)
                            .fontWeight(.medium)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(post.authorName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(timeAgoString)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let tags = post.tags, !tags.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)

                            Text(tags.first ?? "")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    HStack(spacing: 4) {
                        Text("\(commentCount) comments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Follow") {
                    // TODO: Implement follow functionality
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private var postContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = post.title {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
            }

            // Type Badge
            HStack {
                Text(post.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(post.type.color)
                    .cornerRadius(8)

                if let tags = post.tags, !tags.isEmpty {
                    Button(action: {}) {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Post Image (if available)
            if let imageUrl = post.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 250)
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 250)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                        )
                }
            }

            Text(post.content)
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)

            if post.type == .post {
                Button(action: {}) {
                    Text("Read more")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }

    private var postActions: some View {
        HStack(spacing: 24) {
            // Like Button
            Button(action: toggleLike) {
                HStack(spacing: 6) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .secondary)
                    Text("\(likeCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Dislike Button
            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.slash")
                        .foregroundColor(.secondary)
                    Text("23")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Comment Button
            Button(action: {}) {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.secondary)
                    Text("\(commentCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Share Button
            Button(action: sharePost) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                    Text("Share")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }

    private var commentsSection: some View {
        VStack(spacing: 0) {
            // Discussion Header with Sort Options
            HStack {
                Text("Discussion")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Menu {
                    Button("Top") { sortOption = .top }
                    Button("Newest") { sortOption = .newest }
                    Button("Oldest") { sortOption = .oldest }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOption.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))

            // Comments List
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading comments...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if comments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No comments yet")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Be the first to share your thoughts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(sortedComments) { comment in
                        CommentRowView(comment: comment)
                    }
                }
            }
        }
    }

    private var commentInputSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))

            HStack(spacing: 12) {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("YU")
                            .font(.caption)
                            .fontWeight(.medium)
                    )

                TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(1...4)

                Button(action: addComment) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(newCommentText.isEmpty ? .secondary : .red)
                }
                .disabled(newCommentText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }

    private var timeAgoString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }

    private var sortedComments: [Comment] {
        switch sortOption {
        case .top:
            return comments.sorted { $0.likeCount > $1.likeCount }
        case .newest:
            return comments.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            return comments.sorted { $0.createdAt < $1.createdAt }
        }
    }

    private func toggleLike() {
        Task {
            do {
                if isLiked {
                    try await postsApiService.unlikePost(id: post.id)
                    await MainActor.run {
                        isLiked = false
                        likeCount = max(0, likeCount - 1)
                    }
                } else {
                    try await postsApiService.likePost(id: post.id)
                    await MainActor.run {
                        isLiked = true
                        likeCount += 1
                    }
                }
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }

    private func sharePost() {
        // TODO: Implement share functionality
    }

    private func reportPost() {
        // TODO: Implement report functionality
    }

    private func addComment() {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let content = newCommentText
        newCommentText = ""

        Task {
            do {
                let commentResponse = try await postsApiService.createComment(postId: post.id, content: content)

                await MainActor.run {
                    let newComment = Comment(
                        id: commentResponse.id,
                        postId: commentResponse.postId,
                        authorId: commentResponse.authorId,
                        authorName: commentResponse.author?.displayName ?? "Unknown User",
                        content: commentResponse.content,
                        createdAt: ISO8601DateFormatter().date(from: commentResponse.createdAt) ?? Date(),
                        likeCount: commentResponse.likeCount,
                        replyCount: 0
                    )

                    comments.append(newComment)
                    commentCount += 1
                }
            } catch {
                print("Error adding comment: \(error)")
                await MainActor.run {
                    newCommentText = content // Restore the text if there was an error
                }
            }
        }
    }

    private func loadComments() async {
        isLoading = true

        do {
            let commentsResponse = try await postsApiService.getPostComments(postId: post.id)

            await MainActor.run {
                self.comments = commentsResponse.map { commentResponse in
                    Comment(
                        id: commentResponse.id,
                        postId: commentResponse.postId,
                        authorId: commentResponse.authorId,
                        authorName: commentResponse.author?.displayName ?? "Unknown User",
                        content: commentResponse.content,
                        createdAt: ISO8601DateFormatter().date(from: commentResponse.createdAt) ?? Date(),
                        likeCount: commentResponse.likeCount,
                        replyCount: 0
                    )
                }
                self.isLoading = false
            }
        } catch {
            print("Error loading comments: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct CommentRowView: View {
    let comment: Comment
    @State private var isLiked = false
    @State private var showReplies = false
    @State private var likeCount: Int
    @StateObject private var postsApiService = PostsApiService.shared

    init(comment: Comment) {
        self.comment = comment
        self.likeCount = comment.likeCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(comment.authorName.prefix(2)))
                            .font(.caption)
                            .fontWeight(.medium)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    // Author and timestamp
                    HStack(spacing: 8) {
                        Text(comment.authorName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.caption)

                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Comment content
                    Text(comment.content)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)

                    // Comment actions
                    HStack(spacing: 16) {
                        Button(action: toggleCommentLike) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.caption)
                                    .foregroundColor(isLiked ? .red : .secondary)
                                Text("\(likeCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.slash")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("4")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button("Reply") {
                            // TODO: Implement reply functionality
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Button("Share") {
                            // TODO: Implement share functionality
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Divider
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray6))
        }
        .background(Color(.systemBackground))
        .task {
            await loadCommentLikeStatus()
        }
    }

    private func toggleCommentLike() {
        Task {
            do {
                if isLiked {
                    try await postsApiService.unlikeComment(id: comment.id)
                    await MainActor.run {
                        isLiked = false
                        likeCount = max(0, likeCount - 1)
                    }
                } else {
                    try await postsApiService.likeComment(id: comment.id)
                    await MainActor.run {
                        isLiked = true
                        likeCount += 1
                    }
                }
            } catch {
                print("Error toggling comment like: \(error)")
            }
        }
    }

    private func loadCommentLikeStatus() async {
        do {
            let liked = try await postsApiService.getCommentLikeStatus(id: comment.id)
            await MainActor.run {
                self.isLiked = liked
            }
        } catch {
            print("Error loading comment like status: \(error)")
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }
}

struct Comment: Identifiable {
    let id: String
    let postId: String
    let authorId: String
    let authorName: String
    let content: String
    let createdAt: Date
    let likeCount: Int
    let replyCount: Int
}

enum CommentSortOption: String, CaseIterable {
    case top = "Top"
    case newest = "Newest"
    case oldest = "Oldest"
}

extension FeedItemType {
    var color: Color {
        switch self {
        case .post:
            return .blue
        case .event:
            return .green
        case .petition:
            return .orange
        }
    }

    var displayName: String {
        switch self {
        case .post:
            return "Voting Rights"
        case .event:
            return "Event"
        case .petition:
            return "Petition"
        }
    }
}

#Preview {
    PostDetailView(post: FeedItem(
        id: "1",
        type: .post,
        title: "Should states be required to adopt automatic voter registration?",
        content: "Several states have already implemented automatic voter registration when citizens interact with the DMV or other state agencies. Supporters argue it significantly increases voter turnout and reduces registration errors, while opponents raise concerns about privacy, security, and potential for outdated databases.",
        authorId: "sarah-chen",
        authorName: "Sarah Chen",
        authorAvatar: nil,
        createdAt: Date().addingTimeInterval(-10800),
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
        postType: nil,
        imageUrl: nil,
        attachmentUrls: nil,
        tags: ["Voting Rights"],
        likeCount: 89,
        commentCount: 47,
        shareCount: 12
    ))
}