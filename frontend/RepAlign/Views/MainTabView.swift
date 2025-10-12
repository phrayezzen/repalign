import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Feed")
                }
                .tag(0)

            TakeActionView()
                .tabItem {
                    Image(systemName: "hand.raised.fill")
                    Text("Take Action")
                }
                .tag(1)

            MyProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(.red)
    }
}

#Preview {
    @Previewable @State var modelContainer: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: User.self, CitizenProfile.self, LegislatorProfile.self, Post.self, Follow.self, Bill.self, Vote.self, CampaignContributor.self, Event.self,
            configurations: config
        )

        // Insert mock data
        let users = MockDataProvider.createMockUsers()
        let citizenProfiles = MockDataProvider.createMockCitizenProfiles()
        let legislatorProfiles = MockDataProvider.createMockLegislatorProfiles()
        let posts = MockDataProvider.createMockPosts()
        let follows = MockDataProvider.createMockFollows()
        let bills = MockDataProvider.createMockBills()
        let votes = MockDataProvider.createMockVotes()
        let contributors = MockDataProvider.createMockCampaignContributors()
        let events = MockDataProvider.createMockEvents()

        for user in users {
            container.mainContext.insert(user)
        }
        for profile in citizenProfiles {
            container.mainContext.insert(profile)
        }
        for profile in legislatorProfiles {
            container.mainContext.insert(profile)
        }
        for post in posts {
            container.mainContext.insert(post)
        }
        for follow in follows {
            container.mainContext.insert(follow)
        }
        for bill in bills {
            container.mainContext.insert(bill)
        }
        for vote in votes {
            container.mainContext.insert(vote)
        }
        for contributor in contributors {
            container.mainContext.insert(contributor)
        }
        for event in events {
            container.mainContext.insert(event)
        }

        return container
    }()

    MainTabView()
        .modelContainer(modelContainer)
}