import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var username = ""
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingOnboarding = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)

                        Text("Join RepAlign")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Make your voice heard in civic engagement")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Registration Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("Enter your full name", text: $fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("Choose a username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.primary)

                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.primary)

                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.headline)
                                .foregroundColor(.primary)

                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    // Password Requirements
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password must contain:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(password.count >= 8 ? .green : .secondary)
                                .font(.caption)
                            Text("At least 8 characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: hasUppercase ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasUppercase ? .green : .secondary)
                                .font(.caption)
                            Text("One uppercase letter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: hasLowercase ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasLowercase ? .green : .secondary)
                                .font(.caption)
                            Text("One lowercase letter")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: hasNumber ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasNumber ? .green : .secondary)
                                .font(.caption)
                            Text("One number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: hasSpecialChar ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(hasSpecialChar ? .green : .secondary)
                                .font(.caption)
                            Text("One special character")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Register Button
                    Button(action: handleRegister) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }

                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(registerButtonColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(!isFormValid || authService.isLoading)

                    // Terms and Privacy
                    Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingCoordinator()
        }
    }

    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !username.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword &&
        hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecialChar
    }

    private var hasUppercase: Bool {
        password.range(of: "[A-Z]", options: .regularExpression) != nil
    }

    private var hasLowercase: Bool {
        password.range(of: "[a-z]", options: .regularExpression) != nil
    }

    private var hasNumber: Bool {
        password.range(of: "[0-9]", options: .regularExpression) != nil
    }

    private var hasSpecialChar: Bool {
        password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
    }

    private var registerButtonColor: Color {
        isFormValid && !authService.isLoading ? .red : .gray
    }

    private func handleRegister() {
        Task {
            do {
                try await authService.register(
                    username: username,
                    email: email,
                    password: password,
                    displayName: fullName
                )
                await MainActor.run {
                    // After successful registration, proceed to onboarding
                    showingOnboarding = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    RegisterView()
}