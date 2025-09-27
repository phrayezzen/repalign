//
//  RepAlignApp.swift
//  RepAlign
//
//  Created by Xilin Liu on 9/18/25.
//

import SwiftUI
import SwiftData

@main
struct RepAlignApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            CitizenProfile.self,
            LegislatorProfile.self,
            Post.self,
            Follow.self,
            Bill.self,
            Vote.self,
            CampaignContributor.self,
            Event.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            print("DEBUG: Attempting to create ModelContainer with schema...")
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("DEBUG: ModelContainer created successfully")

            // Insert mock data if database is empty
            DispatchQueue.main.async {
                insertMockDataIfNeeded(container: container)
            }

            return container
        } catch {
            print("DEBUG: Failed to create ModelContainer: \(error)")

            // If there's a migration error, delete the store and try again
            let storeURL = modelConfiguration.url
            print("DEBUG: Attempting to clear database at: \(storeURL)")

            try? FileManager.default.removeItem(at: storeURL)
            // Also remove related files
            let baseURL = storeURL.deletingPathExtension()
            try? FileManager.default.removeItem(at: baseURL.appendingPathExtension("sqlite-wal"))
            try? FileManager.default.removeItem(at: baseURL.appendingPathExtension("sqlite-shm"))

            do {
                print("DEBUG: Retrying ModelContainer creation after clearing database...")
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("DEBUG: ModelContainer created successfully on retry")

                // Insert mock data since we recreated the store
                DispatchQueue.main.async {
                    insertMockDataIfNeeded(container: container)
                }

                return container
            } catch {
                print("FATAL: Could not create ModelContainer even after clearing store: \(error)")
                fatalError("Could not create ModelContainer even after clearing store: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private func insertMockDataIfNeeded(container: ModelContainer) {
    let context = container.mainContext

    // Check if we already have data
    let descriptor = FetchDescriptor<User>()
    let existingUsers = try? context.fetch(descriptor)

    if existingUsers?.isEmpty ?? true {
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
            context.insert(user)
        }
        for profile in citizenProfiles {
            context.insert(profile)
        }
        for profile in legislatorProfiles {
            context.insert(profile)
        }
        for post in posts {
            context.insert(post)
        }
        for follow in follows {
            context.insert(follow)
        }
        for bill in bills {
            context.insert(bill)
        }
        for vote in votes {
            context.insert(vote)
        }
        for contributor in contributors {
            context.insert(contributor)
        }
        for event in events {
            context.insert(event)
        }

        try? context.save()
    }
}
