import SwiftUI

struct EventDetailView: View {
    let event: FeedItem
    @State private var isFollowing = false
    @State private var hasRSVPed = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EventHeroSection(
                    event: event,
                    hasRSVPed: $hasRSVPed,
                    isLoading: $isLoading,
                    handleRSVP: handleRSVP
                )

                VStack(spacing: 16) {
                    EventDetailsSection(event: event, isFollowing: $isFollowing, handleFollow: handleFollow)
                    OrganizerSection(event: event, isFollowing: $isFollowing, handleFollow: handleFollow)
                }
                .padding(.top, 16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(.container, edges: .top)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    private func handleRSVP() async {
        isLoading = true

        do {
            if hasRSVPed {
                try await EventService.shared.cancelRSVP(eventId: event.id)
                hasRSVPed = false
            } else {
                try await EventService.shared.rsvpToEvent(eventId: event.id)
                hasRSVPed = true
            }
        } catch {
            errorMessage = "Failed to update RSVP. Please try again."
            showError = true
        }

        isLoading = false
    }

    private func handleFollow() async {
        do {
            if isFollowing {
                try await UserService.shared.unfollowUser(userId: event.authorId)
                isFollowing = false
            } else {
                try await UserService.shared.followUser(userId: event.authorId)
                isFollowing = true
            }
        } catch {
            errorMessage = "Failed to update follow status. Please try again."
            showError = true
        }
    }
}

struct EventHeroSection: View {
    let event: FeedItem
    @Binding var hasRSVPed: Bool
    @Binding var isLoading: Bool
    let handleRSVP: () async -> Void

    var body: some View {
        ZStack {
            // Hero Image
            if let heroImageUrl = event.heroImageUrl ?? event.imageUrl {
                AsyncImage(url: URL(string: heroImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 250)
                        .overlay(
                            ProgressView()
                        )
                }
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 250)
            }

            // Organizer Badge Overlay
            VStack {
                HStack {
                    Spacer()
                }

                Spacer()

                HStack {
                    HStack(spacing: 8) {
                        // Organizer Avatar
                        if let avatarUrl = event.authorAvatar {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(event.authorName.prefix(1)))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    )
                            }
                        } else {
                            Circle()
                                .fill(Color(.systemGray4))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(event.authorName.prefix(1)))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                )
                        }

                        Text(event.authorName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }

        // Content below hero with RSVP button
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                if let title = event.title {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(3)
                }

                Text(event.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }

            HStack {
                Text("Free")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    Task {
                        await handleRSVP()
                    }
                }) {
                    Text(hasRSVPed ? "Cancel RSVP" : "RSVP Now")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(isLoading ? Color.gray : (hasRSVPed ? Color.orange : Color.red))
                        .cornerRadius(25)
                }
                .disabled(isLoading)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct EventDetailsSection: View {
    let event: FeedItem
    @Binding var isFollowing: Bool
    let handleFollow: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Organizer Row
            VStack(alignment: .leading, spacing: 8) {
                if let title = event.title {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                }

                HStack {
                    Text(event.authorName)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        Task {
                            await handleFollow()
                        }
                    }) {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(isFollowing ? .primary : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isFollowing ? Color(.systemGray6) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isFollowing ? Color(.systemGray4) : Color.blue, lineWidth: 1)
                            )
                            .cornerRadius(20)
                    }
                }
            }

            // Description
            Text(event.eventDetailedDescription ?? event.content)
                .font(.body)
                .foregroundColor(.primary)

            // Date and Time
            if let eventDate = event.eventDate {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatEventDate(eventDate, endDate: event.eventEndDate))
                            .font(.body)
                            .fontWeight(.medium)

                        Text(formatEventTime(eventDate, endDate: event.eventEndDate))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            // Location
            if let location = event.eventLocation {
                HStack(spacing: 8) {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(location)
                            .font(.body)
                            .fontWeight(.medium)

                        if let address = event.eventAddress {
                            Text(address)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        Button(action: {
                            if let address = event.eventAddress {
                                EventService.shared.getDirections(to: address)
                            } else if let eventLocation = event.eventLocation {
                                EventService.shared.getDirections(to: eventLocation)
                            }
                        }) {
                            Text("Get directions")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }

                    Spacer()
                }
            }

            // Duration and Format
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(event.eventDuration ?? "2 hours")
                        .font(.body)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Format")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(event.eventFormat ?? "In Person")
                        .font(.body)
                        .fontWeight(.medium)
                }

                Spacer()
            }

            // Note
            if let note = event.eventNote {
                Text("Note: \(note)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private func formatEventDate(_ date: Date, endDate: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private func formatEventTime(_ date: Date, endDate: Date?) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let startTime = formatter.string(from: date)

        if let endDate = endDate {
            let endTime = formatter.string(from: endDate)
            return "\(startTime) - \(endTime) EST"
        } else {
            return "\(startTime) EST"
        }
    }
}

struct OrganizerSection: View {
    let event: FeedItem
    @Binding var isFollowing: Bool
    let handleFollow: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Organizer")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                // Organizer Avatar
                if let avatarUrl = event.authorAvatar {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(event.authorName.prefix(1)))
                                    .font(.title3)
                                    .fontWeight(.medium)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(String(event.authorName.prefix(1)))
                                .font(.title3)
                                .fontWeight(.medium)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.authorName)
                        .font(.body)
                        .fontWeight(.medium)

                    HStack(spacing: 4) {
                        Text("\(event.organizerFollowers ?? 12500) followers")
                        Text("•")
                        Text("\(event.organizerEventsCount ?? 47) events")
                        Text("•")
                        Text("\(event.organizerYearsActive ?? 8) years active")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    EventService.shared.openContactOptions(for: event.authorName)
                }) {
                    Text("Contact")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }

                Button(action: {
                    Task {
                        await handleFollow()
                    }
                }) {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationView {
        EventDetailView(event: FeedItem(
            id: "event-1",
            type: .event,
            title: "Town Hall: Community Safety Discussion",
            content: "Join us for an open forum on neighborhood safety initiatives and community policing programs.",
            authorId: "user-1",
            authorName: "Senator Charles Schumer",
            authorAvatar: nil,
            createdAt: Date(),
            eventDate: Date().addingTimeInterval(86400),
            eventLocation: "Brooklyn Community Center",
            eventType: "Town Hall",
            eventEndDate: Date().addingTimeInterval(86400 + 7200),
            eventAddress: "1234 Community Ave, Brooklyn, NY 11201",
            eventDuration: "2 hours",
            eventFormat: "In Person",
            eventNote: "Doors open at 6:30 PM",
            eventDetailedDescription: "Join Senator Charles Schumer for an important community dialogue about neighborhood safety initiatives and the future of community policing in our district. This town hall will feature: • Open discussion on current safety concerns • Updates on recent legislative initiatives • Q&A session with local law enforcement officials • Community input on proposed safety measures. Light refreshments will be provided. ASL interpretation available upon request.",
            organizerFollowers: 12500,
            organizerEventsCount: 47,
            organizerYearsActive: 8,
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
}
