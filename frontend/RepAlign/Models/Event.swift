import Foundation
import SwiftData

enum EventType: String, CaseIterable, Codable {
    case townHall = "Town Hall"
    case forum = "Forum"
    case meeting = "Meeting"
    case rally = "Rally"
    case debate = "Debate"
    case conference = "Conference"
}

@Model
final class Event {
    var id: String
    var title: String
    var eventDescription: String?
    var type: EventType
    var date: Date
    var location: String
    var attendeeCount: Int
    var maxAttendees: Int?
    var isRSVPRequired: Bool
    var organizerId: String?

    var organizer: User?

    init(
        id: String = UUID().uuidString,
        title: String,
        eventDescription: String? = nil,
        type: EventType,
        date: Date,
        location: String,
        attendeeCount: Int = 0,
        maxAttendees: Int? = nil,
        isRSVPRequired: Bool = true,
        organizerId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.type = type
        self.date = date
        self.location = location
        self.attendeeCount = attendeeCount
        self.maxAttendees = maxAttendees
        self.isRSVPRequired = isRSVPRequired
        self.organizerId = organizerId
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var isUpcoming: Bool {
        return date > Date()
    }
}