import Foundation

// MARK: - AuthViewModel

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool
    @Published var currentUser: User?

    private let authService: AuthService

    init(authService: AuthService = RemoteAuthService()) {
        self.authService = authService
        self.isAuthenticated = authService.token != nil
        self.currentUser = authService.currentUser
    }

    func didLoginSuccessfully() {
        isAuthenticated = true
        currentUser = authService.currentUser
    }

    func logout() {
        authService.logout()
        isAuthenticated = false
        currentUser = nil
    }
}
