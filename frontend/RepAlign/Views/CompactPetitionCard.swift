import SwiftUI

struct CompactPetitionCard: View {
    let petition: PetitionService.Petition
    let onSign: () -> Void
    @State private var showFullDescription = false

    private var progress: Double {
        min(Double(petition.currentSignatures) / Double(petition.targetSignatures), 1.0)
    }

    private var formattedSignatures: String {
        formatNumber(petition.currentSignatures)
    }

    var body: some View {
        NavigationLink(destination: PetitionDetailView(petitionId: petition.id)) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail image
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.3))
                    )

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Category tag
                        Text(petition.category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                        Spacer()

                        // Share button
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Title
                    Text(petition.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                }
            }
            .padding(12)

            // Stats row
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formattedSignatures)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let daysRemaining = petition.daysRemaining {
                        Text("\(daysRemaining) days")
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
                Text(petition.status.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)

            // Progress info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(progress * 100))% to goal")
                    .font(.caption)
                    .fontWeight(.medium)

                ProgressView(value: progress)
                    .tint(.red)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Description preview
            VStack(alignment: .leading, spacing: 4) {
                Text(petition.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(showFullDescription ? nil : 2)

                Button(action: { showFullDescription.toggle() }) {
                    Text("Read More")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            // Sign Now button
            Text(petition.userHasSigned == true ? "Signed" : "Sign Now")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(petition.userHasSigned == true ? Color.gray : Color.red)
                .cornerRadius(8)
                .onTapGesture {
                    if petition.userHasSigned != true {
                        onSign()
                    }
                }
                .padding(12)
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
    VStack(spacing: 16) {
        CompactPetitionCard(
            petition: PetitionService.Petition(
                id: "2",
                title: "Save Our Local Library From Budget Cuts",
                description: "The downtown library faces closure due to budget constraints. Help us petition the city to maintain funding...",
                category: "Education",
                targetSignatures: 5000,
                currentSignatures: 2850,
                progressPercentage: 57.0,
                status: "active",
                deadline: Date().addingTimeInterval(24 * 24 * 60 * 60),
                daysRemaining: 24,
                creatorId: "user2",
                creatorName: "Library Friends",
                creatorAvatar: nil,
                createdAt: Date(),
                updatedAt: Date(),
                userHasSigned: false,
                isFeatured: false
            ),
            onSign: {}
        )

        CompactPetitionCard(
            petition: PetitionService.Petition(
                id: "3",
                title: "Stop the Pipeline Through Protected Wetlands",
                description: "Protect our local ecosystem by stopping the proposed oil pipeline that would destroy 50 acres of protected...",
                category: "Environment",
                targetSignatures: 15000,
                currentSignatures: 12450,
                progressPercentage: 83.0,
                status: "active",
                deadline: Date().addingTimeInterval(8 * 24 * 60 * 60),
                daysRemaining: 8,
                creatorId: "user3",
                creatorName: "Green Alliance",
                creatorAvatar: nil,
                createdAt: Date(),
                updatedAt: Date(),
                userHasSigned: false,
                isFeatured: false
            ),
            onSign: {}
        )
    }
    .padding()
}
