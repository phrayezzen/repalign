import SwiftUI

struct UserTypeSelectionView: View {
    let onContinue: (String) -> Void

    @State private var selectedType: UserTypeOption? = nil
    @State private var isLoading = false

    enum UserTypeOption: String, CaseIterable {
        case voter = "citizen"
        case electedOfficial = "legislator"
        case advocacyOrganization = "organization"

        var displayTitle: String {
            switch self {
            case .voter: return "Voter"
            case .electedOfficial: return "Elected Official"
            case .advocacyOrganization: return "Advocacy Organization"
            }
        }

        var description: String {
            switch self {
            case .voter: return "Stay informed and engaged in your community"
            case .electedOfficial: return "Connect with constituents and share updates"
            case .advocacyOrganization: return "Mobilize supporters and drive change"
            }
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Title
            VStack(spacing: 8) {
                Text("What brings you here?")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Choose your role to get personalized content and features.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            // User Type Cards
            VStack(spacing: 16) {
                ForEach(UserTypeOption.allCases, id: \.self) { userType in
                    UserTypeCard(
                        userType: userType,
                        isSelected: selectedType == userType,
                        onTap: {
                            selectedType = userType
                        }
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue Button
            Button(action: handleContinue) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }

                    Text("Continue")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedType != nil && !isLoading ? Color.red : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(selectedType == nil || isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func handleContinue() {
        guard let selected = selectedType else { return }
        isLoading = true
        onContinue(selected.rawValue)
    }
}

struct UserTypeCard: View {
    let userType: UserTypeSelectionView.UserTypeOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                Text(userType.displayTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(userType.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(isSelected ? Color.red.opacity(0.9) : Color.black)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    UserTypeSelectionView(onContinue: { _ in })
}
