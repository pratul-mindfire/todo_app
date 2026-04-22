import Foundation

// MARK: - AuthViewModel

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false

    func logout() {
        isAuthenticated = false
    }
}
