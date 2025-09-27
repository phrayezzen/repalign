import SwiftUI

struct ProfileAvatarView: View {
    let user: User
    let size: CGFloat

    var body: some View {
        if let profileImageURL = user.profileImageURL {
            AsyncImage(url: URL(string: profileImageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                initialsView
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initials: String {
        let names = user.displayName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1) + names[1].prefix(1))
        } else if let firstName = names.first {
            return String(firstName.prefix(2))
        }
        return "U"
    }

    private var gradientColors: [Color] {
        let hash = abs(user.id.hashValue)
        let colorSets: [[Color]] = [
            [.purple, .blue],
            [.blue, .cyan],
            [.green, .blue],
            [.orange, .red],
            [.pink, .purple],
            [.indigo, .purple],
            [.mint, .cyan],
            [.teal, .blue]
        ]
        return colorSets[hash % colorSets.count]
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileAvatarView(
            user: MockDataProvider.createMockUsers()[0],
            size: 80
        )

        ProfileAvatarView(
            user: MockDataProvider.createMockUsers()[1],
            size: 60
        )

        ProfileAvatarView(
            user: MockDataProvider.createMockUsers()[2],
            size: 40
        )
    }
    .padding()
}