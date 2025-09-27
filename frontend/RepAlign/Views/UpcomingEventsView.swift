import SwiftUI

struct UpcomingEventsView: View {
    let events: [Event]

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            eventsList
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var headerSection: some View {
        HStack {
            Text("Upcoming Events")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()
        }
    }

    private var eventsList: some View {
        VStack(spacing: 16) {
            let upcomingEvents = events.filter { $0.isUpcoming }.prefix(3)

            ForEach(Array(upcomingEvents), id: \.id) { event in
                EventRowView(event: event)
            }

            if upcomingEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            }
        }
    }
}

struct EventRowView: View {
    let event: Event
    @State private var isRSVPed = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Image(systemName: eventIcon)
                        .font(.title3)
                        .foregroundColor(eventColor)

                    Text(dayOfWeek)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(event.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(event.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if event.attendeeCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(event.attendeeCount) people attending")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                if event.isRSVPRequired {
                    Button(action: { isRSVPed.toggle() }) {
                        Text(isRSVPed ? "RSVP'd" : "RSVP")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isRSVPed ? Color.green : Color.red)
                            .cornerRadius(6)
                    }
                }
            }

            Divider()
                .opacity(0.5)
        }
    }

    private var eventIcon: String {
        switch event.type {
        case .townHall: return "building.2"
        case .forum: return "person.3"
        case .meeting: return "calendar"
        case .rally: return "megaphone"
        case .debate: return "bubble.left.and.bubble.right"
        case .conference: return "person.2.badge.gearshape"
        }
    }

    private var eventColor: Color {
        switch event.type {
        case .townHall: return .blue
        case .forum: return .green
        case .meeting: return .orange
        case .rally: return .red
        case .debate: return .purple
        case .conference: return .indigo
        }
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: event.date)
    }
}

#Preview {
    let mockEvents = MockDataProvider.createMockEvents()

    return UpcomingEventsView(events: mockEvents)
        .padding()
        .background(Color(.systemGroupedBackground))
}