## Phase 1: Foundation

_Shared types and service abstraction. Nothing else depends on these; complete before any other phase._

- [x] 1.1 Define `AuthError` enum (`emptyFields`, `invalidEmailFormat`, `invalidCredentials`) conforming to `LocalizedError` — `TodoApp/Services/AuthService.swift`
- [x] 1.2 Define `AuthService` protocol with `login(email:password:) async throws` — `TodoApp/Services/AuthService.swift`
- [x] 1.3 Implement `MockAuthService` (accepts any non-empty email + password) — `TodoApp/Services/AuthService.swift`
- [x] 1.4 Create `AuthViewModel: ObservableObject` with `@Published isAuthenticated: Bool` and `logout()` — `TodoApp/ViewModels/AuthViewModel.swift`

**Phase 1 checkpoint:**
```bash
xcodebuild build -scheme TodoApp -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

---

## Phase 2: Core Implementation

_ViewModel and View can be built in parallel once Phase 1 is done._

### 2A. LoginViewModel [PARALLEL]
- [x] 2A.1 Create `LoginViewModel: ObservableObject` (`@MainActor`) with `@Published` properties: `email`, `password`, `isLoading`, `errorMessage`, `showForgotPasswordAlert` — `TodoApp/ViewModels/LoginViewModel.swift`
- [x] 2A.2 Implement `isLoginEnabled: Bool` — true when email (trimmed) and password are both non-empty
- [x] 2A.3 Implement `isEmailFormatInvalid: Bool` — false when empty; true when non-empty and fails regex
- [x] 2A.4 Implement private `isValidEmail(_:) -> Bool` using regex `^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$`
- [x] 2A.5 Implement `login() async -> Bool`: guard `isLoginEnabled` → validate email format → set `isLoading = true` → call `authService.login` → handle success / set `errorMessage` on failure → set `isLoading = false`
- [x] 2A.6 Implement `forgotPassword()`: set `showForgotPasswordAlert = true`

### 2B. LoginView [PARALLEL]
- [x] 2B.1 Create `LoginView.swift` — `TodoApp/Views/LoginView.swift`
- [x] 2B.2 Add `@StateObject private var viewModel = LoginViewModel()` and `@EnvironmentObject private var authViewModel: AuthViewModel`
- [x] 2B.3 Add `@State private var loginAttempt: Int = 0` (workaround for `Task {}` / `TodoApp.Task` name conflict — see `plan.md §2.3`)
- [x] 2B.4 Render logo (`checkmark.circle.fill`, 64pt) + title "TodoApp" + subtitle "Sign in to continue"
- [x] 2B.5 Render `TextField("Email")` bound to `$viewModel.email` — `.keyboardType(.emailAddress)`, `.textContentType(.emailAddress)`, `.autocapitalization(.none)`
- [x] 2B.6 Render inline error `Text(...)` beneath email field when `viewModel.isEmailFormatInvalid` is true
- [x] 2B.7 Render `SecureField("Password")` bound to `$viewModel.password` — `.textContentType(.password)`
- [x] 2B.8 Render error banner `Text(error)` (red background) when `viewModel.errorMessage` is non-nil
- [x] 2B.9 Render `Button("Forgot Password?")` → calls `viewModel.forgotPassword()`
- [x] 2B.10 Render Login `Button` — increments `loginAttempt`; label shows `ProgressView` when `isLoading`, "Login" text otherwise; `.disabled(!viewModel.isLoginEnabled || viewModel.isLoading)`; background `.blue` / `.gray` based on enabled state
- [x] 2B.11 Attach `.task(id: loginAttempt)` modifier — `guard loginAttempt > 0`; calls `await viewModel.login()`; on `true` sets `authViewModel.isAuthenticated = true`
- [x] 2B.12 Attach `.alert("Feature Coming Soon", isPresented: $viewModel.showForgotPasswordAlert)` with OK button

**Phase 2 checkpoint:**
```bash
xcodebuild build -scheme TodoApp -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

---

## Phase 3: Integration

_Wire everything together at the app root._

- [x] 3.1 In `TodoApp.swift`: add `@StateObject private var authViewModel = AuthViewModel()`
- [x] 3.2 Root `WindowGroup` body: show `LoginView().environmentObject(authViewModel)` when `!authViewModel.isAuthenticated`, else `TaskListView().environmentObject(authViewModel)`
- [x] 3.3 Register new source files in `project.pbxproj`: `AuthService.swift`, `AuthViewModel.swift`, `LoginViewModel.swift`, `LoginView.swift` (PBXBuildFile + PBXFileReference + group children + Sources build phase)

**Phase 3 checkpoint:**
```bash
xcodebuild build -scheme TodoApp -destination "platform=iOS Simulator,name=iPhone 17 Pro"
# Launch in simulator: verify LoginView appears before TaskListView
```

---

## Phase 4: Tests

_One test per spec scenario. All tests live in `TodoAppTests/LoginViewModelTests.swift`._

Add `TodoAppTests` unit test target to `project.pbxproj` before running.

### Spec: Login screen is the app entry point
- [x] 4.1 `test_appEntry_unauthenticated_showsLoginView` — `AuthViewModel.isAuthenticated` starts `false`
- [x] 4.2 `test_appEntry_authenticated_isAuthenticated_isTrue` — setting `isAuthenticated = true` reflects correctly

### Spec: Email input field
- [x] 4.3 `test_emailValidation_validEmail_noError` — `isEmailFormatInvalid` is `false` for `user@example.com`
- [x] 4.4 `test_emailValidation_withSubdomain_isValid` — `isEmailFormatInvalid` is `false` for `user@mail.example.co.uk`

### Spec: Password input / Login button disabled when fields empty
- [x] 4.5 `test_isLoginEnabled_bothEmpty_returnsFalse`
- [x] 4.6 `test_isLoginEnabled_emailOnlyFilled_returnsFalse`
- [x] 4.7 `test_isLoginEnabled_passwordOnlyFilled_returnsFalse`
- [x] 4.8 `test_isLoginEnabled_bothFilled_returnsTrue`
- [x] 4.9 `test_isLoginEnabled_whitespaceEmail_returnsFalse`

### Spec: Email format validation
- [x] 4.10 `test_emailValidation_missingAt_isInvalid`
- [x] 4.11 `test_emailValidation_missingDomain_isInvalid`
- [x] 4.12 `test_emailValidation_emptyString_noError` — empty field shows no inline error

### Spec: Successful login → navigate to task list
- [x] 4.13 `test_login_validCredentials_returnsTrue` — using `AlwaysSucceedAuthService`
- [x] 4.14 `test_login_success_isLoadingFalseAfterwards`

### Spec: Authentication failure feedback
- [x] 4.15 `test_login_invalidCredentials_returnsFalse` — using `AlwaysFailAuthService`
- [x] 4.16 `test_login_invalidCredentials_setsErrorMessage`
- [x] 4.17 `test_login_invalidEmailFormat_setsErrorAndReturnsFalse`

### Spec: Loading state during authentication
- [x] 4.18 `test_login_isLoadingFalseAfterSuccess`
- [x] 4.19 `test_login_isLoadingFalseAfterFailure`

### Spec: Forgot Password button
- [x] 4.20 `test_forgotPassword_setsAlertFlag`

**Phase 4 checkpoint:**
```bash
xcodebuild test -scheme TodoApp -destination "platform=iOS Simulator,name=iPhone 17 Pro"
# Expected: ** TEST SUCCEEDED ** (20 tests)

swiftlint
# Expected: 0 warnings, 0 errors
```
