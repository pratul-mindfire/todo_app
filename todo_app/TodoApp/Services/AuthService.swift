import Foundation

// MARK: - AuthError

enum AuthError: LocalizedError {
    case emptyFields
    case invalidEmailFormat
    case invalidCredentials
    case network(String)

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Email and password are required."
        case .invalidEmailFormat:
            return "Please enter a valid email address."
        case .invalidCredentials:
            return "Incorrect email or password."
        case .network(let message):
            return message
        }
    }
}

// MARK: - AuthService

protocol AuthService {
    func login(email: String, password: String) async throws
    func logout()
    var currentUser: User? { get }
    var token: String? { get }
}

// MARK: - MockAuthService

final class MockAuthService: AuthService {
    func login(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else { throw AuthError.emptyFields }
    }
    func logout() {}
    var currentUser: User? { nil }
    var token: String? { nil }
}
