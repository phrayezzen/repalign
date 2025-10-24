import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var usernameOrEmail = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingRegister = false
    @State private var selectedBackend = AppConfig.shared.backendEnvironment

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("RepAlign")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Your voice in civic engagement")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)

                // Login Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username or Email")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Enter your username or email", text: $usernameOrEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
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
                }

                // Login Button
                Button(action: handleLogin) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }

                        Text("Log In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(loginButtonColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!isFormValid || authService.isLoading)

                // Register Link
                HStack {
                    Text("Need an account?")
                        .foregroundColor(.secondary)

                    Button("Sign up") {
                        showingRegister = true
                    }
                    .foregroundColor(.red)
                    .fontWeight(.medium)
                }

                Spacer()

                // Backend Toggle (temporary dev tool)
                VStack(spacing: 8) {
                    Text("Backend: \(selectedBackend.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: toggleBackend) {
                        Text("Switch to \(nextBackend.rawValue)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }

    private var isFormValid: Bool {
        !usernameOrEmail.isEmpty && !password.isEmpty
    }

    private var loginButtonColor: Color {
        isFormValid && !authService.isLoading ? .red : .gray
    }

    private func handleLogin() {
        Task {
            do {
                try await authService.login(usernameOrEmail: usernameOrEmail, password: password)
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }

    private var nextBackend: BackendEnvironment {
        selectedBackend == .ngrok ? .railway : .ngrok
    }

    private func toggleBackend() {
        selectedBackend = nextBackend
        AppConfig.shared.backendEnvironment = selectedBackend
    }
}

#Preview {
    LoginView()
}