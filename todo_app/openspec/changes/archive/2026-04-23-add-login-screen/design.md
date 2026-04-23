## Context

The app currently launches directly into `TaskListView`. There is no auth layer. The FRS lists Authentication as a future enhancement. This design introduces a login screen as the app entry point, keeping the scope minimal: UI + form validation + local auth simulation (no real backend in v1).

Architecture is MVVM + SwiftUI. iOS 17+ target. Native frameworks only (no third-party auth SDKs).

## Goals / Non-Goals

**Goals:**
- Introduce `LoginView` as the conditional root view when the user is not authenticated
- Support email and password input with inline validation
- Provide a "Forgot Password" button (placeholder navigation for now)
- Provide a "Login" button that validates input and transitions to `TaskListView`
- Abstract auth behind an `AuthService` protocol so real backends can be wired later

**Non-Goals:**
- Real backend authentication (no API calls in v1)
- User registration / sign-up flow
- Password reset implementation (button exists, flow is a future task)
- Biometric authentication (Face ID / Touch ID)
- Persistent session / keychain token storage

## Decisions

### 1. Auth state managed via `@AppStorage` / environment object
**Decision:** Use a shared `AuthViewModel` (or `@AppStorage("isLoggedIn")`) injected at the root to gate navigation between `LoginView` and `TaskListView`.
**Rationale:** Simple boolean flag is sufficient for v1. Avoids over-engineering a full session manager before a real auth backend exists. Swapping to a proper token-based session later only requires updating `AuthService` implementation.
**Alternative considered:** Keeping auth state inside `LoginViewModel` — rejected because the root `App` struct needs to observe it to switch views.

### 2. `AuthService` protocol for abstraction
**Decision:** Define `protocol AuthService` with a `login(email:password:) async throws` method. Provide a `MockAuthService` for v1.
**Rationale:** Decouples `LoginViewModel` from any specific auth backend. Enables unit testing without network. Matches the existing repository abstraction pattern in the project.

### 3. Form validation in `LoginViewModel`
**Decision:** Email format validation (basic regex) and non-empty password check live in `LoginViewModel`, not the View.
**Rationale:** Keeps Views declarative and business-logic-free per MVVM rules.

### 4. "Forgot Password" as a no-op sheet
**Decision:** Tapping "Forgot Password" shows a `.sheet` or alert saying "Feature coming soon." 
**Rationale:** The button must exist per requirements. A placeholder is better than a dead button for UX.

## Risks / Trade-offs

- **Mock auth accepts any non-empty credentials** → Mitigation: Clearly document this is a stub; swap `MockAuthService` with real implementation at that phase.
- **No persistent session** → User must log in each launch in v1. Mitigation: Acceptable for MVP; keychain session storage is a follow-up task.
- **App entry point change** → If something goes wrong with auth state, users could be locked out or bypassed. Mitigation: Keep logic simple; add an escape hatch (e.g., reset flag) for testing.
