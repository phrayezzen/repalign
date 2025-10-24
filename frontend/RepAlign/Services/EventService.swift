import Foundation
import UIKit

class EventService {
    static let shared = EventService()
    private let apiClient = APIClient.shared

    private init() {}

    func rsvpToEvent(eventId: String) async throws {
        try await apiClient.post(path: "/congress/events/\(eventId)/rsvp", requiresAuth: true)
    }

    func cancelRSVP(eventId: String) async throws {
        try await apiClient.delete(path: "/congress/events/\(eventId)/rsvp", requiresAuth: true)
    }

    func getDirections(to address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        #if os(iOS)
        if let url = URL(string: "http://maps.apple.com/?address=\(encodedAddress)") {
            UIApplication.shared.open(url)
        }
        #endif
    }

    func openContactOptions(for organizer: String) {
        // This would typically open a contact modal or email composer
        // For now, we'll just print to console
        print("Opening contact options for \(organizer)")
    }
}

enum EventError: Error {
    case invalidURL
    case rsvpFailed
    case cancelRSVPFailed
    case networkError
}