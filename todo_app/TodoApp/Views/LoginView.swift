import SwiftUI

// MARK: - LoginView

struct LoginView: View {

    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var loginAttempt: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // MARK: Logo / Title
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                Text("TodoApp")
                    .font(.largeTitle.bold())
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 48)

            // MARK: Fields
            VStack(spacing: 16) {
                // Email
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    if viewModel.isEmailFormatInvalid {
                        Text("Please enter a valid email address.")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                    }
                }

                // Password
                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)

            // MARK: Error banner
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.red, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
            }

            // MARK: Forgot Password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    viewModel.forgotPassword()
                }
                .font(.footnote)
                .foregroundStyle(.blue)
                .padding(.trailing, 32)
                .padding(.top, 8)
            }

            // MARK: Login Button
            Button {
                loginAttempt += 1
            } label: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Login")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isLoginEnabled ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.isLoginEnabled || viewModel.isLoading)
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()
        }
        .task(id: loginAttempt) {
            guard loginAttempt > 0 else { return }
            let success = await viewModel.login()
            if success {
                authViewModel.didLoginSuccessfully()
            }
        }
        .alert("Feature Coming Soon", isPresented: $viewModel.showForgotPasswordAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Password reset will be available in a future update.")
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
