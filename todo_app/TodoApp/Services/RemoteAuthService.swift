import Foundation

final class RemoteAuthService: AuthService {

    private struct LoginResponse: Decodable {
        let success: Bool
        let token: String
        let user: User
    }

    private struct APIErrorResponse: Decodable {
        let success: Bool
        let message: String
    }

    private enum Keys {
        static let token = "auth.token"
        static let user  = "auth.user"
    }

    // MARK: - AuthService

    func login(email: String, password: String) async throws {
        guard let url = URL(string: "\(AppConfig.baseURL)/auth/login") else {
            throw AuthError.network("Invalid server URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["email": email, "password": password])

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.network(error.localizedDescription)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if (200..<300).contains(statusCode) {
            guard let decoded = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
                throw AuthError.network("Unexpected server response")
            }
            UserDefaults.standard.set(decoded.token, forKey: Keys.token)
            if let userData = try? JSONEncoder().encode(decoded.user) {
                UserDefaults.standard.set(userData, forKey: Keys.user)
            }
        } else {
            if let errorBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw AuthError.network(errorBody.message)
            }
            throw AuthError.network("Unexpected server error")
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: Keys.token)
        UserDefaults.standard.removeObject(forKey: Keys.user)
    }

    var token: String? {
        UserDefaults.standard.string(forKey: Keys.token)
    }

    var currentUser: User? {
        guard let data = UserDefaults.standard.data(forKey: Keys.user) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }
}
