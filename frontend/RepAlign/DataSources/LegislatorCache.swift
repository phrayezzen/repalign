import Foundation
import SwiftData

// MARK: - Cache Protocol
protocol LegislatorCacheProtocol {
    func getAllLegislators() -> [LegislatorProfile]
    func getLegislator(bioguideId: String) -> LegislatorProfile?
    func saveLegislators(_ legislators: [LegislatorProfile])
    func saveLegislator(_ legislator: LegislatorProfile)
    func deleteLegislator(bioguideId: String)
    func clearCache()
    func getLastSyncDate() -> Date?
    func updateLastSyncDate()
    func shouldRefresh() -> Bool
}

// MARK: - SwiftData Cache Implementation
class SwiftDataLegislatorCache: LegislatorCacheProtocol {
    private let container: ModelContainer
    private let context: ModelContext

    init(container: ModelContainer? = nil) {
        if let container = container {
            self.container = container
        } else {
            // Use app's shared container
            do {
                print("DEBUG: Initializing SwiftData ModelContainer...")
                self.container = try ModelContainer(for:
                    User.self,
                    LegislatorProfile.self,
                    CacheMetadata.self,
                    Post.self,
                    CitizenProfile.self,
                    Follow.self,
                    Bill.self,
                    Vote.self,
                    CampaignContributor.self,
                    Event.self
                )
                print("DEBUG: ModelContainer initialized successfully")
            } catch {
                print("FATAL: Failed to initialize ModelContainer: \(error)")
                fatalError("Failed to initialize ModelContainer: \(error)")
            }
        }
        self.context = self.container.mainContext
    }

    func getAllLegislators() -> [LegislatorProfile] {
        do {
            let descriptor = FetchDescriptor<LegislatorProfile>(
                sortBy: [SortDescriptor(\.userId)]
            )
            let legislators = try context.fetch(descriptor)
            print("DEBUG: Successfully fetched \(legislators.count) legislators from cache")
            return legislators
        } catch {
            print("DEBUG: Error fetching legislators from cache: \(error)")
            return []
        }
    }

    func getLegislator(bioguideId: String) -> LegislatorProfile? {
        let descriptor = FetchDescriptor<LegislatorProfile>(
            predicate: #Predicate { $0.bioguideId == bioguideId }
        )
        return try? context.fetch(descriptor).first
    }

    func saveLegislators(_ legislators: [LegislatorProfile]) {
        // Clear existing legislators first
        clearLegislators()

        // Insert new legislators
        for legislator in legislators {
            context.insert(legislator)
        }

        saveContext()
    }

    func saveLegislator(_ legislator: LegislatorProfile) {
        context.insert(legislator)
        saveContext()
    }

    func deleteLegislator(bioguideId: String) {
        if let legislator = getLegislator(bioguideId: bioguideId) {
            context.delete(legislator)
            saveContext()
        }
    }

    func clearCache() {
        clearLegislators()
        clearMetadata()
        saveContext()
    }

    func getLastSyncDate() -> Date? {
        return getCacheMetadata()?.lastSyncDate
    }

    func updateLastSyncDate() {
        let metadata = getCacheMetadata() ?? CacheMetadata()
        metadata.lastSyncDate = Date()
        context.insert(metadata)
        saveContext()
    }

    func shouldRefresh() -> Bool {
        guard let lastSync = getLastSyncDate() else {
            return true // No sync date, should refresh
        }

        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync > AppConfig.cacheRefreshInterval
    }

    // MARK: - Private Methods

    private func clearLegislators() {
        let descriptor = FetchDescriptor<LegislatorProfile>()
        let legislators = (try? context.fetch(descriptor)) ?? []
        for legislator in legislators {
            context.delete(legislator)
        }
    }

    private func clearMetadata() {
        let descriptor = FetchDescriptor<CacheMetadata>()
        let metadata = (try? context.fetch(descriptor)) ?? []
        for item in metadata {
            context.delete(item)
        }
    }

    private func getCacheMetadata() -> CacheMetadata? {
        let descriptor = FetchDescriptor<CacheMetadata>()
        return try? context.fetch(descriptor).first
    }

    private func saveContext() {
        do {
            print("DEBUG: Attempting to save SwiftData context...")
            try context.save()
            print("DEBUG: SwiftData context saved successfully")
        } catch {
            print("DEBUG: Failed to save SwiftData cache: \(error)")

            // More detailed error logging
            if let nsError = error as NSError? {
                print("DEBUG: Error domain: \(nsError.domain)")
                print("DEBUG: Error code: \(nsError.code)")
                print("DEBUG: Error userInfo: \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - Cache Metadata Model
@Model
final class CacheMetadata {
    var id: String
    var lastSyncDate: Date?
    var cacheVersion: String

    init(id: String = "legislators_cache",
         lastSyncDate: Date? = nil,
         cacheVersion: String = "1.0") {
        self.id = id
        self.lastSyncDate = lastSyncDate
        self.cacheVersion = cacheVersion
    }
}