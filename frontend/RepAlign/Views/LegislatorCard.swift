import SwiftUI

struct LegislatorCard: View {
    let legislator: LegislatorService.Legislator
    let onFollow: () -> Void

    private var partyColor: Color {
        switch legislator.party.lowercased() {
        case "democrat", "democratic":
            return .blue
        case "republican":
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Profile Image with verified badge
            ZStack(alignment: .bottomTrailing) {
                if let photoUrl = legislator.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color(.systemGray5))
                            .overlay(
                                Text(legislator.initials ?? String(legislator.firstName.prefix(1)) + String(legislator.lastName.prefix(1)))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(legislator.initials ?? String(legislator.firstName.prefix(1)) + String(legislator.lastName.prefix(1)))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }

                // Verified badge
                Circle()
                    .fill(.blue)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 2, y: 2)
            }

            // Legislator Info
            VStack(alignment: .leading, spacing: 6) {
                Text(legislator.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Text(legislator.state)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text(legislator.party.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(partyColor)
                }

                Text("\(legislator.formattedFollowers) followers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Follow Button
            Button(action: onFollow) {
                Text(legislator.isFollowing == true ? "Following" : "Follow")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(legislator.isFollowing == true ? .primary : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(legislator.isFollowing == true ? Color.red : Color.clear)
                    .foregroundColor(legislator.isFollowing == true ? .white : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(legislator.isFollowing == true ? Color.clear : Color(.systemGray4), lineWidth: 1)
                    )
                    .cornerRadius(4)
            }
            .buttonStyle(BorderlessButtonStyle())

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

#Preview {
    VStack(spacing: 0) {
        LegislatorCard(
            legislator: LegislatorService.Legislator(
                id: "1",
                firstName: "Elizabeth",
                lastName: "Warren",
                photoUrl: nil,
                initials: "EW",
                chamber: "senate",
                state: "Massachusetts",
                district: nil,
                party: "Democrat",
                yearsInOffice: 11,
                followerCount: 82400,
                bioguideId: "W000817",
                userId: nil,
                createdAt: Date(),
                updatedAt: Date(),
                isFollowing: true
            ),
            onFollow: {}
        )

        Divider()

        LegislatorCard(
            legislator: LegislatorService.Legislator(
                id: "2",
                firstName: "Lisa",
                lastName: "Murkowski",
                photoUrl: nil,
                initials: "LM",
                chamber: "senate",
                state: "Alaska",
                district: nil,
                party: "Republican",
                yearsInOffice: 21,
                followerCount: 52300,
                bioguideId: "M001153",
                userId: nil,
                createdAt: Date(),
                updatedAt: Date(),
                isFollowing: false
            ),
            onFollow: {}
        )

        Divider()

        LegislatorCard(
            legislator: LegislatorService.Legislator(
                id: "3",
                firstName: "James",
                lastName: "Smith",
                photoUrl: nil,
                initials: "JS",
                chamber: "senate",
                state: "Alabama",
                district: nil,
                party: "Democrat",
                yearsInOffice: 4,
                followerCount: 62757,
                bioguideId: "S001234",
                userId: nil,
                createdAt: Date(),
                updatedAt: Date(),
                isFollowing: false
            ),
            onFollow: {}
        )
    }
}
