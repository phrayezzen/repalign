import Foundation
import SwiftData

enum VotePosition: String, CaseIterable, Codable {
    case yes = "Yes"
    case no = "No"
    case abstain = "Abstain"
    case absent = "Absent"
}

enum BillCategory: String, CaseIterable, Codable {
    case climate = "Climate"
    case healthcare = "Healthcare"
    case infrastructure = "Infrastructure"
    case education = "Education"
    case economy = "Economy"
    case defense = "Defense"
    case socialServices = "Social Services"
}

@Model
final class Bill {
    var id: String
    var title: String
    var billDescription: String
    var category: BillCategory
    var amount: String?
    var dateVoted: Date
    var isAlignedWithUser: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        billDescription: String,
        category: BillCategory,
        amount: String? = nil,
        dateVoted: Date,
        isAlignedWithUser: Bool = true
    ) {
        self.id = id
        self.title = title
        self.billDescription = billDescription
        self.category = category
        self.amount = amount
        self.dateVoted = dateVoted
        self.isAlignedWithUser = isAlignedWithUser
    }
}

@Model
final class Vote {
    var id: String
    var legislatorId: String
    var billId: String
    var position: VotePosition
    var timestamp: Date

    var legislator: LegislatorProfile?
    var bill: Bill?

    init(
        id: String = UUID().uuidString,
        legislatorId: String,
        billId: String,
        position: VotePosition,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.legislatorId = legislatorId
        self.billId = billId
        self.position = position
        self.timestamp = timestamp
    }
}

struct VotingStats {
    let totalVotes: Int
    let alignedVotes: Int
    let againstVotes: Int

    var alignmentPercentage: Double {
        guard totalVotes > 0 else { return 0 }
        return Double(alignedVotes) / Double(totalVotes) * 100
    }
}