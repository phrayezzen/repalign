import SwiftUI

struct RelatedLegislatorsView: View {
    let relatedLegislators: [User]
    let legislatorProfiles: [LegislatorProfile]

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            legislatorsList
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var headerSection: some View {
        HStack {
            Text("You might also like")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()
        }
    }

    private var legislatorsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(relatedLegislators, id: \.id) { legislator in
                    if let profile = legislatorProfile(for: legislator) {
                        RelatedLegislatorCard(user: legislator, profile: profile)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func legislatorProfile(for user: User) -> LegislatorProfile? {
        return legislatorProfiles.first { $0.userId == user.id }
    }
}

struct RelatedLegislatorCard: View {
    let user: User
    let profile: LegislatorProfile
    @State private var isFollowing = false

    var body: some View {
        VStack(spacing: 12) {
            ProfileAvatarView(user: user, size: 60)

            VStack(spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(profile.position.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let district = profile.district {
                    Text(district)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 4) {
                Text("RepAlign")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("\(Int(profile.repAlignScore))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(profile.repAlignScore))
            }

            Button(action: { isFollowing.toggle() }) {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isFollowing ? .primary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(isFollowing ? Color.gray.opacity(0.2) : Color.red)
                    .cornerRadius(6)
            }
        }
        .frame(width: 140)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

#Preview {
    let mockLegislators = MockDataProvider.createMockUsers().filter { $0.userType == .legislator }
    let mockProfiles = MockDataProvider.createMockLegislatorProfiles()

    return RelatedLegislatorsView(
        relatedLegislators: mockLegislators,
        legislatorProfiles: mockProfiles
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}