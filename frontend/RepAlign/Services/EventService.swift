import Foundation
import UIKit

class EventService {
    static let shared = EventService()
    private let baseURL = "http://localhost:3000"

    private init() {}

    func rsvpToEvent(eventId: String) async throws {
        guard let url = URL(string: "\(baseURL)/congress/events/\(eventId)/rsvp") else {
            throw EventError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // TODO: Add authentication token when available
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw EventError.rsvpFailed
        }
    }

    func cancelRSVP(eventId: String) async throws {
        guard let url = URL(string: "\(baseURL)/congress/events/\(eventId)/rsvp") else {
            throw EventError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        // TODO: Add authentication token when available
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw EventError.cancelRSVPFailed
        }
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