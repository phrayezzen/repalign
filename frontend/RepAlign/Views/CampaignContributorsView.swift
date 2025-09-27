import SwiftUI

struct CampaignContributorsView: View {
    let contributors: [CampaignContributor]

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            contributorsList
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var headerSection: some View {
        HStack {
            Text("Campaign Contributors")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()
        }
    }

    private var contributorsList: some View {
        VStack(spacing: 16) {
            let topContributors = Array(contributors.prefix(4))

            ForEach(topContributors, id: \.id) { contributor in
                ContributorRowView(contributor: contributor)
            }

            Button(action: {}) {
                Text("View All Contributors")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

struct ContributorRowView: View {
    let contributor: CampaignContributor

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                contributorIcon

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(contributor.name)
                            .font(.headline)
                            .fontWeight(.medium)

                        if contributor.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }

                    Text(contributor.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(contributor.formattedAmount)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(contributor.cycle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()
                .opacity(0.5)
        }
    }

    private var contributorIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 40, height: 40)

            Text(contributor.abbreviation ?? String(contributor.name.prefix(2)).uppercased())
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var iconBackgroundColor: Color {
        switch contributor.type {
        case .pac: return .blue
        case .organization: return .green
        case .individual: return .orange
        case .corporation: return .purple
        }
    }
}

#Preview {
    let mockContributors = MockDataProvider.createMockCampaignContributors()

    return CampaignContributorsView(contributors: mockContributors)
        .padding()
        .background(Color(.systemGroupedBackground))
}