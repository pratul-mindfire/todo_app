# User Login

### Requirement: Login screen is the app entry point for unauthenticated users
The system SHALL display the login screen as the first screen when no authenticated session exists.

#### Scenario: App launch without active session
- **WHEN** the user launches the app and no authenticated session is present
- **THEN** the system SHALL display the login screen

#### Scenario: App launch with active session
- **WHEN** the user launches the app and an active session exists
- **THEN** the system SHALL navigate directly to the task list screen

---

### Requirement: Email input field
The login screen SHALL provide an email text input field.

#### Scenario: Field is visible and editable
- **WHEN** the login screen is displayed
- **THEN** an email text field SHALL be visible and the user can type into it

#### Scenario: Keyboard type is email
- **WHEN** the user taps the email field
- **THEN** the system SHALL present an email-optimized keyboard

---

### Requirement: Password input field
The login screen SHALL provide a secure password input field.

#### Scenario: Field masks input
- **WHEN** the user types in the password field
- **THEN** the input SHALL be masked (characters hidden)

#### Scenario: Field is visible and editable
- **WHEN** the login screen is displayed
- **THEN** a password field SHALL be visible and the user can type into it

---

### Requirement: Login button triggers authentication
The login screen SHALL provide a "Login" button that initiates the authentication flow. The button delegates to `RemoteAuthService` (calls the remote API) rather than a mock implementation.

#### Scenario: Successful login with valid credentials
- **WHEN** the user enters a valid email and non-empty password and taps "Login"
- **THEN** the system SHALL authenticate the user and navigate to the task list screen

#### Scenario: Login button is disabled when fields are empty
- **WHEN** either the email or password field is empty
- **THEN** the "Login" button SHALL be disabled

---

### Requirement: Email format validation
The system SHALL validate that the email field contains a properly formatted email address before submitting.

#### Scenario: Invalid email format
- **WHEN** the user enters a string that is not a valid email format and taps "Login"
- **THEN** the system SHALL display an inline error message indicating the email format is invalid

#### Scenario: Valid email format
- **WHEN** the user enters a properly formatted email address
- **THEN** no email format error SHALL be shown

---

### Requirement: Authentication failure feedback
The system SHALL display an error message when authentication fails.

#### Scenario: Invalid credentials
- **WHEN** the user submits credentials that fail authentication
- **THEN** the system SHALL display an error message indicating the credentials are incorrect

---

### Requirement: Forgot Password button
The login screen SHALL provide a "Forgot Password" button.

#### Scenario: Button is visible
- **WHEN** the login screen is displayed
- **THEN** a "Forgot Password" button SHALL be visible

#### Scenario: Tapping Forgot Password shows placeholder
- **WHEN** the user taps "Forgot Password"
- **THEN** the system SHALL display a message indicating this feature is coming soon

---

### Requirement: Loading state during authentication
The system SHALL indicate a loading state while authentication is in progress.

#### Scenario: Login in progress
- **WHEN** the user taps "Login" and authentication is processing
- **THEN** the "Login" button SHALL show a loading indicator and be non-interactive
