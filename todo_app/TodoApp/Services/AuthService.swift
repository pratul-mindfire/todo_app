import Foundation

// MARK: - AuthError

enum AuthError: LocalizedError {
    case emptyFields
    case invalidEmailFormat
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Email and password are required."
        case .invalidEmailFormat:
            return "Please enter a valid email address."
        case .invalidCredentials:
            return "Incorrect email or password."
        }
    }
}

// MARK: - AuthService

protocol AuthService {
    func login(email: String, password: String) async throws
}

// MARK: - MockAuthService

final class MockAuthService: AuthService {
    func login(email: String, password: String) async throws {
        // Simulate async work without blocking
        guard !email.isEmpty, !password.isEmpty else { throw AuthError.emptyFields }
    }
}
