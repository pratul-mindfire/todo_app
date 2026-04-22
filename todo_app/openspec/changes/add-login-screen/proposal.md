## Why

The app currently has no authentication layer — any user can access all tasks without verification. Adding a login screen is the first step toward enabling user-specific data, future cloud sync, and secure multi-user support as outlined in the FRS Future Enhancements.

## What Changes

- Introduce a new `LoginView` as the app's entry point before the task list
- Add email and password input fields with validation
- Add a "Forgot Password" button (navigates to a placeholder/future reset flow)
- Add a "Login" button that authenticates the user and navigates to the main task list
- Add a `LoginViewModel` to manage form state, validation, and auth logic
- Add an `AuthService` protocol for the authentication abstraction layer

## Capabilities

### New Capabilities

- `user-login`: Email/password login screen with form validation, forgot password affordance, and auth state management

### Modified Capabilities

<!-- No existing spec-level requirements are changing -->

## Impact

- New files: `LoginView.swift`, `LoginViewModel.swift`, `AuthService.swift`
- App entry point (`@main` / root view) updated to conditionally show `LoginView` or `TaskListView` based on auth state
- No changes to existing task management logic or persistence layer
