# Technical Plan: add-login-screen

> Status: **Implemented** — this plan documents what was built and serves as the architectural record.

---

## 1. Overview

Introduce a login screen as the conditional app entry point. Any user who is not authenticated sees `LoginView` first; on successful login they are routed to `TaskListView`. The implementation is v1 / MVP: no real backend, no persistent session. An `AuthService` protocol ensures the backend can be swapped without touching UI code.

**FRS alignment:** Authentication is listed under §5 Future Enhancements. This change advances that roadmap item without breaking any existing task-management requirements.

---

## 2. Architecture Decisions

### 2.1 MVVM layer assignments

| Layer | Type | Responsibility |
|-------|------|----------------|
| Model | `AuthError` | Typed error cases for auth failures |
| Service | `AuthService` protocol + `MockAuthService` | Auth abstraction; swap for real backend later |
| ViewModel | `AuthViewModel` | Root auth state (`isAuthenticated`), shared app-wide |
| ViewModel | `LoginViewModel` | Form state, validation, async login call |
| View | `LoginView` | Declarative UI only; no business logic |

### 2.2 Root navigation gate

`TodoApp.swift` owns a `@StateObject private var authViewModel`. The root `WindowGroup` body switches between `LoginView` and `TaskListView` based on `authViewModel.isAuthenticated`. Both branches receive `authViewModel` via `.environmentObject(authViewModel)`.

This is the simplest correct design: one source of truth, observable from anywhere, easy to reset for testing.

### 2.3 Async login without `Task {}` conflict

The project defines a `Task` model (`struct Task: Identifiable, Codable`). Using `Task { }` anywhere in the module resolves to `TodoApp.Task`, not Swift's concurrency `Task`.

**Solution:** Login button increments `@State private var loginAttempt: Int`. The `.task(id: loginAttempt)` view modifier (SwiftUI, iOS 15+) re-fires the async block whenever the id changes. `guard loginAttempt > 0` prevents it from running on initial view appearance.

This is idiomatic SwiftUI, avoids the naming conflict, and automatically cancels in-flight work if the user taps again.

### 2.4 Form validation location

All validation (`isLoginEnabled`, `isEmailFormatInvalid`, email regex) lives in `LoginViewModel`, not `LoginView`. The view observes published state and renders accordingly. This matches the project's MVVM rule: Views = UI only.

### 2.5 No persistent session (v1)

`AuthViewModel.isAuthenticated` is an in-memory `Bool`. Each app launch starts unauthenticated. This is acceptable for MVP. Future: store a token in Keychain and restore it on launch.

---

## 3. File Map

### 3.1 New files

```
TodoApp/
  Services/
    AuthService.swift         ← AuthError enum + AuthService protocol + MockAuthService
  ViewModels/
    AuthViewModel.swift       ← @Published isAuthenticated: Bool
    LoginViewModel.swift      ← Form state, validation, login(), forgotPassword()
  Views/
    LoginView.swift           ← Login UI (logo, email field, password field, buttons)

TodoAppTests/
  LoginViewModelTests.swift   ← 18 unit tests covering all ViewModel scenarios
```

### 3.2 Modified files

```
TodoApp/TodoApp.swift                       ← Inject AuthViewModel; conditional root view
TodoApp.xcodeproj/project.pbxproj          ← 4 new source files + TodoAppTests target
```

---

## 4. Type Contracts

### `AuthError`
```swift
enum AuthError: LocalizedError {
    case emptyFields
    case invalidEmailFormat
    case invalidCredentials
}
```

### `AuthService`
```swift
protocol AuthService {
    func login(email: String, password: String) async throws
}
```

### `AuthViewModel`
```swift
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    func logout()
}
```

### `LoginViewModel`
```swift
@MainActor final class LoginViewModel: ObservableObject {
    @Published var email: String
    @Published var password: String
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    @Published var showForgotPasswordAlert: Bool

    var isLoginEnabled: Bool           // non-empty email (trimmed) + non-empty password
    var isEmailFormatInvalid: Bool     // false when empty; true when non-empty + bad format

    func login() async -> Bool         // validates → calls AuthService → returns success
    func forgotPassword()              // sets showForgotPasswordAlert = true
}
```

---

## 5. Data / Persistence Impact

None. The auth state is in-memory. The existing task persistence layer (`TaskRepository`, `JSONTaskRepository`) is untouched.

Future: when real auth is added, store a JWT/session token in Keychain. Read on app launch in `AuthViewModel.init()` to restore session.

---

## 6. Reuse of Existing Patterns

| Pattern in codebase | Reuse in this change |
|---------------------|----------------------|
| `TaskRepository` protocol (service abstraction) | Same pattern used for `AuthService` protocol |
| `TaskListViewModel` (`@MainActor`, `@Published`) | Same pattern for `LoginViewModel` |
| `@StateObject` ViewModel ownership in Views | `LoginView` owns `LoginViewModel` via `@StateObject` |
| `.environmentObject` injection (`NotificationService`) | `AuthViewModel` injected via `.environmentObject` from root |

---

## 7. Spec Coverage

| Spec Requirement | Implementation |
|-----------------|----------------|
| Login screen shown when unauthenticated | `TodoApp.swift` root gate on `authViewModel.isAuthenticated` |
| Email `TextField` with email keyboard | `TextField` + `.keyboardType(.emailAddress)` + `.textContentType(.emailAddress)` |
| Password `SecureField` | `SecureField` + `.textContentType(.password)` |
| Login button disabled when fields empty | `.disabled(!viewModel.isLoginEnabled \|\| viewModel.isLoading)` |
| Inline email format error | `if viewModel.isEmailFormatInvalid { Text(...) }` |
| Auth failure error banner | `if let error = viewModel.errorMessage { Text(error) }` |
| Loading indicator in button | `if viewModel.isLoading { ProgressView() }` |
| Forgot Password button visible | `Button("Forgot Password?")` always rendered |
| Forgot Password shows placeholder | `.alert(isPresented: $viewModel.showForgotPasswordAlert)` |

---

## 8. Quality Gates

```bash
# 1. Lint (not installed in this environment; add .swiftlint.yml when available)
swiftlint

# 2. Tests — 18/18 passing
xcodebuild test -scheme TodoApp -destination "platform=iOS Simulator,name=iPhone 17 Pro"

# 3. Build
xcodebuild build -scheme TodoApp -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

**Current results:** Tests `** TEST SUCCEEDED **` (18/18) · Build `** BUILD SUCCEEDED **`

---

## 9. Known Limitations & Follow-up Tasks

| Item | Priority | Notes |
|------|----------|-------|
| Persistent session (Keychain) | Medium | User must log in every launch |
| Real `AuthService` implementation | High (when backend exists) | Replace `MockAuthService`; wire to API endpoint |
| Password reset flow | Low | Placeholder alert only; full flow is future scope |
| Biometric auth (Face ID) | Low | Not in scope for v1 |
| SwiftLint config | Low | No `.swiftlint.yml` in project; add when needed |
