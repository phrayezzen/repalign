import Foundation
import SwiftData

enum ContributorType: String, CaseIterable, Codable {
    case pac = "PAC"
    case organization = "Organization"
    case individual = "Individual"
    case corporation = "Corporation"
}

@Model
final class CampaignContributor {
    var id: String
    var name: String
    var abbreviation: String?
    var type: ContributorType
    var amount: Double
    var cycle: String
    var isVerified: Bool
    var legislatorId: String

    var legislator: LegislatorProfile?

    init(
        id: String = UUID().uuidString,
        name: String,
        abbreviation: String? = nil,
        type: ContributorType,
        amount: Double,
        cycle: String,
        isVerified: Bool = false,
        legislatorId: String
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.type = type
        self.amount = amount
        self.cycle = cycle
        self.isVerified = isVerified
        self.legislatorId = legislatorId
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}