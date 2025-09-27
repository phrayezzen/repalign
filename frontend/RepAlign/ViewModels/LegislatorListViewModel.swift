import Foundation
import SwiftUI

@Observable
class LegislatorListViewModel {
    private let repository: LegislatorRepositoryProtocol

    // Published properties
    var legislators: [LegislatorProfile] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""

    // Filter states
    var selectedParty: Party?
    var selectedChamber: PoliticalPosition?

    init(repository: LegislatorRepositoryProtocol = LegislatorRepository.shared) {
        self.repository = repository
    }

    // MARK: - Public Methods

    @MainActor
    func loadLegislators() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedLegislators = try await repository.fetchAllLegislators()
            legislators = fetchedLegislators
        } catch {
            errorMessage = "Failed to load legislators: \(error.localizedDescription)"
            // Fallback to cached data if available
            legislators = repository.getCachedLegislators()
        }

        isLoading = false
    }

    @MainActor
    func refreshLegislators() async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.syncLegislators()
            legislators = repository.getCachedLegislators()
        } catch {
            errorMessage = "Failed to refresh legislators: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func searchLegislators() async {
        if searchQuery.isEmpty {
            legislators = repository.getCachedLegislators()
        } else {
            legislators = await repository.searchLegislators(query: searchQuery)
        }
        applyFilters()
    }

    func applyFilters() {
        var filteredLegislators = legislators

        // Filter by party
        if let selectedParty = selectedParty {
            filteredLegislators = filteredLegislators.filter { $0.party == selectedParty }
        }

        // Filter by chamber
        if let selectedChamber = selectedChamber {
            filteredLegislators = filteredLegislators.filter { $0.position == selectedChamber }
        }

        legislators = filteredLegislators
    }

    func clearFilters() {
        selectedParty = nil
        selectedChamber = nil
        Task {
            await searchLegislators()
        }
    }

    var shouldShowRefreshButton: Bool {
        return repository.shouldRefreshData()
    }

    // MARK: - Computed Properties

    var senatorCount: Int {
        return legislators.filter { $0.position == .senator }.count
    }

    var representativeCount: Int {
        return legislators.filter { $0.position == .representative }.count
    }

    var democratCount: Int {
        return legislators.filter { $0.party == .democrat }.count
    }

    var republicanCount: Int {
        return legislators.filter { $0.party == .republican }.count
    }

    var independentCount: Int {
        return legislators.filter { $0.party == .independent }.count
    }
}

// MARK: - Filter Helpers
extension LegislatorListViewModel {
    var availableParties: [Party] {
        return [.democrat, .republican, .independent]
    }

    var availableChambers: [PoliticalPosition] {
        return [.senator, .representative]
    }

    func partyDisplayName(_ party: Party) -> String {
        switch party {
        case .democrat:
            return "Democratic"
        case .republican:
            return "Republican"
        case .independent:
            return "Independent"
        default:
            return party.rawValue
        }
    }

    func chamberDisplayName(_ chamber: PoliticalPosition) -> String {
        switch chamber {
        case .senator:
            return "Senate"
        case .representative:
            return "House"
        default:
            return chamber.rawValue
        }
    }
}