## Phase 1: Foundation

_Standalone types and config. No cross-dependencies — all three tasks can be written in parallel._

- [ ] 1.1 Create `TodoApp/Models/User.swift` — `struct User: Codable, Equatable` with `let id: String`, `let name: String`, `let email: String`
- [ ] 1.2 Create `TodoApp/Utilities/AppConfig.swift` — `enum AppConfig { static let baseURL = "http://localhost:5000/api/v1" }`
- [ ] 1.3 Extend `AuthError` in `TodoApp/Services/AuthService.swift` — add `case network(String)` with `errorDescription` returning the associated string value

**Phase 1 checkpoint:**
```bash
xcodebuild build -scheme TodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

---

## Phase 2: Protocol Extension

_Extends `AuthService` with new members. Must complete before Phase 3 (RemoteAuthService requires the full protocol)._
_Tasks 2.1–2.3 touch different files — write in parallel, compile together._

- [ ] 2.1 Extend `AuthService` protocol in `TodoApp/Services/AuthService.swift` — add `func logout()`, `var currentUser: User? { get }`, `var token: String? { get }`
- [ ] 2.2 Update `MockAuthService` in `TodoApp/Services/AuthService.swift` — add `func logout() {}`, `var currentUser: User? { nil }`, `var token: String? { nil }`
- [ ] 2.3 Update test mock stubs in `TodoAppTests/LoginViewModelTests.swift` — add `func logout() {}`, `var currentUser: User? { nil }`, `var token: String? { nil }` to `AlwaysSucceedAuthService`, `AlwaysFailAuthService`, and `SlowAuthService`

**Phase 2 checkpoint:**
```bash
xcodebuild build -scheme TodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
# Must pass with 0 errors before proceeding — Phase 3 depends on the full protocol
```

---

## Phase 3: Remote Service

_Single file, no parallel sub-tasks. Depends on Phase 1 (`User`, `AppConfig`) and Phase 2 (full `AuthService` protocol)._

- [ ] 3.1 Create `TodoApp/Services/RemoteAuthService.swift` — `final class RemoteAuthService: AuthService`:
  - Private nested types: `LoginResponse: Decodable` (`success`, `token`, `user: User`), `APIErrorResponse: Decodable` (`success`, `message`), `Keys` enum (`token = "auth.token"`, `user = "auth.user"`)
  - `login(email:password:)`: build POST `URLRequest` to `AppConfig.baseURL + "/auth/login"` with JSON body `{"email":…,"password":…}` and `Content-Type: application/json`; call `URLSession.shared.data(for:)`; on transport error throw `AuthError.network(error.localizedDescription)`; on non-2xx + decodable `APIErrorResponse` throw `AuthError.network(response.message)`; on non-2xx + undecodable body throw `AuthError.network("Unexpected server error")`; on success decode `LoginResponse`, write `token` string to `UserDefaults["auth.token"]` and JSON-encoded `user` `Data` to `UserDefaults["auth.user"]`
  - `logout()`: `UserDefaults.standard.removeObject(forKey: Keys.token)` and `Keys.user`
  - `var token: String?`: `UserDefaults.standard.string(forKey: Keys.token)`
  - `var currentUser: User?`: read `Data` from `UserDefaults[Keys.user]`, decode with `JSONDecoder`, return `nil` on failure

**Phase 3 checkpoint:**
```bash
xcodebuild build -scheme TodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

---

## Phase 4: ViewModel & View Wiring [PARALLEL]

_4A and 4B touch different files and have no inter-dependency — implement in parallel. 4C depends on 4A._

### 4A. AuthViewModel [PARALLEL]
- [ ] 4A.1 Add `private let authService: AuthService` to `TodoApp/ViewModels/AuthViewModel.swift`
- [ ] 4A.2 Add `@Published var currentUser: User?` to `AuthViewModel`
- [ ] 4A.3 Change `init` to `init(authService: AuthService = RemoteAuthService())` — set `isAuthenticated = authService.token != nil` and `currentUser = authService.currentUser` to restore session on launch
- [ ] 4A.4 Add `func didLoginSuccessfully()` — sets `isAuthenticated = true` and `currentUser = authService.currentUser`
- [ ] 4A.5 Update `func logout()` — call `authService.logout()`, then set `isAuthenticated = false` and `currentUser = nil`

### 4B. LoginViewModel [PARALLEL]
- [ ] 4B.1 Change default argument in `TodoApp/ViewModels/LoginViewModel.swift` `init` from `MockAuthService()` to `RemoteAuthService()`

### 4C. LoginView (depends on 4A)
- [ ] 4C.1 In `TodoApp/Views/LoginView.swift` line 108: replace `authViewModel.isAuthenticated = true` with `authViewModel.didLoginSuccessfully()`

**Phase 4 checkpoint:**
```bash
xcodebuild build -scheme TodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

---

## Phase 5: ATS & Project File Registration [PARALLEL]

_5.1 and 5.2 are independent._

- [ ] 5.1 Add to `TodoApp/Info.plist` (before closing `</dict>`):
  ```xml
  <key>NSAppTransportSecurity</key>
  <dict>
      <key>NSAllowsArbitraryLoads</key>
      <true/>
  </dict>
  ```
- [ ] 5.2 Register new source files in `TodoApp.xcodeproj/project.pbxproj`:
  - `User.swift` — PBXFileReference in `Models` group + PBXBuildFile + Sources build phase entry
  - `RemoteAuthService.swift` — PBXFileReference in `Services` group + PBXBuildFile + Sources build phase entry
  - `AppConfig.swift` — PBXFileReference in new `Utilities` group + PBXBuildFile + Sources build phase entry

**Phase 5 checkpoint:**
```bash
xcodebuild build -scheme TodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
# Expected: ** BUILD SUCCEEDED **
```

---

## Phase 6: Tests

_One test per spec scenario from `specs/api-login/spec.md`. All tests in `TodoAppTests/LoginViewModelTests.swift`._

Add a `StubAuthService` with configurable `token` and `currentUser` to support `AuthViewModel` tests:
```swift
final class StubAuthService: AuthService {
    var stubToken: String? = nil
    var stubUser: User? = nil
    func login(email: String, password: String) async throws {}
    func logout() { stubToken = nil; stubUser = nil }
    var token: String? { stubToken }
    var currentUser: User? { stubUser }
}
```

### Spec: JWT token persisted + session restoration
- [ ] 6.1 `test_authViewModel_init_tokenNil_notAuthenticated` — `StubAuthService(stubToken: nil)` → `authViewModel.isAuthenticated == false`
- [ ] 6.2 `test_authViewModel_init_tokenPresent_isAuthenticated` — `StubAuthService(stubToken: "abc")` → `authViewModel.isAuthenticated == true`
- [ ] 6.3 `test_authViewModel_init_tokenPresent_restoresCurrentUser` — `StubAuthService(stubToken: "abc", stubUser: User(id:"1", name:"X", email:"x@x.com"))` → `authViewModel.currentUser?.name == "X"`

### Spec: Logged-in user available app-wide
- [ ] 6.4 `test_authViewModel_didLoginSuccessfully_setsIsAuthenticated` — call `didLoginSuccessfully()` on stub with token → `isAuthenticated == true`
- [ ] 6.5 `test_authViewModel_didLoginSuccessfully_setsCurrentUser` — stub returns `User`; call `didLoginSuccessfully()` → `currentUser != nil` and matches stub user

### Spec: Token cleared on logout / user nil after logout
- [ ] 6.6 `test_authViewModel_logout_clearsIsAuthenticated` — authenticated state → call `logout()` → `isAuthenticated == false`
- [ ] 6.7 `test_authViewModel_logout_clearsCurrentUser` — `currentUser` set → call `logout()` → `currentUser == nil`

### Spec: Network / server error
- [ ] 6.8 `test_login_networkError_setsErrorMessage` — `AlwaysNetworkErrorAuthService` (throws `AuthError.network("timeout")`) → `login()` returns `false` and `vm.errorMessage == "timeout"`

Add `AlwaysNetworkErrorAuthService` stub:
```swift
final class AlwaysNetworkErrorAuthService: AuthService {
    func login(email: String, password: String) async throws {
        throw AuthError.network("timeout")
    }
    func logout() {}
    var currentUser: User? { nil }
    var token: String? { nil }
}
```

**Phase 6 checkpoint:**
```bash
xcodebuild test -scheme TodoApp \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro"
# Expected: ** TEST SUCCEEDED ** (28 tests: 20 existing + 8 new)

swiftlint
# Expected: 0 warnings, 0 errors
```
