import Foundation
import SwiftData

class MockDataProvider {

    static func createMockUsers() -> [User] {
        return [
            createCurrentUser(),
            createJohnDoe(),
            createSarahChen(),
            createMichaelJohnson(),
            createAnaRodriguez(),
            createDavidPark(),
            createEmmaWilson(),
            createRobertGarcía(),
            createLisaThompson()
        ]
    }

    static func createMockCitizenProfiles() -> [CitizenProfile] {
        return [
            CitizenProfile(
                userId: "current_user",
                civicEngagementScore: 850,
                badges: [.activist, .firstPost],
                isCivicConnector: false
            ),
            CitizenProfile(
                userId: "john_doe",
                civicEngagementScore: 1250,
                badges: [.civicConnector],
                isCivicConnector: true
            ),
            CitizenProfile(
                userId: "michael_johnson",
                civicEngagementScore: 875,
                badges: [.activist, .thoughtLeader]
            ),
            CitizenProfile(
                userId: "ana_rodriguez",
                civicEngagementScore: 2300,
                badges: [.civicConnector, .socialButterfly, .thoughtLeader],
                isCivicConnector: true
            ),
            CitizenProfile(
                userId: "david_park",
                civicEngagementScore: 450,
                badges: [.firstPost]
            ),
            CitizenProfile(
                userId: "emma_wilson",
                civicEngagementScore: 1680,
                badges: [.civicConnector, .activist],
                isCivicConnector: true
            ),
            CitizenProfile(
                userId: "lisa_thompson",
                civicEngagementScore: 790,
                badges: [.socialButterfly]
            )
        ]
    }

    static func createMockLegislatorProfiles() -> [LegislatorProfile] {
        return [
            LegislatorProfile(
                userId: "sarah_chen",
                position: .representative,
                district: "CA-11",
                party: .democrat,
                yearsInOffice: 6,
                alignmentRating: 87.0,
                responsivenessRating: 94.0,
                transparencyRating: 89.0
            ),
            LegislatorProfile(
                userId: "robert_garcia",
                position: .senator,
                district: "Texas",
                party: .republican,
                yearsInOffice: 12,
                alignmentRating: 72.0,
                responsivenessRating: 68.0,
                transparencyRating: 81.0
            )
        ]
    }

    static func createMockPosts() -> [Post] {
        return [
            Post(
                authorId: "john_doe",
                content: "Just attended my first town hall meeting! Great to see so many citizens engaged in local politics. 🏛️ #CivicEngagement",
                likeCount: 23,
                commentCount: 7,
                shareCount: 3,
                tags: ["CivicEngagement", "TownHall"]
            ),
            Post(
                authorId: "sarah_chen",
                content: "Proud to announce our new bill for affordable housing in CA-11. Housing is a fundamental right, and we're working to make it accessible for all families in our district.",
                likeCount: 156,
                commentCount: 34,
                shareCount: 28,
                tags: ["Housing", "CA11", "Policy"]
            ),
            Post(
                authorId: "ana_rodriguez",
                content: "Climate action can't wait! Join us this Saturday for the community cleanup at Golden Gate Park. Together we can make a difference. 🌱",
                likeCount: 45,
                commentCount: 12,
                shareCount: 8,
                tags: ["Climate", "Community", "SanFrancisco"]
            ),
            Post(
                authorId: "robert_garcia",
                content: "Visiting small businesses across Texas today. Our economy thrives when we support local entrepreneurs and innovation.",
                likeCount: 89,
                commentCount: 15,
                shareCount: 6,
                tags: ["Economy", "SmallBusiness", "Texas"]
            )
        ]
    }

    static func createMockFollows() -> [Follow] {
        return [
            Follow(followerId: "john_doe", followingId: "sarah_chen"),
            Follow(followerId: "john_doe", followingId: "ana_rodriguez"),
            Follow(followerId: "michael_johnson", followingId: "sarah_chen"),
            Follow(followerId: "ana_rodriguez", followingId: "robert_garcia"),
            Follow(followerId: "david_park", followingId: "john_doe"),
            Follow(followerId: "emma_wilson", followingId: "sarah_chen"),
            Follow(followerId: "lisa_thompson", followingId: "ana_rodriguez")
        ]
    }

    static func createMockBills() -> [Bill] {
        return [
            Bill(
                id: "climate_innovation_fund",
                title: "Climate Innovation Fund",
                billDescription: "$50M for green jobs and clean energy initiatives",
                category: .climate,
                amount: "$50M",
                dateVoted: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                isAlignedWithUser: true
            ),
            Bill(
                id: "healthcare_reform_act",
                title: "Healthcare Reform Act",
                billDescription: "Expanding access to affordable healthcare",
                category: .healthcare,
                dateVoted: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date(),
                isAlignedWithUser: true
            ),
            Bill(
                id: "infrastructure_bill",
                title: "Infrastructure Bill",
                billDescription: "Federal highway and bridge improvements",
                category: .infrastructure,
                dateVoted: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date(),
                isAlignedWithUser: false
            ),
            Bill(
                id: "education_funding_act",
                title: "Education Funding Act",
                billDescription: "Increased funding for public schools",
                category: .education,
                amount: "$2.5B",
                dateVoted: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
                isAlignedWithUser: true
            )
        ]
    }

    static func createMockVotes() -> [Vote] {
        return [
            Vote(legislatorId: "sarah_chen", billId: "climate_innovation_fund", position: .yes),
            Vote(legislatorId: "sarah_chen", billId: "healthcare_reform_act", position: .yes),
            Vote(legislatorId: "sarah_chen", billId: "infrastructure_bill", position: .no),
            Vote(legislatorId: "sarah_chen", billId: "education_funding_act", position: .yes),
            Vote(legislatorId: "robert_garcia", billId: "climate_innovation_fund", position: .no),
            Vote(legislatorId: "robert_garcia", billId: "healthcare_reform_act", position: .abstain),
            Vote(legislatorId: "robert_garcia", billId: "infrastructure_bill", position: .yes),
            Vote(legislatorId: "robert_garcia", billId: "education_funding_act", position: .yes)
        ]
    }

    static func createMockCampaignContributors() -> [CampaignContributor] {
        return [
            CampaignContributor(
                name: "Climate Action Fund",
                abbreviation: "CAF",
                type: .pac,
                amount: 25000,
                cycle: "this cycle",
                isVerified: true,
                legislatorId: "sarah_chen"
            ),
            CampaignContributor(
                name: "Healthcare Alliance",
                abbreviation: "HA",
                type: .organization,
                amount: 18000,
                cycle: "this cycle",
                isVerified: true,
                legislatorId: "sarah_chen"
            ),
            CampaignContributor(
                name: "Education First PAC",
                abbreviation: "EFP",
                type: .pac,
                amount: 12000,
                cycle: "this cycle",
                isVerified: false,
                legislatorId: "sarah_chen"
            ),
            CampaignContributor(
                name: "Small Business Coalition",
                abbreviation: "SBC",
                type: .organization,
                amount: 8000,
                cycle: "this cycle",
                isVerified: true,
                legislatorId: "sarah_chen"
            )
        ]
    }


    static func createMockEvents() -> [Event] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nextFriday = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        let nextSaturday = Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()

        return [
            Event(
                title: "Healthcare Reform",
                eventDescription: "Discussion on expanding healthcare access",
                type: .townHall,
                date: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                location: "Community Center",
                attendeeCount: 156,
                maxAttendees: 200,
                organizerId: "sarah_chen"
            ),
            Event(
                title: "Climate Action Forum",
                eventDescription: "Solutions for environmental challenges",
                type: .forum,
                date: Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: nextFriday) ?? nextFriday,
                location: "City Hall",
                attendeeCount: 89,
                maxAttendees: 150,
                organizerId: "sarah_chen"
            ),
            Event(
                title: "Coffee with the Rep",
                eventDescription: "Informal meet and greet",
                type: .meeting,
                date: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: nextSaturday) ?? nextSaturday,
                location: "Main Street Cafe",
                attendeeCount: 24,
                maxAttendees: 30,
                organizerId: "sarah_chen"
            )
        ]
    }

    // MARK: - Private Helper Methods

    private static func createCurrentUser() -> User {
        return User(
            id: "current_user",
            username: "me",
            displayName: "Me",
            bio: "Active citizen passionate about making my community better. Love getting involved in local politics!",
            location: "San Francisco, CA",
            postsCount: 12,
            followersCount: 47,
            followingCount: 23,
            userType: .citizen
        )
    }

    private static func createJohnDoe() -> User {
        return User(
            id: "john_doe",
            username: "johndoe",
            displayName: "John Doe",
            bio: "Passionate about civic engagement and making a difference in my community.",
            location: "San Francisco, CA",
            postsCount: 24,
            followersCount: 156,
            followingCount: 89,
            userType: .citizen
        )
    }

    private static func createSarahChen() -> User {
        return User(
            id: "sarah_chen",
            username: "repSarahChen",
            displayName: "Rep. Sarah Chen",
            bio: "House Representative for CA-11. Fighting for affordable housing, climate action, and economic opportunity.",
            location: "California, USA",
            postsCount: 342,
            followersCount: 12500,
            followingCount: 287,
            userType: .legislator,
            isVerified: true
        )
    }

    private static func createMichaelJohnson() -> User {
        return User(
            id: "michael_johnson",
            username: "mikeJ",
            displayName: "Michael Johnson",
            bio: "Teacher, father, and advocate for education reform.",
            location: "Austin, TX",
            postsCount: 67,
            followersCount: 234,
            followingCount: 156,
            userType: .citizen
        )
    }

    private static func createAnaRodriguez() -> User {
        return User(
            id: "ana_rodriguez",
            username: "anarod",
            displayName: "Ana Rodriguez",
            bio: "Environmental activist working on climate solutions in the Bay Area.",
            location: "Oakland, CA",
            postsCount: 189,
            followersCount: 892,
            followingCount: 234,
            userType: .citizen
        )
    }

    private static func createDavidPark() -> User {
        return User(
            id: "david_park",
            username: "dpark",
            displayName: "David Park",
            bio: "New to politics but eager to learn and get involved!",
            location: "Seattle, WA",
            postsCount: 8,
            followersCount: 23,
            followingCount: 45,
            userType: .citizen
        )
    }

    private static func createEmmaWilson() -> User {
        return User(
            id: "emma_wilson",
            username: "emmaw",
            displayName: "Emma Wilson",
            bio: "Healthcare worker advocating for better patient care and worker rights.",
            location: "Portland, OR",
            postsCount: 156,
            followersCount: 567,
            followingCount: 123,
            userType: .citizen
        )
    }

    private static func createRobertGarcía() -> User {
        return User(
            id: "robert_garcia",
            username: "senatorGarcia",
            displayName: "Sen. Robert García",
            bio: "Texas State Senator focused on economic development, veterans affairs, and border security.",
            location: "Texas, USA",
            postsCount: 567,
            followersCount: 8900,
            followingCount: 145,
            userType: .legislator,
            isVerified: true
        )
    }

    private static func createLisaThompson() -> User {
        return User(
            id: "lisa_thompson",
            username: "lisaT",
            displayName: "Lisa Thompson",
            bio: "Small business owner and mom fighting for better schools in our community.",
            location: "Denver, CO",
            postsCount: 78,
            followersCount: 345,
            followingCount: 198,
            userType: .citizen
        )
    }
}