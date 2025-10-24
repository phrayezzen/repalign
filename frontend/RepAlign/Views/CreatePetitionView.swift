import SwiftUI

struct CreatePetitionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory = "Healthcare"
    @State private var targetSignatures = "10000"
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days from now
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let categories = [
        "Healthcare",
        "Education",
        "Environment",
        "Economy",
        "Justice",
        "Infrastructure",
        "Civil Rights",
        "Defense",
        "Other"
    ]

    private var isFormValid: Bool {
        !title.isEmpty &&
        title.count >= 10 &&
        !description.isEmpty &&
        description.count >= 50 &&
        !selectedCategory.isEmpty &&
        !targetSignatures.isEmpty &&
        Int(targetSignatures) ?? 0 >= 100
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)

                        Text("Create a Petition")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Rally support for your cause")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Form
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)

                            TextField("Enter a clear, compelling title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            HStack {
                                Text("\(title.count)/200")
                                    .font(.caption)
                                    .foregroundColor(title.count > 200 ? .red : .secondary)

                                Spacer()

                                if !title.isEmpty && title.count < 10 {
                                    Text("Minimum 10 characters")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)

                            TextEditor(text: $description)
                                .frame(height: 150)
                                .padding(4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )

                            HStack {
                                Text("\(description.count)/10000")
                                    .font(.caption)
                                    .foregroundColor(description.count > 10000 ? .red : .secondary)

                                Spacer()

                                if !description.isEmpty && description.count < 50 {
                                    Text("Minimum 50 characters")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)

                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button(category) {
                                        selectedCategory = category
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedCategory)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }

                        // Target Signatures
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Signatures")
                                .font(.headline)

                            TextField("e.g., 10000", text: $targetSignatures)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            if let target = Int(targetSignatures), target > 0 {
                                Text("Goal: \(formatNumber(target)) signatures")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if !targetSignatures.isEmpty, let target = Int(targetSignatures), target < 100 {
                                Text("Minimum 100 signatures required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        // Deadline Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $hasDeadline) {
                                Text("Set a deadline")
                                    .font(.headline)
                            }

                            if hasDeadline {
                                DatePicker(
                                    "Deadline",
                                    selection: $deadline,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Create Button
                    Button(action: handleCreatePetition) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }

                            Text("Create Petition")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isFormValid && !isLoading ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Petition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func handleCreatePetition() {
        guard isFormValid else { return }

        isLoading = true

        Task {
            do {
                let petition = PetitionService.CreatePetitionRequest(
                    title: title,
                    description: description,
                    category: selectedCategory,
                    targetSignatures: Int(targetSignatures) ?? 10000,
                    deadline: hasDeadline ? deadline : nil,
                    recipientLegislatorIds: nil
                )

                _ = try await PetitionService.shared.createPetition(petition: petition)

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

#Preview {
    CreatePetitionView()
}
