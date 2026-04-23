## Why

The login screen currently uses `MockAuthService` which accepts any non-empty credentials without touching a real backend. This change wires it to the real REST API at `http://localhost:5000/api/v1/auth/login`, persists the returned JWT token and user info via `UserDefaults`, and enables the app to act on authenticated identity (current user's name/email accessible app-wide).

## What Changes

### New Files

- `TodoApp/Models/User.swift` — `User` struct (`id`, `name`, `email`) conforming to `Codable`
- `TodoApp/Services/RemoteAuthService.swift` — concrete `AuthService` impl; calls API, persists token + user to `UserDefaults`
- `TodoApp/Utilities/AppConfig.swift` — holds `baseURL = "http://localhost:5000/api/v1"` (single place to swap for staging/prod)

### Modified Files

- `TodoApp/Services/AuthService.swift`
  - `AuthService` protocol keeps `func login(email:password:) async throws` → `Void` (no signature change)
  - Extend protocol with two read properties: `var currentUser: User? { get }` and `var token: String? { get }`
  - `MockAuthService` updated to satisfy new properties (returns `nil`)
  - Add `network` case to `AuthError` for HTTP/decoding failures

- `TodoApp/ViewModels/AuthViewModel.swift`
  - Inject `AuthService` dependency
  - Expose `@Published var currentUser: User?` (read from `authService.currentUser` after login)
  - `isAuthenticated` derived from whether a token exists in `authService`
  - `logout()` clears `UserDefaults` token + user and resets published state

- `TodoApp/ViewModels/LoginViewModel.swift`
  - Default injected service switches from `MockAuthService()` to `RemoteAuthService()`

- `TodoApp/Info.plist`
  - Add `NSAppTransportSecurity` → `NSAllowsArbitraryLoads: true` to allow HTTP on localhost

### Protocol Contract (unchanged signature, extended)

```swift
protocol AuthService {
    func login(email: String, password: String) async throws  // Void — unchanged
    var currentUser: User? { get }
    var token: String? { get }
}
```

### API Contract

```
POST http://localhost:5000/api/v1/auth/login
Body:  { "email": "abc@gmail.com", "password": "12345678" }

Success 200:
{
  "success": true,
  "token": "<jwt>",
  "user": { "id": "...", "name": "abc", "email": "abc@gmail.com" }
}

Error (any non-2xx):
{ "success": false, "message": "Invalid credentials" }
```

- HTTP error `message` is surfaced directly as `errorMessage` in `LoginViewModel`
- Token and user are stored to `UserDefaults` keys `auth.token` and `auth.user` (JSON-encoded)

## Capabilities

### New Capabilities

- `api-login`: Real HTTP authentication with JWT token and user persistence via `UserDefaults`

### Modified Capabilities

- `user-login`: `AuthService` protocol extended with `currentUser` and `token` read properties; `LoginViewModel` default wired to `RemoteAuthService`

## Non-Goals

- Keychain storage (deferred — UserDefaults chosen for simplicity)
- Shared `NetworkService` / token injection for other API calls (deferred to task CRUD change)
- Token refresh / expiry handling
- Register / forgot-password API integration

## Impact

- New files: `User.swift`, `RemoteAuthService.swift`, `AppConfig.swift`
- Modified files: `AuthService.swift`, `AuthViewModel.swift`, `LoginViewModel.swift`, `Info.plist`
- Existing `MockAuthService` remains valid (used in tests); no test breakage expected
- `LoginViewModelTests.swift` will need `MockAuthService` updated to satisfy new protocol properties
