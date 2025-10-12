import SwiftUI

struct LocationSelectionView: View {
    let onContinue: (String, String?, String) -> Void

    @State private var selectedState: String = ""
    @State private var congressionalDistrict: String = ""
    @State private var city: String = ""
    @State private var isLoading = false

    // US States list
    private let states = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Title
                VStack(spacing: 16) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Where are you located?")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Help us show you relevant local issues and representatives.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)

                // Form Fields
                VStack(spacing: 20) {
                    // State Dropdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("State")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Menu {
                            ForEach(states, id: \.self) { state in
                                Button(state) {
                                    selectedState = state
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedState.isEmpty ? "Select your state" : selectedState)
                                    .foregroundColor(selectedState.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }

                    // Congressional District (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Congressional District")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("(Optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        TextField("e.g., District 5", text: $congressionalDistrict)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // City/Town
                    VStack(alignment: .leading, spacing: 8) {
                        Text("City/Town")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Enter your city or town", text: $city)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)

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
                    .background(isFormValid && !isLoading ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!isFormValid || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var isFormValid: Bool {
        !selectedState.isEmpty && !city.isEmpty
    }

    private func handleContinue() {
        isLoading = true
        let district = congressionalDistrict.isEmpty ? nil : congressionalDistrict
        onContinue(selectedState, district, city)
    }
}

#Preview {
    LocationSelectionView(onContinue: { _, _, _ in })
}
