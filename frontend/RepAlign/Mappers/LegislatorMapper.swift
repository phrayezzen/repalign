import Foundation

// MARK: - Legislator Mapper
struct LegislatorMapper {

    static func mapToDomain(_ congressMember: CongressMember) -> LegislatorProfile? {
        // Create User first
        let user = createUser(from: congressMember)

        // Map party
        guard let party = mapParty(congressMember.party) else {
            print("Unknown party: \(congressMember.party)")
            return nil
        }

        // Map position based on latest term
        guard let position = mapPosition(from: congressMember.terms) else {
            print("Could not determine position for: \(congressMember.name.fullName)")
            return nil
        }

        // Calculate years in office
        let yearsInOffice = calculateYearsInOffice(from: congressMember.terms)

        // Create district string
        let district = createDistrictString(
            state: congressMember.state,
            district: congressMember.district,
            position: position
        )

        // Create LegislatorProfile
        let legislatorProfile = LegislatorProfile(
            userId: user.id,
            bioguideId: congressMember.bioguideId,
            position: position,
            district: district,
            party: party,
            yearsInOffice: yearsInOffice,
            alignmentRating: generateRandomRating(), // TODO: Replace with real data
            responsivenessRating: generateRandomRating(),
            transparencyRating: generateRandomRating(),
            officialWebsiteURL: generateOfficialWebsite(for: congressMember),
            contactPhoneNumber: nil, // TODO: Add phone if available in API
            committees: [], // TODO: Fetch from committees endpoint
            leadership: [] // TODO: Fetch leadership roles
        )

        return legislatorProfile
    }

    // MARK: - Private Helper Methods

    private static func createUser(from congressMember: CongressMember) -> User {
        let displayName = formatDisplayName(congressMember.name, congressMember.terms)
        let location = formatLocation(congressMember.state, congressMember.district)

        return User(
            id: congressMember.bioguideId,
            username: congressMember.bioguideId.lowercased(),
            displayName: displayName,
            bio: generateBio(for: congressMember),
            profileImageURL: congressMember.depiction?.imageUrl,
            location: location,
            postsCount: 0, // Will be populated later
            followersCount: generateRandomFollowerCount(),
            followingCount: 0,
            userType: .legislator,
            isVerified: true
        )
    }

    private static func formatDisplayName(_ name: CongressName, _ terms: [CongressTerm]) -> String {
        let title = determineTitle(from: terms)
        return "\(title) \(name.fullName)"
    }

    private static func determineTitle(from terms: [CongressTerm]) -> String {
        // Get the most recent term (prefer current terms where endYear is nil)
        let latestTerm = terms.max { term1, term2 in
            let endYear1 = term1.endYear ?? Int.max
            let endYear2 = term2.endYear ?? Int.max
            return endYear1 < endYear2
        }
        return latestTerm?.chamber.lowercased() == "senate" ? "Sen." : "Rep."
    }

    private static func formatLocation(_ state: String, _ district: String?) -> String {
        return "\(state), USA"
    }

    private static func mapParty(_ partyString: String) -> Party? {
        switch partyString.lowercased() {
        case "democratic", "democrat":
            return .democrat
        case "republican":
            return .republican
        case "independent":
            return .independent
        default:
            return nil
        }
    }

    private static func mapPosition(from terms: [CongressTerm]) -> PoliticalPosition? {
        // Get the most recent term (prefer current terms where endYear is nil)
        let latestTerm = terms.max { term1, term2 in
            let endYear1 = term1.endYear ?? Int.max
            let endYear2 = term2.endYear ?? Int.max
            return endYear1 < endYear2
        }

        guard let latestTerm = latestTerm else {
            return nil
        }

        switch latestTerm.chamber.lowercased() {
        case "house":
            return .representative
        case "senate":
            return .senator
        default:
            return nil
        }
    }

    private static func calculateYearsInOffice(from terms: [CongressTerm]) -> Int {
        guard !terms.isEmpty else { return 0 }

        let earliestStart = terms.min { $0.startYear < $1.startYear }?.startYear ?? 0
        let currentYear = Calendar.current.component(.year, from: Date())

        return max(0, currentYear - earliestStart)
    }

    private static func createDistrictString(
        state: String,
        district: String?,
        position: PoliticalPosition
    ) -> String? {
        switch position {
        case .senator:
            return state
        case .representative:
            if let district = district, district != "0" {
                return "\(state)-\(district)"
            } else {
                return "\(state) At-Large"
            }
        default:
            return state
        }
    }

    private static func generateBio(for member: CongressMember) -> String {
        let title = member.terms.last?.chamber.lowercased() == "senate" ? "Senator" : "Representative"
        let location = member.district != nil ? "District \(member.district!)" : member.state

        return "\(title) representing \(location). Committed to serving the people and advancing important legislation."
    }

    // MARK: - Temporary Random Data Generation
    // TODO: Replace with real data from your backend

    private static func generateRandomRating() -> Double {
        return Double.random(in: 60...95)
    }

    private static func generateRandomFollowerCount() -> Int {
        return Int.random(in: 1000...50000)
    }

    private static func generateOfficialWebsite(for member: CongressMember) -> String? {
        // Generate a placeholder website URL
        // In real implementation, this would come from the API
        let firstName = member.name.first.lowercased()
        let lastName = member.name.last.lowercased()
        return "https://\(lastName).house.gov"
    }
}