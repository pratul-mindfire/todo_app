import Foundation

// MARK: - LoginViewModel

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: Published State

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showForgotPasswordAlert: Bool = false

    // MARK: Dependencies

    private let authService: AuthService

    // MARK: Init

    init(authService: AuthService = RemoteAuthService()) {
        self.authService = authService
    }

    // MARK: Computed

    var isLoginEnabled: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    var isEmailFormatInvalid: Bool {
        guard !email.isEmpty else { return false }
        return !isValidEmail(email)
    }

    // MARK: Actions

    func login() async -> Bool {
        guard isLoginEnabled else { return false }
        guard isValidEmail(email) else {
            errorMessage = AuthError.invalidEmailFormat.errorDescription
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.login(email: email, password: password)
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    func forgotPassword() {
        showForgotPasswordAlert = true
    }

    // MARK: Private

    private func isValidEmail(_ value: String) -> Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return value.range(of: regex, options: .regularExpression) != nil
    }
}
