## ADDED Requirements

### Requirement: Login submits credentials to the remote API
The system SHALL send a POST request to the configured login endpoint with the user's email and password when the login form is submitted.

#### Scenario: Successful API login
- **WHEN** the user submits valid credentials
- **THEN** the system SHALL call `POST /auth/login` with `{ "email": ..., "password": ... }`
- **AND** the system SHALL receive `{ "success": true, "token": "...", "user": { ... } }`
- **AND** the system SHALL persist the token and user to local storage
- **AND** the system SHALL navigate to the task list screen

#### Scenario: Invalid credentials from API
- **WHEN** the API responds with `{ "success": false, "message": "Invalid credentials" }`
- **THEN** the system SHALL display the `message` value directly as the error banner

#### Scenario: Network or server error
- **WHEN** the network request fails or the server returns a non-2xx status with an undecodable body
- **THEN** the system SHALL display a generic network error message

---

### Requirement: JWT token is persisted after login
The system SHALL store the JWT token in `UserDefaults` after a successful login so authenticated state survives an app restart.

#### Scenario: Token stored on success
- **WHEN** login succeeds
- **THEN** the token SHALL be written to `UserDefaults` under key `auth.token`

#### Scenario: Token cleared on logout
- **WHEN** the user logs out
- **THEN** the `auth.token` entry SHALL be removed from `UserDefaults`

---

### Requirement: Logged-in user's info is accessible app-wide
The system SHALL store and expose the authenticated `User` (id, name, email) via `AuthViewModel` after login.

#### Scenario: User available after login
- **WHEN** login succeeds
- **THEN** `AuthViewModel.currentUser` SHALL be non-nil and reflect the values from the API response

#### Scenario: User nil after logout
- **WHEN** the user logs out
- **THEN** `AuthViewModel.currentUser` SHALL be `nil`

---

### Requirement: App allows HTTP connections to localhost
The system SHALL permit non-HTTPS (HTTP) network requests to support local development APIs.

#### Scenario: HTTP request to localhost succeeds
- **WHEN** the app calls `http://localhost:5000/api/v1/auth/login`
- **THEN** the request SHALL not be blocked by App Transport Security

---

## MODIFIED Requirements

### Requirement: Login button triggers authentication (from `user-login`)
_Extended — no scenario change, implementation now calls remote API instead of mock._

- The `AuthService` protocol gains `currentUser: User?` and `token: String?` read properties
- `LoginViewModel` defaults to `RemoteAuthService` instead of `MockAuthService`
- Existing UI behaviour (loading state, error banner, disabled button) remains unchanged
