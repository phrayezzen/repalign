import SwiftUI

struct LevelBadgeView: View {
    let level: Int
    let isLegislator: Bool

    init(level: Int, isLegislator: Bool = false) {
        self.level = level
        self.isLegislator = isLegislator
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: 44, height: 44)

                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(isLegislator ? "Level \(level)" : "Level \(level)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }

    private var backgroundGradient: LinearGradient {
        if isLegislator {
            return LinearGradient(
                colors: legislatorGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: citizenGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var citizenGradientColors: [Color] {
        switch level {
        case 1...2:
            return [.gray, .gray.opacity(0.7)]
        case 3...4:
            return [.orange, .yellow]
        case 5...6:
            return [.blue, .cyan]
        case 7...8:
            return [.purple, .pink]
        case 9...10:
            return [.orange, .red]
        default:
            return [.gray, .gray.opacity(0.7)]
        }
    }

    private var legislatorGradientColors: [Color] {
        let score = Double(level * 10)
        switch score {
        case 80...100:
            return [.green, .mint]
        case 60..<80:
            return [.orange, .yellow]
        default:
            return [.red, .pink]
        }
    }

    private var iconName: String {
        if isLegislator {
            let score = Double(level * 10)
            switch score {
            case 80...100:
                return "target"
            case 60..<80:
                return "scope"
            default:
                return "dot.scope"
            }
        } else {
            switch level {
            case 1...2:
                return "person"
            case 3...4:
                return "person.badge.plus"
            case 5...6:
                return "person.2"
            case 7...8:
                return "crown"
            case 9...10:
                return "star.fill"
            default:
                return "person"
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            LevelBadgeView(level: 3)
            LevelBadgeView(level: 6)
            LevelBadgeView(level: 9)
        }

        HStack(spacing: 20) {
            LevelBadgeView(level: 5, isLegislator: true)
            LevelBadgeView(level: 8, isLegislator: true)
            LevelBadgeView(level: 10, isLegislator: true)
        }
    }
    .padding()
}