import SwiftUI

struct PetitionDetailView: View {
    let petitionId: String
    @Environment(\.dismiss) private var dismiss
    @State private var petition: PetitionService.Petition?
    @State private var isLoading = true
    @State private var isSigning = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showFullDescription = false

    private var progress: Double {
        guard let petition = petition else { return 0 }
        return min(Double(petition.currentSignatures) / Double(petition.targetSignatures), 1.0)
    }

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading petition...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if let petition = petition {
                VStack(spacing: 0) {
                    // Hero Image Section
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray.opacity(0.3))
                            )

                        // Active badge
                        Text(petition.status.capitalized)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(4)
                            .padding(12)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text(petition.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 20)

                        // Signatures and Progress
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(formatNumber(petition.currentSignatures)) signed")
                                    .font(.headline)
                                    .fontWeight(.semibold)

                                Spacer()

                                Text("Goal: \(formatNumber(petition.targetSignatures))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Progress bar
                            ProgressView(value: progress)
                                .tint(.black)
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                        }

                        // Days left and Trending
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                if let daysRemaining = petition.daysRemaining {
                                    Text("\(daysRemaining) days left")
                                        .font(.caption)
                                } else {
                                    Text("No deadline")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.secondary)

                            // Trending badge (mock - could be based on recent signature velocity)
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.caption)
                                Text("Trending")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)

                            Spacer()
                        }

                        // Sign This Petition Button
                        Button(action: handleSignPetition) {
                            HStack {
                                if isSigning {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }

                                Text(petition.userHasSigned == true ? "Signed" : "Sign this petition")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(petition.userHasSigned == true ? Color.gray : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(petition.userHasSigned == true || isSigning)

                        Divider()
                            .padding(.vertical, 8)

                        // Creator Card
                        CreatorCardView(
                            name: petition.creatorName,
                            title: "Petition Creator", // Could be enhanced with user role
                            createdDate: petition.createdAt,
                            updatesCount: 3, // Mock data
                            mediaMetions: 23 // Mock data
                        )

                        Divider()
                            .padding(.vertical, 8)

                        // The Issue Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("The Issue")
                                .font(.title3)
                                .fontWeight(.bold)

                            // Category tag
                            Text(petition.category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            // Description
                            Text(petition.description)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(showFullDescription ? nil : 6)

                            Button(action: { showFullDescription.toggle() }) {
                                Text(showFullDescription ? "Read less" : "Read more →")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                        }

                        Divider()
                            .padding(.vertical, 8)

                        // Updates Section
                        UpdatesTimelineView()

                        Divider()
                            .padding(.vertical, 8)

                        // Related Petitions
                        RelatedPetitionsView(category: petition.category)

                        Divider()
                            .padding(.vertical, 8)

                        // Report link
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "flag")
                                    .font(.caption)
                                Text("Report this petition")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.primary)
                }
            }
        }
        .task {
            await loadPetition()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unexpected error occurred")
        }
    }

    private func loadPetition() async {
        isLoading = true

        do {
            let loadedPetition = try await PetitionService.shared.getPetition(id: petitionId)
            await MainActor.run {
                self.petition = loadedPetition
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }

    private func handleSignPetition() {
        guard let petition = petition else { return }

        isSigning = true

        Task {
            do {
                let response = try await PetitionService.shared.signPetition(id: petition.id)

                await MainActor.run {
                    // Update petition
                    if var updatedPetition = self.petition {
                        self.petition = PetitionService.Petition(
                            id: updatedPetition.id,
                            title: updatedPetition.title,
                            description: updatedPetition.description,
                            category: updatedPetition.category,
                            targetSignatures: updatedPetition.targetSignatures,
                            currentSignatures: response.currentSignatures,
                            progressPercentage: Double(response.currentSignatures) / Double(updatedPetition.targetSignatures) * 100,
                            status: updatedPetition.status,
                            deadline: updatedPetition.deadline,
                            daysRemaining: updatedPetition.daysRemaining,
                            creatorId: updatedPetition.creatorId,
                            creatorName: updatedPetition.creatorName,
                            creatorAvatar: updatedPetition.creatorAvatar,
                            createdAt: updatedPetition.createdAt,
                            updatedAt: updatedPetition.updatedAt,
                            userHasSigned: true,
                            isFeatured: updatedPetition.isFeatured
                        )
                    }
                    self.isSigning = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isSigning = false
                }
            }
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1

        if number >= 100000 {
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

// MARK: - Creator Card Component

struct CreatorCardView: View {
    let name: String
    let title: String
    let createdDate: Date
    let updatesCount: Int
    let mediaMetions: Int

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.red)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(name.prefix(2).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {}) {
                Text("Follow")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
        }

        // Metadata
        HStack(spacing: 16) {
            Text("Petition created on \(formatDate(createdDate))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)

        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                    .font(.caption)
                Text("\(updatesCount) updates")
                    .font(.caption)
            }

            HStack(spacing: 4) {
                Image(systemName: "newspaper.fill")
                    .font(.caption)
                Text("\(mediaMetions) media mentions")
                    .font(.caption)
            }
        }
        .foregroundColor(.secondary)
        .padding(.top, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Updates Timeline Component

struct UpdatesTimelineView: View {
    // Mock data for now
    let updates = [
        UpdateItem(date: "September 28, 2025", title: "Major news outlets pick up our story", content: "CNN, NBC, and local news stations have covered our petition in the past week highlighting 4 UPS drivers. The media attention is putting pressure on UPS leadership to respond."),
        UpdateItem(date: "September 15, 2025", title: "Teamsters union officially endorses petition", content: "The International Brotherhood of Teamsters has officially endorsed our petition and is making it part of their campaign for air conditioning in UPS trucks."),
        UpdateItem(date: "August 30, 2025", title: "Over 150,000 signatures reached!", content: "We've reached an incredible milestone of 150,000 signatures. Thank you to everyone who has signed and shared this petition. You're making a real difference.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Updates")
                .font(.title3)
                .fontWeight(.bold)

            ForEach(updates) { update in
                UpdateRow(update: update)
            }
        }
    }
}

struct UpdateItem: Identifiable {
    let id = UUID()
    let date: String
    let title: String
    let content: String
}

struct UpdateRow: View {
    let update: UpdateItem
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "megaphone.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(update.date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(update.title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(update.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 3)

            if update.content.count > 100 {
                Button(action: { isExpanded.toggle() }) {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }

            Text("By \(update.id.uuidString.prefix(10))...") // Mock creator reference
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Related Petitions Component

struct RelatedPetitionsView: View {
    let category: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Other petitions you may like")
                .font(.title3)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    RelatedPetitionCard(
                        title: "Protect Amazon Workers from Heat",
                        signatures: "89.2K signed",
                        image: "box.fill"
                    )

                    RelatedPetitionCard(
                        title: "FedEx Driver Safety Standards",
                        signatures: "45.7K signed",
                        image: "shippingbox.fill"
                    )
                }
            }
        }
    }
}

struct RelatedPetitionCard: View {
    let title: String
    let signatures: String
    let image: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(width: 160, height: 100)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: image)
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))
                )

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .frame(width: 160, alignment: .leading)

            Text(signatures)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        PetitionDetailView(petitionId: "sample-id")
    }
}
