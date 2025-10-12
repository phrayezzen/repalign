import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case userType = 1
    case location = 2
    case interests = 3

    var title: String {
        switch self {
        case .userType: return "Choose Your Role"
        case .location: return "Location"
        case .interests: return "Your Interests"
        }
    }
}

struct OnboardingCoordinator: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var currentStep: OnboardingStep = .userType
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicators
                ProgressIndicatorView(currentStep: currentStep.rawValue, totalSteps: 4)
                    .padding(.top, 8)

                // Current Step View
                Group {
                    switch currentStep {
                    case .userType:
                        UserTypeSelectionView(onContinue: handleUserTypeSelection)
                    case .location:
                        LocationSelectionView(onContinue: handleLocationSelection)
                    case .interests:
                        InterestsSelectionView(onComplete: handleInterestsComplete, onSkip: handleSkip)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func handleUserTypeSelection(userType: String) {
        Task {
            do {
                try await authService.updateUserType(userType: userType)
                await MainActor.run {
                    withAnimation {
                        currentStep = .location
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func handleLocationSelection(state: String, district: String?, city: String) {
        Task {
            do {
                try await authService.updateLocation(state: state, congressionalDistrict: district, city: city)
                await MainActor.run {
                    withAnimation {
                        currentStep = .interests
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func handleInterestsComplete(causes: [String]) {
        Task {
            do {
                try await authService.updateInterests(causes: causes)
                try await authService.completeOnboarding()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func handleSkip() {
        // Allow skipping interests - just dismiss
        dismiss()
    }
}

struct ProgressIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep + 1 ? Color.red : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    OnboardingCoordinator()
}
