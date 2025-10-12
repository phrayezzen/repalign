import SwiftUI

struct InterestsSelectionView: View {
    let onComplete: ([String]) -> Void
    let onSkip: () -> Void

    @State private var selectedCauses: Set<CauseOption> = []
    @State private var isLoading = false

    enum CauseOption: String, CaseIterable {
        case climateEnvironment = "climate_environment"
        case housingDevelopment = "housing_development"
        case votingRights = "voting_rights"
        case healthcare = "healthcare"
        case education = "education"
        case transportation = "transportation"
        case workersRights = "workers_rights"
        case civilRights = "civil_rights"
        case governmentReform = "government_reform"
        case communitySafety = "community_safety"
        case economicJustice = "economic_justice"
        case immigration = "immigration"

        var displayName: String {
            switch self {
            case .climateEnvironment: return "Climate & Environment"
            case .housingDevelopment: return "Housing & Development"
            case .votingRights: return "Voting Rights"
            case .healthcare: return "Healthcare"
            case .education: return "Education"
            case .transportation: return "Transportation"
            case .workersRights: return "Workers Rights"
            case .civilRights: return "Civil Rights"
            case .governmentReform: return "Government Reform"
            case .communitySafety: return "Community Safety"
            case .economicJustice: return "Economic Justice"
            case .immigration: return "Immigration"
            }
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("What issues matter to you?")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Select at least 3 causes to personalize your feed.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)

                // Causes Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(CauseOption.allCases, id: \.self) { cause in
                        CauseCard(
                            cause: cause,
                            isSelected: selectedCauses.contains(cause),
                            onTap: {
                                if selectedCauses.contains(cause) {
                                    selectedCauses.remove(cause)
                                } else {
                                    selectedCauses.insert(cause)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Selection Counter
                HStack {
                    Text("Selected: \(selectedCauses.count) causes")
                        .font(.subheadline)
                        .foregroundColor(selectedCauses.count >= 3 ? .primary : .secondary)

                    if selectedCauses.count < 3 {
                        Text("(Select at least 3)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 8)

                // Complete Setup Button
                Button(action: handleComplete) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }

                        Text("Complete Setup")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedCauses.count >= 3 && !isLoading ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(selectedCauses.count < 3 || isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Skip Link
                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .disabled(isLoading)
                .padding(.bottom, 32)
            }
        }
    }

    private func handleComplete() {
        isLoading = true
        let causes = selectedCauses.map { $0.rawValue }
        onComplete(causes)
    }
}

struct CauseCard: View {
    let cause: InterestsSelectionView.CauseOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(cause.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .padding()
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
    InterestsSelectionView(onComplete: { _ in }, onSkip: {})
}
