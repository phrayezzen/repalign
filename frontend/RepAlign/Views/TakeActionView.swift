import SwiftUI

struct TakeActionView: View {
    @State private var showingCreateEvent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Banner
                headerBanner

                // Register to Vote Section
                registerToVoteSection
                    .padding(.horizontal, 20)
                    .padding(.top, -30)

                // Action Cards Grid
                actionCardsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 30)

                // Why Take Action Section
                whyTakeActionSection
                    .padding(.horizontal, 20)
                    .padding(.top, 40)

                // Statistics Section
                statisticsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView()
        }
    }

    private var headerBanner: some View {
        ZStack {
            Color.red
                .frame(height: 280)

            VStack(spacing: 16) {
                Spacer()

                Text("Take Action")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Make your voice heard in your community")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(.top, 80)
        }
    }

    private var registerToVoteSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.square.filled.and.at.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Register To Vote & Find Your Polling Location")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Text("Get registered, find your polling place, and make your voice heard.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button(action: {
                // TODO: Implement register to vote action
            }) {
                Text("Get Started")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 30)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
    }

    private var actionCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            ActionCard(
                title: "Contact Your Rep",
                description: "Send a message to your representatives.",
                icon: "envelope.fill",
                iconColor: .blue,
                backgroundColor: Color.blue.opacity(0.1)
            )

            ActionCard(
                title: "Create Petition",
                description: "Start a petition for change in your community.",
                icon: "heart.fill",
                iconColor: .pink,
                backgroundColor: Color.pink.opacity(0.1)
            )

            ActionCard(
                title: "Plan Event",
                description: "Organize a town hall or community meeting.",
                icon: "calendar",
                iconColor: .green,
                backgroundColor: Color.green.opacity(0.1),
                action: { showingCreateEvent = true }
            )

            ActionCard(
                title: "Launch Fundraiser",
                description: "Raise funds for your civic initiative.",
                icon: "dollarsign.circle.fill",
                iconColor: .purple,
                backgroundColor: Color.purple.opacity(0.1)
            )
        }
    }

    private var whyTakeActionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Take Action?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Your voice matters in democracy. Whether it's contacting representatives, starting petitions, organizing events, or fundraising for causes, every action contributes to positive change in your community.")
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }

    private var statisticsSection: some View {
        HStack(spacing: 0) {
            StatisticView(number: "1.2K", label: "Messages Sent")

            Spacer()

            StatisticView(number: "847", label: "Petitions Created")

            Spacer()

            StatisticView(number: "234", label: "Events Organized")
        }
    }
}

struct ActionCard: View {
    let title: String
    let description: String
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let action: (() -> Void)?

    init(title: String, description: String, icon: String, iconColor: Color, backgroundColor: Color, action: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.icon = icon
        self.iconColor = iconColor
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40)
                        .background(backgroundColor)
                        .cornerRadius(8)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                Button(action: {
                    action?()
                }) {
                    Text(getButtonText())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.red)
                        .cornerRadius(18)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func getButtonText() -> String {
        switch title {
        case "Contact Your Rep":
            return "Contact"
        case "Create Petition":
            return "Create"
        case "Plan Event":
            return "Plan"
        case "Launch Fundraiser":
            return "Launch"
        default:
            return "Start"
        }
    }
}

struct StatisticView: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.red)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    TakeActionView()
}