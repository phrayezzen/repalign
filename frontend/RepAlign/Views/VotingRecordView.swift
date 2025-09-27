import SwiftUI

struct VotingRecordView: View {
    let votes: [Vote]
    let bills: [Bill]
    let stats: VotingStats

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            progressSection
            recentVotesSection
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Voting Record")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("\(stats.alignmentPercentage, specifier: "%.0f")% alignment")
                    .font(.subheadline)
                    .foregroundColor(alignmentColor)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(stats.alignedVotes) votes with you")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)

                Spacer()

                Text("\(stats.againstVotes) votes against")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.red.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.green)
                        .frame(
                            width: geometry.size.width * (stats.alignmentPercentage / 100),
                            height: 8
                        )
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }

    private var recentVotesSection: some View {
        VStack(spacing: 12) {
            let recentVotes = Array(votes.prefix(3))

            ForEach(recentVotes, id: \.id) { vote in
                if let bill = bills.first(where: { $0.id == vote.billId }) {
                    VoteRowView(vote: vote, bill: bill)
                }
            }

            Button(action: {}) {
                Text("View All Votes")
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

    private var alignmentColor: Color {
        switch stats.alignmentPercentage {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
}

struct VoteRowView: View {
    let vote: Vote
    let bill: Bill

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: vote.position == .yes ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(vote.position == .yes ? .green : .red)

                    if bill.isAlignedWithUser {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)

                    if let amount = bill.amount {
                        Text(amount)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(bill.billDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    Text(timeAgo(from: bill.dateVoted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text(vote.position.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(voteColor)
                        .cornerRadius(6)
                }
            }

            Divider()
                .opacity(0.5)
        }
    }

    private var voteColor: Color {
        switch vote.position {
        case .yes: return .blue
        case .no: return .purple
        case .abstain: return .orange
        case .absent: return .gray
        }
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    let mockVotes = MockDataProvider.createMockVotes()
    let mockBills = MockDataProvider.createMockBills()
    let stats = VotingStats(totalVotes: 156, alignedVotes: 134, againstVotes: 22)

    return VotingRecordView(
        votes: mockVotes,
        bills: mockBills,
        stats: stats
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}