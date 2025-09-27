import Foundation
import SwiftData

enum PoliticalPosition: String, CaseIterable, Codable {
    case representative = "Representative"
    case senator = "Senator"
    case governor = "Governor"
    case mayor = "Mayor"
}

enum Party: String, CaseIterable, Codable {
    case democrat = "Democrat"
    case republican = "Republican"
    case independent = "Independent"
    case green = "Green"
    case libertarian = "Libertarian"
}

enum MatchStatus: String, CaseIterable, Codable {
    case excellentMatch = "Excellent Match"
    case goodMatch = "Good Match"
    case fairMatch = "Fair Match"
    case poorMatch = "Poor Match"

    static func from(repAlignScore: Double) -> MatchStatus {
        switch repAlignScore {
        case 85...100:
            return .excellentMatch
        case 70..<85:
            return .goodMatch
        case 50..<70:
            return .fairMatch
        default:
            return .poorMatch
        }
    }
}

@Model
final class LegislatorProfile {
    var userId: String
    var bioguideId: String?
    var position: PoliticalPosition
    var district: String?
    var party: Party
    var yearsInOffice: Int
    var alignmentRating: Double
    var responsivenessRating: Double
    var transparencyRating: Double
    var officialWebsiteURL: String?
    var contactPhoneNumber: String?
    var committees: [String]
    var leadership: [String]

    var user: User?

    init(
        userId: String,
        bioguideId: String? = nil,
        position: PoliticalPosition,
        district: String? = nil,
        party: Party,
        yearsInOffice: Int,
        alignmentRating: Double,
        responsivenessRating: Double,
        transparencyRating: Double,
        officialWebsiteURL: String? = nil,
        contactPhoneNumber: String? = nil,
        committees: [String] = [],
        leadership: [String] = []
    ) {
        self.userId = userId
        self.bioguideId = bioguideId
        self.position = position
        self.district = district
        self.party = party
        self.yearsInOffice = yearsInOffice
        self.alignmentRating = alignmentRating
        self.responsivenessRating = responsivenessRating
        self.transparencyRating = transparencyRating
        self.officialWebsiteURL = officialWebsiteURL
        self.contactPhoneNumber = contactPhoneNumber
        self.committees = committees
        self.leadership = leadership
    }

    var repAlignScore: Double {
        return (alignmentRating + responsivenessRating + transparencyRating) / 3.0
    }

    var matchStatus: MatchStatus {
        return MatchStatus.from(repAlignScore: repAlignScore)
    }

    var formattedPosition: String {
        if let district = district {
            return "\(position.rawValue) • \(district)"
        }
        return position.rawValue
    }
}