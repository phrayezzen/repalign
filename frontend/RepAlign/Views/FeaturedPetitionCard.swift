import SwiftUI

struct FeaturedPetitionCard: View {
    let petition: PetitionService.Petition
    let onSign: () -> Void

    private var progress: Double {
        min(Double(petition.currentSignatures) / Double(petition.targetSignatures), 1.0)
    }

    private var formattedSignatures: String {
        formatNumber(petition.currentSignatures)
    }

    private var formattedGoal: String {
        formatNumber(petition.targetSignatures)
    }

    var body: some View {
        NavigationLink(destination: PetitionDetailView(petitionId: petition.id)) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with Featured badge
            ZStack(alignment: .topLeading) {
                // Placeholder image (replace with actual image URL when available)
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))
                    )

                // Featured badge
                Text("Featured")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(16)
                    .padding(12)
            }

            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Category tag
                Text(petition.category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                // Title
                Text(petition.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)

                // Description preview
                Text(petition.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                // Signatures progress
                HStack {
                    Text("\(formattedSignatures) signed")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("Goal: \(formattedGoal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Progress bar
                ProgressView(value: progress)
                    .tint(.red)
                    .scaleEffect(x: 1, y: 2, anchor: .center)

                // Bottom info: time left and status
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let daysRemaining = petition.daysRemaining {
                            Text("\(daysRemaining) days left")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("No deadline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text(petition.status.capitalized)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                // Sign Now button
                Text(petition.userHasSigned == true ? "Signed" : "Sign Now")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(petition.userHasSigned == true ? Color.gray : Color.red)
                    .cornerRadius(8)
                    .onTapGesture {
                        if petition.userHasSigned != true {
                            onSign()
                        }
                    }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1

        if number >= 100000 {
            let value = Double(number) / 1000.0
            return "\(formatter.string(from: NSNumber(value: value)) ?? "\(value)")K"
        } else if number >= 10000 {
            let value = Double(number) / 1000.0
            return "\(formatter.string(from: NSNumber(value: value)) ?? "\(value)")K"
        } else if number >= 1000 {
            let value = Double(number) / 1000.0
            return "\(formatter.string(from: NSNumber(value: value)) ?? "\(value)")K"
        } else {
            return "\(number)"
        }
    }
}

#Preview {
    FeaturedPetitionCard(
        petition: PetitionService.Petition(
            id: "1",
            title: "Demand UPS provide Air Conditioning to all drivers",
            description: "We demand UPS install working air conditioning in all delivery trucks to prevent heat-related illness...",
            category: "Labor / Safety",
            targetSignatures: 200000,
            currentSignatures: 158000,
            progressPercentage: 79.0,
            status: "active",
            deadline: Date().addingTimeInterval(12 * 24 * 60 * 60),
            daysRemaining: 12,
            creatorId: "user1",
            creatorName: "Workers Union",
            creatorAvatar: nil,
            createdAt: Date(),
            updatedAt: Date(),
            userHasSigned: false,
            isFeatured: true
        ),
        onSign: {}
    )
    .padding()
}
