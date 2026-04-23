# Technical Plan: bind-login-api

> Status: **Draft — awaiting approval**

---

## 1. Overview

Replace `MockAuthService` with `RemoteAuthService`, which POSTs to `http://localhost:5000/api/v1/auth/login` via `URLSession`. On success the JWT token and `User` object are persisted to `UserDefaults`. `AuthViewModel` reads from the service on init (session restore) and after login (populates `currentUser`). The `AuthService` protocol is extended with read properties and a `logout()` method; the `Void` return signature on `login()` is unchanged.

---

## 2. Architecture Decisions

### 2.1 `AuthService` stores internally — `Void` login signature preserved

`RemoteAuthService` writes token + user to `UserDefaults` internally. Callers read back state via `currentUser: User?` and `token: String?` protocol properties. This avoids changing `LoginViewModel.login() async -> Bool` and keeps the existing `.task(id:)` flow in `LoginView` intact.

### 2.2 Session restoration at app launch

`AuthViewModel.init()` reads `authService.token` and `authService.currentUser` immediately. If a token exists the user is marked authenticated without re-entering credentials. This replaces the v1 limitation noted in `add-login-screen/plan.md §9`.

### 2.3 `AuthViewModel.didLoginSuccessfully()` as the coordination point

After `LoginViewModel.login()` returns `true`, `LoginView` currently sets `authViewModel.isAuthenticated = true`. This call is changed to `authViewModel.didLoginSuccessfully()`, which sets both `isAuthenticated` and `currentUser` from the service in one step. No logic leaks into the View.

### 2.4 `logout()` on `AuthService` protocol

Keeps the `UserDefaults` key names (`auth.token`, `auth.user`) inside the service — `AuthViewModel.logout()` delegates to `authService.logout()` rather than knowing storage details.

### 2.5 `NSAllowsArbitraryLoads` scoped to localhost only

`NSAllowsArbitraryLoads: true` is the simplest ATS override for local development and avoids XPC/entitlement complexity. A more targeted `NSExceptionDomains` entry for `localhost` is equally valid but adds noise for dev-only config. Revisit before App Store submission.

### 2.6 No shared `NetworkService` yet

`RemoteAuthService` owns its own `URLSession.shared` usage. A shared `APIClient` (for token injection into task CRUD headers) is deferred to the next change.

---

## 3. Final Type Contracts

### `User` — new
```swift
struct User: Codable, Equatable {
    let id: String
    let name: String
    let email: String
}
```

### `AppConfig` — new
```swift
enum AppConfig {
    static let baseURL = "http://localhost:5000/api/v1"
}
```

### `AuthService` protocol — extended (no breaking signature change)
```swift
protocol AuthService {
    func login(email: String, password: String) async throws  // Void — unchanged
    func logout()
    var currentUser: User? { get }
    var token: String? { get }
}
```

### `AuthError` — extended
```swift
enum AuthError: LocalizedError {
    case emptyFields
    case invalidEmailFormat
    case invalidCredentials
    case network(String)   // ← new: HTTP / decoding failures
}
```

### `RemoteAuthService` — new
```swift
final class RemoteAuthService: AuthService {
    // Private response shapes
    private struct LoginResponse: Decodable { let success: Bool; let token: String; let user: User }
    private struct APIErrorResponse: Decodable { let success: Bool; let message: String }
    private enum Keys { static let token = "auth.token"; static let user = "auth.user" }

    func login(email: String, password: String) async throws  // POSTs, stores on success
    func logout()                                              // removes UserDefaults keys
    var currentUser: User? { get }                            // decodes from UserDefaults
    var token: String? { get }                                // reads from UserDefaults
}
```

### `MockAuthService` — updated to satisfy extended protocol
```swift
final class MockAuthService: AuthService {
    func login(email: String, password: String) async throws { /* existing validation */ }
    func logout() {}
    var currentUser: User? { nil }
    var token: String? { nil }
}
```

### `AuthViewModel` — updated
```swift
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool   // restored from authService.token on init
    @Published var currentUser: User?      // restored from authService.currentUser on init

    private let authService: AuthService

    init(authService: AuthService = RemoteAuthService())
    func didLoginSuccessfully()  // sets isAuthenticated = true, currentUser = authService.currentUser
    func logout()                // delegates to authService.logout(), resets published state
}
```

### `LoginViewModel` — one line change
```swift
// Before:
init(authService: AuthService = MockAuthService())
// After:
init(authService: AuthService = RemoteAuthService())
```

---

## 4. File Map

### 4.1 New files

```
TodoApp/
  Models/
    User.swift                  ← User struct (Codable, Equatable)
  Services/
    RemoteAuthService.swift     ← URLSession-based AuthService + UserDefaults persistence
  Utilities/                    ← new folder
    AppConfig.swift             ← baseURL constant
```

### 4.2 Modified files

```
TodoApp/Services/AuthService.swift          ← extend protocol + AuthError + MockAuthService
TodoApp/ViewModels/AuthViewModel.swift      ← inject AuthService; add currentUser; session restore
TodoApp/ViewModels/LoginViewModel.swift     ← default service → RemoteAuthService()
TodoApp/Views/LoginView.swift               ← line 108: isAuthenticated=true → didLoginSuccessfully()
TodoApp/Info.plist                          ← add NSAppTransportSecurity block
TodoApp.xcodeproj/project.pbxproj          ← register User.swift, RemoteAuthService.swift, AppConfig.swift
TodoAppTests/LoginViewModelTests.swift      ← add 3 protocol members to AlwaysSucceedAuthService,
                                              AlwaysFailAuthService, SlowAuthService
```

---

## 5. Implementation Steps (ordered)

### Phase 1 — Models & Config (no dependencies)

- **1.1** Create `TodoApp/Models/User.swift` — `User: Codable, Equatable`
- **1.2** Create `TodoApp/Utilities/AppConfig.swift` — `AppConfig.baseURL`
- **1.3** Extend `AuthError` in `AuthService.swift` — add `case network(String)` with `errorDescription`

### Phase 2 — Protocol Extension (breaks `MockAuthService` and test mocks)

- **2.1** Extend `AuthService` protocol — add `logout()`, `currentUser`, `token`
- **2.2** Update `MockAuthService` — add `logout() {}`, `currentUser { nil }`, `token { nil }`
- **2.3** Update test mocks in `LoginViewModelTests.swift` — same three additions to `AlwaysSucceedAuthService`, `AlwaysFailAuthService`, `SlowAuthService`

> **Checkpoint:** Build must pass before Phase 3.

### Phase 3 — Remote Service

- **3.1** Create `TodoApp/Services/RemoteAuthService.swift`
  - `login()`: build `URLRequest` (POST, JSON body, `Content-Type: application/json`), call `URLSession.shared.data(for:)`, decode success → store to `UserDefaults`, decode error → throw `AuthError.invalidCredentials` with raw `message`, HTTP/decode failures → throw `AuthError.network(...)`
  - `logout()`: remove `UserDefaults` keys `auth.token` and `auth.user`
  - `currentUser`: decode `auth.user` from `UserDefaults` using `JSONDecoder`
  - `token`: return `UserDefaults.standard.string(forKey: "auth.token")`

### Phase 4 — ViewModel & View Wiring

- **4.1** Update `AuthViewModel` — inject `AuthService`, restore session in `init`, add `didLoginSuccessfully()`, update `logout()`
- **4.2** Update `LoginViewModel` — change default `authService` to `RemoteAuthService()`
- **4.3** Update `LoginView` line 108 — replace `authViewModel.isAuthenticated = true` with `authViewModel.didLoginSuccessfully()`

### Phase 5 — ATS & Project File

- **5.1** Add to `Info.plist`:
  ```xml
  <key>NSAppTransportSecurity</key>
  <dict>
      <key>NSAllowsArbitraryLoads</key>
      <true/>
  </dict>
  ```
- **5.2** Register `User.swift`, `RemoteAuthService.swift`, `AppConfig.swift` in `project.pbxproj` (PBXBuildFile + PBXFileReference + group children + Sources build phase)

---

## 6. UserDefaults Key Reference

| Key | Type | Content |
|-----|------|---------|
| `auth.token` | `String` | Raw JWT string |
| `auth.user` | `Data` | JSON-encoded `User` |

---

## 7. Network Contract

```
POST http://localhost:5000/api/v1/auth/login
Headers: Content-Type: application/json
Body:   { "email": "abc@gmail.com", "password": "12345678" }

Success HTTP 2xx:
{ "success": true, "token": "<jwt>", "user": { "id": "...", "name": "abc", "email": "abc@gmail.com" } }

Error (non-2xx):
{ "success": false, "message": "Invalid credentials" }
```

Error handling priority in `RemoteAuthService.login()`:
1. Network/transport failure → `AuthError.network(error.localizedDescription)`
2. Non-2xx + decodable `APIErrorResponse` → `AuthError.network(response.message)`
3. Non-2xx + undecodable body → `AuthError.network("Unexpected server error")`

---

## 8. Test Impact

### Existing tests — no logic changes needed
All 20 tests in `LoginViewModelTests.swift` pass mock services via `init(authService:)`. Adding protocol members to the three mock classes is the only change; test assertions remain identical.

### New tests to add (in `LoginViewModelTests.swift`)
These cover the extended `AuthViewModel` behaviour:

| Test | Assertion |
|------|-----------|
| `test_authViewModel_init_tokenNil_notAuthenticated` | `isAuthenticated == false` when service returns `nil` token |
| `test_authViewModel_init_tokenPresent_isAuthenticated` | `isAuthenticated == true` when service returns a token |
| `test_authViewModel_didLoginSuccessfully_setsCurrentUser` | `currentUser` populated from service after `didLoginSuccessfully()` |
| `test_authViewModel_logout_clearsState` | `isAuthenticated == false`, `currentUser == nil` after `logout()` |

---

## 9. Reuse of Existing Patterns

| Existing pattern | Applied here |
|-----------------|--------------|
| `JSONEncoder/JSONDecoder` in `JSONTaskRepository` | Same for encoding `User` to `UserDefaults` |
| `AuthService` protocol injection in `LoginViewModel` | Extended; same DI pattern for `AuthViewModel` |
| `@MainActor` + `@Published` in `LoginViewModel` | Unchanged |
| `.task(id:)` workaround for `Task` name conflict | Unchanged in `LoginView` |

---

## 10. Quality Gates

```bash
# 1. Build (after each phase)
xcodebuild build -scheme TodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"

# 2. All tests (after Phase 4)
xcodebuild test -scheme TodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
# Expected: ** TEST SUCCEEDED ** (24 tests: 20 existing + 4 new)

# 3. Lint
swiftlint
```

---

## 11. Out of Scope

- Keychain storage (UserDefaults chosen per decision)
- Token refresh / expiry
- Shared `APIClient` for authenticated task CRUD requests
- Register / forgot-password API endpoints
- Biometric auth
